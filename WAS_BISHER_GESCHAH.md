# Was bisher geschah

Stand: 2026-09-04 — Phase 23a

## Portierungsstand

**Gesamtport: ca. 34 %**

Die Prozentzahl bleibt unveraendert: Phase 23a ist ein Build-/Regressionstest-Fix und noch kein neuer Gameplay-Block.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Ziel

1:1-orientierter Port von *Monty on the Run* (C64) auf NEC PC Engine / HuCard.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce`.
- Phase 22 baut und startet laut Nutzer.
- 320-Pixel-Anzeige ist sichtbar aktiv.
- Monty-Sprite ist sichtbar und in brauchbarer Form.
- Phase 23 konnte wegen eines Python-Regressionstests noch nicht assembliert werden.

## Phase 23 — RLE-/Collision-Korrektur

Die `refactored/src/subsystems/room.asm`-Referenz zeigt eindeutig: Der untere Nibble jedes Room-RLE-Bytes ist bereits der C64-Screen-Character-Code. `DrawRoomPlayfield` schreibt diesen Code unveraendert in den Scratchbuffer und danach auf den 40-Spalten-Screen. Code 0 bleibt leer; Codes 1..8 referenzieren die acht von `SetupTileGraphics` installierten Raumcharacters.

Der PCE-Generator verwendet deshalb keine pauschale `+1`-Transformation mehr. Gleichzeitig implementiert `room00_get_tile_property` die C64-`GetTileFlag`-Semantik: Screen-Code 0 und Codes >=9 sind Property 0, nur Codes 1..8 greifen auf `tile_property_tbl[code-1]` zu.

## Phase 23a — fehlerhaften WORLD-Test entfernt

Der aktuelle Build scheiterte vor PCEAS in `tools/test_port.py` an der statisch doppelt gepflegten Python-Kopie der 6x23-Weltkarte. Die eigentliche Assembly-Tabelle in `src/world.asm` ist weiterhin 6x23 und enthaelt den bekannten Start bei Raum $00 (Zeile 2, Spalte $15), links Raum $01 und rechts eine Wand.

Der Test pflegt diese Weltkarte jetzt nicht mehr als zweite handgeschriebene Konstante. Stattdessen liest er direkt `src/world.asm`, extrahiert `world_room_grid:` und prueft:

- exakt 6 Zeilen
- exakt 23 Eintraege pro Zeile
- Startzelle Raum $00
- linker Nachbar Raum $01
- rechter Nachbar $FF
- Raum $33 an der bekannten Position
- Completion-Raum $30 nicht im normalen Grid

Damit ist `src/world.asm` auch fuer den Test die einzige Quelle der Wahrheit.

## Verifikationsstatus

- Phase 23a Testfix: hochgeladen, lokal noch zu bauen.
- Phase 23 Screen-Code-/Collision-Fix: lokal noch zu testen.
- Bewegung/Walkanimation: lokal nach erfolgreichem Build erneut testen.
- Vollstaendige Room-$00-Dekoration: noch nicht portiert.

## Naechste Portschritte

1. Phase 23a lokal bauen.
2. Danach PCE/C64 erneut vergleichen und Links/Rechts/I testen.
3. Wenn die Basisgrafik nun stimmt, Room-$00-Decor aus `refactored/src` portieren.
4. `CheckTileBelow` Properties 2/3/4 exakt nachziehen.
5. Danach Somersaultframes, generischer Room-Loader, Gegner, Mechanismen, Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
