import XCTest
@testable import Dieta

final class PianiTests: XCTestCase {
    private func piano(_ nome: String, dal: String, al: String = "") -> Piano {
        let giorni = Giorni.nomi.map { GiornoPiano(nome: $0, palestra: false, pasti: []) }
        return Piano(nome: nome, dal: dal, al: al, giorni: giorni)
    }

    func testPianoConLaDataPiuRecenteVince() {
        var p = Profilo(nome: "Prova")
        p.piani = [piano("Nuovo", dal: "2026-10-20"), piano("Vecchio", dal: "2026-10-01")]
        XCTAssertEqual(p.piano(per: "2026-10-31")?.nome, "Nuovo")
    }

    // Ricaricare lo stesso giorno un PDF corretto, con un altro nome: deve valere l'ultimo caricato
    func testConLaStessaDataVinceLUltimoCaricato() {
        var p = Profilo(nome: "Prova")
        p.piani = [piano("Vecchio", dal: "2026-10-31"), piano("Corretto", dal: "2026-10-31")]
        XCTAssertEqual(p.piano(per: "2026-10-31")?.nome, "Corretto")
    }

    func testPianoChiusoNonValeDopoLaFine() {
        var p = Profilo(nome: "Prova")
        p.piani = [piano("Chiuso", dal: "2026-10-01", al: "2026-10-30")]
        XCTAssertNil(p.piano(per: "2026-10-31"))
    }
}
