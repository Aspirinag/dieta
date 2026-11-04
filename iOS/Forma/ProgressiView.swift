import SwiftUI

// Progressi: tutto ciò che guarda indietro. In alto la scelta Corpo / Palestra.
// Le destinazioni stanno sulla radice della pila e si raggiungono sempre per valore.
struct ProgressiView: View {
    private enum Sezione: String, CaseIterable, Identifiable {
        case corpo = "Corpo", palestra = "Palestra"
        var id: String { rawValue }
    }

    @State private var sezione: Sezione = .corpo
    @State private var richiesta: TipoPDF?
    @State private var nuovaMisura = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    Picker("Mostra", selection: $sezione) {
                        ForEach(Sezione.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    switch sezione {
                    case .corpo: CorpoView(aggiungi: { nuovaMisura = true })
                    case .palestra: ProgressiPalestraView()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .sfondoTema()
            .navigationTitle("Progressi")
            .toolbar {
                if sezione == .corpo {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("Aggiungi misurazione", systemImage: "square.and.pencil") { nuovaMisura = true }
                            Button("Carica referto BIA (PDF)", systemImage: "doc.badge.plus") { richiesta = .bia }
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Aggiungi")
                    }
                }
            }
            .importaPDF($richiesta)
            .sheet(isPresented: $nuovaMisura) {
                NavigationStack { EditorMisura(dataEsistente: nil) }
            }
            .destinazioniDieta()
            .destinazioniArchivioPalestra()
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

