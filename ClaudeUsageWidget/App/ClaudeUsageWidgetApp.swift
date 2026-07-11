import SwiftUI

@main
struct ClaudeUsageWidgetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Boş Settings sahne — Cmd+, kısayolunu etkinleştirmek için
        Settings {
            EmptyView()
        }
    }
}
