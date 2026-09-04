# Was bisher geschah

Stand: 2026-09-04 — Phase 28d

## Portierungsstand

**Gesamtport: ca. 39 %**

Phase 28d ist ein reiner Regressionstest-Fix nach Phase 28c. Die Prozentzahl bleibt unveraendert, weil kein neuer Gameplayblock hinzugekommen ist.

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
- Die neue Sprunganimation wird angesprochen, erschien vor Phase 28c aber grafisch defekt.

## Phase 28 — echte Somersaultdaten

Die C64-Referenz benutzt beim normalen Sprung 12 Somersaultframes pro Richtung. `sault_l_spr` liegt bei `$5700-$59ff`, `sault_r_spr` bei `$5a00-$5cff`; jeder VIC-Slot ist 64 Byte gross, davon 63 sichtbare Bitmapbytes plus Padding.

`tools/monty_somersault_source.asm` enthaelt die festen Originalbloecke; `tools/monty_somersault.py` konvertiert sie in PCE-Spritedaten. `build.sh` erzeugt daraus `monty-sault-l.dat` und `monty-sault-r.dat`.

## Phase 28c — PCE-Sprite-Layout korrigiert

Der gemeinsame C64->PCE-Converter schreibt 32x32-Spritegruppen nun in der fuer die PCE benoetigten Reihenfolge `TL,TR,BL,BR` statt `TL,BL,TR,BR`. Ausserdem zeigt die rechte 16x32-Monty-Haelfte nun auf `MONTY_SPR_VRAM+64` VRAM-Woerter statt auf `+256`.

Diese Korrektur betrifft Walk, Climb und Somersault gleichermaßen.

## Phase 28d — versehentlich gekuerzte Jump-Testdaten repariert

Der erste lokale Build nach Phase 28c stoppte bereits im Python-Test mit:

`assert len(JUMP_UP)==22 and sum(JUMP_UP)==20`

Die Ursache war kein neuer Fehler in der eigentlichen Sprungphysik. Beim Umbau von `tools/test_port.py` fuer den Quadranten-Test war die lokale Kopie von `JUMP_UP` versehentlich von den korrekten 22 Eintraegen auf 18 Eintraege gekuerzt worden.

Die Testkonstante ist jetzt wieder identisch mit der bereits im Port verwendeten C64-Sprungkurve:

`0,3,2,2,1,2,1,1,0,1,1,1,0,1,1,1,0,1,0,1,0,0`

Damit gelten wieder exakt 22 Aufwaertsschritte mit einer Summe von 20 Pixeln. Der eigentliche Runtime-Code in `src/monty_physics.asm` wurde dabei nicht veraendert.

## Verifikationsstatus

- Phase 28d ist hochgeladen.
- Lokal erneut `git pull && ./build.sh` ausfuehren.
- Wenn der Build durchlaeuft, Walk links/rechts und besonders Sprung links/rechts visuell pruefen.
- Bewegung, Collision und Physik wurden in Phase 28d nicht angefasst.

## Naechste Portschritte

1. Phase 28d lokal bauen und Sprite-/Somersaultgrafik visuell pruefen.
2. Falls die Sprungframes weiterhin falsch aussehen: PCE-Patternadressierung und jede 16x16-Zelle eines Somersaultframes frameweise gegen die C64-Pixelmatrix pruefen, ohne weitere Heuristik.
3. Walk-/Climb-Rohdaten ebenfalls auf einen festen, adressbasierten Datenpfad umstellen.
4. Danach Room-$00-Decor und generischer Room-Loader.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen danach.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
