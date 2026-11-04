import SwiftUI

// Impostazioni: elenco delle sottopagine (profili, olio e acqua, promemoria, backup)
struct ImpostazioniView: View {
    var body: some View {
        NavigationStack {
            List {
                Group {
                    NavigationLink("Profili") { ProfiliImpostazioni() }
                    NavigationLink("Olio e acqua") { OlioAcquaImpostazioni() }
                    NavigationLink("Promemoria") { PromemoriaImpostazioni() }
                    NavigationLink("Backup") { BackupImpostazioni() }
                }
                .righeTema()
            }
            .sfondoTema()
            .navigationTitle("Impostazioni")
        }
    }
}
