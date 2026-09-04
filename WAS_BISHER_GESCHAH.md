# Was bisher geschah

Stand: 2026-09-04 — Phase 34e bestaetigt

## Portierungsstand

**Gesamtport: ca. 44 %**

Phase 34e ist vom Nutzer lokal im Emulator bestaetigt. Der stabile Phase-32b/34a-Runtime-Pfad bleibt intakt: Monty ist steuerbar, Springen und Animationen funktionieren, und die seitlichen Raumwechsel verhalten sich jetzt auch waehrend eines Sprungs korrekt.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigter Runtime-Stand

- Monty ist steuerbar.
- Gehen, Springen, Falling und Landung funktionieren.
- Walk/Climb und 12+12 Somersaultframes funktionieren visuell.
- Raum $00 -> $01 nach links funktioniert beim Gehen.
- Raum $00 -> $01 nach links funktioniert jetzt auch im Sprung dauerhaft.
- Raum $01 -> $00 nach rechts funktioniert.
- Rechts neben Raum $00 liegt im Original `$ff`; Heraus-Springen nach rechts ist blockiert.
- Die Phase-34-Decor-Reaktivierung bleibt vorerst verworfen, weil zusaetzliches ROM-Layout die noch nicht bankfeste direkte Collision-Datenadressierung verschieben kann.

## Phase 34d — unsupported Side-Exit waehrend Sprung blockiert

Raum $00 rechts und Raum $01 links werden waehrend eines Sprungs als aktuell nicht unterstuetzte Weltseiten abgefangen. Dadurch kann Monty nicht mehr rechts aus Raum $00 heraus-springen.

## Phase 34e — echten horizontalen Exit ueber `monty_jump_step` retten

`monty_update_input` kann waehrend des Sprungs bereits einen echten horizontalen Exit setzen. Der direkt folgende `monty_jump_step` ruft intern `monty_check_room_edges` auf, dessen Start `monty_room_exit` loescht. Phase 34e speichert deshalb einen bereits gesetzten echten Exit vor dem Jump-Step und stellt ihn danach wieder her. Rein synthetische Side-Exits aus der vertikalen Sprungbewegung werden weiterhin verworfen.

Collision-Map, Tile-Properties, Startposition, Sprungtabellen, World-Grid und Room-Loader wurden dabei nicht veraendert.

Commits Phase 34e:

- `f44049d69b1a8f6e2297cdfe7b264c85b9fae592` — echten Side-Exit ueber `monty_jump_step` bewahren
- `8746815830f580559867b6be7eea74f987c28764` — Regressionstest fuer Exit-Preservation
- `09b048e1812589f51c7451b4edc57a64b1953013` — Dokumentation Phase 34e

## Verifikationsstatus

**Phase 34e ist bestaetigt.**

Bestaetigt sind jetzt insbesondere:

1. Raum $00 rechts: kein Heraus-Springen.
2. Raum $00 links: Springen ueber den offenen Ausgang fuehrt korrekt und dauerhaft nach Raum $01.
3. Raum $00 links: Gehen fuehrt weiterhin nach Raum $01.
4. Raum $01 rechts: Rueckweg nach Raum $00 funktioniert.
5. Start, Boden, Sprung und Animationen bleiben korrekt.

## Naechste Portschritte

1. Collision-ROM-Banking des jetzt bestaetigten Pfads exakt analysieren und bankfest machen, ohne Sprung-/Start-/Collision-Semantik umzuschreiben.
2. Danach Room-$01-Decor wieder kontrolliert aktivieren.
3. Danach Raum $02 und weitere Welt-Raeume portieren.
4. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
