import Foundation
import Testing
@testable import Forma

// L'editor di una scheda trova scheda ed esercizi per id, mai per posizione: se la scheda sparisce non succede niente
@MainActor
struct ModificaSchedaTests {
    @Test func modificaPerId() {
        var s = StatoPalestra()
        let a = Routine(nome: "A", voci: [VoceRoutine(esercizio: "x"), VoceRoutine(esercizio: "y")]), b = Routine(nome: "B")
        s.routine = [a, b]
        s.modificaScheda(b.id) { $0.nome = "B2" }
        #expect(s.routine.map(\.nome) == ["A", "B2"])
        s.modificaVoce(a.voci[1].id, in: a.id) { $0.serie = 5 }
        #expect(s.routine[0].voci.map(\.serie) == [3, 5])
    }

    @Test func schedaEliminataNonFaNiente() {
        var s = StatoPalestra()
        let a = Routine(nome: "A", voci: [VoceRoutine(esercizio: "x")])
        s.routine = [a]
        s.routine.removeAll()
        s.modificaScheda(a.id) { $0.nome = "mai" }
        s.modificaVoce(a.voci[0].id, in: a.id) { $0.serie = 9 }
        #expect(s.routine.isEmpty)
        #expect(s.scheda(a.id) == nil)
        #expect(s.voce(a.voci[0].id, in: a.id) == nil)
    }

    @Test func voceEliminataNonFaNiente() {
        var s = StatoPalestra()
        let a = Routine(nome: "A", voci: [VoceRoutine(esercizio: "x")])
        s.routine = [a]
        let id = a.voci[0].id
        s.routine[0].voci.removeAll()
        s.modificaVoce(id, in: a.id) { $0.serie = 9 }
        #expect(s.routine[0].voci.isEmpty)
        #expect(s.voce(id, in: a.id) == nil)
    }
}
