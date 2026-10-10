# MowerDog

A pixel-art screensaver for macOS '90s style.

[![Watch MowerDog in action](https://img.youtube.com/vi/8KRA4wmmOC8/hqdefault.jpg)](https://www.youtube.com/watch?v=8KRA4wmmOC8)

*Click the image to watch it on YouTube.*

The scene is partitioned into tiles of grass which grow at different rates. A lawnmower zigzags across the lawn row by row, starting in the top-right corner, and stops to cut any grass it finds. Bees go from flower to flower and scatter when the mower arrives, moles pop up in freshly cut grass, and every so often a blue jay flies past. Other easter eggs to be added at a later date.

## Credits

- **Code:** I wrote the code together with Claude, Anthropic's AI assistant.
- **Art:** all the pixel art is mine.

## Features

- A growing lawn with three grass variants, each tile on its own timer
- A mower that goes back and forth across the lawn mowing the grass
- Bees that seek out flowers, visit them, and flee the mower
- Occasional visits from a blue jay and a mole
- Options: mower speed, number of bees, grass growth speed, and tile size

See [DESIGN.md](DESIGN.md) for the full design doc.

## Building

Requires macOS and Apple's Command Line Tools (`xcode-select --install`). Xcode is not needed.

```
bash build_sprites.sh
```

This compiles everything in `Sources/`, bundles the images in `Sprites/`, and installs the screensaver to `~/Library/Screen Savers`. Then choose it in **System Settings → Screen Saver**.

## How it was made

Design, behavior, and all pixel art by me. The code was written with Claude, Anthropic's AI assistant, from my instructions; I tested every build and diagnosed several bugs along the way. The details are in [DESIGN.md](DESIGN.md#how-it-was-made).

## Art

All pixel art in `Sprites/` is Copyrighted by the owner, all rights reserved. The art is not covered by any license in this repository and may not be reused without permission.
