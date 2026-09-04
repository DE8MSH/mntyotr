# Was bisher geschah

Stand: 2026-09-04 — Phase 19a

## Portierungsstand

**Gesamtport: ca. 34 %**

Die Prozentzahl bezeichnet den Anteil des fuer einen spielbaren 1:1-orientierten PCE-Port benoetigten Systems. Toolchain-/Buildfixes allein erhoehen sie nicht.

## Ziel

1:1-orientierter Port von *Monty on the Run* (C64) auf NEC PC Engine / HuCard. Referenz ist die kommentierte/refaktorierte 6502-Rekonstruktion von Dave-Agent.

## Bereits umgesetzt

- Linux-Mint-22 Toolchain/Build/Run-Grundgeruest; GitHub-Actions-ROM-Build bleibt entfernt.
- PCE VDC/VCE Bring-up, Palette, BAT und VSync.
- Raum $00 mit echten konvertierten C64-Hintergrundtiles.
- PAL-orientierter Gameplay-Scheduler.
- Montys Sprungkurve, PCE-Pad, horizontale Bewegung, Step-Gate und erste Tile-Kollision.
- C64-Raumkanten und statisches 6x23-Weltgrid.
- Echte Monty-Walkgrafik fuer beide Blickrichtungen.
- Echte Monty-Climbgrafik und deren Gameplay-Auswahl.

## Phase 18i — erster erfolgreicher ROM-Build

Vom Nutzer am 2026-09-04 bestaetigt: `./build.sh` erzeugt erfolgreich eine startende `.pce`; der Emulator zeigt den portierten Raum $00. Damit sind Toolchain, Regressionstests, PCEAS und ROM-Start end-to-end bestaetigt.

## Phase 19 — Tile-State, UP/DOWN und Climb-Runtime

Die C64-Routine `Monty.UpdateTileFlags` wurde fuer den aktuellen logischen Raum uebertragen: Montys 2x3-Footprint wird auf Collision-Property 3 untersucht und daraus `monty_tile_state` gebildet. Vertikale Spielerbewegung wird nur zugelassen, wenn dieser Tile-State aktiv ist und kein Sprung laeuft. PCE-Pad UP/DOWN bewegt Monty unter Collision-Pruefung; `monty_climbing` schaltet auf die authentischen vier Climb-Frames.

## Phase 19a — C64-Animationszustand statt Dauer-Walk

Der erste PCE-Animator liess die Walkframes auch im Stillstand alle vier logischen Ticks weiterlaufen. Das entspricht nicht `Monty.UpdateState` des C64. Der Runtime-Animator wurde deshalb korrigiert: Walkframes laufen nur bei `monty_is_moving`, Climbframes nur bei aktivem vertikalem Klettern, und waehrend eines Sprungs bleibt der Animationstakt aktiv. Ein Richtungs- oder Moduswechsel erzwingt weiterhin den notwendigen VRAM-Upload. Damit steht Monty im Idle auf seinem aktuellen Walkframe statt auf der Stelle zu laufen.

Die eigentlichen 12+12 Somersault-Grafiken fehlen noch; waehrend des Sprungs wird bis zu deren Port weiterhin der vorhandene Vierer-Animationspfad benutzt.

## Verifikationsstatus

Vom Nutzer bestaetigt: Phase 19 baut erfolgreich. Phase 19a ist hochgeladen, aber noch nicht durch den naechsten lokalen `./build.sh`-Lauf bestaetigt. Raum $00 besitzt keine Property-3-Kachel, daher ist der Climbpfad dort noch nicht sinnvoll visuell testbar.

## Aktuell offen

- Phase 19a bauen/regressionspruefen.
- 12+12 Somersault-/Jumpframes portieren und an `monty_jump_phase` koppeln.
- `CheckTileBelow` fuer Properties 2/3/4 exakt nachziehen; insbesondere Property 4 setzt nach zwei Treffern den C64-Eventwert 5.
- Raum $01 und generischen Room-State/Renderer anschliessen.
- Collision-Abbildung zwischen C64-Screenkoordinaten und logischem 32x20-Raum exakt verifizieren.
- Gegner, Mechanismen, Special Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
