# Was bisher geschah

Stand: 2026-09-04 — Phase 28c

## Portierungsstand

**Gesamtport: ca. 39 %**

Phase 28c behebt einen PCE-spezifischen Sprite-Layoutfehler, der besonders bei der neuen Somersault-Animation sichtbar wurde. Die Prozentzahl bleibt unveraendert, weil es sich um eine Korrektur des bereits portierten Animationsblocks handelt.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce` aus den vorigen Phasen.
- Die Basis-Raumgrafik stimmt laut Nutzer brauchbar mit der C64-Referenz ueberein.
- Montys Start-/SAT-Position passt inzwischen weitgehend.
- Gehen funktioniert.
- Springen funktioniert.
- Unsupported Falling funktioniert.
- Landen auf Plattformen funktioniert.
- Die Hauswandoeffnung in Raum $00 ist passierbar.
- Phase 28b baut bis PCEAS; die neue Sprunganimation wird angesprochen, erscheint laut Nutzer aber grafisch defekt.

## Phase 28 — echte Somersaultdaten

Die C64-Referenz benutzt beim normalen Sprung nicht die vier Walkframes. `UpdateState` waehlt bei JumpRight die Spritepointer `$68-$73` und bei JumpLeft `$5c-$67`, also jeweils 12 Frames; der Bewegungsticker wird bei 11 gekappt.

Die originalen Rohdaten wurden direkt aus `refactored/src/subsystems/monty_spr.asm` uebernommen:

- `sault_l_spr`: `$5700-$59ff`, 12 x 64 Byte
- `sault_r_spr`: `$5a00-$5cff`, 12 x 64 Byte
- pro VIC-Slot: 63 sichtbare Bitmapbytes + 1 unbenutztes Slotbyte

`tools/monty_somersault_source.asm` enthaelt diese festen Bloecke; `tools/monty_somersault.py` konvertiert sie in PCE-Spritedaten. `build.sh` erzeugt `monty-sault-l.dat` und `monty-sault-r.dat`.

## Phase 28a/28b — Buildfixes

Phase 28a korrigierte eine falsche Testannahme an der letzten VIC-Framegrenze. Phase 28b ersetzte zu lange relative HuC6280-Branches im 12-Wege-Dispatcher durch absolute `JMP`, damit PCEAS den Somersault-Code assemblieren kann.

## Phase 28c — echter PCE-16x32-Layoutfehler gefunden

Der Nutzer bestaetigte danach, dass die Sprunganimation zwar angesprochen wird, aber grafisch falsch/defekt erscheint. Die Ursache lag nicht mehr in den C64-Somersaultdaten, sondern in unserem PCE-Sprite-Layout.

Monty ist 24x21 Pixel gross und wird auf der PCE aus zwei 16x32-SAT-Sprites zusammengesetzt. Der PCE-VDC behandelt ein 16x32-Sprite als eine Haelfte einer ausgerichteten 32x32-Pattern-Gruppe. Eine 32x32-Gruppe besteht aus vier 16x16-Zellen in der VRAM-Reihenfolge:

- TL = oben links
- TR = oben rechts
- BL = unten links
- BR = unten rechts

Unser Converter hatte bisher x-major geschrieben: `TL, BL, TR, BR`. Das ist fuer den VDC falsch. Hardwareseitig holt ein 16x32-Sprite seine obere und untere Zelle entsprechend der 32x32-Gruppenstruktur, wodurch beim Animieren falsche Quadranten miteinander kombiniert wurden.

`tools/monty_sprite.py` schreibt deshalb jetzt korrekt `TL, TR, BL, BR`. Diese Aenderung gilt automatisch fuer Walk, Climb und Somersault, weil alle denselben C64->PCE-Frameconverter benutzen.

Zusaetzlich war der SAT-Patternpointer der rechten Monty-Haelfte falsch. Ein 16x16-PCE-Spritepattern belegt 64 VRAM-Woerter. Die rechte 16x32-Haelfte der 32x32-Gruppe beginnt deshalb bei `MONTY_SPR_VRAM + 64` Woertern. Der bisherige Code benutzte `+256` und zeigte damit auf einen Bereich hinter dem aktuell hochgeladenen 512-Byte-Frame.

`src/monty_sprite.asm` verwendet fuer die rechte Haelfte jetzt `(MONTY_SPR_VRAM+64)>>5`.

## Regressionstests

`tools/test_port.py` besitzt jetzt einen echten Quadranten-Test: In einen synthetischen C64-Frame wird je ein Pixel in TL/TR/BL/BR gesetzt. Nach der PCE-Konvertierung muss jedes Pixel im passenden 128-Byte-16x16-Block wiederzufinden sein. Ausserdem wird statisch geprueft, dass der SAT-Code `+64` und nicht mehr `+256` verwendet.

Damit pruefen wir nun nicht mehr nur Dateigroessen und Framegrenzen, sondern auch die fuer 16x32-Sprites entscheidende PCE-VRAM-Geometrie.

## Verifikationsstatus

- Phase 28c ist hochgeladen.
- Lokal muss erneut `git pull && ./build.sh` ausgefuehrt werden.
- Danach besonders Walk links/rechts und Sprung links/rechts ansehen, weil derselbe Layoutfix alle Monty-Frames betrifft.
- Bewegung, Collision und Physik wurden in Phase 28c nicht geaendert.

## Naechste Portschritte

1. Phase 28c lokal bauen und Montys Walk-/Somersaultgrafik visuell pruefen.
2. Walk-/Climb-Rohdaten ebenfalls auf einen festen, adressbasierten Datenpfad ohne Prefix-Heuristik umstellen.
3. Room-$00-Decor aus `refactored/src/subsystems/decor.asm` und den Raumtabellen portieren.
4. Danach generischer Room-Loader und echte Raumwechsel.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen danach.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
