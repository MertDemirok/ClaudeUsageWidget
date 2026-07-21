import Foundation
import SwiftData

/// Kullanım geçmişini yerel SwiftData veritabanında saklar.
/// Veri kullanıcının kendi Mac'inde kalır — ağ/kimlik bilgisi gerektirmez.
@MainActor
final class UsageHistoryStore {
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    /// Aynı dakika içinde tekrarlı manuel refresh'lerde spam kaydı önlemek için.
    private let minInterval: TimeInterval = 60

    init() {
        do {
            container = try ModelContainer(for: UsageSnapshot.self)
        } catch {
            fatalError("SwiftData container oluşturulamadı: \(error)")
        }
        pruneOld()
    }

    /// Yeni bir anlık görüntü kaydeder. Son kayıttan `minInterval` geçmediyse atlar.
    func record(fiveHour: Double, weekly: Double, at date: Date = .now) {
        if let last = lastSnapshot(), date.timeIntervalSince(last.timestamp) < minInterval {
            return
        }
        context.insert(UsageSnapshot(timestamp: date, fiveHourPercent: fiveHour, weeklyPercent: weekly))
        try? context.save()
    }

    /// Son `days` gündeki kayıtları zaman sırasıyla döndürür.
    func recentSnapshots(days: Int = 30) -> [UsageSnapshot] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        let descriptor = FetchDescriptor<UsageSnapshot>(
            predicate: #Predicate { $0.timestamp >= cutoff },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    private func lastSnapshot() -> UsageSnapshot? {
        var descriptor = FetchDescriptor<UsageSnapshot>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    /// 30 günden eski kayıtları temizler.
    private func pruneOld(keepDays: Int = 30) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -keepDays, to: .now) ?? .now
        let descriptor = FetchDescriptor<UsageSnapshot>(
            predicate: #Predicate { $0.timestamp < cutoff }
        )
        if let old = try? context.fetch(descriptor), !old.isEmpty {
            old.forEach { context.delete($0) }
            try? context.save()
        }
    }
}
