import ScreenSaver
import SpriteKit

// MARK: - The screensaver view (hosts the SpriteKit "game")

@objc(SpriteSaverView)
class SpriteSaverView: ScreenSaverView {
    private var skView: SKView?
    private var optionsSheet: OptionsSheet?  // kept so the sheet stays alive while open

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)

        // SpriteKit runs its own game loop, so we just add its view and a scene
        let view = SKView(frame: bounds)
        view.autoresizingMask = [.width, .height]
        view.ignoresSiblingOrder = true
        addSubview(view)

        let scene = SaverScene(size: bounds.size)
        scene.scaleMode = .resizeFill
        view.presentScene(scene)
        skView = view

        // Recent macOS keeps the screensaver process running after it's
        // dismissed, so quit when the system says the screensaver is stopping
        if !isPreview {
            DistributedNotificationCenter.default().addObserver(
                self,
                selector: #selector(screenSaverWillStop),
                name: NSNotification.Name("com.apple.screensaver.willstop"),
                object: nil
            )
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func startAnimation() {
        super.startAnimation()
        skView?.isPaused = false
    }

    override func stopAnimation() {
        super.stopAnimation()
        skView?.isPaused = true
    }

    @objc private func screenSaverWillStop() {
        exit(0)
    }

    override func draw(_ rect: NSRect) {
        NSColor.black.setFill()
        bounds.fill()
    }

    override func animateOneFrame() {
        // Empty: SpriteKit does the animating
    }

    // The "Options…" button in System Settings opens this sheet
    override var hasConfigureSheet: Bool { true }

    override var configureSheet: NSWindow? {
        let sheet = OptionsSheet { [weak self] in
            // After saving, rebuild so the preview shows the new settings
            (self?.skView?.scene as? SaverScene)?.reloadOptions()
        }
        optionsSheet = sheet
        return sheet.window
    }
}
