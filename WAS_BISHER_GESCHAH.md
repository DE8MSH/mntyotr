# Was bisher geschah

Stand: 2026-09-04 — Phase 28e

## Portierungsstand

**Gesamtport: ca. 39 %**

Phase 28e korrigiert den Datenzugriff der bereits portierten Sprunganimation. Die Prozentzahl bleibt unveraendert, bis die 12+12 Somersaultframes lokal visuell bestaetigt sind.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce`.
- Basis-Raumgrafik stimmt laut Nutzer brauchbar.
- Montys Start-/SAT-Position passt weitgehend.
- Gehen, Springen und unsupported Falling funktionieren.
- Landen auf Plattformen funktioniert.
- Die Hauswandoeffnung in Raum $00 ist passierbar.
- Nach Phase 28d wird die Jump-Animation angesprochen, ist laut Nutzer aber weiterhin grafisch defekt.

## Phase 28 — Original-Somersaultdaten

Die C64-Referenz benutzt 12 Somersaultframes pro Richtung. `sault_l_spr` liegt bei `$5700-$59ff`, `sault_r_spr` bei `$5a00-$5cff`; jeder VIC-Slot ist 64 Byte gross, davon 63 sichtbare Bitmapbytes plus Padding.

`tools/monty_somersault_source.asm` enthaelt die festen Originalbloecke. `tools/monty_somersault.py` wandelt jeden festen 64-Byte-Slot in ein PCE-Spriteframe um.

## Phase 28c — PCE-Spritegruppe

Der C64->PCE-Converter schreibt die 32x32-Gruppe als `TL,TR,BL,BR`. Die rechte 16x32-Monty-Haelfte zeigt auf `MONTY_SPR_VRAM+64` VRAM-Woerter. Diese Geometrie bleibt aktiv.

## Phase 28e — eigentliche Ursache des verbleibenden Jump-Grafikfehlers

Die neue Sprunganimation ist wesentlich groesser als Walk/Climb:

- Walk links: 2048 Byte PCE-Daten
- Walk rechts: 2048 Byte
- Climb: 2048 Byte
- Somersault links: 6144 Byte
- Somersault rechts: 6144 Byte

Damit liegen die Somersaultlabels hinter rund 6 KiB anderer Spritedaten und verteilen sich im ROM ueber mehrere 8-KiB-PCE-Banks.

Der bisherige Dispatcher benutzte fuer jeden Jumpframe direkt `TIA monty_sault_...,VDC_DL,512`. `TIA` besitzt aber keinen Far-Pointer-/Bankwechsel. Es liest nur die CPU-Adresse aus der aktuell gemappten ROM-Bank. Dadurch kann ein Label in einer anderen Bank zwar korrekt assembliert sein, zur Laufzeit aber Daten aus der falschen gemappten Bank liefern. Das passt zum beobachteten Fehlerbild: Bewegung/Sprung funktionieren, aber die neu hinzugekommenen grossen Jump-Grafikbloecke erscheinen defekt.

Phase 28e entfernt deshalb alle direkten `TIA monty_sault_*`-Transfers. Fuer jeden der 12 Frames pro Richtung gibt es jetzt compile-time Tabellen mit Lowbyte, Highbyte und `BANK(label)`.

`monty_upload_jump_frame` waehlt daraus den echten Far-Pointer. `monty_upload_far_512` verwendet anschliessend HuCs `map_bp_to_mpr34`: die Quellbank wird in MPR3 und die Folge-Bank in MPR4 eingeblendet. Danach werden exakt 512 Byte nach `MONTY_SPR_VRAM` geschrieben. Dadurch funktioniert auch ein einzelner Frame, der eine 8-KiB-ROM-Bankgrenze kreuzt. MPR3, MPR4 und Interruptstatus werden nach dem Transfer wiederhergestellt.

Walk/Climb bleiben vorerst beim bisherigen direkten Transfer, weil der aktuelle konkrete Fehler nur bei den spaeter liegenden Jumpframes sichtbar ist. Wenn Phase 28e bestaetigt ist, kann derselbe bankfeste Pfad anschliessend vereinheitlicht werden.

## Regressionstest

Neu ist `tools/test_sprite_banking.py`. Der Build bricht jetzt ab, falls:

- wieder ein direktes `TIA monty_sault_*` auftaucht,
- `map_bp_to_mpr34` aus dem Jump-Transfer verschwindet,
- nicht genau 12 `BANK(...)`-Eintraege je Richtung vorhanden sind,
- die Phase-28c-Patternadresse `MONTY_SPR_VRAM+64` verloren geht.

`build.sh` fuehrt diesen Test zusaetzlich zu `tools/test_port.py` aus.

## Verifikationsstatus

- Phase 28e ist hochgeladen, aber noch nicht lokal mit dem Nutzer-PCEAS gebaut.
- Als naechstes `git pull && ./build.sh`.
- Danach Sprung nach links und rechts visuell pruefen.
- Physik, Kollision, Startposition und Raumgrafik wurden in Phase 28e nicht veraendert.

## Naechste Portschritte

1. Phase 28e lokal bauen und Jump-L/R pruefen.
2. Bei bestaetigter Grafik Walk/Climb ebenfalls auf feste Original-Slots plus bankfesten Loader umstellen.
3. Danach Room-$00-Decor portieren.
4. Generischen Room-Loader und echte Raumwechsel anbinden.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen danach.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
