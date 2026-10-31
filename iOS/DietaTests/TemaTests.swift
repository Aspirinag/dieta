import XCTest
import SwiftUI
@testable import Dieta

final class TemaTests: XCTestCase {
    // Luminanza relativa WCAG 2.x di un colore 0xRRGGBB
    private func luminanza(_ hex: UInt32) -> Double {
        func canale(_ v: UInt32) -> Double {
            let c = Double(v) / 255
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * canale((hex >> 16) & 0xFF) + 0.7152 * canale((hex >> 8) & 0xFF) + 0.0722 * canale(hex & 0xFF)
    }

    private func contrasto(_ a: UInt32, _ b: UInt32) -> Double {
        let (x, y) = (luminanza(a), luminanza(b))
        return (max(x, y) + 0.05) / (min(x, y) + 0.05)
    }

    func testTemaAssenteEHalloween() {
        XCTAssertEqual(Tema.scelto(nil), .halloween)
        XCTAssertEqual(Stato.vuoto.tema, nil)
        XCTAssertEqual(Tema.scelto(Stato.vuoto.tema), .halloween)
    }

    func testTemaSconosciutoEHalloween() {
        XCTAssertEqual(Tema.scelto("arcobaleno"), .halloween)
        XCTAssertEqual(Tema.scelto("notte"), .notte)
    }

    func testOrdineDeiTemi() {
        XCTAssertEqual(Tema.allCases, [.halloween, .giorno, .notte, .ossidiana])
    }

    func testContrastoDeiTesti() {
        for tema in Tema.allCases {
            let p = tema.palette.esadecimali
            for sfondo in [p.schedaDa, p.schedaA] {
                for (nome, primo) in [("testo", p.testo), ("secondario", p.secondario), ("accento", p.accento)] {
                    XCTAssertGreaterThanOrEqual(contrasto(primo, sfondo), 4.5, "\(tema) \(nome) su \(String(sfondo, radix: 16))")
                }
            }
        }
    }

    func testNeonSoloSuiTastiNelTemaChiaro() {
        let giorno = Tema.giorno.palette.esadecimali
        XCTAssertEqual(giorno.tasto, 0x39FF14)
        XCTAssertNotEqual(giorno.accento, 0x39FF14)
        XCTAssertEqual(Tema.halloween.palette.esadecimali.tasto, 0x39FF14)
    }

    // Le tappe del fondo vengono dai disegni: 52% per tutti, 60% per Ossidiana
    func testTappeDelFondo() {
        XCTAssertEqual(Tema.halloween.palette.esadecimali.tappaFondo, 0.52)
        XCTAssertEqual(Tema.giorno.palette.esadecimali.tappaFondo, 0.52)
        XCTAssertEqual(Tema.notte.palette.esadecimali.tappaFondo, 0.52)
        XCTAssertEqual(Tema.ossidiana.palette.esadecimali.tappaFondo, 0.60)
    }

    // Etichette della barra delle schede e testi a colori sulle schede
    func testContrastoDiBarraEColori() {
        for tema in Tema.allCases {
            let p = tema.palette.esadecimali
            XCTAssertGreaterThanOrEqual(contrasto(p.secondario, p.barra), 4.5, tema.nome)
            XCTAssertGreaterThanOrEqual(contrasto(p.accento, p.barra), 4.5, tema.nome)
            XCTAssertGreaterThanOrEqual(contrasto(p.testo, p.riempimento), 4.5, tema.nome)
            for sfondo in [p.schedaDa, p.schedaA] {
                XCTAssertGreaterThanOrEqual(contrasto(p.caldo, sfondo), 4.5, tema.nome)
                XCTAssertGreaterThanOrEqual(contrasto(p.freddo, sfondo), 4.5, tema.nome)
            }
        }
    }

    func testSoloGiornoEChiaro() {
        XCTAssertEqual(Tema.allCases.filter { $0.schemaColori == .light }, [.giorno])
    }
}

final class FontTests: XCTestCase {
    // Se il nome non si risolve, SwiftUI ripiega in silenzio sul carattere di sistema
    func testIFontEsistono() {
        XCTAssertNotNil(UIFont(name: Font.nomeGeorgia, size: 34))
        XCTAssertNotNil(UIFont(name: Font.nomeGeorgiaGrassetto, size: 34))
    }

    // Barra del titolo e selettori segmentati: UIKit, fuori dalla portata di SwiftUI
    func testIFontUIKitSonoGeorgia() {
        XCTAssertEqual(UIFont.georgia(.largeTitle, grassetto: true).familyName, "Georgia")
        XCTAssertEqual(UIFont.georgia(.caption2).familyName, "Georgia")
    }
}

final class ContrastoPrimaAperturaTests: XCTestCase {
    private func luminanza(_ hex: UInt32) -> Double {
        func c(_ v: UInt32) -> Double { let x = Double(v) / 255; return x <= 0.03928 ? x / 12.92 : pow((x + 0.055) / 1.055, 2.4) }
        return 0.2126 * c((hex >> 16) & 0xFF) + 0.7152 * c((hex >> 8) & 0xFF) + 0.0722 * c(hex & 0xFF)
    }
    private func contrasto(_ a: UInt32, _ b: UInt32) -> Double {
        let (x, y) = (luminanza(a), luminanza(b))
        return (max(x, y) + 0.05) / (min(x, y) + 0.05)
    }

    // Il testo di dettaglio dei tasti di PrimaApertura: suTasto sul tasto pieno, secondario sulla scheda
    func testIlDettaglioDeiTastiSiLegge() {
        for tema in Tema.allCases {
            let e = tema.palette.esadecimali
            XCTAssertGreaterThanOrEqual(contrasto(e.suTasto, e.tasto), 4.5, tema.nome)
            XCTAssertGreaterThanOrEqual(contrasto(e.secondario, e.schedaDa), 4.5, tema.nome)
            XCTAssertGreaterThanOrEqual(contrasto(e.secondario, e.schedaA), 4.5, tema.nome)
        }
    }
}
