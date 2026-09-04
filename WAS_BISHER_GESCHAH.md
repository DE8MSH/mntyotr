# Was bisher geschah

Stand: 2026-09-04 — Phase 33b

## Portierungsstand

**Gesamtport: ca. 45 %**

Phase 32b ist vom Nutzer bestaetigt: Raum $00 -> $01 nach links funktioniert, und aus Raum $01 kommt Monty nach rechts wieder korrekt in Raum $00 zurueck. Phase 33 portierte die zwei Original-Decors fuer Raum $01. Nach dem dadurch gewachsenen ROM meldete der Nutzer eine neue schwere Regression: Monty faellt fortlaufend von oben nach unten durchs Bild und ist waehrenddessen nicht steuerbar.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce`.
- Raum $00 Basisgrafik und alle neun statischen Decor-Records sind sichtbar.
- Raumwechsel $00 -> $01 und Rueckweg $01 -> $00 funktionieren grundsaetzlich.
- 12+12 Somersaultframes sowie Walk/Climb laufen ueber bankfeste ROM-Uploads.
- Room-$01-RLE, Tiles, Farben, Properties und beide Decor-Records werden von den Python-Regressionstests exakt geprueft.

## Phase 33 — Original-Decors fuer Raum $01

Die C64-`Decor.room_list` enthaelt fuer Raum $01 exakt zwei statische Records:

- `$01,$03,$11,$42` — Type 66 `purple_flowers`, 4x4 Zeichen
- `$01,$1d,$07,$41` — Type 65 `bunch_flower`, 3x3 Zeichen

`tools/room01_decor.py` portiert beide direkt aus `refactored/src/subsystems/decor_data.asm` inklusive Bitmap- und Farbstroemen.

## Phase 33a — PCEAS Reichweitenfix

Der erste lokale Phase-33-Build stoppte nach erfolgreichen Python-Tests an einem zu weit entfernten `BSR room01_draw_native`. Alle drei Room-$01-Aufrufe wurden deshalb auf absolute `JSR` umgestellt. Diese Aenderung betraf nur Assembler-Reichweite.

## Phase 33b — Collision aus banked ROM in stabiles Work-RAM

Nach Phase 33a startete das ROM, aber Monty fiel dauerhaft durchs Bild. Die Ursache ist strukturell dieselbe Fehlerklasse, die zuvor die Spritegrafik beschaedigt hatte: die Collision-Routinen lasen `room00_collision_map`, `room01_collision_map` und die Tile-Property-Tabellen direkt ueber ROM-Adressen. Durch weiteres ROM-Wachstum koennen diese Daten in andere HuCard-Banks wandern, waehrend die per-frame Physics keine passende MPR-Umschaltung durchfuehrt. Dann liest `CheckTileBelow` falsche/zufaellige Bytes, erkennt keinen Boden und bleibt im unsupported-fall-Pfad; dieser kehrt vor der normalen Eingabebehandlung zurueck, weshalb Monty waehrend des Falls praktisch unsteuerbar erscheint.

Phase 33b entfernt diese Abhaengigkeit komplett:

- `src/room_loader.asm` reserviert 640 Byte Work-RAM fuer die aktive 32x20 Collision-Map und 8 Byte fuer die aktive C64-Tile-Property-Tabelle.
- `room_collision_load_pending` mappt die jeweilige ROM-Quelle bankfest mit `map_bp_to_mpr34` und kopiert Map + Properties in RAM.
- Das passiert beim Start fuer Raum $00 und bei jedem Raumwechsel fuer $00/$01.
- `src/monty_physics.asm` liest per-frame nur noch `room_collision_map_ram` und `room_tile_properties_ram`; direkte ROM-Pointer auf die Raum-Collision-Daten sind dort entfernt.
- Damit kann weiteres ROM-Wachstum die Boden-/Wandcollision nicht mehr durch Bankverschiebung zerstoeren.

Neu ist `tools/test_collision_ram.py`. Er sichert ab, dass Physics nicht wieder auf direkte ROM-Collision-Pointer zurueckfaellt und dass Startup/Roomloader den RAM-Cache benutzen. `tools/test_room01.py` wurde an diese bankfeste Architektur angepasst; `build.sh` fuehrt den neuen Test automatisch aus.

## Verifikationsstatus

- Die dauerhafte Fall-Regression ist vom Nutzer auf dem Phase-33a-ROM gemeldet.
- Phase 33b ist hochgeladen, aber noch nicht lokal mit dem Nutzer-PCEAS gebaut.
- Als naechstes `git pull && ./build.sh`.
- Danach zuerst Start in Raum $00 pruefen: Monty muss wieder auf dem Boden landen und steuerbar sein.
- Danach $00 -> $01, dort Boden/Plattformen/Gehen/Springen pruefen und wieder nach $00 zurueck.
- Die neuen Raum-$01-Decors bleiben aktiv; Sprite-/Jump-Code wurde in Phase 33b nicht veraendert.

## Naechste Portschritte

1. Phase 33b lokal bauen und die wiederhergestellte Collision/Steuerung bestaetigen.
2. Danach Raum $02 mit exaktem RLE, room_defs-Tileset, Farben, Collision und Decor in denselben Loader aufnehmen.
3. Die temporaere Loader-Schranke auf `$00..$02` erweitern.
4. Den Room-Loader weiter verallgemeinern.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen auf dem Mehrraum-Unterbau.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
