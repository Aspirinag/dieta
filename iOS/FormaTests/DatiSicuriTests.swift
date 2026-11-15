import Foundation
import Testing
import WebKit
@testable import Forma

// I dati non devono mai andare persi né bloccarsi
@MainActor
struct DatiSicuriTests {
    private func cartella() throws -> URL {
        let u = FileManager.default.temporaryDirectory.appending(path: "datisicuri-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    // 1. Numeri non finiti
    @Test func numeriNonFinitiSiRifiutano() {
        for t in ["nan", "NaN", "inf", "-inf", "infinity", "1e999", "-1e999", "1e5", "0x10"] {
            #expect(leggiNumero(t) == nil, "\(t) deve essere rifiutato")
        }
    }

    @Test func numeriNormaliSiLeggonoSempre() {
        #expect(leggiNumero("72,5") == 72.5)
        #expect(leggiNumero(" 72.5 ") == 72.5)
        #expect(leggiNumero("-3") == -3)
        #expect(leggiNumero("٧٢٫٥") == 72.5)
        #expect(leggiNumero("") == nil)
    }

    // 2. Mai scrivere un file vuoto sopra i dati
    @Test func statoConNaNNonProduceUnBackupVuoto() {
        var s = Stato.iniziale
        var m = Misura(data: "2026-11-10")
        m.peso = .nan
        s.profili["io"]?.bia = [m]
        let archivio = Archivio(stato: s)
        #expect(throws: (any Error).self) { try archivio.backup() }
    }

    @Test func backupNormaleSiCodifica() throws {
        let archivio = Archivio(stato: .iniziale)
        let dati = try archivio.backup()
        #expect(!dati.isEmpty)
        #expect((try? JSONDecoder().decode(Stato.self, from: dati)) == Stato.iniziale)
    }

    @Test func scritturaVuotaNonToccaIlFile() throws {
        let u = try cartella().appending(path: "dieta.json")
        let originale = Data(#"{"n":1}"#.utf8)
        try originale.write(to: u)
        #expect(throws: (any Error).self) { try FileDati.scrivi(Data(), su: u) }
        #expect(try Data(contentsOf: u) == originale)
        try FileDati.scrivi(Data(#"{"n":2}"#.utf8), su: u)
        #expect(try Data(contentsOf: u) == Data(#"{"n":2}"#.utf8))
    }

    @Test func fileVuotoNonDaUnaCopiaVuota() throws {
        let c = try cartella()
        let u = c.appending(path: "dieta.json")
        try Data().write(to: u)
        if case .illeggibile = FileDati.leggi(u, come: Stato.self) { Issue.record("nessuna copia per un file vuoto") }
        #expect(FileDati.copie(in: c).isEmpty)
    }

    @Test func palestraConNaNNonScriveVuoto() throws {
        var s = StatoPalestra()
        s.cardio = [SessioneCardio(data: "2026-11-10", tipo: "corsa", minuti: 30, km: .nan)]
        #expect(throws: (any Error).self) { _ = try Palestra(stato: s).datiDaSalvare() }
        #expect(!(try Palestra(stato: StatoPalestra()).datiDaSalvare().isEmpty))
    }

    // 3. Lettore PDF
    @Test func lettorePdfSiRicreaDopoUnErrore() async {
        let l = LettorePDF()
        let prova = Task { await l.prepara() }
        while !l.haPagina { await Task.yield() }
        l.webView(WKWebView(), didFailProvisionalNavigation: nil, withError: CocoaError(.fileReadUnknown))
        await prova.value
        #expect(!l.haPagina)
        // Il tentativo successivo ricrea la pagina invece di restare in attesa
        let seconda = Task { await l.prepara() }
        while !l.haPagina { await Task.yield() }
        l.reimposta()
        await seconda.value
    }

    @Test func lettorePdfSiRicreaSeIosChiudeLaPagina() async {
        let l = LettorePDF()
        let prova = Task { await l.prepara() }
        while !l.haPagina { await Task.yield() }
        l.webView(WKWebView(), didFinish: nil)
        await prova.value
        #expect(l.haPagina)
        l.webViewWebContentProcessDidTerminate(WKWebView())
        #expect(!l.haPagina)
    }

    // 4. Promemoria con dati non leggibili
    @Test func promemoriaNonSiToccanoConDatiBloccati() {
        #expect(!Archivio.promemoriaProgrammabili(demo: false, bloccato: true))
        #expect(Archivio.promemoriaProgrammabili(demo: false, bloccato: false))
        #expect(!Archivio.promemoriaProgrammabili(demo: true, bloccato: false))
    }
}
