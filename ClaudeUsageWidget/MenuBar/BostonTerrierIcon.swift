import SwiftUI

/// Menü bar için minik, ayakta duran Boston Terrier karakteri.
/// Tek renk siluet + yüz işaretleri (göz/alın çizgisi/burun) oyuk olarak —
/// hem koyu hem açık menü barda okunur.
struct BostonTerrierIcon: View {
    var color: Color = .white

    var body: some View {
        ZStack {
            TerrierSilhouette().fill(color)
            TerrierMarkings().fill(.black).blendMode(.destinationOut)
        }
        .compositingGroup()
    }
}

// 32x32 tasarım uzayından verilen rect'e ölçekleme yardımcıları
private func R(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, in r: CGRect) -> CGRect {
    CGRect(x: r.minX + x / 32 * r.width,
           y: r.minY + y / 32 * r.height,
           width: w / 32 * r.width,
           height: h / 32 * r.height)
}
private func P(_ x: CGFloat, _ y: CGFloat, in r: CGRect) -> CGPoint {
    CGPoint(x: r.minX + x / 32 * r.width, y: r.minY + y / 32 * r.height)
}
private func C(_ c: CGFloat, in r: CGRect) -> CGFloat { c / 32 * r.width }

struct TerrierSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()

        // Kulaklar (dik ama kısa/geniş — Boston Terrier tipi)
        p.move(to: P(8.5, 3.5, in: rect))
        p.addLine(to: P(13.5, 9.5, in: rect))
        p.addLine(to: P(6.5, 10, in: rect))
        p.closeSubpath()

        p.move(to: P(23.5, 3.5, in: rect))
        p.addLine(to: P(25.5, 10, in: rect))
        p.addLine(to: P(18.5, 9.5, in: rect))
        p.closeSubpath()

        // Kafa (kare-yuvarlak, hafif geniş)
        p.addRoundedRect(in: R(6.5, 6, 19, 15, in: rect),
                         cornerSize: CGSize(width: C(7, in: rect), height: C(7, in: rect)))

        // Gövde (oturur pozisyon)
        p.addRoundedRect(in: R(9, 16, 14, 13, in: rect),
                         cornerSize: CGSize(width: C(7, in: rect), height: C(7, in: rect)))

        // Ön ayaklar
        p.addRoundedRect(in: R(11, 25, 3.6, 6, in: rect),
                         cornerSize: CGSize(width: C(1.7, in: rect), height: C(1.7, in: rect)))
        p.addRoundedRect(in: R(17.4, 25, 3.6, 6, in: rect),
                         cornerSize: CGSize(width: C(1.7, in: rect), height: C(1.7, in: rect)))

        return p
    }
}

struct TerrierMarkings: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()

        // Alın–burun beyaz çizgisi (Boston Terrier imzası)
        p.addRoundedRect(in: R(14.7, 6.5, 2.6, 11, in: rect),
                         cornerSize: CGSize(width: C(1.3, in: rect), height: C(1.3, in: rect)))

        // Gözler
        p.addEllipse(in: R(11.4, 11.4, 3, 3, in: rect))
        p.addEllipse(in: R(17.6, 11.4, 3, 3, in: rect))

        // Burun
        p.addEllipse(in: R(14.9, 17, 2.2, 1.9, in: rect))

        // Göğüs beyazı
        p.addEllipse(in: R(14.4, 21.5, 3.2, 4.5, in: rect))

        return p
    }
}
