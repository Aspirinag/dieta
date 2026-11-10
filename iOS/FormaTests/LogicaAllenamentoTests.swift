import Foundation
import Testing
@testable import Forma

// Correzioni alla logica dell'allenamento in corso (dalla revisione della palestra)
@MainActor
struct LogicaAllenamentoTests {
    let libreria = [
        Esercizio(id: "panca", nome: "Panca piana", muscolo: .petto, attrezzo: .bilanciere),
        Esercizio(id: "squat", nome: "Squat", muscolo: .quadricipiti, attrezzo: .bilanciere),
        Esercizio(id: "trazioni", nome: "Trazioni", muscolo: .schiena, attrezzo: .corpoLibero),
    ]

    func palestra(inCorso: Allenamento?, storico: [Allenamento] = []) -> (Palestra, TimerRecupero) {
        var s = StatoPalestra()
        s.esercizi = libreria
        s.inCorso = inCorso
        s.allenamenti = storico
        return (Palestra(stato: s), TimerRecupero(aggiungiNotifica: { _ in }, cancellaNotifica: {}))
    }

    func riscaldato(_ a: Allenamento) -> Allenamento {
        var a = a
        for i in Libreria.riscaldamento.indices { a.riscaldamento[String(i)] = true }
        return a
    }

    // Allenamento passato di squat: un riscaldamento da 40 × 10 e una serie di lavoro da 100 × 5
    var squatDiIeri: Allenamento {
        Allenamento(nome: "Prima", inizio: Date().addingTimeInterval(-86400), esercizi: [
            EsercizioFatto(esercizio: "squat", serie: [SerieFatta(kg: 40, rip: 10, fatta: true, riscaldamento: true),
                                                     SerieFatta(kg: 100, rip: 5, fatta: true)])])
    }

    // 1. Riaprendo l'allenamento la serie attiva parte dall'ultima serie salvata, come la Live Activity
    @Test func serieAttivaPartePerUltimaSerie() {
        let a1 = SerieFatta(kg: 60, rip: 8)
        let b1 = SerieFatta(kg: 80, rip: 5, fatta: true), b2 = SerieFatta(kg: 80, rip: 5)
        let a = Allenamento(nome: "Oggi", esercizi: [EsercizioFatto(esercizio: "panca", serie: [a1]),
                                                     EsercizioFatto(esercizio: "squat", serie: [b1, b2])])
        let (p, _) = palestra(inCorso: a)
        p.ultimaSerie = b1.id
        // vista appena aperta: nessun riferimento proprio, vale l'ultima serie salvata
        #expect(p.serieAttiva(riferimento: nil) == b2.id)
        // dopo aver toccato una serie, vale quella
        #expect(p.serieAttiva(riferimento: a1.id) == a1.id)
        // senza ultima serie salvata: la prima da fare
        p.ultimaSerie = nil
        #expect(p.serieAttiva(riferimento: nil) == a1.id)
    }

    // 2. Il riscaldamento prende il riscaldamento corrispondente dell'ultima volta, non la serie di lavoro
    @Test func precedenteDelRiscaldamento() {
        let (p, _) = palestra(inCorso: nil, storico: [squatDiIeri])
        let serie = [SerieFatta(riscaldamento: true), SerieFatta(riscaldamento: true), SerieFatta()]
        #expect(p.precedente("squat", in: serie, posizione: 0)?.kg == 40)
        #expect(p.precedente("squat", in: serie, posizione: 1) == nil)   // l'ultima volta c'era un solo riscaldamento
        #expect(p.precedente("squat", in: serie, posizione: 2)?.kg == 100)
    }

    @Test func riscaldamentoVuotoPrendeIlRiscaldamentoDiPrima() {
        let caldo = SerieFatta(riscaldamento: true)
        let (p, timer) = palestra(inCorso: riscaldato(Allenamento(nome: "Oggi", esercizi: [
            EsercizioFatto(esercizio: "squat", serie: [caldo, SerieFatta()])])), storico: [squatDiIeri])
        p.segnaDaLive(caldo.id, timer: timer)
        #expect(p.stato.inCorso?.esercizi[0].serie[0].kg == 40)
        #expect(p.stato.inCorso?.esercizi[0].serie[0].rip == 10)
        timer.ferma()
    }

    @Test func riscaldamentoSenzaPrecedenteNonSiSegnaDaLive() {
        let senzaCaldo = Allenamento(nome: "Prima", inizio: Date().addingTimeInterval(-86400), esercizi: [
            EsercizioFatto(esercizio: "squat", serie: [SerieFatta(kg: 100, rip: 5, fatta: true)])])
        let caldo = SerieFatta(riscaldamento: true)
        let (p, timer) = palestra(inCorso: riscaldato(Allenamento(nome: "Oggi", esercizi: [
            EsercizioFatto(esercizio: "squat", serie: [caldo, SerieFatta()])])), storico: [senzaCaldo])
        p.segnaDaLive(caldo.id, timer: timer)
        #expect(p.stato.inCorso?.esercizi[0].serie[0].fatta == false)
        #expect(p.stato.inCorso?.esercizi[0].serie[0].kg == nil)
        timer.ferma()
    }

    @Test func liveRiscaldamentoMostraIlRiscaldamentoDiPrima() throws {
        let caldo = SerieFatta(riscaldamento: true)
        let a = riscaldato(Allenamento(nome: "Oggi", esercizi: [EsercizioFatto(esercizio: "squat", serie: [caldo, SerieFatta()])]))
        let (p, _) = palestra(inCorso: a, storico: [squatDiIeri])
        let live = try #require(StatoAllenamentoLive.da(
            allenamento: a, ultimaSerie: nil, recupero: nil, libreria: libreria,
            precedente: { p.precedente($0, $1) },
            precedenteRiscaldamento: { p.precedenteRiscaldamento($0, $1) }))
        #expect(live.idSerie == caldo.id)
        #expect(live.kg == 40)
        #expect(live.rip == 10)
    }

    // 3. Una serie spuntata e poi svuotata perde la spunta
    @Test func serieFattaSvuotataPerdeLaSpunta() {
        var s = SerieFatta(kg: 60, rip: 8, fatta: true)
        s.kg = nil
        let toltas = s.togliSpuntaSeIncompleta()
        #expect(toltas)
        #expect(!s.fatta)
        var r = SerieFatta(kg: 60, rip: 8, fatta: true)
        r.rip = nil
        let toltar = r.togliSpuntaSeIncompleta()
        #expect(toltar)
        #expect(!r.fatta)
        var zero = SerieFatta(kg: 60, rip: 0, fatta: true)
        let toltazero = zero.togliSpuntaSeIncompleta()
        #expect(toltazero)
        #expect(!zero.fatta)
        // completa: resta fatta; non fatta: non cambia niente
        var ok = SerieFatta(kg: 0, rip: 8, fatta: true)
        let toltaok = ok.togliSpuntaSeIncompleta()
        #expect(!toltaok)
        #expect(ok.fatta)
        var vuota = SerieFatta()
        let toltavuota = vuota.togliSpuntaSeIncompleta()
        #expect(!toltavuota)
    }

    // 4. Con solo riscaldamenti spuntati, «Fine» propone di salvare
    @Test func soloRiscaldamentoSiSalva() {
        let a = Allenamento(nome: "Push", esercizi: [
            EsercizioFatto(esercizio: "panca", serie: [SerieFatta(kg: 40, rip: 10, fatta: true, riscaldamento: true),
                                                     SerieFatta(kg: 60, rip: 8)])])
        #expect(a.serieFatte == 0)       // quelle che contano per volume e record
        #expect(a.serieSpuntate == 1)    // quelle che si salvano
        #expect(a.serieNonSpuntate == 1)
    }

    // 5. Live Activity: stessa numerazione dell'app (il riscaldamento è «R», le serie di lavoro partono da 1)
    @Test func numeroSerieLiveConRiscaldamento() throws {
        let r = SerieFatta(kg: 20, rip: 10, fatta: true, riscaldamento: true)
        let lavoro = SerieFatta(kg: 60, rip: 8)
        let a = riscaldato(Allenamento(nome: "Push", esercizi: [
            EsercizioFatto(esercizio: "panca", serie: [r, lavoro, SerieFatta(), SerieFatta()])]))
        let live = try #require(StatoAllenamentoLive.da(allenamento: a, ultimaSerie: r.id, recupero: nil, libreria: libreria))
        #expect(live.idSerie == lavoro.id)
        #expect(live.serie == 1)          // nell'app è «1»
        #expect(live.totaleSerie == 3)    // tre serie di lavoro
    }

    @Test func numeroSerieLiveDelRiscaldamento() throws {
        let r1 = SerieFatta(kg: 20, rip: 10, fatta: true, riscaldamento: true), r2 = SerieFatta(kg: 30, rip: 8, riscaldamento: true)
        let a = riscaldato(Allenamento(nome: "Push", esercizi: [
            EsercizioFatto(esercizio: "panca", serie: [r1, r2, SerieFatta(kg: 60, rip: 8)])]))
        let live = try #require(StatoAllenamentoLive.da(allenamento: a, ultimaSerie: r1.id, recupero: nil, libreria: libreria))
        #expect(live.idSerie == r2.id)
        #expect(live.riscaldamento)
        #expect(live.serie == 2)          // secondo riscaldamento
        #expect(live.totaleSerie == 2)
    }

    // 6. Corpo libero: un record sulle ripetizioni
    @Test func recordRipetizioniACorpoLibero() {
        func trazioni(_ giorno: Double, _ rip: Int) -> Allenamento {
            Allenamento(nome: "Tira", inizio: Date(timeIntervalSinceReferenceDate: 800_000_000 + giorno * 86400), esercizi: [
                EsercizioFatto(esercizio: "trazioni", serie: [SerieFatta(kg: 0, rip: rip, fatta: true)])])
        }
        let prima = trazioni(0, 10), meglio = trazioni(1, 15), uguale = trazioni(2, 15)
        var s = StatoPalestra()
        s.esercizi = libreria
        s.allenamenti = [prima, meglio, uguale]
        let p = Palestra(stato: s)
        #expect(p.nuoviRecord(prima).isEmpty)
        #expect(p.nuoviRecord(meglio).count == 1)
        #expect(p.nuoviRecord(uguale).isEmpty)
        let conteggio = s.conteggioRecord()
        #expect(conteggio[prima.id] == 0)
        #expect(conteggio[meglio.id] == 1)
        #expect(conteggio[uguale.id] == 0)
    }

    // 7. «Questa settimana» ha una sola definizione: pesi più cardio
    @Test func settimanaUnaSolaDefinizione() {
        var s = StatoPalestra()
        let lunedi = "2026-11-02"
        s.allenamenti = [Allenamento(nome: "Pesi", inizio: Giorni.data(lunedi).addingTimeInterval(3600)),
                         Allenamento(nome: "Pesi", inizio: Giorni.data("2026-11-04").addingTimeInterval(3600))]
        s.cardio = [SessioneCardio(data: "2026-11-03", tipo: "Corsa", minuti: 30, km: 4),
                    SessioneCardio(data: "2026-10-30", tipo: "Corsa", minuti: 30, km: 4)]   // settimana prima
        let r = s.riepilogoSettimana(oggi: "2026-11-05")
        #expect(r.allenamenti == 3)
        #expect(r.kg == 0)
    }

    // 8. Piano di meno di 7 giorni (backup modificato): si completa a 7 giorni e si aggiunge la settimana mancante
    @Test func pianoCortoSiCompleta() throws {
        let json = #"{"piani":{"A":["pesi","riposo","cardio","riposo","pesi"]}}"#
        let s = try JSONDecoder().decode(StatoPalestra.self, from: Data(json.utf8))
        #expect(s.piani["A"]?.count == 7)
        #expect(s.piani["A"]?[0] == .pesi)
        #expect(s.piani["A"]?[4] == .pesi)
        #expect(s.piani["A"]?[5] == .riposo)
        #expect(s.piani["A"]?[6] == .riposo)
        #expect(s.piani["B"]?.count == 7)
    }

    @Test func pianoLungoSiTaglia() throws {
        let giorni = Array(repeating: "pesi", count: 9).map { "\"\($0)\"" }.joined(separator: ",")
        let s = try JSONDecoder().decode(StatoPalestra.self, from: Data(#"{"piani":{"A":[\#(giorni)],"B":[]}}"#.utf8))
        #expect(s.piani["A"]?.count == 7)
        #expect(s.piani["B"]?.count == 7)
    }
}
