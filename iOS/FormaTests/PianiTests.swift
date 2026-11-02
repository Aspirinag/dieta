import Foundation
import Testing
@testable import Forma

// Piani alimentari: un piano ricaricato con la stessa data sostituisce il vecchio
// e le spunte dei giorni già segnati seguono il nome del pasto
@MainActor
struct PianiTests {
    private func piano(_ nome: String, dal: String, pasti: [String]) -> Piano {
        let g = Giorni.nomi.map { GiornoPiano(nome: $0, palestra: false, pasti: pasti.map { Pasto(nome: $0, opzioni: [Opzione(alimenti: [])]) }) }
        return Piano(nome: nome, dal: dal, al: "", giorni: g)
    }

    @Test func stessaDataSostituisceIlVecchio() {
        var p = Profilo(nome: "Io")
        p.aggiungiPiano(piano("A", dal: "2026-11-02", pasti: ["Pranzo", "Cena"]))
        p.aggiungiPiano(piano("B", dal: "2026-11-02", pasti: ["Pranzo", "Cena"]))
        #expect(p.piano(per: "2026-11-02")?.nome == "B")
        #expect(!p.piani.contains { $0.nome == "A" })
    }

    @Test func spunteSeguonoIlNomeDelPasto() {
        var p = Profilo(nome: "Io")
        p.aggiungiPiano(piano("A", dal: "2026-11-02", pasti: ["Colazione", "Pranzo", "Cena"]))
        var r = Registro()
        r.slot["2"] = Slot(opt: 0, fatto: true)     // Cena
        p.dieta["2026-11-02"] = r
        p.aggiungiPiano(piano("B", dal: "2026-11-02", pasti: ["Pranzo", "Cena"]))
        #expect(p.dieta["2026-11-02"]?.slot["1"]?.fatto == true)
        #expect(p.dieta["2026-11-02"]?.slot["2"] == nil)
    }

    @Test func giorniPrimaDelNuovoPianoNonCambiano() {
        var p = Profilo(nome: "Io")
        p.aggiungiPiano(piano("A", dal: "2026-10-01", pasti: ["Colazione", "Pranzo", "Cena"]))
        var r = Registro()
        r.slot["2"] = Slot(opt: 0, fatto: true)
        p.dieta["2026-10-30"] = r
        p.aggiungiPiano(piano("B", dal: "2026-11-02", pasti: ["Pranzo", "Cena"]))
        #expect(p.dieta["2026-10-30"]?.slot["2"]?.fatto == true)
        #expect(p.piano(per: "2026-10-30")?.nome == "A")
    }
}
