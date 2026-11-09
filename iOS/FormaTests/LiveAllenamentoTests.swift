import Foundation
import Testing
@testable import Forma

// La Live Activity dell'allenamento: costruzione dello stato, gestore (avvia, aggiorna, chiude) e «Fatta» dalla schermata bloccata
@MainActor
struct LiveAllenamentoTests {
    final class Finto: SistemaAttivita {
        enum Chiamata: Equatable { case avvia(StatoAllenamentoLive), aggiorna(StatoAllenamentoLive), chiudi }
        var chiamate: [Chiamata] = []
        func avvia(_ stato: StatoAllenamentoLive) { chiamate.append(.avvia(stato)) }
        func aggiorna(_ stato: StatoAllenamentoLive) { chiamate.append(.aggiorna(stato)) }
        func chiudi() { chiamate.append(.chiudi) }
    }

    let adesso = Date(timeIntervalSinceReferenceDate: 800_000_000)
    let libreria = [
        Esercizio(id: "panca", nome: "Panca piana", muscolo: .petto, attrezzo: .bilanciere),
        Esercizio(id: "squat", nome: "Squat", muscolo: .quadricipiti, attrezzo: .bilanciere),
        Esercizio(id: "addome", nome: "Addominali", muscolo: .addominali, attrezzo: .corpoLibero),
    ]

    func recupero(_ secondi: TimeInterval, _ esercizio: String? = "Panca piana") -> StatoRecupero {
        StatoRecupero(inizio: adesso, fine: adesso.addingTimeInterval(secondi), esercizio: esercizio)
    }

    func allenamento(_ esercizi: [EsercizioFatto]) -> Allenamento {
        Allenamento(nome: "Push", inizio: adesso, esercizi: esercizi)
    }

    func stato(_ a: Allenamento?, ultima: UUID? = nil, recupero r: StatoRecupero? = nil,
               precedente: @escaping (String, Int) -> SerieFatta? = { _, _ in nil }) -> StatoAllenamentoLive? {
        StatoAllenamentoLive.da(allenamento: a, ultimaSerie: ultima, recupero: r, libreria: libreria, precedente: precedente)
    }

    // ---------- Costruzione dello stato ----------

    @Test func senzaAllenamentoNonCeStato() {
        #expect(stato(nil) == nil)
    }

    @Test func serieConValoriNumeroETotale() throws {
        let s1 = SerieFatta(kg: 60, rip: 8, fatta: true)
        let s2 = SerieFatta(kg: 62.5, rip: 6)
        let a = allenamento([EsercizioFatto(esercizio: "panca", serie: [s1, s2, SerieFatta()])])
        let live = try #require(stato(a, ultima: s1.id))
        #expect(live.titolo == "Push")
        #expect(live.inizio == adesso)
        #expect(live.esercizio == "Panca piana")
        #expect(live.serie == 2)
        #expect(live.totaleSerie == 3)
        #expect(live.kg == 62.5)
        #expect(live.rip == 6)
        #expect(live.idSerie == s2.id)
        #expect(live.riscaldamento == false)
        #expect(live.corpoLibero == false)
        #expect(live.puoSpuntare)
        #expect(live.recupero == nil)
    }

    @Test func senzaRiferimentoParteDallaPrimaDaFare() throws {
        let s1 = SerieFatta(kg: 60, rip: 8, fatta: true)
        let s2 = SerieFatta(kg: 60, rip: 8)
        let a = allenamento([EsercizioFatto(esercizio: "panca", serie: [s1, s2])])
        #expect(try #require(stato(a)).idSerie == s2.id)
    }

    @Test func valoriVuotiDallaPrecedente() throws {
        let s = SerieFatta()
        let a = allenamento([EsercizioFatto(esercizio: "squat", serie: [s])])
        var richieste: [String] = []
        let live = try #require(stato(a) { id, i in
            richieste.append("\(id)\(i)")
            return SerieFatta(kg: 100, rip: 5, fatta: true)
        })
        #expect(richieste == ["squat0"])
        #expect(live.kg == 100)
        #expect(live.rip == 5)
        #expect(live.puoSpuntare)
    }

    @Test func iCampiScrittiHannoLaPrecedenza() throws {
        let a = allenamento([EsercizioFatto(esercizio: "squat", serie: [SerieFatta(kg: 90, rip: nil)])])
        let live = try #require(stato(a) { _, _ in SerieFatta(kg: 100, rip: 5, fatta: true) })
        #expect(live.kg == 90)
        #expect(live.rip == 5)
    }

    @Test func corpoLiberoSenzaKgValeZero() throws {
        let s = SerieFatta(kg: nil, rip: 15)
        let a = allenamento([EsercizioFatto(esercizio: "addome", serie: [s])])
        let live = try #require(stato(a))
        #expect(live.corpoLibero)
        #expect(live.kg == 0)
        #expect(live.rip == 15)
        #expect(live.puoSpuntare)
    }

    @Test func mancanoLeRipetizioniNientePulsanteFatta() throws {
        let a = allenamento([EsercizioFatto(esercizio: "panca", serie: [SerieFatta(kg: 60, rip: nil)])])
        let live = try #require(stato(a))
        #expect(live.esercizio == "Panca piana")
        #expect(live.kg == 60)
        #expect(live.rip == nil)
        #expect(live.puoSpuntare == false)
    }

    @Test func mancanoIKgSuUnEsercizioConPesi() throws {
        let a = allenamento([EsercizioFatto(esercizio: "panca", serie: [SerieFatta(kg: nil, rip: 8)])])
        let live = try #require(stato(a))
        #expect(live.kg == nil)
        #expect(live.rip == 8)
        #expect(live.puoSpuntare == false)
    }

    @Test func tutteLeSerieFatte() throws {
        let a = allenamento([EsercizioFatto(esercizio: "panca", serie: [SerieFatta(kg: 60, rip: 8, fatta: true)]),
                             EsercizioFatto(esercizio: "squat", serie: [SerieFatta(kg: 80, rip: 5, fatta: true)])])
        let live = try #require(stato(a, recupero: recupero(90)))
        #expect(live.esercizio == nil)
        #expect(live.idSerie == nil)
        #expect(live.prossimo == nil)
        #expect(live.puoSpuntare == false)
        #expect(live.titolo == "Push")
        #expect(live.recupero == recupero(90))   // il recupero dell'ultima serie si vede ancora
    }

    @Test func serieDiRiscaldamento() throws {
        let r = SerieFatta(kg: 20, rip: 10, riscaldamento: true)
        let a = allenamento([EsercizioFatto(esercizio: "panca", serie: [r, SerieFatta(kg: 60, rip: 8)])])
        let live = try #require(stato(a))
        #expect(live.riscaldamento)
        #expect(live.serie == 1)
        #expect(live.totaleSerie == 2)
    }

    @Test func prossimoEsercizioConSerieAperte() throws {
        let a = allenamento([EsercizioFatto(esercizio: "panca", serie: [SerieFatta(kg: 60, rip: 8)]),
                             EsercizioFatto(esercizio: "squat", serie: [SerieFatta(kg: 80, rip: 5)])])
        #expect(try #require(stato(a)).prossimo == "Squat")
    }

    @Test func prossimoSaltaGliEserciziFinitiEPoiTornaIndietro() throws {
        let finito = EsercizioFatto(esercizio: "squat", serie: [SerieFatta(kg: 80, rip: 5, fatta: true)])
        let aperto = SerieFatta(kg: 60, rip: 8)
        // Ultimo esercizio aperto: il prossimo è il primo aperto prima
        let indietro = allenamento([EsercizioFatto(esercizio: "panca", serie: [SerieFatta(kg: 1, rip: 1), SerieFatta()]), finito,
                                    EsercizioFatto(esercizio: "addome", serie: [aperto])])
        let live = try #require(stato(indietro, ultima: aperto.id))
        #expect(live.esercizio == "Addominali")
        #expect(live.prossimo == "Panca piana")
        // Gli altri sono finiti: ultimo esercizio
        let solo = allenamento([EsercizioFatto(esercizio: "panca", serie: [SerieFatta(kg: 60, rip: 8)]), finito])
        #expect(try #require(stato(solo)).prossimo == nil)
    }

    @Test func esercizioFuoriLibreriaUsaIlSuoId() throws {
        let a = allenamento([EsercizioFatto(esercizio: "Curl strano", serie: [SerieFatta(kg: 10, rip: 10)])])
        #expect(try #require(stato(a)).esercizio == "Curl strano")
    }

    @Test func ilRecuperoPassaNelloStato() throws {
        let a = allenamento([EsercizioFatto(esercizio: "panca", serie: [SerieFatta(kg: 60, rip: 8)])])
        #expect(try #require(stato(a, recupero: recupero(90))).recupero == recupero(90))
    }

    // ---------- Gestore ----------

    func base(_ r: StatoRecupero? = nil, serie: Int = 1) -> StatoAllenamentoLive {
        StatoAllenamentoLive(titolo: "Push", inizio: adesso, esercizio: "Panca piana", serie: serie, totaleSerie: 3,
                             kg: 60, rip: 8, idSerie: UUID(uuid: (1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, UInt8(serie))),
                             recupero: r)
    }

    @Test func avviaAggiornaEChiude() {
        let finto = Finto()
        let live = LiveAllenamento(sistema: finto)
        live.applica(base(), adesso: adesso)
        live.applica(base(recupero(90)), adesso: adesso)            // serie fatta: parte il recupero
        live.applica(base(recupero(105)), adesso: adesso)           // +15 s
        live.applica(base(serie: 2), adesso: adesso)                // recupero finito o saltato
        live.applica(nil, adesso: adesso)                           // allenamento finito
        #expect(finto.chiamate == [.avvia(base()), .aggiorna(base(recupero(90))), .aggiorna(base(recupero(105))),
                                   .aggiorna(base(serie: 2)), .chiudi])
        #expect(live.mostrato == nil)
    }

    @Test func statoUgualeNonRichiamaIlSistema() {
        let finto = Finto()
        let live = LiveAllenamento(sistema: finto)
        live.applica(base(), adesso: adesso)
        live.applica(base(), adesso: adesso)
        live.applica(nil, adesso: adesso)
        live.applica(nil, adesso: adesso)
        #expect(finto.chiamate == [.avvia(base()), .chiudi])
    }

    @Test func recuperoScadutoSiTogliePerNonChiudereLAttivita() {
        let finto = Finto()
        let live = LiveAllenamento(sistema: finto)
        // Già scaduto all'arrivo: l'attività parte senza recupero
        live.applica(base(recupero(-1)), adesso: adesso)
        #expect(finto.chiamate == [.avvia(base())])
        // Scade mentre è mostrato: si aggiorna senza recupero, non si chiude
        live.applica(base(recupero(60)), adesso: adesso)
        live.applica(base(recupero(60)), adesso: adesso.addingTimeInterval(61))
        #expect(finto.chiamate == [.avvia(base()), .aggiorna(base(recupero(60))), .aggiorna(base())])
        #expect(live.mostrato?.recupero == nil)
    }

    @Test func dopoLaChiusuraUnNuovoAllenamentoRiparte() {
        let finto = Finto()
        let live = LiveAllenamento(sistema: finto)
        live.applica(base(), adesso: adesso)
        live.applica(nil, adesso: adesso)
        live.applica(base(), adesso: adesso)
        #expect(finto.chiamate == [.avvia(base()), .chiudi, .avvia(base())])
    }

    // ---------- «Fatta» dalla Live Activity ----------

    func palestraCon(_ esercizi: [EsercizioFatto], storico: [Allenamento] = []) -> (Palestra, TimerRecupero) {
        var s = StatoPalestra()
        s.esercizi = libreria
        s.inCorso = allenamento(esercizi)
        s.allenamenti = storico
        return (Palestra(stato: s), TimerRecupero(aggiungiNotifica: { _ in }, cancellaNotifica: {}))
    }

    @Test func segnaDaLiveScriveIValoriEAvviaIlRecupero() {
        let s = SerieFatta(kg: 60, rip: 8)
        let (p, timer) = palestraCon([EsercizioFatto(esercizio: "panca", recupero: 120, serie: [s, SerieFatta()])])
        p.segnaDaLive(s.id, timer: timer)
        let fatta = p.stato.inCorso?.esercizi[0].serie[0]
        #expect(fatta?.fatta == true)
        #expect(fatta?.kg == 60)
        #expect(fatta?.rip == 8)
        #expect(p.ultimaSerie == s.id)
        #expect(timer.stato?.esercizio == "Panca piana")
        #expect(timer.stato.map { $0.fine.timeIntervalSince($0.inizio).rounded() } == 120)
        timer.ferma()
    }

    @Test func segnaDaLiveUsaLaPrecedenteEIlCorpoLibero() {
        let storico = Allenamento(nome: "Prima", inizio: adesso.addingTimeInterval(-86400),
                                  esercizi: [EsercizioFatto(esercizio: "squat", serie: [SerieFatta(kg: 100, rip: 5, fatta: true)])])
        let a = SerieFatta()
        let b = SerieFatta(kg: nil, rip: 12)
        let (p, timer) = palestraCon([EsercizioFatto(esercizio: "squat", serie: [a]),
                                      EsercizioFatto(esercizio: "addome", serie: [b])], storico: [storico])
        p.segnaDaLive(a.id, timer: timer)
        #expect(p.stato.inCorso?.esercizi[0].serie[0].kg == 100)
        #expect(p.stato.inCorso?.esercizi[0].serie[0].rip == 5)
        p.segnaDaLive(b.id, timer: timer)
        #expect(p.stato.inCorso?.esercizi[1].serie[0].kg == 0)
        #expect(p.stato.inCorso?.esercizi[1].serie[0].rip == 12)
        timer.ferma()
    }

    @Test func segnaDaLiveSerieGiaFattaNonFaNiente() {
        let s = SerieFatta(kg: 60, rip: 8, fatta: true)
        let (p, timer) = palestraCon([EsercizioFatto(esercizio: "panca", serie: [s])])
        p.segnaDaLive(s.id, timer: timer)
        #expect(timer.stato == nil)
        #expect(p.ultimaSerie == nil)
        #expect(p.stato.inCorso?.esercizi[0].serie[0] == s)
    }

    @Test func segnaDaLiveValoriMancantiNonFaNiente() {
        let s = SerieFatta(kg: 60, rip: nil)
        let (p, timer) = palestraCon([EsercizioFatto(esercizio: "panca", serie: [s])])
        p.segnaDaLive(s.id, timer: timer)
        #expect(p.stato.inCorso?.esercizi[0].serie[0] == s)
        #expect(timer.stato == nil)
        #expect(p.ultimaSerie == nil)
    }

    @Test func segnaDaLiveSerieInesistenteNonFaNiente() {
        let (p, timer) = palestraCon([EsercizioFatto(esercizio: "panca", serie: [SerieFatta(kg: 60, rip: 8)])])
        let prima = p.stato.inCorso
        p.segnaDaLive(UUID(), timer: timer)
        #expect(p.stato.inCorso == prima)
        #expect(timer.stato == nil)
    }

    // Dopo «Fatta» lo stato della Live Activity passa alla serie dopo e mostra il recupero
    @Test func dopoFattaLaLiveMostraLaSerieSuccessivaEIlRecupero() throws {
        let s1 = SerieFatta(kg: 60, rip: 8)
        let s2 = SerieFatta(kg: 62.5, rip: 6)
        let (p, timer) = palestraCon([EsercizioFatto(esercizio: "panca", serie: [s1, s2])])
        p.segnaDaLive(s1.id, timer: timer)
        let live = try #require(StatoAllenamentoLive.da(allenamento: p.stato.inCorso, ultimaSerie: p.ultimaSerie,
                                                        recupero: timer.stato, libreria: p.stato.esercizi))
        #expect(live.serie == 2)
        #expect(live.idSerie == s2.id)
        #expect(live.recupero != nil)
        timer.ferma()
    }

    // Il timer espone lo stato che la Live Activity legge: avvio, ±15 s e fermata
    @Test func ilTimerEsponeLoStatoGiusto() {
        let timer = TimerRecupero(aggiungiNotifica: { _ in }, cancellaNotifica: {})
        timer.avvia(90, esercizio: "Panca piana")
        let primo = timer.stato
        #expect(primo?.esercizio == "Panca piana")
        #expect(primo.map { $0.fine.timeIntervalSince($0.inizio).rounded() } == 90)
        timer.cambia(15)
        #expect(timer.stato.map { $0.fine.timeIntervalSince($0.inizio).rounded() } == 105)
        #expect(timer.stato?.inizio == primo?.inizio)
        timer.ferma()
        #expect(timer.stato == nil)
    }
}
