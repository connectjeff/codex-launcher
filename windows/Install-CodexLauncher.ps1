[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path $PSScriptRoot -Parent),
    [switch]$PinToTaskbar
)

$ErrorActionPreference = 'Stop'
$RepositoryRoot = (Resolve-Path $RepositoryRoot).Path
$installLink = Join-Path $env:LOCALAPPDATA 'Programs\Codex Launcher'
$shortcutPath = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Codex Launcher.lnk'
$launcher = Join-Path $installLink 'windows\Codex-Launcher.ps1'
$workingDirectory = Split-Path $RepositoryRoot -Parent

if (Test-Path -LiteralPath $installLink) {
    $item = Get-Item -LiteralPath $installLink -Force
    if (-not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw "Install path already exists and is not a link: $installLink"
    }
    Remove-Item -LiteralPath $installLink -Force
}

New-Item -ItemType Directory -Path (Split-Path $installLink -Parent) -Force | Out-Null
try {
    New-Item -ItemType SymbolicLink -Path $installLink -Target $RepositoryRoot | Out-Null
    $linkType = 'symbolic link'
} catch {
    New-Item -ItemType Junction -Path $installLink -Target $RepositoryRoot | Out-Null
    $linkType = 'directory junction'
}

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = 'powershell.exe'
$shortcut.Arguments = "-NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$launcher`""
$shortcut.WorkingDirectory = $workingDirectory
$icon = Join-Path $installLink 'windows\CodexLauncher.ico'
if (Test-Path -LiteralPath $icon) { $shortcut.IconLocation = "$icon,0" }
$shortcut.Description = 'Launch Codex with the default or LM Studio profile'
$shortcut.Save()

$pinAttempted = $false
if ($PinToTaskbar) {
    $pinAttempted = $true
    $folder = (New-Object -ComObject Shell.Application).Namespace((Split-Path $shortcutPath -Parent))
    $item = $folder.ParseName((Split-Path $shortcutPath -Leaf))
    $verb = @($item.Verbs()) | Where-Object { ($_.Name -replace '&','') -match 'Pin to taskbar' } | Select-Object -First 1
    if ($verb) { $verb.DoIt() }
}

[pscustomobject]@{
    Repository = $RepositoryRoot
    InstallLink = $installLink
    LinkType = $linkType
    StartMenuShortcut = $shortcutPath
    TaskbarPinAttempted = $pinAttempted
}
