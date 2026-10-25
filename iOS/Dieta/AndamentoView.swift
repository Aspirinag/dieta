import SwiftUI
import Charts

// Cruscotto: costanza nei pasti, una tessera per misura (ultimo valore, variazione, mini grafico),
// il grafico della misura scelta, consigli e storico delle misurazioni
struct AndamentoView: View {
    @Environment(Archivio.self) private var archivio
    @State private var metrica: CampoMisura = .peso
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
        var id: Date { data }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                let bia = archivio.profilo.bia.sorted { $0.data < $1.data }
                VStack(spacing: 14) {
                    costanza
                    if bia.isEmpty {
                        ContentUnavailableView(
                            "Nessuna misurazione",
                            systemImage: "chart.line.uptrend.xyaxis",
                            description: Text("Carica la BIA in PDF o aggiungila a mano dalla scheda Dati.")
                        )
                        .scheda()
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
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Andamento")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { MenuProfilo() } }
            .navigationDestination(for: String.self) { data in
                EditorMisura(dataEsistente: data)
            }
        }
    }

    // ---------- Costanza ----------

    // Pasti segnati negli ultimi 7 giorni (oggi escluso): anello e una barra per giorno
    @ViewBuilder private var costanza: some View {
        let p = archivio.profilo
        let giorni = (1...7).reversed().map { Giorni.aggiungi(Giorni.oggi(), -$0) }
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Costanza").font(.headline)
                    Text("Pasti segnati negli ultimi 7 giorni").font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if let a = p.aderenza() {
                    Anello(valore: Double(a) / 100, testo: "\(a)%", lato: 58,
                           descrizione: "Pasti segnati negli ultimi 7 giorni: \(a) per cento")
                }
            }
            if p.aderenza() == nil {
                Text("Nessun piano attivo negli ultimi 7 giorni.").foregroundStyle(.secondary)
            } else {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(giorni, id: \.self) { iso in
                        let quota = p.quotaSegnata(iso)
                        VStack(spacing: 6) {
                            ZStack(alignment: .bottom) {
                                Capsule().fill(Color.accentColor.opacity(0.14))
                                Capsule()
                                    .fill(Color.accentColor.gradient)
                                    .frame(height: max(quota ?? 0, 0.04) * 44)
                                    .opacity(quota == nil ? 0 : 1)
                            }
                            .frame(height: 44)
                            Text(String(Giorni.nomi[Giorni.indice(iso)].prefix(1)))
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
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
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(voci.filter { v in bia.contains { $0[v.campo] != nil } }, id: \.campo) { v in
                let punti = bia.compactMap { m in m[v.campo].map { Punto(data: Giorni.data(m.data), valore: $0) } }
                let scelta = v.campo == metrica
                Button {
                    withAnimation(.snappy) { metrica = v.campo; selezione = nil }
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(v.campo.nome).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text(num(punti.last?.valore)).font(.title2.weight(.semibold)).fontDesign(.rounded)
                            Text(v.campo.unita).font(.subheadline).foregroundStyle(.secondary)
                        }
                        .monospacedDigit()
                        if punti.count > 1 {
                            BadgeVariazione(testo: testoDelta(punti.first?.valore, punti.last?.valore, v.campo.unita),
                                            colore: colore(punti.first?.valore, punti.last?.valore, v.verso))
                            Chart(punti) { p in
                                LineMark(x: .value("Data", p.data), y: .value(v.campo.nome, p.valore))
                                    .interpolationMethod(.monotone)
                                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                                    .foregroundStyle(colore(punti.first?.valore, punti.last?.valore, v.verso) == .primary
                                                     ? Color.secondary : colore(punti.first?.valore, punti.last?.valore, v.verso))
                            }
                            .chartXAxis(.hidden)
                            .chartYAxis(.hidden)
                            .chartYScale(domain: .automatic(includesZero: false))
                            .frame(height: 30)
                        } else {
                            Text("Una sola misura").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
                    .overlay {
                        if scelta { RoundedRectangle(cornerRadius: 20).strokeBorder(Color.accentColor, lineWidth: 2) }
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

    private func colore(_ a: Double?, _ b: Double?, _ verso: Double) -> Color {
        guard let d = delta(a, b), d != 0 else { return .primary }
        return d * verso > 0 ? .green : .red
    }

    // ---------- Grafico ----------

    private func grafico(_ bia: [Misura]) -> some View {
        let punti = bia.compactMap { m in m[metrica].map { Punto(data: Giorni.data(m.data), valore: $0) } }
        // Obiettivo dall'ultima BIA: peso desiderabile, o massa grassa desiderabile in kg
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
                Text(metrica.nome).font(.headline)
                Spacer()
                Menu {
                    Picker("Misura", selection: $metrica) {
                        ForEach(voci, id: \.campo) { v in Text(v.campo.nome).tag(v.campo) }
                    }
                } label: {
                    Label("Cambia", systemImage: "chevron.up.chevron.down").font(.subheadline)
                }
            }
            if punti.count < 2 {
                Text("Servono almeno due misurazioni con questo valore.").foregroundStyle(.secondary)
            } else {
                Chart {
                    ForEach(punti) { p in
                        AreaMark(x: .value("Data", p.data), yStart: .value("Base", minimo - 1), yEnd: .value(metrica.nome, p.valore))
                            .interpolationMethod(.monotone)
                            .foregroundStyle(.linearGradient(colors: [.accentColor.opacity(0.28), .accentColor.opacity(0.02)],
                                                             startPoint: .top, endPoint: .bottom))
                        LineMark(x: .value("Data", p.data), y: .value(metrica.nome, p.valore))
                            .interpolationMethod(.monotone)
                            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        PointMark(x: .value("Data", p.data), y: .value(metrica.nome, p.valore))
                            .symbolSize(scelto?.id == p.id ? 120 : 40)
                            .annotation(position: .top) {
                                if scelto == nil && punti.count <= 8 {
                                    Text(num(p.valore)).font(.caption2).fontDesign(.rounded).foregroundStyle(.secondary)
                                }
                            }
                    }
                    if let obiettivo {
                        RuleMark(y: .value("Obiettivo", obiettivo))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                            .foregroundStyle(.secondary)
                            .annotation(position: .top, alignment: .leading) {
                                Text("Obiettivo \(num((obiettivo * 10).rounded() / 10)) \(metrica.unita)")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                    }
                    if let scelto {
                        RuleMark(x: .value("Data", scelto.data))
                            .foregroundStyle(.secondary.opacity(0.4))
                            .annotation(position: .top, spacing: 4, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                                VStack(spacing: 2) {
                                    Text("\(num(scelto.valore)) \(metrica.unita)").font(.headline).fontDesign(.rounded)
                                    Text(Giorni.breve(Giorni.iso(scelto.data))).font(.caption2).foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.regularMaterial, in: .rect(cornerRadius: 10))
                            }
                    }
                }
                .chartXSelection(value: $selezione)
                .sensoryFeedback(.selection, trigger: scelto?.id)
                .chartYScale(domain: .automatic(includesZero: false))
                .chartXAxis {
                    AxisMarks(values: punti.map(\.data)) { _ in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    }
                }
                .frame(height: 220)
                Text("Tieni premuto e scorri sul grafico per leggere i valori.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                    Label(c, systemImage: "lightbulb.fill")
                        .symbolRenderingMode(.multicolor)
                }
                if let ultimo = bia.last, ultimo.obiettivoPeso != nil || ultimo.obiettivoGrassoPct != nil {
                    Label("Obiettivi: peso \(num(ultimo.obiettivoPeso)) kg, massa grassa \(num(ultimo.obiettivoGrassoPct))%",
                          systemImage: "flag.checkered")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)
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
                Text("Misurazioni").font(.headline)
                Spacer()
                Text("\(bia.count)").foregroundStyle(.secondary).monospacedDigit()
            }
            .padding(.bottom, 8)
            ForEach(Array(bia.reversed().enumerated()), id: \.element.id) { i, m in
                if i > 0 { Divider() }
                NavigationLink(value: m.data) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Giorni.breve(m.data)).font(.body.weight(.medium))
                            Text("Grasso \(num(m.grassoKg)) kg · magra \(num(m.magraKg)) kg · vita \(num(m.vitaCm)) cm")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(num(m.peso)) kg").font(.body.weight(.semibold)).fontDesign(.rounded).monospacedDigit()
                        Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 10)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            Text("Tocca una misurazione per modificarla o eliminarla.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 6)
        }
        .scheda()
    }
}
