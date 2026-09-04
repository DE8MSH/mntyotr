# Was bisher geschah

Stand: 2026-09-04 — Phase 28b

## Portierungsstand

**Gesamtport: ca. 39 %**

Phase 28b ist ein reiner Assembler-/Buildfix fuer die neue Somersault-Anbindung. Die Prozentzahl bleibt unveraendert, weil kein neuer Gameplayblock hinzugekommen ist.

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
- Die exakte optische Richtigkeit aller Animationsframes ist noch nicht abschliessend bestaetigt.

## Phase 28 — echte Somersaultdaten

Die C64-Referenz benutzt beim normalen Sprung nicht die vier Walkframes. `UpdateState` waehlt bei JumpRight die Spritepointer `$68-$73` und bei JumpLeft `$5c-$67`, also jeweils 12 Frames; der Bewegungsticker wird bei 11 gekappt.

Die originalen Rohdaten wurden direkt aus `refactored/src/subsystems/monty_spr.asm` uebernommen:

- `sault_l_spr`: `$5700-$59ff`, 12 x 64 Byte
- `sault_r_spr`: `$5a00-$5cff`, 12 x 64 Byte
- pro VIC-Slot: 63 sichtbare Bitmapbytes + 1 unbenutztes Slotbyte

`tools/monty_somersault_source.asm` enthaelt diese festen Bloecke; `tools/monty_somersault.py` konvertiert sie in PCE-Spritedaten. `build.sh` erzeugt `monty-sault-l.dat` und `monty-sault-r.dat`.

## Phase 28a — letzte Framegrenze im Test korrigiert

Der erste Phase-28-Build stoppte in `tools/test_port.py`, bevor PCEAS gestartet wurde. Die Ursache war eine falsche Testannahme ueber die Startbytes der jeweils letzten 64-Byte-VIC-Slots. Der Test wurde auf die echten adressbasierten Slotgrenzen `$59c0` und `$5cc0` korrigiert.

## Phase 28b — HuC6280 Relative-Branch-Limit

Der naechste lokale Build erreichte PCEAS und alle Python-Regressionstests liefen erfolgreich durch. PCEAS meldete danach 13 Fehler `Branch address out of range` in `src/monty_sprite.asm`.

Ursache: Die neue 12-Wege-Somersault-Auswahl ist deutlich laenger als die bisherigen 4-Frame-Dispatcher. HuC6280-Branchbefehle wie `BMI` und `BRA` sind relativ und koennen nur Ziele innerhalb ihres begrenzten Offsets erreichen. Der Sprung von der Richtungspruefung bis zum linken 12-Frame-Block sowie mehrere `BRA .jdone` lagen ausserhalb dieses Bereichs.

Die Logik wurde nicht geaendert. Nur der Kontrollfluss wurde assemblerfest gemacht:

- statt eines langen `BMI .jump_left` wird lokal mit `BPL` verzweigt und fuer die entfernte linke Tabelle ein absolutes `JMP .jump_left` benutzt;
- die langen `BRA .jdone` der 12 Framepfade wurden durch absolute `JMP .jdone` ersetzt;
- kurze `BEQ`-Verzweigungen innerhalb der jeweiligen Dispatch-Tabelle bleiben relative Branches.

Damit bleiben Frameauswahl und C64-Semantik gleich, ohne das +/-128-Byte-Limit der relativen HuC6280-Branches zu verletzen.

## Verifikationsstatus

- Die Phase-28a-Python-Tests wurden vom Nutzer erfolgreich ausgefuehrt: `OK: room/world; exact collision/fall; SAT XY; walk/climb + 24 somersault frames`.
- Der anschliessende PCEAS-Lauf scheiterte ausschliesslich an den jetzt behobenen Branch-Reichweiten.
- Phase 28b ist hochgeladen und muss lokal erneut mit `./build.sh` gebaut werden.
- Danach sind besonders linke und rechte Sprunganimation visuell zu pruefen.

## Naechste Portschritte

1. Phase 28b lokal bauen und Somersault links/rechts im Emulator pruefen.
2. Walk-/Climb-Rohdaten ebenfalls auf einen festen, adressbasierten Datenpfad ohne Prefix-Heuristik umstellen.
3. Room-$00-Decor aus `refactored/src/subsystems/decor.asm` und den Raumtabellen portieren.
4. Danach generischer Room-Loader und echte Raumwechsel.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen danach.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
