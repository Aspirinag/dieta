import XCTest
@testable import Dieta

final class AllenamentoTests: XCTestCase {
    private func serie(_ kg: Double, _ rip: Int = 8, _ tipo: TipoSerie = .normale) -> SerieFatta {
        SerieFatta(tipo: tipo, kg: kg, ripetizioni: rip, fatta: true)
    }

    private func allenamento(_ id: String, _ inizio: String, _ nome: String, _ s: [SerieFatta]) -> Allenamento {
        Allenamento(id: id, inizio: inizio, fine: inizio, esercizi: [EsercizioFatto(nome: nome, serie: s)])
    }

    private func rilettura(_ p: Profilo) throws -> Profilo {
        try JSONDecoder().decode(Profilo.self, from: JSONEncoder().encode(p))
    }

    func testVecchioFileSiLeggeSenzaAllenamenti() throws {
        let json = Data(#"{"profili":{"a":{"nome":"Anna","note":"allergia","olio_tot":3,"pesate":{"2026-01-01":60.5}}},"attivo":"a"}"#.utf8)
        let p = try JSONDecoder().decode(Stato.self, from: json).profili["a"]!
        XCTAssertEqual(p.nome, "Anna")
        XCTAssertEqual(p.note, "allergia")
        XCTAssertEqual(p.olioTot, 3)
        XCTAssertEqual(p.pesate["2026-01-01"], 60.5)
        XCTAssertTrue(p.allenamenti.isEmpty)
        XCTAssertTrue(p.routine.isEmpty)
        XCTAssertTrue(p.cardio.isEmpty)
        XCTAssertTrue(p.pagamenti.isEmpty)
        XCTAssertTrue(p.calendario.isEmpty)
        XCTAssertTrue(p.spunte.isEmpty)
        XCTAssertTrue(p.noteEsercizi.isEmpty)
        XCTAssertEqual(p.modoCardio, "")
        XCTAssertNil(p.allenamentoInCorso)
    }

    func testAllenamentoSiSalvaESiRilegge() throws {
        var p = Profilo(nome: "Anna")
        p.note = "nota del profilo"
        p.allenamenti = [Allenamento(id: "1", inizio: "2026-10-01T10:00:00", fine: "2026-10-01T11:00:00", routine: "A",
                                     esercizi: [EsercizioFatto(nome: "Panca", serie: [serie(60, 5), serie(20, 10, .riscaldamento), serie(50, 12, .cedimento)])])]
        p.cardio = [SessioneCardio(data: "2026-10-02", tipo: "Tapis", minuti: 30, km: 4.5)]
        p.pagamenti = ["2026-10": "2026-10-03"]
        p.calendario = ["2026-10-01": "pesi"]
        p.spunte = ["2026-10-01": ["riscaldamento": true, "defaticamento": false]]
        p.modoCardio = "km"
        p.allenamentoInCorso = Allenamento(id: "2", inizio: "2026-10-05T09:00:00")
        p.noteEsercizi = ["Panca": "sedile 3"]

        // Salvataggio vero, con Archivio
        let cartella = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: cartella) }
        let file = cartella.appending(path: "dieta.json"), copie = cartella.appending(path: "copie")
        let a = Archivio(file: file, copie: copie)
        a.creaPrimoProfilo("Prova")
        a.stato.profili[a.stato.attivo] = p
        a.salvaSubito()
        let letto = Archivio(file: file, copie: copie).profilo

        XCTAssertEqual(letto, p)
        XCTAssertEqual(letto.note, "nota del profilo")
        XCTAssertEqual(letto.allenamenti[0].esercizi[0].serie[2].tipo, .cedimento)
        XCTAssertEqual(try rilettura(p), p)
    }

    func testPrecedenteEscludeLAllenamentoInCorso() {
        var p = Profilo(nome: "x")
        p.allenamenti = [allenamento("1", "2026-10-01T10:00:00", "Panca", [serie(50)]),
                         allenamento("2", "2026-10-08T10:00:00", "Panca", [serie(70)])]
        XCTAssertEqual(p.precedente("Panca").map(\.kg), [70])

        // Il secondo è quello in corso (salvato serie per serie): non conta
        p.allenamentoInCorso = p.allenamenti[1]
        XCTAssertEqual(p.precedente("Panca").map(\.kg), [50])
        XCTAssertEqual(p.massimo("Panca"), 50)
        XCTAssertEqual(p.precedente("Squat"), [])
    }

    func testIlRiscaldamentoNonFaRecord() {
        var p = Profilo(nome: "x")
        p.allenamenti = [allenamento("1", "2026-10-01T10:00:00", "Panca", [serie(100, 3, .riscaldamento), serie(60), serie(40, 8, .cedimento)])]
        XCTAssertEqual(p.massimo("Panca"), 60)
        XCTAssertEqual(p.precedente("Panca").map(\.kg), [60, 40])

        p.allenamenti = [allenamento("1", "2026-10-01T10:00:00", "Panca", [serie(100, 3, .riscaldamento)])]
        XCTAssertNil(p.massimo("Panca"))
        XCTAssertEqual(p.precedente("Panca"), [])
    }

    func testRoutineConSerieERecupero() throws {
        var p = Profilo(nome: "x")
        p.routine = [Routine(nome: "A", esercizi: [EsercizioPrevisto(nome: "Panca", serie: 4, recupero: 120)], giorni: [1, 4])]
        let r = try rilettura(p).routine[0]
        XCTAssertEqual(r.nome, "A")
        XCTAssertEqual(r.esercizi[0].serie, 4)
        XCTAssertEqual(r.esercizi[0].recupero, 120)
        XCTAssertEqual(r.giorni, [1, 4])

        let incompleta = try JSONDecoder().decode(Routine.self, from: Data(#"{"nome":"B","esercizi":[{"nome":"Squat"}]}"#.utf8))
        XCTAssertEqual(incompleta.esercizi[0].serie, 3)
        XCTAssertEqual(incompleta.esercizi[0].recupero, 90)
        XCTAssertEqual(incompleta.giorni, [])
    }

    func testEserciziUsatiSenzaDoppioni() {
        var p = Profilo(nome: "x")
        p.routine = [Routine(nome: "A", esercizi: [EsercizioPrevisto(nome: "Panca"), EsercizioPrevisto(nome: "Squat")])]
        p.allenamenti = [allenamento("1", "2026-10-01T10:00:00", "Panca", [serie(50)]),
                         allenamento("2", "2026-10-02T10:00:00", "Alzate", [serie(5)])]
        p.allenamentoInCorso = allenamento("3", "2026-10-03T10:00:00", "Squat", [])
        XCTAssertEqual(p.eserciziUsati(), ["Alzate", "Panca", "Squat"])
    }

    func testRinominaAggiornaRoutineAllenamentiENote() {
        var p = Profilo(nome: "x")
        p.routine = [Routine(nome: "A", esercizi: [EsercizioPrevisto(nome: "Panca")])]
        p.allenamenti = [allenamento("1", "2026-10-01T10:00:00", "Panca", [serie(50)])]
        p.allenamentoInCorso = allenamento("2", "2026-10-02T10:00:00", "Panca", [])
        p.noteEsercizi = ["Panca": "sedile 3"]

        p.rinomina(esercizio: "Panca", in: "Panca piana")

        XCTAssertEqual(p.routine[0].esercizi[0].nome, "Panca piana")
        XCTAssertEqual(p.allenamenti[0].esercizi[0].nome, "Panca piana")
        XCTAssertEqual(p.allenamentoInCorso?.esercizi[0].nome, "Panca piana")
        XCTAssertEqual(p.noteEsercizi, ["Panca piana": "sedile 3"])
        XCTAssertEqual(p.eserciziUsati(), ["Panca piana"])
    }

    func testUnireDueEserciziUnisceRecordEPrecedenti() {
        var p = Profilo(nome: "x")
        p.allenamenti = [allenamento("1", "2026-10-01T10:00:00", "Panca", [serie(80)]),
                         allenamento("2", "2026-10-08T10:00:00", "Panca piana", [serie(60)]),
                         Allenamento(id: "3", inizio: "2026-10-09T10:00:00", fine: "2026-10-09T11:00:00",
                                     esercizi: [EsercizioFatto(nome: "Panca", serie: [serie(55)]),
                                                EsercizioFatto(nome: "Panca piana", serie: [serie(50)])])]
        p.noteEsercizi = ["Panca": "vecchia", "Panca piana": "nuova"]

        p.rinomina(esercizio: "Panca", in: "Panca piana")

        XCTAssertEqual(p.massimo("Panca piana"), 80)
        XCTAssertNil(p.massimo("Panca"))
        XCTAssertEqual(p.precedente("Panca piana").map(\.kg), [55, 50])
        XCTAssertEqual(p.allenamenti[2].esercizi.count, 1)
        XCTAssertEqual(p.noteEsercizi, ["Panca piana": "nuova"])
        XCTAssertEqual(p.eserciziUsati(), ["Panca piana"])
    }
}
