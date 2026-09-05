# Was bisher geschah

Stand: 2026-09-05 — Phase 46

## Portierungsstand

**Gesamtport: ca. 60 %**

Primaere Referenz bleibt `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` ist zusaetzliche Ground-Truth. Die PC-Engine-Portierung verwendet weiterhin C64-Spielkoordinaten, PAL-logische Ticks und einen gemeinsamen 648-Byte-RAM-Collision-Cache fuer banked Tail-Raeume.

## Lokal bestaetigter Runtime-Stand

- PCEAS baut den Port wieder fehlerfrei.
- Raum `$00/$01`: Gehen, Springen, Landen und Animationen funktionieren.
- Raum `$01`: Original-Decors aktiv.
- Raum `$02`: spielbar, fuenf Original-Decors aktiv; Mechanismen wie Piledriver fehlen noch.
- Raum `$03`: spielbar und lokal bestaetigt.
- Unterer Hausweg bis `$04` funktioniert inzwischen praktisch:

`$01 DOWN -> $0A LEFT -> $0B LEFT -> $0E LEFT -> $0D UP -> $04`

- Fallen aus `$01` nach `$0A` funktioniert.
- Rueckweg `$0A UP -> $01` funktioniert nach Korrektur der Room-$01-Kletterproperties.
- Oben rechts wird dauerhaft die aktuelle Raum-ID zweistellig hexadezimal angezeigt (`00`, `01`, `0A`, ...). Das bleibt fuer die weitere Portierung aktiv.

## Wichtige Fixes seit Phase 44

### PCEAS Branch Range

Der gewachsene `world_resolve_exit` hatte einen `BRA .blocked` ausserhalb der signed-8-bit-Reichweite. Der entfernte Sprung ist seit Phase 44b ein absoluter `JMP`; ein Regressionstest pinnt das fest.

### Room-$0D-RLE

Im Room-$0D-Stream fehlte ein `$f0`-Run. Der exakte C64-Stream hat dort fuenf aufeinanderfolgende `$f0`-Bytes und dekodiert auf 640 Zellen.

### Freeze beim Fallen aus Room `$01`

Das war kein gewollter Zustand: unter `$01` liegt laut originaler 6x23-Weltkarte Room `$0A`. Solange `$0A` nicht geladen werden konnte, pendelte Monty am unteren Rand zwischen Y=$D9/$DA. Phase 45 aktivierte deshalb `$0A/$0B` und den echten unteren Hausweg.

### Rueckweg `$0A -> $01`

Beim ersten Runtime-Test flackerte `$01` kurz auf und Monty fiel sofort nach `$0A` zurueck. Der Decompile-Abgleich zeigte einen alten Portierungsfehler in Room `$01`: Tile-IDs `$63` und `$64` liegen im C64-Bereich `$56-$76` und muessen Property 3 haben. Im Port standen sie auf 0.

Korrekte Room-$01-Properties:

`1,3,1,1,2,1,4,3`

Nach dieser Korrektur ist der Aufstieg `$0A UP -> $01` lokal bestaetigt.

## Phase 46 — Room `$05` und `$0C`

Der naechste originale Weltabschnitt ist:

`$04 LEFT -> $05 DOWN -> $0C`

Die Weltkarte hat `$05` auf Zeile 2 / Spalte $10, direkt links von `$04`; darunter auf Zeile 3 liegt `$0C`. Die Room-$05-Geometrie besitzt unten einen echten Durchstieg, daher werden beide Raeume gemeinsam aktiviert.

### Room `$05`

- RLE: 122 Bytes -> exakt 640 Zellen
- Tile-IDs: `$01,$41,$2b,$65,$67,$00,$3f,$63`
- Farben: `$01,$05,$03,$04,$07,$0d,$02,$03`
- Properties: `1,2,2,3,3,1,2,3`

### Room `$0C`

- RLE: 91 Bytes -> exakt 640 Zellen
- Tile-IDs: `$05,$0f,$10,$28,$6a,$5f,$4f,$00`
- Farben: `$0d,$05,$07,$03,$05,$02,$02,$00`
- Properties: `1,1,1,2,3,3,4,1`

Die Properties wurden erneut direkt gegen `Monty.SetTileProperty` geprueft. Beide Raeume brauchen keine neuen BG-Paletten; alle Farben sind bereits vorhanden.

## Phase-46-Architektur

`room_loader.asm` bleibt bewusst unveraendert, weil dieser Pfad fuer die bisher aktiven Raeume bereits lokal bestaetigt ist. Statt ihn weiter wachsen zu lassen, liegt fuer `$05/$0C` jetzt `src/room050c_loader.asm` davor:

- behandelt Pending Room `$05` und `$0C` selbst,
- faellt fuer alle aelteren Raeume per `JMP room_load_pending` auf den bestaetigten Loader zurueck,
- verwendet dieselben gemeinsamen Routinen fuer Pattern-Upload, 36x20-BAT-Draw und 648-Byte-Collision-Cache.

Der alte Jump-Guard, der `$04 LEFT` absichtlich blockierte solange `$05` nicht geladen war, ist entfernt. Der echte Aussenrand `$00 RIGHT` bleibt vorab gesperrt; weitere nicht portierte Ziele blockiert `world_resolve_exit` selbst.

## Neue/aktualisierte Phase-46-Tests

- `tools/test_room050c.py` — exakte RLE/Tile/Property-Daten, Weltpositionen, Loader-Extension und offene `$04->$05`-Kante
- `tools/test_vertical_route.py` — untere Route bis `$05->$0C`
- `tools/test_collision_banking.py` — `$05/$0C` im gemeinsamen RAM-Cache
- `tools/test_jump_edge_guard.py` — `$04->$05` darf nicht wieder vorab blockiert werden
- `tools/test_room02.py` — Edge-Test wieder topology-agnostisch
- `tools/test_room01.py` — neuer Loader-Dispatcher faellt korrekt auf den bestaetigten alten Loader zurueck

`build.sh` erzeugt jetzt auch `room05-*.dat` und `room0c-*.dat` und fuehrt `test_room050c.py` vor PCEAS aus.

## Erwarteter lokaler Test fuer Phase 46

Nach:

`git pull && ./build.sh`

soll zusaetzlich erscheinen:

`OK: exact Room 05/0C assets + $04->$05->$0C continuation wiring`

Danach in Mednafen den bestaetigten Weg bis `$04` laufen und weiter testen:

1. `$04` nach links -> Debug-ID muss auf `05` wechseln und dort bleiben.
2. In `$05` Gehen, Springen, Collision und Rueckweg rechts -> `$04` testen.
3. Den unteren Durchstieg in `$05` finden und nach `$0C` fallen; Debug-ID muss `0C` anzeigen.
4. Falls ein Aufstieg `$0C -> $05` moeglich ist, ebenfalls testen und auf Flackern/sofortigen Rueckfall achten.
5. In `$0C` noch nicht erwarten, dass Gegner, Decors oder alle Mechanismen vorhanden sind.

Die Weltkarte verzweigt von `$0C` weiter nach `$0F` (links), `$11` (unten) und `$0D` (rechts). Welcher dieser Zweige als naechstes portiert wird, wird nach dem Runtime-Test von `$05/$0C` entschieden.

## Noch fehlend / spaeter

- Decors fuer viele neu aktive Raeume
- Piledriver/Zerstampfer und weitere Room-Mechanismen
- Gegner
- Items/Sammelobjekte
- HUD/Gameflow/Leben/Tod
- Musik und SFX

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
