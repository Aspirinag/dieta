import Foundation
import Testing
@testable import Forma

// Numeri e unità seguono il formato del telefono; le unità restano sempre metriche
@MainActor
struct LinguaTests {
    private let usa = Locale(identifier: "en_US")
    private let italia = Locale(identifier: "it_IT")

    @Test func pesoInChiliConPuntoDecimaleInInglese() {
        #expect(kgTesto(81.1, locale: usa) == "81.1 kg")
        #expect(kgTesto(81.1, locale: italia) == "81,1 kg")
        #expect(kgTesto(80, locale: usa) == "80 kg")
    }

    @Test func numeriSenzaDecimaliInutili() {
        #expect(num(0.25, locale: usa) == "0.25")
        #expect(num(0.25, locale: italia) == "0,25")
        #expect(num(nil, locale: usa) == "–")
    }

    @Test func volumeConMigliaiaDelTelefono() {
        #expect(volumeTesto(17130, locale: usa) == "17,130 kg")
        #expect(volumeTesto(17130, locale: italia) == "17.130 kg")
        #expect(volumeTesto(950, locale: usa) == "950 kg")
    }

    @Test func numeriScrittiConVirgolaOPuntoSiLeggono() {
        #expect(leggiNumero("81,1") == 81.1)
        #expect(leggiNumero("81.1") == 81.1)
    }

    @Test func settimanaParteDalLunediInOgniLingua() {
        #expect(Giorni.calendario.firstWeekday == 2)
        #expect(Giorni.indice("2026-11-02") == 0)
        #expect(Giorni.nomi.count == 7 && Giorni.iniziali.count == 7)
    }
}
