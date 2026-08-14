[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path $PSScriptRoot 'CodexLauncher.ico')
)

$ErrorActionPreference = 'Stop'
$iconset = Join-Path (Split-Path $PSScriptRoot -Parent) 'Codex Launcher.app\Contents\Resources\CodexLauncher.iconset'
$sources = @(
    @{ Size = 16; Path = Join-Path $iconset 'icon_16x16.png' },
    @{ Size = 32; Path = Join-Path $iconset 'icon_32x32.png' },
    @{ Size = 128; Path = Join-Path $iconset 'icon_128x128.png' },
    @{ Size = 256; Path = Join-Path $iconset 'icon_256x256.png' }
)

$images = @($sources | ForEach-Object {
    if (-not (Test-Path -LiteralPath $_.Path)) { throw "Missing icon source: $($_.Path)" }
    @{ Size = $_.Size; Bytes = [IO.File]::ReadAllBytes($_.Path) }
})

$stream = [IO.File]::Open($OutputPath, [IO.FileMode]::Create)
$writer = [IO.BinaryWriter]::new($stream)
try {
    $writer.Write([uint16]0)
    $writer.Write([uint16]1)
    $writer.Write([uint16]$images.Count)
    $offset = 6 + (16 * $images.Count)
    foreach ($image in $images) {
        $dimension = if ($image.Size -eq 256) { 0 } else { $image.Size }
        $writer.Write([byte]$dimension)
        $writer.Write([byte]$dimension)
        $writer.Write([byte]0)
        $writer.Write([byte]0)
        $writer.Write([uint16]1)
        $writer.Write([uint16]32)
        $writer.Write([uint32]$image.Bytes.Length)
        $writer.Write([uint32]$offset)
        $offset += $image.Bytes.Length
    }
    foreach ($image in $images) { $writer.Write($image.Bytes) }
} finally {
    $writer.Dispose()
    $stream.Dispose()
}

Get-Item -LiteralPath $OutputPath
