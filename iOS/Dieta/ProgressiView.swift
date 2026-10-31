import SwiftUI
import Charts

// Data della pesata aperta nel foglio ("" = nuova)
private struct DataPesata: Identifiable { let id: String }

// Cruscotto: costanza nei pasti, una tessera per misura (ultimo valore, variazione, mini grafico),
// il grafico della misura scelta, consigli e storico delle misurazioni
struct ProgressiView: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.importa) private var importa
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var testo
    @State private var metrica: CampoMisura = .peso
    @State private var nuovaMisura = false
    @State private var pesata: String?   // "" = nuova pesata, altrimenti la data da modificare
    @State private var selezione: Date?

    private struct Voce {
        let campo: CampoMisura
        let verso: Double   // -1: è bene se scende, 1: è bene se sale
    }

    private let voci: [Voce] = [
        Voce(campo: .peso, verso: -1), Voce(campo: .grasso, verso: -1), Voce(campo: .magra, verso: 1),
        Voce(campo: .vita, verso: -1), Voce(campo: .addome, verso: -1), Voce(campo: .fianchi, verso: -1),
    ]

    private struct Punto: Identifiable {
        let data: Date
        let valore: Double
        var pesata = false   // pesata a casa, non misurazione
        var id: Date { data }
    }

    // Punti di una misura; per il peso anche le pesate a casa (nello stesso giorno vale la misurazione)
    private func punti(_ campo: CampoMisura, _ bia: [Misura]) -> [Punto] {
        var p = bia.compactMap { m in m[campo].map { Punto(data: Giorni.data(m.data), valore: $0) } }
        if campo == .peso {
            let giorniBia = Set(bia.map(\.data))
            p += archivio.profilo.pesate.filter { !giorniBia.contains($0.key) }
                .map { Punto(data: Giorni.data($0.key), valore: $0.value, pesata: true) }
        }
        return p.sorted { $0.data < $1.data }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                let bia = archivio.profilo.bia.sorted { $0.data < $1.data }
                VStack(spacing: 14) {
                    costanza
                    if bia.isEmpty && archivio.profilo.pesate.isEmpty {
                        StatoVuoto(titolo: "Nessuna misurazione", icona: "chart.line.uptrend.xyaxis",
                                   descrizione: "Carica i referti delle misurazioni in PDF o aggiungine una a mano.") {
                            Button("Carica misurazioni (PDF)") { importa(.bia) }
                                .buttonStyle(TastoTema())
                            Button("Pesata rapida") { pesata = "" }
                                .buttonStyle(TastoTema(principale: false))
                            Button("Aggiungi a mano") { nuovaMisura = true }
                                .buttonStyle(TastoTema(principale: false))
                        }
                    } else {
                        tessere(bia)
                        grafico(bia)
                        consigli(bia)
                        storico(bia)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle("Progressi")
            .sfondoTema()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("Pesata rapida", systemImage: "scalemass") { pesata = "" }
                        Button("Carica misurazioni (PDF)", systemImage: "doc.text.magnifyingglass") { importa(.bia) }
                        Button("Aggiungi misurazione a mano", systemImage: "square.and.pencil") { nuovaMisura = true }
                    } label: {
                        Label("Aggiungi", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) { MenuProfilo(conSfondo: false) }
            }
            .navigationDestination(for: String.self) { data in
                EditorMisura(dataEsistente: data)
            }
            .sheet(isPresented: $nuovaMisura) {
                NavigationStack { EditorMisura(dataEsistente: nil) }
                    .presentationBackground(palette.fondo)
            }
            .sheet(item: Binding(get: { pesata.map { DataPesata(id: $0) } }, set: { pesata = $0?.id })) { p in
                EditorPesata(dataEsistente: p.id.isEmpty ? nil : p.id)
            }
        }
    }

    // ---------- Costanza ----------

    // Pasti segnati negli ultimi 7 giorni (oggi escluso): anello e una barra per giorno
    @ViewBuilder private var costanza: some View {
        let p = archivio.profilo
        let giorni = (1...7).reversed().map { Giorni.aggiungi(Giorni.oggi(), -$0) }
        VStack(alignment: .leading, spacing: 14) {
            // Con il testo molto grande l'anello va sotto: accanto spezzerebbe «Costanza»
            let intestazione = testo.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10)) : AnyLayout(HStackLayout(spacing: 16))
            intestazione {
                VStack(alignment: .leading, spacing: 3) {
                    TestoIntero(testo: "Costanza").font(.georgia(.headline))
                    Text("Pasti segnati negli ultimi 7 giorni").font(.georgia(.subheadline)).foregroundStyle(palette.secondario)
                }
                Spacer(minLength: 0)
                if let a = p.aderenza() {
                    Anello(valore: Double(a) / 100, testo: "\(a)%", lato: 58,
                           descrizione: "Pasti segnati negli ultimi 7 giorni: \(a) per cento")
                }
            }
            if p.aderenza() == nil {
                Text("Nessun piano attivo negli ultimi 7 giorni.").foregroundStyle(palette.secondario)
            } else {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(giorni, id: \.self) { iso in
                        let quota = p.quotaSegnata(iso)
                        VStack(spacing: 6) {
                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 5).fill(palette.traccia)
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(palette.accento)
                                    .frame(height: max(quota ?? 0, 0.08) * 44)
                                    .opacity(quota == nil || quota == 0 ? 0 : 1)
                            }
                            .frame(width: 14, height: 44)
                            Text(String(Giorni.nomi[Giorni.indice(iso)].prefix(1)))
                                .font(.georgia(.caption2))
                                .foregroundStyle(palette.secondario)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(Giorni.nomi[Giorni.indice(iso)]): \(quota.map { "\(Int(($0 * 100).rounded())) per cento" } ?? "nessun piano")")
                    }
                }
            }
        }
        .scheda()
    }

    // ---------- Tessere ----------

    private func tessere(_ bia: [Misura]) -> some View {
        // Due colonne non reggono il testo molto grande
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: testo.isAccessibilitySize ? 1 : 2), spacing: 12) {
            ForEach(voci.filter { v in !punti(v.campo, bia).isEmpty }, id: \.campo) { v in
                let punti = punti(v.campo, bia)
                let scelta = v.campo == metrica
                Button {
                    withAnimation(.snappy) { metrica = v.campo; selezione = nil }
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        TestoIntero(testo: v.campo.nome).font(.georgia(.subheadline)).foregroundStyle(palette.secondario)
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text(num(punti.last?.valore)).font(.georgia(.title2, grassetto: true))
                            Text(v.campo.unita).font(.georgia(.subheadline)).foregroundStyle(palette.secondario)
                        }
                        if punti.count > 1 {
                            BadgeVariazione(testo: testoDelta(punti.first?.valore, punti.last?.valore, v.campo.unita),
                                            colore: colore(punti.first?.valore, punti.last?.valore, v.verso))
                            Chart(punti) { p in
                                LineMark(x: .value("Data", p.data), y: .value(v.campo.nome, p.valore))
                                    .interpolationMethod(.monotone)
                                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                                    .foregroundStyle(colore(punti.first?.valore, punti.last?.valore, v.verso) ?? palette.secondario)
                            }
                            .chartXAxis(.hidden)
                            .chartYAxis(.hidden)
                            .chartYScale(domain: .automatic(includesZero: false))
                            .frame(height: 30)
                        } else {
                            Text("Una sola misura").font(.georgia(.caption)).foregroundStyle(palette.secondario)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(palette.scheda, in: .rect(cornerRadius: 20))
                    .overlay {
                        if scelta { RoundedRectangle(cornerRadius: 20).strokeBorder(palette.accento, lineWidth: 2) }
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(scelta ? .isSelected : [])
                .accessibilityHint("Mostra il grafico di \(v.campo.nome.lowercased())")
            }
        }
        .sensoryFeedback(.selection, trigger: metrica)
    }

    private func delta(_ a: Double?, _ b: Double?) -> Double? {
        guard let a, let b else { return nil }
        return ((b - a) * 10).rounded() / 10
    }

    private func testoDelta(_ a: Double?, _ b: Double?, _ unita: String) -> String {
        guard let d = delta(a, b) else { return "–" }
        return "\(d > 0 ? "+" : "")\(num(d)) \(unita)"
    }

    // Accento se va bene, colore caldo se va male, nil se non è cambiato
    private func colore(_ a: Double?, _ b: Double?, _ verso: Double) -> Color? {
        guard let d = delta(a, b), d != 0 else { return nil }
        return d * verso > 0 ? palette.accento : palette.caldo
    }

    // ---------- Grafico ----------

    private func grafico(_ bia: [Misura]) -> some View {
        let punti = punti(metrica, bia)
        // Obiettivo dall'ultima misurazione: peso desiderabile, o massa grassa desiderabile in kg
        let obiettivo: Double? = switch metrica {
        case .peso: bia.last?.obiettivoPeso
        case .grasso: bia.last.flatMap { m in m.obiettivoGrassoPct.flatMap { pct in m.peso.map { $0 * pct / 100 } } }
        default: nil
        }
        // Il punto più vicino al dito, mentre si tocca il grafico
        let scelto = selezione.flatMap { s in punti.min { abs($0.data.timeIntervalSince(s)) < abs($1.data.timeIntervalSince(s)) } }
        let minimo = (punti.map(\.valore) + [obiettivo].compactMap { $0 }).min() ?? 0
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                TestoIntero(testo: metrica.nome).font(.georgia(.headline))
                Spacer()
                Menu {
                    Picker("Misura", selection: $metrica) {
                        ForEach(voci, id: \.campo) { v in Text(v.campo.nome).tag(v.campo) }
                    }
                } label: {
                    Label("Cambia", systemImage: "chevron.up.chevron.down").font(.georgia(.subheadline))
                }
            }
            if punti.count < 2 {
                Text("Servono almeno due misurazioni con questo valore.").foregroundStyle(palette.secondario)
            } else {
                Chart {
                    ForEach(punti) { p in
                        AreaMark(x: .value("Data", p.data), yStart: .value("Base", minimo - 1), yEnd: .value(metrica.nome, p.valore))
                            .interpolationMethod(.monotone)
                            .foregroundStyle(.linearGradient(colors: [palette.accento.opacity(0.28), palette.accento.opacity(0.02)],
                                                             startPoint: .top, endPoint: .bottom))
                        LineMark(x: .value("Data", p.data), y: .value(metrica.nome, p.valore))
                            .interpolationMethod(.monotone)
                            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                            .foregroundStyle(palette.accento)
                        PointMark(x: .value("Data", p.data), y: .value(metrica.nome, p.valore))
                            .symbolSize(scelto?.id == p.id ? 120 : p.pesata ? 18 : 40)
                            .foregroundStyle(p.pesata ? palette.secondario : palette.accento)
                            .annotation(position: .top) {
                                if scelto == nil && punti.count <= 8 && !p.pesata {
                                    Text(num(p.valore)).font(.georgia(.caption2)).foregroundStyle(palette.secondario)
                                }
                            }
                    }
                    if let obiettivo {
                        RuleMark(y: .value("Obiettivo", obiettivo))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                            .foregroundStyle(palette.secondario)
                            .annotation(position: .top, alignment: .leading) {
                                Text("Obiettivo \(num((obiettivo * 10).rounded() / 10)) \(metrica.unita)")
                                    .font(.georgia(.caption2)).foregroundStyle(palette.secondario)
                            }
                    }
                    if let scelto {
                        RuleMark(x: .value("Data", scelto.data))
                            .foregroundStyle(palette.secondario.opacity(0.4))
                            .annotation(position: .top, spacing: 4, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                                VStack(spacing: 2) {
                                    Text("\(num(scelto.valore)) \(metrica.unita)").font(.georgia(.headline))
                                    Text(Giorni.breve(Giorni.iso(scelto.data))).font(.georgia(.caption2)).foregroundStyle(palette.secondario)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(palette.riempimento, in: .rect(cornerRadius: 10))
                            }
                    }
                }
                .chartXSelection(value: $selezione)
                .sensoryFeedback(.selection, trigger: scelto?.id)
                .chartYScale(domain: .automatic(includesZero: false))
                .chartXAxis {
                    AxisMarks(values: punti.filter { !$0.pesata }.map(\.data)) { _ in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            .font(.georgia(.caption2))
                            .foregroundStyle(palette.secondario)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(palette.traccia)
                        AxisValueLabel()
                            .font(.georgia(.caption2))
                            .foregroundStyle(palette.secondario)
                    }
                }
                .frame(height: 220)
                Text("Tieni premuto e scorri sul grafico per leggere i valori."
                     + (punti.contains(where: \.pesata) ? " I punti grigi sono le pesate a casa." : ""))
                    .font(.georgia(.caption))
                    .foregroundStyle(palette.secondario)
            }
        }
        .scheda()
    }

    // ---------- Consigli ----------

    @ViewBuilder private func consigli(_ bia: [Misura]) -> some View {
        let testi = testiConsigli(bia)
        if !testi.isEmpty || bia.last?.obiettivoPeso != nil {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(testi, id: \.self) { c in
                    Label { Text(c) } icon: { Image(systemName: "lightbulb.fill").foregroundStyle(palette.caldo) }
                }
                if let ultimo = bia.last {
                    let obiettivi = [ultimo.obiettivoPeso.map { "peso \(num($0)) kg" },
                                     ultimo.obiettivoGrassoPct.map { "massa grassa \(num($0))%" }].compactMap { $0 }
                    if !obiettivi.isEmpty {
                        Label("Obiettivi: " + obiettivi.joined(separator: ", "), systemImage: "flag.checkered")
                            .foregroundStyle(palette.secondario)
                    }
                }
            }
            .font(.georgia(.subheadline))
            .scheda()
        }
    }

    private func testiConsigli(_ bia: [Misura]) -> [String] {
        guard bia.count > 1, let primo = bia.first, let ultimo = bia.last,
              let dg = delta(primo.grassoKg, ultimo.grassoKg), let dm = delta(primo.magraKg, ultimo.magraKg) else { return [] }
        var c: [String] = []
        if dg < 0 && dm >= -0.5 { c.append("Dall'inizio il calo riguarda soprattutto la massa grassa, e la massa magra è stabile: è il risultato che cerchiamo.") }
        if dm < -1 { c.append("La massa magra è scesa di più di 1 kg: conviene parlarne con la nutrizionista.") }
        if dg > 0 { c.append("La massa grassa è salita rispetto all'inizio.") }
        return c
    }

    // ---------- Storico ----------

    private func storico(_ bia: [Misura]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                TestoIntero(testo: "Misurazioni").font(.georgia(.headline))
                Spacer()
                Text("\(bia.count)").foregroundStyle(palette.secondario)
            }
            .padding(.bottom, 8)
            ForEach(Array(bia.reversed().enumerated()), id: \.element.id) { i, m in
                if i > 0 { Divider() }
                NavigationLink(value: m.data) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Giorni.breve(m.data)).font(.georgia(.body))
                            Text("Grasso \(num(m.grassoKg)) kg · magra \(num(m.magraKg)) kg · vita \(num(m.vitaCm)) cm")
                                .font(.georgia(.caption))
                                .foregroundStyle(palette.secondario)
                        }
                        Spacer()
                        Text("\(num(m.peso)) kg").font(.georgia(.body, grassetto: true))
                        Image(systemName: "chevron.right").font(.georgia(.caption, grassetto: true)).foregroundStyle(palette.secondario)
                    }
                    .padding(.vertical, 10)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            let pesate = archivio.profilo.pesate.sorted { $0.key > $1.key }
            if !pesate.isEmpty {
                HStack {
                    Text("Pesate a casa").font(.georgia(.headline))
                    Spacer()
                    Text("\(pesate.count)").foregroundStyle(palette.secondario)
                }
                .padding(.top, 18)
                .padding(.bottom, 8)
                ForEach(Array(pesate.enumerated()), id: \.element.key) { i, p in
                    if i > 0 { Divider() }
                    Button { pesata = p.key } label: {
                        HStack {
                            Label(Giorni.breve(p.key), systemImage: "scalemass").foregroundStyle(palette.testo)
                            Spacer()
                            Text("\(num(p.value)) kg").font(.georgia(.body, grassetto: true))
                            Image(systemName: "chevron.right").font(.georgia(.caption, grassetto: true)).foregroundStyle(palette.secondario)
                        }
                        .padding(.vertical, 10)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("Tocca una misurazione per modificarla o eliminarla. Con + ne aggiungi di nuove.")
                .font(.georgia(.caption))
                .foregroundStyle(palette.secondario)
                .padding(.top, 6)
        }
        .scheda()
    }
}
