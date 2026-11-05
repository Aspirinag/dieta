import Testing
@testable import Forma

// Progressi → Corpo: l'invito «Aggiungi il primo peso» solo senza alcuna misurazione
@MainActor
struct CorpoTests {
    @Test func vuotoSoloSenzaMisurazioni() {
        #expect(CorpoView.senzaMisurazioni([]))
        var soloVita = Misura(data: "2026-10-01")
        soloVita.vitaCm = 90
        #expect(!CorpoView.senzaMisurazioni([soloVita]))
        var conPeso = Misura(data: "2026-10-02")
        conPeso.peso = 80
        #expect(!CorpoView.senzaMisurazioni([soloVita, conPeso]))
    }

    private func misura(_ data: String, peso: Double) -> Misura {
        var m = Misura(data: data)
        m.peso = peso
        return m
    }

    // Il peso si confronta con circa 30 giorni prima dell'ultima misura, non con la prima
    @Test func variazioneRispettoATrentaGiorniFa() {
        let misure = [misura("2026-08-01", peso: 90), misura("2026-10-05", peso: 82.5), misura("2026-11-04", peso: 81.1)]
        #expect(CorpoView.variazioneTrentaGiorni(misure, .peso) == -1.4)
        // con due misure a 61 giorni di distanza non c'è un confronto onesto
        #expect(CorpoView.variazioneTrentaGiorni([misura("2026-09-04", peso: 90), misura("2026-11-04", peso: 81)], .peso) == nil)
        // troppo vicine (10 giorni)
        #expect(CorpoView.variazioneTrentaGiorni([misura("2026-10-25", peso: 90), misura("2026-11-04", peso: 81)], .peso) == nil)
        #expect(CorpoView.variazioneTrentaGiorni([], .peso) == nil)
    }

    @Test func variazioneEUnaSolaFraDueMisureVicineA30Giorni() {
        let misure = [misura("2026-10-01", peso: 80), misura("2026-10-06", peso: 79), misura("2026-11-04", peso: 80.4)]
        // 34 giorni (80) e 29 giorni (79): vince quella più vicina a 30
        #expect(CorpoView.variazioneTrentaGiorni(misure, .peso) == 1.4)
    }

    @Test func variazioneHaIlSegnoVeroENonEColorata() {
        #expect(Testi.conSegno(-1.4, unita: "kg").hasPrefix("\u{2212}"))
        #expect(Testi.conSegno(0.3, unita: "kg").hasPrefix("+"))
    }
}
