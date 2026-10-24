# M4 | Music v0.7 — source and build instructions

This source-only archive is provided for review of the M4 | Music v0.7 release.
No executables, DLLs, nested archives, user songs, cover caches or game assets are included.

## Prerequisites

- Windows x64 with .NET Framework 4.x, including WPF and its C# compiler.
- Visual Studio 2022 or Build Tools with **Desktop development with C++**, MSVC x64 tools and a Windows SDK.
- Windows PowerShell 5.1 or PowerShell 7.
- No NuGet packages, downloaded codecs or third-party source libraries are needed.

## Build

Extract the archive into a writable folder. Open PowerShell in that folder and run:

```powershell
& .\build.ps1
```

If local PowerShell policy blocks scripts, inspect the script first and use a
process-only policy override if permitted by your system policy:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
```

The script builds the C# Windows application from `src/MusicHost.cs` and
`src/CoverArt.cs`, then compiles the x64 native launcher from `src/NativeStart.cpp`.
Outputs are `build/M4MusicHost.exe` and `build/M4MusicStart.dll`.
It does not install files, launch the game, access the network or modify the release.
Compiler versions and build settings can change binary hashes; a byte-identical
reproduction of the original release binaries is not claimed.

## Runtime layout

For a separate test installation, use the Lua scripts and settings in `runtime/`.
Place the newly built EXE in the mod root, and the DLL in its `Scripts/` folder.
Create a `Music/` folder in the mod root and add your own MP3/WAV files.
The mod root is `Pal/Binaries/Win64/ue4ss/Mods/M4Music/` within an existing
Palworld/UE4SS installation. See README_EN.txt for normal installation and controls.
The optional StartHost.ps1 is a manual fallback; normal game startup uses the DLL.

## Review map

- `src/NativeStart.cpp`: Lua-loadable `m4music_start` export. Starts the adjacent
  M4MusicHost.exe with CreateProcessW and hidden-window flags, closes the returned
  process handles, and writes launcher-error.txt if process creation fails.
- `src/MusicHost.cs`: local Windows WPF MediaPlayer playback, playlist, fade and
  combat state handling, game process monitoring and local file-based control/status.
- `src/CoverArt.cs`: bounded local ID3 cover extraction and PNG cache generation.
- `runtime/Scripts/`: UE4SS Lua integration, menu widgets, game music mixing,
  player/combat state and local control/status protocol.
- `RELEASE_SHA256SUMS.txt`: hashes of files in the original release for identification.
- `SOURCE_SHA256SUMS.txt`: integrity hashes of this source package.

The host reads music locally and writes settings, status/control data, logs,
last-start.txt and generated CoverCache files under the mod folder. The launcher
starts a separate helper process; audio decoding is performed outside the game.
The native launcher itself does not inject code or patch the game executable.
The Lua component runs inside the game through the user's existing UE4SS installation.

This archive is review material, not a replacement end-user download.
