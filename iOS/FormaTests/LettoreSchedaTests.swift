import Foundation
import PDFKit
import Testing
@testable import Forma

// Lettura di una scheda di allenamento da PDF: schede, esercizi, recuperi e abbinamento alla libreria
@MainActor
struct LettoreSchedaTests {
    private final class Marcatore {}

    private func testoDelPDF() throws -> String {
        let url = try #require(Bundle(for: Marcatore.self).url(forResource: "SchedaAllenamentoForma", withExtension: "pdf"))
        let doc = try #require(PDFDocument(url: url))
        return try #require(doc.string)
    }

    private func leggi(_ testo: String) -> [SchedaLetta] {
        LettoreScheda.leggi(testo: testo, libreria: Libreria.predefiniti)
    }

    @Test func pdfDiEsempio() throws {
        let schede = leggi(try testoDelPDF())
        #expect(schede.count == 3)
        #expect(schede.map(\.nome) == ["Scheda A", "Scheda B", "Scheda C"])
        #expect(schede.allSatisfy { $0.voci.count == 5 })
        #expect(schede.flatMap(\.voci).allSatisfy { !$0.nuovo })

        let a = schede[0].voci
        #expect(a[0].esercizio.id == "Leg press")
        #expect(a[0].serie == 3 && a[0].ripMin == 8 && a[0].ripMax == 10 && a[0].recupero == 120)
        #expect(a[2].esercizio.id == "Lat machine")
        #expect(a[2].ripMin == 8 && a[2].ripMax == 12 && a[2].recupero == 90)
        #expect(a[3].esercizio.id == "Alzate laterali")
        #expect(a[4].esercizio.id == "Estensioni sopra la testa con manubrio")

        let b = schede[1].voci
        #expect(b[0].esercizio.id == "Leg curl seduto")
        #expect(b[0].serie == 3 && b[0].ripMin == 10 && b[0].ripMax == 12 && b[0].recupero == 75)
        #expect(b.map(\.esercizio.id) == ["Leg curl seduto", "Chest press", "Rematore alla macchina", "Hip thrust alla macchina", "Curl alla macchina"])

        let c = schede[2].voci
        #expect(c.map(\.esercizio.id) == ["Goblet squat", "Lat machine presa stretta", "Shoulder press", "Piegamenti", "Leg extension"])
        #expect(c[1].serie == 3 && c[1].ripMin == 8 && c[1].ripMax == 10 && c[1].recupero == 90)
        #expect(c[3].serie == 2 && c[3].ripMin == 10 && c[3].ripMax == 15 && c[3].recupero == 60)
    }

    @Test func formatiAlternativi() {
        let s = leggi("""
        Giorno 1
        Squat 3x10 90"
        Panca piana 4 x 8-10 1:30
        Plank 3×12 2 min
        Crunch 2 15 60s
        Curl con manubri 3 10
        Face pull 3 12-15 1'30" note varie
        """)
        #expect(s.count == 1)
        let v = s[0].voci
        #expect(v.count == 6)
        #expect(v[0].serie == 3 && v[0].ripMin == 10 && v[0].ripMax == 10 && v[0].recupero == 90)
        #expect(v[1].serie == 4 && v[1].ripMin == 8 && v[1].ripMax == 10 && v[1].recupero == 90)
        #expect(v[2].ripMin == 12 && v[2].ripMax == 12 && v[2].recupero == 120)
        #expect(v[3].recupero == 60)
        #expect(v[4].ripMin == 10 && v[4].ripMax == 10 && v[4].recupero == 90)   // senza recupero
        #expect(v[5].recupero == 90 && v[5].esercizio.id == "Face pull")
    }

    @Test func nomiDelleSchede() {
        let s = leggi("""
        Lunedì — Petto
        Squat 3x10
        Allenamento B
        Squat 3x10
        Giorno 3: Gambe
        Squat 3x10
        """)
        #expect(s.map(\.nome) == ["Lunedì", "Allenamento B", "Giorno 3: Gambe"])
    }

    @Test func nomeSconosciutoDiventaNuovo() {
        let s = leggi("""
        Scheda A
        Esercizio inventato 3 10 1'
        Squat 3 10
        Esercizio  Inventato 2 8
        """)
        let v = s[0].voci
        #expect(v.count == 3)
        #expect(v[0].nuovo)
        #expect(v[0].esercizio.nome == "Esercizio inventato")
        #expect(v[0].esercizio.muscolo == .altro && v[0].esercizio.attrezzo == .altro)
        #expect(!v[1].nuovo)
        #expect(v[2].esercizio.id == v[0].esercizio.id)   // stesso nome: stesso esercizio nuovo
    }

    @Test func abbinamentoIgnoraMaiuscoleAccentiESpazi() {
        let lib = [Esercizio(nome: "Pressa à gambe", muscolo: .quadricipiti, attrezzo: .macchina),
                   Esercizio(nome: "Pressa", muscolo: .quadricipiti, attrezzo: .macchina)]
        let s = LettoreScheda.leggi(testo: "Scheda A\nPRESSA  A GAMBE 3 10\nPressa orizzontale 3 10", libreria: lib)
        #expect(s[0].voci[0].esercizio.id == "Pressa à gambe")
        #expect(s[0].voci[1].esercizio.id == "Pressa")   // la più lunga che combacia
        #expect(!s[0].voci[1].nuovo)
    }

    @Test func nomeAndatoACapo() {
        let s = leggi("""
        Scheda A
        Leg press 3 8-10 2' Piedi larghi, scendi
        controllato
        Estensioni sopra la testa con
        manubrio 2 10-12 1'
        Lat machine 3 8-12 1'30"
        """)
        let v = s[0].voci
        #expect(v.count == 3)
        #expect(v[1].esercizio.id == "Estensioni sopra la testa con manubrio")
        #expect(v[1].serie == 2 && v[1].recupero == 60)
        #expect(v[2].esercizio.id == "Lat machine")
    }

    @Test func vinceLaCorrispondenzaPiuLunga() {
        let s = leggi("Scheda A\nLat machine presa stretta 3 8-10 1'30\"\nLat machine 3 8-12\nLat machine con maniglia 3 10")
        #expect(s[0].voci.map(\.esercizio.id) == ["Lat machine presa stretta", "Lat machine", "Lat machine"])
    }

    @Test func rigaDiContinuazioneConUnNomeNonCreaVoci() {
        let s = leggi("""
        Scheda C
        Piegamenti 2 10-15 1' Troppo duri? Mani su un rialzo:
        Piegamenti inclinati
        Leg extension 2 12-15 1'
        """)
        #expect(s[0].voci.map(\.esercizio.id) == ["Piegamenti", "Leg extension"])
    }

    @Test func nienteEsercizi() {
        #expect(leggi("Un paragrafo qualunque.\nScheda A\nSolo testo qui").isEmpty)
        #expect(leggi("").isEmpty)
    }

    @Test func importaAggiungeSenzaToccareLeEsistenti() {
        var stato = StatoPalestra()
        let prima = stato.routine
        let schede = leggi("Scheda A\nSquat 3x10\nEsercizio inventato 2 8 1'\nScheda A\nEsercizio inventato 3 10")
        stato.importa(schede)
        stato.importa(schede)
        #expect(Array(stato.routine.prefix(prima.count)) == prima)
        #expect(stato.routine.dropFirst(prima.count).map(\.nome) == ["Scheda A", "Scheda A (2)", "Scheda A (3)", "Scheda A (4)"])
        let nuovi = stato.esercizi.filter { $0.nome == "Esercizio inventato" }
        #expect(nuovi.count == 2)   // uno per importazione, ma uno solo per scheda doppia
        let ultima = stato.routine.last!
        #expect(stato.esercizi.contains { $0.id == ultima.voci[0].esercizio })
        #expect(stato.routine.dropFirst(prima.count).first!.voci[0].esercizio == "Squat")
    }
}
