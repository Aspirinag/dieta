import SwiftUI
import Charts

// Progressi → Corpo: peso e grafico, grasso / magra / vita con la data, ultime misurazioni.
// Le variazioni sono sempre grigie e col segno, rispetto a circa 30 giorni prima dell'ultima misura:
// il colore non giudica mai un dato del corpo (M1, M3).
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

    private static let riquadri: [CampoMisura] = [.grasso, .magra, .vita]

    var body: some View {
        let bia = archivio.profilo.bia.sorted { $0.data < $1.data }
        if Self.senzaMisurazioni(bia) {
            vuoto
        } else {
            grafico(bia)
            composizione(bia)
            misurazioni(bia)
        }
    }

    // L'invito «Aggiungi il primo peso» compare solo senza alcuna misurazione:
    // quelle con la sola vita o la sola BIA (dal sito) si vedono comunque
    static func senzaMisurazioni(_ bia: [Misura]) -> Bool { bia.isEmpty }

    // ---------- Stato vuoto ----------

    private var vuoto: some View {
        Section {
            VStack(alignment: .leading, spacing: Spazio.s) {
                Text("Peso").font(.headline)
                Button("Aggiungi il primo peso", action: aggiungi)
                    .buttonStyle(PulsanteAccento())
            }
            .padding(.vertical, Spazio.xs)
        }
        .righeTema()
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

    // Variazione tra l'ultima misura di quel campo e quella più vicina a 30 giorni prima
    // (accettata tra 23 e 37 giorni prima, come in PesoVeloce.variazione). Senza una misura così vecchia: nil, non si inventa un confronto.
    static func variazioneTrentaGiorni(_ misure: [Misura], _ campo: CampoMisura) -> Double? {
        let con = misure.filter { $0[campo] != nil }.sorted { $0.data < $1.data }
        guard let ultima = con.last, let fine = ultima[campo] else { return nil }
        let giorniFa: (Misura) -> Int = {
            Giorni.calendario.dateComponents([.day], from: Giorni.data($0.data), to: Giorni.data(ultima.data)).day ?? 0
        }
        let candidate = con.dropLast().filter { (23...37).contains(giorniFa($0)) }
        guard let inizio = candidate.min(by: { abs(giorniFa($0) - 30) < abs(giorniFa($1) - 30) }),
              let a = inizio[campo] else { return nil }
        return ((fine - a) * 10).rounded() / 10
    }

    // −1,2 kg · +0,4 kg · 0 kg
    static func testoVariazione(_ d: Double, _ unita: String) -> String {
        Testi.conSegno(d, unita: unita)
    }

    private func testoInTrentaGiorni(_ delta: Double, _ campo: CampoMisura) -> String {
        String(localized: "\(Self.testoVariazione(delta, campo.unita)) in 30 giorni")
    }

    // ---------- Peso e grafico ----------

    private func grafico(_ bia: [Misura]) -> some View {
        let campo = metrica
        let misure = misureNelPeriodo(bia, campo)
        let ultimo = bia.last { $0[campo] != nil }?[campo]
        let delta = Self.variazioneTrentaGiorni(bia, campo)
        let punti = misure.compactMap { m in m[campo].map { Punto(data: Giorni.data(m.data), valore: $0) } }
        return Section {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text(campo.nome).font(.headline)
                        .accessibilityIdentifier("grafico-titolo")
                    Spacer()
                    if campo != .peso {
                        Button("Torna al peso") { withAnimation { metrica = .peso } }
                            .font(.subheadline)
                            .tint(.primary)
                            .frame(minHeight: Misure.tocco)
                    }
                }
                HStack(alignment: .firstTextBaseline, spacing: Spazio.xs) {
                    Text(num(ultimo)).numero(.largeTitle)
                        .accessibilityIdentifier("valore-grande")
                    Text(campo.unita).font(.subheadline).foregroundStyle(.secondary)
                }
                if let delta {
                    Text(testoInTrentaGiorni(delta, campo))
                        .font(.subheadline).foregroundStyle(.secondary)
                        .monospacedDigit()
                        .accessibilityIdentifier("variazione")
                }
                if punti.count < 2 {
                    Text(punti.isEmpty ? LocalizedStringKey("Nessun valore in questo periodo.") : LocalizedStringKey("Servono due misurazioni in questo periodo."))
                        .font(.subheadline).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 100)
                } else {
                    let valori = punti.map(\.valore)
                    let basso = valori.min() ?? 0
                    let alto = valori.max() ?? 1
                    let margine = max((alto - basso) * 0.25, 0.5)
                    let minY = floor((basso - margine) * 2) / 2
                    let maxY = ceil((alto + margine) * 2) / 2
                    Chart(punti) { p in
                        AreaMark(x: .value("Data", p.data), yStart: .value("Base", minY), yEnd: .value(campo.nome, p.valore))
                            .interpolationMethod(.monotone)
                            .foregroundStyle(LinearGradient(colors: [Colori.accento.opacity(0.22), .clear], startPoint: .top, endPoint: .bottom))
                        LineMark(x: .value("Data", p.data), y: .value(campo.nome, p.valore))
                            .interpolationMethod(.monotone)
                            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            .foregroundStyle(Colori.accento)
                        PointMark(x: .value("Data", p.data), y: .value(campo.nome, p.valore))
                            .symbolSize(p.id == punti.last?.id ? 70 : 32)
                            .foregroundStyle(Colori.accento)
                    }
                    .chartXScale(range: .plotDimension(padding: 14))
                    .chartYScale(domain: minY...maxY)
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
                    .frame(height: 120)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)   // assi leggibili, senza sovrapporsi al testo grande
                    .padding(.top, Spazio.xs)
                    .accessibilityLabel("Grafico: \(campo.nome)")
                    .accessibilityValue(punti.map { "\(num($0.valore)) \(campo.unita)" }.joined(separator: ", "))
                }
                Picker("Periodo", selection: $periodo) {
                    ForEach(Periodo.allCases) { Text($0.etichetta).tag($0) }
                }
                .pickerStyle(.segmented)
                .controlSize(.small)
                .padding(.top, Spazio.s)
            }
            .padding(.vertical, Spazio.xs)
        }
        .righeTema()
    }

    // ---------- Grasso, magra, vita ----------

    private func composizione(_ bia: [Misura]) -> some View {
        Section {
            ForEach(Self.riquadri, id: \.self) { campo in
                rigaComposizione(bia, campo)
            }
        } header: {
            Text("Composizione").textCase(nil)
        }
        .righeTema()
    }

    private func rigaComposizione(_ bia: [Misura], _ campo: CampoMisura) -> some View {
        let scelto = metrica == campo
        let ultima = bia.last { $0[campo] != nil }
        let valore = ultima?[campo]
        let delta = Self.variazioneTrentaGiorni(bia, campo)
        let dettaglio: Text? = ultima.map { m in
            Text(verbatim: ([dataMisura(m.data)] + (delta.map { [testoInTrentaGiorni($0, campo)] } ?? [])).joined(separator: " · "))
        }
        return Button {
            withAnimation { metrica = scelto ? .peso : campo }
        } label: {
            Riga(Text(verbatim: campo.nome), dettaglio: dettaglio, valore: Text(verbatim: "\(num(valore)) \(campo.unita)")) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.subheadline.weight(scelto ? .semibold : .regular))
                    .foregroundStyle(scelto ? AnyShapeStyle(Colori.sulAccento) : AnyShapeStyle(Colori.accento))
                    .frame(width: 28, height: 28)
                    .background(scelto ? AnyShapeStyle(Colori.accento) : AnyShapeStyle(Colori.accento.opacity(0.14)), in: .rect(cornerRadius: 6))
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 2)
            .frame(minHeight: Misure.tocco)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(campo.nome)
        .accessibilityValue("\(num(valore)) \(campo.unita)" + (delta.map { ", " + testoInTrentaGiorni($0, campo) } ?? ""))
        .accessibilityHint(scelto ? Text("Torna al peso nel grafico") : Text("Mostra nel grafico"))
        .accessibilityAddTraits(scelto ? .isSelected : [])
        .accessibilityIdentifier("metrica-\(campo.rawValue)")
    }

    // ---------- Misurazioni ----------

    private func misurazioni(_ bia: [Misura]) -> some View {
        Section {
            RigheMisure(misure: Array(bia.reversed().prefix(2)))
            NavigationLink(value: PaginaDieta.misure) {
                Text("Tutte le misurazioni")
            }
            .accessibilityIdentifier("tutte-le-misurazioni")
        } header: {
            Text("Misurazioni").textCase(nil)
        }
        .righeTema()
    }
}

// Date come «1 novembre» (con l'anno se non è quello in corso)
func dataMisura(_ iso: String) -> String {
    let d = Giorni.data(iso)
    let stessoAnno = Giorni.calendario.isDate(d, equalTo: Date(), toGranularity: .year)
    return stessoAnno ? d.formatted(.dateTime.day().month(.wide)) : d.formatted(.dateTime.day().month(.wide).year())
}

// Righe delle misurazioni nella schermata Corpo: data e peso, si toccano per modificare
struct RigheMisure: View {
    let misure: [Misura]

    var body: some View {
        ForEach(misure) { m in
            NavigationLink(value: PaginaDieta.misura(m.data)) {
                RigaMisura(misura: m)
            }
            .accessibilityLabel("\(dataMisura(m.data)), \(m.peso.map { kgTesto($0) } ?? String(localized: "senza peso"))")
            .accessibilityHint(Text("Apre la misurazione per modificarla"))
            .accessibilityIdentifier("misura-\(m.data)")
        }
    }
}

// Data e peso di una misurazione
struct RigaMisura: View {
    let misura: Misura

    var body: some View {
        Riga(Text(dataMisura(misura.data)), valore: Text(verbatim: misura.peso.map { kgTesto($0) } ?? "–"))
    }
}

// Progressi → Corpo → Tutte: l'elenco completo. Si tocca per modificare; si elimina con un tocco prolungato o scorrendo
struct MisurazioniView: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.dismiss) private var chiudi
    @State private var daEliminare: Misura?

    var body: some View {
        let bia = archivio.profilo.bia.sorted { $0.data > $1.data }
        List {
            Group {
                Section {
                    if bia.isEmpty {
                        Text("Nessuna misurazione.").foregroundStyle(.secondary)
                    }
                    ForEach(bia) { m in
                        NavigationLink(value: PaginaDieta.misura(m.data)) { RigaMisura(misura: m) }
                            .accessibilityLabel("\(dataMisura(m.data)), \(m.peso.map { kgTesto($0) } ?? String(localized: "senza peso"))")
                            .accessibilityHint(Text("Apre la misurazione per modificarla. Tieni premuto per eliminarla."))
                            .accessibilityIdentifier("misura-\(m.data)")
                            .contextMenu {
                                Button("Elimina", systemImage: "trash", role: .destructive) { daEliminare = m }
                            }
                            .swipeActions {
                                Button("Elimina", systemImage: "trash", role: .destructive) { daEliminare = m }
                            }
                    }
                } header: {
                    Text("\(bia.count) misurazioni")
                }
            }
            .righeTema()
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
