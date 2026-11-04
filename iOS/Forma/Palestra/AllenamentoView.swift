import SwiftUI

// Apre l'editor di una scheda (tipo a parte: gli UUID semplici aprono il dettaglio di un allenamento)
struct ApriScheda: Hashable { let id: UUID }

// Palestra serve a iniziare: prossima scheda, settimana, schede con ▶. Storico e calendario stanno in Progressi
struct AllenamentoView: View {
    @Environment(Palestra.self) private var palestra
    @Environment(Navigazione.self) private var navigazione
    @Environment(\.dynamicTypeSize) private var dimensione
    @State private var percorso = NavigationPath()
    @State private var daAvviare: Routine??
    @State private var cardio = false
    @State private var schedaDaEliminare: Routine?

    var body: some View {
        NavigationStack(path: $percorso) {
            ScrollView {
                VStack(spacing: 12) {
                    prossima
                    settimana
                    schede
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .sfondoTema()
            .navigationTitle("Palestra")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Nuova scheda", systemImage: "square.and.pencil") { nuovaScheda() }
                        Button("Schede pronte", systemImage: "square.stack.3d.up") { percorso.append(PaginaPalestraDest.modelli) }
                        Button("Libreria esercizi", systemImage: "books.vertical") { percorso.append(PaginaPalestraDest.libreria) }
                        Button("Programma della settimana", systemImage: "calendar") { percorso.append(PaginaPalestraDest.pianoSettimanale) }
                        Button("Registra cardio", systemImage: "figure.run") { cardio = true }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Aggiungi")
                }
            }
            .destinazioniArchivioPalestra()
            .navigationDestination(for: PaginaPalestraDest.self) { pagina in
                switch pagina {
                case .libreria: LibreriaView(modo: .sfoglia)
                case .modelli: ModelliView(percorso: $percorso)
                case .storico: PaginaPalestra(titolo: "Storico") { StoricoAllenamenti() }
                case .calendario: PaginaPalestra(titolo: "Calendario") { CalendarioContenuto() }
                case .impostazioni: PaginaPalestra(titolo: "Impostazioni palestra") { SezioniPalestra() }
                case .pianoSettimanale: PianoSettimanaleView()
                }
            }
            .navigationDestination(for: ApriScheda.self) { EditorSchedaView(idScheda: $0.id) }
            .sheet(isPresented: $cardio) { NuovoCardioView() }
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
        let r = Routine(nome: "Nuova scheda")
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

    // ---------- Prossima scheda ----------

    @ViewBuilder private var prossima: some View {
        if let a = palestra.stato.inCorso {
            Riquadro {
                Text("In corso").font(.footnote).foregroundStyle(.secondary)
                Text(a.nome).font(.title2.bold()).padding(.top, 2)
                Button { navigazione.allenamentoAperto = true } label: {
                    Text("Riprendi").frame(maxWidth: .infinity, minHeight: 28)
                }
                .buttonStyle(PulsanteAccento())
                .padding(.top, 12)
            }
        } else if let r = palestra.stato.prossimaRoutine() {
            Riquadro {
                Text("Prossima scheda").font(.footnote).foregroundStyle(.secondary)
                Text(r.nome).font(.title2.bold()).padding(.top, 2)
                if !r.voci.isEmpty {
                    Text(frase(r, massimo: 80))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
                Button { avvia(r) } label: {
                    Text("Inizia").frame(maxWidth: .infinity, minHeight: 28)
                }
                .buttonStyle(PulsanteAccento())
                .padding(.top, 12)
            }
        } else {
            Riquadro {
                Text("Nessuna scheda").font(.title2.bold())
                Text("Crea la tua o parti da una scheda pronta.")
                    .font(.subheadline).foregroundStyle(.secondary).padding(.top, 2)
                Button { nuovaScheda() } label: {
                    Text("Crea la prima scheda").frame(maxWidth: .infinity, minHeight: 28)
                }
                .buttonStyle(PulsanteAccento())
                .padding(.top, 12)
                Button { percorso.append(PaginaPalestraDest.modelli) } label: {
                    Text("Scegli tra le schede pronte")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Colori.accento)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // ---------- Questa settimana ----------

    private var settimana: some View {
        let oggi = Giorni.oggi()
        let fatti = palestra.stato.giorniAllenati(settimanaDi: oggi)
        let durata = palestra.stato.durataSettimana(oggi)
        let n = fatti.count
        let riepilogo = n == 0 ? "Nessun allenamento" : "\(n) \(n == 1 ? "allenamento" : "allenamenti") · \(durataTesto(durata))"
        return Riquadro {
            Text("Questa settimana").font(.headline)
            Text(riepilogo).font(.subheadline).foregroundStyle(.secondary).padding(.top, 2)
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(fatti.contains(i) ? Colori.accento : Color(.systemFill))
                            .frame(width: 18, height: 18)
                        Text(Giorni.iniziali[i])
                            .font(.caption2.weight(i == Giorni.indice(oggi) ? .bold : .regular))
                            .foregroundStyle(i == Giorni.indice(oggi) ? Color.primary : Color.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 12)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Giorni allenati")
            .accessibilityValue(riepilogo)
        }
    }

    // ---------- Schede ----------

    private var schede: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Schede").font(.headline).padding(.leading, 4).padding(.top, 8)
            Riquadro {
                ForEach(palestra.stato.routine) { r in
                    HStack(spacing: 8) {
                        NavigationLink(value: ApriScheda(id: r.id)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(r.nome).font(.headline).foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                if !r.voci.isEmpty {
                                    Text(frase(r, massimo: 44))
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Button { avvia(r) } label: {
                            Image(systemName: "play.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(Colori.sulAccento)
                                .frame(width: 44, height: 44)
                                .background(Colori.accento, in: .circle)
                                .contentShape(.circle)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Inizia \(r.nome)")
                    }
                    .padding(.vertical, 4)
                    .contextMenu {
                        Button("Duplica", systemImage: "plus.square.on.square") {
                            var copia = r
                            copia.id = UUID()
                            copia.nome += " (copia)"
                            palestra.stato.routine.append(copia)
                        }
                        Button("Elimina", systemImage: "trash", role: .destructive) { schedaDaEliminare = r }
                    }
                    Divider()
                }
                Button { avvia(nil) } label: {
                    Text("Allenamento libero")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Colori.accento)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
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
// Pagine della Palestra aperte per valore: le destinazioni stanno sulla radice della scheda.
// Con collegamenti diretti, il primo collegamento per valore (allenamento, esercizio) le chiudeva
enum PaginaPalestraDest: Hashable {
    case libreria, modelli, storico, calendario, impostazioni, pianoSettimanale
}

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

extension View {
    // Pagine raggiungibili da più schede (storico, calendario, dettagli): le destinazioni stanno sulla radice
    func destinazioniArchivioPalestra() -> some View {
        navigationDestination(for: UUID.self) { DettaglioAllenamentoView(id: $0) }
            .navigationDestination(for: Esercizio.self) { DettaglioEsercizioView(idEsercizio: $0.id) }
    }
}
