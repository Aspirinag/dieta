import Foundation
import Testing
import UserNotifications
@testable import Forma

// Recupero dalla Live Activity e dalla notifica: ±15 s, salta, salta il riscaldamento, «Ancora 30 s»
@MainActor
struct RecuperoLiveTests {
    enum Evento: Equatable { case aggiunta(Int), cancella }

    // Finto della notifica di fine recupero: tiene in ordine quello che il timer chiede
    final class Registro {
        var eventi: [Evento] = []
        var aggiunte: [Int] { eventi.compactMap { if case .aggiunta(let s) = $0 { s } else { nil } } }
        func timer() -> TimerRecupero {
            TimerRecupero(aggiungiNotifica: { s in
                try? await Task.sleep(for: .milliseconds(20))
                self.eventi.append(.aggiunta(s))
            }, cancellaNotifica: { self.eventi.append(.cancella) })
        }
    }

    func durata(_ t: TimerRecupero) -> Int? {
        t.stato.map { Int($0.fine.timeIntervalSince($0.inizio).rounded()) }
    }

    // ---------- ±15 s ----------

    @Test func piu15SpostaFineENotifica() async {
        let r = Registro()
        let t = r.timer()
        t.avvia(90)
        await t.attendiNotifica()
        t.cambia(15)
        await t.attendiNotifica()
        #expect(durata(t) == 105)
        #expect(r.aggiunte == [90, 105])
        #expect(r.eventi.last == .aggiunta(105))
        t.ferma()
    }

    @Test func meno15AnticipaFineENotifica() async {
        let r = Registro()
        let t = r.timer()
        t.avvia(90)
        await t.attendiNotifica()
        t.cambia(-15)
        await t.attendiNotifica()
        #expect(durata(t) == 75)
        #expect(r.aggiunte == [90, 75])
        t.ferma()
    }

    // Mai sotto adesso: se −15 porta oltre la fine, il recupero finisce e la notifica non resta
    @Test func meno15OltreLaFineChiudeIlRecupero() async {
        let r = Registro()
        let t = r.timer()
        t.avvia(10)
        await t.attendiNotifica()
        t.cambia(-15)
        await t.attendiNotifica()
        #expect(t.stato == nil)
        #expect(!t.attivo)
        #expect(r.eventi.last == .cancella)
    }

    // Senza recupero in corso (finito nel frattempo) ±15 non fa niente e non crea notifiche
    @Test func cambiaSenzaRecuperoNonFaNiente() async {
        let r = Registro()
        let t = r.timer()
        t.cambia(15)
        t.cambia(-15)
        await t.attendiNotifica()
        #expect(t.stato == nil)
        #expect(r.eventi.isEmpty)
    }

    // ---------- Salta ----------

    @Test func saltaFermaERimuoveLaNotificaInAttesa() async {
        let r = Registro()
        let t = r.timer()
        t.avvia(90)          // la notifica è ancora in corso di aggiunta
        t.ferma()
        await t.attendiNotifica()
        #expect(t.stato == nil)
        #expect(r.eventi.last == .cancella)
    }

    @Test func saltaDopoLaNotificaAggiuntaLaToglie() async {
        let r = Registro()
        let t = r.timer()
        t.avvia(90)
        await t.attendiNotifica()
        t.ferma()
        await t.attendiNotifica()
        #expect(r.eventi.last == .cancella)
    }

    // ---------- «Ancora 30 s» ----------

    @Test func ancora30AvviaUnRecuperoDi30Secondi() async {
        let r = Registro()
        let t = r.timer()
        t.ancora30()
        await t.attendiNotifica()
        #expect(durata(t) == 30)
        #expect(t.attivo)
        #expect(r.eventi.last == .aggiunta(30))
        t.ferma()
    }

    @Test func ancora30SostituisceUnRecuperoInCorso() async {
        let r = Registro()
        let t = r.timer()
        t.avvia(90)
        await t.attendiNotifica()
        t.ancora30()
        await t.attendiNotifica()
        #expect(durata(t) == 30)
        #expect(r.eventi.last == .aggiunta(30))
        t.ferma()
    }

    @Test func laNotificaDiFineRecuperoHaLAzioneAncora30() {
        let categorie = Notifiche.categorie()
        let c = categorie.first { $0.identifier == Notifiche.categoriaRecupero }
        #expect(c?.actions.map(\.identifier) == [Notifiche.azioneAncora30])
        #expect(c?.actions.first?.options.contains(.foreground) == false)   // non apre l'app
        #expect(Notifiche.eAncora30(Notifiche.azioneAncora30))
        #expect(!Notifiche.eAncora30(UNNotificationDefaultActionIdentifier))
    }

    // ---------- Salta il riscaldamento ----------

    func palestraSenzaRiscaldamento() -> Palestra {
        var s = StatoPalestra()
        var a = Allenamento(nome: "Push", esercizi: [EsercizioFatto(esercizio: "panca", serie: [SerieFatta(), SerieFatta()])])
        a.riscaldamento = ["0": true]
        s.inCorso = a
        return Palestra(stato: s)
    }

    func live(_ p: Palestra) -> StatoAllenamentoLive? {
        StatoAllenamentoLive.da(allenamento: p.stato.inCorso, ultimaSerie: p.ultimaSerie, recupero: nil,
                                libreria: [Esercizio(id: "panca", nome: "Panca piana", muscolo: .petto, attrezzo: .bilanciere)])
    }

    @Test func saltaIlRiscaldamentoPortaLaLiveAllaPrimaSerie() throws {
        let p = palestraSenzaRiscaldamento()
        let prima = try #require(live(p))
        #expect(prima.movimento == 1)       // c'è ancora un movimento da fare
        p.saltaRiscaldamentoDaLive()
        let dopo = try #require(live(p))
        #expect(dopo.movimento == nil)
        #expect(!dopo.riscaldamento)
        #expect(dopo.esercizio == "Panca piana")
        #expect(dopo.serie == 1)
        #expect(dopo.idSerie == p.stato.inCorso?.esercizi[0].serie[0].id)
        #expect(p.stato.inCorso?.riscaldamentoSaltato == true)
    }

    @Test func saltaIlRiscaldamentoNonSegnaIMovimentiComeFatti() {
        let p = palestraSenzaRiscaldamento()
        p.saltaRiscaldamentoDaLive()
        #expect(p.stato.inCorso?.riscaldamento == ["0": true])
    }

    @Test func saltaIlRiscaldamentoSenzaAllenamentoNonFaNiente() {
        let p = Palestra(stato: StatoPalestra())
        p.saltaRiscaldamentoDaLive()
        #expect(p.stato.inCorso == nil)
    }

    @Test func riscaldamentoSaltatoSiCodificaEVecchioJSONHaIlPredefinito() throws {
        var a = Allenamento(nome: "Push")
        a.riscaldamentoSaltato = true
        let letto = try JSONDecoder().decode(Allenamento.self, from: JSONEncoder().encode(a))
        #expect(letto.riscaldamentoSaltato)
        let vecchio = try JSONDecoder().decode(Allenamento.self, from: Data(#"{"nome":"Push"}"#.utf8))
        #expect(!vecchio.riscaldamentoSaltato)
    }
}
