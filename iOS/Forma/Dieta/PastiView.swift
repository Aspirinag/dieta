import SwiftUI

// Scheda Dieta: pasti del giorno, olio e acqua; con le frecce si torna ai giorni passati.
// La settimana e la lista della spesa si aprono dal pulsante in alto
struct PastiView: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.scenePhase) private var fase
    @State private var giorno = Giorni.oggi()
    @State private var ultimoOggi = Giorni.oggi()
    @State private var settimana = ["settimana", "spesa"].contains(Avvio.valore("-vista") ?? "")
    @State private var richiesta: TipoPDF?

    private var titolo: String {
        let oggi = Giorni.oggi()
        let nome = Giorni.nomi[Giorni.indice(giorno)]
        if giorno == oggi { return "Dieta" }
        if giorno == Giorni.aggiungi(oggi, -1) { return "Ieri" }
        return nome
    }

    var body: some View {
        NavigationStack {
            List {
                Group {
                    if let piano = archivio.profilo.piano(per: giorno) {
                        let g = piano.giorni[Giorni.indice(giorno)]
                        Section {
                            LabeledContent(Giorni.nomi[Giorni.indice(giorno)] + " " + Giorni.breve(giorno), value: piano.nome)
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
                        ContentUnavailableView {
                            Label("Nessun piano per questo giorno", systemImage: "fork.knife")
                        } description: {
                            Text("Carica lo schema dietetico che ti ha dato il nutrizionista, in PDF.")
                        } actions: {
                            Button("Carica schema dietetico", systemImage: "doc.badge.plus") { richiesta = .schema }
                                .pulsanteVetro(evidente: true)
                        }
                    }
                    Section {
                        NavigationLink { AndamentoPagina() } label: {
                            Label("Andamento e misure BIA", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        NavigationLink { PianiDietaView() } label: {
                            Label("Piani e referti (PDF)", systemImage: "doc.text")
                        }
                    } header: {
                        Text("Progressi e piani")
                    }
                }
                .righeTema()
            }
            .sfondoTema()
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
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Settimana e spesa", systemImage: "calendar") { settimana = true }
                    MenuProfilo()
                }
            }
            .animation(.default, value: giorno)
            .sheet(isPresented: $settimana) { SettimanaView() }
            .importaPDF($richiesta)
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
                    scelte.segmentiOMenu()
                } else {
                    scelte.pickerStyle(.menu)
                }
            }
            if let opz = pasto.opzioni.indices.contains(scelta) ? pasto.opzioni[scelta] : nil {
                ForEach(Array(opz.alimenti.enumerated()), id: \.offset) { _, a in
                    RigaAlimento(nome: a.nome, quantita: a.quantita)
                    .opacity(s.fatto ? 0.5 : 1)
                }
            }
            RigaSpunta(fatto: s.fatto, azione: {
                archivio.cambiaSlot(giorno, indice) { $0.fatto.toggle() }
            }) {
                Text(s.fatto ? "Fatto" : "Segna come fatto")
            }
        } header: {
            Text(pasto.nome)
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
            ), in: 0...max(p.olio * 2, 10)) {
                // Si può segnare anche oltre la dose: il numero diventa arancione
                LabeledContent {
                    Text("\(r.olio) / \(p.olio)").foregroundStyle(r.olio > p.olio ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary))
                } label: {
                    Text("Olio extra vergine")
                }
            }
            Stepper(value: Binding(
                get: { r.acqua },
                set: { v in archivio.cambiaRegistro(giorno) { $0.acqua = v } }
            ), in: 0...max(p.acqua * 2, 4), step: 0.25) {
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
