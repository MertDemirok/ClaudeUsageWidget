import AppKit
import SwiftUI

final class FloatingPanel: NSPanel {
    private static let positionKey = "floatingPanelPosition"

    init() {
        let size = NSSize(width: 140, height: 140)  // orb(76) + ring(76) + shadow padding(28*2)
        let origin = FloatingPanel.savedOrigin(size: size)
        super.init(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .floating
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        ignoresMouseEvents = false
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func savePosition() {
        let origin = frame.origin
        UserDefaults.standard.set([origin.x, origin.y], forKey: FloatingPanel.positionKey)
    }

    private static func savedOrigin(size: NSSize) -> NSPoint {
        if let arr = UserDefaults.standard.array(forKey: positionKey) as? [Double], arr.count == 2 {
            let pt = NSPoint(x: arr[0], y: arr[1])
            if NSScreen.screens.contains(where: { $0.frame.intersects(NSRect(origin: pt, size: size)) }) {
                return pt
            }
        }
        // Default: bottom-right of main screen
        if let screen = NSScreen.main {
            return NSPoint(x: screen.visibleFrame.maxX - size.width - 20,
                           y: screen.visibleFrame.minY + 80)
        }
        return NSPoint(x: 100, y: 100)
    }
}
