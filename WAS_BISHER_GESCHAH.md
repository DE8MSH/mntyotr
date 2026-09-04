# Was bisher geschah

Stand: 2026-09-04 — Phase 14

## Portierungsstand

**Gesamtport: ca. 25 %**

Die Prozentzahl bezeichnet den Anteil des fuer einen spielbaren 1:1-orientierten PCE-Port benoetigten Systems. Sie steigt nur fuer konkret portierte bzw. verifizierte Subsysteme.

## Ziel

1:1-orientierter Port von *Monty on the Run* (C64) auf NEC PC Engine / HuCard. Referenz fuer Verhalten und Daten ist die kommentierte/refaktorierte 6502-Rekonstruktion von Dave-Agent.

## Bereits umgesetzt

- Linux-Mint-22-Toolchain-, Build- und Run-Grundgeruest; kein GitHub-Actions-ROM-Build mehr.
- PCE VDC/VCE Bring-up, Palette, Font, BAT und VSync.
- 320-Pixel-Ausgabe fuer die 320x200-C64-Spielmatrix vorbereitet.
- Raum `$00` auf 640 logische Zellen = 32x20 dekodiert und als native PCE-BAT-Daten erzeugt.
- Acht raumspezifische C64-Character-Bitmaps nach PCE-4bpp konvertiert und Paletten angelegt.
- PAL-orientierter Gameplay-Scheduler mit getrenntem VBlank/Gameplay-Takt.
- Montys originale Sprungkurve, PCE-Pad Links/Rechts + Button I/Fire, gespeicherte Sprungrichtung, C64-`ToggleStepGate` und erste Tile-Kollision.
- 16-Bit-Zugriff auf die komplette 640-Byte-Kollisionsmap.
- C64-Raumkanten/Hand-off-Koordinaten und Room-Exit-Signal.
- Vollstaendiges statisches C64-Weltgrid 6x23 plus Lookup/Exit-Resolver.
- Automatische Regressionstests fuer Raum, Jump-Arc, Scheduler und Weltgrid.

## Neu in Phase 14

### C64-Weltgrid nach HuC6280 portiert

`src/world.asm` enthaelt jetzt die 6x23-Navigationstabelle der C64-Rekonstruktion. `$ff` bleibt Wand/kein Raum. Die sechs Row-Offets `$00,$17,$2e,$45,$5c,$73` und der initiale C5-Rueckkehrwert `$33` an row 2/col 4 sind erhalten. Completion-Raum `$30` bleibt absichtlich ausserhalb der statischen Karte.

Der originale Startzustand ist jetzt ebenfalls uebernommen: Weltposition row 2 / col `$15`, Raum `$00`; Monty startet bei X=`$86`, Y=`$b0` und blickt links.

### Exit-Aufloesung angeschlossen

`world_resolve_exit` konsumiert `monty_room_exit`, verschiebt je nach Richtung Weltzeile/-spalte und prueft den Zielwert. Ein gueltiger Nachbar wird in `world_pending_room` abgelegt und mit `world_transition_ready=1` markiert. Ein `$ff`-Ziel blockiert den Uebergang und stellt Montys Kantenkoordinate wieder her.

Der Mainloop ruft den Resolver bereits nach Bewegung/Sprung auf. Der Zielraum wird jedoch noch **nicht** als aktiv committed: Solange nur Raum `$00` dekodiert/gerendert werden kann, darf dessen Kollisionsmap nicht faelschlich fuer Raum `$01` verwendet werden.

### Regression

`tools/test_port.py` prueft jetzt zusaetzlich 6x23-Geometrie, Startzelle `$00`, links davon Raum `$01`, rechts davon `$ff`, C5-Slot `$33` und dass `$30` nicht im statischen Grid vorkommt.

## Aktuell offen

- Generischer Raumdecoder/Room-State fuer alle Raum-IDs fehlt; bisher ist nur `$00` nativ vorhanden.
- Deshalb ist `world_pending_room` noch kein vollstaendig sichtbarer Raumwechsel.
- Monty ist noch nicht als PCE-Sprite sichtbar.
- DOWN/UP, Leiter-/Seil-Semantik und exakte Tile-State-Logik fehlen.
- Property-4/Piledriver-Nebenwirkung fehlt.
- 320px-Horizontalporches muessen im Emulator/Echthardware verifiziert werden.
- 5/6 ist weiterhin eine Bring-up-Approximation fuer PAL-Timing.
- Echte PCEAS-Verifikation erfolgt lokal, da die GitHub Action auf Wunsch entfernt wurde.

## Naechste harte Schritte

1. Raum `$01` und danach generischen C64-RLE-Raumdecoder/Room-State portieren.
2. `world_pending_room` an echten Raumdatenwechsel und Renderer anschliessen.
3. Montys C64-Spritedaten in PCE-SPR-4bpp konvertieren und SATB anschliessen.
4. Vollstaendige C64-Tile-State-/Leiter-/Seil-Logik portieren.
5. Gegner, Mechanismen, Special Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
