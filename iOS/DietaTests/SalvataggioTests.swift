import XCTest
@testable import Dieta

final class SalvataggioTests: XCTestCase {
    private var cartella: URL!
    private var file: URL { cartella.appending(path: "dieta.json") }
    private var copie: URL { cartella.appending(path: "copie") }

    override func setUpWithError() throws {
        cartella = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: cartella)
    }

    private func archivio() -> Archivio { Archivio(file: file, copie: copie) }

    private func copieConservate() -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: copie, includingPropertiesForKeys: nil)) ?? []
    }

    func testIDatiSalvatiSiRileggono() {
        let a = archivio()
        a.stato.profili[a.stato.attivo]?.nome = "Salvato"
        a.salvaSubito()
        XCTAssertEqual(archivio().profilo.nome, "Salvato")
    }

    func testUnFileIlleggibileVieneConservato() throws {
        let rotto = Data(#"{"profili":{"r":{"nome":"DATI VERI"#.utf8)
        try rotto.write(to: file)

        let a = archivio()

        XCTAssertEqual(copieConservate().count, 1)
        XCTAssertEqual(try Data(contentsOf: copieConservate()[0]), rotto)
        XCTAssertNotNil(a.avvisoDati)
    }

    func testDopoUnFileIlleggibileLaCopiaSopravviveAlSalvataggio() throws {
        let rotto = Data("non è json".utf8)
        try rotto.write(to: file)

        let a = archivio()
        a.stato.profili[a.stato.attivo]?.olioTot = 7
        a.salvaSubito()

        XCTAssertEqual(try Data(contentsOf: copieConservate()[0]), rotto)
    }

    func testSenzaUnaCopiaNonSiSovrascriveIlFileIlleggibile() throws {
        let rotto = Data("non è json".utf8)
        try rotto.write(to: file)
        // Al posto della cartella delle copie c'è un file: la copia non si può fare
        try Data().write(to: copie)

        let a = archivio()
        a.stato.profili[a.stato.attivo]?.olioTot = 7
        a.salvaSubito()

        XCTAssertEqual(try Data(contentsOf: file), rotto)
        XCTAssertNotNil(a.erroreSalvataggio)
    }

    func testIlPrimoAvvioNonMostraAvvisi() {
        let a = archivio()
        XCTAssertNil(a.avvisoDati)
        XCTAssertTrue(copieConservate().isEmpty)
    }

    // Un valore che JSON non sa scrivere non deve svuotare il file
    func testSeLaCodificaFallisceIlFileResta() throws {
        let a = archivio()
        a.stato.profili[a.stato.attivo]?.nome = "Salvato"
        a.salvaSubito()
        let prima = try Data(contentsOf: file)

        a.stato.profili[a.stato.attivo]?.pesate["2026-10-31"] = .nan
        a.salvaSubito()

        XCTAssertEqual(try Data(contentsOf: file), prima)
        XCTAssertNotNil(a.erroreSalvataggio)
    }
}
