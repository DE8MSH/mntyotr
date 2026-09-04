# Was bisher geschah

Stand: 2026-09-04 — Phase 23

## Portierungsstand

**Gesamtport: ca. 34 %**

Der Stand steigt um einen Punkt, weil diesmal zwei zentrale Referenzfehler korrigiert wurden, die sowohl die sichtbare Raumgrafik als auch die Bewegung blockierten.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Ziel

1:1-orientierter Port von *Monty on the Run* (C64) auf NEC PC Engine / HuCard.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce`.
- Phase 22 baut und startet laut Nutzer.
- 320-Pixel-Anzeige ist sichtbar aktiv.
- Monty-Sprite ist jetzt sichtbar und in brauchbarer Form.
- Der Nutzervergleich PCE vs. C64 zeigt weiterhin falsche Raumgrafik, nur eine minimale Linksbewegung und noch keine sichtbare Walkanimation.

## Phase 23 — entscheidender RLE-/Collision-Fehler gefunden

Die `refactored/src/subsystems/room.asm`-Referenz zeigt eindeutig: Der untere Nibble jedes Room-RLE-Bytes ist bereits der **C64-Screen-Character-Code**. `DrawRoomPlayfield` schreibt diesen Code unveraendert in den 32x20-Scratchbuffer und danach auf den 40-Spalten-Screen. `SetupTileGraphics` ist ein separater Schritt und installiert die acht raumspezifischen Bitmaptiles in C64-Characters 1..8.

Der bisherige PCE-Generator hatte diese beiden Ebenen vermischt und zu jedem RLE-Wert noch `+1` addiert. Dadurch wurde insbesondere der extrem wichtige Screen-Code 0 (schwarz/leer) zu Character 1 und damit zu einem sichtbaren, soliden Raumtile. Genau deshalb war der PCE-Screenshot grossflaechig mit dem gelb/gruenen Pattern gefuellt, wo die C64-Referenz schwarzen Hintergrund zeigt.

`tools/room_rle.py` bildet RLE-Codes jetzt 1:1 ab:

- Code 0 -> Blank-Character 0 / Palette 0
- Codes 1..8 -> die von `SetupTileGraphics` installierten Raumcharacters 1..8
- keine pauschale `+1`-Transformation mehr

## Phase 23 — Bewegung ebenfalls erklaert

Der gleiche Screen-Code-Fehler steckte in der Collision. Das C64-`GetTileFlag` behandelt Screen-Code 0 und Codes >=9 als Property 0; nur Codes 1..8 greifen auf `tile_property_tbl[code-1]` zu.

Der PCE-Port hatte dagegen Code 0 direkt als Property-Slot 0 ausgewertet. In Raum $00 ist Slot 0 Property 1 (solid). Damit war **schwarzer Leerraum fuer die PCE-Collision massiv**. Das passt exakt zur Nutzerbeobachtung: Monty konnte einmal minimal nach links und wurde danach praktisch sofort blockiert.

`room00_get_tile_property` implementiert jetzt die C64-Semantik:

- 0 -> leer/non-solid
- 1..8 -> `room00_tile_properties[code-1]`
- >=9 -> fuer den aktuellen Raumtile-Pfad Property 0

Die bereits in Phase 22 korrigierte 40x25-Screen->32x20-Raumabbildung bleibt bestehen.

## Regressionstests

`tools/test_port.py` prueft jetzt ausdruecklich:

- ein RLE-Code 0 bleibt PCE-Character/Palette 0
- alle Playfieldcodes werden ohne +1 in die BAT uebernommen
- `GetTileFlag`-Modell: 0->0, 1->Property Slot0, 4->Property Slot3, 9->0
- 36-Spalten-Gutters und C64/PCE-Koordinatenbruecke bleiben erhalten

## Was im C64-Vergleich noch fehlt

Der neue Fix betrifft die **Basisraumgrafik**. Der C64-Screenshot enthaelt zusaetzlich Dekorationen und Objekte, die nicht Teil der simplen Room-RLE sind: z. B. `MPL ST.`-Schild, Fenster, Pflanzen, Spezialitem/Gegner und die Strassenlaterne. Diese stammen aus weiteren Subsystemen (`decor`, enemies/special items/mechanisms) und werden nach der jetzt korrigierten Basisgeometrie portiert.

## Verifikationsstatus

- Host-Toolchain/startendes ROM: bestaetigt.
- Phase-22 Sprite sichtbar: bestaetigt.
- Phase-23 Screen-Code-Fix: lokal noch zu bauen/testen.
- Bewegung nach GetTileFlag-Fix: lokal noch zu testen.
- Walkanimation sollte erst sichtbar werden, wenn horizontale Bewegung mehrere Ticks frei durchlaeuft; ebenfalls lokal zu testen.
- Vollstaendige Room-$00-Dekoration: noch nicht portiert.

## Naechste Portschritte

1. Phase 23 lokal bauen und PCE/C64 erneut vergleichen.
2. Wenn Bewegung jetzt frei laeuft: Walkanimation visuell pruefen und ggf. SAT/Framewechsel separat fixen.
3. Room-$00-Decor aus `refactored/src` portieren, damit Schild/Fenster/Pflanzen etc. erscheinen.
4. `CheckTileBelow` Properties 2/3/4 exakt nachziehen.
5. Danach Somersaultframes, generischer Room-Loader, Gegner, Mechanismen, Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
