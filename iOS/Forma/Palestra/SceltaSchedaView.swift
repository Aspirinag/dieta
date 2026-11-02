import SwiftUI

// Dopo una sessione registrata dal Watch: scegli la scheda fatta, le serie si riempiono
// con i pesi dell'ultima volta e si correggono nell'allenamento
struct SceltaSchedaView: View {
    @Environment(Palestra.self) private var palestra
    @Environment(Navigazione.self) private var navigazione
    let id: UUID

    var body: some View {
        NavigationStack {
            List {
                Group {
                    if let a = palestra.stato.allenamenti.first(where: { $0.id == id }) {
                        Section {
                            LabeledContent("Quando", value: a.inizio.formatted(.dateTime.weekday(.wide).day().month(.wide).hour().minute().locale(Locale(identifier: "it_IT"))))
                            LabeledContent("Durata", value: durataTesto(a.durata))
                            if let kcal = a.watch?.calorie { LabeledContent("Calorie", value: "\(Int(kcal.rounded())) kcal") }
                        } footer: {
                            Text("Scegli la scheda che hai fatto: le serie si riempiono con i pesi dell'ultima volta, tu correggi e spunti.")
                        }
                        if palestra.stato.inCorso != nil {
                            Text("C'è già un allenamento in corso: finiscilo prima.").foregroundStyle(.secondary)
                        } else {
                            Section("Schede") {
                                ForEach(palestra.stato.routine) { r in
                                    Button { scegli(r) } label: {
                                        Label(r.nome, systemImage: "list.bullet.clipboard")
                                    }
                                }
                                Button { scegli(nil) } label: {
                                    Label("Allenamento libero", systemImage: "plus")
                                }
                            }
                        }
                    } else {
                        Text("Questa sessione non c'è più.").foregroundStyle(.secondary)
                    }
                }
                .righeTema()
            }
            .sfondoTema()
            .navigationTitle("Aggiungi esercizi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Più tardi") { navigazione.compila = nil }
                }
            }
        }
    }

    private func scegli(_ r: Routine?) {
        guard palestra.compila(id, con: r) else { return }
        navigazione.compila = nil
        // L'allenamento si apre a schermo intero quando il foglio si è chiuso
        Task {
            try? await Task.sleep(for: .milliseconds(450))
            navigazione.allenamentoAperto = true
        }
    }
}
