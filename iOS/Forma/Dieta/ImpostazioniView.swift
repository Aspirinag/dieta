import SwiftUI

// Pagine delle Impostazioni, aperte per valore: le destinazioni stanno sulla radice del foglio
enum PaginaImpostazioni: Hashable {
    case olioAcqua, pagamento, watch, promemoria, backup, profili
}

// Foglio aperto dall'ingranaggio di Oggi: sette voci in tre gruppi
struct ImpostazioniView: View {
    @Environment(\.dismiss) private var chiudi

    var body: some View {
        NavigationStack {
            List {
                Group {
                    Section("Dieta") {
                        NavigationLink(value: PaginaDieta.piani) {
                            etichetta("Piani alimentari", "doc.text")
                        }
                        riga("Olio e acqua", "drop", .olioAcqua)
                    }
                    Section("Palestra") {
                        riga("Abbonamento palestra", "creditcard", .pagamento)
                        riga("Apple Watch", "applewatch", .watch)
                    }
                    Section("Generali") {
                        riga("Promemoria", "bell", .promemoria)
                        riga("Backup", "externaldrive", .backup)
                        riga("Profili", "person.2", .profili)
                    }
                }
                .righeTema()
            }
            .sfondoTema()
            .navigationTitle("Impostazioni")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") { chiudi() }
                }
            }
            .destinazioniDieta()
            .navigationDestination(for: PaginaImpostazioni.self) { pagina in
                switch pagina {
                case .olioAcqua: OlioAcquaImpostazioni()
                case .pagamento: PaginaPalestra(titolo: "Abbonamento palestra") { SezioniPalestra(parte: .pagamento) }
                case .watch: PaginaPalestra(titolo: "Apple Watch") { SezioniPalestra(parte: .watch) }
                case .promemoria: PromemoriaImpostazioni()
                case .backup: BackupImpostazioni()
                case .profili: ProfiliImpostazioni()
                }
            }
        }
        .tint(.primary)   // niente verde nei menu: le icone e le azioni sono neutre
    }

    private func riga(_ titolo: LocalizedStringKey, _ simbolo: String, _ pagina: PaginaImpostazioni) -> some View {
        NavigationLink(value: pagina) { etichetta(titolo, simbolo) }
    }

    // Icona grigia: il verde resta all'azione principale e allo stato «fatto»
    private func etichetta(_ titolo: LocalizedStringKey, _ simbolo: String) -> some View {
        Label {
            Text(titolo)
        } icon: {
            Image(systemName: simbolo).foregroundStyle(.secondary)
        }
    }
}
