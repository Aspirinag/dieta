import SwiftUI

// Pasti del giorno, olio e acqua; con le frecce si torna ai giorni passati
struct OggiView: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.scenePhase) private var fase
    @State private var giorno = Giorni.oggi()
    @State private var ultimoOggi = Giorni.oggi()

    private var titolo: String {
        let oggi = Giorni.oggi()
        let nome = Giorni.nomi[Giorni.indice(giorno)]
        if giorno == oggi { return "Oggi" }
        if giorno == Giorni.aggiungi(oggi, -1) { return "Ieri" }
        return nome
    }

    var body: some View {
        NavigationStack {
            List {
                if let piano = archivio.profilo.piano(per: giorno) {
                    let g = piano.giorni[Giorni.indice(giorno)]
                    Section {
                        let fatti = g.pasti.indices.filter { archivio.slot(giorno, $0).fatto }.count
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Giorni.nomi[Giorni.indice(giorno)] + " " + Giorni.breve(giorno))
                                    .font(.headline)
                                Text(piano.nome).font(.subheadline).foregroundStyle(.secondary)
                                if fatti == g.pasti.count {
                                    Label("Tutti i pasti segnati", systemImage: "star.fill")
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.tint)
                                }
                            }
                            Spacer(minLength: 0)
                            Anello(valore: g.pasti.isEmpty ? 0 : Double(fatti) / Double(g.pasti.count), testo: "\(fatti)/\(g.pasti.count)")
                        }
                        .padding(.vertical, 4)
                        if g.palestra {
                            Label("Giorno di palestra", systemImage: "dumbbell.fill")
                                .foregroundStyle(.tint)
                        }
                    }
                    ForEach(Array(g.pasti.enumerated()), id: \.offset) { i, pasto in
                        SezionePasto(giorno: giorno, indice: i, pasto: pasto)
                    }
                    SezioneOlioAcqua(giorno: giorno)
                } else {
                    ContentUnavailableView(
                        "Nessun piano per questo giorno",
                        systemImage: "fork.knife",
                        description: Text("Carica lo schema dietetico in PDF dalla scheda Dati.")
                    )
                }
            }
            .navigationTitle(titolo)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button("Giorno precedente", systemImage: "chevron.left") {
                        giorno = Giorni.aggiungi(giorno, -1)
                    }
                    Button("Giorno successivo", systemImage: "chevron.right") {
                        giorno = Giorni.aggiungi(giorno, 1)
                    }
                    .disabled(giorno >= Giorni.oggi())
                    if giorno != Giorni.oggi() {
                        Button("Oggi") { giorno = Giorni.oggi() }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) { MenuProfilo() }
            }
            .animation(.default, value: giorno)
        }
        // Se l'app resta aperta oltre la mezzanotte, passa al nuovo giorno
        .onChange(of: fase) { _, nuova in
            guard nuova == .active else { return }
            if giorno == ultimoOggi { giorno = Giorni.oggi() }
            ultimoOggi = Giorni.oggi()
        }
    }
}

struct SezionePasto: View {
    @Environment(Archivio.self) private var archivio
    let giorno: String
    let indice: Int
    let pasto: Pasto

    var body: some View {
        let s = archivio.slot(giorno, indice)
        let scelta = pasto.opzioni.indices.contains(s.opt) ? s.opt : 0
        Section {
            if pasto.opzioni.count > 1 {
                let scelte = Picker("Alternativa", selection: Binding(
                    get: { scelta },
                    set: { nuova in archivio.cambiaSlot(giorno, indice) { $0.opt = nuova } }
                )) {
                    ForEach(pasto.opzioni.indices, id: \.self) { j in
                        Text(pasto.opzioni[j].titolo ?? "Opzione \(j + 1)").tag(j)
                    }
                }
                if pasto.opzioni.count <= 3 {
                    scelte.pickerStyle(.segmented)
                } else {
                    scelte.pickerStyle(.menu)
                }
            }
            if let opz = pasto.opzioni.indices.contains(scelta) ? pasto.opzioni[scelta] : nil {
                ForEach(Array(opz.alimenti.enumerated()), id: \.offset) { _, a in
                    HStack(alignment: .firstTextBaseline) {
                        Text(a.nome).strikethrough(s.fatto)
                        Spacer()
                        Text(a.quantita).foregroundStyle(.secondary).monospacedDigit()
                    }
                    .opacity(s.fatto ? 0.5 : 1)
                }
            }
            RigaSpunta(fatto: s.fatto, azione: {
                archivio.cambiaSlot(giorno, indice) { $0.fatto.toggle() }
            }) {
                Text(s.fatto ? "Fatto" : "Segna come fatto")
            }
        } header: {
            HStack {
                Label(pasto.nome, systemImage: iconaPasto(pasto.nome))
                Spacer()
                if s.fatto {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.3), value: s.fatto)
        }
    }
}

struct SezioneOlioAcqua: View {
    @Environment(Archivio.self) private var archivio
    let giorno: String

    var body: some View {
        let r = archivio.registro(giorno)
        let p = archivio.profilo
        Section {
            Stepper(value: Binding(
                get: { r.olio },
                set: { v in archivio.cambiaRegistro(giorno) { $0.olio = v } }
            ), in: 0...max(p.olio, 0)) {
                LabeledContent("Olio extra vergine", value: "\(r.olio) / \(p.olio)")
            }
            Stepper(value: Binding(
                get: { r.acqua },
                set: { v in archivio.cambiaRegistro(giorno) { $0.acqua = v } }
            ), in: 0...max(p.acqua, 0), step: 0.25) {
                LabeledContent("Acqua", value: "\(num(r.acqua)) / \(num(p.acqua)) L")
            }
        } header: {
            Text("Olio e acqua")
        } footer: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Olio in cucchiaini. Un bicchiere d'acqua è circa 0,25 L.")
                if !p.testoNote.isEmpty { Text(p.testoNote) }
            }
        }
    }
}
