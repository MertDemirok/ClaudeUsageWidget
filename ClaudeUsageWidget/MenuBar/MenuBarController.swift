import AppKit
import Combine
import SwiftUI
import PhosphorSwift

@MainActor
final class MenuBarController {
    private var statusItem: NSStatusItem!
    private var popoverPanel: NSPanel?
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    private let store: UsageDataStore

    init(store: UsageDataStore) {
        self.store = store
        setupStatusItem()
        bindStore()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }
        button.action = #selector(togglePopover)
        button.target = self
        updateButton(pct: 0, loading: true)
    }

    private func bindStore() {
        store.$fiveHourPeriod
            .combineLatest(store.$isLoading, store.$errorMessage)
            .receive(on: RunLoop.main)
            .sink { [weak self] period, loading, err in
                self?.updateButton(pct: period?.percent ?? 0, loading: loading, hasError: err != nil)
            }
            .store(in: &cancellables)
    }

    private func updateButton(pct: Double, loading: Bool, hasError: Bool = false) {
        guard let button = statusItem.button else { return }

        if loading {
            setButtonImage(render(Ph.circleDashed.regular), tint: .gray, button: button)
            button.title = ""
            return
        }
        if hasError {
            setButtonImage(render(Ph.warningCircle.regular), tint: .systemRed, button: button)
            button.title = ""
            return
        }

        let phImage: NSImage?
        switch pct {
        case ..<50:   phImage = render(Ph.circle.regular)
        case 50..<75: phImage = render(Ph.circleHalf.regular)
        case 75..<90: phImage = render(Ph.warning.regular)
        default:      phImage = render(Ph.warningCircle.regular)
        }

        setButtonImage(phImage, tint: urgencyNSColor(pct: pct), button: button)
        button.title = " \(Int(pct))%"
        button.imagePosition = .imageLeft
    }

    private func render(_ image: Image, size: CGFloat = 14) -> NSImage? {
        let renderer = ImageRenderer(
            content: image.resizable().scaledToFit().frame(width: size, height: size)
        )
        renderer.scale = 2.0
        return renderer.nsImage
    }

    @objc private func togglePopover() {
        if let panel = popoverPanel, panel.isVisible {
            hidePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button,
              let buttonWindow = button.window else { return }

        let screen = buttonWindow.screen ?? NSScreen.main ?? NSScreen.screens[0]

        // Button'ın yatay merkezini ekran koordinatlarında bul
        let buttonRect = buttonWindow.convertToScreen(
            button.convert(button.bounds, to: nil)
        )

        let width: CGFloat = 280
        let height: CGFloat = 480

        // X: tıklanan ikona ortalı, ekrandan taşmasın
        let x = max(
            screen.visibleFrame.minX + 8,
            min(buttonRect.midX - width / 2, screen.visibleFrame.maxX - width - 8)
        )
        // Y: menu bar'ın hemen altı (visibleFrame.maxY = menu bar'ın alt kenarı)
        let y = screen.visibleFrame.maxY - height - 4

        if popoverPanel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: x, y: y, width: width, height: height),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = true
            panel.level = .popUpMenu
            let hostingView = NSHostingView(rootView: MenuBarPopoverView(store: store))
            hostingView.wantsLayer = true
            hostingView.layer?.backgroundColor = .clear
            hostingView.layer?.borderWidth = 0
            panel.contentView = hostingView
            popoverPanel = panel
        }

        popoverPanel?.setFrameOrigin(NSPoint(x: x, y: y))
        popoverPanel?.orderFront(nil)

        // Dışarı tıklayınca kapat
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            self?.hidePopover()
        }
    }

    private func hidePopover() {
        popoverPanel?.orderOut(nil)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func setButtonImage(_ img: NSImage?, tint: NSColor, button: NSButton) {
        guard let img else { return }
        img.size = NSSize(width: 14, height: 14)
        let colored = img.tinted(with: tint)
        colored.isTemplate = false
        button.image = colored
    }

    private func urgencyNSColor(pct: Double) -> NSColor {
        switch pct {
        case ..<60: return NSColor(red: 0.831, green: 0.463, blue: 0.282, alpha: 1)
        case 60..<80: return NSColor(red: 0.85, green: 0.30, blue: 0.10, alpha: 1)
        default: return .systemRed
        }
    }
}

private extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let copy = self.copy() as! NSImage
        copy.lockFocus()
        color.set()
        NSRect(origin: .zero, size: copy.size).fill(using: .sourceAtop)
        copy.unlockFocus()
        return copy
    }
}
