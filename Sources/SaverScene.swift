import ScreenSaver
import SpriteKit
import ImageIO

// The scene's core: settings, setup, image loading, the grid, and the lawn.
// The other characters live in their own files as extensions of SaverScene:
//   SaverScene+Mower.swift, SaverScene+Bees.swift,
//   SaverScene+BlueJay.swift, SaverScene+Mole.swift

// MARK: - The scene: a lawn that grows and a mower that cuts it

class SaverScene: SKScene {

    // ---- Settings you can tweak ----
    let frameSize = 32                       // width of one frame, in pixels
    let screenHeightInPixels: CGFloat = 240  // smaller = bigger pixels
    let baseGrowMinSeconds: TimeInterval = 8     // at normal growth speed, each tile
    let baseGrowMaxSeconds: TimeInterval = 10    //   grows one stage every 8–10 seconds
    let baseMowerStepSeconds: TimeInterval = 0.4 // at normal mower speed: time per tile
    let baseTrimPauseSeconds: TimeInterval = 0.6 //   and time spent cutting a tile
    let mowerFrameDuration = 0.1             // mower animation speed
    let mowerCuttingFrameDuration = 0.1      // speed of mower_cutting.png
    let flowerFrames: Set<Int> = [7, 8]      // grass frames with flowers (1 = first)
    let beeStepSeconds: TimeInterval = 0.5   // time for a bee to fly one tile
    let beeVisitSeconds: TimeInterval = 9    // time spent on a flower
    let beeFrameDuration = 0.5               // bee animation speed
    let bluejayMinSeconds: TimeInterval = 10 // a blue jay flies by every
    let bluejayMaxSeconds: TimeInterval = 30 //   10–30 seconds
    let bluejayTilesPerSecond: CGFloat = 4   // blue jay flying speed
    let bluejayFrameDuration = 0.15          // used if bluejay.png has frames
    let moleMinSeconds: TimeInterval = 15    // a mole pops up every
    let moleMaxSeconds: TimeInterval = 40    //   15–40 seconds
    let moleFrameDuration = 0.15             // mole animation speed
    // --------------------------------

    // Settings people choose in Options (loaded fresh each time the scene is built)
    var options = SaverOptions.load()

    // These combine the base timings above with the chosen speeds
    var growMinSeconds: TimeInterval { baseGrowMinSeconds / options.growthSpeed }
    var growMaxSeconds: TimeInterval { baseGrowMaxSeconds / options.growthSpeed }
    var mowerStepSeconds: TimeInterval { baseMowerStepSeconds / options.mowerSpeed }
    var trimPauseSeconds: TimeInterval { baseTrimPauseSeconds / options.mowerSpeed }

    // Images must come from the screensaver's own bundle, not Bundle.main
    let bundle = Bundle(for: SaverScene.self)
    var pixelScale: CGFloat = 1
    var tileSize: CGFloat = 32

    // Where the grid sits on screen. Only whole tiles are used, and the
    // grid is centered, leaving a thin black border around it.
    var gridLeft: CGFloat = 0
    var gridBottom: CGFloat = 0

    // The lawn: a grid of tiles. Row 0 is the top row.
    var grassVariants: [[SKTexture]] = []  // frames of grass1.png, grass2.png, ...
    var grassStageCount = 0                 // growth stages per variant
    var grassKinds: [[Int]] = []            // which variant each tile uses
    var grassTiles: [[SKSpriteNode]] = []
    var grassStages: [[Int]] = []  // 0 = freshly cut, last frame = tallest
    var rows = 0
    var cols = 0

    // The mower and where it is on the grid
    var mowerFrames: [SKTexture] = []
    var mowerCuttingFrames: [SKTexture] = []  // optional: plays while cutting
    var mower: SKSpriteNode?
    var mowerRow = 0
    var mowerCol = 0
    var mowerDirX = -1  // -1 = moving left, 1 = moving right
    var mowerDirY = 1   //  1 = next row is below, -1 = above

    // The bees
    var beeFrames: [SKTexture] = []
    var bees: [Bee] = []

    // The blue jay
    var bluejayFrames: [SKTexture] = []

    // The mole
    var moleFrames: [SKTexture] = []
    var moleTiles: Set<TileSpot> = []  // tiles with a mole on them right now

    var builtSize: CGSize = .zero  // screen size the lawn was laid out for

    // Called once when the scene appears: set everything up
    override func didMove(to view: SKView) {
        buildScene()
    }

    // macOS sometimes resizes the screensaver after it starts. If that
    // happens, rebuild everything so the grass and mower stay on one grid.
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if view != nil && builtSize != .zero && size != builtSize {
            buildScene()
        }
    }

    // Called after the Options sheet saves new settings
    func reloadOptions() {
        buildScene()
    }

    func buildScene() {
        options = SaverOptions.load()

        // Clear out anything from a previous layout
        removeAllActions()
        removeAllChildren()
        grassTiles = []
        grassStages = []
        grassKinds = []
        mower = nil
        bees = []
        moleTiles = []
        mowerDirX = -1
        mowerDirY = 1
        builtSize = size

        backgroundColor = .black
        // Work out how big each art pixel is, measured in REAL screen pixels.
        // Retina screens have 2 screen pixels per point, so this gives finer
        // steps (and lets small views like the preview zoom out too).
        let screenScale = view?.window?.backingScaleFactor
            ?? NSScreen.main?.backingScaleFactor ?? 1
        let heightInScreenPixels = size.height * screenScale

        // "Large" shows about screenHeightInPixels art pixels top to bottom
        let largest = max(1, (heightInScreenPixels / screenHeightInPixels).rounded())

        // Each tile size is a fraction of Large: Large, Medium, Small, Tiny
        let sizeFactors: [CGFloat] = [1, 0.75, 0.5, 0.25]
        let factor = sizeFactors[min(max(options.zoomOut, 0), sizeFactors.count - 1)]

        // Always a whole number of screen pixels per art pixel, so it stays crisp
        let screenPixelsPerArtPixel = max(1, (largest * factor).rounded())
        pixelScale = screenPixelsPerArtPixel / screenScale  // back to points
        tileSize = CGFloat(frameSize) * pixelScale

        // Load grass1.png, grass2.png, grass3.png... until one is missing
        grassVariants = []
        var number = 1
        while true {
            let frames = loadFrames(named: "grass\(number)")
            if frames.isEmpty { break }
            grassVariants.append(frames)
            number += 1
        }
        // If variants have different frame counts, use the smallest
        grassStageCount = grassVariants.map { $0.count }.min() ?? 0
        mowerFrames = loadFrames(named: "mower")
        mowerCuttingFrames = loadFrames(named: "mower_cutting")
        beeFrames = loadFrames(named: "bees")
        bluejayFrames = loadFrames(named: "bluejay")
        moleFrames = loadFrames(named: "mole")

        // Show a message instead of a black screen if a file is missing
        if grassVariants.isEmpty { showMessage("Missing grass1.png"); return }
        if mowerFrames.isEmpty { showMessage("Missing mower.png"); return }

        addLawn()
        addMower()
        addBees()  // bees are optional: skipped if bees.png is missing
        scheduleBluejay()  // also optional
        scheduleMole()     // also optional
    }

    // MARK: Loading images

    // Cuts a sprite sheet into 32×32 frames. Frames are read like text:
    // left to right along the top row, then the next row down, and so on.
    func loadFrames(named name: String) -> [SKTexture] {
        guard let url = bundle.url(forResource: name, withExtension: "png"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return [] }

        let sheet = SKTexture(cgImage: image)
        let framesAcross = max(1, image.width / frameSize)
        let framesDown = max(1, image.height / frameSize)

        // Texture rects use 0–1 fractions of the sheet, not pixels
        let frameWidth = CGFloat(frameSize) / CGFloat(image.width)
        let frameHeight = CGFloat(frameSize) / CGFloat(image.height)

        var frames: [SKTexture] = []
        for row in 0..<framesDown {
            for col in 0..<framesAcross {
                // SpriteKit measures y from the BOTTOM of the image,
                // so the top row of frames has the highest y value
                let rect = CGRect(x: CGFloat(col) * frameWidth,
                                  y: 1 - CGFloat(row + 1) * frameHeight,
                                  width: frameWidth,
                                  height: frameHeight)
                let frame = SKTexture(rect: rect, in: sheet)
                frame.filteringMode = .nearest  // crisp pixels instead of blurry ones
                frames.append(frame)
            }
        }
        return frames
    }

    func showMessage(_ text: String) {
        let label = SKLabelNode(text: text)
        label.fontName = "Menlo"
        label.fontSize = 18
        label.fontColor = .white
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(label)
    }

    // Screen position of the center of a grid tile
    func tileCenter(row: Int, col: Int) -> CGPoint {
        let gridTop = gridBottom + CGFloat(rows) * tileSize
        return CGPoint(x: gridLeft + CGFloat(col) * tileSize + tileSize / 2,
                       y: gridTop - (CGFloat(row) * tileSize + tileSize / 2))
    }

    // MARK: The lawn

    // Black strips over the space around the grid. They sit in front of
    // everything, so anything flying in from outside (like the blue jay)
    // appears and disappears neatly at the edge of the lawn.
    func addBorder() {
        let gridRight = gridLeft + CGFloat(cols) * tileSize
        let gridTop = gridBottom + CGFloat(rows) * tileSize

        let strips = [
            CGRect(x: 0, y: 0, width: gridLeft, height: size.height),                       // left
            CGRect(x: gridRight, y: 0, width: size.width - gridRight, height: size.height), // right
            CGRect(x: gridLeft, y: 0, width: gridRight - gridLeft, height: gridBottom),     // bottom
            CGRect(x: gridLeft, y: gridTop, width: gridRight - gridLeft, height: size.height - gridTop) // top
        ]
        for rect in strips where rect.width > 0 && rect.height > 0 {
            let strip = SKSpriteNode(color: .black, size: rect.size)
            strip.anchorPoint = .zero
            strip.position = rect.origin
            strip.zPosition = 10  // in front of everything
            addChild(strip)
        }
    }

    func addLawn() {
        // As many WHOLE tiles as fit (rounded down), at least one
        cols = max(1, Int((size.width / tileSize).rounded(.down)))
        rows = max(1, Int((size.height / tileSize).rounded(.down)))

        // Center the grid: split the leftover space evenly on each side.
        // Rounded to whole points so the pixel art stays crisp.
        gridLeft = ((size.width - CGFloat(cols) * tileSize) / 2).rounded(.down)
        gridBottom = ((size.height - CGFloat(rows) * tileSize) / 2).rounded(.down)
        addBorder()

        for row in 0..<rows {
            var rowTiles: [SKSpriteNode] = []
            var rowStages: [Int] = []
            var rowKinds: [Int] = []
            for col in 0..<cols {
                // Pick a random grass variant and a random starting height
                let kind = Int.random(in: 0..<grassVariants.count)
                let stage = Int.random(in: 0..<grassStageCount)
                let tile = SKSpriteNode(texture: grassVariants[kind][stage])
                tile.setScale(pixelScale)
                tile.position = tileCenter(row: row, col: col)
                tile.zPosition = 0  // behind the mower
                addChild(tile)
                rowTiles.append(tile)
                rowStages.append(stage)
                rowKinds.append(kind)
            }
            grassTiles.append(rowTiles)
            grassStages.append(rowStages)
            grassKinds.append(rowKinds)
        }

        for row in 0..<rows {
            for col in 0..<cols {
                scheduleGrowth(row: row, col: col)
            }
        }
    }

    // Waits a random 8–10 seconds, grows the tile one stage, then repeats
    func scheduleGrowth(row: Int, col: Int) {
        let delay = TimeInterval.random(in: growMinSeconds...growMaxSeconds)
        grassTiles[row][col].run(.sequence([
            .wait(forDuration: delay),
            .run { [weak self] in
                self?.grow(row: row, col: col)
                self?.scheduleGrowth(row: row, col: col)
            }
        ]))
    }

    func grow(row: Int, col: Int) {
        // No growing while a mole is popping up here
        if moleTiles.contains(TileSpot(row: row, col: col)) { return }

        let tallest = grassStageCount - 1
        if grassStages[row][col] < tallest {
            setStage(grassStages[row][col] + 1, row: row, col: col)
        }
    }

    func setStage(_ stage: Int, row: Int, col: Int) {
        grassStages[row][col] = stage
        let kind = grassKinds[row][col]
        grassTiles[row][col].texture = grassVariants[kind][stage]
    }
}

// A position on the lawn grid
struct TileSpot: Hashable {  // Hashable lets it go in a Set (includes Equatable)
    let row: Int
    let col: Int
}
