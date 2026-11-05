import SwiftUI

// Progressi: tutto ciò che guarda indietro. In alto la scelta Corpo / Palestra.
// Le destinazioni stanno sulla radice della pila e si raggiungono sempre per valore.
struct ProgressiView: View {
    private enum Sezione: String, CaseIterable, Identifiable {
        case corpo = "Corpo", palestra = "Palestra"
        var id: String { rawValue }
        var etichetta: LocalizedStringKey {
            switch self {
            case .corpo: "Corpo"
            case .palestra: "Palestra"
            }
        }
    }

    @State private var sezione: Sezione = .corpo
    @State private var richiesta: TipoPDF?
    @State private var nuovaMisura = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spazio.l) {
                    Picker("Mostra", selection: $sezione) {
                        ForEach(Sezione.allCases) { Text($0.etichetta).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    switch sezione {
                    case .corpo: CorpoView(aggiungi: { nuovaMisura = true })
                    case .palestra: ProgressiPalestraView()
                    }
                }
                .padding(.horizontal, Spazio.l)
                .padding(.bottom, Spazio.l)
            }
            .sfondoTema()
            .navigationTitle("Progressi")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if sezione == .corpo {
                        Menu {
                            Button("Nuova misura", systemImage: "square.and.pencil") { nuovaMisura = true }
                            Button("Carica la BIA (PDF)", systemImage: "doc.badge.plus") { richiesta = .bia }
                        } label: {
                            Image(systemName: "plus")
                        }
                        .tint(.primary)
                        .accessibilityLabel("Aggiungi")
                    }
                    PulsanteImpostazioni()
                }
            }
            .importaPDF($richiesta)
            .sheet(isPresented: $nuovaMisura) {
                NavigationStack { EditorMisura(dataEsistente: nil) }
            }
            .destinazioniDieta()
            .destinazioniArchivioPalestra()
            // Registrata una volta sola sulla radice (non su ogni figlio di un Group)
            .navigationDestination(for: ApriCardio.self) { DettaglioCardioView(id: $0.id) }
            .navigationDestination(for: PaginaProgressi.self) { pagina in
                switch pagina {
                case .allenamenti: StoricoAllenamenti()
                case .calendario: CalendarioContenuto()
                case .record: RecordView()
                }
            }
        }
    }
}

