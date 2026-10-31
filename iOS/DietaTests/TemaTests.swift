import XCTest
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
        XCTAssertEqual(Stato.iniziale.tema, nil)
        XCTAssertEqual(Tema.scelto(Stato.iniziale.tema), .halloween)
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

    func testSoloGiornoEChiaro() {
        XCTAssertEqual(Tema.allCases.filter { $0.schemaColori == .light }, [.giorno])
    }
}
