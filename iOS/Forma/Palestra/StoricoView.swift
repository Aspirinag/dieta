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
            Group {
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
                        LabeledContent("Massimale stimato", value: "\(num((r.massimale * 10).rounded() / 10)) kg")
                        LabeledContent("Serie migliore (kg × ripetizioni)", value: volumeTesto(r.volumeSerie))
                        LabeledContent("Più ripetizioni", value: "\(r.ripMax)")
                    }
                }
                if punti.count >= 2 {
                    Section("Andamento") {
                        Picker("Misura", selection: $metrica) {
                            Text("Peso massimo").tag(0)
                            Text("Massimale").tag(1)
                            Text("Kg totali").tag(2)
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
                            Text(voce.allenamento.inizio.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                                .font(.subheadline.weight(.semibold))
                            Text(voce.serie.map { "\($0.riscaldamento ? String(localized: "R") + " " : "")\(num($0.kg ?? 0)) × \($0.rip ?? 0)" }.joined(separator: " · "))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .righeTema()
        }
        .sfondoTema()
        .navigationTitle(e.titolo)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Progressi → Palestra → Tutti: riepilogo e tutti gli allenamenti (pesi e cardio), un riquadro per mese
struct StoricoAllenamenti: View {
    @Environment(Palestra.self) private var palestra

    var body: some View {
        let tutte = palestra.stato.attivitaRecenti()
        let lista = palestra.stato.allenamenti
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if tutte.isEmpty {
                    Riquadro {
                        Text("Nessun allenamento").font(.headline)
                        Text("Gli allenamenti finiti compaiono qui.").font(.subheadline).foregroundStyle(.secondary).padding(.top, 2)
                    }
                } else {
                    let settimana = lista.filter { $0.inizio > Date().addingTimeInterval(-7 * 86400) }
                    Riquadro {
                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .top) { statistiche(settimana, lista) }
                            VStack(alignment: .leading, spacing: 8) { statistiche(settimana, lista) }
                        }
                    }
                    let mesi = Dictionary(grouping: tutte) { String($0.giorno.prefix(7)) }
                    ForEach(mesi.keys.sorted(by: >), id: \.self) { m in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Giorni.data(m + "-01").formatted(.dateTime.month(.wide).year()).capitalized)
                                .font(.headline).padding(.horizontal, 4)
                            Riquadro {
                                ForEach(Array((mesi[m] ?? []).enumerated()), id: \.element.id) { i, voce in
                                    if i > 0 { Divider() }
                                    RigaAttivita(voce: voce)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .sfondoTema()
        .navigationTitle("Allenamenti")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private func statistiche(_ settimana: [Allenamento], _ lista: [Allenamento]) -> some View {
        statistica("Questa settimana", "\(settimana.count)")
        statistica("Kg totali", volumeTesto(settimana.reduce(0) { $0 + $1.volume }))
        statistica("Totale", "\(lista.count)")
    }

    private func statistica(_ titolo: LocalizedStringKey, _ valore: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titolo).font(.caption).foregroundStyle(.secondary)
            Text(valore).font(.headline).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Una riga di allenamento: stesso stile ovunque (Progressi, Tutti, Calendario)
struct RigaAttivita: View {
    let voce: Attivita

    var body: some View {
        switch voce {
        case .pesi(let a): RigaRecente(allenamento: a)
        case .cardio(let c): RigaCardio(cardio: c, conData: true)
        }
    }
}

struct DettaglioAllenamentoView: View {
    @Environment(Palestra.self) private var palestra
    @Environment(Navigazione.self) private var navigazione
    @Environment(\.dismiss) private var chiudi
    let id: UUID
    @State private var chiediElimina = false

    var body: some View {
        if let a = palestra.stato.allenamenti.first(where: { $0.id == id }) {
            List {
                Group {
                    ContenutoAllenamento(allenamento: a)
                    if a.soloWatch {
                        Section {
                            Button("Aggiungi esercizi e pesi", systemImage: "plus") { navigazione.compila = a.id }
                        } footer: {
                            Text("Registrata dall'Apple Watch: scegli la scheda e correggi i pesi.")
                        }
                    }
                    Section {
                        Button("Elimina allenamento", systemImage: "trash", role: .destructive) { chiediElimina = true }
                    }
                }
                .righeTema()
            }
            .sfondoTema()
            .navigationTitle(a.titolo)
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
            LabeledContent("Data", value: a.inizio.formatted(.dateTime.weekday(.wide).day().month(.wide).hour().minute()))
            LabeledContent("Durata", value: durataTesto(a.durata))
            if !a.esercizi.isEmpty {
                LabeledContent("Kg totali", value: volumeTesto(a.volume))
                LabeledContent("Serie", value: "\(a.serieFatte)")
            }
        }
        if let w = a.watch {
            Section {
                if let kcal = w.calorie { LabeledContent("Calorie attive", value: "\(Int(kcal.rounded())) kcal") }
                if let bpm = w.battito { LabeledContent("Battito medio", value: "\(Int(bpm.rounded())) bpm") }
            } header: {
                Label("Apple Watch", systemImage: "applewatch")
            }
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
                    LabeledContent(s.riscaldamento ? LocalizedStringKey("Riscaldamento") : LocalizedStringKey("Serie \(e.serie[..<n].filter { !$0.riscaldamento }.count + 1)"),
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
                Group {
                    Section {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(.tint)
                                .symbolEffect(.bounce, value: allenamento.id)
                            Text("Allenamento finito!").font(.title2.weight(.bold))
                            Text(verbatim: allenamento.titolo).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .listRowBackground(Color.clear)
                    }
                    ContenutoAllenamento(allenamento: allenamento)
                }
                .righeTema()
            }
            .sfondoTema()
            .navigationTitle("Riepilogo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Esercizio.self) { DettaglioEsercizioView(idEsercizio: $0.id) }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Fine") { chiudi() } }
            }
        }
    }
}

// Una sessione di cardio (anche dal Watch). Non ha un dettaglio: si elimina con un tocco prolungato, dopo una conferma
struct RigaCardio: View {
    @Environment(Palestra.self) private var palestra
    let cardio: SessioneCardio
    var conData = false
    @State private var chiediElimina = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: Libreria.simboloCardio(cardio.tipo))
                .foregroundStyle(Colori.accento)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: Libreria.nomeCardio(cardio.tipo)).font(.headline)
                Text(dettaglio).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if cardio.km > 0 {
                Text("\(num(cardio.km)) km").font(.subheadline).foregroundStyle(.secondary).monospacedDigit()
            }
        }
        .frame(minHeight: 44)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("cardio-\(cardio.id.uuidString)")
        .accessibilityHint("Tieni premuto per eliminare")
        .accessibilityAction(named: "Elimina") { chiediElimina = true }
        .contextMenu {
            Button("Elimina", systemImage: "trash", role: .destructive) { chiediElimina = true }
        }
        .confirmationDialog("Eliminare questo cardio?", isPresented: $chiediElimina, titleVisibility: .visible) {
            Button("Elimina", role: .destructive) { palestra.stato.eliminaCardio(cardio.id) }
        }
    }

    private var dettaglio: String {
        var parti: [String] = []
        if conData { parti.append(Giorni.data(cardio.data).formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))) }
        parti.append("\(cardio.minuti) min")
        if let w = cardio.watch {
            parti.append("Watch")
            if let kcal = w.calorie { parti.append("\(Int(kcal.rounded())) kcal") }
        }
        return parti.joined(separator: " · ")
    }
}
