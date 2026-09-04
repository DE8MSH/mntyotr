# Was bisher geschah

Stand: 2026-09-04 — Phase 28

## Portierungsstand

**Gesamtport: ca. 39 %**

Phase 28 portiert den naechsten sichtbaren C64-Gameplayblock: Montys echte 12+12 Somersault-/Sprungframes und die zugehoerige Animationsauswahl. Die vom Nutzer bestaetigte Bewegungs-/Collision-Basis aus Phase 27 bleibt dabei unangetastet.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce`.
- Die Basis-Raumgrafik stimmt laut Nutzer brauchbar mit der C64-Referenz ueberein.
- Montys Start-/SAT-Position passt inzwischen weitgehend.
- Gehen funktioniert.
- Springen funktioniert.
- Unsupported Falling funktioniert.
- Landen auf Plattformen funktioniert.
- Die Hauswandoeffnung in Raum $00 ist passierbar.
- Die exakte optische Richtigkeit aller Animationsframes war vor Phase 28 noch nicht bestaetigt.

## Phase 28 — echte Somersaultdaten

Die C64-Referenz benutzt beim normalen Sprung nicht die vier Walkframes. `UpdateState` waehlt bei JumpRight die Spritepointer `$68-$73` und bei JumpLeft `$5c-$67`, also jeweils **12 Frames**. Der Bewegungsticker wird bei 11 gekappt.

Die originalen Rohdaten wurden deshalb direkt aus `refactored/src/subsystems/monty_spr.asm` uebernommen:

- `sault_l_spr`: `$5700-$59ff`, 12 x 64 Byte
- `sault_r_spr`: `$5a00-$5cff`, 12 x 64 Byte
- pro VIC-Slot: 63 sichtbare Bitmapbytes + 1 unbenutztes Slotbyte

Die Daten liegen im Zielprojekt jetzt separat in `tools/monty_somersault_source.asm`. Damit muessen die 12 Frames nicht ueber unsichere Prefix-Heuristiken rekonstruiert werden.

`tools/monty_somersault.py` liest die beiden festen 768-Byte-Bloecke, entfernt aus jedem 64-Byte-VIC-Slot nur das letzte Paddingbyte und nutzt denselben 24x21-C64 -> PCE-16x16-Spriteconverter wie Walk/Climb. `build.sh` erzeugt daraus `monty-sault-l.dat` und `monty-sault-r.dat` mit jeweils 12 x 512 Byte PCE-Spritedaten.

## Phase 28 — Jump-Animationszustand

`src/monty_sprite.asm` besitzt jetzt einen echten dritten Animationsmodus neben Walk und Climb:

- Mode 0: Walk, vier Frames
- Mode 1: Climb, vier Frames
- Mode 2: Jump/Somersault, zwoelf Frames

Beim Eintritt in einen normalen Jump wird Frame 0 geladen und der Timer auf 4 gesetzt. Danach wird alle vier logischen Gameplay-Ticks auf den naechsten Somersaultframe gewechselt. Frame 11 bleibt stehen, falls die physische Jump-Action laenger dauert. Das entspricht der C64-Logik, die `monty_movement_ticker` vor der Addition zum Spritepointer auf `$0b` begrenzt.

Die Blickrichtung entscheidet zwischen dem linken und rechten 12-Frame-Satz. Der separate unsupported-fall-Zustand ist weiterhin **keine** normale Jump-Action und wird deshalb nicht faelschlich als Somersault dargestellt.

Walk und Climb werden beim Modus- bzw. Richtungswechsel wieder auf Frame 0 synchronisiert. Ihre vier Frames laufen weiterhin mit Timer 4 und Walk wird nur bei echter Bewegung weitergeschaltet.

## Regressionstests

`tools/test_port.py` prueft jetzt zusaetzlich:

- beide Somersault-Rohbloecke sind exakt `12*64 = 768` Byte lang;
- erster und letzter Frame besitzen die bekannten Original-Startbytes;
- nach Entfernen der VIC-Paddingbytes entstehen exakt `12*63` sichtbare Bytes pro Richtung;
- die PCE-Konvertierung ergibt exakt `12*512 = 6144` Byte pro Richtung.

Damit ist die Sprunganimation jetzt wesentlich staerker gegen verschobene oder versehentlich verkuerzte Frames abgesichert als der fruehe Walk/Climb-Bring-up.

## Noch offen

- Phase 28 muss lokal gebaut und im Emulator visuell bestaetigt werden.
- Walk-L/R und Climb sollten danach noch einmal gegen die C64-Animation verglichen werden; deren alte Texttranskription ist weniger sauber als der jetzt feste Somersault-Datenpfad.
- Der Piledriver-Dispatcher fuer `action_counter=5` fehlt noch.
- Room-$00-Decor fehlt noch.
- Generischer Room-Loader, Gegner, Mechanismen, Items, HUD/Gameflow und Audio fehlen noch.

## Naechste Portschritte

1. Phase 28 lokal bauen und beim Springen pruefen, ob Monty jetzt sichtbar durch die 12 Somersaultphasen laeuft.
2. Walk-/Climb-Rohdaten ebenfalls auf einen festen, adressbasierten Datenpfad ohne Prefix-Heuristik umstellen.
3. Room-$00-Decor aus `refactored/src/subsystems/decor.asm` und den Raumtabellen portieren.
4. Danach generischer Room-Loader und echte Raumwechsel.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen danach.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
