import SwiftUI

// Pasti di ogni giorno del piano attivo e lista della spesa della settimana
struct SettimanaView: View {
    @Environment(Archivio.self) private var archivio
    @State private var vista = Avvio.valore("-vista") == "spesa" ? 1 : 0
    @State private var giorno = Giorni.indice(Giorni.oggi())

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Vista", selection: $vista) {
                        Text("Giorni").tag(0)
                        Text("Lista della spesa").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
                if vista == 0 {
                    giorni
                } else {
                    spesa
                }
            }
            .navigationTitle("Settimana")
            .toolbar {
                if vista == 1 {
                    ToolbarItem(placement: .topBarLeading) {
                        ShareLink(item: testoSpesa, preview: SharePreview("Lista della spesa")) {
                            Label("Condividi", systemImage: "square.and.arrow.up")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) { MenuProfilo() }
            }
        }
    }

    // ---------- Giorni ----------

    @ViewBuilder private var giorni: some View {
        let oggi = Giorni.indice(Giorni.oggi())
        if let piano = archivio.profilo.piano(per: Giorni.oggi()) {
            let g = piano.giorni[giorno]
            Section {
                selettoreGiorni(piano, oggi: oggi)
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
                Section {
                    ForEach(Array(pasto.opzioni.enumerated()), id: \.offset) { j, o in
                        if pasto.opzioni.count > 1 {
                            Text(o.titolo ?? "Opzione \(j + 1)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.tint)
                        }
                        ForEach(Array(o.alimenti.enumerated()), id: \.offset) { _, a in
                            HStack(alignment: .firstTextBaseline) {
                                Text(a.nome)
                                Spacer()
                                Text(a.quantita).foregroundStyle(.secondary).monospacedDigit()
                            }
                        }
                    }
                } header: {
                    Label(pasto.nome, systemImage: iconaPasto(pasto.nome))
                }
            }
        } else {
            ContentUnavailableView(
                "Nessun piano attivo",
                systemImage: "calendar",
                description: Text("Carica lo schema dietetico in PDF dalla scheda Dati.")
            )
        }
    }

    // Giorni della settimana corrente: oggi evidenziato, manubrio per la palestra, spunta se tutti i pasti sono segnati
    private func selettoreGiorni(_ piano: Piano, oggi: Int) -> some View {
        let lun = Giorni.lunedi(Giorni.oggi())
        return HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { i in
                let data = Giorni.aggiungi(lun, i)
                let scelto = i == giorno
                Button {
                    giorno = i
                } label: {
                    VStack(spacing: 3) {
                        Text(String(Giorni.nomi[i].prefix(3)))
                            .font(.caption2.weight(.medium))
                            .textCase(.uppercase)
                        Text(String(Int(data.suffix(2)) ?? 0))
                            .font(.title3.weight(.semibold))
                            .fontDesign(.rounded)
                            .monospacedDigit()
                        Group {
                            if completo(data) {
                                Image(systemName: "checkmark.circle.fill")
                            } else if piano.giorni[i].palestra {
                                Image(systemName: "dumbbell.fill")
                            } else {
                                Image(systemName: "circle.fill").hidden()
                            }
                        }
                        .font(.caption2)
                        .frame(height: 12)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(scelto ? AnyShapeStyle(.white) : i == oggi ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(scelto ? AnyShapeStyle(.tint) : AnyShapeStyle(Color(.secondarySystemGroupedBackground)))
                        if i == oggi && !scelto {
                            RoundedRectangle(cornerRadius: 14).strokeBorder(.tint, lineWidth: 1.5)
                        }
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Giorni.nomi[i] + (i == oggi ? ", oggi" : ""))
                .accessibilityAddTraits(scelto ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: giorno)
        .animation(.snappy(duration: 0.25), value: giorno)
    }

    // Giorno passato (o oggi) con tutti i pasti segnati
    private func completo(_ data: String) -> Bool {
        guard data <= Giorni.oggi(), let p = archivio.profilo.piano(per: data) else { return false }
        let pasti = p.giorni[Giorni.indice(data)].pasti
        return !pasti.isEmpty && pasti.indices.allSatisfy { archivio.slot(data, $0).fatto }
    }

    // ---------- Spesa ----------

    @ViewBuilder private var spesa: some View {
        let voci = archivio.vociSpesa()
        let profili = archivio.profiliSpesa
        let presi = archivio.spunteSpesa()
        let lun = Giorni.lunedi(Giorni.oggi())
        if voci.isEmpty {
            ContentUnavailableView("Nessun piano questa settimana", systemImage: "cart")
        } else {
            Section {
                ForEach(voci) { v in
                    let preso = presi[v.chiave] == true
                    RigaSpunta(fatto: preso, azione: { archivio.spunta(v.chiave) }) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(v.nome).strikethrough(preso)
                            Text(v.quanto).font(.caption).foregroundStyle(.secondary).monospacedDigit()
                            if let d = v.dettaglio {
                                Text(d).font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                        .opacity(preso ? 0.5 : 1)
                    }
                }
            } header: {
                Text("Dal \(Giorni.breve(lun)) al \(Giorni.breve(Giorni.aggiungi(lun, 6)))")
            } footer: {
                Text((profili.count > 1 ? "Lista unica per \(profili.map(\.nome).formatted(.list(type: .and))): le quantità sono sommate e le spunte valgono per tutti. " : "")
                     + "Per ogni pasto conta l'alternativa scelta in Oggi, altrimenti la prima. Le spunte ripartono ogni lunedì.")
            }
            if !presi.isEmpty {
                Section {
                    Button("Togli le spunte", systemImage: "arrow.counterclockwise") { archivio.azzeraSpesa() }
                }
            }
        }
    }

    private var testoSpesa: String {
        let presi = archivio.spunteSpesa()
        let righe = archivio.vociSpesa().filter { presi[$0.chiave] != true }.map { "- \($0.nome): \($0.quanto)" }
        return (["Lista della spesa"] + righe).joined(separator: "\n")
    }
}
