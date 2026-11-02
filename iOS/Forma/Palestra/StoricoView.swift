import SwiftUI
import Charts

// Record, grafico e storico di un esercizio
struct DettaglioEsercizioView: View {
    @Environment(Palestra.self) private var palestra
    let idEsercizio: String
    @State private var metrica = 0

    var body: some View {
        let e = palestra.esercizio(idEsercizio)
        let r = palestra.record(idEsercizio)
        let punti = palestra.andamento(idEsercizio)
        List {
            Section {
                HStack(spacing: 14) {
                    IconaEsercizio(esercizio: e, lato: 56)
                    VStack(alignment: .leading) {
                        Text(e.muscolo.nome).font(.headline)
                        Text(e.attrezzo.nome).foregroundStyle(.secondary)
                    }
                }
            }
            if r.pesoMax > 0 || r.ripMax > 0 {
                Section("Record personali") {
                    LabeledContent("Peso massimo", value: "\(num(r.pesoMax)) kg")
                    LabeledContent("Massimale stimato (1RM)", value: "\(num((r.massimale * 10).rounded() / 10)) kg")
                    LabeledContent("Miglior serie (volume)", value: volumeTesto(r.volumeSerie))
                    LabeledContent("Più ripetizioni", value: "\(r.ripMax)")
                }
            }
            if punti.count >= 2 {
                Section("Andamento") {
                    Picker("Misura", selection: $metrica) {
                        Text("Peso max").tag(0)
                        Text("1RM stimato").tag(1)
                        Text("Volume").tag(2)
                    }
                    .pickerStyle(.segmented)
                    Chart(punti) { p in
                        let v = metrica == 0 ? p.peso : metrica == 1 ? p.massimale : p.volume
                        LineMark(x: .value("Data", p.data), y: .value("kg", v))
                            .interpolationMethod(.monotone)
                            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        PointMark(x: .value("Data", p.data), y: .value("kg", v))
                    }
                    .chartYScale(domain: .automatic(includesZero: false))
                    .frame(height: 200)
                    .padding(.vertical, 6)
                }
            }
            let storico = palestra.storico(idEsercizio)
            Section("Storico") {
                if storico.isEmpty {
                    Text("Ancora nessuna serie con questo esercizio.").foregroundStyle(.secondary)
                }
                ForEach(Array(storico.enumerated()), id: \.offset) { _, voce in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(voce.allenamento.inizio.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "it_IT"))))
                            .font(.subheadline.weight(.semibold))
                        Text(voce.serie.map { "\($0.riscaldamento ? "R " : "")\(num($0.kg ?? 0)) × \($0.rip ?? 0)" }.joined(separator: " · "))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(e.nome)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Elenco degli allenamenti, dal più recente
struct StoricoAllenamenti: View {
    @Environment(Palestra.self) private var palestra

    var body: some View {
        let lista = palestra.stato.allenamenti.sorted { $0.inizio > $1.inizio }
        if lista.isEmpty {
            ContentUnavailableView("Nessun allenamento", systemImage: "dumbbell",
                                   description: Text("Gli allenamenti finiti compaiono qui."))
        } else {
            Section {
                let settimana = lista.filter { $0.inizio > Date().addingTimeInterval(-7 * 86400) }
                HStack {
                    statistica("Questa settimana", "\(settimana.count)")
                    statistica("Volume", volumeTesto(settimana.reduce(0) { $0 + $1.volume }))
                    statistica("Totale", "\(lista.count)")
                }
            }
            let mesi = Dictionary(grouping: lista) { String($0.giorno.prefix(7)) }
            ForEach(mesi.keys.sorted(by: >), id: \.self) { m in
                Section(Giorni.data(m + "-01").formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "it_IT"))).capitalized) {
                    ForEach(mesi[m] ?? []) { a in
                        NavigationLink(value: a.id) { RigaAllenamento(allenamento: a) }
                    }
                }
            }
        }
    }

    private func statistica(_ titolo: String, _ valore: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titolo).font(.caption).foregroundStyle(.secondary)
            Text(valore).font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RigaAllenamento: View {
    @Environment(Palestra.self) private var palestra
    let allenamento: Allenamento

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(allenamento.nome).font(.headline)
                Spacer()
                Text(allenamento.inizio.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(Locale(identifier: "it_IT"))))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 14) {
                Label(durataTesto(allenamento.durata), systemImage: "clock")
                Label(volumeTesto(allenamento.volume), systemImage: "scalemass")
                let record = palestra.nuoviRecord(allenamento).count
                if record > 0 { Label("\(record)", systemImage: "trophy.fill").foregroundStyle(.yellow) }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            Text(allenamento.esercizi.map { "\($0.serie.count) × \(palestra.nome($0.esercizio))" }.joined(separator: ", "))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
    }
}

struct DettaglioAllenamentoView: View {
    @Environment(Palestra.self) private var palestra
    @Environment(\.dismiss) private var chiudi
    let id: UUID
    @State private var chiediElimina = false

    var body: some View {
        if let a = palestra.stato.allenamenti.first(where: { $0.id == id }) {
            List {
                ContenutoAllenamento(allenamento: a)
                Section {
                    Button("Elimina allenamento", systemImage: "trash", role: .destructive) { chiediElimina = true }
                }
            }
            .navigationTitle(a.nome)
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Eliminare l'allenamento?", isPresented: $chiediElimina, titleVisibility: .visible) {
                Button("Elimina", role: .destructive) {
                    palestra.stato.allenamenti.removeAll { $0.id == id }
                    chiudi()
                }
            }
        }
    }
}

// Statistiche, record ed esercizi di un allenamento (dettaglio e riepilogo)
struct ContenutoAllenamento: View {
    @Environment(Palestra.self) private var palestra
    let allenamento: Allenamento

    var body: some View {
        let a = allenamento
        Section {
            LabeledContent("Data", value: a.inizio.formatted(.dateTime.weekday(.wide).day().month(.wide).hour().minute().locale(Locale(identifier: "it_IT"))))
            LabeledContent("Durata", value: durataTesto(a.durata))
            LabeledContent("Volume", value: volumeTesto(a.volume))
            LabeledContent("Serie", value: "\(a.serieFatte)")
        }
        let record = palestra.nuoviRecord(a)
        if !record.isEmpty {
            Section("Nuovi record") {
                ForEach(record, id: \.self) { Label($0, systemImage: "trophy.fill").foregroundStyle(.primary) }
            }
        }
        ForEach(a.esercizi) { e in
            Section {
                ForEach(Array(e.serie.enumerated()), id: \.offset) { n, s in
                    LabeledContent(s.riscaldamento ? "Riscaldamento" : "Serie \(e.serie[..<n].filter { !$0.riscaldamento }.count + 1)",
                                   value: "\(num(s.kg ?? 0)) kg × \(s.rip ?? 0)")
                }
            } header: {
                NavigationLink(value: palestra.esercizio(e.esercizio)) {
                    Text(palestra.nome(e.esercizio))
                }
            }
        }
    }
}

// Mostrato appena finito un allenamento
struct RiepilogoView: View {
    @Environment(\.dismiss) private var chiudi
    let allenamento: Allenamento

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.tint)
                            .symbolEffect(.bounce, value: allenamento.id)
                        Text("Allenamento completato!").font(.title2.weight(.bold))
                        Text(allenamento.nome).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                }
                ContenutoAllenamento(allenamento: allenamento)
            }
            .navigationTitle("Riepilogo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Esercizio.self) { DettaglioEsercizioView(idEsercizio: $0.id) }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Fine") { chiudi() } }
            }
        }
    }
}
