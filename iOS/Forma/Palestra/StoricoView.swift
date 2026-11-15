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
        let storico = palestra.storico(idEsercizio)
        let migliore = storico.flatMap(\.serie).filter(\.valida).max { $0.volume < $1.volume }
        List {
            Group {
                Section {
                    HStack(spacing: Spazio.l) {
                        IconaEsercizio(esercizio: e, lato: 56)
                        VStack(alignment: .leading) {
                            Text(e.muscolo.nome).font(.headline)
                            Text(e.attrezzo.nome).foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
                if r.pesoMax > 0 || r.ripMax > 0 {
                    Section {
                        LabeledContent("Peso massimo", value: "\(num(r.pesoMax)) kg")
                        LabeledContent("Massimale stimato (1 ripetizione)", value: "\(num((r.massimale * 10).rounded() / 10)) kg")
                        if let m = migliore {
                            LabeledContent("Serie migliore", value: "\(num(m.kg ?? 0)) kg × \(m.rip ?? 0)")
                        }
                        LabeledContent("Più ripetizioni", value: "\(r.ripMax)")
                    } header: {
                        Text("Record personali")
                    } footer: {
                        Text("Il massimale è una stima del peso con cui faresti una sola ripetizione.")
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
                            // Linea retta tra i punti: niente valori inventati tra una seduta e l'altra
                            LineMark(x: .value("Data", p.data), y: .value("kg", v))
                                .interpolationMethod(.linear)
                                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                                .foregroundStyle(.primary)
                            PointMark(x: .value("Data", p.data), y: .value("kg", v))
                                .foregroundStyle(.primary)
                        }
                        .chartYScale(domain: .automatic(includesZero: false))
                        .frame(height: 200)
                        .padding(.vertical, 6)
                    }
                }
                Section("Storico") {
                    if storico.isEmpty {
                        Text("Ancora nessuna serie con questo esercizio.").foregroundStyle(.secondary)
                    }
                    ForEach(Array(storico.enumerated()), id: \.offset) { _, voce in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Testi.data(voce.allenamento.inizio))
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
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if tutte.isEmpty {
                    Riquadro {
                        Text("Nessun allenamento").font(.headline)
                        Text("Gli allenamenti finiti compaiono qui.").font(.subheadline).foregroundStyle(.secondary).padding(.top, 2)
                    }
                } else {
                    riepilogoSettimana
                    let mesi = Dictionary(grouping: tutte) { String($0.giorno.prefix(7)) }
                    ForEach(mesi.keys.sorted(by: >), id: \.self) { m in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Giorni.data(m + "-01").formatted(.dateTime.month(.wide).year()))
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

    // Questa settimana = da lunedì a domenica, la stessa definizione del grafico in Progressi
    private var riepilogoSettimana: some View {
        let sett = palestra.stato.riepilogoSettimana(oggi: Giorni.oggi())
        return Riquadro {
            Text("Questa settimana").font(.headline)
            Text(verbatim: sett.etichetta()).font(.subheadline).foregroundStyle(.secondary)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top) { statistiche(sett) }
                VStack(alignment: .leading, spacing: Spazio.s) { statistiche(sett) }
            }
            .padding(.top, Spazio.s)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private func statistiche(_ sett: RiepilogoSettimana) -> some View {
        statistica("Allenamenti", "\(sett.allenamenti)")
        statistica("Kg totali", volumeTesto(sett.kg))
        statistica("Allenamenti in tutto", "\(palestra.stato.allenamenti.count + palestra.stato.cardio.count)")
    }

    private func statistica(_ titolo: LocalizedStringKey, _ valore: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titolo).font(.caption).foregroundStyle(.secondary)
            Text(valore).numero(.title3)
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

// Statistiche, record ed esercizi di un allenamento (dettaglio storico). Nel riepilogo di fine allenamento
// i numeri stanno in testa e la data non si ripete: `riepilogo: true`
struct ContenutoAllenamento: View {
    @Environment(Palestra.self) private var palestra
    let allenamento: Allenamento
    var riepilogo = false

    var body: some View {
        let a = allenamento
        if !riepilogo {
            Section {
                LabeledContent("Data", value: Testi.data(a.inizio, anno: true))
                LabeledContent("Inizio", value: a.inizio.formatted(date: .omitted, time: .shortened))
                LabeledContent("Durata", value: durataTesto(a.durata))
                if !a.esercizi.isEmpty {
                    LabeledContent("Kg totali", value: volumeTesto(a.volume))
                    LabeledContent("Serie", value: "\(a.serieFatte)")
                }
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
        // Una riga per esercizio: «77,5 kg × 12 · 11 · 10»
        if !a.esercizi.isEmpty {
            Section("Esercizi") {
                ForEach(a.esercizi) { e in
                    NavigationLink(value: palestra.esercizio(e.esercizio)) {
                        Riga(Text(palestra.nome(e.esercizio)), dettaglio: Text(verbatim: Self.riassunto(e.serie)), evidente: true)
                    }
                }
            }
        }
    }

    // Le serie con lo stesso peso si uniscono: «77,5 kg × 12 · 11 · 10»; pesi diversi vanno a capo.
    // Il riscaldamento è a parte, con la sua etichetta.
    static func riassunto(_ serie: [SerieFatta], riscaldamento: String = String(localized: "Riscaldamento")) -> String {
        func gruppi(_ lista: [SerieFatta]) -> [String] {
            var righe: [(kg: Double, rip: [Int])] = []
            for s in lista {
                let kg = s.kg ?? 0
                if let ultima = righe.last, ultima.kg == kg { righe[righe.count - 1].rip.append(s.rip ?? 0) }
                else { righe.append((kg, [s.rip ?? 0])) }
            }
            return righe.map { "\(num($0.kg)) kg × " + $0.rip.map(String.init).joined(separator: " · ") }
        }
        var righe = gruppi(serie.filter { !$0.riscaldamento })
        let caldo = gruppi(serie.filter(\.riscaldamento))
        if !caldo.isEmpty { righe.append(riscaldamento + ": " + caldo.joined(separator: ", ")) }
        return righe.joined(separator: "\n")
    }
}

// Mostrato appena finito un allenamento: titolo = scheda, tre numeri e il confronto con l'ultima volta
struct RiepilogoView: View {
    @Environment(\.dismiss) private var chiudi
    @Environment(Palestra.self) private var palestra
    let allenamento: Allenamento

    // L'ultimo allenamento fatto con la stessa scheda, se c'è
    private var precedente: Allenamento? {
        guard let r = allenamento.routine else { return nil }
        return palestra.stato.allenamenti.filter { $0.routine == r && $0.id != allenamento.id && $0.inizio < allenamento.inizio }
            .max { $0.inizio < $1.inizio }
    }

    var body: some View {
        NavigationStack {
            List {
                Group {
                    Section {
                        numeri
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: Spazio.m, leading: 0, bottom: Spazio.m, trailing: 0))
                    }
                    ContenutoAllenamento(allenamento: allenamento, riepilogo: true)
                }
                .righeTema()
            }
            .sfondoTema()
            .navigationTitle(Text(verbatim: allenamento.titolo))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Esercizio.self) { DettaglioEsercizioView(idEsercizio: $0.id) }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Fine") { chiudi() } }
            }
        }
    }

    private var numeri: some View {
        let a = allenamento, p = precedente
        let minuti = { (x: Allenamento) in Double(Int(x.durata / 60)) }
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .top) { colonne(a, p, minuti) }
            VStack(alignment: .leading, spacing: Spazio.l) { colonne(a, p, minuti) }
        }
    }

    @ViewBuilder private func colonne(_ a: Allenamento, _ p: Allenamento?, _ minuti: (Allenamento) -> Double) -> some View {
        numero("Durata", durataTesto(a.durata), p.map { Testi.conSegno(minuti(a) - minuti($0), unita: "min") })
        numero("Kg totali", volumeTesto(a.volume), p.map { Testi.conSegno((a.volume - $0.volume).rounded(), unita: "kg") })
        numero("Serie", "\(a.serieFatte)", p.map { Testi.conSegno(Double(a.serieFatte - $0.serieFatte), unita: "") .trimmingCharacters(in: .whitespaces) })
    }

    private func numero(_ titolo: LocalizedStringKey, _ valore: String, _ differenza: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titolo).font(.subheadline).foregroundStyle(.secondary)
            Text(valore).numero(.title)
            if let differenza {
                Text(verbatim: differenza).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

// Una sessione di cardio (anche dal Watch): si tocca per il dettaglio, dove si elimina
struct RigaCardio: View {
    @Environment(\.dynamicTypeSize) private var dimensione
    let cardio: SessioneCardio
    var conData = false

    var body: some View {
        NavigationLink(value: ApriCardio(id: cardio.id)) {
            (dimensione.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4)) : AnyLayout(HStackLayout(spacing: 12))) {
                Image(systemName: Libreria.simboloCardio(cardio.tipo))
                    .foregroundStyle(.secondary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: Libreria.nomeCardio(cardio.tipo)).font(.headline)
                    Text(dettaglio).font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                if cardio.km > 0 {
                    Text("\(num(cardio.km)) km").font(.subheadline).foregroundStyle(.secondary).numero(.subheadline)
                }
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
            }
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Apre il dettaglio")
        .accessibilityIdentifier("cardio-\(cardio.id.uuidString)")
    }

    private var dettaglio: String {
        var parti: [String] = []
        if conData { parti.append(Testi.data(Giorni.data(cardio.data))) }
        parti.append("\(cardio.minuti) min")
        if let w = cardio.watch {
            parti.append("Watch")
            if let kcal = w.calorie { parti.append("\(Int(kcal.rounded())) kcal") }
        }
        return parti.joined(separator: " · ")
    }
}

// Dettaglio di una sessione di cardio: durata, distanza, calorie; qui si elimina
struct DettaglioCardioView: View {
    @Environment(Palestra.self) private var palestra
    @Environment(\.dismiss) private var chiudi
    let id: UUID
    @State private var chiediElimina = false

    var body: some View {
        if let c = palestra.stato.cardio.first(where: { $0.id == id }) {
            List {
                Group {
                    Section {
                        LabeledContent("Data", value: Testi.data(Giorni.data(c.data), anno: true))
                        LabeledContent("Durata", value: "\(c.minuti) min")
                        if c.km > 0 { LabeledContent("Distanza", value: "\(num(c.km)) km") }
                    }
                    if let w = c.watch {
                        Section {
                            if let kcal = w.calorie { LabeledContent("Calorie attive", value: "\(Int(kcal.rounded())) kcal") }
                            if let bpm = w.battito { LabeledContent("Battito medio", value: "\(Int(bpm.rounded())) bpm") }
                        } header: {
                            Label("Apple Watch", systemImage: "applewatch")
                        }
                    }
                    Section {
                        Button("Elimina cardio", systemImage: "trash", role: .destructive) { chiediElimina = true }
                            .tint(.red)
                    }
                }
                .righeTema()
            }
            .sfondoTema()
            .navigationTitle(Text(verbatim: Libreria.nomeCardio(c.tipo)))
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Eliminare questo cardio?", isPresented: $chiediElimina, titleVisibility: .visible) {
                Button("Elimina", role: .destructive) {
                    palestra.stato.eliminaCardio(id)
                    chiudi()
                }
            }
        }
    }
}
