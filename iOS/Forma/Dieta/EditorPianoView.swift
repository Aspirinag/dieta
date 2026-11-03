import SwiftUI

// Piano alimentare modificato a mano: nome, date e, per ogni giorno, pasti, alternative e alimenti.
// Si lavora su una copia; "Salva" la mette al posto dell'originale (o la aggiunge se è nuovo)
struct EditorPianoView: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.dismiss) private var chiudi
    let originale: Piano?
    @State private var piano: Piano
    @State private var giorno = 0
    @State private var dal: Date
    @State private var al: Date
    @State private var senzaFine: Bool
    @State private var chiediCopia = false

    init(originale: Piano?) {
        self.originale = originale
        var p = originale ?? Piano(nome: "Nuovo piano", dal: Giorni.oggi(), al: "",
                                   giorni: Giorni.nomi.map { GiornoPiano(nome: $0, palestra: false, pasti: []) })
        // Piani vecchi o della web app con meno di 7 giorni: si completano
        while p.giorni.count < 7 { p.giorni.append(GiornoPiano(nome: Giorni.nomi[p.giorni.count], palestra: false, pasti: [])) }
        _piano = State(initialValue: p)
        _dal = State(initialValue: Giorni.data(p.dal))
        _al = State(initialValue: p.al.isEmpty ? Giorni.data(p.dal) : Giorni.data(p.al))
        _senzaFine = State(initialValue: p.al.isEmpty)
    }

    var body: some View {
        NavigationStack {
            Form {
                Group {
                    Section {
                        TextField("Nome del piano", text: $piano.nome)
                        DatePicker("Valido dal", selection: $dal, displayedComponents: .date)
                        Toggle("Senza data di fine", isOn: $senzaFine)
                        if !senzaFine {
                            DatePicker("Fino al", selection: $al, in: dal..., displayedComponents: .date)
                        }
                    } footer: {
                        if let altro = archivio.profilo.pianoConStessaData(Giorni.iso(dal), escluso: originale) {
                            Text("Attenzione: sostituisce «\(altro.nome)», che inizia lo stesso giorno.")
                                .foregroundStyle(.orange)
                        }
                    }
                    Section {
                        Picker("Giorno", selection: $giorno) {
                            ForEach(0..<7, id: \.self) { Text(String(Giorni.nomi[$0].prefix(3))).tag($0) }
                        }
                        .segmentiOMenu()
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }
                    Section {
                        Toggle("Giorno di palestra", isOn: $piano.giorni[giorno].palestra)
                        Button("Copia \(Giorni.nomi[giorno]) su tutti i giorni", systemImage: "doc.on.doc") {
                            chiediCopia = true
                        }
                        .disabled(piano.giorni[giorno].pasti.isEmpty)
                    } header: {
                        Text(Giorni.nomi[giorno])
                    }
                    ForEach(piano.giorni[giorno].pasti.indices, id: \.self) { i in
                        // Binding protetto: durante un'eliminazione la riga può chiedere un indice che non c'è più
                        EditorPasto(pasto: Binding(
                            get: { piano.giorni[giorno].pasti.indices.contains(i) ? piano.giorni[giorno].pasti[i] : Pasto(nome: "", opzioni: []) },
                            set: { if piano.giorni[giorno].pasti.indices.contains(i) { piano.giorni[giorno].pasti[i] = $0 } }
                        )) {
                            if piano.giorni[giorno].pasti.indices.contains(i) { piano.giorni[giorno].pasti.remove(at: i) }
                        }
                    }
                    Section {
                        Button("Aggiungi pasto", systemImage: "plus") {
                            piano.giorni[giorno].pasti.append(Pasto(nome: "", opzioni: [Opzione(alimenti: [])]))
                        }
                    }
                }
                .righeTema()
            }
            .sfondoTema()
            .navigationTitle(originale == nil ? "Nuovo piano" : "Modifica piano")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla", role: .cancel) { chiudi() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva", systemImage: "checkmark") { salva() }
                        .disabled(piano.nome.trimmingCharacters(in: .whitespaces).isEmpty
                                  || (originale == nil && piano.giorni.allSatisfy { $0.pasti.isEmpty }))
                }
            }
            .interactiveDismissDisabled()
            .confirmationDialog("Copiare \(Giorni.nomi[giorno]) su tutti i giorni?", isPresented: $chiediCopia, titleVisibility: .visible) {
                Button("Sostituisci gli altri giorni", role: .destructive) {
                    let g = piano.giorni[giorno]
                    for i in piano.giorni.indices where i != giorno {
                        piano.giorni[i].pasti = g.pasti
                        piano.giorni[i].palestra = g.palestra
                    }
                }
            } message: {
                Text("I pasti degli altri giorni vengono sostituiti da quelli di \(Giorni.nomi[giorno]). Dopo puoi cambiare i singoli giorni.")
            }
        }
    }

    private func salva() {
        var p = piano
        p.nome = p.nome.trimmingCharacters(in: .whitespaces)
        p.dal = Giorni.iso(dal)
        p.al = senzaFine ? "" : Giorni.iso(max(al, dal))
        // Pasti senza nome o senza alimenti non servono
        for g in p.giorni.indices {
            for k in p.giorni[g].pasti.indices {
                for o in p.giorni[g].pasti[k].opzioni.indices {
                    p.giorni[g].pasti[k].opzioni[o].alimenti.removeAll { $0.nome.trimmingCharacters(in: .whitespaces).isEmpty }
                }
            }
            p.giorni[g].pasti.removeAll { $0.nome.trimmingCharacters(in: .whitespaces).isEmpty }
        }
        if let originale {
            archivio.profilo.sostituisciPiano(originale, con: p)
        } else {
            archivio.aggiungiPiano(p)
        }
        chiudi()
    }
}

// Un pasto: nome, alternative (con titolo se più di una) e alimenti con quantità
private struct EditorPasto: View {
    @Binding var pasto: Pasto
    let elimina: () -> Void
    @State private var chiediElimina = false

    var body: some View {
        Section {
            TextField("Nome del pasto (es. Colazione)", text: $pasto.nome)
                .font(.headline)
            ForEach(pasto.opzioni.indices, id: \.self) { o in
                if pasto.opzioni.indices.contains(o) {
                if pasto.opzioni.count > 1 {
                    HStack {
                        TextField("Alternativa \(o + 1)", text: Binding(
                            get: { pasto.opzioni.indices.contains(o) ? pasto.opzioni[o].titolo ?? "" : "" },
                            set: { if pasto.opzioni.indices.contains(o) { pasto.opzioni[o].titolo = $0.isEmpty ? nil : $0 } }
                        ))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.tint)
                        Button("Elimina alternativa", systemImage: "minus.circle") {
                            if pasto.opzioni.indices.contains(o) { pasto.opzioni.remove(at: o) }
                        }
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.red)
                            .buttonStyle(.borderless)
                    }
                }
                ForEach(pasto.opzioni[o].alimenti.indices, id: \.self) { a in
                    HStack {
                        TextField("Alimento", text: campo(o, a, \.nome))
                        TextField("Quantità", text: campo(o, a, \.quantita))
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: 110)
                    }
                }
                .onDelete { if pasto.opzioni.indices.contains(o) { pasto.opzioni[o].alimenti.remove(atOffsets: $0) } }
                Button("Aggiungi alimento", systemImage: "plus") {
                    if pasto.opzioni.indices.contains(o) { pasto.opzioni[o].alimenti.append(Alimento(nome: "", quantita: "")) }
                }
                .buttonStyle(.borderless)
                }
            }
            Button("Aggiungi alternativa", systemImage: "arrow.triangle.branch") {
                pasto.opzioni.append(Opzione(alimenti: []))
            }
            .buttonStyle(.borderless)
            Button("Elimina pasto", systemImage: "trash", role: .destructive) { chiediElimina = true }
                .buttonStyle(.borderless)
        } footer: {
            Text("Scorri a sinistra su un alimento per eliminarlo.")
        }
        .confirmationDialog("Eliminare \(pasto.nome.isEmpty ? "il pasto" : pasto.nome)?", isPresented: $chiediElimina, titleVisibility: .visible) {
            Button("Elimina", role: .destructive, action: elimina)
        }
    }

    // Campo di un alimento con controllo degli indici (righe in corso di eliminazione)
    private func campo(_ o: Int, _ a: Int, _ k: WritableKeyPath<Alimento, String>) -> Binding<String> {
        Binding(
            get: {
                guard pasto.opzioni.indices.contains(o), pasto.opzioni[o].alimenti.indices.contains(a) else { return "" }
                return pasto.opzioni[o].alimenti[a][keyPath: k]
            },
            set: { v in
                guard pasto.opzioni.indices.contains(o), pasto.opzioni[o].alimenti.indices.contains(a) else { return }
                pasto.opzioni[o].alimenti[a][keyPath: k] = v
            }
        )
    }
}
