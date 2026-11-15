import Foundation
import Testing
@testable import Forma

// Rotella di kg e ripetizioni al posto della tastiera
@MainActor
struct SerieComodeTests {
    @Test func rotellaKgVaDaZeroATrecentoAMezzoChiloPerVolta() {
        let o = PassoSerie.opzioniKg(attuale: 40)
        #expect(o.first == 0)
        #expect(o.last == 300)
        #expect(o.count == 601)
        #expect(o[1] == 0.5)
        #expect(o.contains(37.5))
    }

    @Test func rotellaKgMostraAncheUnValoreNonMultiploDiMezzo() {
        let o = PassoSerie.opzioniKg(attuale: 37.25)
        #expect(o.contains(37.25))
        #expect(o.count == 602)
        #expect(o == o.sorted())
        #expect(Set(o).count == o.count)
    }

    @Test func rotellaKgSenzaValoreOMultiploNonAggiungeNulla() {
        #expect(PassoSerie.opzioniKg(attuale: nil).count == 601)
        #expect(PassoSerie.opzioniKg(attuale: 42.5).count == 601)
    }

    @Test func rotellaKgOltreTrecentoMostraIlValore() {
        let o = PassoSerie.opzioniKg(attuale: 320)
        #expect(o.last == 320)
    }

    @Test func rotellaKgArrotondaIlValoreAlCentesimo() {
        // 37.1 + 0.15 e simili: nessuna coda di decimali sulla rotella
        let o = PassoSerie.opzioniKg(attuale: 37.250000001)
        #expect(o.contains(37.25))
    }

    @Test func rotellaRipetizioniDaZeroACinquanta() {
        let o = PassoSerie.opzioniRip(attuale: 8)
        #expect(o == Array(0...50))
    }

    @Test func rotellaRipetizioniMostraUnValoreFuoriScala() {
        let o = PassoSerie.opzioniRip(attuale: 60)
        #expect(o.last == 60)
        #expect(o.count == 52)
        #expect(PassoSerie.opzioniRip(attuale: nil).count == 51)
    }

    @Test func rotellaNonHaValoriNegativi() {
        #expect(PassoSerie.opzioniKg(attuale: -3).first == 0)
        #expect(PassoSerie.opzioniRip(attuale: -1).first == 0)
    }

    // Dopo la rotella il testo del campo è quello che si legge: «37,5», non «37.5»
    @Test func ilTestoDelCampoSegueIlValoreScelto() {
        #expect(PassoSerie.kg("", base: nil, delta: 0) == 0)
        #expect(PassoSerie.kg("37,25", base: nil, delta: 2.5) == 39.75)
    }
}
