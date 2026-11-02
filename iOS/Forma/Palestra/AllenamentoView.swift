import SwiftUI

// Apre l'editor di una scheda (tipo a parte: gli UUID semplici aprono il dettaglio di un allenamento)
struct ApriScheda: Hashable { let id: UUID }

// Scheda Palestra: inizia un allenamento, le mie schede, cardio, storico e calendario, impostazioni
struct AllenamentoView: View {
    @Environment(Palestra.self) private var palestra
    @Environment(Navigazione.self) private var navigazione
    @State private var percorso = NavigationPath()
    @State private var daAvviare: Routine??
    @State private var cardio = false
    @State private var schedaDaEliminare: Routine?
    @State private var cardioDaEliminare: SessioneCardio?

    var body: some View {
        NavigationStack(path: $percorso) {
            List {
                Group {
                    avvio
                    schede
                    sezioneCardio
                    Section {
                        NavigationLink { LibreriaView(modo: .sfoglia) } label: {
                            Label("Libreria esercizi", systemImage: "books.vertical")
                        }
                        NavigationLink { ModelliView(percorso: $percorso) } label: {
                            Label("Schede pronte", systemImage: "square.stack.3d.up")
                        }
                    }
                    Section {
                        NavigationLink { PaginaPalestra(titolo: "Storico") { StoricoAllenamenti() } } label: {
                            LabeledContent {
                                Text("\(palestra.stato.allenamenti.count)")
                            } label: {
                                Label("Storico e record", systemImage: "chart.line.uptrend.xyaxis")
                            }
                        }
                        NavigationLink { PaginaPalestra(titolo: "Calendario") { CalendarioContenuto() } } label: {
                            Label("Calendario", systemImage: "calendar")
                        }
                        NavigationLink { PaginaPalestra(titolo: "Impostazioni palestra") { SezioniPalestra() } } label: {
                            Label("Piano A/B, pagamento e Watch", systemImage: "gearshape")
                        }
                    } header: {
                        Text("Progressi e impostazioni")
                    }
                }
                .righeTema()
            }
            .sfondoTema()
            .navigationTitle("Palestra")
            .navigationDestination(for: ApriScheda.self) { EditorSchedaView(idScheda: $0.id) }
            .navigationDestination(for: UUID.self) { DettaglioAllenamentoView(id: $0) }
            .navigationDestination(for: Esercizio.self) { DettaglioEsercizioView(idEsercizio: $0.id) }
            .sheet(isPresented: $cardio) { NuovoCardioView() }
            .confirmationDialog("Eliminare la scheda?", isPresented: Binding(
                get: { schedaDaEliminare != nil }, set: { if !$0 { schedaDaEliminare = nil } }
            ), titleVisibility: .visible, presenting: schedaDaEliminare) { r in
                Button("Elimina \(r.nome)", role: .destructive) { palestra.stato.routine.removeAll { $0.id == r.id } }
            } message: { _ in
                Text("Gli allenamenti già fatti con questa scheda restano nello storico.")
            }
            .confirmationDialog("Eliminare questo cardio?", isPresented: Binding(
                get: { cardioDaEliminare != nil }, set: { if !$0 { cardioDaEliminare = nil } }
            ), titleVisibility: .visible, presenting: cardioDaEliminare) { c in
                Button("Elimina", role: .destructive) { palestra.stato.cardio.removeAll { $0.id == c.id } }
            }
            .confirmationDialog("C'è già un allenamento in corso", isPresented: Binding(
                get: { daAvviare != nil }, set: { if !$0 { daAvviare = nil } }
            ), titleVisibility: .visible) {
                Button("Riprendi quello in corso") { navigazione.allenamentoAperto = true }
                Button("Annullalo e inizia il nuovo", role: .destructive) {
                    if let r = daAvviare { avvia(r, forza: true) }
                }
            }
        }
    }

    private func avvia(_ r: Routine?, forza: Bool = false) {
        if palestra.stato.inCorso != nil && !forza {
            daAvviare = .some(r)
            return
        }
        palestra.inizia(r)
        navigazione.allenamentoAperto = true
    }

    private var avvio: some View {
        let oggi = Giorni.oggi()
        let t = palestra.programmato(oggi)
        return Section {
            if let a = palestra.stato.inCorso {
                Button { navigazione.allenamentoAperto = true } label: {
                    Label("Riprendi \(a.nome)", systemImage: "play.fill").frame(maxWidth: .infinity)
                }
                .pulsanteVetro(evidente: true)
                .controlSize(.large)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } else {
                Button { avvia(nil) } label: {
                    Label("Allenamento libero", systemImage: "plus").frame(maxWidth: .infinity)
                }
                .pulsanteVetro(evidente: true)
                .controlSize(.large)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
        } footer: {
            Text("Oggi: \(t.nome.lowercased()) · settimana \(palestra.settimana(oggi))")
        }
    }

    private var schede: some View {
        Section {
            ForEach(palestra.stato.routine) { r in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        NavigationLink(value: ApriScheda(id: r.id)) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(r.nome).font(.headline)
                                Text(r.voci.map { palestra.nome($0.esercizio) }.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    Button { avvia(r) } label: {
                        Label("Inizia", systemImage: "play.fill").frame(maxWidth: .infinity)
                    }
                    .pulsanteVetro()
                }
                .padding(.vertical, 4)
                .swipeActions {
                    Button("Elimina", systemImage: "trash") { schedaDaEliminare = r }
                        .tint(.red)
                    Button("Duplica", systemImage: "plus.square.on.square") {
                        var copia = r
                        copia.id = UUID()
                        copia.nome += " (copia)"
                        palestra.stato.routine.append(copia)
                    }
                    .tint(.blue)
                }
            }
            .onMove { palestra.stato.routine.move(fromOffsets: $0, toOffset: $1) }
            Button("Nuova scheda", systemImage: "square.and.pencil") {
                let r = Routine(nome: "Nuova scheda")
                palestra.stato.routine.append(r)
                percorso.append(ApriScheda(id: r.id))
            }
        } header: {
            Text("Le mie schede")
        }
    }

    private var sezioneCardio: some View {
        Section {
            ForEach(palestra.stato.cardio.sorted { $0.data > $1.data }.prefix(3)) { c in
                Label {
                    VStack(alignment: .leading) {
                        Text("\(c.tipo) · \(c.minuti) min" + (c.km > 0 ? " · \(num(c.km)) km" : ""))
                        Text(Giorni.breve(c.data)).font(.caption).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: Libreria.simboloCardio(c.tipo)).foregroundStyle(.tint)
                }
                .swipeActions {
                    Button("Elimina", systemImage: "trash") { cardioDaEliminare = c }
                        .tint(.red)
                }
            }
            Button("Registra cardio", systemImage: "figure.run") { cardio = true }
        } header: {
            Text("Cardio")
        }
    }
}

// Modifica di una scheda: nome, esercizi con serie, ripetizioni e recupero
struct EditorSchedaView: View {
    @Environment(Palestra.self) private var palestra
    @Environment(Navigazione.self) private var navigazione
    @Environment(\.dismiss) private var chiudi
    let idScheda: UUID
    @State private var aggiungi = false
    @State private var chiediElimina = false

    private var indice: Int? { palestra.stato.routine.firstIndex { $0.id == idScheda } }

    var body: some View {
        if let i = indice {
            let r = palestra.stato.routine[i]
            List {
                Group {
                    Section {
                        TextField("Nome della scheda", text: Binding(
                            get: { r.nome },
                            set: { palestra.stato.routine[i].nome = $0 }
                        ))
                        .font(.headline)
                    }
                    Section {
                        ForEach(r.voci) { v in
                            if let j = r.voci.firstIndex(where: { $0.id == v.id }) {
                                VoceSchedaView(voce: Binding(
                                    get: { palestra.stato.routine[i].voci[j] },
                                    set: { palestra.stato.routine[i].voci[j] = $0 }
                                ))
                            }
                        }
                        .onDelete { palestra.stato.routine[i].voci.remove(atOffsets: $0) }
                        .onMove { palestra.stato.routine[i].voci.move(fromOffsets: $0, toOffset: $1) }
                        Button("Aggiungi esercizi", systemImage: "plus") { aggiungi = true }
                    } header: {
                        Text("Esercizi")
                    } footer: {
                        Text("Tocca un esercizio per cambiare serie, ripetizioni e recupero. Tieni premuto e trascina per riordinare.")
                    }
                    Section {
                        Button("Elimina scheda", systemImage: "trash", role: .destructive) { chiediElimina = true }
                    }
                }
                .righeTema()
            }
            .sfondoTema()
            .navigationTitle(r.nome)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { EditButton() }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Inizia", systemImage: "play.fill") {
                        guard palestra.stato.inCorso == nil else {
                            navigazione.allenamentoAperto = true
                            return
                        }
                        palestra.inizia(r)
                        navigazione.allenamentoAperto = true
                    }
                    .disabled(r.voci.isEmpty)
                }
            }
            .confirmationDialog("Eliminare la scheda?", isPresented: $chiediElimina, titleVisibility: .visible) {
                Button("Elimina \(r.nome)", role: .destructive) {
                    palestra.stato.routine.removeAll { $0.id == idScheda }
                    chiudi()
                }
            } message: {
                Text("Gli allenamenti già fatti con questa scheda restano nello storico.")
            }
            .sheet(isPresented: $aggiungi) {
                LibreriaView(modo: .scelta { ids in
                    palestra.stato.routine[i].voci += ids.map { VoceRoutine(esercizio: $0) }
                })
            }
        }
    }
}

struct VoceSchedaView: View {
    @Environment(Palestra.self) private var palestra
    @Binding var voce: VoceRoutine
    @State private var aperta = false

    var body: some View {
        DisclosureGroup(isExpanded: $aperta) {
            Stepper("Serie: \(voce.serie)", value: $voce.serie, in: 1...10)
            Stepper("Ripetizioni minime: \(voce.ripMin)", value: Binding(
                get: { voce.ripMin },
                set: { voce.ripMin = $0; voce.ripMax = max(voce.ripMax, $0) }
            ), in: 1...50)
            Stepper("Ripetizioni massime: \(voce.ripMax)", value: Binding(
                get: { voce.ripMax },
                set: { voce.ripMax = $0; voce.ripMin = min(voce.ripMin, $0) }
            ), in: 1...50)
            Picker("Recupero", selection: $voce.recupero) {
                ForEach([30, 45, 60, 90, 120, 150, 180, 240], id: \.self) { Text("\($0) s").tag($0) }
            }
        } label: {
            HStack(spacing: 12) {
                IconaEsercizio(esercizio: palestra.esercizio(voce.esercizio), lato: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(palestra.nome(voce.esercizio))
                    Text("\(voce.obiettivo) · recupero \(voce.recupero) s").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}

// Schede pronte (Full body, Push/Pull/Legs, Upper/Lower...): si copiano tra le mie schede
struct ModelliView: View {
    @Environment(Palestra.self) private var palestra
    @Binding var percorso: NavigationPath

    var body: some View {
        List {
            Group {
                ForEach(Libreria.modelli) { m in
                    Section {
                        ForEach(m.voci) { v in
                            LabeledContent(palestra.nome(v.esercizio), value: v.obiettivo)
                        }
                        Button("Aggiungi alle mie schede", systemImage: "plus.circle") {
                            var copia = m
                            copia.id = UUID()
                            palestra.stato.routine.append(copia)
                            percorso = NavigationPath([ApriScheda(id: copia.id)])
                        }
                    } header: {
                        Text(m.nome)
                    }
                }
            }
            .righeTema()
        }
        .sfondoTema()
        .navigationTitle("Schede pronte")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NuovoCardioView: View {
    @Environment(Palestra.self) private var palestra
    @Environment(\.dismiss) private var chiudi
    @State private var tipo = Libreria.tipiCardio[0]
    @State private var data = Date()
    @State private var minuti = ""
    @State private var km = ""

    var body: some View {
        NavigationStack {
            Form {
                Group {
                    Picker("Tipo", selection: $tipo) {
                        ForEach(Libreria.tipiCardio, id: \.self) { Label($0, systemImage: Libreria.simboloCardio($0)).tag($0) }
                    }
                    DatePicker("Data", selection: $data, in: ...Date(), displayedComponents: .date)
                    LabeledContent("Minuti") {
                        TextField("30", text: $minuti).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Km (facoltativi)") {
                        TextField("0", text: $km).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                }
                .righeTema()
            }
            .sfondoTema()
            .navigationTitle("Cardio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla", role: .cancel) { chiudi() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva", systemImage: "checkmark") {
                        guard let m = Int(minuti), m > 0 else { return }
                        let iso = Giorni.iso(data)
                        palestra.stato.cardio.append(SessioneCardio(data: iso, tipo: tipo, minuti: m, km: leggiNumero(km) ?? 0))
                        palestra.stato.saltati.removeAll { $0 == iso }
                        chiudi()
                    }
                    .disabled((Int(minuti) ?? 0) <= 0)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// Pagina della scheda Palestra con il contenuto di una lista (storico, calendario, impostazioni)
struct PaginaPalestra<Contenuto: View>: View {
    let titolo: String
    @ViewBuilder let contenuto: Contenuto

    var body: some View {
        List {
            Group { contenuto }.righeTema()
        }
        .sfondoTema()
        .navigationTitle(titolo)
        .navigationBarTitleDisplayMode(.inline)
    }
}
