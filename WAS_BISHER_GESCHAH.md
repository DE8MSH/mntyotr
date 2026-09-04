# Was bisher geschah

Stand: 2026-09-04 — Phase 33c

## Portierungsstand

**Gesamtport: ca. 45 %**

Phase 32b ist vom Nutzer bestaetigt: Raum $00 -> $01 nach links funktioniert, und aus Raum $01 kommt Monty nach rechts wieder korrekt in Raum $00 zurueck. Phase 33 portierte die zwei Original-Decors fuer Raum $01. Danach trat eine schwere Collision-Regression auf: Monty fiel endlos durch den Boden und war waehrend des Fallzustands nicht steuerbar.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce`.
- Raum $00 Basisgrafik und alle neun statischen Decor-Records sind sichtbar.
- Raumwechsel $00 -> $01 und Rueckweg $01 -> $00 funktionieren grundsaetzlich.
- 12+12 Somersaultframes sowie Walk/Climb laufen ueber bankfeste ROM-Uploads.
- Room-$01-RLE, Tiles, Farben, Properties und beide Decor-Records werden durch Regressionstests geprueft.

## Phase 33 — Original-Decors fuer Raum $01

Die C64-`Decor.room_list` enthaelt fuer Raum $01 exakt zwei statische Records:

- `$01,$03,$11,$42` — Type 66 `purple_flowers`, 4x4 Zeichen
- `$01,$1d,$07,$41` — Type 65 `bunch_flower`, 3x3 Zeichen

`tools/room01_decor.py` portiert beide inklusive Bitmap- und Farbstroemen.

## Phase 33a — PCEAS Reichweitenfix

Der erste Phase-33-Build stoppte an einem zu weit entfernten `BSR room01_draw_native`. Die drei Room-$01-Aufrufe wurden auf absolute `JSR` umgestellt.

## Phase 33b — Collision-Cache in Work-RAM

Um per-frame direkte Zugriffe auf banked ROM zu vermeiden, wurde die aktive 640-Byte-Collision-Map plus 8 Tile-Properties beim Raumladen in Work-RAM kopiert. Die Physics liest seitdem nur diesen RAM-Cache.

Der Nutzer meldete jedoch nach Phase 33b weiterhin eine schwere Regression: Monty startet zu tief bzw. im Boden und faellt anschliessend endlos von oben nach unten durchs Bild; normale Steuerung ist dabei nicht moeglich.

## Phase 33c — eigentliche Ursache im Mapper-Aufruf

Die RAM-Cache-Idee war richtig, aber der erste Loader benutzte in den beiden Copy-Routinen `jsr map_bp_to_mpr34`. Das unterscheidet sich vom bereits bewaehrten Sprite-Far-Loader, der den HuC-Mapper explizit mit `call map_bp_to_mpr34` aufruft.

`map_bp_to_mpr34` ist eine HuC-Hilfsroutine, deren Erreichbarkeit selbst nicht von der aktuellen Codebank abhaengen darf. Ein normales `JSR` ist hier bei wachsendem ROM nicht robust. Wenn der Mapper nicht korrekt erreicht wird, bleibt `_bp` auf der falschen ROM-Abbildung, die RAM-Collision wird mit falschen Bytes gefuellt und `CheckTileBelow` erkennt dauerhaft keinen Boden.

Phase 33c korrigiert deshalb beide Collision-Copy-Pfade auf denselben bewaehrten Aufruf wie die Sprite- und Room-Grafikloader:

- `room_collision_copy640`: `call map_bp_to_mpr34`
- `room_collision_copy_props`: `call map_bp_to_mpr34`

`tools/test_collision_ram.py` verbietet jetzt explizit `jsr map_bp_to_mpr34` im Loader und verlangt die bankfesten `call`-Aufrufe.

## Verifikationsstatus

- Die Phase-33b-RAM-Cache-Version ist vom Nutzer als weiterhin defekt gemeldet.
- Phase 33c ist hochgeladen, aber noch nicht lokal mit dem Nutzer-PCEAS/Mednafen verifiziert.
- Als naechstes `git pull && ./build.sh`.
- Danach zuerst nur Raum $00 pruefen: Monty muss wieder korrekt auf dem Boden landen, stehen bleiben und steuerbar sein.
- Erst danach Raum $01 und Rueckweg testen.

## Naechste Portschritte

1. Phase 33c lokal verifizieren und die Collision/Steuerung wieder stabilisieren.
2. Danach Raum $02 mit exaktem RLE, room_defs-Tileset, Farben, Collision und Decor aufnehmen.
3. Die temporaere Loader-Schranke auf `$00..$02` erweitern.
4. Den Room-Loader weiter verallgemeinern.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
