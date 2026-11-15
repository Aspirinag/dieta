import Foundation
import Testing
@testable import Forma

// Importare un backup della web app non cambia i promemoria di Forma
@MainActor
struct BackupWebTests {
    @Test func backupWebTienePromemoriaAttuali() throws {
        let web = #"{"profili":{"io":{"nome":"Io"}},"attivo":"io","promemoria":{"acqua":true,"pasti":true}}"#
        var mio = Promemoria()
        mio.mattino = false
        mio.oraPasti = 20 * 60
        let stato = try Backup.dietaImportata(Data(web.utf8), promemoria: mio)
        #expect(stato.promemoria?.mattino == false)
        #expect(stato.promemoria?.oraPasti == 20 * 60)
        #expect(stato.promemoria?.acqua == false)
        #expect(stato.profili["io"] != nil)
    }

    @Test func backupWebSenzaPromemoriaAttualiNonNeCreaDiNuovi() throws {
        let web = #"{"profili":{"io":{"nome":"Io"}},"attivo":"io","promemoria":{"acqua":true,"pasti":true}}"#
        let stato = try Backup.dietaImportata(Data(web.utf8), promemoria: nil)
        #expect(stato.promemoria == nil)
    }
}
