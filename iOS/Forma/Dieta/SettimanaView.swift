import SwiftUI

// Pasti di ogni giorno del piano attivo e lista della spesa della settimana
struct SettimanaView: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.dismiss) private var chiudi
    @State private var vista = Avvio.valore("-vista") == "spesa" ? 1 : 0
    @State private var giorno = Giorni.indice(Giorni.oggi())
    @State private var lunSpesa = Profilo.lunediSpesa(oggi: Giorni.oggi())

    var body: some View {
        NavigationStack {
            List {
                Group {
                    Section {
                        Picker("Vista", selection: $vista) {
                            Text("Giorni").tag(0)
                            Text("Lista della spesa").tag(1)
                        }
                        .segmentiOMenu()
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }
                    if vista == 0 {
                        giorni
                    } else {
                        spesa
                    }
                }
                .righeTema()
            }
            .sfondoTema()
            .navigationTitle("Settimana")
            .toolbar {
                if vista == 1 {
                    ToolbarItem(placement: .topBarLeading) {
                        ShareLink(item: testoSpesa, preview: SharePreview("Lista della spesa")) {
                            Label("Condividi", systemImage: "square.and.arrow.up")
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) { Button("Fine") { chiudi() } }
            }
        }
    }

    // ---------- Giorni ----------

    @ViewBuilder private var giorni: some View {
        let oggi = Giorni.indice(Giorni.oggi())
        if let piano = archivio.profilo.piano(per: Giorni.oggi()) {
            let g = piano.giorni[giorno]
            Section {
                Picker("Giorno", selection: $giorno) {
                    ForEach(0..<7, id: \.self) { i in
                        Text(String(Giorni.nomi[i].prefix(3))).tag(i)
                    }
                }
                .segmentiOMenu()
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } footer: {
                Text(piano.nome)
            }
            Section {
                LabeledContent(Giorni.nomi[giorno], value: giorno == oggi ? "oggi" : "")
                if g.palestra {
                    Label("Giorno di palestra", systemImage: "dumbbell.fill").foregroundStyle(.tint)
                }
            }
            ForEach(Array(g.pasti.enumerated()), id: \.offset) { _, pasto in
                Section(pasto.nome) {
                    ForEach(Array(pasto.opzioni.enumerated()), id: \.offset) { j, o in
                        if pasto.opzioni.count > 1 {
                            Text(o.titolo ?? "Opzione \(j + 1)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.tint)
                        }
                        ForEach(Array(o.alimenti.enumerated()), id: \.offset) { _, a in
                            RigaAlimento(nome: a.nome, quantita: a.quantita)
                        }
                    }
                }
            }
        } else {
            ContentUnavailableView(
                "Nessun piano attivo",
                systemImage: "calendar",
                description: Text("Carica lo schema dietetico in PDF da Dieta → Piani e referti.")
            )
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
                Text("Prossima").tag(Giorni.aggiungi(questa, 7))
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
                            Text(v.quanto).font(.caption).foregroundStyle(.secondary)
                        }
                        .opacity(preso ? 0.5 : 1)
                    }
                }
            } header: {
                Text("Dal \(Giorni.breve(lun)) al \(Giorni.breve(Giorni.aggiungi(lun, 6)))")
            } footer: {
                Text("Per ogni pasto conta l'alternativa scelta, altrimenti la prima. Le spunte valgono per una settimana alla volta.")
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
        let righe = archivio.profilo.vociSpesa(lunedi: lunSpesa).filter { presi[$0.chiave] != true }.map { "- \($0.nome): \($0.quanto)" }
        return (["Lista della spesa"] + righe).joined(separator: "\n")
    }
}
