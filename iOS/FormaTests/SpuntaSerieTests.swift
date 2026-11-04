import Foundation
import Testing
@testable import Forma

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

    @Test func senzaRipetizioniNonSegna() {
        #expect(EsitoSpunta.valuta(kg: 10, rip: nil, precedente: nil, corpoLibero: true) == .manca(.rip))
        #expect(EsitoSpunta.valuta(kg: 10, rip: 0, precedente: nil, corpoLibero: false) == .manca(.rip))
    }

    @Test func usaLaSeriePrecedente() {
        let p = SerieFatta(kg: 20, rip: 10, fatta: true)
        #expect(EsitoSpunta.valuta(kg: nil, rip: nil, precedente: p, corpoLibero: false) == .segna(kg: 20, rip: 10))
    }

    @Test func scalpiTogliereLaSerieFermaIlRecupero() {
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
