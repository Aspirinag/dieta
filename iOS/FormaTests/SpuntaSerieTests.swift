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
    // MARK: Serie attiva (quella con i ± e verso cui si scorre)

    private func esercizio(_ fatte: [Bool]) -> EsercizioFatto {
        EsercizioFatto(esercizio: "x", serie: fatte.map { SerieFatta(kg: 10, rip: 8, fatta: $0) })
    }

    @Test func senzaRiferimentoLaPrimaDaFare() {
        let a = esercizio([true, true]), b = esercizio([true, false, false])
        #expect(SerieAttiva.trova(in: [a, b], riferimento: nil) == b.serie[1].id)
    }

    @Test func dopoUnaSpuntaLaSuccessivaDelloStessoEsercizio() {
        let a = esercizio([false, false]), b = esercizio([true, false, false])
        // Spuntata la seconda di b (fuori ordine): la prossima è la terza di b, non la prima di a
        var b2 = b
        b2.serie[1].fatta = true
        #expect(SerieAttiva.trova(in: [a, b2], riferimento: b2.serie[1].id) == b2.serie[2].id)
    }

    @Test func unaSerieDaFareScelta() {
        let a = esercizio([false, false, false])
        #expect(SerieAttiva.trova(in: [a], riferimento: a.serie[2].id) == a.serie[2].id)
    }

    @Test func esercizioFinitoPassaAlProssimoPoiTornaIndietro() {
        let a = esercizio([false]), b = esercizio([true, true]), c = esercizio([false])
        #expect(SerieAttiva.trova(in: [a, b, c], riferimento: b.serie[1].id) == c.serie[0].id)
        #expect(SerieAttiva.trova(in: [a, b], riferimento: b.serie[1].id) == a.serie[0].id)
        // Una serie prima dell'ultima spuntata, nello stesso esercizio, rimasta indietro
        let d = esercizio([false, true])
        #expect(SerieAttiva.trova(in: [d], riferimento: d.serie[1].id) == d.serie[0].id)
    }

    @Test func tuttoFattoNessunaAttiva() {
        let a = esercizio([true])
        #expect(SerieAttiva.trova(in: [a], riferimento: nil) == nil)
        #expect(SerieAttiva.trova(in: [a], riferimento: UUID()) == nil)
    }

    // MARK: ± senza tastiera

    @Test func piuKgPartendoDalCampo() {
        #expect(PassoSerie.kg("40", base: 37.5, delta: 2.5) == 42.5)
        #expect(PassoSerie.kg("37,5", base: nil, delta: -2.5) == 35)
    }

    @Test func piuKgCampoVuotoUsaLUltimaVolta() {
        #expect(PassoSerie.kg("", base: 37.5, delta: 2.5) == 40)
        #expect(PassoSerie.kg("", base: nil, delta: 2.5) == 2.5)
    }

    @Test func kgERipetizioniMaiSottoZero() {
        #expect(PassoSerie.kg("1", base: nil, delta: -2.5) == 0)
        #expect(PassoSerie.rip("0", base: nil, delta: -1) == 0)
    }

    @Test func ripetizioni() {
        #expect(PassoSerie.rip("10", base: 8, delta: 1) == 11)
        #expect(PassoSerie.rip("", base: 8, delta: -1) == 7)
    }

    // MARK: Stato del recupero (per la Live Activity)

    @Test func statoDelRecupero() {
        let timer = TimerRecupero(aggiungiNotifica: { _ in }, cancellaNotifica: {})
        #expect(timer.stato == nil)
        timer.avvia(90, serie: UUID(), esercizio: "Chest press")
        guard let s = timer.stato else { Issue.record("Recupero avviato senza stato"); return }
        #expect(s.esercizio == "Chest press")
        #expect(abs(s.fine.timeIntervalSince(s.inizio) - 90) < 1)
        timer.cambia(15)
        #expect(timer.stato?.inizio == s.inizio)
        #expect(abs((timer.stato?.fine.timeIntervalSince(s.inizio) ?? 0) - 105) < 1)
        timer.ferma()
        #expect(timer.stato == nil)
    }

    @Test func avanzamentoDelRecupero() {
        let i = Date(timeIntervalSince1970: 0)
        let s = StatoRecupero(inizio: i, fine: i.addingTimeInterval(100), esercizio: nil)
        #expect(s.trascorso(il: i.addingTimeInterval(25)) == 0.25)
        #expect(s.trascorso(il: i.addingTimeInterval(-5)) == 0)
        #expect(s.trascorso(il: i.addingTimeInterval(500)) == 1)
    }
}
