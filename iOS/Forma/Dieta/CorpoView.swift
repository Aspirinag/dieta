import SwiftUI
import Charts

// Progressi → Corpo: peso e grafico, tre numeri della BIA, ultime misurazioni
struct CorpoView: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.dynamicTypeSize) private var dimensione
    let aggiungi: () -> Void

    @State private var metrica: CampoMisura = .peso
    @State private var periodo: Periodo = .treMesi

    enum Periodo: String, CaseIterable, Identifiable {
        case mese = "1 mese", treMesi = "3 mesi", tutto = "Tutto"
        var id: String { rawValue }
        var etichetta: LocalizedStringKey {
            switch self {
            case .mese: "1 mese"
            case .treMesi: "3 mesi"
            case .tutto: "Tutto"
            }
        }
        var giorni: Int? {
            switch self {
            case .mese: 30
            case .treMesi: 90
            case .tutto: nil
            }
        }
    }

    // Tra le misure del riquadro: -1 è bene se scende, 1 è bene se sale
    private static let riquadri: [(campo: CampoMisura, nome: String, verso: Double)] = [
        (.grasso, String(localized: "Grasso"), -1), (.magra, String(localized: "Magra"), 1), (.vita, String(localized: "Vita"), -1),
    ]

    var body: some View {
        let bia = archivio.profilo.bia.sorted { $0.data < $1.data }
        if Self.senzaMisurazioni(bia) {
            vuoto
        } else {
            grafico(bia)
            riquadriBia(bia)
            misurazioni(bia)
        }
    }

    // L'invito «Aggiungi il primo peso» compare solo senza alcuna misurazione:
    // quelle con la sola vita o la sola BIA (dal sito) si vedono comunque
    static func senzaMisurazioni(_ bia: [Misura]) -> Bool { bia.isEmpty }

    // ---------- Stato vuoto ----------

    private var vuoto: some View {
        Button(action: aggiungi) {
            Riquadro {
                HStack {
                    Text("Peso").font(.headline)
                    Spacer()
                    Text("Aggiungi il primo peso").font(.subheadline).foregroundStyle(Colori.accento)
                }
                .frame(minHeight: 44)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Peso")
        .accessibilityValue("Aggiungi il primo peso")
    }

    // ---------- Dati ----------

    private struct Punto: Identifiable {
        let data: Date
        let valore: Double
        var id: Date { data }
    }

    // Misure con quel valore dentro il periodo scelto
    private func misureNelPeriodo(_ bia: [Misura], _ campo: CampoMisura) -> [Misura] {
        let con = bia.filter { $0[campo] != nil }
        guard let giorni = periodo.giorni else { return con }
        let da = Giorni.aggiungi(Giorni.oggi(), -giorni)
        return con.filter { $0.data >= da }
    }

    private func variazione(_ bia: [Misura], _ campo: CampoMisura) -> Double? {
        let m = misureNelPeriodo(bia, campo)
        guard m.count > 1, let a = m.first?[campo], let b = m.last?[campo] else { return nil }
        return ((b - a) * 10).rounded() / 10
    }

    // −1,2 kg · +0,4 kg · 0 kg
    static func testoVariazione(_ d: Double, _ unita: String) -> String {
        "\(d > 0 ? "+" : d < 0 ? "−" : "")\(num(abs(d))) \(unita)"
    }

    private func colore(_ d: Double?, _ verso: Double) -> some ShapeStyle {
        guard let d, d != 0, d * verso > 0 else { return AnyShapeStyle(.secondary) }
        return AnyShapeStyle(Colori.accento)
    }

    private func verso(_ campo: CampoMisura) -> Double { campo == .magra ? 1 : -1 }

    // ---------- Peso e grafico ----------

    private func grafico(_ bia: [Misura]) -> some View {
        let campo = metrica
        let misure = misureNelPeriodo(bia, campo)
        let ultimo = bia.last { $0[campo] != nil }?[campo]
        let delta = variazione(bia, campo)
        let punti = misure.compactMap { m in m[campo].map { Punto(data: Giorni.data(m.data), valore: $0) } }
        return Riquadro {
            HStack(alignment: .firstTextBaseline) {
                Text(campo.nome).font(.headline)
                    .accessibilityIdentifier("grafico-titolo")
                Spacer()
                if campo != .peso {
                    Button("Peso") { withAnimation { metrica = .peso } }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Colori.accento)
                        .frame(minHeight: 44)
                } else if let delta {
                    Text(Self.testoVariazione(delta, campo.unita))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(colore(delta, verso(campo)))
                        .monospacedDigit()
                }
            }
            HStack(alignment: .firstTextBaseline) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(num(ultimo)).font(.system(size: 34, weight: .bold)).monospacedDigit()
                        .accessibilityIdentifier("valore-grande")
                    Text(campo.unita).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                if campo != .peso, let delta {
                    Text(Self.testoVariazione(delta, campo.unita))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(colore(delta, verso(campo)))
                        .monospacedDigit()
                }
            }
            if punti.count < 2 {
                Text(punti.isEmpty ? LocalizedStringKey("Nessun valore in questo periodo.") : LocalizedStringKey("Servono due misurazioni in questo periodo."))
                    .font(.subheadline).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                Chart(punti) { p in
                    LineMark(x: .value("Data", p.data), y: .value(campo.nome, p.valore))
                        .interpolationMethod(.monotone)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        .foregroundStyle(Colori.accento)
                    if let u = punti.last {
                        PointMark(x: .value("Data", u.data), y: .value(campo.nome, u.valore))
                            .symbolSize(60)
                            .foregroundStyle(Colori.accento)
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(height: 150)
                .padding(.top, 8)
                .accessibilityLabel("Grafico: \(campo.nome)")
                .accessibilityValue(punti.map { "\(num($0.valore)) \(campo.unita)" }.joined(separator: ", "))
            }
            periodi.padding(.top, 8)
            if let a = archivio.profilo.aderenza() {
                Divider().padding(.top, 8)
                Text("Pasti segnati negli ultimi 7 giorni: \(a)%")
                    .font(.footnote).foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
        }
    }

    private var periodi: some View {
        HStack(spacing: 8) {
            ForEach(Periodo.allCases) { p in
                Button { periodo = p } label: {
                    Text(p.etichetta)
                        .font(.subheadline.weight(p == periodo ? .semibold : .regular))
                        .foregroundStyle(p == periodo ? AnyShapeStyle(Colori.sulAccento) : AnyShapeStyle(.primary))
                        .padding(.horizontal, 14)
                        .frame(minHeight: 44)
                        .background(p == periodo ? AnyShapeStyle(Colori.accento) : AnyShapeStyle(Color(.systemFill)), in: .capsule)
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(p == periodo ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // ---------- Grasso, magra, vita ----------

    private func riquadriBia(_ bia: [Misura]) -> some View {
        let layout = dimensione.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
        return layout {
            ForEach(Self.riquadri, id: \.campo) { r in
                let scelto = metrica == r.campo
                let ultimo = bia.last { $0[r.campo] != nil }?[r.campo]
                let delta = variazione(bia, r.campo)
                Button {
                    withAnimation { metrica = scelto ? .peso : r.campo }
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: r.nome).font(.caption).foregroundStyle(.secondary)
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text(num(ultimo)).font(.title3.weight(.bold)).monospacedDigit()
                            Text(r.campo.unita).font(.caption).foregroundStyle(.secondary)
                        }
                        Text(delta.map { Self.testoVariazione($0, r.campo.unita) } ?? " ")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(colore(delta, r.verso))
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16, style: .continuous))
                    .overlay {
                        if scelto {
                            RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Colori.accento, lineWidth: 2)
                        }
                    }
                    .contentShape(.rect(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(r.campo.nome)
                .accessibilityValue("\(num(ultimo)) \(r.campo.unita)" + (delta.map { ", \(Self.testoVariazione($0, r.campo.unita))" } ?? ""))
                .accessibilityHint(scelto ? Text("Torna al peso nel grafico") : Text("Mostra nel grafico"))
                .accessibilityAddTraits(scelto ? .isSelected : [])
                .accessibilityIdentifier("metrica-\(r.campo.rawValue)")
            }
        }
    }

    // ---------- Misurazioni ----------

    private func misurazioni(_ bia: [Misura]) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text("Misurazioni").font(.headline)
                Spacer()
                NavigationLink(value: PaginaDieta.misure) {
                    Text("Tutte").font(.subheadline.weight(.semibold)).foregroundStyle(Colori.accento)
                        .frame(minHeight: 44)
                        .contentShape(.rect)
                }
            }
            .padding(.horizontal, 4)
            Riquadro { RigheMisure(misure: Array(bia.reversed().prefix(2))) }
        }
    }
}

// Date come «1 novembre» (con l'anno se non è quello in corso)
func dataMisura(_ iso: String) -> String {
    let d = Giorni.data(iso)
    let stessoAnno = Giorni.calendario.isDate(d, equalTo: Date(), toGranularity: .year)
    return stessoAnno ? d.formatted(.dateTime.day().month(.wide)) : d.formatted(.dateTime.day().month(.wide).year())
}

// Righe delle misurazioni: data e peso, si toccano per modificare
struct RigheMisure: View {
    let misure: [Misura]
    var elimina: ((Misura) -> Void)?

    var body: some View {
        ForEach(Array(misure.enumerated()), id: \.element.id) { i, m in
            if i > 0 { Divider() }
            NavigationLink(value: PaginaDieta.misura(m.data)) {
                HStack {
                    Text(dataMisura(m.data))
                    Spacer()
                    Text(verbatim: m.peso.map { kgTesto($0) } ?? "–").foregroundStyle(.secondary).monospacedDigit()
                    Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
                }
                .frame(minHeight: 44)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(dataMisura(m.data)), \(m.peso.map { kgTesto($0) } ?? String(localized: "senza peso"))")
            .accessibilityHint("Apre la misurazione per modificarla")
            .accessibilityIdentifier("misura-\(m.data)")
            .contextMenu {
                if let elimina { Button("Elimina", systemImage: "trash", role: .destructive) { elimina(m) } }
            }
        }
    }
}

// Progressi → Corpo → Tutte: l'elenco completo. Si tocca per modificare; si elimina con un tocco prolungato
struct MisurazioniView: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.dismiss) private var chiudi
    @State private var daEliminare: Misura?

    var body: some View {
        let bia = archivio.profilo.bia.sorted { $0.data > $1.data }
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(bia.count) misurazioni")
                    .font(.subheadline).foregroundStyle(.secondary).padding(.horizontal, 4)
                if bia.isEmpty {
                    Text("Nessuna misurazione.").font(.subheadline).foregroundStyle(.secondary).padding(.horizontal, 4)
                } else {
                    Riquadro { RigheMisure(misure: bia, elimina: { daEliminare = $0 }) }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .sfondoTema()
        .navigationTitle("Misurazioni")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Eliminare la misurazione?", isPresented: Binding(
            get: { daEliminare != nil }, set: { if !$0 { daEliminare = nil } }
        ), titleVisibility: .visible, presenting: daEliminare) { m in
            Button("Elimina quella del \(dataMisura(m.data))", role: .destructive) {
                archivio.profilo.bia.removeAll { $0.data == m.data }
                if archivio.profilo.bia.isEmpty { chiudi() }
            }
        }
    }
}
