import SpriteKit

// The mole: occasionally pops up in freshly cut grass

extension SaverScene {

    // Waits a random amount of time, pops up a mole, then repeats
    func scheduleMole() {
        guard !moleFrames.isEmpty else { return }
        let delay = TimeInterval.random(in: moleMinSeconds...moleMaxSeconds)
        run(.sequence([
            .wait(forDuration: delay),
            .run { [weak self] in
                self?.popMole()
                self?.scheduleMole()
            }
        ]), withKey: "mole")
    }

    func popMole() {
        // Find freshly cut tiles (frame 1) that don't already have a mole
        // and aren't under the mower right now
        let mowerSpot = TileSpot(row: mowerRow, col: mowerCol)
        var choices: [TileSpot] = []
        for row in 0..<rows {
            for col in 0..<cols {
                let spot = TileSpot(row: row, col: col)
                if grassStages[row][col] == 0 && !moleTiles.contains(spot) && spot != mowerSpot {
                    choices.append(spot)
                }
            }
        }
        guard let spot = choices.randomElement() else { return }  // none: skip this time

        moleTiles.insert(spot)  // stops this tile growing

        // The mole is its own sprite on top of the grass tile
        let mole = SKSpriteNode(texture: moleFrames[0])
        mole.setScale(pixelScale)
        mole.position = tileCenter(row: spot.row, col: spot.col)
        mole.zPosition = 0.5  // above the grass, below the mower
        addChild(mole)

        // Play the animation once, let the tile grow again, then remove the mole
        mole.run(.sequence([
            .animate(with: moleFrames, timePerFrame: moleFrameDuration),
            .run { [weak self] in self?.moleTiles.remove(spot) },
            .removeFromParent()
        ]))
    }
}
