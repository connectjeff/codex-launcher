[CmdletBinding()]
param(
    [ValidateSet('Prompt','Default','LMStudio')][string]$Profile = 'Prompt',
    [string]$Endpoint = $(if ($env:LMSTUDIO_BASE_URL) { $env:LMSTUDIO_BASE_URL } else { 'http://127.0.0.1:1234/v1' }),
    [string]$Model,
    [string]$StartDirectory = (Join-Path $HOME 'codex-config'),
    [switch]$NoLaunch,
    [switch]$NonInteractive
)

$ErrorActionPreference = 'Stop'
$defaultCodexHome = Join-Path $HOME '.codex'
$localCodexHome = Join-Path $HOME 'codex-config\codex-home-lmstudio'
$preferenceFile = Join-Path $localCodexHome 'launcher-preferences.json'
$logFile = Join-Path $HOME 'codex-config\codex-launcher.log'

function Write-LauncherLog([string]$Message) {
    $parent = Split-Path $logFile -Parent
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    Add-Content -LiteralPath $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
}

trap {
    $message = $_.Exception.Message
    Write-LauncherLog "ERROR: $message"
    Write-Host "`nCodex Launcher failed: $message" -ForegroundColor Red
    if (-not $NonInteractive) { [void](Read-Host 'Press Enter to close') }
    exit 1
}

function Resolve-CodexAppExecutable {
    $package = Get-AppxPackage -Name 'OpenAI.Codex' -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1
    if (-not $package) { throw 'The Codex Windows app package is not installed.' }

    $executable = Join-Path $package.InstallLocation 'app\ChatGPT.exe'
    if (-not (Test-Path -LiteralPath $executable)) {
        throw "The Codex app executable was not found at: $executable"
    }
    return $executable
}

function Restart-CodexAppIfNeeded {
    $running = @(Get-Process -Name 'ChatGPT' -ErrorAction SilentlyContinue)
    if (-not $running.Count) { return }

    if ($NonInteractive) {
        throw 'Codex/ChatGPT is already running. Close it before using non-interactive launch mode.'
    }

    $answer = Read-Host 'Codex/ChatGPT is already running and must restart to apply this profile. Restart it now? [Y/n]'
    if ($answer -match '^(n|no)$') {
        Write-LauncherLog 'Launch cancelled because Codex/ChatGPT was already running'
        throw 'Launch cancelled; the existing Codex/ChatGPT instance was left running.'
    }

    Write-LauncherLog "Stopping $($running.Count) existing Codex/ChatGPT process(es)"
    $running | Stop-Process -Force
    $deadline = (Get-Date).AddSeconds(15)
    do {
        Start-Sleep -Milliseconds 250
        $remaining = @(Get-Process -Name 'ChatGPT' -ErrorAction SilentlyContinue)
    } while ($remaining.Count -and (Get-Date) -lt $deadline)

    if ($remaining.Count) { throw 'Codex/ChatGPT did not stop within 15 seconds.' }
}

function Select-FromList([string]$Title, [string[]]$Choices) {
    if ($NonInteractive) { return $Choices[0] }
    Write-Host "`n$Title"
    for ($i = 0; $i -lt $Choices.Count; $i++) { Write-Host "  $($i + 1)) $($Choices[$i])" }
    do { $answer = Read-Host 'Selection' } until ($answer -as [int] -and [int]$answer -in 1..$Choices.Count)
    return $Choices[[int]$answer - 1]
}

function Get-LMStudioModels {
    $response = Invoke-RestMethod -Uri "$($Endpoint.TrimEnd('/'))/models" -TimeoutSec 10
    @($response.data | Where-Object {
        $text = ($_ | ConvertTo-Json -Compress).ToLowerInvariant()
        $text -notmatch 'embedding|rerank'
    } | ForEach-Object id | Sort-Object -Unique)
}

function Test-LMStudioModel([string]$SelectedModel) {
    $body = @{
        model = $SelectedModel
        messages = @(@{ role = 'user'; content = 'Reply with exactly: OK' })
        max_tokens = 8
        temperature = 0
    } | ConvertTo-Json -Depth 5
    $result = Invoke-RestMethod -Method Post -Uri "$($Endpoint.TrimEnd('/'))/chat/completions" -ContentType 'application/json' -Body $body -TimeoutSec 60
    if (-not $result.choices) { throw 'LM Studio returned no completion choices.' }
}

function Set-LMStudioConfig([string]$SelectedModel) {
    New-Item -ItemType Directory -Path $localCodexHome -Force | Out-Null
    $escapedEndpoint = $Endpoint.Replace('\','\\').Replace('"','\"')
    $escapedModel = $SelectedModel.Replace('\','\\').Replace('"','\"')
    $config = @"
model = "$escapedModel"
model_provider = "lmstudio-local"

[model_providers.lmstudio-local]
name = "LM Studio"
base_url = "$escapedEndpoint"
wire_api = "chat"
requires_openai_auth = false
"@
    Set-Content -LiteralPath (Join-Path $localCodexHome 'config.toml') -Value $config -Encoding utf8
    @{ endpoint = $Endpoint; last_used_model = $SelectedModel } |
        ConvertTo-Json | Set-Content -LiteralPath $preferenceFile -Encoding utf8
}

if ($Profile -eq 'Prompt') {
    $picked = Select-FromList 'Choose the Codex configuration for this session:' @('Default Codex config','Local LM Studio only')
    $Profile = if ($picked -eq 'Default Codex config') { 'Default' } else { 'LMStudio' }
}

$selectedCodexHome = $defaultCodexHome
if ($Profile -eq 'LMStudio') {
    Write-Host "Checking LM Studio at $Endpoint ..."
    $models = @(Get-LMStudioModels)
    if (-not $models.Count) { throw "No usable chat models were returned by $Endpoint/models." }
    if (-not $Model) { $Model = Select-FromList 'Choose an LM Studio model:' $models }
    if ($Model -notin $models) { throw "Model '$Model' is not currently available from LM Studio." }
    Test-LMStudioModel $Model
    Set-LMStudioConfig $Model
    $selectedCodexHome = $localCodexHome
    Write-LauncherLog "LM Studio validated: endpoint=$Endpoint model=$Model"
    Write-Host "LM Studio validated with model: $Model"
}

if ($NoLaunch) { return }
New-Item -ItemType Directory -Path $StartDirectory -Force | Out-Null
$codexApp = Resolve-CodexAppExecutable
Restart-CodexAppIfNeeded

$oldCodexHome = $env:CODEX_HOME
try {
    $env:CODEX_HOME = $selectedCodexHome
    if ($Profile -eq 'LMStudio') {
        Remove-Item Env:OPENAI_API_KEY,Env:CHATGPT_API_KEY,Env:CODEX_AUTH_TOKEN,Env:CODEX_API_KEY -ErrorAction SilentlyContinue
    }
    Write-LauncherLog "Launching Codex app with CODEX_HOME=$selectedCodexHome executable=$codexApp"
    $started = Start-Process -FilePath $codexApp -WorkingDirectory $StartDirectory -PassThru
    Start-Sleep -Seconds 3
    $appProcesses = @(Get-Process -Name 'ChatGPT' -ErrorAction SilentlyContinue)
    if (-not $appProcesses.Count) { throw 'The Codex app process did not remain running after launch.' }
    Write-LauncherLog "Codex app started successfully; initial PID=$($started.Id)"
} finally {
    $env:CODEX_HOME = $oldCodexHome
}
