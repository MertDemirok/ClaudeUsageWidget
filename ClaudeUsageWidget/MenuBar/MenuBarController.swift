import AppKit
import Combine
import SwiftUI

@MainActor
final class MenuBarController {
    private var statusItem: NSStatusItem!
    private var popoverPanel: NSPanel?
    private var popoverHostingView: NSHostingView<MenuBarPopoverView>?
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

        let color: NSColor
        if loading { color = NSColor.secondaryLabelColor }
        else if hasError { color = .systemRed }
        else { color = urgencyNSColor(pct: pct) }

        button.image = renderTerrier(color: color)
        button.imagePosition = .imageLeft
        button.title = (loading || hasError) ? "" : " \(Int(pct))%"
    }

    /// Boston Terrier karakterini menü bar ikonu olarak NSImage'e render eder.
    private func renderTerrier(color: NSColor, size: CGFloat = 18) -> NSImage? {
        let view = BostonTerrierIcon(color: Color(nsColor: color))
            .frame(width: size, height: size)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        let img = renderer.nsImage
        img?.isTemplate = false
        return img
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

        if popoverPanel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: width, height: 480),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = true
            panel.level = .popUpMenu

            // Arka planda dark blur — cam (glass) etki için
            let blur = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: width, height: 480))
            blur.material = .hudWindow
            blur.blendingMode = .behindWindow
            blur.state = .active
            blur.wantsLayer = true
            blur.layer?.cornerRadius = 20
            blur.layer?.masksToBounds = true

            let hostingView = NSHostingView(rootView: MenuBarPopoverView(store: store))
            hostingView.wantsLayer = true
            hostingView.layer?.backgroundColor = .clear
            hostingView.layer?.borderWidth = 0
            hostingView.frame = blur.bounds
            hostingView.autoresizingMask = [.width, .height]
            blur.addSubview(hostingView)

            panel.contentView = blur
            popoverPanel = panel
            popoverHostingView = hostingView
        }

        // İçeriğin gerçek yüksekliğini hesapla ve paneli ona göre boyutla
        popoverHostingView?.layoutSubtreeIfNeeded()
        let contentHeight = popoverHostingView?.fittingSize.height ?? 480
        popoverPanel?.setContentSize(NSSize(width: width, height: contentHeight))

        // X: tıklanan ikona ortalı, ekrandan taşmasın
        let x = max(
            screen.visibleFrame.minX + 8,
            min(buttonRect.midX - width / 2, screen.visibleFrame.maxX - width - 8)
        )
        // Üst-sol köşeyi menü bar'ın hemen altına sabitle
        // (içerik yüksekliği değişse de kaymaması için setFrameTopLeftPoint)
        let topY = screen.visibleFrame.maxY - 4

        popoverPanel?.setFrameTopLeftPoint(NSPoint(x: x, y: topY))
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

    private func urgencyNSColor(pct: Double) -> NSColor {
        switch pct {
        case ..<60: return NSColor(red: 0.831, green: 0.463, blue: 0.282, alpha: 1)
        case 60..<80: return NSColor(red: 0.85, green: 0.30, blue: 0.10, alpha: 1)
        default: return .systemRed
        }
    }
}
