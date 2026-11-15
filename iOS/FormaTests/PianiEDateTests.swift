import Foundation
import Testing
@testable import Forma

// Quale piano vale in un giorno e che giorno è «oggi»
@MainActor
struct PianiEDateTests {
    private func piano(_ nome: String, dal: String, al: String = "") -> Piano {
        let pasto = Pasto(nome: "Pranzo", opzioni: [Opzione(alimenti: [Alimento(nome: "Riso", quantita: "80 g")])])
        return Piano(nome: nome, dal: dal, al: al, giorni: Giorni.nomi.map { GiornoPiano(nome: $0, palestra: false, pasti: [pasto]) })
    }

    // Un piano a termine non chiude per sempre quello aperto: dopo la sua fine torna il precedente
    @Test func dopoLaFineDelPianoATermineTornaIlPrecedente() {
        var p = Profilo(nome: "Io")
        p.aggiungiPiano(piano("Vecchio", dal: "2026-01-01"))
        p.aggiungiPiano(piano("Marzo", dal: "2026-03-01", al: "2026-03-31"))
        #expect(p.piano(per: "2026-02-10")?.nome == "Vecchio")
        #expect(p.piano(per: "2026-03-15")?.nome == "Marzo")
        #expect(p.piano(per: "2026-04-10")?.nome == "Vecchio")
        #expect(p.piani.first { $0.nome == "Vecchio" }?.al == "")
    }

    // Un piano senza fine continua a chiudere quello aperto il giorno prima
    @Test func pianoSenzaFineChiudeIlPrecedente() {
        var p = Profilo(nome: "Io")
        p.aggiungiPiano(piano("Vecchio", dal: "2026-01-01"))
        p.aggiungiPiano(piano("Nuovo", dal: "2026-03-01"))
        #expect(p.piani.first { $0.nome == "Vecchio" }?.al == "2026-02-28")
    }

    // Eliminare un piano caricato per errore riapre quello che aveva chiuso
    @Test func eliminareIlPianoNuovoRiapreIlVecchio() {
        var p = Profilo(nome: "Io")
        p.aggiungiPiano(piano("Vecchio", dal: "2026-01-01"))
        let sbagliato = piano("Sbagliato", dal: "2026-11-01")
        p.aggiungiPiano(sbagliato)
        p.eliminaPiano(sbagliato)
        #expect(p.piano(per: "2026-11-10")?.nome == "Vecchio")
        #expect(p.piani.count == 1)
    }

    // Se il piano eliminato non aveva chiuso nessuno, gli altri non cambiano
    @Test func eliminareNonRiapreUnPianoChiusoAltrove() {
        var p = Profilo(nome: "Io")
        p.aggiungiPiano(piano("Vecchio", dal: "2026-01-01", al: "2026-06-30"))
        let altro = piano("Altro", dal: "2026-09-01")
        p.aggiungiPiano(altro)
        p.eliminaPiano(altro)
        #expect(p.piani.first?.al == "2026-06-30")
    }

    // Con la stessa data di inizio vince il primo, come nella web app (index.html, planFor)
    @Test func stessaDataDiInizioVinceIlPrimo() {
        var p = Profilo(nome: "Io")
        p.piani = [piano("Primo", dal: "2026-11-02"), piano("Secondo", dal: "2026-11-02")]
        #expect(p.piano(per: "2026-11-10")?.nome == "Primo")
    }

    // «Oggi» segue il fuso attuale anche se cambia con l'app aperta: il calendario non ne tiene una copia
    // fissata all'avvio, usa il fuso che si aggiorna da solo (da un test non si può cambiare il fuso di sistema)
    @Test func calendarioSegueIlFusoDiSistema() {
        #expect(String(describing: Giorni.calendario.timeZone).hasPrefix("autoupdating"))
        #expect(Giorni.calendario.timeZone == TimeZone.autoupdatingCurrent)
    }
}
