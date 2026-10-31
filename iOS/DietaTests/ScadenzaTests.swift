import XCTest
@testable import Dieta

final class ScadenzaTests: XCTestCase {
    private let adesso = Date(timeIntervalSince1970: 1_793_000_000)

    private func data(_ s: String) -> Date { ISO8601DateFormatter().date(from: s)! }

    // Il profilo di firma è un plist racchiuso tra byte binari
    private func profilo(scadenza: String) -> Data {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <plist version="1.0"><dict><key>ExpirationDate</key><date>\(scadenza)</date></dict></plist>
        """
        return Data([0x30, 0x82, 0xFF, 0x00]) + Data(xml.utf8) + Data([0xA0, 0x00, 0xFE])
    }

    func testLeggeLaScadenzaDalProfiloDiFirma() {
        XCTAssertEqual(Scadenza.leggi(profilo(scadenza: "2026-11-07T08:30:00Z")), data("2026-11-07T08:30:00Z"))
    }

    func testUnFileSenzaPlistNonHaScadenza() {
        XCTAssertNil(Scadenza.leggi(Data([0x30, 0x82, 0x00])))
    }

    func testGliAvvisiArrivanoDueGiorniEUnGiornoPrimaAlleDieci() {
        let c = Giorni.calendario
        let scadenza = c.date(from: DateComponents(year: 2026, month: 11, day: 7, hour: 8))!
        let prima = c.date(from: DateComponents(year: 2026, month: 11, day: 1))!
        XCTAssertEqual(Scadenza.avvisi(scadenza, adesso: prima), [
            c.date(from: DateComponents(year: 2026, month: 11, day: 5, hour: 10))!,
            c.date(from: DateComponents(year: 2026, month: 11, day: 6, hour: 10))!,
        ])
    }

    func testGliAvvisiGiaPassatiNonSiProgrammano() {
        let c = Giorni.calendario
        let scadenza = c.date(from: DateComponents(year: 2026, month: 11, day: 7, hour: 8))!
        let dopoIlPrimo = c.date(from: DateComponents(year: 2026, month: 11, day: 5, hour: 11))!
        XCTAssertEqual(Scadenza.avvisi(scadenza, adesso: dopoIlPrimo).count, 1)
    }

    func testNessunMessaggioQuandoMancanoPiuDiDueGiorni() {
        XCTAssertNil(Scadenza.messaggio(adesso.addingTimeInterval(3 * 86_400), adesso: adesso))
    }

    func testMessaggioQuandoMancaUnGiorno() throws {
        let m = try XCTUnwrap(Scadenza.messaggio(adesso.addingTimeInterval(30 * 3600), adesso: adesso))
        XCTAssertTrue(m.contains("domani"), m)
    }

    func testMessaggioQuandoScadeOggi() throws {
        let inizio = Giorni.calendario.startOfDay(for: adesso)
        let scadenza = inizio.addingTimeInterval(20 * 3600)
        let m = try XCTUnwrap(Scadenza.messaggio(scadenza, adesso: inizio.addingTimeInterval(3600)))
        XCTAssertTrue(m.contains("oggi"), m)
    }
}
