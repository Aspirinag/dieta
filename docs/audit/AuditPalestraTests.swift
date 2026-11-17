import Foundation
import Testing
@testable import Forma

// Test temporanei della revisione: ognuno PASSA se il comportamento sospetto c'è davvero
@MainActor
struct AuditPalestraTests {
    let libreria = [
        Esercizio(id: "panca", nome: "Panca piana", muscolo: .petto, attrezzo: .bilanciere),
        Esercizio(id: "squat", nome: "Squat", muscolo: .quadricipiti, attrezzo: .bilanciere),
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

    // 1. Una serie di riscaldamento vuota, spuntata, prende kg e ripetizioni della prima serie di LAVORO dell'ultima volta
    @Test func riscaldamentoPrendeIKgDiLavoro() {
        let storico = Allenamento(nome: "Prima", inizio: Date().addingTimeInterval(-86400), esercizi: [
            EsercizioFatto(esercizio: "squat", serie: [SerieFatta(kg: 40, rip: 10, fatta: true, riscaldamento: true),
                                                     SerieFatta(kg: 100, rip: 5, fatta: true)])])
        let caldo = SerieFatta(riscaldamento: true)
        let (p, timer) = palestra(inCorso: riscaldato(Allenamento(nome: "Oggi", esercizi: [
            EsercizioFatto(esercizio: "squat", serie: [caldo, SerieFatta()])])), storico: [storico])
        p.segnaDaLive(caldo.id, timer: timer)
        #expect(p.stato.inCorso?.esercizi[0].serie[0].kg == 100)
        #expect(p.stato.inCorso?.esercizi[0].serie[0].rip == 5)
        timer.ferma()
    }

    // 2. Una sessione del Watch di oggi si aggancia a un allenamento rimasto aperto da due giorni
    @Test func watchAgganciatoAUnAllenamentoVecchio() {
        let vecchio = Allenamento(nome: "Push", inizio: Date().addingTimeInterval(-2 * 86400))
        let (p, _) = palestra(inCorso: vecchio)
        let w = AllenamentoWatch(uuid: "W1", genere: .palestra, inizio: Date().addingTimeInterval(-3600),
                                 fine: Date().addingTimeInterval(-60), calorie: 300, battito: 120, km: 0)
        guard case .agganciato = p.registraDalWatch(w) else { Issue.record("non agganciato"); return }
        #expect(p.stato.inCorso?.watch?.uuid == "W1")
        #expect(p.stato.allenamenti.isEmpty)
    }

    // 3. «Annullalo e inizia il nuovo» chiama solo inizia: la sessione del Watch agganciata va persa
    //    (annulla() invece la terrebbe)
    @Test func iniziaSopraUnAllenamentoConWatchLoPerde() {
        var a = Allenamento(nome: "Push", inizio: Date().addingTimeInterval(-1800))
        a.watch = DatiWatch(uuid: "W2", calorie: 200, battito: 110)
        let (p, _) = palestra(inCorso: a)
        p.inizia(nil)
        #expect(p.stato.allenamenti.isEmpty)
        #expect(p.stato.inCorso?.watch == nil)
        // confronto: annulla la terrebbe
        let (q, _) = palestra(inCorso: a)
        q.annulla()
        #expect(q.stato.allenamenti.count == 1)
    }

    // 4. Allenamento lasciato aperto e finito il giorno dopo: durata di oltre 24 ore, conta nella settimana
    @Test func allenamentoFinitoIlGiornoDopo() throws {
        let a = Allenamento(nome: "Push", inizio: Date().addingTimeInterval(-26 * 3600), esercizi: [
            EsercizioFatto(esercizio: "panca", serie: [SerieFatta(kg: 60, rip: 8, fatta: true)])])
        let (p, _) = palestra(inCorso: a)
        let salvato = try #require(p.termina())
        #expect(salvato.durata > 24 * 3600)
    }

    // 5. Piano settimanale con meno di 7 giorni (backup modificato/vecchio): si decodifica così com'è,
    //    e PianoSettimanaleView legge piani[w]?[i] per i in 0..<7 senza controllo → indice fuori dai limiti
    @Test func pianoCortoSiDecodifica() throws {
        let json = #"{"piani":{"A":["pesi","riposo","cardio","riposo","pesi"]}}"#
        let s = try JSONDecoder().decode(StatoPalestra.self, from: Data(json.utf8))
        #expect(s.piani["A"]?.count == 5)
        #expect(s.piani["B"] == nil)
    }

    // 6. Senza riferimento (vista appena aperta) la serie attiva è diversa da quella calcolata con l'ultima serie salvata
    @Test func serieAttivaIgnoraUltimaSerieAllApertura() {
        let a1 = SerieFatta(kg: 60, rip: 8)
        let b1 = SerieFatta(kg: 80, rip: 5, fatta: true), b2 = SerieFatta(kg: 80, rip: 5)
        let es = [EsercizioFatto(esercizio: "panca", serie: [a1]), EsercizioFatto(esercizio: "squat", serie: [b1, b2])]
        #expect(SerieAttiva.trova(in: es, riferimento: nil) == a1.id)
        #expect(SerieAttiva.trova(in: es, riferimento: b1.id) == b2.id)
    }

    // 7. Serie spuntata e poi svuotata nei kg: resta salvata come fatta ma non conta (volume 0, «0 kg × 8» nello storico);
    //    svuotata nelle ripetizioni: sparisce senza avviso
    @Test func serieFattaSvuotata() throws {
        let a = Allenamento(nome: "Push", esercizi: [
            EsercizioFatto(esercizio: "panca", serie: [SerieFatta(kg: 60, rip: 8, fatta: true),
                                                     SerieFatta(kg: nil, rip: 8, fatta: true),
                                                     SerieFatta(kg: 60, rip: nil, fatta: true)])])
        let (p, _) = palestra(inCorso: a)
        let salvato = try #require(p.termina())
        #expect(salvato.esercizi[0].serie.count == 2)
        #expect(salvato.serieFatte == 1)
    }

    // 8. Solo serie di riscaldamento spuntate: serieFatte = 0, «Fine» propone di chiudere senza salvare
    @Test func soloRiscaldamentoContaZero() {
        let a = Allenamento(nome: "Push", esercizi: [
            EsercizioFatto(esercizio: "panca", serie: [SerieFatta(kg: 40, rip: 10, fatta: true, riscaldamento: true)])])
        #expect(a.serieFatte == 0)
    }

    // 9. Live Activity: la prima serie di lavoro dopo un riscaldamento è «Serie 2 di 4»; nell'app è «1»
    @Test func numeroSerieLiveConRiscaldamento() throws {
        let r = SerieFatta(kg: 20, rip: 10, fatta: true, riscaldamento: true)
        let a = riscaldato(Allenamento(nome: "Push", esercizi: [
            EsercizioFatto(esercizio: "panca", serie: [r, SerieFatta(kg: 60, rip: 8), SerieFatta(), SerieFatta()])]))
        let live = try #require(StatoAllenamentoLive.da(allenamento: a, ultimaSerie: r.id, recupero: nil, libreria: libreria))
        #expect(live.serie == 2)
        #expect(live.totaleSerie == 4)
    }
}
