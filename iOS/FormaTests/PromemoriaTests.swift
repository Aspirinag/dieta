import Foundation
import Testing
@testable import Forma

// Orari dei promemoria scelti dall'utente (minuti dalla mezzanotte)
@MainActor
struct PromemoriaTests {
    @Test func predefinitiComePrima() {
        let p = Promemoria()
        #expect(p.oraMattino == 9 * 60)
        #expect(p.oraPasti == 21 * 60)
        #expect(p.orariAcqua == [600, 720, 840, 960, 1080, 1200])
    }

    @Test func acquaNellaFasciaScelta() {
        var p = Promemoria()
        p.acquaDalle = 8 * 60 + 30
        p.acquaAlle = 12 * 60
        p.acquaOgni = 1
        #expect(p.orariAcqua == [510, 570, 630, 690])
    }

    @Test func acquaConFasciaRovesciataNonDaOrari() {
        var p = Promemoria()
        p.acquaDalle = 20 * 60
        p.acquaAlle = 10 * 60
        #expect(p.orariAcqua == [20 * 60])
    }

    @Test func backupVecchioSenzaOrariUsaIPredefiniti() throws {
        let p = try JSONDecoder().decode(Promemoria.self, from: Data(#"{"acqua":true,"pasti":false,"mattino":true}"#.utf8))
        #expect(p.acqua)
        #expect(p.oraMattino == 540)
        #expect(p.acquaOgni == 2)
    }

    @Test func notificheConGliOrariScelti() {
        var p = Promemoria()
        p.mattino = true
        p.oraMattino = 7 * 60 + 15
        p.pasti = true
        p.oraPasti = 22 * 60 + 45
        p.acqua = false
        let n = p.notifiche
        #expect(n.map(\.id) == ["mattino", "pasti"])
        #expect(n.map(\.minuti) == [435, 1365])
    }

    @Test func pagamentoAllOraScelta() {
        // 28 ottobre 2026: il prossimo promemoria è il 1 novembre all'ora scelta
        let ora = Giorni.data("2026-10-28")
        let p = Palestra.prossimoPagamento(dopo: ora, pagamenti: [:], minuti: 18 * 60 + 30)
        #expect(p?.quando.month == 11)
        #expect(p?.quando.day == 1)
        #expect(p?.quando.hour == 18)
        #expect(p?.quando.minute == 30)
    }

    @Test func statoPalestraVecchioHaPagamentoAlleNove() throws {
        let s = try JSONDecoder().decode(StatoPalestra.self, from: Data("{}".utf8))
        #expect(s.oraPagamento == 9 * 60)
    }

    @Test func orariFuoriScalaRiportatiNeiLimiti() throws {
        let p = try JSONDecoder().decode(Promemoria.self, from: Data(#"{"oraMattino":1500,"oraPasti":-20,"acquaOgni":-3,"acquaDalle":900,"acquaAlle":600}"#.utf8))
        #expect(p.oraMattino == 1439)
        #expect(p.oraPasti == 0)
        #expect(p.acquaOgni == 1)
        #expect(p.acquaAlle >= p.acquaDalle)
    }

    @Test func oraPagamentoFuoriScala() throws {
        let s = try JSONDecoder().decode(StatoPalestra.self, from: Data(#"{"oraPagamento":5000}"#.utf8))
        #expect(s.oraPagamento == 1439)
    }

    private func ora(_ iso: String, _ h: Int = 8) -> Date { Giorni.data(iso).addingTimeInterval(TimeInterval(h * 3600)) }

    @Test func pagamentoIlQuindici() {
        let p = Palestra.prossimoPagamento(dopo: ora("2026-11-10"), pagamenti: [:], minuti: 540, giorno: 15)
        #expect(p?.quando.day == 15)
        #expect(p?.primo == true)
        let q = Palestra.prossimoPagamento(dopo: ora("2026-11-15", 10), pagamenti: [:], minuti: 540, giorno: 15)
        #expect(q?.quando.day == 16)
        #expect(q?.primo == false)
    }

    @Test func avvisoPagamentoUnaSettimanaPrima() {
        #expect(Palestra.avvisoPagamento(oggi: "2026-11-07", giorno: 15, pagamenti: [:]) == nil)
        #expect(Palestra.avvisoPagamento(oggi: "2026-11-08", giorno: 15, pagamenti: [:])?.mese == "2026-11")
        #expect(Palestra.avvisoPagamento(oggi: "2026-11-16", giorno: 15, pagamenti: [:])?.testo == "Ultimo giorno per pagare la palestra.")
        #expect(Palestra.avvisoPagamento(oggi: "2026-11-17", giorno: 15, pagamenti: [:]) == nil)
        #expect(Palestra.avvisoPagamento(oggi: "2026-11-10", giorno: 15, pagamenti: ["2026-11": "2026-11-09"]) == nil)
        // Come prima con il giorno 1: dal 25 del mese prima
        #expect(Palestra.avvisoPagamento(oggi: "2026-10-25", giorno: 1, pagamenti: [:])?.mese == "2026-11")
        #expect(Palestra.avvisoPagamento(oggi: "2026-10-24", giorno: 1, pagamenti: [:]) == nil)
    }

    @Test func avvisoPagamentoGiornoDopoAFineMese() {
        // Pagamento il 28: a febbraio il giorno dopo è il 1° marzo, l'avviso deve ancora esserci
        #expect(Palestra.avvisoPagamento(oggi: "2027-03-01", giorno: 28, pagamenti: [:])?.mese == "2027-02")
        #expect(Palestra.avvisoPagamento(oggi: "2027-03-01", giorno: 28, pagamenti: [:])?.testo == "Ultimo giorno per pagare la palestra.")
        // Febbraio pagato: niente avviso il 1° marzo
        #expect(Palestra.avvisoPagamento(oggi: "2027-03-01", giorno: 28, pagamenti: ["2027-02": "2027-02-27"]) == nil)
        // Mese prima pagato non nasconde l'avviso del mese dopo (giorno 1: il 25 avvisa per il mese dopo)
        #expect(Palestra.avvisoPagamento(oggi: "2026-11-25", giorno: 1, pagamenti: ["2026-11": "2026-11-01"])?.mese == "2026-12")
    }

    @Test func pianoABSpento() {
        var s = StatoPalestra()
        s.usaAB = false
        #expect(s.settimana("2026-11-02") == "A")
        #expect(s.settimana("2026-11-09") == "A")
        s.usaAB = true
        #expect(s.settimana("2026-11-02") != s.settimana("2026-11-09"))
    }

    @Test func campiPagamentoNuoviConValoriDiPrima() throws {
        let s = try JSONDecoder().decode(StatoPalestra.self, from: Data("{}".utf8))
        #expect(s.pagamentoAttivo)
        #expect(s.giornoPagamento == 1)
        #expect(s.usaAB)
    }
}
