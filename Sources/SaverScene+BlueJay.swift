import SpriteKit

// The blue jay: occasionally flies across the lawn

extension SaverScene {

    // Waits a random amount of time, sends a blue jay across, then repeats
    func scheduleBluejay() {
        guard !bluejayFrames.isEmpty else { return }
        let delay = TimeInterval.random(in: bluejayMinSeconds...bluejayMaxSeconds)
        run(.sequence([
            .wait(forDuration: delay),
            .run { [weak self] in
                self?.sendBluejay()
                self?.scheduleBluejay()
            }
        ]), withKey: "bluejay")
    }

    func sendBluejay() {
        let bird = SKSpriteNode(texture: bluejayFrames[0])
        bird.setScale(pixelScale)
        bird.zPosition = 3  // in front of everything
        if bluejayFrames.count > 1 {
            bird.run(.repeatForever(.animate(with: bluejayFrames, timePerFrame: bluejayFrameDuration)))
        }

        // Fly along a random row, from a random side
        let row = Int.random(in: 0..<rows)
        let y = tileCenter(row: row, col: 0).y
        let halfWidth = tileSize / 2  // half of the full 32×32 frame
        let gridRight = gridLeft + CGFloat(cols) * tileSize
        let leftEdge = gridLeft - halfWidth       // fully past the lawn's left edge
        let rightEdge = gridRight + halfWidth     // fully past the lawn's right edge

        let flyingLeft = Bool.random()
        let startX = flyingLeft ? rightEdge : leftEdge
        let endX = flyingLeft ? leftEdge : rightEdge

        // Face the direction of travel (bluejay.png is drawn facing left)
        bird.xScale = flyingLeft ? pixelScale : -pixelScale
        bird.position = CGPoint(x: startX, y: y)
        addChild(bird)

        let distance = rightEdge - leftEdge
        let duration = TimeInterval(distance / (tileSize * bluejayTilesPerSecond))
        bird.run(.sequence([
            .moveTo(x: endX, duration: duration),
            .removeFromParent()  // once the whole frame is off screen, delete it
        ]))
    }
}
