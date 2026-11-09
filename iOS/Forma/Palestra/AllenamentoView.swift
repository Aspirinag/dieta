import SwiftUI

// Apre l'editor di una scheda (tipo a parte: gli UUID semplici aprono il dettaglio di un allenamento)
struct ApriScheda: Hashable { let id: UUID }

// Palestra serve a iniziare: prossima scheda, altre schede, e le funzioni di tutti i giorni con il loro nome.
// Storico e calendario stanno in Progressi
struct AllenamentoView: View {
    @Environment(Palestra.self) private var palestra
    @Environment(Navigazione.self) private var navigazione
    @Environment(\.dynamicTypeSize) private var dimensione
    @State private var percorso = NavigationPath()
    @State private var daAvviare: Routine??
    @State private var cardio = false
    @State private var schedaDaEliminare: Routine?
    @State private var importaPDF = false

    var body: some View {
        NavigationStack(path: $percorso) {
            List {
                prossima
                altreSchede
                altro
            }
            .tint(.primary)
            .sfondoTema()
            .navigationTitle("Palestra")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Scheda vuota", systemImage: "square.and.pencil") { nuovaScheda() }
                        Button("Importa da PDF", systemImage: "doc.badge.plus") { importaPDF = true }
                    } label: {
                        Label("Nuova scheda", systemImage: "plus")
                    }
                    .tint(.primary)
                }
                ToolbarItem(placement: .topBarTrailing) { PulsanteImpostazioni() }
            }
            .destinazioniArchivioPalestra()
            .navigationDestination(for: PaginaPalestraDest.self) { pagina in
                switch pagina {
                case .libreria: LibreriaView(modo: .sfoglia)
                case .modelli: ModelliView(percorso: $percorso)
                case .pianoSettimanale: PianoSettimanaleView()
                }
            }
            .navigationDestination(for: ApriScheda.self) { EditorSchedaView(idScheda: $0.id) }
            .sheet(isPresented: $cardio) { NuovoCardioView() }
            .importaSchedaPDF($importaPDF)
            .confirmationDialog("Eliminare la scheda?", isPresented: Binding(
                get: { schedaDaEliminare != nil }, set: { if !$0 { schedaDaEliminare = nil } }
            ), titleVisibility: .visible, presenting: schedaDaEliminare) { r in
                Button("Elimina \(r.nome)", role: .destructive) { palestra.stato.routine.removeAll { $0.id == r.id } }
            } message: { _ in
                Text("Gli allenamenti già fatti con questa scheda restano nello storico.")
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

    private func nuovaScheda() {
        let r = Routine(nome: String(localized: "Nuova scheda"))
        palestra.stato.routine.append(r)
        percorso.append(ApriScheda(id: r.id))
    }

    // Esercizi in una frase: nomi interi fino a un limite di lettere, poi «…»
    private func frase(_ r: Routine, massimo: Int) -> String {
        let nomi = r.voci.map { palestra.nome($0.esercizio) }
        var scelti: [String] = [], lunghezza = 0
        for n in nomi {
            if !scelti.isEmpty && lunghezza + n.count + 2 > massimo { break }
            scelti.append(n)
            lunghezza += n.count + 2
        }
        return scelti.joined(separator: ", ") + (scelti.count < nomi.count ? "…" : "")
    }

    // La scheda messa in evidenza in alto (la prossima): nella lista sotto non si ripete
    private var inEvidenza: Routine? {
        palestra.stato.inCorso == nil ? palestra.stato.prossimaRoutine() : nil
    }

    // ---------- Prossima scheda, con sotto il riepilogo della settimana ----------

    private var prossima: some View {
        let oggi = Giorni.oggi()
        let riepilogo = riepilogoAllenamenti(palestra.stato.allenamentiSettimana(oggi), durata: palestra.stato.durataSettimana(oggi))
        return Section {
            riquadroPrincipale
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        } footer: {
            Text("Questa settimana: \(riepilogo)")
                .accessibilityIdentifier("settimana")
        }
    }

    @ViewBuilder private var riquadroPrincipale: some View {
        if let a = palestra.stato.inCorso {
            Riquadro {
                Text("In corso").font(.footnote).foregroundStyle(.secondary)
                Text(verbatim: a.titolo).font(.title2.bold()).padding(.top, Spazio.xs)
                Button { navigazione.allenamentoAperto = true } label: {
                    Text("Riprendi").frame(maxWidth: .infinity, minHeight: 28)
                }
                .buttonStyle(PulsanteAccento())
                .padding(.top, Spazio.m)
            }
        } else if let r = inEvidenza {
            Riquadro {
                Text("Prossima scheda").font(.footnote).foregroundStyle(.secondary)
                Text(r.nome).font(.title2.bold()).padding(.top, Spazio.xs)
                if !r.voci.isEmpty {
                    Text(frase(r, massimo: 80))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(dimensione.isAccessibilitySize ? nil : 2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Spazio.xs)
                }
                Button { avvia(r) } label: {
                    Text("Inizia").frame(maxWidth: .infinity, minHeight: 28)
                }
                .buttonStyle(PulsanteAccento())
                .padding(.top, Spazio.m)
            }
        } else {
            Riquadro {
                Text("Nessuna scheda").font(.title2.bold())
                Text("Crea la tua o parti da una scheda pronta.")
                    .font(.subheadline).foregroundStyle(.secondary).padding(.top, Spazio.xs)
                Button { nuovaScheda() } label: {
                    Text("Crea la prima scheda").frame(maxWidth: .infinity, minHeight: 28)
                }
                .buttonStyle(PulsanteAccento())
                .padding(.top, Spazio.m)
                Button { percorso.append(PaginaPalestraDest.modelli) } label: {
                    Text("Scegli tra le schede pronte")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, minHeight: Misure.tocco)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // ---------- Altre schede ----------

    @ViewBuilder private var altreSchede: some View {
        let altre = palestra.stato.routine.filter { $0.id != inEvidenza?.id }
        if !altre.isEmpty {
            Section {
                ForEach(altre) { r in
                    NavigationLink(value: ApriScheda(id: r.id)) {
                        Riga(Text(r.nome), dettaglio: r.voci.isEmpty ? nil : Text(frase(r, massimo: 44)), evidente: true, righeDettaglio: 2) {
                            Button { avvia(r) } label: {
                                Image(systemName: "play.fill")
                                    .foregroundStyle(.secondary)
                                    .frame(minWidth: Misure.tocco, minHeight: Misure.tocco)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Inizia \(r.nome)")
                        }
                    }
                    .accessibilityHint("Tieni premuto per duplicare o eliminare la scheda")
                    .contextMenu {
                        Button("Duplica", systemImage: "plus.square.on.square") {
                            var copia = r
                            copia.id = UUID()
                            copia.nome = String(localized: "\(r.nome) (copia)")
                            palestra.stato.routine.append(copia)
                        }
                        Button("Elimina", systemImage: "trash", role: .destructive) { schedaDaEliminare = r }
                    }
                }
            } header: {
                Text(inEvidenza == nil ? LocalizedStringKey("Schede") : LocalizedStringKey("Altre schede"))
                    .accessibilityIdentifier("intestazioneSchede")
            }
        }
    }

    // ---------- Altro: le funzioni, ognuna con il suo nome ----------

    private var altro: some View {
        Section("Altro") {
            Button { cardio = true } label: {
                Label("Registra cardio", systemImage: "figure.run").foregroundStyle(.primary)
            }
            NavigationLink(value: PaginaPalestraDest.pianoSettimanale) {
                Label("Programma della settimana", systemImage: "calendar")
            }
            NavigationLink(value: PaginaPalestraDest.libreria) {
                Label("Libreria esercizi", systemImage: "books.vertical")
            }
            NavigationLink(value: PaginaPalestraDest.modelli) {
                Label("Schede pronte", systemImage: "square.stack.3d.up")
            }
            Button { importaPDF = true } label: {
                Label("Importa da PDF", systemImage: "doc.badge.plus").foregroundStyle(.primary)
            }
            Button { avvia(nil) } label: {
                Label("Allenamento libero", systemImage: "figure.strengthtraining.traditional").foregroundStyle(.primary)
            }
        }
    }
}

extension AllenamentoView {
    // «1 allenamento» / «3 allenamenti» (inglese: workout / workouts); lo usa anche il riepilogo della settimana
    static func conteggio(_ n: Int, bundle: Bundle = .main) -> String {
        String(localized: "\(n) allenamenti", bundle: bundle)
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
            .tint(.primary)
            .sfondoTema()
            // Il nome si cambia toccando il titolo (menu del titolo → Rinomina)
            .navigationTitle(Binding(get: { r.nome }, set: { palestra.stato.routine[i].nome = $0 }))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarTitleMenu { RenameButton() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { EditButton() }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    guard palestra.stato.inCorso == nil else {
                        navigazione.allenamentoAperto = true
                        return
                    }
                    palestra.inizia(r)
                    navigazione.allenamentoAperto = true
                } label: {
                    Text("Inizia").frame(maxWidth: .infinity, minHeight: 28)
                }
                .buttonStyle(PulsanteAccento())
                .disabled(r.voci.isEmpty)
                .padding(.horizontal, Spazio.l)
                .padding(.vertical, Spazio.s)
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
                // L'omino solo se c'è il disegno della macchina: l'omino generico non dice niente
                if Figura.esercizi[voce.esercizio] != nil {
                    IconaEsercizio(esercizio: palestra.esercizio(voce.esercizio), lato: 36)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(palestra.nome(voce.esercizio))
                    Text("\(voce.obiettivo) · recupero \(voce.recupero) s").font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
    }
}

// Schede pronte (Full body, Push/Pull/Legs, Upper/Lower...): si copiano tra le mie schede
struct ModelliView: View {
    @Environment(Palestra.self) private var palestra
    @Binding var percorso: NavigationPath

    // «3 × 30–45 s» per gli esercizi a tempo (plank): ogni numero ha la sua unità
    private func obiettivo(_ v: VoceRoutine) -> String {
        palestra.nome(v.esercizio).localizedCaseInsensitiveContains("plank") ? "\(v.obiettivo) s" : v.obiettivo
    }

    var body: some View {
        List {
            Group {
                ForEach(Libreria.modelli) { m in
                    Section {
                        ForEach(m.voci) { v in
                            LabeledContent(palestra.nome(v.esercizio), value: obiettivo(v))
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
        .tint(.primary)
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
    @State private var minuti = 30
    @State private var minutiToccati = false
    @State private var km = ""

    // Minuti dell'ultimo cardio dello stesso tipo, altrimenti 30: è un valore vero, si salva così com'è
    private func minutiTipici(_ tipo: String) -> Int {
        palestra.stato.cardio.last(where: { $0.tipo == tipo })?.minuti ?? 30
    }

    var body: some View {
        NavigationStack {
            Form {
                Group {
                    Picker("Tipo", selection: $tipo) {
                        ForEach(Libreria.tipiCardio, id: \.self) { Label(Libreria.nomeCardio($0), systemImage: Libreria.simboloCardio($0)).tag($0) }
                    }
                    DatePicker("Data", selection: $data, in: ...Date(), displayedComponents: .date)
                    Stepper(value: Binding(get: { minuti }, set: { minuti = $0; minutiToccati = true }), in: 5...600, step: 5) {
                        LabeledContent("Minuti") { Text("\(minuti)").numero() }
                    }
                    LabeledContent("Km (facoltativi)") {
                        TextField("", text: $km)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Km (facoltativi)")
                    }
                }
                .righeTema()
            }
            .tint(.primary)
            .sfondoTema()
            .navigationTitle("Cardio")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { minuti = minutiTipici(tipo) }
            .onChange(of: tipo) { _, nuovo in if !minutiToccati { minuti = minutiTipici(nuovo) } }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla", role: .cancel) { chiudi() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva", systemImage: "checkmark") {
                        let iso = Giorni.iso(data)
                        palestra.stato.cardio.append(SessioneCardio(data: iso, tipo: tipo, minuti: minuti, km: leggiNumero(km) ?? 0))
                        palestra.stato.saltati.removeAll { $0 == iso }
                        chiudi()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// Pagina della scheda Palestra con il contenuto di una lista (storico, calendario, impostazioni)
// Pagine della Palestra aperte per valore: le destinazioni stanno sulla radice della scheda.
// Con collegamenti diretti, il primo collegamento per valore (allenamento, esercizio) le chiudeva
enum PaginaPalestraDest: Hashable {
    case libreria, modelli, pianoSettimanale
}

struct PaginaPalestra<Contenuto: View>: View {
    let titolo: LocalizedStringKey
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

extension View {
    // Pagine raggiungibili da più schede (storico, calendario, dettagli): le destinazioni stanno sulla radice
    func destinazioniArchivioPalestra() -> some View {
        navigationDestination(for: UUID.self) { DettaglioAllenamentoView(id: $0) }
            .navigationDestination(for: Esercizio.self) { DettaglioEsercizioView(idEsercizio: $0.id) }
    }
}
