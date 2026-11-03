import Testing
import SwiftUI
import UIKit
@testable import Forma

@MainActor
struct AspettoTests {
    private func componenti(_ colore: Color, _ stile: UIUserInterfaceStyle) -> (Double, Double, Double) {
        let ui = UIColor(colore).resolvedColor(with: UITraitCollection(userInterfaceStyle: stile))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }

    private func vicino(_ c: (Double, Double, Double), _ esa: UInt32) -> Bool {
        abs(c.0 - Double((esa >> 16) & 0xFF) / 255) < 0.01
            && abs(c.1 - Double((esa >> 8) & 0xFF) / 255) < 0.01
            && abs(c.2 - Double(esa & 0xFF) / 255) < 0.01
    }

    @Test func accentoHaDueVarianti() {
        #expect(vicino(componenti(Colori.accento, .light), 0x2F6B4F))
        #expect(vicino(componenti(Colori.accento, .dark), 0x7FB89A))
    }
}
