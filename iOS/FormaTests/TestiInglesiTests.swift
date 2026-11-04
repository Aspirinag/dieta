import Foundation
import Testing
@testable import Forma

// Testi nelle due lingue: nomi dati dall'app o scritti dall'utente, periodi, date brevi, plurali
@MainActor
struct TestiInglesiTests {
    private let italia = Locale(identifier: "it_IT")
    private let usa = Locale(identifier: "en_US")
    private var italiano: Bundle {
        Bundle(path: Bundle.main.path(forResource: "it", ofType: "lproj")!)!
    }
    private var inglese: Bundle {
        Bundle(path: Bundle.main.path(forResource: "en", ofType: "lproj")!)!
    }

    // Si traducono i nomi dati dall'app, compresi «Pesi» e «Allenamento» (salvati dalle versioni e dai backup vecchi);
    // un altro nome scritto dall'utente resta com'è
    @Test func soloINomiDellAppSiTraducono() {
        #expect(Allenamento.nomiDiSistema == [Allenamento.nomeLibero, Allenamento.nomeWatch, "Pesi", "Allenamento"])
        #expect(Allenamento(nome: "Pesi").titolo(in: inglese) == "Weights")
        #expect(Allenamento(nome: "Allenamento").titolo(in: inglese) == "Workout")
        #expect(Allenamento(nome: "Gambe").titolo(in: inglese) == "Gambe")
        #expect(Allenamento(nome: Allenamento.nomeLibero).titolo(in: inglese) == "Free workout")
        #expect(Allenamento(nome: Allenamento.nomeWatch).titolo(in: inglese) != Allenamento.nomeWatch)
    }

    // Un allenamento senza nome nel file prende il nome dato dall'app
    @Test func allenamentoSenzaNomeRestaLibero() throws {
        let a = try JSONDecoder().decode(Allenamento.self, from: Data("{}".utf8))
        #expect(a.nome == Allenamento.nomeLibero)
    }

    // Il sistema scrive «2–8 novembre» (senza spazi) e, a cavallo di due mesi, trattino con spazi sottili
    @Test func periodoDellaSpesaInItalianoEInInglese() {
        #expect(SpesaView.periodo(lunedi: "2026-11-02", locale: italia) == "2–8 novembre")
        #expect(SpesaView.periodo(lunedi: "2026-11-02", locale: usa) == "November 2\u{2009}–\u{2009}8")
        #expect(SpesaView.periodo(lunedi: "2026-11-30", locale: italia) == "30 novembre\u{2009}–\u{2009}6 dicembre")
    }

    @Test func dataBreveNelFormatoDelTelefono() {
        #expect(Giorni.breve("2026-11-04", locale: italia) == "04/11/2026")
        #expect(Giorni.breve("2026-11-04", locale: usa) == "11/4/2026")
        #expect(Giorni.breve("non una data", locale: italia) == "non una data")
    }

    @Test func conteggioAllenamentiAlSingolareEAlPlurale() {
        #expect(AllenamentoView.conteggio(1, bundle: italiano) == "1 allenamento")
        #expect(AllenamentoView.conteggio(3, bundle: italiano) == "3 allenamenti")
        #expect(AllenamentoView.conteggio(1, bundle: inglese) == "1 workout")
        #expect(AllenamentoView.conteggio(3, bundle: inglese) == "3 workouts")
    }
}
