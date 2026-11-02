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
}
