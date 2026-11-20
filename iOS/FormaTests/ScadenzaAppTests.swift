import XCTest
@testable import Forma

final class ScadenzaAppTests: XCTestCase {
    private var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "Europe/Rome")!; return c }
    private func data(_ g: Int, _ h: Int, _ m: Int = 0) -> Date { cal.date(from: DateComponents(year: 2026, month: 11, day: g, hour: h, minute: m))! }

    func testAvvisoDueGiorniPrimaAlle9() {
        let q = ScadenzaApp.momentoAvviso(scadenza: data(22, 15), adesso: data(15, 12), calendario: cal)
        XCTAssertEqual(q, data(20, 9))
    }

    func testGiaDentroGliUltimiDueGiorniAvvisaTraUnMinuto() {
        let adesso = data(21, 10)
        XCTAssertEqual(ScadenzaApp.momentoAvviso(scadenza: data(22, 15), adesso: adesso, calendario: cal), adesso.addingTimeInterval(60))
    }

    func testGiaScadutaNessunAvviso() {
        XCTAssertNil(ScadenzaApp.momentoAvviso(scadenza: data(22, 15), adesso: data(23, 8), calendario: cal))
    }

    func testLeggeLaScadenzaDalProfilo() {
        let plist = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><plist version=\"1.0\"><dict><key>ExpirationDate</key><date>2026-11-22T14:00:00Z</date></dict></plist>"
        var d = Data([0x30, 0x82, 0x01, 0xFF]); d.append(Data(plist.utf8)); d.append(Data([0x00, 0x11]))
        XCTAssertEqual(ScadenzaApp.scadenza(dalProfilo: d), ISO8601DateFormatter().date(from: "2026-11-22T14:00:00Z"))
    }

    func testProfiloIllegibileNessunaScadenza() {
        XCTAssertNil(ScadenzaApp.scadenza(dalProfilo: Data([1, 2, 3])))
    }

    func testAvvisoInAppNegliUltimiDueGiorni() {
        let scadenza = data(22, 15)
        XCTAssertNil(ScadenzaApp.avvisoInApp(scadenza: scadenza, adesso: data(17, 12), calendario: cal))
        XCTAssertNotNil(ScadenzaApp.avvisoInApp(scadenza: scadenza, adesso: data(20, 8), calendario: cal))
        XCTAssertNotNil(ScadenzaApp.avvisoInApp(scadenza: scadenza, adesso: data(21, 10), calendario: cal))
        XCTAssertNotNil(ScadenzaApp.avvisoInApp(scadenza: scadenza, adesso: data(22, 10), calendario: cal))
        XCTAssertNil(ScadenzaApp.avvisoInApp(scadenza: scadenza, adesso: data(22, 16), calendario: cal))
    }
}
