import SwiftUI

// Allenamento in corso: un registro compatto su un unico sfondo. In alto durata e serie; per ogni esercizio
// la tabella delle serie (precedente, kg, ripetizioni, spunta); la spunta fa partire il recupero.
// La serie «attiva» (la prossima da fare, vedi SerieAttiva) ha sotto i ± per kg e ripetizioni e, se esce dalla vista
// (testo grande, esercizio appena finito), la schermata scorre fino a lei.
// Verde solo per «Fine» e per le serie fatte.
struct AllenamentoInCorsoView: View {
    @Environment(Palestra.self) private var palestra
    @Environment(TimerRecupero.self) private var timer
    @Environment(Navigazione.self) private var navigazione
    @Environment(\.dynamicTypeSize) private var dimensione
    @State private var aggiungi = false
    @State private var chiediFine = false
    @State private var chiediSenzaSerie = false
    @State private var chiediAnnulla = false
    @State private var senzaSpunta = 0   // serie che si perdono finendo (per la conferma)
    @State private var riaperti: Set<UUID> = []   // esercizi finiti che restano aperti: riaperti a mano o appena finiti
    @State private var chiusure: [UUID: Task<Void, Never>] = [:]   // chiusura in attesa, per esercizio
    @State private var riferimento: UUID?   // l'ultima serie spuntata o toccata: da lei si cerca la serie attiva
    @State private var visibili: Set<UUID> = []   // serie che si vedono per intero
    @State private var passo: RichiestaPasso?   // ± della barra sopra la tastiera, per la serie che ha il cursore
    @FocusState private var campo: PuntoDiFocus?

    var body: some View {
        NavigationStack {
            if let a = palestra.stato.inCorso {
                let attiva = SerieAttiva.trova(in: a.esercizi, riferimento: riferimento)
                ScrollViewReader { scorri in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        testata(a)
                        RigaRiscaldamento()
                        ForEach(a.esercizi) { e in
                            Divider()
                            SezioneEsercizioInCorso(idEsercizio: e.id, attiva: attiva, campo: $campo, riaperti: $riaperti,
                                                    riferimento: $riferimento, visibili: $visibili, passo: passo)
                                .id(e.id)
                        }
                        Divider()
                        piede
                    }
                    .padding(.horizontal, Spazio.l)
                    // Su schermi larghi (iPhone in orizzontale, iPhone Duo aperto) il registro resta a larghezza leggibile
                    .frame(maxWidth: 640)
                    .frame(maxWidth: .infinity)
                }
                .background(Color(.systemBackground), ignoresSafeAreaEdges: .all)
                .onChange(of: a.esercizi.filter(PercorsoAllenamento.completo).map(\.id)) { prima, ora in
                    // Un esercizio tornato incompleto si riapre da solo e la sua chiusura in attesa salta
                    riaperti.formIntersection(ora)
                    for (id, compito) in chiusure where !ora.contains(id) {
                        compito.cancel()
                        chiusure[id] = nil
                    }
                    // Uno appena finito resta aperto un attimo (per annullare una spunta sbagliata), poi si chiude e porta alla serie attiva
                    guard let finito = PercorsoAllenamento.appenaFinito(prima: prima, ora: ora) else { return }
                    riaperti.insert(finito)
                    chiusure[finito]?.cancel()
                    chiusure[finito] = Task {
                        try? await Task.sleep(for: PercorsoAllenamento.ritardoChiusura)
                        guard !Task.isCancelled,
                              let esercizi = palestra.stato.inCorso?.esercizi,
                              PercorsoAllenamento.siChiudeDopoIlRitardo(finito, in: esercizi) else { return }
                        chiusure[finito] = nil
                        withAnimation(.smooth) { _ = riaperti.remove(finito) }
                        try? await Task.sleep(for: .milliseconds(400))   // il tempo di chiudersi e di aggiornare le serie visibili
                        mostraAttiva(scorri)
                    }
                }
                .onChange(of: attiva) {
                    // Aspetta che l'eventuale chiusura di un esercizio appena finito sia registrata
                    Task {
                        try? await Task.sleep(for: .milliseconds(80))
                        mostraAttiva(scorri)
                    }
                }
                .onChange(of: campo) { _, c in
                    if let c { riferimento = c.serie }
                }
                .task {
                    // All'apertura: se la prossima serie da fare è fuori dalla vista (testo grande), ci si va
                    try? await Task.sleep(for: .milliseconds(350))
                    mostraAttiva(scorri, animato: false)
                }
                .navigationTitle(a.titolo)
                .navigationBarTitleDisplayMode(.inline)
                .scrollDismissesKeyboard(.interactively)
                .toolbar { barra(a) }
                .safeAreaInset(edge: .bottom) { TimerInAllenamento() }
                .sheet(isPresented: $aggiungi) {
                    LibreriaView(modo: .scelta { ids in palestra.aggiungi(esercizi: ids) })
                        .tint(Colori.accento)   // il foglio è un'altra schermata: tiene il suo tema
                }
                .confirmationDialog("Finire l'allenamento?", isPresented: $chiediFine, titleVisibility: .visible) {
                    Button("Finisci e salva") { finisci() }
                    Button("Continua", role: .cancel) {}
                } message: {
                    Text("\(senzaSpunta) serie senza spunta non verranno salvate.")
                }
                .confirmationDialog("Nessuna serie spuntata: chiudere senza salvare?", isPresented: $chiediSenzaSerie, titleVisibility: .visible) {
                    Button("Chiudi", role: .destructive) { annulla() }
                    Button("Continua", role: .cancel) {}
                }
                .confirmationDialog("Annullare l'allenamento?", isPresented: $chiediAnnulla, titleVisibility: .visible) {
                    Button("Annulla allenamento", role: .destructive) { annulla() }
                } message: {
                    Text("Le serie di questo allenamento non vengono salvate.")
                }
                }
            }
        }
        // Barra, menu e testi in nero/bianco: il verde resta a «Fine» e alle serie fatte
        .tint(.primary)
    }

    // Porta la serie attiva nella vista, se non si vede già per intero. Non si muove mentre si scrive
    // o mentre un esercizio appena finito aspetta di chiudersi
    private func mostraAttiva(_ scorri: ScrollViewProxy, animato: Bool = true) {
        guard campo == nil, chiusure.isEmpty,
              let id = SerieAttiva.trova(in: palestra.stato.inCorso?.esercizi ?? [], riferimento: riferimento),
              !visibili.contains(id) else { return }
        // Un po' sotto il bordo alto: sopra resta il nome dell'esercizio
        let punto = UnitPoint(x: 0.5, y: 0.3)
        if animato {
            withAnimation(.smooth) { scorri.scrollTo(id, anchor: punto) }
        } else {
            scorri.scrollTo(id, anchor: punto)
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
            // Sempre attivo: senza serie fatte chiede se chiudere senza salvare; con serie non spuntate dice quante se ne perdono
            Button("Fine") {
                senzaSpunta = a.esercizi.flatMap(\.serie).filter { !$0.fatta }.count
                if a.serieFatte == 0 {
                    chiediSenzaSerie = true
                } else if senzaSpunta > 0 {
                    chiediFine = true
                } else {
                    finisci()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Colori.accento)
        }
        // Sopra la tastiera: ± del campo che ha il cursore e «Chiudi» (non «Fine», che è già nella barra in alto)
        ToolbarItemGroup(placement: .keyboard) {
            if let c = campo {
                Button { passo = RichiestaPasso(punto: c, su: false) } label: { TestiPasso.etichetta(c.campo, su: false) }
                    .accessibilityLabel(TestiPasso.voce(c.campo, su: false))
                Button { passo = RichiestaPasso(punto: c, su: true) } label: { TestiPasso.etichetta(c.campo, su: true) }
                    .accessibilityLabel(TestiPasso.voce(c.campo, su: true))
            }
            Spacer()
            Button("Chiudi") { campo = nil }
        }
    }

    // Durata a sinistra, serie fatte (e kg, a testo normale) a destra: una riga sola anche a testo grande;
    // solo se non ci sta (allenamento oltre l'ora a testo massimo) le serie vanno sotto, mai troncate
    private func testata(_ a: Allenamento) -> some View {
        let durata = Group {
            // Sessione del Watch completata dopo: durata fissa; altrimenti cronometro
            if a.fine != nil { Text(durataTesto(a.durata)) }
            else { Text(timerInterval: a.inizio...Date.distantFuture, countsDown: false) }
        }
        .numero(.title2)
        .foregroundStyle(.primary)
        .fixedSize()
        .accessibilityLabel(Text("Durata"))
        let totali = Group {
            if dimensione.isAccessibilitySize {
                Text("\(a.serieFatte) serie")
            } else {
                Text("\(volumeTesto(a.volume)) · \(a.serieFatte) serie")
            }
        }
        .numero(.subheadline)
        .foregroundStyle(.secondary)
        .fixedSize()
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: Spazio.m) {
                durata
                Spacer(minLength: Spazio.s)
                totali
            }
            VStack(alignment: .leading, spacing: 0) {
                durata
                totali
            }
        }
        .frame(minHeight: Misure.tocco)
    }

    private var piede: some View {
        Button {
            aggiungi = true
        } label: {
            Label("Aggiungi esercizio", systemImage: "plus")
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: Misure.tocco)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .padding(.top, Spazio.l)
        .padding(.bottom, Spazio.xl)
    }

    private func annulla() {
        timer.ferma()
        campo = nil
        palestra.annulla()
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

// Un tocco su ± nella barra sopra la tastiera: lo esegue la riga che ha il cursore (i testi dei campi sono suoi)
struct RichiestaPasso: Equatable {
    let id = UUID()
    let punto: PuntoDiFocus
    let su: Bool
}

// Testi dei pulsanti ±: con l'unità sullo schermo, a parole per VoiceOver
enum TestiPasso {
    static func etichetta(_ campo: EsitoSpunta.Campo, su: Bool) -> Text {
        switch (campo, su) {
        case (.kg, true): Text("+\(num(PassoSerie.kg)) kg")
        case (.kg, false): Text("−\(num(PassoSerie.kg)) kg")
        case (.rip, true): Text("+\(PassoSerie.rip) rip")
        case (.rip, false): Text("−\(PassoSerie.rip) rip")
        }
    }

    static func voce(_ campo: EsitoSpunta.Campo, su: Bool) -> Text {
        switch (campo, su) {
        case (.kg, true): Text("Aggiungi \(num(PassoSerie.kg)) kg")
        case (.kg, false): Text("Togli \(num(PassoSerie.kg)) kg")
        case (.rip, true): Text("Una ripetizione in più")
        case (.rip, false): Text("Una ripetizione in meno")
        }
    }
}

// Riscaldamento dei giorni di pesi: una riga di 44 pt «Riscaldamento 3/6» che si apre sui movimenti.
// Se il nome non ci sta (testo molto grande) restano icona e conteggio
struct RigaRiscaldamento: View {
    @Environment(Palestra.self) private var palestra
    @State private var aperto = false

    var body: some View {
        let fatti = palestra.stato.inCorso?.riscaldamento ?? [:]
        let conteggio = "\(fatti.values.filter { $0 }.count)/\(Libreria.riscaldamento.count)"
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.smooth) { aperto.toggle() }
            } label: {
                ViewThatFits(in: .horizontal) {
                    riga(conteggio, conNome: true)
                    riga(conteggio, conNome: false)
                }
                .frame(minHeight: Misure.tocco)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Riscaldamento"))
            .accessibilityValue(Text(verbatim: conteggio))
            .accessibilityAddTraits(.isButton)
            if aperto {
                ForEach(Array(Libreria.riscaldamento.enumerated()), id: \.offset) { i, voce in
                    RigaSpunta(fatto: fatti[String(i)] == true, azione: {
                        palestra.stato.inCorso?.riscaldamento[String(i)] = !(fatti[String(i)] == true)
                    }) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(voce.0).font(.subheadline.weight(.semibold))
                            Text(voce.1).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, Spazio.xs)
                }
                .padding(.bottom, Spazio.s)
            }
        }
    }

    private func riga(_ conteggio: String, conNome: Bool) -> some View {
        HStack(spacing: Spazio.s) {
            Image(systemName: "figure.cooldown").foregroundStyle(.secondary)
            if conNome {
                Text("Riscaldamento").fontWeight(.semibold).fixedSize()
            }
            Text(verbatim: conteggio).numero(.subheadline).foregroundStyle(.secondary).fixedSize()
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(aperto ? 90 : 0))
        }
        .font(.subheadline)
    }
}

// Colonne della tabella delle serie, uguali per intestazione e righe. Con il testo molto grande ogni serie va su due righe
// (numero e precedente sopra; kg, ripetizioni e spunta sotto) e l'intestazione non si mostra
struct ColonneSerie<Numero: View, Precedente: View, Kg: View, Rip: View, Spunta: View>: View {
    @Environment(\.dynamicTypeSize) private var dimensione
    let conPrecedente: Bool
    @ViewBuilder let numero: Numero
    @ViewBuilder let precedente: Precedente
    @ViewBuilder let kg: Kg
    @ViewBuilder let rip: Rip
    @ViewBuilder let spunta: Spunta

    static var spazio: CGFloat { Spazio.s }
    static var numero: CGFloat { 32 }

    var body: some View {
        if dimensione.isAccessibilitySize {
            VStack(alignment: .leading, spacing: Spazio.xs) {
                HStack(spacing: Self.spazio) {
                    numero.frame(minWidth: Self.numero, alignment: .leading)
                    precedente.frame(maxWidth: .infinity, alignment: .leading)
                }
                // Campi con l'unità accanto: oltre accessibility3 il testo non cresce più, se no «37,5» non ci sta
                HStack(spacing: Self.spazio) {
                    kg.frame(maxWidth: .infinity)
                    rip.frame(maxWidth: .infinity)
                    spunta.frame(minWidth: Misure.tocco)
                }
                .dynamicTypeSize(...DynamicTypeSize.accessibility3)
            }
        } else {
            HStack(spacing: Self.spazio) {
                numero.frame(width: Self.numero)
                // Senza serie precedenti la colonna resta stretta e lo spazio va ai campi
                precedente.frame(maxWidth: conPrecedente ? .infinity : 20)
                kg.frame(maxWidth: conPrecedente ? 72 : .infinity)
                rip.frame(maxWidth: conPrecedente ? 60 : .infinity)
                spunta.frame(width: Misure.tocco)
            }
        }
    }
}

struct SezioneEsercizioInCorso: View {
    @Environment(Palestra.self) private var palestra
    @Environment(\.dynamicTypeSize) private var dimensione
    let idEsercizio: UUID
    let attiva: UUID?
    var campo: FocusState<PuntoDiFocus?>.Binding
    @Binding var riaperti: Set<UUID>
    @Binding var riferimento: UUID?
    @Binding var visibili: Set<UUID>
    let passo: RichiestaPasso?
    @State private var chiediRimuovi = false

    private var indice: Int? { palestra.stato.inCorso?.esercizi.firstIndex { $0.id == idEsercizio } }

    var body: some View {
        if let i = indice, let e = palestra.stato.inCorso?.esercizi[i] {
            let ex = palestra.esercizio(e.esercizio)
            let inModifica = e.serie.first { $0.id == campo.wrappedValue?.serie }?.id != nil ? e.id : nil
            if PercorsoAllenamento.compresso(e, riaperti: riaperti, inModifica: inModifica) {
                compresso(ex, e)
            } else {
                let conPrecedente = e.serie.indices.contains { j in
                    palestra.precedente(e.esercizio, e.serie[..<j].filter { !$0.riscaldamento }.count) != nil
                }
                VStack(alignment: .leading, spacing: 2) {
                    intestazione(ex, e, i)
                        .padding(.bottom, Spazio.xs)
                    if !dimensione.isAccessibilitySize {
                        ColonneSerie(conPrecedente: conPrecedente) {
                            Text("Serie")
                        } precedente: {
                            if conPrecedente { Text("Precedente") } else { Color.clear.frame(height: 1) }
                        } kg: {
                            Text("Kg")
                        } rip: {
                            Text("rip")
                        } spunta: {
                            Image(systemName: "checkmark")
                        }
                        .font(.caption2.weight(.semibold))
                        .textCase(.uppercase)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .accessibilityHidden(true)
                    }
                    ForEach(e.serie) { s in
                        RigaSerie(idEsercizio: idEsercizio, idSerie: s.id, conPrecedente: conPrecedente, attiva: s.id == attiva,
                                  campo: campo, riaperti: $riaperti, riferimento: $riferimento, passo: passo)
                            .id(s.id)
                            .onScrollVisibilityChange(threshold: 0.9) { visibile in
                                if visibile { visibili.insert(s.id) } else { visibili.remove(s.id) }
                            }
                    }
                    Button {
                        let ultima = e.serie.last
                        palestra.stato.inCorso?.esercizi[i].serie.append(SerieFatta(kg: ultima?.kg, rip: ultima?.rip))
                    } label: {
                        Label("Aggiungi serie", systemImage: "plus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, minHeight: Misure.tocco)
                            .background(.fill.quaternary, in: .rect(cornerRadius: 8))
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, Spazio.xs)
                }
                .padding(.top, Spazio.m)
                .padding(.bottom, Spazio.m)
            }
        }
    }

    // Esercizio finito: una riga di 44 pt con la spunta piena e quante serie; si tocca per riaprirlo
    private func compresso(_ ex: Esercizio, _ e: EsercizioFatto) -> some View {
        let n = PercorsoAllenamento.serieDiLavoro(e)
        return Button {
            withAnimation(.smooth) { _ = riaperti.insert(e.id) }
        } label: {
            HStack(spacing: Spazio.s) {
                CerchioSpunta(fatta: true)
                Text(verbatim: ex.titolo)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(n) serie")
                    .numero(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize()
                Image(systemName: "chevron.down").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            .padding(.trailing, Spazio.m)
            .frame(minHeight: Misure.tocco)
            .background(Colori.sfondoFatto, in: .rect(cornerRadius: 8))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(ex.titolo): \(n) serie fatte"))
        .accessibilityHint(Text("Tocca per riaprire"))
        .accessibilityAddTraits(.isButton)
        .padding(.vertical, Spazio.s)
    }

    private func intestazione(_ ex: Esercizio, _ e: EsercizioFatto, _ i: Int) -> some View {
        HStack(spacing: Spazio.m) {
            IconaEsercizio(esercizio: ex, lato: 32)
                .tint(.secondary)
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: ex.titolo).font(.headline).foregroundStyle(.primary)
                Text("\(ex.muscolo.nome) · recupero \(e.recupero) s").font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
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
                Image(systemName: "ellipsis")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: Misure.tocco, height: Misure.tocco)
                    .contentShape(.rect)
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
    @Environment(\.dynamicTypeSize) private var dimensione
    let idEsercizio: UUID
    let idSerie: UUID
    let conPrecedente: Bool
    let attiva: Bool
    var campo: FocusState<PuntoDiFocus?>.Binding
    @Binding var riaperti: Set<UUID>
    @Binding var riferimento: UUID?
    let passo: RichiestaPasso?
    @State private var kg = ""
    @State private var rip = ""
    @State private var caricato = false
    @State private var errore = 0
    @State private var manca: EsitoSpunta.Campo?   // campo vuoto alla spunta: contorno e «Scrivi i kg» finché non si scrive

    private var posizione: (Int, Int)? {
        guard let i = palestra.stato.inCorso?.esercizi.firstIndex(where: { $0.id == idEsercizio }),
              let j = palestra.stato.inCorso?.esercizi[i].serie.firstIndex(where: { $0.id == idSerie }) else { return nil }
        return (i, j)
    }

    var body: some View {
        if let p = posizione, let e = palestra.stato.inCorso?.esercizi[p.0] {
            let j = p.1
            let s = e.serie[j]
            let numero = e.serie[..<j].filter { !$0.riscaldamento }.count
            let prec = palestra.precedente(e.esercizio, numero)
            let ex = palestra.esercizio(e.esercizio)
            VStack(alignment: .leading, spacing: Spazio.xs) {
                ColonneSerie(conPrecedente: conPrecedente) {
                    // Il numero apre il menu della serie: riscaldamento ed eliminazione
                    Menu {
                        Toggle("Serie di riscaldamento", isOn: Binding(
                            get: { s.riscaldamento },
                            set: { v in modifica { $0.riscaldamento = v } }
                        ))
                        Button("Elimina", systemImage: "trash", role: .destructive) { elimina() }
                    } label: {
                        Text(verbatim: s.riscaldamento ? String(localized: "R") : "\(numero + 1)")
                            .numero(.subheadline)
                            .foregroundStyle(s.riscaldamento ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                            .frame(minWidth: ColonneSerie<EmptyView, EmptyView, EmptyView, EmptyView, EmptyView>.numero, minHeight: Misure.tocco)
                            .contentShape(.rect)
                    }
                } precedente: {
                    ultimaVolta(prec, fatta: s.fatta)
                } kg: {
                    cella(testo: $kg, segnaposto: prec?.kg.map { num($0) } ?? String(localized: "kg"), tastiera: .decimalPad, quale: .kg)
                        .onChange(of: kg) { _, v in
                            modifica { $0.kg = leggiNumero(v) }
                            if !v.isEmpty, manca == .kg { manca = nil }
                        }
                } rip: {
                    cella(testo: $rip, segnaposto: prec?.rip.map(String.init) ?? String(localized: "rip"), tastiera: .numberPad, quale: .rip)
                        .onChange(of: rip) { _, v in
                            modifica { $0.rip = Int(v) }
                            if !v.isEmpty, manca == .rip { manca = nil }
                        }
                } spunta: {
                    // La vibrazione la fa la riga (.success quando la serie diventa fatta)
                    CerchioSpunta(fatta: s.fatta,
                                  etichetta: s.riscaldamento ? Text("Serie di riscaldamento") : Text("Serie \(numero + 1)"),
                                  stati: ("fatta", "da fare"), vibra: false) {
                        segna(s, prec, e.recupero, titolo: ex.titolo, corpoLibero: ex.attrezzo == .corpoLibero)
                    }
                    .accessibilityHint(s.fatta ? Text(verbatim: "") : Text("Segna la serie e fa partire il recupero"))
                    .accessibilityAction(named: Text("Elimina")) { elimina() }
                }
                .padding(.horizontal, 6)
                .frame(minHeight: Misure.tocco)
                // Serie fatta: tutta la riga prende l'accento, dentro i margini del contenuto
                .background(s.fatta ? Colori.sfondoFatto : .clear, in: .rect(cornerRadius: 8))
                .animation(.smooth(duration: 0.2), value: s.fatta)

                if let manca, !s.fatta {
                    Label(manca == .kg ? "Scrivi i kg" : "Scrivi le ripetizioni", systemImage: "exclamationmark.circle")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 6)
                }
                if attiva, !s.fatta {
                    passi(prec)
                        .padding(.bottom, Spazio.xs)
                        .transition(.opacity)
                }
            }
            .sensoryFeedback(.success, trigger: s.fatta) { _, nuovo in nuovo }
            .sensoryFeedback(.error, trigger: errore)
            .onChange(of: passo) { _, richiesta in
                guard let richiesta, richiesta.punto.serie == idSerie else { return }
                applica(richiesta.punto.campo, su: richiesta.su, prec: prec)
            }
            .onAppear {
                guard !caricato else { return }
                caricato = true
                kg = s.kg.map { num($0) } ?? ""
                rip = s.rip.map(String.init) ?? ""
            }
        }
    }

    // ± senza tastiera sotto la serie attiva: kg a sinistra, ripetizioni a destra (su due righe se non ci stanno)
    private func passi(_ prec: SerieFatta?) -> some View {
        let kgMeno = pulsantePasso(.kg, su: false, prec: prec)
        let kgPiu = pulsantePasso(.kg, su: true, prec: prec)
        let ripMeno = pulsantePasso(.rip, su: false, prec: prec)
        let ripPiu = pulsantePasso(.rip, su: true, prec: prec)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: Spazio.s) {
                kgMeno; kgPiu
                Spacer(minLength: Spazio.m)
                ripMeno; ripPiu
            }
            // Testo molto grande: due righe, i pulsanti si dividono la larghezza
            VStack(alignment: .leading, spacing: Spazio.xs) {
                HStack(spacing: Spazio.s) {
                    pulsantePasso(.kg, su: false, prec: prec, largo: true)
                    pulsantePasso(.kg, su: true, prec: prec, largo: true)
                }
                HStack(spacing: Spazio.s) {
                    pulsantePasso(.rip, su: false, prec: prec, largo: true)
                    pulsantePasso(.rip, su: true, prec: prec, largo: true)
                }
            }
        }
        .padding(.horizontal, 6)
    }

    // `largo`: occupa la sua parte di riga e rimpicciolisce il testo se serve (mai troncato)
    private func pulsantePasso(_ quale: EsitoSpunta.Campo, su: Bool, prec: SerieFatta?, largo: Bool = false) -> some View {
        Button {
            applica(quale, su: su, prec: prec)
        } label: {
            TestiPasso.etichetta(quale, su: su)
                .numero(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(largo ? 0.6 : 1)
                .fixedSize(horizontal: !largo, vertical: false)
                .padding(.horizontal, Spazio.m)
                .frame(maxWidth: largo ? .infinity : nil)
                .frame(minHeight: 36)
                .background(.fill.tertiary, in: .capsule)
                .frame(minHeight: Misure.tocco)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(TestiPasso.voce(quale, su: su))
    }

    private func applica(_ quale: EsitoSpunta.Campo, su: Bool, prec: SerieFatta?) {
        riferimento = idSerie
        switch quale {
        case .kg: kg = num(PassoSerie.kg(kg, base: prec?.kg, delta: su ? PassoSerie.kg : -PassoSerie.kg))
        case .rip: rip = String(PassoSerie.rip(rip, base: prec?.rip, delta: su ? PassoSerie.rip : -PassoSerie.rip))
        }
    }

    // Il testo della serie precedente è un pulsante: copia kg e ripetizioni nei campi, senza spuntare
    @ViewBuilder
    private func ultimaVolta(_ prec: SerieFatta?, fatta: Bool) -> some View {
        let breve = prec.map { "\(num($0.kg ?? 0)) × \($0.rip ?? 0)" } ?? "–"
        let completo = prec.map { "\(num($0.kg ?? 0)) kg × \($0.rip ?? 0)" } ?? "–"
        let etichetta = Text(verbatim: breve)
            .font(.numero(.footnote))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(maxWidth: .infinity, minHeight: Misure.tocco)
        if let v = UltimaVolta.valori(da: prec), !fatta {
            Button {
                if let k = v.kg { kg = num(k) }
                if let r = v.rip { rip = String(r) }
            } label: { etichetta.contentShape(.rect) }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .accessibilityLabel(Text("Usa i valori dell'ultima volta"))
            .accessibilityValue(Text(verbatim: completo))
        } else {
            etichetta
                .foregroundStyle(prec == nil ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.secondary))
                .accessibilityLabel(Text("Ultima volta"))
                .accessibilityValue(Text(verbatim: completo))
        }
    }

    // Campo di kg o ripetizioni. A testo molto grande l'unità si scrive accanto (l'intestazione della tabella non c'è)
    private func cella(testo: Binding<String>, segnaposto: String, tastiera: UIKeyboardType, quale: EsitoSpunta.Campo) -> some View {
        HStack(spacing: Spazio.xs) {
            TextField(segnaposto, text: testo)
                .keyboardType(tastiera)
                .multilineTextAlignment(.center)
                .font(.numero(.callout))
                .padding(.vertical, 6)
                .padding(.horizontal, Spazio.xs)
                .frame(minHeight: 36)
                .background(.fill.tertiary, in: .rect(cornerRadius: 7))
                .overlay {
                    if manca == quale {
                        RoundedRectangle(cornerRadius: 7).strokeBorder(Colori.oltre, lineWidth: 2)
                    }
                }
                .focused(campo, equals: PuntoDiFocus(serie: idSerie, campo: quale))
            if dimensione.isAccessibilitySize {
                Text(quale == .kg ? "kg" : "rip").font(.callout).foregroundStyle(.secondary).fixedSize()
            }
        }
    }

    private func modifica(_ cambia: (inout SerieFatta) -> Void) {
        guard let p = posizione, var s = palestra.stato.inCorso?.esercizi[p.0].serie[p.1] else { return }
        cambia(&s)
        palestra.stato.inCorso?.esercizi[p.0].serie[p.1] = s
    }

    private func elimina() {
        guard let p = posizione else { return }
        if campo.wrappedValue?.serie == idSerie { campo.wrappedValue = nil }
        timer.fermaSeAvviatoDa(idSerie)
        palestra.stato.inCorso?.esercizi[p.0].serie.remove(at: p.1)
    }

    // Spunta: i campi vuoti prendono i valori della serie precedente (a corpo libero i kg vuoti valgono 0);
    // se manca qualcosa lo dice sotto la riga e il cursore va nel campo da compilare. Togliere la spunta ferma il recupero che aveva fatto partire
    private func segna(_ s: SerieFatta, _ prec: SerieFatta?, _ recupero: Int, titolo: String, corpoLibero: Bool) {
        riferimento = idSerie
        palestra.ultimaSerie = idSerie   // anche la Live Activity parte da questa serie
        if s.fatta {
            modifica { $0.fatta = false }
            timer.fermaSeAvviatoDa(s.id)
            return
        }
        switch EsitoSpunta.valuta(kg: s.kg, rip: s.rip, precedente: prec, corpoLibero: corpoLibero) {
        case .manca(let quale):
            errore += 1
            withAnimation(.smooth(duration: 0.2)) { manca = quale }
            campo.wrappedValue = PuntoDiFocus(serie: idSerie, campo: quale)
        case .segna(let k, let r):
            manca = nil
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
            timer.avvia(recupero, serie: s.id, esercizio: titolo)
        }
    }
}

// Recupero in corso dentro l'allenamento (la tab bar qui è nascosta): «Recupero», conto alla rovescia grande,
// barra che si riempie, −15 s / +15 s / Salta. Resta nell'area sicura (anche con la colonna di sistema laterale);
// a testo molto grande i pulsanti vanno sotto il conto alla rovescia
struct TimerInAllenamento: View {
    @Environment(TimerRecupero.self) private var timer

    var body: some View {
        if let stato = timer.stato, timer.attivo {
            VStack(alignment: .leading, spacing: Spazio.s) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Spazio.m) {
                        conto(stato)
                        Spacer(minLength: Spazio.s)
                        pulsanti
                    }
                    VStack(alignment: .leading, spacing: Spazio.s) {
                        conto(stato)
                        HStack(spacing: Spazio.s) { pulsanti }
                    }
                }
                ProgressView(timerInterval: stato.inizio...stato.fine, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .progressViewStyle(.linear)
                .tint(.secondary)
                .accessibilityHidden(true)
            }
            .padding(.horizontal, Spazio.l)
            .padding(.vertical, Spazio.m)
            .modifier(SfondoVetro())
            .frame(maxWidth: 640)
            .padding(.horizontal, Spazio.m)
            .padding(.bottom, Spazio.xs)
            .frame(maxWidth: .infinity)
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func conto(_ stato: StatoRecupero) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recupero").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Text(timerInterval: Date()...stato.fine, countsDown: true)
                .numero(.title2)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .fixedSize()
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var pulsanti: some View {
        Button { timer.cambia(-15) } label: { Text(verbatim: "−15 s").numero(.subheadline).fixedSize() }
            .pulsanteVetro()
            .accessibilityLabel(Text("15 secondi in meno"))
        Button { timer.cambia(15) } label: { Text(verbatim: "+15 s").numero(.subheadline).fixedSize() }
            .pulsanteVetro()
            .accessibilityLabel(Text("15 secondi in più"))
        Button { timer.ferma() } label: { Text("Salta").font(.subheadline.weight(.semibold)).fixedSize() }
            .pulsanteVetro()
    }
}

// Vetro Liquid Glass su iOS 26, materiale sfocato prima. Rettangolo arrotondato: a testo grande il recupero va su due righe
struct SfondoVetro: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: .rect(cornerRadius: Spazio.xl, style: .continuous))
        } else {
            content.background(.regularMaterial, in: .rect(cornerRadius: Spazio.xl, style: .continuous))
        }
    }
}

// Icona di un esercizio: pittogramma se c'è, altrimenti il simbolo del muscolo
struct IconaEsercizio: View {
    let esercizio: Esercizio
    // Il cerchio e il simbolo crescono con il testo grande
    private let base: CGFloat
    @ScaledMetric(relativeTo: .body) private var scala: CGFloat = 1
    private var lato: CGFloat { base * min(scala, 1.6) }

    init(esercizio: Esercizio, lato: CGFloat = 40) {
        self.esercizio = esercizio
        self.base = lato
    }

    var body: some View {
        Group {
            if let f = Figura.esercizi[esercizio.id] {
                Pittogramma(figura: f, lato: lato * 0.85)
            } else {
                Image(systemName: esercizio.muscolo.simbolo)
                    .font(.system(size: lato * 0.45))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: lato, height: lato)
        .background(Color.secondary.opacity(0.12), in: .circle)
    }
}
