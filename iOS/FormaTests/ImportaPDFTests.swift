import Foundation
import Testing
@testable import Forma

// Esito della lettura di un PDF dopo la scelta del file: piano, BIA o errore spiegato
@MainActor
struct ImportaPDFTests {
    private func giorni(_ n: Int, pasti: Int = 2) -> [GiornoPiano] {
        (0..<n).map { i in GiornoPiano(nome: Giorni.nomi[i % 7], palestra: false,
                                       pasti: (0..<pasti).map { Pasto(nome: "P\($0)", opzioni: []) }) }
    }

    @Test func schemaCompleto() {
        guard case .piano(let g) = ImportaPDF.valuta(.schema, giorni: giorni(7), misura: nil) else { Issue.record("atteso piano"); return }
        #expect(g.count == 7)
    }

    @Test func schemaIncompleto() {
        guard case .errore(let t) = ImportaPDF.valuta(.schema, giorni: giorni(3), misura: nil) else { Issue.record("atteso errore"); return }
        #expect(t.contains("trovati 3 giorni su 7"))
    }

    @Test func schemaConGiornoVuoto() {
        var g = giorni(7)
        g[2].pasti = []
        guard case .errore = ImportaPDF.valuta(.schema, giorni: g, misura: nil) else { Issue.record("atteso errore"); return }
    }

    @Test func biaSenzaData() {
        var m = Misura(data: "")
        m.peso = 80
        guard case .errore(let t) = ImportaPDF.valuta(.bia, giorni: nil, misura: m) else { Issue.record("atteso errore"); return }
        #expect(t.contains("referto BIA"))
    }

    @Test func biaValida() {
        var m = Misura(data: "2026-10-14")
        m.peso = 80
        guard case .bia(let letta) = ImportaPDF.valuta(.bia, giorni: nil, misura: m) else { Issue.record("attesa bia"); return }
        #expect(letta.peso == 80)
    }
}
