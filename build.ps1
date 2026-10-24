$ErrorActionPreference = 'Stop'
$reviewRoot = $PSScriptRoot
$buildDir = Join-Path $reviewRoot 'build'
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
$frameworkDir = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319'
$compiler = Join-Path $frameworkDir 'csc.exe'
if (-not (Test-Path -LiteralPath $compiler)) { throw '.NET Framework 4.x x64 C# compiler not found.' }
$refs = @('WindowsBase.dll', 'PresentationCore.dll', 'PresentationFramework.dll')
$hostArgs = @('/nologo', '/target:winexe', '/platform:x64', '/optimize+', ('/out:' + (Join-Path $buildDir 'M4MusicHost.exe')))
$hostArgs += '/reference:' + (Join-Path $frameworkDir 'System.Xaml.dll')
foreach ($ref in $refs) { $hostArgs += '/reference:' + (Join-Path (Join-Path $frameworkDir 'WPF') $ref) }
$hostArgs += Join-Path $reviewRoot 'src\MusicHost.cs'
$hostArgs += Join-Path $reviewRoot 'src\CoverArt.cs'
& $compiler @hostArgs
if ($LASTEXITCODE -ne 0) { throw 'C# build failed.' }
$locator = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (-not (Test-Path -LiteralPath $locator)) { throw 'Install Visual Studio 2022 / Build Tools with Desktop development with C++.' }
$vsRoot = & $locator -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vsRoot) { throw 'No Visual Studio installation with the x64 C++ tools found.' }
$vcvars = Join-Path $vsRoot 'VC\Auxiliary\Build\vcvarsall.bat'
& $env:ComSpec /d /c call (Join-Path $reviewRoot 'build-native.cmd') $vcvars
if ($LASTEXITCODE -ne 0) { throw 'Native launcher build failed.' }
Get-FileHash -LiteralPath (Join-Path $buildDir 'M4MusicHost.exe'), (Join-Path $buildDir 'M4MusicStart.dll') -Algorithm SHA256
Write-Host 'Build complete. Outputs are in build/. The installed game and release were not changed.'
