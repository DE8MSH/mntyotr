# Was bisher geschah

Stand: 2026-09-04 — Phase 20a

## Portierungsstand

**Gesamtport: ca. 32 %**

Die Prozentzahl bezeichnet den Anteil des fuer einen spielbaren 1:1-orientierten PCE-Port benoetigten Systems. Sicht-/Input-Reparaturen erhoehen den Stand noch nicht.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`. Diese Version ist die editierbare, subsystem-orientierte KickAssembler-Rekonstruktion und laut Upstream funktional identisch zum Original. `byte-perfect` wird nur als zusaetzliche Ground-Truth fuer Originaladressen/Opcodefragen herangezogen. PCE-spezifische Anpassungen duerfen Hardwaredetails aendern, nicht aber Spielregeln, Raumdaten oder Animationslogik ohne dokumentierten Grund.

## Ziel

1:1-orientierter Port von *Monty on the Run* (C64) auf NEC PC Engine / HuCard.

## Bereits umgesetzt

- Linux-Mint-22 Toolchain/Build/Run-Grundgeruest; GitHub-Actions-ROM-Build bleibt entfernt.
- PCE VDC/VCE Bring-up, Palette, BAT und VSync.
- PAL-orientierter Gameplay-Scheduler.
- Montys Sprungkurve, PCE-Pad, horizontale Bewegung, Step-Gate und erste Tile-Kollision.
- C64-Raumkanten und statisches 6x23-Weltgrid.
- Echte Monty-Walkgrafik fuer beide Blickrichtungen.
- Echte Monty-Climbgrafik und deren Gameplay-Auswahl.

## Phase 18i — erster erfolgreicher ROM-Build

Vom Nutzer am 2026-09-04 bestaetigt: `./build.sh` erzeugt erfolgreich eine startende `.pce`; Toolchain, Regressionstests, PCEAS und ROM-Start sind end-to-end bestaetigt.

## Phase 20 — sichtbare C64-Paritaet zuerst

Room-Character-Off-by-one, Sprite-Palette und PCE-SAT-X-Offset wurden korrigiert. Der folgende Nutzerscreenshot bestaetigte: Monty ist nun sichtbar und Raum $00 ist wesentlich plausibler aufgebaut. Er zeigte aber auch zwei neue konkrete Fehler: Monty sieht zusammengedrueckt/geduckt aus und Padbewegung reagiert nicht sichtbar.

## Phase 20a — Sprite-Layout und Pad-Bring-up

1. **Monty-Spriteformat:** Der C64-Pixeldecoder selbst liefert 24x21 Pixel. Der PCE-Konverter schrieb die vier Bitplanes eines 16x16-Sprite-Cells jedoch als vier komplette serielle Ebenen. Native PCE-Spritepatterns speichern die Ebenen paarweise/interleaved (0/1 je Scanline, danach 2/3). `tools/monty_sprite.py` erzeugt dieses Layout jetzt explizit. Das soll den im Screenshot zusammengedrueckten Monty beheben.
2. **Pad-Polling:** `bare-startup.asm` liest Pads im VBLANK bereits automatisch. Fuer den Bring-up wird `read_joypads` jetzt zusaetzlich unmittelbar nach `wait_vsync` aufgerufen, damit `joynow` garantiert direkt vor dem PAL-Gameplay-Gate frisch ist. Die verwendeten Bits bleiben die HuC-Werte I=$01, UP=$10, RIGHT=$20, DOWN=$40, LEFT=$80.

Beide Aenderungen muessen jetzt im lokalen Emulator verifiziert werden. Falls Pad danach weiterhin keine sichtbare Bewegung ergibt, ist als naechstes nicht das Padformat, sondern die aktuelle C64-Screen-zu-32x20-Collision-Abbildung zu korrigieren.

## Verifikationsstatus

- HuC/PCEAS Host-Toolchain: bestaetigt.
- Startendes `.pce`: bestaetigt.
- Phase-20-Raumdarstellung: Screenshot bestaetigt, aber noch nicht 1:1 gegen C64.
- Monty sichtbar: bestaetigt.
- Monty korrekt geformt: Phase 20a zu testen.
- Pad/Bewegung: Phase 20a zu testen.

## Aktuell offen

- Phase 20a bauen und Screenshot + Links/Rechts/I testen.
- C64 `DrawRoomPlayfield`, `CreatePlayfieldBorder`, `PopulateColourRam` und PCE-BAT-Ausgabe gegeneinander verifizieren.
- Collision-Abbildung zwischen C64-40-Spalten-Screenkoordinaten und logischem 32x20-Raum exakt verifizieren.
- Danach 12+12 Somersault-/Jumpframes, generischer Room-Loader, Gegner, Mechanismen, Special Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
