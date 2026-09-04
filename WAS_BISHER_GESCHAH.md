# Was bisher geschah

Stand: 2026-09-04 — Phase 24b

## Portierungsstand

**Gesamtport: ca. 35 %**

Die Prozentzahl bleibt unveraendert: Phase 24b ist ein konkreter Build-/Asset-Fix fuer die Spritekonvertierung, noch kein neuer Gameplay-Block.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce`.
- Die Basis-Raumgrafik stimmt laut Nutzer jetzt zunaechst brauchbar mit der C64-Referenz ueberein.
- Monty-Sprite ist sichtbar; die Collision gegen Waende reagiert plausibel.
- Phase 24 brachte einen Rueckschritt bei der Y-Position; der vorzeitige Fall-Proxy wurde in Phase 24a wieder entfernt.
- Der Build von Phase 24a scheiterte vor PCEAS in `tools/monty_sprite.py`, weil die transkribierte Walk-L-Konstante 249 statt 252 sichtbare Bytes enthaelt.

## Phase 24b — Sprite-Transkription robust normalisiert

Die verbindliche `refactored/src/subsystems/monty_spr.asm`-Referenz zeigt, dass Walk-L, Walk-R und Climb jeweils einen kompletten 256-Byte-VIC-Block belegen. Pro Frame sind davon 63 Bytes sichtbare Bitmapdaten plus ein ungenutztes Paddingbyte.

Die lokalen Python-Konstanten sind eine textuelle Transkription der sichtbaren Bytes. Bei der letzten Animation sind am Blockende einige ausschliesslich nullwertige Bytes nicht mittranskribiert worden. Das ist kein Grund, zwischen Frames Bytes einzuschieben: genau das hatte zuvor die Animation zerstoert.

`tools/monty_sprite.py` macht deshalb jetzt nur Folgendes:

- einen echten 256-Byte-Rohblock als vier 64-Byte-Slots lesen und jeweils das 64. Paddingbyte entfernen;
- eine bereits sichtbare Folge bis 252 Bytes unveraendert lassen und ausschliesslich fehlende **trailing zero bytes am Ende des letzten Frames** bis auf 252 Bytes auffuellen;
- bei mehr als 8 fehlenden Bytes abbrechen, damit echte Transkriptionsfehler nicht verdeckt werden;
- niemals mehr innerhalb der 4x63 sichtbaren Framefolge kuenstlich Padding einfuegen.

Damit sollte der aktuelle `unexpected C64 sprite block length: 249`-Fehler verschwinden, ohne erneut Frames 1..3 um ein Byte zu verschieben.

## Positionsstatus

`src/monty_physics.asm` bleibt auf dem Phase-23a-Verhalten ohne den vorzeitigen `monty_falling`-Proxy. Die originalen Startwerte bleiben `monty_x=$86`, `monty_y=$b0`. Der echte C64-Fallzustand wird erst zusammen mit der exakten `CheckTileBelow`-/`monty_action`-/`monty_jumping_flag2`-Semantik portiert.

## Verifikationsstatus

- Phase-24b Sprite-Normalisierung: hochgeladen, lokal noch zu bauen.
- Startposition nach Rollback: lokal erneut zu pruefen.
- Walkframes: nach erfolgreichem Build visuell zu pruefen.
- Collision gegen Seitenwaende scheint laut Nutzer grundsaetzlich zu funktionieren.
- Das Mauerloch bleibt bis zur exakten vertikalen Collision-/Fallsemantik offen.

## Naechste Portschritte

1. Phase 24b lokal bauen und Startposition + Walkframes testen.
2. `CheckTileBelow` fuer Properties 1/2/3/4 exakt aus `refactored/src` portieren.
3. Danach den echten C64-Fallzustand (`monty_jumping_flag2`) ohne Proxy einsetzen und das Mauerloch testen.
4. Anschliessend 12+12 Somersaultframes sowie Room-$00-Decor.
5. Danach generischer Room-Loader, Gegner, Mechanismen, Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
