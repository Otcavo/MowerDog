import SpriteKit

// The mower: zigzags across the lawn and cuts grass

extension SaverScene {

    func addMower() {
        let node = SKSpriteNode(texture: mowerFrames[0])
        node.setScale(pixelScale)
        node.zPosition = 1  // in front of the grass

        // Start in the top-right corner, heading left
        mowerRow = 0
        mowerCol = cols - 1
        node.position = tileCenter(row: mowerRow, col: mowerCol)
        addChild(node)
        mower = node
        playMowerAnimation(mowerFrames, timePerFrame: mowerFrameDuration)

        arriveAtTile()
    }

    // Loops a set of frames on the mower. Using the key "animation" means
    // starting one animation automatically stops the previous one.
    func playMowerAnimation(_ frames: [SKTexture], timePerFrame: TimeInterval) {
        guard let mower = mower, !frames.isEmpty else { return }
        mower.texture = frames[0]
        if frames.count > 1 {
            mower.run(.repeatForever(.animate(with: frames, timePerFrame: timePerFrame)),
                      withKey: "animation")
        } else {
            mower.removeAction(forKey: "animation")
        }
    }

    // Called each time the mower reaches a tile
    func arriveAtTile() {
        guard let mower = mower else { return }

        if grassStages[mowerRow][mowerCol] > 0 {
            // There's grass here: pause, cut it, then keep going.
            // Switch to the cutting animation while stopped (if there is one).
            if !mowerCuttingFrames.isEmpty {
                playMowerAnimation(mowerCuttingFrames, timePerFrame: mowerCuttingFrameDuration)
            }
            mower.run(.sequence([
                .wait(forDuration: trimPauseSeconds),
                .run { [weak self] in
                    guard let self = self else { return }
                    // Back to the driving animation
                    self.playMowerAnimation(self.mowerFrames, timePerFrame: self.mowerFrameDuration)
                    self.setStage(0, row: self.mowerRow, col: self.mowerCol)
                    self.scareBees(from: TileSpot(row: self.mowerRow, col: self.mowerCol))
                    self.moveToNextTile()
                }
            ]))
        } else {
            moveToNextTile()
        }
    }

    func moveToNextTile() {
        guard let mower = mower else { return }
        advanceMowerPosition()

        // Face the direction of travel (mower.png is drawn facing left)
        mower.xScale = mowerDirX < 0 ? pixelScale : -pixelScale

        mower.run(.sequence([
            .move(to: tileCenter(row: mowerRow, col: mowerCol), duration: mowerStepSeconds),
            .run { [weak self] in self?.arriveAtTile() }
        ]))
    }

    // Works out the next tile: along the row, and at the end of a row,
    // down one row and turn around. At the bottom, it heads back up.
    func advanceMowerPosition() {
        let nextCol = mowerCol + mowerDirX
        if nextCol >= 0 && nextCol < cols {
            mowerCol = nextCol
            return
        }

        mowerDirX = -mowerDirX
        guard rows > 1 else { return }

        var nextRow = mowerRow + mowerDirY
        if nextRow < 0 || nextRow >= rows {
            mowerDirY = -mowerDirY
            nextRow = mowerRow + mowerDirY
        }
        mowerRow = nextRow
    }
}
