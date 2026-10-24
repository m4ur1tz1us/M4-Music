$ErrorActionPreference = 'Stop'
$musicExecutable = Join-Path $PSScriptRoot 'M4MusicHost.exe'
if (-not (Test-Path -LiteralPath $musicExecutable -PathType Leaf)) { exit 2 }
Start-Process -FilePath $musicExecutable -WorkingDirectory $PSScriptRoot -WindowStyle Hidden
