import SwiftUI

// Lista della spesa della settimana, aperta da Dieta (Task 6 la ridisegna)
struct SettimanaView: View {
    @Environment(Archivio.self) private var archivio
    @State private var lunSpesa = Profilo.lunediSpesa(oggi: Giorni.oggi())

    var body: some View {
        List {
            Group { spesa }
                .righeTema()
        }
        .sfondoTema()
        .navigationTitle("Spesa")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: testoSpesa, preview: SharePreview("Lista della spesa")) {
                    Label("Condividi", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    // ---------- Spesa ----------

    @ViewBuilder private var spesa: some View {
        let lun = lunSpesa
        let voci = archivio.profilo.vociSpesa(lunedi: lun)
        let presi = archivio.spunteSpesa(lunedi: lun)
        let questa = Giorni.lunedi(Giorni.oggi())
        Section {
            Picker("Settimana", selection: $lunSpesa) {
                Text("Questa settimana").tag(questa)
                Text("Prossima settimana").tag(Giorni.aggiungi(questa, 7))
            }
            .segmentiOMenu()
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        }
        if voci.isEmpty {
            ContentUnavailableView("Nessun piano in questa settimana", systemImage: "cart")
        } else {
            Section {
                ForEach(voci) { v in
                    let preso = presi[v.chiave] == true
                    RigaSpunta(fatto: preso, azione: { archivio.spunta(v.chiave, lunedi: lun) }) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(v.nome).strikethrough(preso)
                            if !v.quanto.isEmpty { Text(v.quanto).font(.caption).foregroundStyle(.secondary) }
                        }
                        .opacity(preso ? 0.5 : 1)
                    }
                }
            } header: {
                Text("Dal \(Giorni.breve(lun)) al \(Giorni.breve(Giorni.aggiungi(lun, 6)))")
            } footer: {
                Text("Per ogni pasto conta l'alternativa scelta, altrimenti la prima. Le spunte restano per questa settimana e la prossima.")
            }
            if !presi.isEmpty {
                Section {
                    Button("Togli le spunte", systemImage: "arrow.counterclockwise") { archivio.azzeraSpesa(lunedi: lun) }
                }
            }
        }
    }

    private var testoSpesa: String {
        let presi = archivio.spunteSpesa(lunedi: lunSpesa)
        let righe = archivio.profilo.vociSpesa(lunedi: lunSpesa).filter { presi[$0.chiave] != true }.map { ($0.quanto.isEmpty ? "- \($0.nome)" : "- \($0.nome): \($0.quanto)") }
        return (["Lista della spesa"] + righe).joined(separator: "\n")
    }
}
