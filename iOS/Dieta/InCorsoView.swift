import SwiftUI

// ---------- Schermata a tutto schermo ----------

extension View {
    // L'allenamento in corso copre l'app; si riapre da solo se all'avvio ce n'è uno interrotto
    func schermataAllenamento(schema: ColorScheme) -> some View { modifier(SchermataAllenamento(schema: schema)) }
}

private struct SchermataAllenamento: ViewModifier {
    let schema: ColorScheme
    @Environment(Archivio.self) private var archivio

    func body(content: Content) -> some View {
        @Bindable var a = archivio
        content
            .fullScreenCover(isPresented: $a.allenamentoAperto) {
                InCorsoView { archivio.allenamentoAperto = false }
                    .preferredColorScheme(schema)
            }
            .onChange(of: archivio.profilo.allenamentoInCorso != nil, initial: true) { _, inCorso in
                if inCorso { archivio.allenamentoAperto = true }
            }
    }
}

struct InCorsoView: View {
    let chiudi: () -> Void
    @Environment(Archivio.self) private var archivio
    @Environment(\.palette) private var palette
    @Environment(\.scenePhase) private var fase
    @State private var riepilogo: Riepilogo?
    @State private var chiediTermina = false
    @State private var scegliEsercizio = false
    @State private var messaggio: String?

    var body: some View {
        ZStack {
            palette.fondo.ignoresSafeArea()
            if let riepilogo {
                RiepilogoView(riepilogo: riepilogo, chiudi: chiudi)
            } else if let a = archivio.profilo.allenamentoInCorso {
                contenuto(a)
            } else {
                Color.clear.onAppear { chiudi() }
            }
        }
        .foregroundStyle(palette.testo)
        .font(.georgia())
        .task { _ = await Notifiche.permesso() }
        .onChange(of: fase) { _, nuova in
            if nuova == .active {
                Notifiche.annullaRecupero()
            } else {
                let r = archivio.recupero.rimanenti()
                if r > 0 { Task { await Notifiche.recupero(fra: TimeInterval(r)) } }
            }
        }
        .sheet(isPresented: $scegliEsercizio) { SceltaEsercizio() }
        .alert("Terminare l'allenamento?", isPresented: $chiediTermina) {
            Button("Termina") { riepilogo = archivio.terminaAllenamento() }
            Button("Continua", role: .cancel) {}
        } message: {
            Text("Le serie non segnate non vengono salvate.")
        }
    }

    private func contenuto(_ a: Allenamento) -> some View {
        VStack(spacing: 0) {
            barra(a)
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(a.esercizi.indices, id: \.self) { i in
                        SchedaEsercizio(indice: i, messaggio: $messaggio)
                    }
                    Button {
                        scegliEsercizio = true
                    } label: {
                        Label("Aggiungi esercizio", systemImage: "plus")
                            .font(.georgia(.callout, grassetto: true))
                            .foregroundStyle(palette.testo)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(palette.riempimento, in: .rect(cornerRadius: 14))
                            .contentShape(.rect(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
            .scorrimentoTema()
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 8) {
                if let messaggio {
                    Text(messaggio)
                        .font(.georgia(.subheadline, grassetto: true))
                        .foregroundStyle(palette.suAccento)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(palette.accento, in: .capsule)
                        .task(id: messaggio) {
                            try? await Task.sleep(for: .seconds(3))
                            if self.messaggio == messaggio { self.messaggio = nil }
                        }
                        .accessibilityAddTraits(.updatesFrequently)
                }
                BarraRecupero()
                BannerAnnulla(tipo: .spunta)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }

    private func barra(_ a: Allenamento) -> some View {
        let tempo = VStack(alignment: .leading, spacing: 2) {
            Text(a.routine ?? "Allenamento libero")
                .font(.georgia(.footnote))
                .foregroundStyle(palette.secondario)
            TimelineView(.periodic(from: .now, by: 1)) { c in
                CifreFisse(testo: formatoDurata(c.date.timeIntervalSince(a.dataInizio ?? c.date)), stile: .title2, grassetto: true)
            }
        }
        let riduci = Button(action: chiudi) {
            Label("Riduci", systemImage: "chevron.down")
                .font(.georgia(.callout, grassetto: true))
                .foregroundStyle(palette.testo)
                .padding(.horizontal, 14)
                .frame(minWidth: 44, minHeight: 44)
                .background(palette.riempimento, in: .rect(cornerRadius: 14))
                .contentShape(.rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Chiude la schermata senza terminare: l'allenamento continua")
        let termina = Button {
            chiediTermina = true
        } label: {
            Text("Termina")
                .font(.georgia(.callout, grassetto: true))
                .foregroundStyle(palette.suTasto)
                .padding(.horizontal, 18)
                .frame(minWidth: 44, minHeight: 44)
                .background(palette.tasto, in: .rect(cornerRadius: 14))
                .contentShape(.rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { tempo; Spacer(minLength: 4); riduci; termina }
            VStack(alignment: .leading, spacing: 8) {
                tempo
                HStack(spacing: 8) { riduci; Spacer(minLength: 4); termina }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// ---------- Un esercizio ----------

private struct SchedaEsercizio: View {
    let indice: Int
    @Binding var messaggio: String?
    @Environment(Archivio.self) private var archivio
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var testo
    @ScaledMetric(relativeTo: .body) private var scala = 1.0

    var body: some View {
        if let a = archivio.profilo.allenamentoInCorso, a.esercizi.indices.contains(indice) {
            let e = a.esercizi[indice]
            let prima = archivio.profilo.precedente(e.nome)
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Pittogramma(figura: .per(e.nome), lato: 40)
                    Text(e.nome)
                        .font(.georgia(.headline))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.isHeader)
                    Menu {
                        Button("Aggiungi serie", systemImage: "plus") { archivio.aggiungiSerie(esercizio: indice) }
                        Button("Togli esercizio", systemImage: "trash", role: .destructive) { archivio.togliEsercizio(indice) }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.georgia(.title3))
                            .foregroundStyle(palette.secondario)
                            .frame(width: 44, height: 44)
                            .contentShape(.rect)
                    }
                    .accessibilityLabel("Altro per \(e.nome)")
                }
                CampoNota(nome: e.nome)
                if !testo.aDueLivelli { intestazione }
                // L'identità della riga è della serie, non la sua posizione: togliendone una i campi non passano a un'altra
                ForEach(Array(e.serie.enumerated()), id: \.element.idLocale) { s, dato in
                    RigaSerie(esercizio: indice, serie: s, dato: dato, conta: contaNormali(e, fino: s),
                              precedente: prima.indices.contains(s) ? prima[s] : nil, messaggio: $messaggio)
                }
                Button {
                    archivio.aggiungiSerie(esercizio: indice)
                } label: {
                    Label("Aggiungi serie", systemImage: "plus")
                        .font(.georgia(.subheadline, grassetto: true))
                        .foregroundStyle(palette.testo)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(palette.riempimento, in: .rect(cornerRadius: 12))
                        .contentShape(.rect(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .scheda()
        }
    }

    // Il numero mostrato salta le serie di riscaldamento, come in Hevy
    private func contaNormali(_ e: EsercizioFatto, fino s: Int) -> Int {
        e.serie[0...s].filter { $0.tipo != .riscaldamento }.count
    }

    private var intestazione: some View {
        HStack(spacing: 6) {
            let m = Metriche(scala)
            Text("Serie").frame(width: m.serie)
            Text("Prima").frame(maxWidth: .infinity)
            Text("Kg").frame(width: m.valore)
            Text("Rip.").frame(width: m.valore)
            Color.clear.frame(width: m.spunta, height: 1)
        }
        .font(.georgia(.caption, grassetto: true))
        .foregroundStyle(palette.secondario)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .accessibilityHidden(true)
    }
}

// Larghezze delle colonne: crescono con il testo, senza esagerare (oltre si passa alla riga su due livelli)
private struct Metriche {
    let k: CGFloat
    init(_ scala: CGFloat) { k = min(scala, 1.3) }
    var serie: CGFloat { 40 * k }
    var valore: CGFloat { 66 * k }
    let spunta: CGFloat = 44
}

private struct CampoNota: View {
    let nome: String
    @Environment(Archivio.self) private var archivio
    @Environment(\.palette) private var palette

    var body: some View {
        TextField("", text: Binding(
            get: { archivio.profilo.noteEsercizi[nome] ?? "" },
            set: { archivio.profilo.noteEsercizi[nome] = $0.isEmpty ? nil : $0 }
        ), prompt: Text("Nota").foregroundStyle(palette.secondario), axis: .vertical)
            .font(.georgia(.subheadline))
            .padding(.horizontal, 10)
            .frame(minHeight: 44)
            .background(palette.riempimento, in: .rect(cornerRadius: 10))
            .accessibilityLabel("Nota di \(nome)")
    }
}

private struct RigaSerie: View {
    let esercizio: Int
    let serie: Int
    let dato: SerieFatta
    let conta: Int
    let precedente: SerieFatta?
    @Binding var messaggio: String?
    @Environment(Archivio.self) private var archivio
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var testo
    @ScaledMetric(relativeTo: .body) private var scala = 1.0
    @State private var kg: String
    @State private var rip: String

    init(esercizio: Int, serie: Int, dato: SerieFatta, conta: Int, precedente: SerieFatta?, messaggio: Binding<String?>) {
        self.esercizio = esercizio
        self.serie = serie
        self.dato = dato
        self.conta = conta
        self.precedente = precedente
        _messaggio = messaggio
        _kg = State(initialValue: Self.testoKg(dato))
        _rip = State(initialValue: Self.testoRip(dato))
    }

    // Un kg vuoto non è zero: 0 vale (corpo libero) ma va scritto
    private static func testoKg(_ s: SerieFatta) -> String { s.fatta || s.kg > 0 ? num(s.kg) : "" }
    private static func testoRip(_ s: SerieFatta) -> String { s.ripetizioni > 0 ? String(s.ripetizioni) : "" }

    var body: some View {
        let m = Metriche(scala)
        Group {
            if testo.aDueLivelli {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        tipo.frame(width: m.serie)
                        prima.frame(maxWidth: .infinity, alignment: .leading)
                    }
                    HStack(alignment: .bottom, spacing: 8) {
                        VStack(spacing: 2) { etichetta("Kg"); campoKg }
                        VStack(spacing: 2) { etichetta("Rip."); campoRip }
                        spunta
                    }
                }
            } else {
                HStack(spacing: 6) {
                    tipo.frame(width: m.serie)
                    prima.frame(maxWidth: .infinity)
                    campoKg.frame(width: m.valore)
                    campoRip.frame(width: m.valore)
                    spunta
                }
            }
        }
        // Se i valori cambiano sotto (annulla) i campi li seguono; il cambio di tipo non li tocca
        .onChange(of: dato.kg) { _, _ in kg = Self.testoKg(dato) }
        .onChange(of: dato.ripetizioni) { _, _ in rip = Self.testoRip(dato) }
        .onChange(of: dato.fatta) { _, _ in
            kg = Self.testoKg(dato)
            rip = Self.testoRip(dato)
        }
    }

    private func etichetta(_ t: String) -> some View {
        Text(t).font(.georgia(.caption, grassetto: true)).foregroundStyle(palette.secondario).accessibilityHidden(true)
    }

    private var tipo: some View {
        Menu {
            ForEach(TipoSerie.allCases, id: \.self) { t in
                Button(t.nome) { archivio.cambiaTipo(esercizio: esercizio, serie: serie, t) }
            }
            Button("Togli serie", systemImage: "trash", role: .destructive) { archivio.togliSerie(esercizio: esercizio, serie: serie) }
        } label: {
            CifreFisse(testo: dato.tipo == .normale ? "\(conta)" : dato.tipo == .riscaldamento ? "R" : "C\(conta)",
                       colore: dato.tipo == .normale ? palette.testo : palette.caldo)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(.rect)
        }
        .accessibilityLabel("Serie \(serie + 1), \(dato.tipo.nome)")
        .accessibilityHint("Cambia tipo o togli la serie")
    }

    @ViewBuilder private var prima: some View {
        if let p = precedente {
            CifreFisse(testo: "\(num(p.kg))×\(p.ripetizioni)", stile: .footnote, colore: palette.secondario)
                .minimumScaleFactor(0.6)
                .accessibilityLabel("Volta scorsa \(num(p.kg)) chili per \(p.ripetizioni) ripetizioni")
        } else {
            Text("–").font(.georgia(.footnote)).foregroundStyle(palette.secondario).accessibilityHidden(true)
        }
    }

    private var campoKg: some View {
        CampoCifre(testo: $kg, titolo: "Chilogrammi", segnaposto: precedente.map { num($0.kg) } ?? "0", decimale: true, fatto: dato.fatta)
    }

    private var campoRip: some View {
        CampoCifre(testo: $rip, titolo: "Ripetizioni", segnaposto: precedente.map { String($0.ripetizioni) } ?? "–", decimale: false, fatto: dato.fatta)
    }

    private var spunta: some View {
        Button {
            premi()
        } label: {
            Image(systemName: "checkmark")
                .font(.georgia(.body, grassetto: true))
                .foregroundStyle(dato.fatta ? palette.suTasto : palette.secondario)
                .frame(width: 44, height: 44)
                .background(dato.fatta ? palette.tasto : palette.riempimento, in: .rect(cornerRadius: 10))
                .contentShape(.rect(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(dato.fatta ? "Serie \(serie + 1) segnata" : "Segna la serie \(serie + 1)")
        .accessibilityAddTraits(dato.fatta ? .isSelected : [])
        .sensoryFeedback(.success, trigger: dato.fatta)
    }

    private func premi() {
        if dato.fatta {
            archivio.riapriSerie(esercizio: esercizio, serie: serie)
            return
        }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        // L'avviso va calcolato prima: dopo la spunta il massimo di oggi è già questo carico
        let nuovoMassimo = dato.tipo != .riscaldamento && archivio.superaIlMassimo(esercizio: esercizio, kg: kg)
        switch archivio.spuntaSerie(esercizio: esercizio, serie: serie, kg: kg, ripetizioni: rip) {
        case .fatta:
            if nuovoMassimo { messaggio = "Nuovo massimo: \(kg.replacingOccurrences(of: ".", with: ",")) kg" }
        case .valoriNonValidi:
            messaggio = "Scrivi i kg (anche 0) e le ripetizioni (almeno 1)"
        case .giaFatta, .nonTrovata:
            break   // un secondo tocco veloce: niente errore
        }
    }
}

private extension DynamicTypeSize {
    // Dalle ultime dimensioni normali le colonne non stanno più in una riga sui telefoni stretti
    var aDueLivelli: Bool { self >= .xxLarge }
}

extension TipoSerie {
    var nome: String {
        switch self {
        case .riscaldamento: "Riscaldamento"
        case .normale: "Normale"
        case .cedimento: "Cedimento"
        }
    }
}

// Un campo normale, con cursore e selezione al loro posto. Le cifre sono quelle di Georgia con spaziatura
// uniforme se il carattere la offre, altrimenti proporzionali: nelle colonne si leggono comunque bene
private struct CampoCifre: View {
    @Binding var testo: String
    let titolo: String
    let segnaposto: String
    let decimale: Bool
    let fatto: Bool
    @Environment(\.palette) private var palette
    @FocusState private var attivo: Bool

    var body: some View {
        TextField("", text: $testo, prompt: Text(segnaposto).foregroundStyle(palette.secondario))
            .font(.georgia(.body))
            .monospacedDigit()
            .keyboardType(decimale ? .decimalPad : .numberPad)
            .multilineTextAlignment(.center)
            .foregroundStyle(fatto ? palette.suAccento : palette.testo)
            .tint(palette.accento)
            .disabled(fatto)
            .focused($attivo)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(fatto ? palette.accento : palette.riempimento, in: .rect(cornerRadius: 10))
            .contentShape(.rect(cornerRadius: 10))
            // Il campo prende il tocco solo sul testo: così vale tutta la casella
            .onTapGesture { if !fatto { attivo = true } }
            .accessibilityLabel(titolo)
            .onChange(of: testo) { _, nuovo in
                // Solo cifre e una virgola o un punto
                var visto = false
                let pulito = String(nuovo.filter { c in
                    if c.isASCII, c.isNumber { return true }
                    if decimale, c == "," || c == ".", !visto { visto = true; return true }
                    return false
                }.prefix(6))
                if pulito != nuovo { testo = pulito }
            }
    }
}

// ---------- Recupero, annulla, scelta, riepilogo ----------

private struct BarraRecupero: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.palette) private var palette

    var body: some View {
        if archivio.recupero.fine != nil {
            TimelineView(.periodic(from: .now, by: 0.5)) { c in
                let r = archivio.recupero.rimanenti(adesso: c.date)
                if r > 0 {
                    let tempo = VStack(alignment: .leading, spacing: 0) {
                        Text("Recupero").font(.georgia(.caption)).foregroundStyle(palette.secondario)
                        CifreFisse(testo: formatoDurata(TimeInterval(r)), stile: .title2, grassetto: true, colore: palette.accento)
                    }
                    let tasti = HStack(spacing: 8) {
                        tasto("−15") { archivio.recupero.aggiungi(-15) }
                        tasto("+15") { archivio.recupero.aggiungi(15) }
                        tasto("Salta") { archivio.recupero.salta() }
                    }
                    // A testo grande i tasti vanno sotto il tempo
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) { tempo; Spacer(minLength: 4); tasti }
                        VStack(alignment: .leading, spacing: 6) { tempo; tasti }
                    }
                    .padding(10)
                    .background(palette.barra, in: .rect(cornerRadius: 16))
                    .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(palette.traccia) }
                    .accessibilityElement(children: .contain)
                }
            }
        }
    }

    private func tasto(_ titolo: String, _ azione: @escaping () -> Void) -> some View {
        Button(action: azione) {
            Text(titolo)
                .font(.georgia(.subheadline, grassetto: true))
                .foregroundStyle(palette.testo)
                .padding(.horizontal, 10)
                .frame(minWidth: 44, minHeight: 44)
                .background(palette.riempimento, in: .rect(cornerRadius: 12))
                .contentShape(.rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

private struct SceltaEsercizio: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var chiudi
    @State private var ricerca = ""

    private var nomi: [String] {
        let tutti = archivio.profilo.eserciziUsati()
        return ricerca.isEmpty ? tutti : tutti.filter { $0.localizedCaseInsensitiveContains(ricerca) }
    }

    var body: some View {
        let nuovo = ricerca.trimmingCharacters(in: .whitespaces)
        VStack(spacing: 0) {
            HStack {
                Text("Aggiungi esercizio").font(.georgia(.headline)).accessibilityAddTraits(.isHeader)
                Spacer()
                Button { chiudi() } label: {
                    Text("Chiudi").font(.georgia(.callout)).foregroundStyle(palette.accento)
                        .frame(minWidth: 44, minHeight: 44).contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            TextField("", text: $ricerca, prompt: Text("Cerca o scrivi un nome nuovo").foregroundStyle(palette.secondario))
                .font(.georgia())
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(palette.riempimento, in: .rect(cornerRadius: 12))
                .padding(.horizontal, 16)
            ScrollView {
                VStack(spacing: 8) {
                    if !nuovo.isEmpty, !nomi.contains(where: { $0.caseInsensitiveCompare(nuovo) == .orderedSame }) {
                        riga("Crea «\(nuovo)»", icona: "plus") { aggiungi(nuovo) }
                    }
                    ForEach(nomi, id: \.self) { n in
                        riga(n, icona: nil) { aggiungi(n) }
                    }
                }
                .padding(16)
            }
            .scorrimentoTema()
            .scrollDismissesKeyboard(.interactively)
        }
        .padding(.top, 8)
        .background(palette.fondo.ignoresSafeArea())
        .foregroundStyle(palette.testo)
        .font(.georgia())
        .presentationDetents([.large])
    }

    private func aggiungi(_ nome: String) {
        archivio.aggiungiEsercizio(nome)
        chiudi()
    }

    private func riga(_ testo: String, icona: String?, _ azione: @escaping () -> Void) -> some View {
        Button(action: azione) {
            HStack {
                if let icona { Image(systemName: icona) }
                Text(testo).frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.georgia(.callout))
            .foregroundStyle(palette.testo)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(palette.riempimento, in: .rect(cornerRadius: 12))
            .contentShape(.rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

private struct RiepilogoView: View {
    let riepilogo: Riepilogo
    let chiudi: () -> Void
    @Environment(\.palette) private var palette

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Allenamento finito")
                    .font(.georgia(.title, grassetto: true))
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, 24)
                VStack(spacing: 12) {
                    voce("Durata", formatoDurata(riepilogo.durata))
                    voce("Serie", "\(riepilogo.serie)")
                    voce("Volume", "\(num(riepilogo.volume)) kg")
                }
                .scheda()
                if !riepilogo.record.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Record").font(.georgia(.headline))
                        ForEach(riepilogo.record, id: \.self) { r in
                            Text(r).font(.georgia(.body)).foregroundStyle(palette.accento)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .scheda()
                }
                Button("Chiudi", action: chiudi)
                    .buttonStyle(TastoTema())
            }
            .padding(16)
        }
        .scorrimentoTema()
    }

    private func voce(_ nome: String, _ valore: String) -> some View {
        HStack {
            Text(nome).font(.georgia(.body)).foregroundStyle(palette.secondario)
            Spacer()
            CifreFisse(testo: valore, stile: .title3, grassetto: true)
        }
    }
}
