import Foundation
import Testing
@testable import Forma

// La Live Activity del recupero si avvia, si aggiorna e si chiude seguendo lo stato del timer
@MainActor
struct LiveRecuperoTests {
    final class Finto: SistemaAttivita {
        enum Chiamata: Equatable { case avvia(StatoRecupero), aggiorna(StatoRecupero), chiudi }
        var chiamate: [Chiamata] = []
        func avvia(_ stato: StatoRecupero) { chiamate.append(.avvia(stato)) }
        func aggiorna(_ stato: StatoRecupero) { chiamate.append(.aggiorna(stato)) }
        func chiudi() { chiamate.append(.chiudi) }
    }

    let adesso = Date(timeIntervalSinceReferenceDate: 800_000_000)
    func stato(_ secondi: TimeInterval, _ esercizio: String? = "Panca piana") -> StatoRecupero {
        StatoRecupero(inizio: adesso, fine: adesso.addingTimeInterval(secondi), esercizio: esercizio)
    }

    @Test func avviaAggiornaEChiude() {
        let finto = Finto()
        let live = LiveRecupero(sistema: finto)
        live.applica(stato(90), adesso: adesso)
        live.applica(stato(105), adesso: adesso)          // +15 s
        live.applica(stato(120, "Squat"), adesso: adesso) // nuova serie con il recupero ancora in corso
        live.applica(nil, adesso: adesso)                 // fine del recupero o dell'allenamento
        #expect(finto.chiamate == [.avvia(stato(90)), .aggiorna(stato(105)), .aggiorna(stato(120, "Squat")), .chiudi])
        #expect(live.mostrato == nil)
    }

    @Test func statoUgualeNonRichiamaIlSistema() {
        let finto = Finto()
        let live = LiveRecupero(sistema: finto)
        live.applica(stato(90), adesso: adesso)
        live.applica(stato(90), adesso: adesso)
        live.applica(nil, adesso: adesso)
        live.applica(nil, adesso: adesso)
        #expect(finto.chiamate == [.avvia(stato(90)), .chiudi])
    }

    @Test func recuperoScadutoNonSiMostraESiChiude() {
        let finto = Finto()
        let live = LiveRecupero(sistema: finto)
        live.applica(stato(-1), adesso: adesso)
        #expect(finto.chiamate.isEmpty)
        live.applica(stato(60), adesso: adesso)
        live.applica(stato(60), adesso: adesso.addingTimeInterval(61))
        #expect(finto.chiamate == [.avvia(stato(60)), .chiudi])
    }

    @Test func dopoLaChiusuraUnNuovoRecuperoRiparte() {
        let finto = Finto()
        let live = LiveRecupero(sistema: finto)
        live.applica(stato(60), adesso: adesso)
        live.applica(nil, adesso: adesso)
        live.applica(stato(90), adesso: adesso)
        #expect(finto.chiamate == [.avvia(stato(60)), .chiudi, .avvia(stato(90))])
    }

    // Il timer espone lo stato che la Live Activity legge: avvio, ±15 s e fermata
    @Test func ilTimerEsponeLoStatoGiusto() {
        let timer = TimerRecupero(aggiungiNotifica: { _ in }, cancellaNotifica: {})
        timer.avvia(90, esercizio: "Panca piana")
        let primo = timer.stato
        #expect(primo?.esercizio == "Panca piana")
        #expect(primo.map { $0.fine.timeIntervalSince($0.inizio).rounded() } == 90)
        timer.cambia(15)
        #expect(timer.stato.map { $0.fine.timeIntervalSince($0.inizio).rounded() } == 105)
        #expect(timer.stato?.inizio == primo?.inizio)
        timer.ferma()
        #expect(timer.stato == nil)
    }
}
