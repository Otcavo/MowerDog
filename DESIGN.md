# MowerDog Screensaver: Design Doc

## Overview

MowerDog is a pixel-art screensaver for macOS. The screen is a lawn of grass tiles that grow over time, while a lawnmower drives back and forth trimming them. Bees look for flowers, a mole pops up in freshly mowed grass, and a bird occasionally flies past.

The screensaver is a small game that runs without user input. It is built with Apple's SpriteKit game framework and hosted inside a macOS `ScreenSaverView`.

## Assets

All sprites use 32×32 pixel frames. A wider or taller image is a sprite sheet for animating, read left to right, then top to bottom.

| Asset | File | Frames | Notes |
|---|---|---|---|
| Grass (3 variants) | `grass1.png`, `grass2.png`, `grass3.png` | 8 each | Frame 1 is freshly cut, frame 8 is fully grown. Frames 7–8 have flowers. |
| Lawnmower | `mower.png` | 3 | Animation plays while mowing. An optional mower_cutting.png plays while cutting. |
| Mole | `mole.png` | 12 | Pops up and looks around |
| Bird (blue jay) | `bluejay.png` | 2 | Flaps while flying |
| Bees | `bees.png` | 2 | Wings switch every 0.5 seconds |

## Behavior

### The lawn

- The screen is filled with as many whole tiles as fit. The grid is centered, with a thin black border taking up the leftover space, so no tile is ever cut off.
- Each tile is randomly given one of the three grass variants and a random starting height.
- Each tile grows one frame at a time on its own random timer (8–10 seconds at normal speed). The lawn grows unevenly.

### The mower

- Starts in the top-right corner and drives along the row. At the end of a row, it moves down one row and reverses direction. At the bottom, it zigzags back up the same way, and repeats forever.
- Moves one tile at a time. When it reaches a tile with any growth, it stops, plays its cutting animation, trims the tile back to frame 1, and continues.

### The bees

- Move tile to tile, only left, right, up, or down, like the mower.
- Pick a random flowering tile (frames 7–8) and fly to it, then stay for 9 seconds before choosing another. A bee won't go straight back to the flower it just left, but can return later.
- If the mower cuts a flower, any bee on it leaves immediately. A bee heading to a flower that gets mowed picks a new destination.
- With no flowers on the lawn, bees wander randomly, a few tiles at a time.

### The mole

- Every so often, appears on a random freshly mowed tile (frame 1) and plays its look-around animation once.
- The tile doesn't grow while the mole is there.

### The bird

- Every 10–30 seconds, a blue jay flies straight across the lawn along a random row, from a random side.
- It enters and leaves from behind the border, and is removed once fully off the lawn.

## Options

The **Options…** button in System Settings opens a window with:

- **Mower speed:** 0.5× to 3×
- **Bees:** 0 to 10
- **Grass growth speed:** 0.5× to 3×
- **Tile size:** Large, Medium, Small, Tiny. Large is the default zoom; smaller sizes fit more tiles on screen. Pixels always stay crisp.

## Code structure

| File | Contents |
|---|---|
| `SpriteSaverView.swift` | The screensaver view; starts and pauses SpriteKit, opens Options |
| `SaverScene.swift` | Core scene: settings, setup, sprite sheet loading, grid, and lawn |
| `SaverScene+Mower.swift` | The mower |
| `SaverScene+Bees.swift` | The bees |
| `SaverScene+BlueJay.swift` | The bird |
| `SaverScene+Mole.swift` | The mole |
| `Options.swift` | Saved settings and the Options window |

Characters move using chains of SpriteKit actions ("move to the next tile, then decide what to do"), which suits grid-based, step-by-step movement.

## How it was made

All art was hand-drawn by me in Krita.

The code was written by Claude (Anthropic's AI assistant) from instructions I gave: what each character should do, how it should move, and how it should look. I tested every build on my Mac, and several problems were found and fixed through human intervention:

- **Mower sat between rows.** I spotted from a screenshot that the mower was offset by half a tile from the grass. The cause was my grass sprite sheet being laid out in two rows, which the loader read as 64-pixel-tall frames. The loader was changed to read sprite sheets with any number of rows.
- **Partial tiles at the screen edges.** I noticed the grid didn't tile the screen evenly. After comparing options, I chose whole tiles, centered with a thin border, over stretching the pixels or cropping the edges.
- **Bees moved diagonally.** They didn't match the grid the rest of the scene follows, so I had them changed to move tile by tile, left, right, up, and down, like the mower.
- **Options window cut off.** The window was too narrow for its contents. It was fixed by sizing the window after its layout is calculated.
- **Tile size option had no effect.** Sizes were calculated in a way that bottomed out immediately. They were changed to be calculated in real screen pixels, as fractions of the largest size.
