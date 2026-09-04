# Was bisher geschah

Stand: 2026-09-04 — Phase 33d

## Portierungsstand

**Gesamtport: ca. 44 %**

Nach Phase 33/33b/33c trat eine schwere Gameplay-Regression auf: Monty startete falsch bzw. im Boden, sprang unplausibel hoch und fiel durch den Boden. Deshalb wurde der aktive Runtime-Pfad bewusst auf den zuletzt vom Nutzer bestaetigten Stand Phase 32b zurueckgesetzt. Korrektheit geht hier vor neuem Content.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Letzter sicher bestaetigter Runtime-Stand

Phase 32b wurde vom Nutzer praktisch bestaetigt:

- Monty startet an der brauchbaren C64-nahen Position.
- Gehen, Springen, Falling und Plattform-Landung funktionieren.
- Der Hauseingang in Raum $00 ist passierbar.
- Walk/Climb und die 12+12 Somersaultframes funktionieren visuell.
- Raum $00 -> $01 nach links funktioniert.
- Raum $01 -> $00 nach rechts funktioniert.
- Rechts neben Raum $00 liegt in der originalen Weltkarte `$ff`; dort gibt es keinen Zielraum.

## Phase 33 — Versuch Room-$01-Decor

Die zwei originalen Room-$01-Decors wurden als Daten/Generatoren portiert:

- Type `$42` `purple_flowers`
- Type `$41` `bunch_flower`

Die Generator- und Testdateien bleiben im Repository erhalten, sind nach dem Rollback aber nicht mehr Teil des aktiven Build-/Runtime-Pfads. Sie werden erst wieder zugeschaltet, wenn der Mehrraum-/Banking-Pfad ohne Gameplay-Regression abgesichert ist.

## Phase 33b/33c — verworfener Collision-RAM-Cache

Der Versuch, die aktive 640-Byte-Collision-Map und 8 Tile-Properties in einen neuen Work-RAM-Cache zu kopieren, hat die Regression nicht behoben und den Runtime-Zustand weiter destabilisiert. Der komplette Cache-Pfad wurde deshalb aus der aktiven Runtime entfernt.

Insbesondere wurden wieder auf den Phase-32b-Stand gesetzt:

- `src/main.asm`
- `src/monty_physics.asm`
- `src/room_loader.asm`
- `src/room01_assets.asm`
- `build.sh`
- `tools/test_room01.py`

Der Restore-Commit ist `0bc77d50c66d7766cc1a925cda1237a182396dcd`.

## Verifikationsstatus

Phase 33d ist bewusst ein Stabilitaets-Rollback auf den zuletzt bestaetigten Runtime-Code. Er wurde hier nicht lokal mit PCEAS ausgefuehrt. Als naechstes muss der Nutzer `git pull && ./build.sh` ausfuehren und zuerst nur Raum $00 testen: Startposition, Boden, normaler Sprung, Landung und Steuerung. Danach $00 -> $01 -> $00.

Wenn dieser bekannte Stand wieder korrekt laeuft, wird Room-$01-Decor nicht einfach erneut hineingeschoben. Stattdessen wird zuerst der ROM-/Room-Datenpfad so umgebaut, dass neue Daten keine bereits funktionierende Physics/Sprite-/Collision-Logik mehr verschieben oder beeinflussen koennen.

## Naechste Portschritte

1. Phase-32b-Runtime erneut visuell bestaetigen.
2. ROM-/Room-Datenlayout und Banking isoliert absichern, ohne Physics zu veraendern.
3. Danach die bereits vorhandenen Room-$01-Decor-Daten kontrolliert wieder aktivieren.
4. Erst danach Raum $02 und weitere Welt-Raeume anbinden.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen danach.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
