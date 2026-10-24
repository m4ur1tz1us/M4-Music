# M4 | Music

A local MP3/WAV music player for Palworld with UE4SS integration.

**Version 0.7 — source code for review of the Nexus Mods release.**

This repository contains the complete project-specific source code for the
audio host, native launcher and UE4SS Lua component. Sources are provided as
individual files so they can be reviewed directly on GitHub.

## Build from source

See **[BUILD_EN.md](BUILD_EN.md)** for prerequisites, exact build commands,
output paths, runtime layout and a component review map.

Requires Windows x64, .NET Framework 4.x/WPF and Visual Studio 2022 or Build
Tools with the Desktop development with C++ workload and a Windows SDK.
Clone this repository or extract GitHub's source ZIP, then open PowerShell
in the repository root and run:

```powershell
& .\build.ps1
```

Outputs: `build/M4MusicHost.exe` and `build/M4MusicStart.dll`.
The build script does not install or launch them. Build outputs are excluded
from Git. No NuGet packages or third-party codec libraries are required.

## Source layout

| Path | Purpose |
| --- | --- |
| `src/MusicHost.cs` | Windows audio host, playlist, fades and local state protocol |
| `src/CoverArt.cs` | Embedded MP3 cover extraction and image cache |
| `src/NativeStart.cpp` | Small x64 launcher loaded by the Lua component |
| `runtime/Scripts/` | UE4SS integration, menu player, combat state and game audio mixing |
| `runtime/Settings.ini` | Default settings |
| `runtime/StartHost.ps1` | Optional manual launcher; not used for normal game startup |

## End users

This is a source repository, not the ready-to-install mod package.
Download the mod from its [Nexus Mods page](https://www.nexusmods.com/palworld/mods/5987).
A working UE4SS installation is required; UE4SS and Palworld are not included.

- [English installation and usage](README_EN.txt)
- [Deutsche Installation und Bedienung](README_DE.txt)

No music files, generated covers, compiled binaries or game assets are included.
The player reads the user's own local MP3 and WAV files.

## Release identification

[RELEASE_REFERENCE.txt](RELEASE_REFERENCE.txt) identifies the reviewed release ZIP.
[RELEASE_SHA256SUMS.txt](RELEASE_SHA256SUMS.txt) lists its file hashes.
[SOURCE_SHA256SUMS.txt](SOURCE_SHA256SUMS.txt) lists the source repository file hashes.
Compiler versions and build settings can change compiled hashes; byte-identical
reproduction of the original binaries is not claimed.

## Deutsch

Dieses Repository enthaelt den vollstaendigen mod-eigenen Quellcode von
**M4 | Music v0.7** fuer die Pruefung durch Nexus Mods. Die englische
[Bauanleitung](BUILD_EN.md) beschreibt Voraussetzungen und Erstellung der
beiden Programmdateien. Fuer die normale Installation bitte das Mod-Paket
auf Nexus Mods und die deutsche Readme verwenden.
