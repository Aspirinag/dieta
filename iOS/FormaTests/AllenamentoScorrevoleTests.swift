import Foundation
import Testing
@testable import Forma

// Allenamento in corso più scorrevole: «ultima volta» che si tocca, esercizi finiti che si chiudono
@MainActor
struct AllenamentoScorrevoleTests {
    private func esercizio(_ fatte: [Bool]) -> EsercizioFatto {
        EsercizioFatto(esercizio: "x", serie: fatte.map { SerieFatta(kg: 10, rip: 5, fatta: $0) })
    }

    @Test func ultimaVoltaCopiaKgERipetizioni() {
        let v = UltimaVolta.valori(da: SerieFatta(kg: 62.5, rip: 8, fatta: true))
        #expect(v == UltimaVolta.Valori(kg: 62.5, rip: 8))
    }

    @Test func ultimaVoltaSenzaStoricoNonCopiaNulla() {
        #expect(UltimaVolta.valori(da: nil) == nil)
    }

    @Test func esercizioCompletoSoloConTutteLeSerieSpuntate() {
        #expect(PercorsoAllenamento.completo(esercizio([true, true, true])))
        #expect(!PercorsoAllenamento.completo(esercizio([true, false, true])))
        #expect(!PercorsoAllenamento.completo(esercizio([])))
    }

    @Test func siChiudeSoloSeCompletoENonInModifica() {
        let e = esercizio([true, true])
        #expect(PercorsoAllenamento.compresso(e, riaperti: [], inModifica: nil))
        #expect(!PercorsoAllenamento.compresso(e, riaperti: [e.id], inModifica: nil))
        #expect(!PercorsoAllenamento.compresso(e, riaperti: [], inModifica: e.id))
        #expect(!PercorsoAllenamento.compresso(esercizio([true, false]), riaperti: [], inModifica: nil))
    }

    @Test func prossimoEsercizioAperto() {
        let a = esercizio([true, true]), b = esercizio([true, true]), c = esercizio([true, false]), d = esercizio([false])
        #expect(PercorsoAllenamento.prossimoAperto(dopo: a.id, in: [a, b, c, d]) == c.id)
        #expect(PercorsoAllenamento.prossimoAperto(dopo: c.id, in: [a, b, c, d]) == d.id)
        // Se in fondo non c'è niente, si torna al primo ancora aperto prima; se non c'è nessuno, nil
        #expect(PercorsoAllenamento.prossimoAperto(dopo: d.id, in: [a, b, c, d]) == c.id)
        #expect(PercorsoAllenamento.prossimoAperto(dopo: b.id, in: [a, b]) == nil)
        #expect(PercorsoAllenamento.prossimoAperto(dopo: d.id, in: [c, a, d]) == c.id)
    }

    // Chiusura ritardata: un esercizio appena finito resta aperto, poi si chiude se è ancora finito
    @Test func appenaFinitoSoloSeOraEComplettoEPrimaNo() {
        let a = UUID(), b = UUID()
        #expect(PercorsoAllenamento.appenaFinito(prima: [a], ora: [a, b]) == b)
        #expect(PercorsoAllenamento.appenaFinito(prima: [a, b], ora: [a, b]) == nil)
        #expect(PercorsoAllenamento.appenaFinito(prima: [a, b], ora: [a]) == nil)
    }

    @Test func chiusuraRitardataSaltaSeLaSerieEStataTolta() {
        var e = esercizio([true, true])
        #expect(PercorsoAllenamento.siChiudeDopoIlRitardo(e.id, in: [e]))
        e.serie[1].fatta = false
        #expect(!PercorsoAllenamento.siChiudeDopoIlRitardo(e.id, in: [e]))
        #expect(!PercorsoAllenamento.siChiudeDopoIlRitardo(UUID(), in: [e]))
    }

    // «N serie ✓» sulla riga chiusa non conta il riscaldamento
    @Test func serieDiLavoroEscludeIlRiscaldamento() {
        var e = esercizio([true, true, true, true])
        e.serie[0].riscaldamento = true
        #expect(PercorsoAllenamento.serieDiLavoro(e) == 3)
        #expect(PercorsoAllenamento.serieDiLavoro(esercizio([true, true])) == 2)
    }
}
