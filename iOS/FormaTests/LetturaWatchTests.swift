import Foundation
import Testing
@testable import Forma

// Quante volte Forma legge la Salute: solo gli allenamenti nuovi, una volta sola per apertura
@MainActor
struct LetturaWatchTests {
    final class FonteFinta: FonteSalute {
        var letture: [Data?] = []
        var richiestePermesso = 0
        var giaChiesto = false
        var risposta: [AllenamentoWatch] = []
        func permessoGiaChiesto() async -> Bool { giaChiesto }
        func chiediPermesso() async -> Bool { richiestePermesso += 1; giaChiesto = true; return true }
        func nuovi(dopo ancora: Data?, da: Date) async throws -> (allenamenti: [AllenamentoWatch], ancora: Data?) {
            letture.append(ancora)
            return (risposta, Data("ancora\(letture.count)".utf8))
        }
    }

    private func memoria() -> UserDefaults {
        let nome = "LetturaWatchTests-\(UUID().uuidString)"
        return UserDefaults(suiteName: nome)!
    }

    private let ora = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func dueLettureRavvicinateLeggonoUnaVolta() async {
        let f = FonteFinta()
        let l = LetturaWatch(fonte: f, memoria: memoria())
        _ = await l.leggi(adesso: ora)
        let seconda = await l.leggi(adesso: ora.addingTimeInterval(5))
        #expect(f.letture.count == 1)
        #expect(seconda == nil)
    }

    @Test func dopoUnMinutoLeggeSoloIlNuovo() async {
        let f = FonteFinta()
        let l = LetturaWatch(fonte: f, memoria: memoria())
        _ = await l.leggi(adesso: ora)
        _ = await l.leggi(adesso: ora.addingTimeInterval(120))
        #expect(f.letture.count == 2)
        #expect(f.letture[0] == nil)
        #expect(f.letture[1] == Data("ancora1".utf8))
    }

    @Test func ilPuntoRaggiuntoSiRicordaDopoLaRiapertura() async {
        let f = FonteFinta()
        let m = memoria()
        _ = await LetturaWatch(fonte: f, memoria: m).leggi(adesso: ora)
        _ = await LetturaWatch(fonte: f, memoria: m).leggi(adesso: ora.addingTimeInterval(3600))
        #expect(f.letture.last == Data("ancora1".utf8))
    }

    @Test func permessoChiestoUnaVoltaSola() async {
        let f = FonteFinta()
        let l = LetturaWatch(fonte: f, memoria: memoria())
        #expect(await l.permesso())
        #expect(await l.permesso())
        #expect(f.richiestePermesso == 1)
    }

    @Test func risvegliInBackgroundAlPiuOgniOra() {
        #expect(Salute.frequenzaRisveglio == .hourly)
    }
}
