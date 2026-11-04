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
                    case .palestra: PalestraProvvisoria()
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
            .navigationDestination(for: PaginaPalestraDest.self) { pagina in
                switch pagina {
                case .calendario: PaginaPalestra(titolo: "Calendario") { CalendarioContenuto() }
                case .storico: PaginaPalestra(titolo: "Storico") { StoricoAllenamenti() }
                case .libreria, .modelli, .pianoSettimanale: EmptyView()
                }
            }
        }
    }
}

// Provvisorio fino al Task 9: dà accesso a Storico e Calendario
private struct PalestraProvvisoria: View {
    @Environment(Palestra.self) private var palestra

    var body: some View {
        Riquadro {
            NavigationLink(value: PaginaPalestraDest.storico) {
                LabeledContent {
                    Text("\(palestra.stato.allenamenti.count)")
                } label: {
                    Label("Storico e record", systemImage: "chart.line.uptrend.xyaxis")
                }
                .frame(minHeight: 44)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            Divider()
            NavigationLink(value: PaginaPalestraDest.calendario) {
                Label("Calendario", systemImage: "calendar")
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }
}
