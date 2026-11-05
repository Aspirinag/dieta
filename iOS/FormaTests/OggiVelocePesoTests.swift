import Foundation
import Testing
@testable import Forma

// Oggi: peso veloce, riga degli alimenti sotto il pasto, link «Un'altra scheda»
@MainActor
struct OggiVelocePesoTests {
    private var italiano: Bundle { Bundle(path: Bundle.main.path(forResource: "it", ofType: "lproj")!)! }
    private var inglese: Bundle { Bundle(path: Bundle.main.path(forResource: "en", ofType: "lproj")!)! }

    @Test func pesoDiOggiAggiungeUnaMisura() {
        var vecchia = Misura(data: "2026-11-01")
        vecchia.peso = 81
        let nuove = PesoVeloce.registra(80.4, il: "2026-11-04", in: [vecchia])
        #expect(nuove.count == 2)
        #expect(nuove.first { $0.data == "2026-11-04" }?.peso == 80.4)
    }

    @Test func pesoDiOggiAggiornaLaMisuraDiOggiSenzaPerdereIDati() {
        var oggi = Misura(data: "2026-11-04")
        oggi.peso = 81
        oggi.vitaCm = 90
        let nuove = PesoVeloce.registra(80.2, il: "2026-11-04", in: [oggi])
        #expect(nuove.count == 1)
        #expect(nuove[0].peso == 80.2)
        #expect(nuove[0].vitaCm == 90)
    }

    @Test func ultimoPesoSaltaLeMisureSenzaPeso() {
        var a = Misura(data: "2026-11-01"); a.peso = 81
        var b = Misura(data: "2026-11-03"); b.vitaCm = 90
        #expect(PesoVeloce.ultimo([b, a])?.data == "2026-11-01")
        #expect(PesoVeloce.ultimo([]) == nil)
    }

    @Test func etichettaDellaData() {
        let o = "2026-11-04"
        #expect(PesoVeloce.etichetta("2026-11-04", oggi: o, bundle: italiano) == "oggi")
        #expect(PesoVeloce.etichetta("2026-11-03", oggi: o, bundle: italiano) == "ieri")
        #expect(PesoVeloce.etichetta("2026-11-01", oggi: o, bundle: italiano) == "3 giorni fa")
        #expect(PesoVeloce.etichetta("2026-11-01", oggi: o, bundle: inglese) == "3 days ago")
        #expect(PesoVeloce.etichetta("2026-10-01", oggi: o, bundle: italiano) == Giorni.breve("2026-10-01"))
    }

    @Test func variazioneConfrontaConTrentaGiorniFa() {
        func m(_ d: String, _ kg: Double) -> Misura { var x = Misura(data: d); x.peso = kg; return x }
        let misure = [m("2026-08-01", 90), m("2026-10-05", 82), m("2026-11-04", 81.2)]
        let v = PesoVeloce.variazione(misure, ultimo: misure[2])
        #expect(v != nil && abs(v! - (-0.8)) < 0.001)   // non rispetto alla prima misura (90)
    }

    @Test func variazioneSenzaMisuraVicinaATrentaGiorniNonSiMostra() {
        func m(_ d: String, _ kg: Double) -> Misura { var x = Misura(data: d); x.peso = kg; return x }
        let misure = [m("2026-10-25", 82), m("2026-08-01", 90), m("2026-11-04", 81.2)]
        #expect(PesoVeloce.variazione(misure, ultimo: misure[2]) == nil)
    }

    @Test func riassuntoDegliAlimenti() {
        let o = Opzione(alimenti: [Alimento(nome: "Yogurt greco", quantita: "150 g"), Alimento(nome: "Avena", quantita: "40 g")])
        #expect(o.riassunto == "Yogurt greco 150 g, avena 40 g")
        #expect(Opzione(alimenti: []).riassunto == "")
        #expect(Opzione(alimenti: [Alimento(nome: "Mela", quantita: "")]).riassunto == "Mela")
        // Oggi e Dieta scrivono lo stesso testo: senza i prefissi «Contorno:» e «Secondo:»
        let c = Opzione(alimenti: [Alimento(nome: "Pollo", quantita: "150 g"), Alimento(nome: "Contorno: Spinaci", quantita: "200 g")])
        #expect(c.riassunto == "Pollo 150 g, spinaci 200 g")
    }

    @Test func altraSchedaSoloAFineAllenamento() {
        #expect(HomeView.mostraAltraScheda(inCorso: false, pesiFatti: 1, cardioFatto: 0))
        #expect(HomeView.mostraAltraScheda(inCorso: false, pesiFatti: 0, cardioFatto: 1))
        #expect(!HomeView.mostraAltraScheda(inCorso: true, pesiFatti: 1, cardioFatto: 0))
        #expect(!HomeView.mostraAltraScheda(inCorso: false, pesiFatti: 0, cardioFatto: 0))
    }
}
