import SwiftUI
import PhosphorSwift

struct CharacterWidgetView: View {
    @ObservedObject var store: UsageDataStore
    @State private var isHovered = false
    @State private var bobOffset: CGFloat = 0

    private let orbSize: CGFloat = 64
    private let ringSize: CGFloat = 76

    var body: some View {
        ZStack {
            outerRing
            orb
        }
        .frame(width: ringSize, height: ringSize)
        .scaleEffect(isHovered ? 1.08 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
        .offset(y: bobOffset)
        .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: bobOffset)
        .padding(28) // gölgeye nefes alanı
        .onHover { hovered in
            withAnimation(.easeInOut(duration: 0.18)) { isHovered = hovered }
        }
        .onAppear { bobOffset = -5 }
        .contextMenu {
            Button {
                store.isWidgetVisible = false
            } label: {
                Label(title: { Text("widget.hide") },
                      icon: { Ph.eyeSlash.regular.resizable().scaledToFit().frame(width: 13, height: 13) })
            }
        }
    }

    // MARK: - Outer Ring

    private var outerRing: some View {
        let pct = store.percentUsed
        return ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 4)

            Circle()
                .trim(from: 0, to: pct / 100)
                .stroke(Color.white.opacity(0.88),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: pct)

            if pct > 2 {
                Circle()
                    .trim(from: max(0, pct / 100 - 0.02), to: pct / 100)
                    .stroke(Color.white.opacity(0.5), lineWidth: 6)
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 3)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: pct)
            }
        }
        .frame(width: ringSize, height: ringSize)
    }

    // MARK: - Orb

    private var orb: some View {
        ZStack {
            Circle()
                .fill(orbGradient)
                .shadow(color: orbGlowColor.opacity(0.55), radius: 10, y: 2)
                .shadow(color: .black.opacity(0.3), radius: 4, y: 3)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.clear, Color.black.opacity(0.2)],
                        center: .init(x: 0.5, y: 0.8),
                        startRadius: 0,
                        endRadius: orbSize * 0.5
                    )
                )

            // Glass shine
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.52), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 14
                    )
                )
                .frame(width: 26, height: 14)
                .offset(x: -9, y: -14)
                .blur(radius: 2)
        }
        .frame(width: orbSize, height: orbSize)
    }

    // MARK: - Helpers

    private var orbGradient: RadialGradient {
        let pct = store.percentUsed
        let colors: [Color]
        if pct >= 90 {
            colors = [
                Color(red: 0.85, green: 0.20, blue: 0.20),
                Color(red: 0.55, green: 0.05, blue: 0.05),
                Color(red: 0.25, green: 0.00, blue: 0.00)
            ]
        } else if pct >= 75 {
            colors = [
                Color(red: 0.90, green: 0.38, blue: 0.12),
                Color(red: 0.62, green: 0.18, blue: 0.02),
                Color(red: 0.30, green: 0.06, blue: 0.00)
            ]
        } else {
            colors = [
                Color(red: 0.93, green: 0.58, blue: 0.36),
                Color(red: 0.76, green: 0.36, blue: 0.15),
                Color(red: 0.40, green: 0.12, blue: 0.02)
            ]
        }
        return RadialGradient(
            colors: colors,
            center: .init(x: 0.35, y: 0.3),
            startRadius: 0,
            endRadius: orbSize * 0.72
        )
    }

    private var orbGlowColor: Color {
        switch store.urgencyLevel {
        case .calm:     return Color(red: 0.831, green: 0.463, blue: 0.282)
        case .moderate: return Color(red: 0.85, green: 0.30, blue: 0.10)
        case .warning:  return Color(red: 0.90, green: 0.20, blue: 0.10)
        case .critical: return .red
        }
    }
}
