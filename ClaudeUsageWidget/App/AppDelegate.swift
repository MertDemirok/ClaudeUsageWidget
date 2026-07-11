import AppKit
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController!
    private var floatingPanel: FloatingPanel!
    private let store = UsageDataStore()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        menuBarController = MenuBarController(store: store)

        floatingPanel = FloatingPanel()
        let widgetView = NSHostingView(rootView: CharacterWidgetView(store: store))
        widgetView.wantsLayer = true
        widgetView.layer?.backgroundColor = .clear
        widgetView.layer?.borderWidth = 0
        floatingPanel.contentView = widgetView
        if store.isWidgetVisible { floatingPanel.orderFront(nil) }

        // Widget görünürlüğünü store'dan takip et
        store.$isWidgetVisible
            .receive(on: RunLoop.main)
            .sink { [weak self] visible in
                guard let self else { return }
                if visible { self.floatingPanel.orderFront(nil) }
                else { self.floatingPanel.orderOut(nil) }
            }
            .store(in: &cancellables)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(panelMoved),
            name: NSWindow.didMoveNotification,
            object: floatingPanel
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        floatingPanel.savePosition()
    }

    @objc private func panelMoved() {
        floatingPanel.savePosition()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
