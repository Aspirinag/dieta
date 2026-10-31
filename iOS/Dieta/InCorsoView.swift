import SwiftUI

// Georgia ha cifre proporzionali (altezze e larghezze diverse): ogni cifra sta in una casella
// larga quanto la cifra più larga, così timer e colonne non ballano
struct CifreFisse: View {
    let testo: String
    var stile: Font.TextStyle = .body
    var grassetto = false
    var colore: Color?
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var dimensioneTesto

    private static var larghezze: [String: CGFloat] = [:]

    private var larghezza: CGFloat {
        let font = UIFont.georgia(Self.stileUIKit(stile), grassetto: grassetto)
        let chiave = "\(font.fontName)-\(font.pointSize)"
        if let w = Self.larghezze[chiave] { return w }
        let w = ceil("0123456789".map { String($0).size(withAttributes: [.font: font]).width }.max() ?? font.pointSize / 2)
        Self.larghezze[chiave] = w
        return w
    }

    var body: some View {
        let w = larghezza
        HStack(spacing: 0) {
            ForEach(Array(testo.enumerated()), id: \.offset) { _, c in
                if c.isASCII, c.isNumber {
                    Text(String(c)).frame(width: w)
                } else {
                    Text(String(c))
                }
            }
        }
        .font(.georgia(stile, grassetto: grassetto))
        .foregroundStyle(colore ?? palette.testo)
        .lineLimit(1)
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(testo)
    }

    static func stileUIKit(_ s: Font.TextStyle) -> UIFont.TextStyle {
        switch s {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .callout: .callout
        case .subheadline: .subheadline
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        default: .body
        }
    }
}

func formatoDurata(_ secondi: TimeInterval) -> String {
    let s = max(0, Int(secondi))
    return s >= 3600 ? String(format: "%d:%02d:%02d", s / 3600, s % 3600 / 60, s % 60) : String(format: "%02d:%02d", s / 60, s % 60)
}

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
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(a.routine ?? "Allenamento libero")
                    .font(.georgia(.footnote))
                    .foregroundStyle(palette.secondario)
                TimelineView(.periodic(from: .now, by: 1)) { c in
                    CifreFisse(testo: formatoDurata(c.date.timeIntervalSince(a.dataInizio ?? c.date)), stile: .title2, grassetto: true)
                }
            }
            Spacer()
            Button {
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
                intestazione
                ForEach(e.serie.indices, id: \.self) { s in
                    RigaSerie(esercizio: indice, serie: s, dato: e.serie[s], conta: contaNormali(e, fino: s),
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
            Text("Serie").frame(width: Colonne.serie)
            Text("Prima").frame(maxWidth: .infinity)
            Text("Kg").frame(width: Colonne.valore)
            Text("Rip.").frame(width: Colonne.valore)
            Color.clear.frame(width: Colonne.spunta, height: 1)
        }
        .font(.georgia(.caption, grassetto: true))
        .foregroundStyle(palette.secondario)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .accessibilityHidden(true)
    }
}

private enum Colonne {
    static let serie: CGFloat = 40
    static let valore: CGFloat = 66
    static let spunta: CGFloat = 44
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

    private static func testoKg(_ s: SerieFatta) -> String { s.kg > 0 ? num(s.kg) : "" }
    private static func testoRip(_ s: SerieFatta) -> String { s.ripetizioni > 0 ? String(s.ripetizioni) : "" }

    var body: some View {
        HStack(spacing: 6) {
            Menu {
                ForEach(TipoSerie.allCases, id: \.self) { t in
                    Button(t.nome) { archivio.cambiaTipo(esercizio: esercizio, serie: serie, t) }
                }
                Button("Togli serie", systemImage: "trash", role: .destructive) { archivio.togliSerie(esercizio: esercizio, serie: serie) }
            } label: {
                CifreFisse(testo: dato.tipo == .normale ? "\(conta)" : dato.tipo == .riscaldamento ? "R" : "C\(conta)",
                           colore: dato.tipo == .normale ? palette.testo : palette.caldo)
                    .frame(width: Colonne.serie, height: 44)
                    .contentShape(.rect)
            }
            .accessibilityLabel("Serie \(serie + 1), \(dato.tipo.nome)")
            .accessibilityHint("Cambia tipo o togli la serie")

            Group {
                if let p = precedente {
                    CifreFisse(testo: "\(num(p.kg))×\(p.ripetizioni)", stile: .footnote, colore: palette.secondario)
                } else {
                    Text("–").font(.georgia(.footnote)).foregroundStyle(palette.secondario)
                }
            }
            .frame(maxWidth: .infinity)
            .minimumScaleFactor(0.6)

            CampoCifre(testo: $kg, titolo: "Chilogrammi", decimale: true, fatto: dato.fatto)
                .frame(width: Colonne.valore)
            CampoCifre(testo: $rip, titolo: "Ripetizioni", decimale: false, fatto: dato.fatto)
                .frame(width: Colonne.valore)

            Button {
                spunta()
            } label: {
                Image(systemName: "checkmark")
                    .font(.georgia(.body, grassetto: true))
                    .foregroundStyle(dato.fatto ? palette.suTasto : palette.secondario)
                    .frame(width: Colonne.spunta, height: 44)
                    .background(dato.fatto ? palette.tasto : palette.riempimento, in: .rect(cornerRadius: 10))
                    .contentShape(.rect(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(dato.fatto ? "Serie \(serie + 1) segnata" : "Segna la serie \(serie + 1)")
            .accessibilityAddTraits(dato.fatto ? .isSelected : [])
            .sensoryFeedback(.success, trigger: dato.fatta)
        }
        // Se la serie cambia sotto (tolta un'altra, annullata) i campi la seguono
        .onChange(of: dato) { _, nuova in
            kg = Self.testoKg(nuova)
            rip = Self.testoRip(nuova)
        }
    }

    private func spunta() {
        if dato.fatto {
            archivio.riapriSerie(esercizio: esercizio, serie: serie)
            return
        }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        // L'avviso va calcolato prima: dopo la spunta il massimo di oggi è già questo carico
        let nuovoMassimo = dato.tipo != .riscaldamento && archivio.superaIlMassimo(esercizio: esercizio, kg: kg)
        if archivio.spuntaSerie(esercizio: esercizio, serie: serie, kg: kg, ripetizioni: rip) {
            if nuovoMassimo { messaggio = "Nuovo massimo: \(kg.replacingOccurrences(of: ".", with: ",")) kg" }
        } else {
            messaggio = "Scrivi kg e ripetizioni maggiori di zero"
        }
    }
}

private extension SerieFatta {
    var fatto: Bool { fatta }
    var fatta_: Bool { fatta }
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

// Il valore si legge con le cifre di larghezza fissa; il campo vero sta sopra, con il testo invisibile
private struct CampoCifre: View {
    @Binding var testo: String
    let titolo: String
    let decimale: Bool
    let fatto: Bool
    @Environment(\.palette) private var palette

    var body: some View {
        ZStack {
            CifreFisse(testo: testo, colore: fatto ? palette.suTasto : palette.testo)
            TextField("", text: $testo)
                .keyboardType(decimale ? .decimalPad : .numberPad)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.clear)   // invisibile: le cifre le disegna CifreFisse
                .tint(palette.accento)
                .disabled(fatto)
                .accessibilityLabel(titolo)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(fatto ? palette.accento : palette.riempimento, in: .rect(cornerRadius: 10))
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
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Recupero").font(.georgia(.caption)).foregroundStyle(palette.secondario)
                            CifreFisse(testo: formatoDurata(TimeInterval(r)), stile: .title2, grassetto: true, colore: palette.accento)
                        }
                        Spacer(minLength: 4)
                        tasto("−15") { archivio.recupero.aggiungi(-15) }
                        tasto("+15") { archivio.recupero.aggiungi(15) }
                        tasto("Salta") { archivio.recupero.salta() }
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

// «Annulla» per qualche secondo dopo una spunta o dopo «Mangiato»
struct BannerAnnulla: View {
    let tipo: TipoAnnulla
    @Environment(Archivio.self) private var archivio
    @Environment(\.palette) private var palette

    var body: some View {
        if let r = archivio.richiestaAnnulla, r.tipo == tipo {
            HStack {
                Text(r.testo)
                    .font(.georgia(.subheadline))
                Spacer()
                Button {
                    if tipo == .spunta { archivio.annullaSpunta() } else { archivio.annullaUltimoPasto() }
                } label: {
                    Text("Annulla")
                        .font(.georgia(.subheadline, grassetto: true))
                        .foregroundStyle(palette.accento)
                        .padding(.horizontal, 12)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 14)
            .padding(.trailing, 4)
            .background(palette.barra, in: .capsule)
            .overlay { Capsule().strokeBorder(palette.traccia) }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
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
