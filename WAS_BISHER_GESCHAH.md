# Was bisher geschah

Stand: 2026-09-04 — Phase 25

## Portierungsstand

**Gesamtport: ca. 35 %**

Die Prozentzahl bleibt unveraendert: Phase 25 korrigiert die zentrale SAT-Koordinatenbruecke, fuegt aber noch keinen neuen Gameplay-Block hinzu.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce`.
- Die Basis-Raumgrafik stimmt laut Nutzer inzwischen brauchbar mit der C64-Referenz ueberein.
- Monty-Sprite ist sichtbar; Seitenwand-Collision reagiert plausibel.
- Nach Phase 24d steht Monty jedoch weit links unten statt an der C64-Startposition.

## Phase 25 — SAT-X-Highbit und SAT-Y korrigiert

Der Positionsfehler hatte zwei konkrete Ursachen in `src/monty_sprite.asm`.

Erstens ist Montys horizontale C64-Spielkoordinate intern halb aufgeloest; `Sprites.ProcessSprites` verdoppelt sie vor dem VIC-II. Fuer die PCE gilt deshalb weiterhin:

- sichtbares C64-X = `2 * (monty_x - $0c)`
- PCE SAT-X = `2 * monty_x + 8`

Beim Originalstart `monty_x=$86` ist SAT-X damit **276 = $0114**. Die bisherige HuC6280-Routine machte zwar `ASL`, loeschte danach aber mit `CLC` genau den Carry, der das 9. X-Bit enthielt. Dadurch wurde `$0114` effektiv als `$0014` geschrieben: Monty erschien ganz links. Phase 25 bewahrt den ASL-Carry und addiert auch einen eventuellen Carry des Offsets in das SAT-Highbyte. Fuer die rechte 16-Pixel-Haelfte gilt entsprechend `$0124`.

Zweitens war SAT-Y in Phase 24 versehentlich auf `monty_y+65` gesetzt. Das addierte die PCE-64-Pixel-SAT-Origin ein zweites Mal. Die korrekte Ableitung ist:

- sichtbares C64-Y = `(monty_y + 1) - $32`
- PCE SAT-Y = sichtbares Y + 64 = `monty_y + 15`

Beim Originalstart `monty_y=$b0` ergibt das **SAT-Y=191** statt 241. Damit sollte Monty wieder im eigentlichen Raum und nicht am unteren Bildschirmrand erscheinen.

## Regressionstest

`tools/test_port.py` prueft jetzt fuer den Originalstart explizit:

- sichtbares C64 `(244,127)`
- PCE SAT `(276,191)`
- linkes SAT-X als Low/High `($14,$01)`
- rechtes SAT-X als Low/High `($24,$01)`

Damit kann der konkrete Highbit-Wrap auf die linke Bildschirmkante nicht wieder unbemerkt eingefuehrt werden.

## Animationsstatus

Die Spriteframe-Rekonstruktion aus Phase 24d bleibt aktiv. Die Position muss zuerst visuell bestaetigt werden. Falls die Walkframes danach weiterhin falsch aussehen, wird als naechstes nicht mehr heuristisch an Prefixen gearbeitet, sondern die vier 64-Byte-VIC-Slots werden als explizite per-Frame-Referenzdaten aus `refactored/src/subsystems/monty_spr.asm` abgelegt und gegen die PCE-Ausgabe geprueft.

## Naechste Portschritte

1. Phase 25 lokal bauen und Original-Startposition visuell pruefen.
2. Walk-L/R-Animation visuell pruefen.
3. Falls Frames falsch bleiben: explizite VIC-Frames statt Heuristik.
4. Danach `CheckTileBelow` Properties 1/2/3/4 und echten Fallzustand portieren, damit das Mauerloch korrekt funktioniert.
5. Anschliessend Somersaultframes, Room-$00-Decor, generischer Room-Loader, Gegner, Mechanismen, Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
