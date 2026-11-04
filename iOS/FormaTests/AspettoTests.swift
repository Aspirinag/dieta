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

    private func luminanza(_ c: (Double, Double, Double)) -> Double {
        let l = [c.0, c.1, c.2].map { $0 <= 0.03928 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4) }
        return 0.2126 * l[0] + 0.7152 * l[1] + 0.0722 * l[2]
    }

    // Il testo sull'accento si legge (almeno 4,5:1) in chiaro e in scuro
    @Test func testoSullAccentoHaContrasto() {
        for stile in [UIUserInterfaceStyle.light, .dark] {
            let a = luminanza(componenti(Colori.accento, stile)), t = luminanza(componenti(Colori.sulAccento, stile))
            #expect((max(a, t) + 0.05) / (min(a, t) + 0.05) >= 4.5)
        }
    }
}
