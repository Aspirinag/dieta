import XCTest
@testable import Dieta

final class GiornoTests: XCTestCase {
    private var cartella: URL!
    private let giorno = "2026-10-31"

    override func setUpWithError() throws {
        cartella = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: cartella)
    }

    private func archivio() -> Archivio {
        let a = Archivio(file: cartella.appending(path: "dieta.json"), copie: cartella.appending(path: "copie"))
        a.creaPrimoProfilo("Prova")
        return a
    }

    func testAcquaSuperaLObiettivo() {
        let a = archivio()
        a.profilo.acquaTot = 0.5
        for _ in 0..<3 { a.aggiungiAcqua(giorno) }
        XCTAssertEqual(a.registro(giorno).acqua, 0.75)
    }

    func testOlioSuperaLObiettivo() {
        let a = archivio()
        a.profilo.olioTot = 2
        for _ in 0..<3 { a.aggiungiOlio(giorno) }
        XCTAssertEqual(a.registro(giorno).olio, 3)
    }

    // Un tocco di troppo si corregge, senza andare sotto zero
    func testAcquaSiCorregge() {
        let a = archivio()
        a.aggiungiAcqua(giorno)
        a.aggiungiAcqua(giorno)
        a.togliAcqua(giorno)
        XCTAssertEqual(a.registro(giorno).acqua, 0.25)
        a.togliAcqua(giorno)
        a.togliAcqua(giorno)
        XCTAssertEqual(a.registro(giorno).acqua, 0)
    }

    func testOlioSiCorregge() {
        let a = archivio()
        a.aggiungiOlio(giorno)
        a.togliOlio(giorno)
        a.togliOlio(giorno)
        XCTAssertEqual(a.registro(giorno).olio, 0)
    }

    func testAcquaEOlioOltreLObiettivoRestanoDopoIlSalvataggio() throws {
        let a = archivio()
        a.profilo.olioTot = 1
        for _ in 0..<3 { a.aggiungiOlio(giorno) }
        let riletto = try JSONDecoder().decode(Stato.self, from: a.backup())
        XCTAssertEqual(riletto.profili[riletto.attivo]?.dieta[giorno]?.olio, 3)
    }

    // Il tema scelto in Profilo si ritrova alla prossima apertura
    func testIlTemaSceltoSiSalva() throws {
        let a = archivio()
        a.stato.tema = Tema.notte.rawValue
        let riletto = try JSONDecoder().decode(Stato.self, from: a.backup())
        XCTAssertEqual(Tema.scelto(riletto.tema), .notte)
    }

    func testSchedeInOrdine() {
        XCTAssertEqual(Scheda.allCases.map(\.rawValue), ["oggi", "dieta", "allenamento", "progressi", "profilo"])
    }

    func testDataEstesa() {
        XCTAssertEqual(Giorni.estesa("2026-10-31"), "Sabato 31 ottobre")
        XCTAssertEqual(Giorni.estesa("2026-11-01"), "Domenica 1 novembre")
    }

    // Prossimo pasto: il primo né segnato né fuori piano
    func testProssimoPasto() {
        let pasti = ["Colazione", "Pranzo", "Cena"].map { Pasto(nome: $0, opzioni: []) }
        var r = Registro()
        XCTAssertEqual(r.prossimoPasto(pasti), 0)
        r.slot["0"] = Slot(fatto: true)
        r.slot["1"] = Slot(altro: "Pizza")
        XCTAssertEqual(r.prossimoPasto(pasti), 2)
        r.slot["2"] = Slot(fatto: true)
        XCTAssertNil(r.prossimoPasto(pasti))
    }

    // Un'alternativa non più nel piano (piano cambiato) ripiega sulla prima
    func testOpzioneScelta() {
        let pasto = Pasto(nome: "Pranzo", opzioni: [Opzione(titolo: "Pasta", alimenti: []), Opzione(titolo: "Riso", alimenti: [])])
        XCTAssertEqual(pasto.opzione(Slot(opt: 1))?.titolo, "Riso")
        XCTAssertEqual(pasto.opzione(Slot(opt: 9))?.titolo, "Pasta")
    }

    func testRigheDiTestoInteroUnaPerParola() {
        XCTAssertEqual(TestoIntero.righe("Colazione"), 1)
        XCTAssertEqual(TestoIntero.righe("Spuntino pomeridiano"), 2)
        XCTAssertEqual(TestoIntero.righe(""), 1)
    }

    func testDescrizioneDegliAlimenti() {
        let o = Opzione(alimenti: [Alimento(nome: "Riso basmati", quantita: "70 g"), Alimento(nome: "Pollo al limone", quantita: " ")])
        XCTAssertEqual(o.descrizione, "Riso basmati 70 g · Pollo al limone")
    }
}
