import Foundation
import Testing
@testable import Forma

// Lista della spesa di una settimana scelta (anche la prossima)
@MainActor
struct SpesaTests {
    private func piano(_ nome: String, dal: String, al: String, cibo: String) -> Piano {
        let pasto = Pasto(nome: "Pranzo", opzioni: [Opzione(alimenti: [Alimento(nome: cibo, quantita: "80 g")])])
        return Piano(nome: nome, dal: dal, al: al, giorni: Giorni.nomi.map { GiornoPiano(nome: $0, palestra: false, pasti: [pasto]) })
    }

    @Test func settimanaProssimaUsaIlSuoPiano() {
        var p = Profilo(nome: "Io")
        p.piani = [piano("A", dal: "2026-11-02", al: "2026-11-08", cibo: "Riso"),
                   piano("B", dal: "2026-11-09", al: "", cibo: "Pasta")]
        let voci = p.vociSpesa(lunedi: "2026-11-09")
        #expect(voci.map(\.nome) == ["Pasta"])
        #expect(voci.first?.quanto == "560 g (7 volte)")
        #expect(p.vociSpesa(lunedi: "2026-11-02").map(\.nome) == ["Riso"])
    }

    @Test func daVenerdiSiProponeLaProssima() {
        #expect(Profilo.lunediSpesa(oggi: "2026-11-05") == "2026-11-02")   // giovedì
        #expect(Profilo.lunediSpesa(oggi: "2026-11-06") == "2026-11-09")   // venerdì
        #expect(Profilo.lunediSpesa(oggi: "2026-11-08") == "2026-11-09")   // domenica
    }

    @Test func spunteDiDueSettimaneConvivono() {
        var p = Profilo(nome: "Io")
        p.spunta("riso", lunedi: "2026-11-02")
        p.spunta("pasta", lunedi: "2026-11-09")
        #expect(p.spunteSpesa(lunedi: "2026-11-02") == ["riso": true])
        #expect(p.spunteSpesa(lunedi: "2026-11-09") == ["pasta": true])
        // Per la web app la settimana in «spesa» resta quella corrente
        #expect(p.spesa?.settimana == "2026-11-02")
        // Una terza settimana fa uscire la più vecchia
        p.spunta("pane", lunedi: "2026-11-16")
        #expect(p.spunteSpesa(lunedi: "2026-11-02").isEmpty)
        #expect(p.spunteSpesa(lunedi: "2026-11-09") == ["pasta": true])
        // Togliere le spunte vale solo per la settimana scelta
        p.azzeraSpesa(lunedi: "2026-11-16")
        #expect(p.spunteSpesa(lunedi: "2026-11-09") == ["pasta": true])
        #expect(p.spunteSpesa(lunedi: "2026-11-16").isEmpty)
    }
}
