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
        #expect(voci.first?.quanto == "560 g")
        #expect(p.vociSpesa(lunedi: "2026-11-02").map(\.nome) == ["Riso"])
    }

    @Test func daVenerdiSiProponeLaProssima() {
        #expect(Profilo.lunediSpesa(oggi: "2026-11-05") == "2026-11-02")   // giovedì
        #expect(Profilo.lunediSpesa(oggi: "2026-11-06") == "2026-11-09")   // venerdì
        #expect(Profilo.lunediSpesa(oggi: "2026-11-08") == "2026-11-09")   // domenica
    }

    private func profilo(cibo: String, quantita: String) -> Profilo {
        let pasto = Pasto(nome: "Pranzo", opzioni: [Opzione(alimenti: [Alimento(nome: cibo, quantita: quantita)])])
        var p = Profilo(nome: "Io")
        p.piani = [Piano(nome: "A", dal: "2026-11-02", al: "", giorni: Giorni.nomi.map { GiornoPiano(nome: $0, palestra: false, pasti: [pasto]) })]
        return p
    }

    @Test func kgSopraIlChilo() {
        let p = profilo(cibo: "Riso", quantita: "150 g")
        #expect(p.vociSpesa(lunedi: "2026-11-02").first?.quanto == "1,05 kg")
    }

    @Test func millilitriELitri() {
        #expect(profilo(cibo: "Latte", quantita: "250 ml").vociSpesa(lunedi: "2026-11-02").first?.quanto == "1,75 L")
        #expect(profilo(cibo: "Latte", quantita: "1 l").vociSpesa(lunedi: "2026-11-02").first?.quanto == "7 L")
    }

    @Test func porzioniSenzaGrammi() {
        let p = profilo(cibo: "Insalata", quantita: "a piacere")
        #expect(p.vociSpesa(lunedi: "2026-11-02").first?.quanto == "7 porzioni")
        var q = p
        q.piani[0].giorni = q.piani[0].giorni.enumerated().map { i, g in i == 0 ? g : GiornoPiano(nome: g.nome, palestra: false, pasti: []) }
        #expect(q.vociSpesa(lunedi: "2026-11-02").first?.quanto == "1 porzione")
    }

    @Test func giorniDellaVoce() {
        let v = profilo(cibo: "Riso", quantita: "80 g").vociSpesa(lunedi: "2026-11-02").first
        #expect(v?.giorni.count == 7)
        #expect(v?.giorni.first?.giorno == "lun")
        #expect(v?.giorni.first?.quanto == "80 g")
        #expect(v?.giorni.last?.giorno == "dom")
    }

    @Test func repartoDellaVoce() {
        let v = profilo(cibo: "Mela", quantita: "150 g").vociSpesa(lunedi: "2026-11-02").first
        #expect(v?.reparto == .fruttaVerdura)
        #expect(v?.aggiunta == false)
    }

    @Test func repartoManualeVinceSullaStima() {
        var p = profilo(cibo: "Riso", quantita: "80 g")
        #expect(p.reparto(di: "riso") == .panePastaCereali)
        p.sposta("riso", in: .dispensa)
        #expect(p.reparto(di: "riso") == .dispensa)
        #expect(p.vociSpesa(lunedi: "2026-11-02").first?.reparto == .dispensa)
    }

    @Test func extraCompareNellaSettimana() {
        var p = profilo(cibo: "Riso", quantita: "80 g")
        p.aggiungiExtra("Biscotti", lunedi: "2026-11-02")
        let voci = p.vociSpesa(lunedi: "2026-11-02")
        let extra = voci.first { $0.nome == "Biscotti" }
        #expect(extra?.aggiunta == true)
        #expect(extra?.quanto == "")
        #expect(p.vociSpesa(lunedi: "2026-11-09").contains { $0.nome == "Biscotti" } == false)
        p.togliExtra("Biscotti", lunedi: "2026-11-02")
        #expect(p.vociSpesa(lunedi: "2026-11-02").contains { $0.nome == "Biscotti" } == false)
    }

    @Test func jsonVecchioSenzaCampiNuovi() throws {
        let s = try JSONDecoder().decode(Spesa.self, from: Data(#"{"settimana":"2026-11-02","presi":{}}"#.utf8))
        #expect(s.extra == [])
        let p = try JSONDecoder().decode(Profilo.self, from: Data(#"{"nome":"Io"}"#.utf8))
        #expect(p.repartiSpesa == nil)
    }

    @Test func repartiSpesaUsaLaChiaveDelFileDati() throws {
        var p = Profilo(nome: "Io")
        p.sposta("riso", in: .dispensa)
        let json = String(decoding: try JSONEncoder().encode(p), as: UTF8.self)
        #expect(json.contains("reparti_spesa"))
        #expect(try JSONDecoder().decode(Profilo.self, from: Data(json.utf8)).repartiSpesa == ["riso": "dispensa"])
    }

    @Test func extraSopravvivonoAlleSpunteTolte() {
        var p = profilo(cibo: "Riso", quantita: "80 g")
        p.aggiungiExtra("Biscotti", lunedi: "2026-11-02")
        p.spesa?.presi["riso"] = true
        p.togliSpunte()
        #expect(p.spesa?.presi == [:])
        #expect(p.spesa?.extra == ["Biscotti"])
        #expect(p.spesa?.settimana == "2026-11-02")
    }
}
