import SwiftUI
import PhosphorSwift

extension Color {
    static let claudeOrange = Color(red: 0.831, green: 0.463, blue: 0.282)
    static let claudeDark   = Color(red: 0.071, green: 0.071, blue: 0.078)
}

struct MenuBarPopoverView: View {
    @ObservedObject var store: UsageDataStore
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 0) {
            header
            bodySection
            footer
        }
        .frame(width: 280)
        .background(Color.claudeDark)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .sheet(isPresented: $showingSettings) {
            SettingsView(store: store)
        }
    }

    // MARK: - Header

    private var header: some View {
        ZStack(alignment: .topTrailing) {
            // Background decorative circles
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 120, height: 120)
                .offset(x: 50, y: -30)
            Circle()
                .fill(Color.white.opacity(0.04))
                .frame(width: 70, height: 70)
                .offset(x: -80, y: 30)

            VStack(spacing: 14) {
                // Top row: avatar + name + refresh
                HStack(spacing: 10) {
                    characterBubble
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.account?.displayName ?? String(localized: "app.title"))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        if let email = store.account?.emailAddress {
                            Text(email)
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                    }
                    Spacer()
                    refreshButton
                }

                // Session ring + info
                HStack(spacing: 14) {
                    sessionRing
                    sessionInfo
                    Spacer()
                }
            }
            .padding(16)
        }
        .background(headerGradient)
        .clipped()
    }

    private var headerGradient: LinearGradient {
        let pct = store.percentUsed
        let colors: [Color]
        if pct >= 90 {
            colors = [
                Color(red: 0.70, green: 0.13, blue: 0.13),
                Color(red: 0.48, green: 0.00, blue: 0.00),
                Color(red: 0.29, green: 0.00, blue: 0.00)
            ]
        } else if pct >= 75 {
            colors = [
                Color(red: 0.77, green: 0.31, blue: 0.13),
                Color(red: 0.55, green: 0.17, blue: 0.00),
                Color(red: 0.35, green: 0.06, blue: 0.00)
            ]
        } else {
            colors = [
                Color(red: 0.77, green: 0.37, blue: 0.16),
                Color(red: 0.55, green: 0.18, blue: 0.00),
                Color(red: 0.35, green: 0.10, blue: 0.00)
            ]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var characterBubble: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.15))
                .shadow(color: .black.opacity(0.3), radius: 6, y: 3)

            // Inner top highlight for 3D glass effect
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.25), Color.clear],
                        startPoint: .top, endPoint: .center
                    )
                )

            Text(characterEmoji)
                .font(.system(size: 22))
        }
        .frame(width: 44, height: 44)
    }

    private var characterEmoji: String {
        switch store.urgencyLevel {
        case .calm:     return "😊"
        case .moderate: return "😐"
        case .warning:  return "😟"
        case .critical: return "🚨"
        }
    }

    private var refreshButton: some View {
        Button {
            Task { await store.refresh() }
        } label: {
            ZStack {
                Circle().fill(Color.white.opacity(0.12))
                if store.isLoading {
                    ProgressView().scaleEffect(0.5).tint(.white)
                } else {
                    Ph.arrowClockwise.regular.resizable().scaledToFit()
                        .frame(width: 12, height: 12)
                        .foregroundColor(Color.white.opacity(0.7))
                }
            }
            .frame(width: 26, height: 26)
        }
        .buttonStyle(.plain)
    }

    private var sessionRing: some View {
        let pct = store.percentUsed

        return ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 5)

            Circle()
                .trim(from: 0, to: pct / 100)
                .stroke(Color.white.opacity(0.9),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5), value: pct)

            VStack(spacing: 0) {
                Text("\(Int(pct))%")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("5H")
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(0.5)
            }
        }
        .frame(width: 56, height: 56)
    }

    private var sessionInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("section.current_session")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.8)

            Text("\(Int(store.percentUsed))% \(String(localized: "usage.used"))")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)

            if let date = store.resetAt {
                HStack(spacing: 3) {
                    Ph.arrowClockwise.regular.resizable().scaledToFit().frame(width: 9, height: 9)
                    Text(date, style: .relative)
                }
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.45))
            }
        }
    }

    // MARK: - Body

    private var bodySection: some View {
        VStack(spacing: 0) {
            if let err = store.errorMessage {
                errorView(err)
            } else if store.sessionCookie.isEmpty {
                emptyView
            } else {
                weeklyCard
                    .padding(.horizontal, 12)
                    .padding(.top, 12)

                if !store.modelPeriods.isEmpty {
                    modelSection
                        .padding(.horizontal, 12)
                        .padding(.top, 10)
                        .padding(.bottom, 4)
                }
            }
        }
        .background(Color.claudeDark)
    }

    private var weeklyCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("section.weekly")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
                    .textCase(.uppercase)
                    .tracking(1)
                Spacer()
                if let date = store.weeklyResetAt {
                    HStack(spacing: 3) {
                        Ph.arrowClockwise.regular.resizable().scaledToFit().frame(width: 9, height: 9)
                        Text(date, style: .relative)
                    }
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.25))
                }
            }
            .padding(.bottom, 8)

            HStack {
                Text(String(localized: "usage.all_models"))
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Text("\(Int(store.weeklyPercent))%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 6)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [.claudeOrange, Color(red: 1.0, green: 0.44, blue: 0.25)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * store.weeklyPercent / 100, height: 4)
                        .shadow(color: .claudeOrange.opacity(0.5), radius: 4)
                        .animation(.spring(response: 0.4), value: store.weeklyPercent)
                }
            }
            .frame(height: 4)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var modelSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("section.by_model")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
                    .textCase(.uppercase)
                    .tracking(1)
                Spacer()
            }
            .padding(.bottom, 6)

            ForEach(store.modelPeriods, id: \.label) { item in
                modelRow(label: item.label, period: item.period)
            }
        }
    }

    private func modelRow(label: String, period: UsagePeriod) -> some View {
        let pct = period.percent
        let unused = pct == 0 && period.resetsAt != nil
        let color = modelColor(label: label)

        return HStack(spacing: 8) {
            Circle()
                .fill(unused ? Color.white.opacity(0.15) : color)
                .frame(width: 6, height: 6)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(unused ? .white.opacity(0.3) : .white.opacity(0.65))
                .lineLimit(1)

            if unused {
                Spacer()
                Text("—")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.2))
            } else {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color.white.opacity(0.07))
                            .frame(height: 3)
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(color)
                            .frame(width: geo.size.width * pct / 100, height: 3)
                            .animation(.spring(response: 0.4), value: pct)
                    }
                }
                .frame(height: 3)

                Text("\(Int(pct))%")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 28, alignment: .trailing)
            }
        }
        .padding(.vertical, 5)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1)
        }
    }

    private func modelColor(label: String) -> Color {
        if label.contains("Opus")   { return Color(red: 0.55, green: 0.44, blue: 0.83) }
        if label.contains("Fable")  { return Color(red: 0.33, green: 0.75, blue: 0.55) }
        if label.contains("Code")   { return Color(red: 0.35, green: 0.65, blue: 0.95) }
        if label.contains("OAuth")  { return Color(red: 0.75, green: 0.55, blue: 0.35) }
        return .claudeOrange
    }

    // MARK: - Error / Empty

    private func errorView(_ msg: String) -> some View {
        HStack(spacing: 10) {
            Ph.warningCircle.fill
                .resizable().scaledToFit().frame(width: 18, height: 18)
                .foregroundColor(Color.claudeOrange)
            Text(msg)
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Ph.userCircleDashed.regular.resizable().scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(Color.claudeOrange.opacity(0.6))
            Text("empty.title")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
            Text("empty.subtitle")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            Button("action.open_settings") { showingSettings = true }
                .buttonStyle(.borderedProminent)
                .tint(.claudeOrange)
                .controlSize(.small)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 6) {
            if let t = store.lastUpdated {
                Text(t, style: .time)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.2))
            }
            Spacer()

            Button {
                store.isWidgetVisible.toggle()
            } label: {
                if store.isWidgetVisible {
                    Ph.eyeSlash.regular.resizable().scaledToFit().frame(width: 13, height: 13)
                } else {
                    Ph.eye.regular.resizable().scaledToFit().frame(width: 13, height: 13)
                }
            }
            .buttonStyle(.plain)
            .foregroundColor(.white.opacity(0.3))
            .help(store.isWidgetVisible
                  ? String(localized: "widget.hide")
                  : String(localized: "widget.show"))

            footerSep

            Button("action.settings") { showingSettings = true }
                .font(.system(size: 11))
                .buttonStyle(.plain)
                .foregroundColor(.claudeOrange.opacity(0.8))

            footerSep

            Button("action.quit") { NSApp.terminate(nil) }
                .font(.system(size: 11))
                .buttonStyle(.plain)
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.claudeDark)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1)
        }
    }

    private var footerSep: some View {
        Text("·").foregroundColor(.white.opacity(0.15)).font(.system(size: 11))
    }
}
