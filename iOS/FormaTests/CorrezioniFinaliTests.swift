import Foundation
import Testing
@testable import Forma

// Correzioni dopo la revisione finale
@MainActor
struct CorrezioniFinaliTests {
    // Dieta: dopo il cambio di settimana non resta scelto un giorno della settimana passata
    @Test func giornoVecchioDopoCambioSettimanaTornaAOggi() {
        // venerdì 6 novembre scelto, l'app si riapre lunedì 9
        #expect(Giorni.giornoScelto("2026-11-06", ultimoOggi: "2026-11-04", oggi: "2026-11-09") == "2026-11-09")
        // il vecchio «oggi» segue il nuovo oggi
        #expect(Giorni.giornoScelto("2026-11-04", ultimoOggi: "2026-11-04", oggi: "2026-11-05") == "2026-11-05")
        // un giorno scelto nella stessa settimana resta
        #expect(Giorni.giornoScelto("2026-11-06", ultimoOggi: "2026-11-04", oggi: "2026-11-05") == "2026-11-06")
        // un giorno di una settimana passata, senza cambio di giorno, torna a oggi
        #expect(Giorni.giornoScelto("2026-10-30", ultimoOggi: "2026-11-04", oggi: "2026-11-04") == "2026-11-04")
    }

    // Palestra: la sintesi conta gli allenamenti, non i giorni
    @Test func settimanaContaGliAllenamentiNonIGiorni() {
        var s = StatoPalestra()
        let lunedi = "2026-11-02"
        let pesi = Allenamento(nome: "Pesi", inizio: Giorni.data(lunedi).addingTimeInterval(3600))
        s.allenamenti = [pesi]
        s.cardio = [SessioneCardio(data: lunedi, tipo: "Corsa", minuti: 30, km: 4),
                    SessioneCardio(data: "2026-11-04", tipo: "Bici", minuti: 30, km: 10)]
        s.cardio.append(SessioneCardio(data: "2026-10-30", tipo: "Corsa", minuti: 30, km: 4))   // settimana prima
        #expect(s.allenamentiSettimana("2026-11-05") == 3)
        #expect(s.giorniAllenati(settimanaDi: "2026-11-05") == [0, 2])
    }

    // Testi che rimandano alla pagina dei piani: ora sta in Impostazioni → Piani alimentari
    @Test func spesaVuotaRimandaAImpostazioni() {
        let t = SpesaView.indicazioneVuoto
        #expect(t.contains("Impostazioni → Piani alimentari"))
        #expect(!t.contains("Piani e misure"))
    }

    @Test func pdfNonLeggibileRimandaAImpostazioni() {
        guard case .errore(let t) = ImportaPDF.valuta(.schema, giorni: [], misura: nil) else {
            Issue.record("Doveva essere un errore"); return
        }
        #expect(t.contains("Impostazioni → Piani alimentari"))
        #expect(!t.contains("Piani e misure"))
    }
}

// Un test dell'interfaccia che dipende dal giorno della settimana fallisce un giorno su sette (di lunedì il
// primo giorno che non è «oggi» è nel futuro e il suo cerchio è spento). Con `-demo -oggi AAAA-MM-GG` la data è fissa
@MainActor
struct OggiFissatoTests {
    @Test func nelleProveDemoOggiSiPuoFissare() {
        // domenica 8 novembre 2026: la striscia va da lunedì 2 a domenica 8, oggi è l'ultimo giorno
        let oggi = Giorni.oggi(argomenti: ["-demo", "-oggi", "2026-11-08"])
        #expect(oggi == "2026-11-08")
        #expect(Giorni.indice(oggi) == 6)
        #expect(Giorni.lunedi(oggi) == "2026-11-02")
    }

    @Test func senzaDemoOSenzaDataValidaOggiEQuelloVero() {
        let vero = Giorni.iso(Date())
        #expect(Giorni.oggi(argomenti: ["-oggi", "2026-11-08"]) == vero)
        #expect(Giorni.oggi(argomenti: ["-demo", "-oggi", "domani"]) == vero)
        #expect(Giorni.oggi(argomenti: ["-demo", "-oggi", "2026-13-40"]) == vero)
        #expect(Giorni.oggi(argomenti: ["-demo"]) == vero)
    }

    // Di domenica i giorni passati sono sei e il cerchio resta attivo; di lunedì non ce n'è nessuno
    @Test func giorniPassatiDellaSettimana() {
        func passati(_ oggi: String) -> Int { (0..<7).filter { Giorni.aggiungi(Giorni.lunedi(oggi), $0) < oggi }.count }
        #expect(passati("2026-11-08") == 6)
        #expect(passati("2026-11-09") == 0)
    }
}
