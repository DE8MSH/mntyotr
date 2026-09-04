# Was bisher geschah

Stand: 2026-09-04 — Phase 24c

## Portierungsstand

**Gesamtport: ca. 35 %**

Die Prozentzahl bleibt unveraendert: Phase 24c ist ein weiterer Asset-/Build-Fix und kein neuer Gameplay-Block.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce`.
- Die Basis-Raumgrafik stimmt laut Nutzer inzwischen brauchbar mit der C64-Referenz ueberein.
- Monty-Sprite ist sichtbar; Seitenwand-Collision reagiert plausibel.
- Der vorzeitige Fall-Proxy aus Phase 24 wurde wieder entfernt; Startwerte bleiben `monty_x=$86`, `monty_y=$b0`.
- Phase 24b scheiterte vor PCEAS, weil die lokale Climb-Transkription 14 sichtbare Nullbytes weniger als 4x63 enthielt.

## Phase 24c — Spriteframes nicht mehr ueber Gesamtlaenge rekonstruieren

Die verbindliche `refactored/src/subsystems/monty_spr.asm`-Quelle zeigt die echten VIC-Blockgrenzen: Walk-L liegt bei `$5400/$5440/$5480/$54c0`, Walk-R bei `$5500/$5540/$5580/$55c0`, Climb bei `$5600/$5640/$5680/$56c0`. Jeder Frame besitzt 63 sichtbare Bitmapbytes und ein ungenutztes Slotbyte.

Die lokale Texttranskription laesst bei mehreren Frames am Ende reine Nullfolgen weg. Deshalb war es falsch, fehlende Bytes nur am Ende des gesamten 4-Frame-Blocks anzufuegen oder eine maximale Gesamtfehlmenge anzunehmen.

`tools/monty_sprite.py` rekonstruiert jetzt **jeden Frame einzeln**:

- Walk-L-Frames werden an ihrem authentischen Prefix `02 00 00` erkannt;
- Walk-R an `00 40 00`;
- Climb an `07 80 00`;
- es muessen exakt vier Prefix-Vorkommen existieren, das erste an Offset 0;
- jedes Segment bis zum naechsten Prefix wird nur am eigenen Ende mit Nullbytes auf 63 sichtbare Bytes aufgefuellt;
- ein Segment >63 Bytes gilt als Fehler.

Damit werden ausgelassene trailing zero bytes dort restauriert, wo sie laut Originaladressierung tatsaechlich fehlen, ohne die nachfolgenden Frames zu verschieben. Der bestehende Regressionstest prueft weiterhin vier Frames pro Animation sowie die authentischen Startbytes jedes Frames.

## Verifikationsstatus

- Phase-24c Frame-Recovery: hochgeladen, lokal noch zu bauen.
- Startposition nach Rollback: lokal erneut zu pruefen.
- Walkframes: nach erfolgreichem Build visuell zu pruefen.
- Collision gegen Seitenwaende scheint laut Nutzer grundsaetzlich zu funktionieren.
- Das Mauerloch bleibt bis zur exakten vertikalen Collision-/Fallsemantik offen.

## Naechste Portschritte

1. Phase 24c lokal bauen und Startposition + Walkframes testen.
2. `CheckTileBelow` fuer Properties 1/2/3/4 exakt aus `refactored/src` portieren.
3. Danach den echten C64-Fallzustand (`monty_jumping_flag2`) ohne Proxy einsetzen und das Mauerloch testen.
4. Anschliessend 12+12 Somersaultframes sowie Room-$00-Decor.
5. Danach generischer Room-Loader, Gegner, Mechanismen, Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
