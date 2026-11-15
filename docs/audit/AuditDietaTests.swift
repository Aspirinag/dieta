import Foundation
import Testing
@testable import Forma

@MainActor
struct AuditDietaTests {
    private let it = Locale(identifier: "it_IT")

    private func piano(_ nome: String, dal: String, al: String = "", alimenti: [Alimento] = [Alimento(nome: "Riso", quantita: "80 g")]) -> Piano {
        let pasto = Pasto(nome: "Pranzo", opzioni: [Opzione(alimenti: alimenti)])
        return Piano(nome: nome, dal: dal, al: al, giorni: Giorni.nomi.map { GiornoPiano(nome: $0, palestra: false, pasti: [pasto]) })
    }

    // 1. NaN / infinito accettati dal modulo misura e poi il JSON non si codifica
    @Test func nanEInfinitoPassanoDaLeggiNumero() {
        #expect(leggiNumero("nan")?.isNaN == true)
        #expect(leggiNumero("1e999") == .infinity)
        #expect(leggiNumero("inf") == .infinity)
    }

    @Test func statoConNaNNonSiCodifica() {
        var s = Stato.iniziale
        var m = Misura(data: "2026-11-10")
        m.peso = leggiNumero("nan")
        s.profili["io"]?.bia = [m]
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        // Archivio.backup() fa `(try? e.encode(stato)) ?? Data()` e salva() scrive quel Data() sul file
        let dati = (try? e.encode(s)) ?? Data()
        #expect(dati.isEmpty)
    }

    // 2. Spesa
    private func profilo(_ q: [String], cibo: String = "Uova") -> Profilo {
        var p = Profilo(nome: "Io")
        let pasti = q.map { Pasto(nome: "Pasto", opzioni: [Opzione(alimenti: [Alimento(nome: cibo, quantita: $0)])]) }
        p.piani = [Piano(nome: "A", dal: "2026-11-02", al: "", giorni: Giorni.nomi.enumerated().map { i, n in
            GiornoPiano(nome: n, palestra: false, pasti: i == 0 ? pasti : []) })]
        return p
    }

    @Test func spesaPezziDiventanoAPiacere() {
        let p = profilo(["2"])
        #expect(p.vociSpesa(lunedi: "2026-11-02", locale: it).first?.quanto == "a piacere")
    }

    @Test func spesaMigliaiaColPunto() {
        let p = profilo(["1.000 g"], cibo: "Riso")
        #expect(p.vociSpesa(lunedi: "2026-11-02", locale: it).first?.quanto == "1 g")
    }

    @Test func spesaUnitaMisteNascondeIPezzi() {
        let p = profilo(["100 g", "1 vasetto"], cibo: "Yogurt")
        #expect(p.vociSpesa(lunedi: "2026-11-02", locale: it).first?.quanto == "100 g")
    }

    // 3. Piani
    @Test func pianoConFineTroncaIlVecchioPerSempre() {
        var p = Profilo(nome: "Io")
        p.aggiungiPiano(piano("Vecchio", dal: "2026-01-01"))
        p.aggiungiPiano(piano("Marzo", dal: "2026-03-01", al: "2026-03-31"))
        #expect(p.piano(per: "2026-04-10") == nil)
        #expect(p.piani.first { $0.nome == "Vecchio" }?.al == "2026-02-28")
    }

    @Test func eliminareIlPianoNuovoNonRiapreIlVecchio() {
        var p = Profilo(nome: "Io")
        p.aggiungiPiano(piano("Vecchio", dal: "2026-01-01"))
        p.aggiungiPiano(piano("Sbagliato", dal: "2026-11-01"))
        p.piani.removeAll { $0.nome == "Sbagliato" }
        #expect(p.piano(per: "2026-11-10") == nil)
    }

    // 4. Fuso orario fissato all'avvio
    @Test func calendarioNonSegueIlCambioDiFuso() {
        _ = Giorni.calendario
        let prima = NSTimeZone.default
        defer { NSTimeZone.default = prima }
        let altro = TimeZone(identifier: prima.identifier == "Pacific/Kiritimati" ? "Pacific/Pago_Pago" : "Pacific/Kiritimati")!
        NSTimeZone.default = altro
        #expect(Giorni.calendario.timeZone != altro)
    }

    // 5. Ora legale
    @Test func oraLegale() {
        #expect(Giorni.aggiungi("2026-10-24", 1) == "2026-10-25")
        #expect(Giorni.aggiungi("2026-10-25", 1) == "2026-10-26")
        #expect(Giorni.aggiungi("2026-03-28", 2) == "2026-03-30")
        #expect(Giorni.indice("2026-10-25") == 6)
        #expect(Giorni.lunedi("2026-11-08") == "2026-11-02")
    }
}
