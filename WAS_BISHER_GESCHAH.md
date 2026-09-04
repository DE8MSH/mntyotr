# Was bisher geschah

Stand: 2026-09-04 — Phase 28a

## Portierungsstand

**Gesamtport: ca. 39 %**

Phase 28a ist ein Build-/Regressionstest-Fix fuer Phase 28. Die Prozentzahl bleibt unveraendert, weil kein neuer Gameplayblock hinzukommt.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce`.
- Die Basis-Raumgrafik stimmt laut Nutzer brauchbar mit der C64-Referenz ueberein.
- Montys Start-/SAT-Position passt inzwischen weitgehend.
- Gehen funktioniert.
- Springen funktioniert.
- Unsupported Falling funktioniert.
- Landen auf Plattformen funktioniert.
- Die Hauswandoeffnung in Raum $00 ist passierbar.
- Die exakte optische Richtigkeit aller Animationsframes ist noch nicht abschliessend bestaetigt.

## Phase 28 — echte Somersaultdaten

Die C64-Referenz benutzt beim normalen Sprung nicht die vier Walkframes. `UpdateState` waehlt bei JumpRight die Spritepointer `$68-$73` und bei JumpLeft `$5c-$67`, also jeweils 12 Frames; der Bewegungsticker wird bei 11 gekappt.

Die originalen Rohdaten wurden direkt aus `refactored/src/subsystems/monty_spr.asm` uebernommen:

- `sault_l_spr`: `$5700-$59ff`, 12 x 64 Byte
- `sault_r_spr`: `$5a00-$5cff`, 12 x 64 Byte
- pro VIC-Slot: 63 sichtbare Bitmapbytes + 1 unbenutztes Slotbyte

`tools/monty_somersault_source.asm` enthaelt diese festen Bloecke; `tools/monty_somersault.py` konvertiert sie in PCE-Spritedaten. `build.sh` erzeugt `monty-sault-l.dat` und `monty-sault-r.dat`.

## Phase 28a — falsche letzte Frame-Prefix-Erwartung korrigiert

Der erste lokale Phase-28-Build stoppte in `tools/test_port.py`, bevor PCEAS gestartet wurde. Ursache war nicht der Somersault-Datenblock, sondern eine falsche Testannahme ueber den Beginn des jeweils letzten 64-Byte-VIC-Slots.

Bei festen VIC-Slots ist die Slotgrenze die Adresse selbst. Der letzte linke Frame beginnt bei `$59c0`, der letzte rechte bei `$5cc0`. Beide beginnen im Original mit mehreren Nullbytes. Der Test hatte stattdessen spaeter folgende erste Nicht-Null-Muster als vermeintlichen Frameanfang erwartet (`02 00 00` bzw. `00 80 00`). Dadurch schlug der Test trotz korrekt 768 Byte langer Rohbloecke fehl.

Der Regressionstest prueft jetzt die echten adressbasierten Slotstarts:

- `$59c0`: `00 00 00 02 00 00 ...`
- `$5cc0`: `00 00 00 00 80 ...`

Damit wird nicht mehr ein Grafikmuster mit einer Framegrenze verwechselt. Die eigentliche Phase-28-Somersaultanbindung bleibt unveraendert.

## Verifikationsstatus

- Phase 28a ist hochgeladen.
- Der Nutzer muss `git pull && ./build.sh` erneut ausfuehren.
- Der vorherige Lauf erreichte PCEAS nicht; die neue Somersault-ROM wurde deshalb noch nicht lokal getestet.
- Nach erfolgreichem Build sind besonders linke und rechte Sprunganimation visuell zu pruefen.

## Naechste Portschritte

1. Phase 28a lokal bauen und die 12-Frame-Somersaulte links/rechts im Emulator pruefen.
2. Walk-/Climb-Rohdaten ebenfalls auf einen festen, adressbasierten Datenpfad ohne Prefix-Heuristik umstellen.
3. Room-$00-Decor aus `refactored/src/subsystems/decor.asm` und den Raumtabellen portieren.
4. Danach generischer Room-Loader und echte Raumwechsel.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen danach.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
