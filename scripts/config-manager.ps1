[CmdletBinding()]
param(
    [Parameter(Position=0)][ValidateSet('list','create','switch','export','import','show','edit')][string]$Command = 'show',
    [Parameter(Position=1)][string]$Value
)

$ErrorActionPreference = 'Stop'
$configDir = Join-Path $HOME 'codex-config\codex-home-lmstudio'
$configFile = Join-Path $configDir 'config.toml'
$preferences = Join-Path $configDir 'launcher-preferences.json'
$profilesDir = Join-Path $HOME 'codex-config\profiles'
New-Item -ItemType Directory -Path $profilesDir -Force | Out-Null

function Assert-Name([string]$Name) {
    if (-not $Name -or $Name -notmatch '^[A-Za-z0-9._-]+$') { throw 'Supply a profile name containing only letters, numbers, dot, underscore, or hyphen.' }
}

switch ($Command) {
    'list' {
        $profiles = @(Get-ChildItem -LiteralPath $profilesDir -Filter '*.toml')
        if (-not $profiles.Count) { Write-Host 'No profiles found.' }
        else { $profiles.BaseName }
    }
    'create' {
        Assert-Name $Value
        if (-not (Test-Path $configFile)) { throw 'No LM Studio config exists. Run the Windows launcher in LMStudio mode first.' }
        Copy-Item -LiteralPath $configFile -Destination (Join-Path $profilesDir "$Value.toml")
        Write-Host "Created profile: $Value"
    }
    'switch' {
        Assert-Name $Value
        $source = Join-Path $profilesDir "$Value.toml"
        if (-not (Test-Path $source)) { throw "Profile '$Value' was not found." }
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        if (Test-Path $configFile) { Copy-Item $configFile "$configFile.backup" -Force }
        Copy-Item -LiteralPath $source -Destination $configFile -Force
        Write-Host "Switched to profile: $Value"
    }
    'export' {
        if (-not (Test-Path $configFile)) { throw 'No LM Studio config exists.' }
        if (-not $Value) { $Value = Join-Path ([Environment]::GetFolderPath('Desktop')) 'codex-lmstudio-config.zip' }
        $items = @($configFile)
        if (Test-Path $preferences) { $items += $preferences }
        Compress-Archive -LiteralPath $items -DestinationPath $Value -Force
        Write-Host "Exported configuration to: $Value"
    }
    'import' {
        if (-not $Value -or -not (Test-Path $Value)) { throw 'Supply an existing .zip or .toml file.' }
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        if (Test-Path $configFile) { Copy-Item $configFile "$configFile.backup-before-import" -Force }
        if ([IO.Path]::GetExtension($Value) -eq '.zip') { Expand-Archive -LiteralPath $Value -DestinationPath $configDir -Force }
        else { Copy-Item -LiteralPath $Value -Destination $configFile -Force }
        Write-Host "Imported configuration from: $Value"
    }
    'show' {
        if (Test-Path $configFile) { Get-Content $configFile } else { Write-Host "Config not found: $configFile" }
    }
    'edit' {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        if (-not (Test-Path $configFile)) { New-Item -ItemType File -Path $configFile | Out-Null }
        Start-Process notepad.exe -ArgumentList $configFile
    }
}
