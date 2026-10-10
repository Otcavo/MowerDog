import ScreenSaver
import AppKit

// MARK: - Options (saved settings)

struct SaverOptions {
    var mowerSpeed: Double = 1.0   // 0.5× to 3×
    var beeCount: Int = 3          // 0 to 10
    var growthSpeed: Double = 1.0  // 0.5× to 3×
    var zoomOut: Int = 0           // 0 = biggest tiles; higher = smaller tiles, more of them

    // Screensavers save settings with ScreenSaverDefaults, named after the bundle
    private static var store: ScreenSaverDefaults? {
        let name = Bundle(for: SaverScene.self).bundleIdentifier ?? "io.github.otcavo.MowerDog"
        return ScreenSaverDefaults(forModuleWithName: name)
    }

    static func load() -> SaverOptions {
        var options = SaverOptions()  // starts with the defaults above
        guard let store = store else { return options }
        // Only use saved values that actually exist, otherwise keep the default
        if store.object(forKey: "mowerSpeed") != nil { options.mowerSpeed = store.double(forKey: "mowerSpeed") }
        if store.object(forKey: "beeCount") != nil { options.beeCount = store.integer(forKey: "beeCount") }
        if store.object(forKey: "growthSpeed") != nil { options.growthSpeed = store.double(forKey: "growthSpeed") }
        if store.object(forKey: "zoomOut") != nil { options.zoomOut = store.integer(forKey: "zoomOut") }
        return options
    }

    func save() {
        guard let store = SaverOptions.store else { return }
        store.set(mowerSpeed, forKey: "mowerSpeed")
        store.set(beeCount, forKey: "beeCount")
        store.set(growthSpeed, forKey: "growthSpeed")
        store.set(zoomOut, forKey: "zoomOut")
        store.synchronize()
    }
}

// MARK: - Options window

// Builds the small window that appears when someone clicks "Options…"
final class OptionsSheet: NSObject {
    let window: NSWindow
    private let onSave: () -> Void

    private let tileSizeNames = ["Large", "Medium", "Small", "Tiny"]

    // Sliders: NSSlider(value:minValue:maxValue:target:action:)
    private let mowerSlider = NSSlider(value: 1, minValue: 0.5, maxValue: 3, target: nil, action: nil)
    private let beeSlider = NSSlider(value: 3, minValue: 0, maxValue: 10, target: nil, action: nil)
    private let growthSlider = NSSlider(value: 1, minValue: 0.5, maxValue: 3, target: nil, action: nil)
    private let zoomSlider = NSSlider(value: 0, minValue: 0, maxValue: 3, target: nil, action: nil)

    // Labels showing each slider's current value
    private let mowerValue = NSTextField(labelWithString: "")
    private let beeValue = NSTextField(labelWithString: "")
    private let growthValue = NSTextField(labelWithString: "")
    private let zoomValue = NSTextField(labelWithString: "")

    init(onSave: @escaping () -> Void) {
        self.onSave = onSave
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 420, height: 220),
                          styleMask: [.titled],
                          backing: .buffered,
                          defer: false)
        super.init()

        // Whole-number sliders snap to their tick marks
        beeSlider.numberOfTickMarks = 11
        beeSlider.allowsTickMarkValuesOnly = true
        zoomSlider.numberOfTickMarks = 4
        zoomSlider.allowsTickMarkValuesOnly = true

        // Show the saved settings
        let options = SaverOptions.load()
        mowerSlider.doubleValue = options.mowerSpeed
        beeSlider.integerValue = options.beeCount
        growthSlider.doubleValue = options.growthSpeed
        zoomSlider.integerValue = options.zoomOut

        for slider in [mowerSlider, beeSlider, growthSlider, zoomSlider] {
            slider.target = self
            slider.action = #selector(sliderMoved)
            slider.widthAnchor.constraint(equalToConstant: 200).isActive = true
        }
        for label in [mowerValue, beeValue, growthValue, zoomValue] {
            label.widthAnchor.constraint(equalToConstant: 60).isActive = true
        }
        updateValueLabels()

        // A grid: name | slider | value
        let grid = NSGridView(views: [
            [NSTextField(labelWithString: "Mower speed:"), mowerSlider, mowerValue],
            [NSTextField(labelWithString: "Bees:"), beeSlider, beeValue],
            [NSTextField(labelWithString: "Grass growth speed:"), growthSlider, growthValue],
            [NSTextField(labelWithString: "Tile size:"), zoomSlider, zoomValue],
        ])
        grid.column(at: 0).xPlacement = .trailing
        grid.rowSpacing = 12
        grid.columnSpacing = 8

        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        cancelButton.keyEquivalent = "\u{1b}"  // Escape key
        let okButton = NSButton(title: "OK", target: self, action: #selector(saveAndClose))
        okButton.keyEquivalent = "\r"          // Return key
        let buttons = NSStackView(views: [cancelButton, okButton])

        let stack = NSStackView(views: [grid, buttons])
        stack.orientation = .vertical
        stack.alignment = .trailing
        stack.spacing = 20

        // Put the stack inside a plain view, pinned 20 points from every edge.
        // Those constraints make the margins part of the window's required size.
        let container = NSView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
        ])

        // Lay everything out FIRST, then size the window to fit it
        container.layoutSubtreeIfNeeded()
        let fit = container.fittingSize
        window.contentView = container
        window.setContentSize(fit)
        window.contentMinSize = fit  // never let it shrink smaller than its contents
    }

    @objc private func sliderMoved() {
        updateValueLabels()
    }

    private func updateValueLabels() {
        mowerValue.stringValue = String(format: "%.1f×", mowerSlider.doubleValue)
        beeValue.stringValue = "\(beeSlider.integerValue)"
        growthValue.stringValue = String(format: "%.1f×", growthSlider.doubleValue)
        zoomValue.stringValue = tileSizeNames[min(max(zoomSlider.integerValue, 0), 3)]
    }

    @objc private func saveAndClose() {
        var options = SaverOptions()
        options.mowerSpeed = mowerSlider.doubleValue
        options.beeCount = beeSlider.integerValue
        options.growthSpeed = growthSlider.doubleValue
        options.zoomOut = zoomSlider.integerValue
        options.save()
        onSave()
        close()
    }

    @objc private func cancel() {
        close()
    }

    private func close() {
        // The sheet is attached to System Settings; end it properly
        if let parent = window.sheetParent {
            parent.endSheet(window)
        } else {
            window.close()
        }
    }
}
