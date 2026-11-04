import Foundation
import Testing
@testable import Forma

// Numeri nelle lingue con cifre non latine, formatter in cache, reparti della spesa, promemoria e variazioni
@MainActor
struct LogicaNumeriTests {
    @Test func numeroScrittoEPoiLettoTornaUguale() {
        for id in ["ar_SA@numbers=arab", "ar_SA", "fa_IR", "hi_IN@numbers=deva", "it_IT", "en_US"] {
            let l = Locale(identifier: id)
            #expect(leggiNumero(num(81.1, locale: l)) == 81.1, "\(id)")
            #expect(leggiNumero(num(80, locale: l)) == 80, "\(id)")
        }
        #expect(num(81.1, locale: Locale(identifier: "ar_SA@numbers=arab")) != "81.1")
    }

    @Test func formatterInCachePerLingua() {
        let it = Locale(identifier: "it_IT")
        #expect(FormatoNumeri.formatter(it) === FormatoNumeri.formatter(it))
        #expect(FormatoNumeri.formatter(it) !== FormatoNumeri.formatter(Locale(identifier: "en_US")))
        #expect(num(81.1, locale: it) == "81,1")
        #expect(num(81.1, locale: Locale(identifier: "en_US")) == "81.1")
    }

    @Test func repartiSenzaFalsiPositivi() {
        #expect(Reparto.indovina("Pane semintegrale") == .panePastaCereali)
        #expect(Reparto.indovina("Semintegrale") == .altro)
        #expect(Reparto.indovina("Semi di lino") == .dispensa)
        #expect(Reparto.indovina("Frutta secca") == .dispensa)
        #expect(Reparto.indovina("Frutta secca e semi") == .dispensa)
        #expect(Reparto.indovina("Frutta a guscio mista") == .dispensa)
        #expect(Reparto.indovina("Frutta di stagione") == .fruttaVerdura)
        #expect(Reparto.indovina("Mele") == .fruttaVerdura)
        #expect(Reparto.indovina("Pane ai semi") == .panePastaCereali)
    }

    @Test func repartoEspostaIgnoranoLeMaiuscole() {
        var p = Profilo(nome: "Io")
        p.sposta("Riso", in: .dispensa)
        #expect(p.repartiSpesa == ["riso": "dispensa"])
        #expect(p.reparto(di: "RISO") == .dispensa)
        #expect(Profilo(nome: "Io").reparto(di: "Mela") == .fruttaVerdura)
    }

    @Test func vociAggiuntePerOrdineAlfabetico() {
        var p = Profilo(nome: "Io")
        p.aggiungiExtra("Zucchero", lunedi: "2026-11-02")
        p.aggiungiExtra("arachidi", lunedi: "2026-11-02")
        p.aggiungiExtra("Miele", lunedi: "2026-11-02")
        p.aggiungiExtra("Èlla", lunedi: "2026-11-02")
        #expect(p.vociSpesa(lunedi: "2026-11-02").map(\.nome) == ["arachidi", "Èlla", "Miele", "Zucchero"])
    }

    @Test func riprogrammaSoloSeLaLinguaCambia() {
        #expect(Notifiche.serveRiprogrammare(salvata: nil, attuale: "it-IT"))
        #expect(Notifiche.serveRiprogrammare(salvata: "it-IT", attuale: "en-GB"))
        #expect(!Notifiche.serveRiprogrammare(salvata: "it-IT", attuale: "it-IT"))
    }

    @Test func testoVariazione() {
        #expect(CorpoView.testoVariazione(0.4, "kg") == "+\(num(0.4)) kg")
        #expect(CorpoView.testoVariazione(-1.2, "kg") == "−\(num(1.2)) kg")
        #expect(CorpoView.testoVariazione(0, "cm") == "\(num(0)) cm")
        #expect(!CorpoView.testoVariazione(0, "cm").hasPrefix("+"))
        #expect(!CorpoView.testoVariazione(0, "cm").hasPrefix("−"))
        #expect(num(nil) == "–")
    }
}
