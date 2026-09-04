# Was bisher geschah

Stand: 2026-09-04 — Phase 24d

## Portierungsstand

**Gesamtport: ca. 35 %**

Die Prozentzahl bleibt unveraendert: Phase 24d behebt einen weiteren Build-/Assetfehler in der Sprite-Rekonstruktion.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce`.
- Die Basis-Raumgrafik stimmt laut Nutzer inzwischen brauchbar mit der C64-Referenz ueberein.
- Monty-Sprite ist sichtbar; Seitenwand-Collision reagiert plausibel.
- Der vorzeitige Fall-Proxy aus Phase 24 wurde wieder entfernt; Startwerte bleiben `monty_x=$86`, `monty_y=$b0`.
- Phase 24c scheiterte vor PCEAS, weil der Climb-Prefix `07 80 00` nicht nur am Frameanfang, sondern auch innerhalb jedes Climb-Bitmaps vorkommt.

## Phase 24d — Climb-Framegrenzen robust erkannt

Die verbindliche `refactored/src/subsystems/monty_spr.asm`-Quelle zeigt die echten Climb-Slots bei `$5600/$5640/$5680/$56c0`. In der lokalen verkurzten Texttranskription liegen deren echten Startkandidaten bei etwa 60 Byte Abstand. Das Byte-Muster `07 80 00` kommt jedoch zusaetzlich sechs Bytes nach jedem echten Frameanfang als normale Grafikdaten vor. Deshalb war die Phase-24c-Regel "es muessen genau vier Prefix-Vorkommen existieren" falsch.

`tools/monty_sprite.py` sammelt jetzt zwar weiterhin alle Prefix-Kandidaten, akzeptiert aber nur Kandidaten, die mindestens 48 Bytes nach dem zuletzt akzeptierten Frameanfang liegen. Fuer Climb werden damit aus `[0,6,60,66,120,126,180,186]` die echten Starts `[0,60,120,180]`. Jedes so abgegrenzte Segment wird anschliessend nur am eigenen Ende mit Nullbytes auf 63 sichtbare VIC-Bitmapbytes ergaenzt.

Die Originalquelle bleibt die geometrische Wahrheit: vier 64-Byte-Slots pro Walk-/Climb-Animation, davon je 63 sichtbare Bitmapbytes plus ein ungenutztes Slotbyte.

## Verifikationsstatus

- Phase-24d Prefix-Filter: hochgeladen, lokal noch zu bauen.
- Startposition nach Rollback: lokal erneut zu pruefen.
- Walkframes: nach erfolgreichem Build visuell zu pruefen.
- Collision gegen Seitenwaende scheint laut Nutzer grundsaetzlich zu funktionieren.
- Das Mauerloch bleibt bis zur exakten vertikalen Collision-/Fallsemantik offen.

## Naechste Portschritte

1. Phase 24d lokal bauen und Startposition + Walkframes testen.
2. `CheckTileBelow` fuer Properties 1/2/3/4 exakt aus `refactored/src` portieren.
3. Danach den echten C64-Fallzustand (`monty_jumping_flag2`) ohne Proxy einsetzen und das Mauerloch testen.
4. Anschliessend 12+12 Somersaultframes sowie Room-$00-Decor.
5. Danach generischer Room-Loader, Gegner, Mechanismen, Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
