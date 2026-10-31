import XCTest
@testable import Dieta

final class InCorsoTests: XCTestCase {
    private var cartella: URL!
    private var file: URL { cartella.appending(path: "dieta.json") }
    private var copie: URL { cartella.appending(path: "copie") }

    override func setUpWithError() throws {
        cartella = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: cartella)
    }

    private func archivio() -> Archivio {
        let a = Archivio(file: file, copie: copie)
        if a.senzaProfili { a.creaPrimoProfilo("Prova") }
        return a
    }

    private let routine = Routine(nome: "A", esercizi: [EsercizioPrevisto(nome: "Panca", serie: 3, recupero: 120),
                                                         EsercizioPrevisto(nome: "Squat", serie: 2, recupero: 90)])

    private func data(_ g: Int, _ h: Int, _ m: Int) -> Date {
        Giorni.calendario.date(from: DateComponents(year: 2026, month: 10, day: g, hour: h, minute: m))!
    }

    private func precedente(_ a: Archivio, _ kg: Double, nome: String = "Panca") {
        a.profilo.allenamenti.append(Allenamento(id: "old", inizio: "2026-10-01T10:00:00", fine: "2026-10-01T11:00:00",
                                                 esercizi: [EsercizioFatto(nome: nome, serie: [SerieFatta(kg: kg, ripetizioni: 8)])]))
    }

    func testSpuntaSalvaSubito() {
        let a = archivio()
        a.iniziaAllenamento(routine)
        XCTAssertTrue(a.spuntaSerie(esercizio: 0, serie: 0, kg: "60", ripetizioni: "8"))
        // Nessuna attesa: il file è già scritto
        let letto = Archivio(file: file, copie: copie).profilo.allenamentoInCorso
        XCTAssertEqual(letto?.esercizi[0].serie[0], SerieFatta(kg: 60, ripetizioni: 8, fatta: true))
        XCTAssertEqual(letto?.esercizi[0].serie.count, 3)
        XCTAssertEqual(letto?.esercizi[1].serie.count, 2)
    }

    func testAllenamentoRiprendeDopoIlRiavvio() {
        let a = archivio()
        a.iniziaAllenamento(routine)
        a.spuntaSerie(esercizio: 1, serie: 0, kg: "100", ripetizioni: "5")
        let b = Archivio(file: file, copie: copie)
        XCTAssertEqual(b.profilo.allenamentoInCorso, a.profilo.allenamentoInCorso)
        XCTAssertEqual(b.profilo.allenamentoInCorso?.routine, "A")
        XCTAssertTrue(b.profilo.allenamenti.isEmpty)
        // Un secondo «inizia» non cancella quello in corso
        b.iniziaAllenamento(nil)
        XCTAssertEqual(b.profilo.allenamentoInCorso, a.profilo.allenamentoInCorso)
    }

    func testDopoMezzanotteRestaIlGiornoDiInizio() {
        let a = archivio()
        a.iniziaAllenamento(routine, adesso: data(30, 23, 50))
        a.spuntaSerie(esercizio: 0, serie: 0, kg: "60", ripetizioni: "8", adesso: data(31, 0, 5))
        XCTAssertEqual(a.profilo.allenamentoInCorso?.giorno, "2026-10-30")
        let r = a.terminaAllenamento(adesso: data(31, 0, 20))
        XCTAssertEqual(r.durata, 30 * 60, accuracy: 1)
        XCTAssertEqual(a.profilo.allenamenti.last?.giorno, "2026-10-30")
        XCTAssertEqual(a.profilo.allenamenti.last?.inizio, "2026-10-30T23:50:00")
        XCTAssertNil(a.profilo.allenamentoInCorso)
    }

    func testValoriNonValidiNonSiSalvano() throws {
        let a = archivio()
        a.iniziaAllenamento(routine)
        let prima = try Data(contentsOf: file)
        for (kg, rip) in [("", "8"), ("60", ""), ("0", "8"), ("60", "0"), ("-5", "8"), ("abc", "8"), ("nan", "8"),
                          ("inf", "8"), ("60", "8,5"), ("1e3", "8"), ("60", "x"), ("  ", "8"), ("5000", "8")] {
            XCTAssertFalse(a.spuntaSerie(esercizio: 0, serie: 0, kg: kg, ripetizioni: rip), "\(kg) × \(rip)")
        }
        XCTAssertFalse(a.profilo.allenamentoInCorso!.esercizi[0].serie[0].fatta)
        XCTAssertEqual(a.recupero.rimanenti(adesso: Date()), 0)
        XCTAssertNil(a.richiestaAnnulla)
        XCTAssertEqual(try Data(contentsOf: file), prima)
        // Indici fuori dall'allenamento
        XCTAssertFalse(a.spuntaSerie(esercizio: 9, serie: 0, kg: "60", ripetizioni: "8"))
        XCTAssertFalse(a.spuntaSerie(esercizio: 0, serie: 9, kg: "60", ripetizioni: "8"))
    }

    func testVirgolaAccettata() {
        let a = archivio()
        a.iniziaAllenamento(routine)
        XCTAssertTrue(a.spuntaSerie(esercizio: 0, serie: 0, kg: "62,5", ripetizioni: "8"))
        XCTAssertTrue(a.spuntaSerie(esercizio: 0, serie: 1, kg: " 62.5 ", ripetizioni: "8"))
        XCTAssertEqual(a.profilo.allenamentoInCorso?.esercizi[0].serie[0].kg, 62.5)
        XCTAssertEqual(a.profilo.allenamentoInCorso?.esercizi[0].serie[1].kg, 62.5)
    }

    func testRecordRilevato() {
        let a = archivio()
        precedente(a, 60)
        a.iniziaAllenamento(routine)
        a.spuntaSerie(esercizio: 0, serie: 0, kg: "60", ripetizioni: "8")     // pari: non è record
        a.spuntaSerie(esercizio: 0, serie: 1, kg: "62,5", ripetizioni: "5")
        a.spuntaSerie(esercizio: 1, serie: 0, kg: "100", ripetizioni: "5")    // Squat mai fatto: niente da battere
        let r = a.terminaAllenamento()
        XCTAssertEqual(r.record, ["Panca: 62,5 kg"])
    }

    func testRiepilogoCalcolaIlVolume() {
        let a = archivio()
        a.iniziaAllenamento(routine)
        a.cambiaTipo(esercizio: 0, serie: 0, .riscaldamento)
        a.spuntaSerie(esercizio: 0, serie: 0, kg: "20", ripetizioni: "10")    // riscaldamento: fuori da serie e volume
        a.spuntaSerie(esercizio: 0, serie: 1, kg: "60", ripetizioni: "10")
        a.spuntaSerie(esercizio: 1, serie: 0, kg: "50", ripetizioni: "8")
        let r = a.terminaAllenamento()
        XCTAssertEqual(r.serie, 2)
        XCTAssertEqual(r.volume, 1000, accuracy: 0.001)
        // Le serie non segnate non si salvano
        let salvato = a.profilo.allenamenti.last!
        XCTAssertEqual(salvato.esercizi.map(\.nome), ["Panca", "Squat"])
        XCTAssertEqual(salvato.esercizi[0].serie.count, 2)
        XCTAssertEqual(salvato.esercizi[1].serie.count, 1)
        XCTAssertFalse(salvato.fine.isEmpty)
    }

    func testAllenamentoSenzaSerieSegnateNonSiSalva() {
        let a = archivio()
        a.iniziaAllenamento(routine)
        let r = a.terminaAllenamento()
        XCTAssertEqual(r.serie, 0)
        XCTAssertTrue(a.profilo.allenamenti.isEmpty)
        XCTAssertNil(a.profilo.allenamentoInCorso)
    }

    func testAggiuntaETolturaDiSerieEdEsercizi() {
        let a = archivio()
        precedente(a, 60)
        a.iniziaAllenamento(routine)
        // I campi partono dai valori precedenti
        XCTAssertEqual(a.profilo.allenamentoInCorso?.esercizi[0].serie[2].kg, 60)
        XCTAssertEqual(a.profilo.allenamentoInCorso?.esercizi[0].serie[2].ripetizioni, 8)
        a.aggiungiSerie(esercizio: 0)
        XCTAssertEqual(a.profilo.allenamentoInCorso?.esercizi[0].serie.count, 4)
        XCTAssertFalse(a.profilo.allenamentoInCorso!.esercizi[0].serie[3].fatta)
        a.togliSerie(esercizio: 0, serie: 0)
        XCTAssertEqual(a.profilo.allenamentoInCorso?.esercizi[0].serie.count, 3)
        a.aggiungiEsercizio("  Curl ")
        XCTAssertEqual(a.profilo.allenamentoInCorso?.esercizi.last?.nome, "Curl")
        XCTAssertTrue(a.profilo.eserciziUsati().contains("Curl"))
        a.aggiungiEsercizio("   ")
        XCTAssertEqual(a.profilo.allenamentoInCorso?.esercizi.count, 3)
        a.togliEsercizio(0)
        XCTAssertEqual(a.profilo.allenamentoInCorso?.esercizi.map(\.nome), ["Squat", "Curl"])
        // Indici sbagliati non fanno niente e non si schianta
        a.togliSerie(esercizio: 7, serie: 0)
        a.togliEsercizio(7)
        a.aggiungiSerie(esercizio: 7)
        XCTAssertEqual(a.profilo.allenamentoInCorso?.esercizi.count, 2)
        // Salvato subito
        XCTAssertEqual(Archivio(file: file, copie: copie).profilo.allenamentoInCorso, a.profilo.allenamentoInCorso)
    }

    func testCambioTipoDiSerie() {
        let a = archivio()
        a.iniziaAllenamento(routine)
        a.cambiaTipo(esercizio: 0, serie: 1, .cedimento)
        a.cambiaTipo(esercizio: 0, serie: 0, .riscaldamento)
        XCTAssertEqual(a.profilo.allenamentoInCorso?.esercizi[0].serie.map(\.tipo), [.riscaldamento, .cedimento, .normale])
        a.cambiaTipo(esercizio: 5, serie: 0, .cedimento)
        XCTAssertEqual(Archivio(file: file, copie: copie).profilo.allenamentoInCorso?.esercizi[0].serie[1].tipo, .cedimento)
    }

    func testAvvisoQuandoSiSuperaIlMassimo() {
        let a = archivio()
        precedente(a, 60)
        a.iniziaAllenamento(routine)
        XCTAssertTrue(a.superaIlMassimo(esercizio: 0, kg: "62,5"))
        XCTAssertFalse(a.superaIlMassimo(esercizio: 0, kg: "60"))
        XCTAssertFalse(a.superaIlMassimo(esercizio: 0, kg: "abc"))
        XCTAssertFalse(a.superaIlMassimo(esercizio: 1, kg: "500"))   // Squat: nessun massimo precedente
        XCTAssertFalse(a.superaIlMassimo(esercizio: 9, kg: "500"))
        // Dopo aver segnato 62,5 lo stesso carico non avvisa di nuovo
        a.spuntaSerie(esercizio: 0, serie: 0, kg: "62,5", ripetizioni: "5")
        XCTAssertFalse(a.superaIlMassimo(esercizio: 0, kg: "62,5"))
        XCTAssertTrue(a.superaIlMassimo(esercizio: 0, kg: "65"))
    }

    func testAnnullaSpuntaRipristina() throws {
        let a = archivio()
        a.iniziaAllenamento(routine)
        let prima = a.profilo.allenamentoInCorso
        let fileprima = try Data(contentsOf: file)
        a.spuntaSerie(esercizio: 0, serie: 0, kg: "70", ripetizioni: "6")
        XCTAssertNotNil(a.richiestaAnnulla)
        XCTAssertTrue(a.annullaSpunta())
        XCTAssertEqual(a.profilo.allenamentoInCorso, prima)
        XCTAssertNil(a.richiestaAnnulla)
        XCTAssertEqual(try Data(contentsOf: file), fileprima)
        // Una sola volta
        XCTAssertFalse(a.annullaSpunta())
    }

    func testAnnullaUltimoPastoRipristina() throws {
        let a = archivio()
        a.salvaSubito()
        let prima = try Data(contentsOf: file)
        a.segnaMangiato("2026-10-31", 0)
        XCTAssertEqual(a.slot("2026-10-31", 0).fatto, true)
        XCTAssertNotNil(a.richiestaAnnulla)
        XCTAssertTrue(a.annullaUltimoPasto())
        XCTAssertNil(a.profilo.dieta["2026-10-31"])
        XCTAssertEqual(try Data(contentsOf: file), prima)

        // Con un pasto già in parte compilato torna com'era
        a.cambiaSlot("2026-10-31", 1) { $0.opt = 2; $0.altro = "pizza" }
        a.cambiaRegistro("2026-10-31") { $0.acqua = 0.5 }
        let registro = a.registro("2026-10-31")
        a.segnaMangiato("2026-10-31", 1, azzeraAltro: true)
        XCTAssertNil(a.slot("2026-10-31", 1).altro)
        a.aggiungiAcqua("2026-10-31")                                   // un altro tocco nel frattempo resta
        XCTAssertTrue(a.annullaUltimoPasto())
        XCTAssertEqual(a.slot("2026-10-31", 1), registro.slot["1"])
        XCTAssertEqual(a.registro("2026-10-31").acqua, 0.75)
    }

    func testRecuperoSiCalcolaDallOrarioDiFine() {
        let inizio = Date(timeIntervalSince1970: 1_000_000)
        var t = TimerRecupero()
        XCTAssertEqual(t.rimanenti(adesso: inizio), 0)
        t.avvia(90, adesso: inizio)
        XCTAssertEqual(t.rimanenti(adesso: inizio), 90)
        XCTAssertEqual(t.rimanenti(adesso: inizio.addingTimeInterval(30.4)), 60)   // arrotonda per eccesso
        XCTAssertEqual(t.rimanenti(adesso: inizio.addingTimeInterval(600)), 0)     // dopo un lungo secondo piano
        t.aggiungi(15)
        XCTAssertEqual(t.rimanenti(adesso: inizio.addingTimeInterval(30)), 75)
        t.aggiungi(-15)
        t.aggiungi(-15)
        XCTAssertEqual(t.rimanenti(adesso: inizio.addingTimeInterval(30)), 45)
        t.aggiungi(-600)
        XCTAssertEqual(t.rimanenti(adesso: inizio), 0)
        t.avvia(60, adesso: inizio)
        t.salta()
        XCTAssertEqual(t.rimanenti(adesso: inizio), 0)
        t.aggiungi(15)                                                           // fermo: non riparte
        XCTAssertEqual(t.rimanenti(adesso: inizio), 0)
    }

    func testRecuperoAnnullatoConLaSpunta() {
        let a = archivio()
        a.profilo.routine = [routine]   // il recupero previsto sta nella routine salvata
        a.iniziaAllenamento(routine)
        let adesso = Date()
        a.spuntaSerie(esercizio: 0, serie: 0, kg: "60", ripetizioni: "8", adesso: adesso)
        XCTAssertEqual(a.recupero.rimanenti(adesso: adesso), 120)   // quello previsto per Panca
        a.spuntaSerie(esercizio: 1, serie: 0, kg: "60", ripetizioni: "8", adesso: adesso)
        XCTAssertEqual(a.recupero.rimanenti(adesso: adesso), 90)
        a.annullaSpunta()
        XCTAssertEqual(a.recupero.rimanenti(adesso: adesso), 0)
    }
}
