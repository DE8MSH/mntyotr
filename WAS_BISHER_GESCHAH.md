# Was bisher geschah

Stand: 2026-09-04 — Phase 22

## Portierungsstand

**Gesamtport: ca. 33 %**

Die Prozentzahl steigt nur leicht: diesmal wurde kein neues Spielsystem erfunden, sondern eine zentrale falsche Bildschirm-/Koordinatenbasis durch die C64-Referenz ersetzt.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Ziel

1:1-orientierter Port von *Monty on the Run* (C64) auf NEC PC Engine / HuCard.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce`.
- PCE VDC/VCE Bring-up und PAL-orientierter Gameplay-Scheduler.
- Phase 21 baut laut Nutzer, aber der sichtbare Aufbau blieb falsch, Monty war wieder nicht sichtbar und Linksbewegung ging nur minimal.

## Phase 22 — 320-Pixel-Modus und echte C64-Koordinaten

Der wichtigste Fehler war nicht die Raum-RLE selbst, sondern die Displayinitialisierung: Der Port startete weiterhin mit `init_256x224` und schrieb danach nur HDR auf 40 Zeichen. Damit wurden 256-Pixel-Horizontal-Timings mit einer 320-Pixel-Anzeige vermischt. Phase 22 startet jetzt mit der vollstaendigen HuC-`init_352x224`-Initialisierung (7-MHz-Modus, 64x32 BAT, 224 Zeilen, SAT-DMA) und schaltet anschliessend HSR/HDR mit den HuC-Konstanten auf 320 Pixel. Damit entsprechen 40 C64-Zeichen exakt 320 sichtbaren PCE-Pixeln.

Aus `refactored/src/subsystems/sprites.asm` wurde ausserdem der bislang uebersehene entscheidende Schritt uebernommen: `Sprites.ProcessSprites` schreibt Montys VIC-X nicht direkt, sondern fuehrt vor dem VIC-Schreiben `ASL` aus. `monty_sprite_x2` ist also ein halbauflosender horizontaler Spielwert. Zusammen mit den Collision-Gleichungen ergibt sich exakt:

- sichtbares C64-Screen-X = `2 * (monty_x - $0c)`
- sichtbares C64-Screen-Y = `monty_y - $32`
- PCE-SAT-X = `2 * monty_x + 8`
- PCE-SAT-Y = `monty_y + 14`

Der PCE-Spritepfad schreibt X nun 9-bit-sicher inklusive High-Bit. Das ist fuer den Startwert `$86` zwingend: die korrekte PCE-SAT-X-Position ist 276 und passt nicht in acht Bit.

## Collision-Korrektur

Die Collision-Routinen aus der C64-Referenz liefern **40x25-Screenkoordinaten**. Der Port hatte diese Werte bisher faelschlich direkt als Indizes in die 32x20-RLE-Karte benutzt. Das erklaert die praktisch sofort blockierte Bewegung.

`room00_get_tile_xy` bildet jetzt die C64-Screenkoordinaten auf die RLE-Geometrie ab:

- Screen-Zeilen 3..22 -> Raum-Zeilen 0..19
- Screen-Spalten 4..35 -> Raum-Spalten 0..31
- Gutters 2..3 spiegeln Raum-Spalte 0
- Gutters 36..37 spiegeln Raum-Spalte 31
- ausserhalb dieses Bereichs ist fuer den aktuellen Raum-Collision-Stand leer

Damit benutzen Renderer, Spriteposition und Collision erstmals dasselbe C64-Screenmodell.

## Regressionstests

`tools/test_port.py` prueft jetzt zusaetzlich die Koordinatenbruecke. Fuer den Originalstart `$86,$b0` ergibt sie sichtbare C64-Screenkoordinate `(244,126)` und PCE-SAT `(276,190)`. Ausserdem werden Playfield- und Gutter-Screenkoordinaten gegen die 32x20-Raumkarte getestet.

## Verifikationsstatus

- Host-Toolchain/startendes ROM: bestaetigt.
- Phase-22 Build: **noch lokal zu testen**.
- 320x224 Timing: implementiert, noch im Emulator zu bestaetigen.
- Sprite-X/Y-Bruecke: direkt aus `refactored/src` abgeleitet, noch visuell zu bestaetigen.
- Collision-Screen->Room: implementiert, Bewegung erneut zu testen.
- Sprite-Grafikformat selbst bleibt unter Beobachtung, falls Monty nach der Koordinatenkorrektur weiterhin unsichtbar/falsch ist.

## Naechste Portschritte

1. Phase 22 lokal bauen und Screenshot pruefen.
2. Links/Rechts/I testen; bei verbleibendem Spritefehler SAT/Pattern-Daten separat mit festem Referenzframe verifizieren.
3. Danach `CheckTileBelow` Properties 2/3/4 exakt nachziehen.
4. Danach Somersaultframes und generischer Room-Loader.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen anschliessend.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
