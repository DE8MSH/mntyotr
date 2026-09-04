# Was bisher geschah

Stand: 2026-09-04 — Phase 24a

## Portierungsstand

**Gesamtport: ca. 35 %**

Die Prozentzahl bleibt unveraendert: Phase 24a korrigiert zwei falsche Bring-up-Entscheidungen, statt einen neuen Gameplay-Block hinzuzufuegen.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce`.
- Die Basis-Raumgrafik stimmt laut Nutzer jetzt zunaechst brauchbar mit der C64-Referenz ueberein.
- Monty-Sprite ist sichtbar; die Collision gegen Waende reagiert plausibel.
- Phase 24 brachte jedoch einen klaren Rueckschritt: Monty fiel nach dem Start bis ganz nach unten und stand nicht mehr an der originalen Startposition.
- Die Walk-Animationsframes waren weiterhin sichtbar defekt.

## Phase 24a — vorzeitigen Fall-Proxy wieder entfernt

Der in Phase 24 eingefuehrte `monty_falling`-Proxy war zu frueh. Zwar besitzt die C64-Referenz mit `monty_jumping_flag2` einen separaten Fallzustand, dieser haengt aber an der exakten `CheckTileBelow`-/Action-/Tile-State-Semantik. Unser aktuelles `CheckTileBelow` ist fuer Properties 2/3/4 noch nicht vollstaendig 1:1. Dadurch interpretierte der Proxy die Startposition faelschlich als ungestuetzt und liess Monty bis an den unteren Rand fallen.

`src/monty_physics.asm` ist deshalb auf den letzten stabilen Phase-23a-Zustand zurueckgesetzt. Damit gelten wieder die originalen Startwerte `monty_x=$86`, `monty_y=$b0`, ohne automatische Fallbewegung. Der echte Fallzustand wird erst wieder aktiviert, wenn `CheckTileBelow`, `monty_action` und `monty_jumping_flag2` gemeinsam portiert sind.

## Phase 24a — eigentlichen Animationsdatenfehler gefunden

Der sichtbare Framefehler lag im Converter `tools/monty_sprite.py`.

Die transkribierten Konstanten enthalten pro C64-Spriteframe genau die 63 sichtbaren Bitmapbytes. Die vier Frames einer Animation sind dort direkt als 4x63 Bytes aneinandergehaengt. Der Converter behandelte diesen 252-Byte-Block jedoch nachtraeglich wie vier 64-Byte-VIC-Slots, fuellte nur am Ende auf 256 Bytes auf und schnitt dann bei Offsets 0,64,128,192.

Damit war Frame 0 noch korrekt, aber Frames 1..3 jeweils um Bytes verschoben. Genau das passt zur Beobachtung, dass Monty selbst erkennbar ist, seine Animationsphasen aber kaputt aussehen.

Der Converter akzeptiert jetzt explizit zwei Formate:

- 4x63 Bytes: bereits normalisierte sichtbare Bitmapframes -> unveraendert benutzen
- 4x64 Bytes: roher VIC-Slotblock -> aus jedem Slot die ersten 63 Bitmapbytes nehmen

Andere Laengen gelten als Transkriptionsfehler. Die Regressionstests pruefen ausserdem fuer alle vier Frames die bekannten Startbytes aus `refactored/src/subsystems/monty_spr.asm`:

- Walk Left: `02 00 00`
- Walk Right: `00 40 00`
- Climb: `07 80 00`

Damit kann die bisherige ein-Byte-Verschiebung der Frames nicht unbemerkt zurueckkehren.

## Verifikationsstatus

- Phase-24a Positionsrollback: hochgeladen, lokal noch zu bauen.
- Framegrenzen Walk-L/R/Climb: im Converter und Regressionstest korrigiert, lokal noch visuell zu testen.
- Sprite-SAT-Y hat weiterhin das aus `Sprites.ProcessSprites` uebernommene +1.
- Collision gegen Seitenwaende scheint laut Nutzer grundsaetzlich zu funktionieren.
- Das Mauerloch bleibt noch separat zu pruefen; dafuer ist die exakte vertikale Collision-/Fallsemantik noch offen.

## Naechste Portschritte

1. Phase 24a lokal bauen und Startposition + Walkframes testen.
2. `CheckTileBelow` fuer Properties 1/2/3/4 exakt aus `refactored/src` portieren.
3. Danach den echten C64-Fallzustand (`monty_jumping_flag2`) ohne Proxy wieder einsetzen und das Mauerloch testen.
4. Anschliessend 12+12 Somersaultframes sowie Room-$00-Decor.
5. Danach generischer Room-Loader, Gegner, Mechanismen, Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
