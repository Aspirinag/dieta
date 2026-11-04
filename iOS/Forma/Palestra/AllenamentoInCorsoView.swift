import SwiftUI

// Allenamento in corso (come Hevy): per ogni esercizio la tabella delle serie con la serie precedente,
// kg, ripetizioni e la spunta; la spunta fa partire il recupero
struct AllenamentoInCorsoView: View {
    @Environment(Palestra.self) private var palestra
    @Environment(TimerRecupero.self) private var timer
    @Environment(Navigazione.self) private var navigazione
    @Environment(\.dynamicTypeSize) private var dimensione
    @State private var aggiungi = false
    @State private var chiediFine = false
    @State private var chiediAnnulla = false
    @State private var riaperti: Set<UUID> = []   // esercizi finiti che restano aperti: riaperti a mano o appena finiti
    @State private var chiusure: [UUID: Task<Void, Never>] = [:]   // chiusura in attesa, per esercizio
    @FocusState private var campo: PuntoDiFocus?

    var body: some View {
        NavigationStack {
            if let a = palestra.stato.inCorso {
                ScrollViewReader { scorri in
                List {
                    Group {
                        statistiche(a)
                        SezioneRiscaldamento()
                        ForEach(a.esercizi) { e in
                            SezioneEsercizioInCorso(idEsercizio: e.id, campo: $campo, riaperti: $riaperti)
                        }
                        Section {
                            Button {
                                aggiungi = true
                            } label: {
                                Label("Aggiungi esercizio", systemImage: "plus").frame(maxWidth: .infinity)
                            }
                            .pulsanteVetro(evidente: true)
                            .controlSize(.large)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                        }
                        Section {
                            Button("Annulla allenamento", systemImage: "trash", role: .destructive) { chiediAnnulla = true }
                        }
                    }
                    .righeTema()
                }
                .sfondoTema()
                .onChange(of: a.esercizi.filter(PercorsoAllenamento.completo).map(\.id)) { prima, ora in
                    // Un esercizio tornato incompleto si riapre da solo e la sua chiusura in attesa salta
                    riaperti.formIntersection(ora)
                    for (id, compito) in chiusure where !ora.contains(id) {
                        compito.cancel()
                        chiusure[id] = nil
                    }
                    // Uno appena finito resta aperto un attimo (per annullare una spunta sbagliata), poi si chiude e porta al prossimo da fare
                    guard let finito = PercorsoAllenamento.appenaFinito(prima: prima, ora: ora) else { return }
                    riaperti.insert(finito)
                    chiusure[finito]?.cancel()
                    chiusure[finito] = Task {
                        try? await Task.sleep(for: PercorsoAllenamento.ritardoChiusura)
                        guard !Task.isCancelled,
                              let esercizi = palestra.stato.inCorso?.esercizi,
                              PercorsoAllenamento.siChiudeDopoIlRitardo(finito, in: esercizi) else { return }
                        chiusure[finito] = nil
                        let prossimo = PercorsoAllenamento.prossimoAperto(dopo: finito, in: esercizi)
                        withAnimation(.smooth) {
                            riaperti.remove(finito)
                            if let prossimo { scorri.scrollTo(prossimo, anchor: .top) }
                        }
                    }
                }
                .navigationTitle(a.titolo)
                .navigationBarTitleDisplayMode(.inline)
                .scrollDismissesKeyboard(.interactively)
                .toolbar { barra(a) }
                .safeAreaInset(edge: .bottom) { TimerInAllenamento() }
                .sheet(isPresented: $aggiungi) {
                    LibreriaView(modo: .scelta { ids in palestra.aggiungi(esercizi: ids) })
                }
                .confirmationDialog("Finire l'allenamento?", isPresented: $chiediFine, titleVisibility: .visible) {
                    Button("Finisci e salva") { finisci() }
                    Button("Continua", role: .cancel) {}
                } message: {
                    Text("Le serie senza spunta non vengono salvate.")
                }
                .confirmationDialog("Annullare l'allenamento?", isPresented: $chiediAnnulla, titleVisibility: .visible) {
                    Button("Annulla allenamento", role: .destructive) {
                        timer.ferma()
                        palestra.annulla()
                    }
                } message: {
                    Text("Le serie di questo allenamento non vengono salvate.")
                }
                }
            }
        }
    }

    @ToolbarContentBuilder
    private func barra(_ a: Allenamento) -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Nascondi", systemImage: "chevron.down") { navigazione.allenamentoAperto = false }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Annulla allenamento", systemImage: "trash", role: .destructive) { chiediAnnulla = true }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("Altre azioni")
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Fine") {
                let daSegnare = a.esercizi.flatMap(\.serie).contains { !$0.fatta }
                if daSegnare { chiediFine = true } else { finisci() }
            }
            .disabled(a.serieFatte == 0)
        }
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Fine") { campo = nil }
        }
    }

    private func statistiche(_ a: Allenamento) -> some View {
        Section {
            let layout = dimensione.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout())
            layout {
                dato("Durata") {
                    // Sessione del Watch completata dopo: durata fissa; altrimenti cronometro
                    if a.fine != nil { Text(durataTesto(a.durata)) }
                    else { Text(timerInterval: a.inizio...Date.distantFuture, countsDown: false).monospacedDigit() }
                }
                dato("Kg totali") { Text(volumeTesto(a.volume)) }
                dato("Serie") { Text("\(a.serieFatte)") }
            }
        }
    }

    private func dato<V: View>(_ titolo: LocalizedStringKey, @ViewBuilder _ valore: () -> V) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titolo).font(.caption).foregroundStyle(.secondary)
            valore().font(.headline).foregroundStyle(.tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func finisci() {
        timer.ferma()
        campo = nil
        if let salvato = palestra.termina() {
            navigazione.allenamentoAperto = false
            navigazione.riepilogo = salvato
        }
    }
}

// Riscaldamento dei giorni di pesi, con la spiegazione dei movimenti
struct SezioneRiscaldamento: View {
    @Environment(Palestra.self) private var palestra
    @State private var aperto = false

    var body: some View {
        let fatti = palestra.stato.inCorso?.riscaldamento ?? [:]
        Section {
            DisclosureGroup(isExpanded: $aperto) {
                ForEach(Array(Libreria.riscaldamento.enumerated()), id: \.offset) { i, voce in
                    RigaSpunta(fatto: fatti[String(i)] == true, azione: {
                        palestra.stato.inCorso?.riscaldamento[String(i)] = !(fatti[String(i)] == true)
                    }) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(voce.0).font(.subheadline.weight(.semibold))
                            Text(voce.1).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            } label: {
                LabeledContent("Riscaldamento", value: "\(fatti.values.filter { $0 }.count)/\(Libreria.riscaldamento.count)")
            }
        }
    }
}

struct SezioneEsercizioInCorso: View {
    @Environment(Palestra.self) private var palestra
    let idEsercizio: UUID
    var campo: FocusState<PuntoDiFocus?>.Binding
    @Binding var riaperti: Set<UUID>
    @State private var chiediRimuovi = false

    private var indice: Int? { palestra.stato.inCorso?.esercizi.firstIndex { $0.id == idEsercizio } }

    var body: some View {
        if let i = indice, let e = palestra.stato.inCorso?.esercizi[i] {
            let ex = palestra.esercizio(e.esercizio)
            let inModifica = e.serie.first { $0.id == campo.wrappedValue?.serie }?.id != nil ? e.id : nil
            if PercorsoAllenamento.compresso(e, riaperti: riaperti, inModifica: inModifica) {
                Section {
                    Button {
                        withAnimation(.smooth) { _ = riaperti.insert(e.id) }
                    } label: {
                        HStack(spacing: 12) {
                            IconaEsercizio(esercizio: ex, lato: 32)
                            Text(verbatim: "\(ex.titolo) · " + String(localized: "\(PercorsoAllenamento.serieDiLavoro(e)) serie ✓"))
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.down").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(Text("Tocca per riaprire"))
                    .listRowBackground(Color.green.opacity(0.14))
                    .id(idEsercizio)
                }
            } else {
            Section {
                intestazione(ex, e, i)
                    .id(idEsercizio)
                HStack(spacing: 8) {
                    Text("Serie").frame(width: 36)
                    Text("Ultima volta").frame(maxWidth: .infinity)
                    Text("Kg").frame(width: 64)
                    Text("Ripetizioni").frame(width: 52)
                    Image(systemName: "checkmark").frame(width: 32)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                ForEach(e.serie) { s in
                    RigaSerie(idEsercizio: idEsercizio, idSerie: s.id, campo: campo, riaperti: $riaperti)
                }
                Button("Aggiungi serie", systemImage: "plus") {
                    let ultima = e.serie.last
                    palestra.stato.inCorso?.esercizi[i].serie.append(SerieFatta(kg: ultima?.kg, rip: ultima?.rip))
                }
                .font(.subheadline.weight(.semibold))
            }
            }
        }
    }

    private func intestazione(_ ex: Esercizio, _ e: EsercizioFatto, _ i: Int) -> some View {
        HStack(spacing: 12) {
            IconaEsercizio(esercizio: ex)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: ex.titolo).font(.headline)
                Text("\(ex.muscolo.nome) · recupero \(e.recupero) s").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Menu {
                Picker("Recupero", selection: Binding(
                    get: { e.recupero },
                    set: { palestra.stato.inCorso?.esercizi[i].recupero = $0 }
                )) {
                    ForEach([30, 45, 60, 90, 120, 150, 180, 240], id: \.self) { Text("\($0) s").tag($0) }
                }
                if i > 0 {
                    Button("Sposta su", systemImage: "arrow.up") { palestra.stato.inCorso?.esercizi.swapAt(i, i - 1) }
                }
                if i < (palestra.stato.inCorso?.esercizi.count ?? 0) - 1 {
                    Button("Sposta giù", systemImage: "arrow.down") { palestra.stato.inCorso?.esercizi.swapAt(i, i + 1) }
                }
                Button("Rimuovi esercizio", systemImage: "trash", role: .destructive) { chiediRimuovi = true }
            } label: {
                Image(systemName: "ellipsis.circle").font(.title3)
            }
            .accessibilityLabel("Opzioni di \(ex.titolo)")
            .confirmationDialog("Rimuovere \(ex.titolo)?", isPresented: $chiediRimuovi, titleVisibility: .visible) {
                Button("Rimuovi", role: .destructive) { palestra.stato.inCorso?.esercizi.removeAll { $0.id == idEsercizio } }
            } message: {
                Text("Le serie di questo esercizio non vengono salvate.")
            }
        }
    }
}

struct RigaSerie: View {
    @Environment(Palestra.self) private var palestra
    @Environment(TimerRecupero.self) private var timer
    let idEsercizio: UUID
    let idSerie: UUID
    var campo: FocusState<PuntoDiFocus?>.Binding
    @Binding var riaperti: Set<UUID>
    @State private var kg = ""
    @State private var rip = ""
    @State private var caricato = false
    @State private var errore = 0

    private var posizione: (Int, Int)? {
        guard let i = palestra.stato.inCorso?.esercizi.firstIndex(where: { $0.id == idEsercizio }),
              let j = palestra.stato.inCorso?.esercizi[i].serie.firstIndex(where: { $0.id == idSerie }) else { return nil }
        return (i, j)
    }

    var body: some View {
        if let p = posizione, let e = palestra.stato.inCorso?.esercizi[p.0] {
            let i = p.0, j = p.1
            let s = e.serie[j]
            let numero = e.serie[..<j].filter { !$0.riscaldamento }.count
            let prec = palestra.precedente(e.esercizio, numero)
            HStack(spacing: 8) {
                Menu {
                    Toggle("Serie di riscaldamento", isOn: Binding(
                        get: { s.riscaldamento },
                        set: { v in modifica { $0.riscaldamento = v } }
                    ))
                } label: {
                    Text(verbatim: s.riscaldamento ? String(localized: "R") : "\(numero + 1)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(s.riscaldamento ? AnyShapeStyle(.orange) : AnyShapeStyle(.primary))
                        .frame(width: 36)
                }
                ultimaVolta(prec, fatta: s.fatta)
                cella(testo: $kg, segnaposto: prec?.kg.map { num($0) } ?? "kg", tastiera: .decimalPad, larghezza: 64, quale: .kg)
                    .onChange(of: kg) { _, v in modifica { $0.kg = leggiNumero(v) } }
                cella(testo: $rip, segnaposto: prec?.rip.map(String.init) ?? String(localized: "rip"), tastiera: .numberPad, larghezza: 52, quale: .rip)
                    .onChange(of: rip) { _, v in modifica { $0.rip = Int(v) } }
                Button {
                    segna(s, prec, e.recupero, corpoLibero: palestra.esercizio(e.esercizio).attrezzo == .corpoLibero)
                } label: {
                    Image(systemName: s.fatta ? "checkmark.square.fill" : "square")
                        .font(.title2)
                        .foregroundStyle(s.fatta ? AnyShapeStyle(.green) : AnyShapeStyle(.secondary))
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
                .frame(width: 32)
                .accessibilityLabel(s.riscaldamento ? Text("Serie di riscaldamento") : Text("Serie \(numero + 1)"))
                .accessibilityValue(s.fatta ? Text("fatta") : Text("da fare"))
                .accessibilityHint(s.fatta ? Text(verbatim: "") : Text("Segna la serie e fa partire il recupero"))
            }
            .listRowBackground(s.fatta ? Color.green.opacity(0.14) : nil)
            .sensoryFeedback(.success, trigger: s.fatta) { _, nuovo in nuovo }
            .sensoryFeedback(.error, trigger: errore)
            .swipeActions {
                Button("Elimina", systemImage: "trash", role: .destructive) {
                    palestra.stato.inCorso?.esercizi[i].serie.remove(at: j)
                }
            }
            .onAppear {
                guard !caricato else { return }
                caricato = true
                kg = s.kg.map { num($0) } ?? ""
                rip = s.rip.map(String.init) ?? ""
            }
        }
    }

    // Il testo della serie precedente è un pulsante: copia kg e ripetizioni nei campi, senza spuntare
    @ViewBuilder
    private func ultimaVolta(_ prec: SerieFatta?, fatta: Bool) -> some View {
        let testo = prec.map { "\(num($0.kg ?? 0)) kg × \($0.rip ?? 0)" } ?? "–"
        let etichetta = Text(verbatim: testo)
            .font(.caption)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
        if let v = UltimaVolta.valori(da: prec), !fatta {
            Button {
                if let k = v.kg { kg = num(k) }
                if let r = v.rip { rip = String(r) }
            } label: { etichetta.contentShape(.rect) }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
            .accessibilityLabel(Text("Usa i valori dell'ultima volta"))
            .accessibilityValue(Text(verbatim: testo))
        } else {
            etichetta.foregroundStyle(.secondary)
        }
    }

    private func cella(testo: Binding<String>, segnaposto: String, tastiera: UIKeyboardType, larghezza: CGFloat, quale: EsitoSpunta.Campo) -> some View {
        TextField(segnaposto, text: testo)
            .keyboardType(tastiera)
            .multilineTextAlignment(.center)
            .font(.body.weight(.semibold).monospacedDigit())
            .padding(.vertical, 6)
            .frame(width: larghezza)
            .background(.fill.tertiary, in: .rect(cornerRadius: 8))
            .focused(campo, equals: PuntoDiFocus(serie: idSerie, campo: quale))
    }

    private func modifica(_ cambia: (inout SerieFatta) -> Void) {
        guard let p = posizione, var s = palestra.stato.inCorso?.esercizi[p.0].serie[p.1] else { return }
        cambia(&s)
        palestra.stato.inCorso?.esercizi[p.0].serie[p.1] = s
    }

    // Spunta: i campi vuoti prendono i valori della serie precedente (a corpo libero i kg vuoti valgono 0);
    // se manca qualcosa il cursore va nel campo da compilare. Togliere la spunta ferma il recupero che aveva fatto partire
    private func segna(_ s: SerieFatta, _ prec: SerieFatta?, _ recupero: Int, corpoLibero: Bool) {
        if s.fatta {
            modifica { $0.fatta = false }
            timer.fermaSeAvviatoDa(s.id)
            return
        }
        switch EsitoSpunta.valuta(kg: s.kg, rip: s.rip, precedente: prec, corpoLibero: corpoLibero) {
        case .manca(let quale):
            errore += 1
            campo.wrappedValue = PuntoDiFocus(serie: idSerie, campo: quale)
        case .segna(let k, let r):
            modifica {
                $0.kg = k
                $0.rip = r
                $0.fatta = true
            }
            kg = num(k)
            rip = String(r)
            campo.wrappedValue = nil
            // L'ultima serie spuntata non chiude subito l'esercizio: resta aperto finché la chiusura ritardata lo chiude
            if palestra.stato.inCorso?.esercizi.first(where: { $0.id == idEsercizio }).map(PercorsoAllenamento.completo) == true {
                riaperti.insert(idEsercizio)
            }
            timer.avvia(recupero, serie: s.id)
        }
    }
}

// Recupero in corso dentro l'allenamento (la tab bar qui è nascosta)
struct TimerInAllenamento: View {
    @Environment(TimerRecupero.self) private var timer

    var body: some View {
        if let fine = timer.fine, timer.attivo {
            HStack(spacing: 12) {
                Image(systemName: "timer").foregroundStyle(.tint).symbolEffect(.pulse)
                Text(timerInterval: Date()...fine, countsDown: true)
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.tint)
                Spacer()
                Button("−15") { timer.cambia(-15) }.pulsanteVetro()
                Button("+15") { timer.cambia(15) }.pulsanteVetro()
                Button("Salta") { timer.ferma() }.pulsanteVetro(evidente: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .modifier(SfondoVetro())
            .padding(.horizontal, 12)
            .padding(.bottom, 4)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

// Vetro Liquid Glass su iOS 26, materiale sfocato prima
struct SfondoVetro: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: .capsule)
        } else {
            content.background(.regularMaterial, in: .capsule)
        }
    }
}

// Icona di un esercizio: pittogramma se c'è, altrimenti il simbolo del muscolo
struct IconaEsercizio: View {
    let esercizio: Esercizio
    var lato: CGFloat = 40

    var body: some View {
        Group {
            if let f = Figura.esercizi[esercizio.id] {
                Pittogramma(figura: f, lato: lato * 0.85)
            } else {
                Image(systemName: esercizio.muscolo.simbolo)
                    .font(.system(size: lato * 0.45))
                    .foregroundStyle(.tint)
            }
        }
        .frame(width: lato, height: lato)
        .background(.tint.opacity(0.12), in: .circle)
    }
}
