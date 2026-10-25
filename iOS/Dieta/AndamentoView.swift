import SwiftUI
import Charts

// Aderenza alla dieta, variazioni delle misure BIA, grafico e storico
struct AndamentoView: View {
    @Environment(Archivio.self) private var archivio
    @State private var metrica: CampoMisura = .peso

    private struct Voce {
        let campo: CampoMisura
        let verso: Double   // -1: è bene se scende, 1: è bene se sale
    }

    private let voci: [Voce] = [
        Voce(campo: .peso, verso: -1), Voce(campo: .grasso, verso: -1), Voce(campo: .magra, verso: 1),
        Voce(campo: .vita, verso: -1), Voce(campo: .addome, verso: -1), Voce(campo: .fianchi, verso: -1),
    ]

    var body: some View {
        NavigationStack {
            List {
                let bia = archivio.profilo.bia.sorted { $0.data < $1.data }
                riepilogo(bia)
                if let primo = bia.first, let ultimo = bia.last {
                    if bia.count > 1 { dallInizio(primo, ultimo) }
                    grafico(bia)
                    storico(bia)
                } else {
                    ContentUnavailableView(
                        "Nessuna misurazione",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Carica la BIA in PDF o aggiungila a mano dalla scheda Dati.")
                    )
                }
            }
            .navigationTitle("Andamento")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { MenuProfilo() } }
            .navigationDestination(for: String.self) { data in
                EditorMisura(dataEsistente: data)
            }
        }
    }

    // ---------- Riepilogo ----------

    @ViewBuilder private func riepilogo(_ bia: [Misura]) -> some View {
        Section("Riepilogo") {
            if let a = archivio.profilo.aderenza() {
                VStack(alignment: .leading, spacing: 6) {
                    LabeledContent("Pasti segnati negli ultimi 7 giorni", value: "\(a)%")
                    ProgressView(value: Double(a), total: 100)
                }
            } else {
                Text("Nessun piano attivo negli ultimi 7 giorni.").foregroundStyle(.secondary)
            }
            if bia.count > 1 {
                let prec = bia[bia.count - 2], ultimo = bia[bia.count - 1]
                VStack(alignment: .leading, spacing: 6) {
                    Text("Dall'ultima misurazione (\(Giorni.breve(prec.data)))").font(.subheadline.weight(.semibold))
                    HStack {
                        variazione("Peso", prec.peso, ultimo.peso, "kg", -1)
                        variazione("Grasso", prec.grassoKg, ultimo.grassoKg, "kg", -1)
                        variazione("Vita", prec.vitaCm, ultimo.vitaCm, "cm", -1)
                    }
                }
                ForEach(consigli(bia), id: \.self) { c in
                    Label(c, systemImage: "lightbulb").font(.subheadline)
                }
            }
        }
    }

    private func variazione(_ nome: String, _ a: Double?, _ b: Double?, _ unita: String, _ verso: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(nome).font(.caption).foregroundStyle(.secondary)
            Text(testoDelta(a, b, unita)).font(.headline).foregroundStyle(colore(a, b, verso))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private func consigli(_ bia: [Misura]) -> [String] {
        guard let primo = bia.first, let ultimo = bia.last,
              let dg = delta(primo.grassoKg, ultimo.grassoKg), let dm = delta(primo.magraKg, ultimo.magraKg) else { return [] }
        var c: [String] = []
        if dg < 0 && dm >= -0.5 { c.append("Dall'inizio il calo riguarda soprattutto la massa grassa, e la massa magra è stabile: è il risultato che cerchiamo.") }
        if dm < -1 { c.append("La massa magra è scesa di più di 1 kg: conviene parlarne con la nutrizionista.") }
        if dg > 0 { c.append("La massa grassa è salita rispetto all'inizio.") }
        return c
    }

    // ---------- Dall'inizio ----------

    private func dallInizio(_ primo: Misura, _ ultimo: Misura) -> some View {
        Section {
            ForEach(voci, id: \.campo) { v in
                LabeledContent(v.campo.nome) {
                    HStack(spacing: 10) {
                        Text("\(num(primo[v.campo])) → \(num(ultimo[v.campo])) \(v.campo.unita)")
                            .foregroundStyle(.secondary)
                        Text(testoDelta(primo[v.campo], ultimo[v.campo], v.campo.unita))
                            .fontWeight(.semibold)
                            .foregroundStyle(colore(primo[v.campo], ultimo[v.campo], v.verso))
                            .frame(minWidth: 64, alignment: .trailing)
                    }
                    .monospacedDigit()
                }
            }
        } header: {
            Text("Dall'inizio: \(Giorni.breve(primo.data)) → \(Giorni.breve(ultimo.data))")
        } footer: {
            if ultimo.obiettivoPeso != nil || ultimo.obiettivoGrassoPct != nil {
                Text("Obiettivi: peso \(num(ultimo.obiettivoPeso)) kg, massa grassa \(num(ultimo.obiettivoGrassoPct))%")
            }
        }
    }

    // ---------- Grafico ----------

    private struct Punto: Identifiable {
        let data: Date
        let valore: Double
        var id: Date { data }
    }

    private func grafico(_ bia: [Misura]) -> some View {
        let punti = bia.compactMap { m in m[metrica].map { Punto(data: Giorni.data(m.data), valore: $0) } }
        return Section {
            Picker("Misura", selection: $metrica) {
                ForEach(voci, id: \.campo) { v in Text(v.campo.nome).tag(v.campo) }
            }
            if punti.count < 2 {
                Text("Servono almeno due misurazioni con questo valore.").foregroundStyle(.secondary)
            } else {
                Chart(punti) { p in
                    LineMark(x: .value("Data", p.data), y: .value(metrica.nome, p.valore))
                        .interpolationMethod(.monotone)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    PointMark(x: .value("Data", p.data), y: .value(metrica.nome, p.valore))
                        .annotation(position: .top) {
                            Text(num(p.valore)).font(.caption2).foregroundStyle(.secondary)
                        }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartXAxis {
                    AxisMarks(values: punti.map(\.data)) { _ in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    }
                }
                .frame(height: 220)
                .padding(.vertical, 8)
            }
        } header: {
            Text("Grafico")
        }
    }

    // ---------- Storico ----------

    private func storico(_ bia: [Misura]) -> some View {
        Section {
            ForEach(bia.reversed()) { m in
                NavigationLink(value: m.data) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Giorni.breve(m.data)).font(.headline)
                        Text("Peso \(num(m.peso)) · grasso \(num(m.grassoKg)) · magra \(num(m.magraKg)) · vita \(num(m.vitaCm))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .swipeActions {
                    Button("Elimina", systemImage: "trash", role: .destructive) {
                        archivio.profilo.bia.removeAll { $0.data == m.data }
                    }
                }
            }
        } header: {
            Text("Misurazioni")
        } footer: {
            Text("Tocca una misurazione per modificarla, scorri a sinistra per eliminarla.")
        }
    }
}
