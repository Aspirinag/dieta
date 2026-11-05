import Testing
import SwiftUI
import UIKit
@testable import Forma

// Sistema visivo (pacchetto P1): contrasti dei colori, misure, formato di date e variazioni
@MainActor
struct SistemaVisivoTests {
    private let riga = Color(.secondarySystemGroupedBackground)     // sfondo di righe e riquadri
    private let fondo = Color(.systemGroupedBackground)             // sfondo della schermata
    private let foglio = Color(.tertiarySystemGroupedBackground)    // righe dentro un foglio in scuro

    private var casi: [(UIUserInterfaceStyle, Bool)] {
        [(.light, false), (.dark, false), (.light, true), (.dark, true)]
    }

    // Forme con significato (pieni e vuoti) almeno 3:1 sullo sfondo della riga, in chiaro, scuro e Aumenta contrasto
    @Test(arguments: ["accento", "olio", "acqua", "oltre", "vuoto"])
    func formeHannoContrasto(_ nome: String) {
        let colore: Color = switch nome {
        case "accento": Colori.accento
        case "olio": Colori.olio
        case "acqua": Colori.acqua
        case "oltre": Colori.oltre
        default: Colori.vuoto
        }
        for (stile, alto) in casi {
            for sfondo in [riga, fondo, foglio] {
                let r = Contrasto.rapporto(colore, su: sfondo, stile: stile, contrastoAlto: alto)
                #expect(r >= 3, "\(nome) \(stile == .dark ? "scuro" : "chiaro")\(alto ? " contrasto alto" : ""): \(r)")
            }
        }
    }

    // Il segno sopra l'accento si legge come testo (4,5:1)
    @Test func segnoSullAccento() {
        for (stile, alto) in casi {
            #expect(Contrasto.rapporto(Colori.sulAccento, su: Colori.accento, stile: stile, contrastoAlto: alto) >= 4.5)
        }
    }

    // Il riempimento leggero del vuoto non deve sembrare pieno: resta vicino allo sfondo
    @Test func riempimentoVuotoLeggero() {
        for (stile, _) in casi {
            #expect(Contrasto.rapporto(Colori.riempimentoVuoto, su: riga, stile: stile) < 1.5)
        }
    }

    @Test func contrastoNotoBiancoNero() {
        #expect(abs(Contrasto.rapporto(.black, su: .white, stile: .light) - 21) < 0.01)
        #expect(abs(Contrasto.rapporto(.white, su: .white, stile: .light) - 1) < 0.01)
    }

    @Test func accentoHaVarianti() {
        let chiaro = Contrasto.rapporto(Colori.accento, su: .white, stile: .light)
        let alto = Contrasto.rapporto(Colori.accento, su: .white, stile: .light, contrastoAlto: true)
        #expect(alto > chiaro)
    }

    @Test func scalaDegliSpazi() {
        #expect([Spazio.xs, Spazio.s, Spazio.m, Spazio.l, Spazio.xl] == [4, 8, 12, 16, 24])
        #expect(Misure.tocco == 44)
        #expect(Misure.riga >= Misure.tocco)
        #expect(Misure.spunta < Misure.tocco)
    }

    private let it = Locale(identifier: "it_IT")
    private let en = Locale(identifier: "en_US")
    private var giovedi: Date { Giorni.data("2026-11-05") }

    // «giovedì 5 novembre»: minuscolo, senza anno, senza barre
    @Test func dataInItaliano() {
        #expect(Testi.data(giovedi, locale: it) == "giovedì 5 novembre")
        #expect(Testi.data(iso: "2026-11-05", locale: it) == "giovedì 5 novembre")
        #expect(Testi.data(giovedi, anno: true, locale: it) == "giovedì 5 novembre 2026")
    }

    @Test func dataInInglese() {
        let t = Testi.data(giovedi, locale: en)
        #expect(t.contains("Thursday") && t.contains("November") && t.contains("5"))
        #expect(!t.contains("/"))
    }

    @Test func periodoDellaSettimana() {
        let t = Testi.periodo(da: Giorni.data("2026-11-02"), a: Giorni.data("2026-11-08"), locale: it)
        #expect(t.contains("2") && t.contains("8") && t.contains("novembre"))
        #expect(!t.contains("ottobre"))
        let t2 = Testi.periodo(da: Giorni.data("2026-11-30"), a: Giorni.data("2026-12-06"), locale: it)
        #expect(t2.contains("novembre") && t2.contains("dicembre"))
    }

    // Variazioni neutre con il segno vero (U+2212), mai «--» o «+-»
    @Test func variazioniConSegno() {
        #expect(Testi.conSegno(-0.8, unita: "kg", locale: it) == "\u{2212}0,8 kg")
        #expect(Testi.conSegno(0.3, unita: "kg", locale: it) == "+0,3 kg")
        #expect(Testi.conSegno(0, unita: "kg", locale: it) == "0 kg")
        #expect(Testi.conSegno(-0.001, unita: "kg", locale: it) == "0 kg")
        #expect(Testi.conSegno(1.25, unita: "cm", locale: en) == "+1.25 cm")
    }
}
