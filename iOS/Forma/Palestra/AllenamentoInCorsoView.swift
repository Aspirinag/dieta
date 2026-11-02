import SwiftUI

// Allenamento in corso (come Hevy): per ogni esercizio la tabella delle serie con la serie precedente,
// kg, ripetizioni e la spunta; la spunta fa partire il recupero
struct AllenamentoInCorsoView: View {
    @Environment(Palestra.self) private var palestra
    @Environment(TimerRecupero.self) private var timer
    @Environment(Navigazione.self) private var navigazione
    @State private var aggiungi = false
    @State private var chiediFine = false
    @State private var chiediAnnulla = false
    @FocusState private var campo: String?

    var body: some View {
        NavigationStack {
            if let a = palestra.stato.inCorso {
                List {
                    statistiche(a)
                    SezioneRiscaldamento()
                    ForEach(a.esercizi) { e in
                        SezioneEsercizioInCorso(idEsercizio: e.id, campo: $campo)
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
                .navigationTitle(a.nome)
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

    @ToolbarContentBuilder
    private func barra(_ a: Allenamento) -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Riduci", systemImage: "chevron.down") { navigazione.allenamentoAperto = false }
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
            HStack {
                dato("Durata") { Text(timerInterval: a.inizio...Date.distantFuture, countsDown: false).monospacedDigit() }
                dato("Volume") { Text(volumeTesto(a.volume)) }
                dato("Serie") { Text("\(a.serieFatte)") }
            }
        }
    }

    private func dato<V: View>(_ titolo: String, @ViewBuilder _ valore: () -> V) -> some View {
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
    var campo: FocusState<String?>.Binding

    private var indice: Int? { palestra.stato.inCorso?.esercizi.firstIndex { $0.id == idEsercizio } }

    var body: some View {
        if let i = indice, let e = palestra.stato.inCorso?.esercizi[i] {
            let ex = palestra.esercizio(e.esercizio)
            Section {
                intestazione(ex, e, i)
                HStack(spacing: 8) {
                    Text("SERIE").frame(width: 36)
                    Text("PRECEDENTE").frame(maxWidth: .infinity)
                    Text("KG").frame(width: 64)
                    Text("RIP").frame(width: 52)
                    Image(systemName: "checkmark").frame(width: 32)
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                ForEach(e.serie) { s in
                    RigaSerie(idEsercizio: idEsercizio, idSerie: s.id, campo: campo)
                }
                Button("Aggiungi serie", systemImage: "plus") {
                    let ultima = e.serie.last
                    palestra.stato.inCorso?.esercizi[i].serie.append(SerieFatta(kg: ultima?.kg, rip: ultima?.rip))
                }
                .font(.subheadline.weight(.semibold))
            }
        }
    }

    private func intestazione(_ ex: Esercizio, _ e: EsercizioFatto, _ i: Int) -> some View {
        HStack(spacing: 12) {
            IconaEsercizio(esercizio: ex)
            VStack(alignment: .leading, spacing: 2) {
                Text(ex.nome).font(.headline)
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
                Button("Rimuovi esercizio", systemImage: "trash", role: .destructive) {
                    palestra.stato.inCorso?.esercizi.remove(at: i)
                }
            } label: {
                Image(systemName: "ellipsis.circle").font(.title3)
            }
        }
    }
}

struct RigaSerie: View {
    @Environment(Palestra.self) private var palestra
    @Environment(TimerRecupero.self) private var timer
    let idEsercizio: UUID
    let idSerie: UUID
    var campo: FocusState<String?>.Binding
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
                    Text(s.riscaldamento ? "R" : "\(numero + 1)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(s.riscaldamento ? AnyShapeStyle(.orange) : AnyShapeStyle(.primary))
                        .frame(width: 36)
                }
                Text(prec.map { "\(num($0.kg ?? 0)) kg × \($0.rip ?? 0)" } ?? "–")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                cella(testo: $kg, segnaposto: prec?.kg.map { num($0) } ?? "kg", tastiera: .decimalPad, larghezza: 64)
                    .onChange(of: kg) { _, v in modifica { $0.kg = leggiNumero(v) } }
                cella(testo: $rip, segnaposto: prec?.rip.map(String.init) ?? "rip", tastiera: .numberPad, larghezza: 52)
                    .onChange(of: rip) { _, v in modifica { $0.rip = Int(v) } }
                Button {
                    segna(s, prec, e.recupero)
                } label: {
                    Image(systemName: s.fatta ? "checkmark.square.fill" : "square")
                        .font(.title2)
                        .foregroundStyle(s.fatta ? AnyShapeStyle(.green) : AnyShapeStyle(.secondary))
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
                .frame(width: 32)
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

    private func cella(testo: Binding<String>, segnaposto: String, tastiera: UIKeyboardType, larghezza: CGFloat) -> some View {
        TextField(segnaposto, text: testo)
            .keyboardType(tastiera)
            .multilineTextAlignment(.center)
            .font(.body.weight(.semibold).monospacedDigit())
            .padding(.vertical, 6)
            .frame(width: larghezza)
            .background(.fill.tertiary, in: .rect(cornerRadius: 8))
            .focused(campo, equals: "\(idSerie)-\(larghezza)")
    }

    private func modifica(_ cambia: (inout SerieFatta) -> Void) {
        guard let p = posizione, var s = palestra.stato.inCorso?.esercizi[p.0].serie[p.1] else { return }
        cambia(&s)
        palestra.stato.inCorso?.esercizi[p.0].serie[p.1] = s
    }

    // Spunta: i campi vuoti prendono i valori della serie precedente; poi parte il recupero
    private func segna(_ s: SerieFatta, _ prec: SerieFatta?, _ recupero: Int) {
        if s.fatta {
            modifica { $0.fatta = false }
            return
        }
        let k = s.kg ?? prec?.kg
        let r = s.rip ?? prec?.rip
        guard let k, let r, r > 0 else {
            errore += 1
            return
        }
        modifica {
            $0.kg = k
            $0.rip = r
            $0.fatta = true
        }
        kg = num(k)
        rip = String(r)
        campo.wrappedValue = nil
        timer.avvia(recupero)
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
