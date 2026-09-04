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
- 256x224-Modus, Palette, Font-Upload, BAT-Textausgabe und VSync-Schleife im Bring-up-Quelltext angelegt.
- VRAM-Aufteilung in `src/platform.inc` dokumentiert.

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

Geplante feste Abbildung:

- C64 32x20 Raum-Tilefeld -> PCE BAT-Zellen.
- C64 Tilecode/Room-Farbe -> PCE Pattern + Palette-Index.
- PCE BAT bleibt groesser als das sichtbare 32x28-Fenster, damit HUD und spaetere Scroll-/Randlogik getrennt bleiben.
- C64 Raumdaten werden nicht kuenstlerisch neu interpretiert, sondern deterministisch in PCE-Daten konvertiert.
- Gameplay-Takt wird von der Display-Framerate getrennt, damit PAL-Verhalten auf der PCE moeglichst erhalten bleibt.

## Aktueller Arbeitsschritt

1. C64-Raumformat vollstaendig dokumentieren.
2. Konverter fuer Tilemap-/Raumdaten definieren.
3. Raum `$00` als erste Referenz auf der PCE darstellen.
4. Danach Monty-Sprite und Pad-Eingabe.
5. Anschliessend Bewegung, Sprungkurve und Tile-Kollisionen gegen die C64-Routinen vergleichen.

## Noch nicht behauptet

- Es gibt noch keinen verifizierten spielbaren Monty-Port.
- Der ROM-Build wurde noch nicht auf dem Zielrechner des Projekts bestaetigt.
- Grafik-, Bewegungs- und Kollisionsgleichheit sind noch nicht erreicht.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/uli/huc
