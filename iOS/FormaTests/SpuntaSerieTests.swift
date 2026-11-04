import Foundation
import Testing
@testable import Forma

@MainActor
final class Eventi { var lista: [String] = [] }

@MainActor
struct SpuntaSerieTests {
    @Test func corpoLiberoSenzaKgValeZero() {
        let e = EsitoSpunta.valuta(kg: nil, rip: 8, precedente: nil, corpoLibero: true)
        #expect(e == .segna(kg: 0, rip: 8))
    }

    @Test func conPesiSenzaKgNonSegnaEIndicaIlCampo() {
        let e = EsitoSpunta.valuta(kg: nil, rip: 8, precedente: nil, corpoLibero: false)
        #expect(e == .manca(.kg))
    }

    // Scritto «0» su un esercizio con i pesi, la serie si segna con 0 kg (non resta «manca kg»)
    @Test func zeroKgSuEsercizioConPesiSegnaZero() {
        #expect(EsitoSpunta.valuta(kg: 0, rip: 8, precedente: SerieFatta(kg: 20, rip: 10, fatta: true), corpoLibero: false) == .segna(kg: 0, rip: 8))
        #expect(EsitoSpunta.valuta(kg: 0, rip: 8, precedente: nil, corpoLibero: false) == .segna(kg: 0, rip: 8))
    }

    // Il campo con il cursore si identifica con serie e campo (non con la larghezza)
    @Test func ilFocusDistingueKgERipetizioni() {
        let s = UUID()
        #expect(PuntoDiFocus(serie: s, campo: .kg) != PuntoDiFocus(serie: s, campo: .rip))
        #expect(PuntoDiFocus(serie: s, campo: .kg) == PuntoDiFocus(serie: s, campo: .kg))
        #expect(PuntoDiFocus(serie: s, campo: .kg) != PuntoDiFocus(serie: UUID(), campo: .kg))
    }

    // Se si toglie la spunta subito dopo averla messa, la notifica «Recupero finito» non deve restare
    @Test func notificaNonRestaSeFermatoSubito() async throws {
        let eventi = Eventi()
        let timer = TimerRecupero(aggiungiNotifica: { _ in
            try? await Task.sleep(for: .milliseconds(150))
            eventi.lista.append("aggiungi")
        }, cancellaNotifica: { eventi.lista.append("cancella") })
        let serie = UUID()
        timer.avvia(3600, serie: serie)
        timer.fermaSeAvviatoDa(serie)
        try await Task.sleep(for: .milliseconds(500))
        #expect(eventi.lista.last == "cancella")
        #expect(!timer.attivo)
    }

    @Test func senzaRipetizioniNonSegna() {
        #expect(EsitoSpunta.valuta(kg: 10, rip: nil, precedente: nil, corpoLibero: true) == .manca(.rip))
        #expect(EsitoSpunta.valuta(kg: 10, rip: 0, precedente: nil, corpoLibero: false) == .manca(.rip))
    }

    @Test func usaLaSeriePrecedente() {
        let p = SerieFatta(kg: 20, rip: 10, fatta: true)
        #expect(EsitoSpunta.valuta(kg: nil, rip: nil, precedente: p, corpoLibero: false) == .segna(kg: 20, rip: 10))
    }

    @Test func togliereLaSerieFermaIlRecupero() {
        let timer = TimerRecupero()
        let serie = UUID()
        timer.avvia(3600, serie: serie)
        #expect(timer.attivo)
        timer.fermaSeAvviatoDa(UUID())
        #expect(timer.attivo)
        timer.fermaSeAvviatoDa(serie)
        #expect(!timer.attivo)
        timer.ferma()
    }
}
