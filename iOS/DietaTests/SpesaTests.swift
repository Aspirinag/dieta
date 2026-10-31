import XCTest
@testable import Dieta

final class SpesaTests: XCTestCase {
    private func quanto(_ quantita: [String], nome: String = "Riso") -> String {
        var c = Profilo.Conto(nome: nome, profilo: "")
        quantita.forEach { c.aggiungi($0) }
        return c.quanto
    }

    func testSommaIGrammi() {
        XCTAssertEqual(quanto(["70 g", "70g", "60 gr"]), "200 g")
    }

    func testDaMilleGrammiPassaAiChili() {
        XCTAssertEqual(quanto(["700 g", "500 g"]), "1,2 kg")
    }

    func testDiDueAlternativeValeLaPrima() {
        XCTAssertEqual(quanto(["40g/120g"]), "40 g")
        XCTAssertEqual(quanto(["100ml o n°1"]), "100 ml")
    }

    func testIPezziSiContano() {
        XCTAssertEqual(quanto(["n°1", "n°2"], nome: "Banana"), "×3")
    }

    func testSenzaQuantitaLeggibileEQb() {
        XCTAssertEqual(quanto(["libera"]), "q.b.")
    }
}
