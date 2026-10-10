import SpriteKit

// The bees: visit flowers, wander, and flee the mower

extension SaverScene {

    func addBees() {
        guard !beeFrames.isEmpty else { return }

        for _ in 0..<options.beeCount {
            let node = SKSpriteNode(texture: beeFrames[0])
            node.setScale(pixelScale)
            node.zPosition = 2  // in front of the mower
            if beeFrames.count > 1 {
                node.run(.repeatForever(.animate(with: beeFrames, timePerFrame: beeFrameDuration)))
            }

            // Start on a random tile
            let start = TileSpot(row: .random(in: 0..<rows), col: .random(in: 0..<cols))
            node.position = tileCenter(row: start.row, col: start.col)
            addChild(node)

            let bee = Bee(node: node, tile: start)
            bees.append(bee)
            sendBeeSomewhere(bee)
        }
    }

    // Is this tile currently showing flowers?
    func isFlowering(_ spot: TileSpot) -> Bool {
        flowerFrames.contains(grassStages[spot.row][spot.col] + 1)
    }

    func allFlowerTiles() -> [TileSpot] {
        var spots: [TileSpot] = []
        for row in 0..<rows {
            for col in 0..<cols {
                let spot = TileSpot(row: row, col: col)
                if isFlowering(spot) { spots.append(spot) }
            }
        }
        return spots
    }

    // Decides where a bee goes next: a flower if there is one
    // (but not the one it just left), otherwise a short random trip
    func sendBeeSomewhere(_ bee: Bee) {
        let choices = allFlowerTiles().filter { $0 != bee.lastFlower }

        if let flower = choices.randomElement() {
            bee.targetFlower = flower
            travel(bee, to: flower) { [weak self, weak bee] in
                guard let self = self, let bee = bee else { return }
                self.arriveAtFlower(bee)
            }
        } else {
            bee.targetFlower = nil
            let destination = randomTileNear(bee.tile)

            // Picked the tile it's already on? Hover a moment, then try again
            if destination == bee.tile {
                bee.node.run(.sequence([
                    .wait(forDuration: beeStepSeconds),
                    .run { [weak self, weak bee] in
                        guard let self = self, let bee = bee else { return }
                        self.sendBeeSomewhere(bee)
                    }
                ]), withKey: "move")
                return
            }

            travel(bee, to: destination) { [weak self, weak bee] in
                guard let self = self, let bee = bee else { return }
                bee.lastFlower = nil        // after a trip, it may go back to its old flower
                self.sendBeeSomewhere(bee)  // look for flowers again
            }
        }
    }

    func arriveAtFlower(_ bee: Bee) {
        bee.isVisiting = true
        bee.node.run(.sequence([
            .wait(forDuration: beeVisitSeconds),
            .run { [weak self, weak bee] in
                guard let self = self, let bee = bee else { return }
                self.leaveFlower(bee)
            }
        ]), withKey: "move")
    }

    func leaveFlower(_ bee: Bee) {
        bee.isVisiting = false
        bee.lastFlower = bee.targetFlower  // don't go straight back to this one
        bee.targetFlower = nil
        sendBeeSomewhere(bee)
    }

    // Called when the mower cuts a tile: any bee sitting on it leaves.
    // (Bees still on their way notice when they next reach a tile.)
    func scareBees(from spot: TileSpot) {
        for bee in bees where bee.isVisiting && bee.targetFlower == spot {
            leaveFlower(bee)
        }
    }

    // Starts a trip. Like the mower, bees only move left, right, up, or
    // down, one tile at a time. Each trip randomly goes sideways first
    // or up/down first, which makes an L-shaped path.
    func travel(_ bee: Bee, to destination: TileSpot, then done: @escaping () -> Void) {
        bee.sidewaysFirst = Bool.random()
        step(bee, toward: destination, then: done)
    }

    func step(_ bee: Bee, toward destination: TileSpot, then done: @escaping () -> Void) {
        // Heading to a flower that's been mowed? Pick somewhere else.
        if let flower = bee.targetFlower, flower == destination, !isFlowering(flower) {
            bee.targetFlower = nil
            sendBeeSomewhere(bee)
            return
        }

        let colsToGo = destination.col - bee.tile.col
        let rowsToGo = destination.row - bee.tile.row
        if colsToGo == 0 && rowsToGo == 0 {
            done()  // arrived
            return
        }

        // Move sideways if that's the plan (or there's no up/down left to do)
        let goSideways = colsToGo != 0 && (bee.sidewaysFirst || rowsToGo == 0)
        if goSideways {
            bee.tile = TileSpot(row: bee.tile.row, col: bee.tile.col + colsToGo.signum())
            // Face the direction of travel (bees.png is drawn facing left)
            bee.node.xScale = colsToGo < 0 ? pixelScale : -pixelScale
        } else {
            bee.tile = TileSpot(row: bee.tile.row + rowsToGo.signum(), col: bee.tile.col)
        }

        // Using the key "move" replaces whatever the bee was doing before
        bee.node.run(.sequence([
            .move(to: tileCenter(row: bee.tile.row, col: bee.tile.col), duration: beeStepSeconds),
            .run { [weak self, weak bee] in
                guard let self = self, let bee = bee else { return }
                self.step(bee, toward: destination, then: done)
            }
        ]), withKey: "move")
    }

    // A random tile within three tiles of this one, kept on screen
    func randomTileNear(_ spot: TileSpot) -> TileSpot {
        let row = min(max(spot.row + .random(in: -3...3), 0), rows - 1)
        let col = min(max(spot.col + .random(in: -3...3), 0), cols - 1)
        return TileSpot(row: row, col: col)
    }
}

// One bee: its sprite, where it is, and what it's up to
class Bee {
    let node: SKSpriteNode
    var tile: TileSpot              // the tile it's on (or flying to right now)
    var targetFlower: TileSpot?     // flower it's visiting or heading to
    var lastFlower: TileSpot?       // flower it just left
    var isVisiting = false          // sitting on a flower right now?
    var sidewaysFirst = true        // this trip: sideways first, or up/down first?

    init(node: SKSpriteNode, tile: TileSpot) {
        self.node = node
        self.tile = tile
    }
}
