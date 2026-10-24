M4 | Music — Release v0.7
English

Your own music in Palworld: a compact player in the ESC/Options menu,
with an MP3/WAV playlist, album artwork and automatic combat transitions.

REQUIREMENTS
- Palworld for Windows. This release was tested with the Steam version.
- An existing, working UE4SS installation.
- Windows media playback components and .NET Framework 4.x with WPF.
  These components were already present on the tested Windows system.
- Install on the playing client only, not on a dedicated server.

INSTALLATION
1. Close Palworld completely.
2. Copy the "Pal" folder from this archive into your Palworld game directory.
   Merge the folders so that the mod is located here:
   Pal/Binaries/Win64/ue4ss/Mods/M4Music/
3. Put your own MP3 and/or WAV files directly into:
   Pal/Binaries/Win64/ue4ss/Mods/M4Music/Music/
4. Start Palworld and load a world.
5. Press ESC and select the Options tab if necessary.

No additional PAK or PalSchema installation is required.
UE4SS itself and music files are not included in this archive.

UPDATING AN EXISTING INSTALLATION
- Close the game completely and back up your existing M4Music folder.
- Replace the program files and the "Scripts" folder with the new versions.
- Keep your own Settings.ini and Music folder.
- Do not replace your entire mod folder with an empty folder.
- Restart Palworld completely after updating.

MUSIC FOLDER
- MP3 and WAV files can share the same playlist.
- Only files directly inside Music are scanned; subfolders are not scanned.
- File extensions are case-insensitive.
- Files are played directly. The mod does not create WAV copies of MP3 files.
- Playback depends on the formats supported by Windows media playback.
  MP3 and PCM-WAV were tested; unreadable files are skipped.
- Added files while playing? Press the Eject icon to rescan the folder.

CONTROLS
- Play / Pause: start playback or pause it manually.
- Previous / next: change the current track.
- Eject icon: rescan the music folder. It does not open an external window.
- Crossed arrows: toggle Shuffle.
- Position slider: seek within the current track.
- Vertical slider: adjust your music volume.
- Long track names scroll within the title area.

STARTUP AND COMBAT
- Defaults: Shuffle enabled, volume 35%, playback enabled.
- With Shuffle enabled, the first track is chosen randomly. Where possible,
  the starting track from the previous session is avoided.
- After entering a world, playback waits about five seconds,
  then fades in over three seconds.
- On entering combat, your music fades out over about 1.5 seconds,
  while the original game/combat music is allowed to fade back in.
- After combat ends and a short calm-state check passes, your music
  resumes from its paused position with a three-second fade-in.
- A manual pause remains in effect after combat.
- Peaceful riding does not count as combat by itself.
- Your music pauses during world transitions or when communication with
  the game is lost. A missing heartbeat is detected after about three seconds.

ALBUM ARTWORK
- Embedded MP3 artwork is read from ID3v2.2, ID3v2.3 and ID3v2.4 tags.
- Embedded PNG/JPEG images are supported; front covers are preferred.
- Aspect ratio is preserved. Black borders may appear.
- Without readable embedded artwork, the "M4 Music" placeholder stays visible.
- External cover.jpg files and WAV artwork are not read in this release.
- Small, automatically generated images are stored in CoverCache.
  Original music files are not modified.

SETTINGS AND AUDIO PLAYBACK
Settings.ini stores volume (0–100), shuffle (0/1) and wanted (0/1).
Changes made in the player are saved automatically. Your music has its own
volume control; the game's saved audio settings are not overwritten.

M4MusicHost.exe plays audio in a separate process without a window.
Scripts/M4MusicStart.dll launches it without CMD or PowerShell. The process
exits when Palworld closes. StartHost.ps1 is an optional manual launcher;
the normal mod startup does not call it.

DISABLING / REMOVING
Close Palworld. To disable the mod, rename enabled.txt inside M4Music.
To remove it, first back up your music and Settings.ini, then remove only
ue4ss/Mods/M4Music. Leave UE4SS and other mods in place.

TROUBLESHOOTING
- No player visible: check your UE4SS installation and the complete mod path;
  restart the game completely after making changes.
- No tracks: check the format and folder, then press Eject to rescan.
- Search UE4SS.log for "[M4 Music]".
- Additional diagnostics: host.log, host-fatal.log or launcher-error.txt
  in the mod folder, if generated. Keep Palworld's crash report after a crash.
- When reporting a problem, include the version, reproduction steps,
  UE4SS.log and relevant host logs. Your music files are usually not needed.

RELEASE STATUS
The previously agreed functionality and appearance were confirmed in game;
the MP3/WAV extension was also tested with actual Windows playback.
This release packages those program files without changing them. Package
verification does not replace testing on other systems or game versions.

SHA256SUMS.txt lists checksums for the files in this package.
