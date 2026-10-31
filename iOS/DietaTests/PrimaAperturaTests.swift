import XCTest
@testable import Dieta

final class PrimaAperturaTests: XCTestCase {
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

    func testNuovaInstallazioneNonHaProfili() {
        let a = archivio()
        XCTAssertTrue(a.senzaProfili)
        XCTAssertTrue(a.stato.profili.isEmpty)
        XCTAssertNil(a.avvisoDati)
    }

    func testConZeroProfiliNonSiScriveIlFile() {
        let a = archivio()
        a.stato.tema = "notte"
        a.salvaSubito()
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        XCTAssertNil(a.erroreSalvataggio)
        // E la riapertura resta una prima apertura, senza avvisi
        let b = archivio()
        XCTAssertTrue(b.senzaProfili)
        XCTAssertNil(b.avvisoDati)
    }

    func testIlPrimoProfiloDiventaAttivo() {
        let a = archivio()
        a.creaPrimoProfilo("  Giulia ")
        XCTAssertFalse(a.senzaProfili)
        XCTAssertEqual(a.stato.profili.count, 1)
        XCTAssertEqual(a.profilo.nome, "Giulia")
        XCTAssertNotNil(a.stato.profili[a.stato.attivo])
        a.salvaSubito()
        let b = archivio()
        XCTAssertFalse(b.senzaProfili)
        XCTAssertEqual(b.profilo.nome, "Giulia")
        XCTAssertNil(b.avvisoDati)
    }

    func testDatiEsistentiRestanoIntatti() throws {
        let s = Stato(profili: ["raffaele": Profilo(nome: "Raffaele"), "alessandra": Profilo(nome: "Alessandra")], attivo: "raffaele")
        try JSONEncoder().encode(s).write(to: file)
        let a = archivio()
        XCTAssertFalse(a.senzaProfili)
        XCTAssertEqual(Set(a.stato.profili.values.map(\.nome)), ["Raffaele", "Alessandra"])
    }

    func testNomeVuotoNonCreaProfili() {
        let a = archivio()
        a.creaPrimoProfilo("")
        a.creaPrimoProfilo("   \n ")
        XCTAssertTrue(a.senzaProfili)
        XCTAssertTrue(a.stato.profili.isEmpty)
    }

    func testImportareUnBackupSenzaProfiliTogliELaPrimaApertura() throws {
        let s = Stato(profili: ["x": Profilo(nome: "Da backup")], attivo: "x")
        let a = archivio()
        try a.importa(try JSONEncoder().encode(s))
        XCTAssertFalse(a.senzaProfili)
        XCTAssertEqual(a.profilo.nome, "Da backup")
    }
}
