import Foundation
import Testing
@testable import Forma

// Scheda suggerita a giro e record calcolati in una sola passata
@MainActor
struct PalestraTests {
    private func stato(_ schede: [Routine]) -> StatoPalestra {
        var s = StatoPalestra()
        s.routine = schede
        s.allenamenti = []
        return s
    }

    private func fatto(_ r: Routine?, giorno: Int, kg: Double = 50, esercizio: String = "Panca piana") -> Allenamento {
        var a = Allenamento(nome: r?.nome ?? "Libero", inizio: Date(timeIntervalSince1970: Double(giorno) * 86400), routine: r?.id)
        a.fine = a.inizio.addingTimeInterval(3600)
        a.esercizi = [EsercizioFatto(esercizio: esercizio, serie: [SerieFatta(kg: kg, rip: 8, fatta: true)])]
        return a
    }

    @Test func prossimaSchedaAGiro() {
        let a = Routine(nome: "A"), b = Routine(nome: "B"), c = Routine(nome: "C")
        var s = stato([a, b, c])
        #expect(s.prossimaRoutine()?.nome == "A")
        s.allenamenti = [fatto(a, giorno: 1), fatto(b, giorno: 2)]
        #expect(s.prossimaRoutine()?.nome == "C")
        s.allenamenti.append(fatto(c, giorno: 3))
        #expect(s.prossimaRoutine()?.nome == "A")
        s.allenamenti.append(fatto(nil, giorno: 4))     // un allenamento libero non sposta il giro
        #expect(s.prossimaRoutine()?.nome == "A")
    }

    @Test func recordInUnaPassata() {
        var s = stato([])
        let x = fatto(nil, giorno: 1, kg: 50), y = fatto(nil, giorno: 2, kg: 60), z = fatto(nil, giorno: 3, kg: 55)
        s.allenamenti = [x, y, z]
        let r = s.conteggioRecord()
        #expect(r[x.id] == 0)
        #expect(r[y.id] == 1)
        #expect(r[z.id] == 0)
    }
}
