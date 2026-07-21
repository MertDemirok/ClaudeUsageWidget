import SwiftUI
import Charts

/// Chart zaman aralıkları.
enum HistoryRange: String, CaseIterable, Identifiable {
    case day, week, month
    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .day:   return "range.day"
        case .week:  return "range.week"
        case .month: return "range.month"
        }
    }

    /// Kaç günlük pencere.
    var days: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        }
    }

    /// Grafiği sadeleştirmek için bucket süresi (0 = ham veri).
    var bucket: TimeInterval {
        switch self {
        case .day:   return 0            // ham
        case .week:  return 3600         // saatlik
        case .month: return 6 * 3600     // 6 saatlik
        }
    }
}

/// Kullanım geçmişini seçilebilir aralıkla (1 gün / 1 hafta / 1 ay) çizen mini chart.
struct UsageHistoryChart: View {
    let snapshots: [UsageSnapshot]
    @State private var range: HistoryRange = .day

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("section.history")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
                    .textCase(.uppercase)
                    .tracking(1)
                Spacer()
                if let latest = snapshots.last {
                    Text("\(Int(latest.fiveHourPercent))%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.claudeOrange.opacity(0.9))
                }
            }

            Picker("", selection: $range) {
                ForEach(HistoryRange.allCases) { r in
                    Text(r.titleKey).tag(r)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .controlSize(.mini)

            if points.count < 2 {
                emptyState
            } else {
                chart
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Data

    private struct Point: Identifiable {
        let date: Date
        let value: Double
        var id: TimeInterval { date.timeIntervalSince1970 }
    }

    private var points: [Point] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -range.days, to: .now) ?? .now
        let windowed = snapshots.filter { $0.timestamp >= cutoff }

        guard range.bucket > 0 else {
            return windowed.map { Point(date: $0.timestamp, value: $0.fiveHourPercent) }
        }

        // Bucket başına en yüksek değer (tepe kullanım) — çizgiyi sadeleştirir
        var buckets: [TimeInterval: Double] = [:]
        for s in windowed {
            let key = (s.timestamp.timeIntervalSince1970 / range.bucket).rounded(.down) * range.bucket
            buckets[key] = max(buckets[key] ?? 0, s.fiveHourPercent)
        }
        return buckets
            .map { Point(date: Date(timeIntervalSince1970: $0.key), value: $0.value) }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Chart

    private var chart: some View {
        Chart(points) { pt in
            AreaMark(
                x: .value("Zaman", pt.date),
                y: .value("Kullanım", pt.value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                LinearGradient(
                    colors: [.claudeOrange.opacity(0.35), .claudeOrange.opacity(0.02)],
                    startPoint: .top, endPoint: .bottom
                )
            )

            LineMark(
                x: .value("Zaman", pt.date),
                y: .value("Kullanım", pt.value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(Color.claudeOrange)
            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(values: [0, 50, 100]) { _ in
                AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                AxisValueLabel()
                    .font(.system(size: 8))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine().foregroundStyle(Color.white.opacity(0.04))
                AxisValueLabel(format: xAxisFormat)
                    .font(.system(size: 8))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
        }
        .frame(height: 90)
    }

    private var xAxisFormat: Date.FormatStyle {
        switch range {
        case .day:   return .dateTime.hour()
        case .week:  return .dateTime.weekday(.abbreviated)
        case .month: return .dateTime.day().month(.abbreviated)
        }
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            Text("history.collecting")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.3))
            Spacer()
        }
        .frame(height: 90)
    }
}
