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

    private func allenamento(_ iso: String, ore: Double = 1, kg: Double = 10, rip: Int = 10) -> Allenamento {
        var a = Allenamento(nome: "Pesi", inizio: Giorni.data(iso).addingTimeInterval(18 * 3600))
        a.fine = a.inizio.addingTimeInterval(ore * 3600)
        a.esercizi = [EsercizioFatto(esercizio: "Panca piana", serie: [SerieFatta(kg: kg, rip: rip, fatta: true)])]
        return a
    }

    @Test func giorniAllenatiDellaSettimana() {
        var s = stato([])
        s.allenamenti = [allenamento("2026-11-02"), allenamento("2026-11-04"), allenamento("2026-11-09")]
        s.cardio = [SessioneCardio(data: "2026-11-08", tipo: "Corsa", minuti: 30, km: 5)]
        #expect(s.giorniAllenati(settimanaDi: "2026-11-05") == [0, 2, 6])
        #expect(s.giorniAllenati(settimanaDi: "2026-11-09") == [0])
    }

    @Test func volumiDelleUltimeSettimane() {
        var s = stato([])
        // settimana scorsa (26 ott): 100; questa (2 nov): 200 + 300
        s.allenamenti = [allenamento("2026-10-28", kg: 10, rip: 10), allenamento("2026-11-02", kg: 20, rip: 10), allenamento("2026-11-05", kg: 30, rip: 10)]
        #expect(s.volumiSettimanali(ultime: 3, oggi: "2026-11-06") == [0, 100, 500])
        #expect(s.volumiSettimanali(ultime: 1, oggi: "2026-11-06") == [500])
    }

    @Test func durataDellaSettimana() {
        var s = stato([])
        s.allenamenti = [allenamento("2026-11-02", ore: 1), allenamento("2026-11-04", ore: 0.5), allenamento("2026-11-09", ore: 2)]
        s.cardio = [SessioneCardio(data: "2026-11-06", tipo: "Corsa", minuti: 30, km: 5)]
        #expect(s.durataSettimana("2026-11-03") == 2 * 3600)
        #expect(s.durataSettimana("2026-11-09") == 2 * 3600)
    }

    // Stesse regole del dettaglio (Palestra.nuoviRecord): l'esercizio conta se c'era già prima,
    // anche senza serie valide, e ogni voce si confronta con i record prima dell'allenamento
    @Test func recordComeNelDettaglio() {
        var s = stato([])
        var x = fatto(nil, giorno: 1, kg: 50)
        x.esercizi[0].serie[0].fatta = false                 // c'era, ma nessuna serie valida
        let y = fatto(nil, giorno: 2, kg: 40)
        s.allenamenti = [x, y]
        #expect(s.conteggioRecord()[y.id] == 1)

        var z = fatto(nil, giorno: 3, kg: 60)
        z.esercizi.append(EsercizioFatto(esercizio: "Panca piana", serie: [SerieFatta(kg: 55, rip: 8, fatta: true)]))
        s.allenamenti.append(z)
        #expect(s.conteggioRecord()[z.id] == 2)                // 60 e 55 battono entrambi il 40 di prima
    }
}
