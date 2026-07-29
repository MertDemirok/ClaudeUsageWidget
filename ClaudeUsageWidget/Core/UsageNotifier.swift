import Foundation
import UserNotifications

/// 5 saatlik oturum kullanımı eşikleri aşınca macOS bildirimi gönderir.
@MainActor
final class UsageNotifier: NSObject, UNUserNotificationCenterDelegate {
    static let shared = UsageNotifier()

    private let thresholds = [80, 95]
    private var notifiedThresholds: Set<Int> = []
    private var lastPercent: Double = 0

    func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// Her refresh sonrası çağrılır. Eşik aşıldıysa bir kez bildirir;
    /// oturum sıfırlanınca (yüzde belirgin düşünce) eşikler tekrar tetiklenir.
    func evaluate(percent: Double, enabled: Bool) {
        guard enabled else { return }
        if percent < lastPercent - 10 {
            notifiedThresholds.removeAll()
        }
        lastPercent = percent

        for t in thresholds where percent >= Double(t) && !notifiedThresholds.contains(t) {
            notifiedThresholds.insert(t)
            send(threshold: t)
        }
    }

    private func send(threshold: Int) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notify.title")
        content.body = String(format: String(localized: "notify.body"), threshold)
        content.sound = .default
        let req = UNNotificationRequest(identifier: "usage-\(threshold)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }

    // Uygulama önplandayken de bildirimi göster
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
