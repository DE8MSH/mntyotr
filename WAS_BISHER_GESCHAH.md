# Was bisher geschah

Stand: 2026-09-05 — Phase 47

## Portierungsstand

**Gesamtport: ca. 61 %**

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
- Oben rechts wird dauerhaft die aktuelle Raum-ID zweistellig hexadezimal angezeigt (`00`, `01`, `0A`, ...).

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

Die Properties wurden direkt gegen `Monty.SetTileProperty` geprueft. Beide Raeume brauchen keine neuen BG-Paletten; alle Farben sind bereits vorhanden.

## Phase-46-Architektur

`room_loader.asm` bleibt bewusst unveraendert, weil dieser Pfad fuer die bisher aktiven Raeume bereits lokal bestaetigt ist. Statt ihn weiter wachsen zu lassen, liegt fuer `$05/$0C` jetzt `src/room050c_loader.asm` davor:

- behandelt Pending Room `$05` und `$0C` selbst,
- faellt fuer alle aelteren Raeume per `JMP room_load_pending` auf den bestaetigten Loader zurueck,
- verwendet dieselben gemeinsamen Routinen fuer Pattern-Upload, 36x20-BAT-Draw und 648-Byte-Collision-Cache.

Der alte Jump-Guard, der `$04 LEFT` absichtlich blockierte solange `$05` nicht geladen war, ist entfernt. Der echte Aussenrand `$00 RIGHT` bleibt vorab gesperrt; weitere nicht portierte Ziele blockiert `world_resolve_exit` selbst.

## Phase 47 — Room `$02` Runtime-Befund

Der Nutzer meldete, dass man aus Room `$02` nicht auf die hoeheren Bereiche kommt. Der Abgleich mit der C64-Referenz zeigt, dass dies **kein zu niedriger PCE-Sprung** ist:

- `Monty.Data.jump_arc_tbl` hat im Original exakt dieselbe Aufwaertskurve wie der Port.
- Die Summe der positiven Aufwaerts-Deltas betraegt 20 Pixel.
- Room `$02` besitzt in der exakten C64-RLE eine massive zentrale Wand, die den rechten und linken Bereich weitgehend trennt.
- Rechts liegt eine Property-3-Kletterflaeche, aber sie macht die Mittelwand nicht zu einem direkten `$01 -> $03`-Durchgang.
- Fuer Room `$02` existiert kein Jetpack-/Freedom-Kit-Raumeffekt, der die normale Sprunghoehe veraendert.

Daher wird die Sprunghoehe **nicht** kuenstlich erhoeht. Der derzeitige Hauptfortschritt bleibt der bereits bestaetigte untere Weg aus `$01`. `tools/test_room02.py` pinnt jetzt die zentrale Solid-Geometrie, die rechte Kletterflaeche und die originale 20-Pixel-Sprungkurve fest.

## Phase 47 — permanente Build-/Debug-Anzeige

Die bisherige Raumnummer oben rechts bleibt erhalten und wurde erweitert:

- oben links: **7-stellige Git-Commit-ID** des ROM-Builds,
- oben rechts: aktuelle zweistellige Hex-Raumnummer,
- unten links: **`A thE rZA PCE port`**.

Die Commit-ID wird nicht manuell gepflegt. `build.sh` fuehrt `git rev-parse --short=7 HEAD` aus, wandelt die sieben Hex-Zeichen in Nibble-Bytes um und schreibt `build/build-commit.dat`. `debug_room.asm` bindet diese sieben Nibbles ein und rendert sie mit dem reservierten Diagnose-Font. Damit identifiziert jedes lokal gebaute ROM exakt seinen Git-Stand.

Der Overlay-Font belegt 32 der bereits reservierten 112 Diagnose-Glyphen unterhalb von `CHR_GAME`; Raumgrafiken ueberschreiben ihn nicht. Die Commit-ID liegt in BAT-Zeile 0 links, die Room-ID in Zeile 0 rechts und die Signatur in der letzten sichtbaren Zeile 27 links.

## Phase-47-Commits

- `7c9c6fb355f954c98ae050fc989480b64e275475` — Commit-ID und Port-Signatur in Debug-Overlay
- `26af5b1a42ee3804af5b5108699cabc505c8c808` — Git-Short-SHA automatisch in ROM-Build einbetten
- `4e9ffae09f9a66c172c998b9ab0dd5620655673c` — Overlay-Regressionstest erweitert
- `86ffdcd0191ebbcba1a687b35bfaf33066dd47c3` — Room-$02`-Geometrie/Sprungkurve als Regression aufgenommen
- `26b03f66d9ca4d374be9dc0b386241dfb7474403` — Room-$02-Wandspalten im Test korrigiert

## Erwarteter lokaler Test fuer Phase 47

Nach:

`git pull && ./build.sh`

soll im Build eine Zeile wie

`ROM commit overlay: ABC1234`

erscheinen. Im Emulator muessen danach gleichzeitig sichtbar sein:

- oben links dieselbe 7-stellige Commit-ID,
- oben rechts die aktuelle Room-ID,
- unten links `A thE rZA PCE port`.

Fuer den Spielweg nicht versuchen, Room `$02` durch eine kuenstlich hoeher gedachte Sprungpassage nach links zu verlassen. Stattdessen aus `$01` in den unteren Weg wechseln und von dort bis `$04`, `$05` und `$0C` weitertesten.

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
