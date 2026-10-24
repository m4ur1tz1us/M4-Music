M4 | Music — Release v0.7
Deutsch

Eigene Musik für Palworld: ein kompakter Player im ESC-/Optionen-Menü,
mit MP3/WAV-Playlist, Albumcovern und automatischen Kampfübergängen.

VORAUSSETZUNGEN
- Palworld für Windows. Diese Version wurde mit der Steam-Version getestet.
- Eine bereits funktionierende UE4SS-Installation.
- Windows-Medienwiedergabe und .NET Framework 4.x mit WPF.
  Auf dem getesteten Windows-System waren diese Komponenten bereits vorhanden.
- Nur auf dem spielenden Client installieren; kein Mod für einen Dedicated Server.

INSTALLATION
1. Palworld vollständig beenden.
2. Den Ordner „Pal“ aus diesem Archiv in den Palworld-Spielordner kopieren.
   Ordner zusammenführen, damit der Mod hier liegt:
   Pal/Binaries/Win64/ue4ss/Mods/M4Music/
3. Eigene MP3- und/oder WAV-Dateien direkt in diesen Ordner legen:
   Pal/Binaries/Win64/ue4ss/Mods/M4Music/Music/
4. Palworld starten und eine Spielwelt laden.
5. ESC öffnen und bei Bedarf den Optionen-Reiter auswählen.

Es wird keine zusätzliche PAK und kein PalSchema benötigt.
UE4SS selbst und Musikdateien sind in diesem Archiv nicht enthalten.

UPDATE VON EINER ÄLTEREN VERSION
- Spiel vollständig schließen und den bisherigen M4Music-Ordner sichern.
- Die neuen Programmdateien und den Ordner „Scripts“ übernehmen.
- Die eigene Settings.ini und den eigenen Music-Ordner behalten.
- Nicht den gesamten Modordner durch einen leeren Ordner ersetzen.
- Nach dem Update Palworld vollständig neu starten.

MUSIKORDNER
- MP3 und WAV können gemeinsam in einer Playlist liegen.
- Nur Dateien direkt im Music-Ordner werden eingelesen, keine Unterordner.
- Groß-/Kleinschreibung der Dateiendung spielt keine Rolle.
- Die Dateien werden direkt abgespielt; es werden keine WAV-Kopien erzeugt.
- Unterstützt werden Formate, die die Windows-Medienwiedergabe lesen kann.
  MP3 und PCM-WAV wurden getestet; unlesbare Dateien werden übersprungen.
- Dateien während des Spiels ergänzt? Eject-Symbol zum erneuten Einlesen drücken.

BEDIENUNG
- Play / Pause: Wiedergabe starten oder manuell pausieren.
- Vorheriger / nächster Titel: innerhalb der Playlist wechseln.
- Eject-Symbol: Musikordner neu einlesen. Öffnet kein externes Fenster.
- Gekreuzte Pfeile: Shuffle ein-/ausschalten.
- Positionsleiste: an eine andere Stelle des aktuellen Titels springen.
- Senkrechter Regler: eigene Musiklautstärke einstellen.
- Lange Titel laufen automatisch im begrenzten Titelfeld durch.

START UND KAMPF
- Standard: Shuffle an, Lautstärke 35 %, Wiedergabe an.
- Der erste Titel wird bei aktivem Shuffle zufällig gewählt. Wenn möglich,
  wird der Starttitel der vorherigen Sitzung vermieden.
- Nach Betreten der Welt etwa fünf Sekunden Startverzögerung,
  anschließend drei Sekunden Einblenden.
- Kampfbeginn: eigene Musik blendet über etwa 1,5 Sekunden aus,
  während die originale Spiel-/Kampfmusik freigegeben wird.
- Nach Ende des Kampfes folgt eine kurze Ruheprüfung; danach blendet
  die eigene Musik über drei Sekunden am pausierten Punkt wieder ein.
- Eine manuelle Pause bleibt auch nach einem Kampf erhalten.
- Friedliches Reiten zählt nicht allein als Kampf.
- Bei Weltwechsel oder fehlender Verbindung zum Spiel pausiert die Musik.
  Ein fehlender Spiel-Heartbeat wird nach etwa drei Sekunden erkannt.

COVER
- Eingebettete MP3-Cover aus ID3v2.2, ID3v2.3 und ID3v2.4 werden gelesen.
- Unterstützt werden eingebettete PNG-/JPEG-Bilder; Frontcover werden bevorzugt.
- Die Darstellung behält das Seitenverhältnis bei. Schwarze Ränder sind möglich.
- Ohne lesbares eingebettetes Bild bleibt „M4 Music“ als Platzhalter sichtbar.
- Externe cover.jpg-Dateien und WAV-Cover werden in dieser Version nicht gelesen.
- Kleine, automatisch erzeugte Bilder liegen im Ordner CoverCache.
  Original-Musikdateien werden nicht verändert.

EINSTELLUNGEN UND AUDIOSYSTEM
Settings.ini speichert volume (0–100), shuffle (0/1) und wanted (0/1).
Änderungen über den Player werden automatisch gespeichert. Die eigene Musik
hat eine separate Lautstärke; die gespeicherten Audiooptionen des Spiels
werden nicht überschrieben.

M4MusicHost.exe spielt die Musik in einem separaten, fensterlosen Prozess ab.
Scripts/M4MusicStart.dll startet ihn ohne CMD oder PowerShell. Der Prozess
beendet sich beim Schließen von Palworld. StartHost.ps1 ist nur ein optionaler
manueller Starter und wird vom normalen Modstart nicht aufgerufen.

DEAKTIVIEREN / ENTFERNEN
Palworld schließen. Zum Deaktivieren enabled.txt im M4Music-Ordner umbenennen.
Zum Entfernen zuerst eigene Musik und Settings.ini sichern, danach nur den
Ordner ue4ss/Mods/M4Music entfernen. Andere Mods und UE4SS bleiben erhalten.

HILFE
- Kein Player sichtbar: UE4SS-Installation und den vollständigen Modpfad prüfen;
  das Spiel nach Änderungen vollständig neu starten.
- Keine Titel: Dateiformat/Ordner prüfen und Eject zum erneuten Einlesen drücken.
- Bei Problemen: UE4SS.log nach „[M4 Music]“ durchsuchen.
- Weitere Diagnose: host.log, host-fatal.log oder launcher-error.txt im Modordner,
  sofern diese Dateien erzeugt wurden. Bei einem Crash auch den Crashbericht
  von Palworld aufbewahren.
- Zum Melden eines Problems Version, Ablauf, UE4SS.log und passende Host-Logs
  angeben. Eigene Musikdateien sind dafür normalerweise nicht erforderlich.

RELEASE-STAND
Die zuvor abgestimmten Funktionen und die Optik wurden im Spiel bestätigt;
die MP3/WAV-Erweiterung wurde zusätzlich mit echter Windows-Wiedergabe getestet.
Das Release-Paket übernimmt diese Programmdateien unverändert. Die Paketprüfung
ersetzt keinen Kompatibilitätstest auf anderen Spielständen oder Systemen.

SHA256SUMS.txt enthält Prüfsummen der Dateien dieses Pakets.
