import Foundation
import SwiftData

/// Tek bir zaman noktasındaki kullanım anlık görüntüsü.
/// Her refresh'te (5/10/30 dk) kaydedilir, chart bu kayıtlardan çizilir.
@Model
final class UsageSnapshot {
    var timestamp: Date
    var fiveHourPercent: Double
    var weeklyPercent: Double

    init(timestamp: Date = .now, fiveHourPercent: Double, weeklyPercent: Double) {
        self.timestamp = timestamp
        self.fiveHourPercent = fiveHourPercent
        self.weeklyPercent = weeklyPercent
    }
}
