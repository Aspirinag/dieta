import Foundation
import Testing
@testable import Forma

// Sessioni del Watch e allenamenti rimasti aperti: aggancio per orario, annullare davvero, durata sensata
@MainActor
struct SessioniWatchTests {
    let libreria = [Esercizio(id: "panca", nome: "Panca piana", muscolo: .petto, attrezzo: .bilanciere)]

    func palestra(inCorso: Allenamento?, storico: [Allenamento] = []) -> (Palestra, TimerRecupero) {
        var s = StatoPalestra()
        s.esercizi = libreria
        s.inCorso = inCorso
        s.allenamenti = storico
        return (Palestra(stato: s), TimerRecupero(aggiungiNotifica: { _ in }, cancellaNotifica: {}))
    }

    func serie(_ fattaIl: Date?) -> SerieFatta {
        var s = SerieFatta(kg: 60, rip: 8, fatta: true)
        s.fattaIl = fattaIl
        return s
    }

    func watch(_ uuid: String, da: TimeInterval, a: TimeInterval) -> AllenamentoWatch {
        AllenamentoWatch(uuid: uuid, genere: .palestra, inizio: Date().addingTimeInterval(da),
                         fine: Date().addingTimeInterval(a), calorie: 300, battito: 120, km: 0)
    }

    // ---------- Aggancio per orario ----------

    @Test func watchDiOggiNonSiAgganciaAUnAllenamentoDiDueGiorniFa() {
        let vecchio = Allenamento(nome: "Push", inizio: Date().addingTimeInterval(-2 * 86400))
        let (p, _) = palestra(inCorso: vecchio)
        guard case .nuovo = p.registraDalWatch(watch("W1", da: -3600, a: -60)) else { Issue.record("doveva essere una sessione nuova"); return }
        #expect(p.stato.inCorso?.watch == nil)
        #expect(p.stato.allenamenti.count == 1)
    }

    @Test func watchDuranteLAllenamentoDiOggiSiAggancia() {
        let a = Allenamento(nome: "Push", inizio: Date().addingTimeInterval(-1800))
        let (p, _) = palestra(inCorso: a)
        guard case .agganciato = p.registraDalWatch(watch("W2", da: -1800, a: -60)) else { Issue.record("doveva agganciarsi"); return }
        #expect(p.stato.inCorso?.watch?.uuid == "W2")
    }

    @Test func watchAgganciaUnAllenamentoLungoSenzaOrariDelleSerie() {
        // Allenamento di oggi iniziato 2 ore fa, serie vecchie senza orario: resta «in corso» fino ad adesso
        var a = Allenamento(nome: "Push", inizio: Date().addingTimeInterval(-7200))
        a.esercizi = [EsercizioFatto(esercizio: "panca", serie: [serie(nil)])]
        let (p, _) = palestra(inCorso: a)
        guard case .agganciato = p.registraDalWatch(watch("W3", da: -3600, a: -60)) else { Issue.record("doveva agganciarsi"); return }
    }

    @Test func terminaNonAssorbeSessioniWatchDeiGiorniPrima() throws {
        var soloWatch = Allenamento(nome: Allenamento.nomeWatch, inizio: Date().addingTimeInterval(-86400 - 3600))
        soloWatch.fine = Date().addingTimeInterval(-86400)
        soloWatch.watch = DatiWatch(uuid: "W4", calorie: 200, battito: 110)
        let a = Allenamento(nome: "Push", inizio: Date().addingTimeInterval(-2 * 86400), esercizi: [
            EsercizioFatto(esercizio: "panca", serie: [serie(Date().addingTimeInterval(-2 * 86400 + 600))])])
        let (p, _) = palestra(inCorso: a, storico: [soloWatch])
        let salvato = try #require(p.termina())
        #expect(salvato.watch == nil)
        #expect(p.stato.allenamenti.contains { $0.watch?.uuid == "W4" })
        #expect(p.stato.allenamenti.count == 2)
    }

    @Test func terminaUnisceLaSessioneWatchDiOggi() throws {
        var soloWatch = Allenamento(nome: Allenamento.nomeWatch, inizio: Date().addingTimeInterval(-3000))
        soloWatch.fine = Date().addingTimeInterval(-100)
        soloWatch.watch = DatiWatch(uuid: "W5", calorie: 200, battito: 110)
        let a = Allenamento(nome: "Push", inizio: Date().addingTimeInterval(-3000), esercizi: [
            EsercizioFatto(esercizio: "panca", serie: [serie(Date().addingTimeInterval(-200))])])
        let (p, _) = palestra(inCorso: a, storico: [soloWatch])
        let salvato = try #require(p.termina())
        #expect(salvato.watch?.uuid == "W5")
        #expect(p.stato.allenamenti.count == 1)
    }

    // ---------- Annullare davvero ----------

    @Test func annullaEIniziaTieneLaSessioneWatchEFermaIlRecupero() {
        var a = Allenamento(nome: "Push", inizio: Date().addingTimeInterval(-1800))
        a.watch = DatiWatch(uuid: "W6", calorie: 200, battito: 110)
        let (p, timer) = palestra(inCorso: a)
        timer.avvia(90, serie: UUID(), esercizio: "Panca piana")
        p.annullaEInizia(nil, timer: timer)
        #expect(p.stato.allenamenti.count == 1)
        #expect(p.stato.allenamenti[0].watch?.uuid == "W6")
        #expect(p.stato.allenamenti[0].soloWatch)
        #expect(p.stato.inCorso?.watch == nil)
        #expect(p.stato.inCorso?.id != a.id)
        #expect(timer.stato == nil)
    }

    // ---------- Durata ----------

    @Test func allenamentoChiusoIlGiornoDopoDuraFinoAllUltimaSeriePiuMargine() throws {
        let inizio = Date().addingTimeInterval(-26 * 3600)
        let ultima = inizio.addingTimeInterval(50 * 60)
        let a = Allenamento(nome: "Push", inizio: inizio, esercizi: [
            EsercizioFatto(esercizio: "panca", serie: [serie(inizio.addingTimeInterval(600)), serie(ultima)])])
        let (p, _) = palestra(inCorso: a)
        let salvato = try #require(p.termina())
        #expect(salvato.durata == 50 * 60 + Allenamento.margineFine)
        #expect(salvato.fine == ultima.addingTimeInterval(Allenamento.margineFine))
    }

    @Test func allenamentoVecchioSenzaSerieConOrarioDuraUnMargineDallInizio() throws {
        let inizio = Date().addingTimeInterval(-30 * 3600)
        let a = Allenamento(nome: "Push", inizio: inizio, esercizi: [EsercizioFatto(esercizio: "panca", serie: [serie(nil)])])
        let (p, _) = palestra(inCorso: a)
        let salvato = try #require(p.termina())
        #expect(salvato.durata <= Allenamento.margineFine)
    }

    @Test func allenamentoNormaleDuraFinoAdesso() throws {
        let inizio = Date().addingTimeInterval(-3000)
        let a = Allenamento(nome: "Push", inizio: inizio, esercizi: [
            EsercizioFatto(esercizio: "panca", serie: [serie(Date().addingTimeInterval(-120))])])
        let (p, _) = palestra(inCorso: a)
        let salvato = try #require(p.termina())
        #expect(abs(salvato.durata - 3000) < 5)
    }

    @Test func allenamentoSenzaOrariDelleSerieDiOggiDuraFinoAdesso() throws {
        let inizio = Date().addingTimeInterval(-2 * 3600)
        let a = Allenamento(nome: "Push", inizio: inizio, esercizi: [EsercizioFatto(esercizio: "panca", serie: [serie(nil)])])
        let (p, _) = palestra(inCorso: a)
        let salvato = try #require(p.termina())
        #expect(abs(salvato.durata - 7200) < 5)
    }

    @Test func fattaIlSiDecodificaTollerante() throws {
        let s = try JSONDecoder().decode(SerieFatta.self, from: Data(#"{"kg":50,"rip":5,"fatta":true}"#.utf8))
        #expect(s.fattaIl == nil)
        let giro = try JSONDecoder().decode(SerieFatta.self, from: JSONEncoder().encode(serie(Date(timeIntervalSinceReferenceDate: 1000))))
        #expect(giro.fattaIl == Date(timeIntervalSinceReferenceDate: 1000))
    }
}
