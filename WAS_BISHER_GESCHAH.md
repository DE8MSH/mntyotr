# Was bisher geschah

Stand: 2026-09-04

Dieses Dokument wird bei den weiteren Portierungsschritten mitgepflegt.

## Ziel

1:1-orientierter Port von *Monty on the Run* (C64) auf NEC PC Engine / HuCard. Referenz fuer das Verhalten ist die kommentierte/refaktorierte 6502-Rekonstruktion von Dave-Agent. Prioritaet: Gameplay, Raumgeometrie, Bewegung und Kollisionen; Musik/SFX folgen spaeter.

## Bereits umgesetzt

- GitHub-Projekt initialisiert.
- Linux-Mint-22-Toolchain-Skripte angelegt.
- HuC/PCEAS als Assembler-Toolchain festgelegt.
- Build-/Run-/Makefile-Grundgeruest angelegt.
- PCEAS-Aufruf korrigiert.
- HuC CORE(not TM)-Startup eingebunden.
- PC-Engine VDC/VCE Bring-up begonnen.
- Palette, Font-Upload, BAT-Textausgabe und VSync-Schleife angelegt.
- VRAM-Aufteilung in `src/platform.inc` dokumentiert.
- C64-Raumformat in `docs/ROOM_FORMAT.md` dokumentiert.
- C64-Videogeometrie geprueft und in `docs/VIDEO_MODE.md` dokumentiert.
- PCE-Bring-up von 256 Pixel Zielbreite auf **320 Pixel** umgestellt.
- 40-Zeichen/320-Pixel Diagnoseruler fuer Emulator-/Hardwaretest eingebaut.

## Video-Erkenntnis

Der normale aktive VIC-II-Bildbereich des C64 ist **320x200 Pixel = 40x25 Zeichen zu 8x8 Pixeln**. Beim PAL-C64 (6569) besteht ein Frame insgesamt aus 312 Rasterzeilen und laeuft mit etwa 50,12 Hz; die analogen Border-/Overscan-Abmessungen sind nicht identisch mit der 320x200 Spielmatrix.

Fuer den Port gilt deshalb ab jetzt:

- C64-Spielkoordinaten bleiben 320x200.
- PCE-Ausgabe wird 320x224.
- Das C64-Bild wird ohne horizontale Skalierung abgebildet.
- Die 200 C64-Zeilen werden mit 12 Zeilen Padding oben und unten in 224 PCE-Zeilen eingebettet.
- PCE VDC HDW=$27 -> 40 Tiles -> 320 aktive Pixel.
- PCE VCE PCC=01 -> 7,159-MHz-Pixeltakt fuer den breiteren Modus.
- Exakte horizontale Porch-/Zentrierwerte werden nach Emulator-/Echthardwaretest festgeschrieben.

## Erkenntnisse aus der C64-Referenz

- Die Welt besteht aus einem 6x23 Navigationsraster; `$FF` bedeutet keine Raumverbindung.
- Raum `$30` ist der Abschlussraum und wird nicht ueber das normale Navigationsraster betreten.
- Es gibt 52 regulaer indizierte Raum-Tilemaps (`$00` bis `$33`).
- Die Raumdarstellung ist 32 Tiles breit; die C64-Routine zeichnet das Spielfeld in ein 40-Zeichen-Screenlayout und erzeugt seitliche Gutters.
- Der sichtbare Spielbereich umfasst 20 Raumzeilen.
- Tilecodes 1..8 erhalten ihre Farbe aus einer raumspezifischen 8-Eintrag-Farbtabelle; weitere Codes sind Sonder-/Animationszeichen.
- Pro Raum existieren separate Pointer fuer Tilemap und Enemy-Spawn-Daten.
- Enemy-Spawn-Streams bestehen aus 7-Byte-Records und enden mit `$FF`; maximal vier Enemy-Slots werden verwendet.
- Sektornamen werden ueber eine Room-ID-zu-Sektor-Tabelle ausgewaehlt.

## PC-Engine-Abbildung

- C64 32x20 Raum-Tilefeld -> PCE BAT-Zellen innerhalb des 40x25 C64-Canvas.
- C64 Tilecode/Room-Farbe -> PCE Pattern + Palette-Index.
- Logische C64-Tile-IDs bleiben separat erhalten; Kollisionen arbeiten nicht auf PCE-Grafiknummern.
- C64 Raumdaten werden deterministisch konvertiert, nicht kuenstlerisch neu interpretiert.
- Gameplay-Takt wird von der Display-Framerate getrennt. Ziel ist ein PAL-Logiktakt von ca. 50,12 Hz auf dem PCE-VBlank-Takt.

## Aktueller Arbeitsschritt

1. 320-Pixel-Videomodus in Emulator und spaeter echter Hardware verifizieren.
2. Exakte PCE HSR/HDR Porch-Werte festschreiben.
3. Raum `$00` dekodieren und als erstes echtes Monty-Bild darstellen.
4. Monty-Sprite und Pad-Eingabe.
5. Bewegung, Sprungkurve und Tile-Kollisionen gegen die C64-Routinen vergleichen.
6. PAL-50,12-Hz-Logik-Scheduler einbauen.

## Noch nicht behauptet

- Es gibt noch keinen verifizierten spielbaren Monty-Port.
- Der ROM-Build wurde noch nicht auf dem Zielrechner des Projekts bestaetigt.
- Der neue 320-Pixel-Modus braucht noch Emulator-/Hardwareverifikation der Porch-Werte.
- Grafik-, Bewegungs- und Kollisionsgleichheit sind noch nicht erreicht.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/uli/huc
