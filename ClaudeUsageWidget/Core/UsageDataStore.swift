import Foundation
import Combine

/// Uygulama genel yapılandırma bayrakları.
enum AppConfig {
    /// Gezinen (floating) orb widget'ı şimdilik kapalı — ileride açılacak.
    static let floatingWidgetEnabled = false
}

@MainActor
final class UsageDataStore: ObservableObject {
    @Published var fiveHourPeriod: UsagePeriod? = nil
    @Published var sevenDayPeriod: UsagePeriod? = nil
    @Published var modelPeriods: [(label: String, period: UsagePeriod)] = []
    @Published var account: AccountResponse? = nil
    @Published var lastUpdated: Date? = nil
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false
    @Published var sessionCookie: String = ""

    // Kullanım geçmişi (yerel SwiftData) — chart bunu kullanır
    @Published var historySnapshots: [UsageSnapshot] = []
    private let history = UsageHistoryStore()

    // Widget visibility — persisted
    @Published var isWidgetVisible: Bool = true {
        didSet { UserDefaults.standard.set(isWidgetVisible, forKey: "widgetVisible") }
    }

    // Refresh interval in minutes; 0 = manual only — persisted
    @Published var refreshIntervalMinutes: Int = 5 {
        didSet {
            UserDefaults.standard.set(refreshIntervalMinutes, forKey: "refreshInterval")
            restartTimer()
        }
    }

    private let client = UsageAPIClient()
    private var timer: AnyCancellable?
    private let cookieKey = "sessionCookie"

    var percentUsed: Double { fiveHourPeriod?.percent ?? 0 }
    var resetAt: Date? { fiveHourPeriod?.resetDate }
    var weeklyPercent: Double { sevenDayPeriod?.percent ?? 0 }
    var weeklyResetAt: Date? { sevenDayPeriod?.resetDate }

    init() {
        isWidgetVisible = UserDefaults.standard.object(forKey: "widgetVisible") as? Bool ?? true
        refreshIntervalMinutes = UserDefaults.standard.object(forKey: "refreshInterval") as? Int ?? 5
        sessionCookie = KeychainStore.load(key: cookieKey) ?? ""
        historySnapshots = history.recentSnapshots(days: 30)
        if !sessionCookie.isEmpty { Task { await refresh() } }
        restartTimer()
    }

    func saveCookie(_ cookie: String) {
        sessionCookie = cookie.trimmingCharacters(in: .whitespacesAndNewlines)
        _ = KeychainStore.save(key: cookieKey, value: sessionCookie)
        Task { await client.invalidateOrgCache(); await refresh() }
    }

    func clearCookie() {
        sessionCookie = ""
        KeychainStore.delete(key: cookieKey)
        fiveHourPeriod = nil; sevenDayPeriod = nil; modelPeriods = []
        account = nil; errorMessage = nil
    }

    func refresh() async {
        guard !sessionCookie.isEmpty else {
            errorMessage = String(localized: "error.no_cookie"); return
        }
        isLoading = true; errorMessage = nil
        if lastUpdated == nil {
            account = await client.fetchAccount(sessionCookie: sessionCookie)
        }
        do {
            let r = try await client.fetchUsage(sessionCookie: sessionCookie)
            fiveHourPeriod = r.fiveHour
            sevenDayPeriod = r.sevenDay

            var periods: [(String, UsagePeriod)] = []
            func add(_ key: String, _ p: UsagePeriod?) {
                if let p, !p.isNull { periods.append((key, p)) }
            }
            add(String(localized: "usage.opus"),   r.sevenDayOpus)
            add(String(localized: "usage.sonnet"), r.sevenDaySonnet)
            add(String(localized: "usage.fable"),  r.tangelo)
            add(String(localized: "usage.cowork"), r.sevenDayCowork)
            add(String(localized: "usage.code"),   r.iguanaNecktie)
            add(String(localized: "usage.oauth"),  r.sevenDayOauthApps)
            add(String(localized: "usage.other"),  r.sevenDayOmelette)
            modelPeriods = periods
            lastUpdated = Date()

            // Anlık görüntüyü yerel geçmişe kaydet ve chart'ı güncelle
            history.record(fiveHour: fiveHourPeriod?.percent ?? 0,
                           weekly: sevenDayPeriod?.percent ?? 0)
            historySnapshots = history.recentSnapshots(days: 30)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func restartTimer() {
        timer?.cancel()
        guard refreshIntervalMinutes > 0 else { return }
        let interval = TimeInterval(refreshIntervalMinutes * 60)
        timer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                Task { await self.refresh() }
            }
    }

    var urgencyLevel: UrgencyLevel {
        switch percentUsed {
        case ..<50: return .calm
        case 50..<75: return .moderate
        case 75..<90: return .warning
        default: return .critical
        }
    }
}

enum UrgencyLevel {
    case calm, moderate, warning, critical
    var label: String {
        switch self {
        case .calm:     return String(localized: "urgency.calm")
        case .moderate: return String(localized: "urgency.moderate")
        case .warning:  return String(localized: "urgency.warning")
        case .critical: return String(localized: "urgency.critical")
        }
    }
}
