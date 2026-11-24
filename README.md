# Reef Runner 6502

An original NES surfing game set at Amethyst Point. The Ricoh 2A03 runs hand-written 6502 assembly for the game loop, controller input, sprite drawing, scoring, and sound. The browser player runs the same cartridge through JSNES.

[Play Reef Runner on SurfingCoder](https://surfingcoder.com/apps/reef-runner-6502/)

## Play

1. Press Start to paddle.
2. Press A when the moving pocket turns gold and the game calls for takeoff. An early or late press leaves you on the board to catch the next wave.
3. Steer with the D-pad. Ride inside the moving pocket to score, dodge the reefs, and finish the 30-second ride.

In the browser, use Enter for Start, Z or A for takeoff, and the arrow keys to steer. Touch controls are available below or beside the display. A new run keeps the session best score. Resetting the console clears it.

Load `web/reef-runner.nes` in an NES emulator to play outside the browser. The original cartridge uses mapper 0 with 16 KiB of PRG ROM and 8 KiB of CHR ROM.

## Build and verify

Install [cc65](https://cc65.github.io/) and Python 3. Put `ca65` and `ld65` on PATH or pass their directory to `build.py --tools`.

```sh
python assets/generate_chr.py
python build.py --labels reef-runner.lbl
python build.py --check
node tests/playthrough.mjs reef-runner.lbl
python -m http.server 8000 --bind 127.0.0.1 --directory web
```

Open `http://127.0.0.1:8000` for the local browser player. The playthrough test uses the bundled JSNES build and requires Node.js.

## Source

- `src/game.s` contains the 6502 game.
- `assets/generate_chr.py` generates the original 2-bit tile art for the NES PPU.
- `nes.cfg` defines the cartridge memory layout.
- `web/` contains the cartridge and browser player. [JSNES license](web/vendor/JSNES-LICENSE.txt)
