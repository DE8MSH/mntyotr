# Was bisher geschah

Stand: 2026-09-04

Dieses Dokument wird bei den weiteren Portierungsschritten mitgepflegt.

## Ziel

1:1-orientierter Port von *Monty on the Run* (C64) auf NEC PC Engine / HuCard. Referenz fuer das Verhalten ist die kommentierte/refaktorierte 6502-Rekonstruktion von Dave-Agent. Prioritaet: Gameplay, Raumgeometrie, Bewegung und Kollisionen; Musik/SFX folgen spaeter.

## Bereits umgesetzt

- GitHub-Projekt, Linux-Mint-22-Install-/Build-/Run-Skripte und Makefile angelegt.
- HuC/PCEAS + CORE(not TM)-Startup eingebunden.
- VDC/VCE-, Font-, BAT- und VSync-Bring-up angelegt.
- C64-Videogeometrie geprueft; Zielmodus ist 320x224 PCE fuer ein unskaliertes 320x200-C64-Canvas.
- 40-Zeichen-Diagnoseruler fuer den 320-Pixel-Modus eingebaut.
- C64-Raumformat und Videoentscheidungen dokumentiert.
- **Raum $00 RLE vollstaendig dekodiert und auf exakt 640 Zellen (32x20) verifiziert.**
- Die Raum-$00-Geometrie wird bereits im PCE-BAT an C64-Position Spalte 4 / Zeile 3 ausgegeben.
- Host-Verifier `tools/room_rle.py` implementiert; er versteht auch die Besonderheit, dass ein einzelnes `$FF` ein gueltiger 16x-Tile-$F`-Run ist und erst `$FF $FF` terminiert.
- Raumdefinition $00 analysiert: Tile-Library-Indizes `$0A,$0B,$01,$3A,$15,$00,$00,$00`; Farben `$09,$09,$02,$03,$0B,$00,$00,$00`.
- Die benoetigten originalen 8x8-C64-Character-Bitmaps fuer Raum $00 aus der rekonstruierten Tile-Library uebernommen.
- `tools/c64_to_pce.py` implementiert: C64-Hires-1bpp -> PCE-8x8-4bpp und C64-RGB -> PCE-VCE-9-bit.
- `src/room00_assets.asm` enthaelt jetzt acht native PCE-Patterns und acht raumspezifische BG-Paletten fuer Raum $00.
- ROM-Bring-up laedt diese Patterns bereits nach VRAM und die Paletten in die VCE.

## Video-Erkenntnis

Der normale aktive VIC-II-Bildbereich des C64 ist **320x200 Pixel = 40x25 Zeichen zu 8x8 Pixeln**. PAL laeuft mit rund 50,12 Hz. Der PCE-Port nutzt 320x224, damit C64-X-Koordinaten ohne Skalierung uebernommen werden koennen. VDC HDW=$27 ergibt 40 aktive Tiles. VCE PCC=01 waehlt den mittleren Pixeltakt. Exakte Porch-/Zentrierwerte bleiben bis zum Emulator-/Echthardwaretest als Bring-up-Werte markiert.

## Raum-$00-Erkenntnisse

- Komprimierter Stream: 90 Bytes inklusive `$FF $FF` Terminator.
- Dekodiert: exakt 640 logische Zellen = 32x20.
- Raum $00 benutzt in seiner statischen Tilemap nur die logischen Tile-IDs 0..5.
- Die C64-Raumdefinition waehlt fuer Slots 0..7 globale Tile-Library-Eintraege aus und besitzt parallel acht Vordergrundfarben.
- PCE-Abbildung: ein Pattern pro logischem Tile-Slot; Palette 0..7 entspricht Slot 0..7; Pixel 0 ist C64-Schwarz, Pixel 1 die jeweilige C64-Vordergrundfarbe.
- Damit bleiben Raumgeometrie, Character-Bitmap und per-Tile-Farbmodell voneinander getrennt und spaeter fuer Kollisionen reproduzierbar.

## PC-Engine-Abbildung

- C64 40x25 Screen-Canvas -> PCE 40 sichtbare 8-Pixel-Spalten.
- C64 32x20 Raum -> BAT bei Spalte 4 / Zeile 3.
- Logische C64-Tile-IDs bleiben die Gameplay-Wahrheit; BAT/Patternnummern sind nur Rendering.
- C64 1bpp Character -> PCE 4bpp Pattern mit Pixelwerten 0/1.
- C64 Vordergrundfarbe -> PCE Palette pro logischem Tile-Slot.
- Gameplay-Takt wird spaeter vom PCE-VBlank getrennt und auf PAL-Verhalten angenaehert.

## Aktueller Arbeitsschritt

1. BAT-Ausgabe von den momentanen Tile-ID-Diagnoseglyphen auf die bereits konvertierten echten Raum-$00-Patterns umstellen.
2. Build auf Linux Mint 22 / PCEAS verifizieren und alle Assemblerdetails korrigieren.
3. 320-Pixel-Horizontal-Timing in Geargrafx und echter Hardware pruefen.
4. Monty-Sprite-Daten und Startposition fuer Raum $00 portieren.
5. Pad-Eingabe, Links/Rechts und Animation.
6. Sprungkurve und Tile-Kollisionen routine-fuer-routine portieren.
7. PAL-Logik-Scheduler implementieren.
8. Enemy-Spawn-Records von Raum $00 portieren.

## Noch nicht behauptet

- Es gibt noch keinen verifizierten spielbaren Monty-Port.
- Der aktuelle ROM-Stand wurde in dieser Sitzung nicht mit einem lokal installierten PCEAS assembliert, weil die Ausfuehrungsumgebung keinen Netzwerkzugriff auf die Toolchain hat.
- Die konvertierten Raum-$00-Patterns sind im ROM integriert, die BAT-Zellen zeigen aber im aktuellen Zwischenstand noch Diagnoseglyphen statt der neuen Patterns.
- Porch-Werte, Monty-Bewegung, Kollisionen und Gegner sind noch nicht verifiziert.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
