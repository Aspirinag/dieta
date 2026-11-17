import SwiftUI
import Charts

// Pagine di Progressi → Palestra, aperte per valore: le destinazioni stanno sulla radice di Progressi
enum PaginaProgressi: Hashable {
    case allenamenti, calendario, record
}

// Dettaglio di una sessione di cardio (aperta per valore: l'id del cardio)
struct ApriCardio: Hashable {
    let id: UUID
}

// Progressi → Palestra: kg sollevati per settimana, record recenti, ultimi allenamenti
struct ProgressiPalestraView: View {
    @Environment(Palestra.self) private var palestra
    @Environment(\.dynamicTypeSize) private var dimensione

    private static let settimane = 7

    var body: some View {
        let stato = palestra.stato
        if stato.allenamenti.isEmpty && stato.cardio.isEmpty {
            Section {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nessun allenamento").font(.headline)
                    Text("Gli allenamenti finiti compaiono qui, con i kg totali e i record.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.vertical, Spazio.xs)
            }
            .righeTema()
        } else {
            Group {
                volume(stato)
                record(stato)
                allenamenti(stato)
            }
        }
    }

    // ---------- Kg totali per settimana ----------

    private struct Barra: Identifiable {
        let inizio: String          // lunedì della settimana
        let kg: Double
        let ultima: Bool
        var id: String { inizio }
    }

    private func volume(_ stato: StatoPalestra) -> some View {
        let oggi = Giorni.oggi()
        let lunedi = Giorni.lunedi(oggi)
        let volumi = stato.volumiSettimanali(ultime: Self.settimane, oggi: oggi)
        let barre = volumi.enumerated().map { i, kg in
            Barra(inizio: Giorni.aggiungi(lunedi, -7 * (Self.settimane - 1 - i)), kg: kg, ultima: i == volumi.count - 1)
        }
        // Se questa settimana non ha ancora pesi, il titolo mostra l'ultima con dati.
        // Il totale di questa settimana viene dalla funzione unica (da lunedì), la stessa di «Allenamenti»
        let corrente = stato.riepilogoSettimana(oggi: oggi)
        let titolo = barre.last { $0.kg > 0 } ?? barre[barre.count - 1]
        let massimo = volumi.max() ?? 0
        return Section {
            VStack(alignment: .leading, spacing: 0) {
                Text("Kg totali per settimana").font(.headline)
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: Spazio.s) { totale(titolo, corrente) }
                    VStack(alignment: .leading, spacing: Spazio.xs) { totale(titolo, corrente) }
                }
                if volumi.allSatisfy({ $0 == 0 }) {
                    Text("Ancora nessun allenamento con i pesi nelle ultime \(Self.settimane) settimane.")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
                } else {
                    Chart(barre) { b in
                        // Settimane intere in terracotta leggero; la settimana in corso in terracotta pieno con la scritta «finora»
                        BarMark(x: .value("Settimana", etichetta(b.inizio)), y: .value("Kg", b.kg))
                            .cornerRadius(4)
                            .foregroundStyle(b.ultima ? Colori.terracotta : Colori.terracotta.opacity(0.45))
                            .annotation(position: .top, alignment: .center, spacing: 2) {
                                if b.ultima && !dimensione.isAccessibilitySize { Text("finora").font(.caption2).foregroundStyle(.secondary) }
                            }
                    }
                    // A testo di accessibilità le etichette degli assi si sovrapporrebbero: restano nella descrizione per VoiceOver
                    .chartYAxis {
                        AxisMarks(position: .leading, values: dimensione.isAccessibilitySize ? [] : [0, massimo]) { v in
                            AxisGridLine()
                            AxisValueLabel {
                                if let kg = v.as(Double.self) { Text(volumeTesto(kg)).font(.caption2) }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { _ in AxisValueLabel().font(.caption2) }
                    }
                    .modifier(AsseXNascosto(nascosto: dimensione.isAccessibilitySize))
                    .frame(height: 150)
                    .padding(.top, 8)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Grafico: kg totali per settimana")
                    .accessibilityValue(barre.map { String(localized: "settimana del \(etichetta($0.inizio)): \(volumeTesto($0.kg))") }.joined(separator: ", "))
                }
            }
            .padding(.vertical, Spazio.xs)
        }
        .righeTema()
    }

    // Il totale grande con la scritta sotto o accanto: «questa settimana, finora» e il periodo (2–8 novembre)
    @ViewBuilder private func totale(_ titolo: Barra, _ corrente: RiepilogoSettimana) -> some View {
        Text(volumeTesto(titolo.kg)).numero(.largeTitle)
        VStack(alignment: .leading, spacing: 0) {
            if titolo.ultima {
                Text("questa settimana, finora")
                Text(verbatim: corrente.etichetta())
            } else {
                Text(verbatim: Testi.periodo(da: Giorni.data(titolo.inizio), a: Giorni.data(Giorni.aggiungi(titolo.inizio, 6))))
            }
        }
        .font(.subheadline).foregroundStyle(.secondary)
    }

    private func etichetta(_ iso: String) -> String {
        Giorni.data(iso).formatted(.dateTime.day().month(.abbreviated))
    }

    // ---------- Record ----------

    private func record(_ stato: StatoPalestra) -> some View {
        let tutti = stato.recordPerEsercizio()
        return Section {
            if tutti.isEmpty {
                Text("I record compaiono dopo le prime serie con i pesi.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            } else {
                ForEach(tutti.prefix(2)) { r in
                    RigaRecord(record: r)
                }
                if tutti.count > 2 {
                    NavigationLink("Tutti i record", value: PaginaProgressi.record)
                }
            }
        } header: {
            Text("Record recenti").textCase(nil)
        }
        .righeTema()
    }

    // ---------- Allenamenti ----------

    private func allenamenti(_ stato: StatoPalestra) -> some View {
        Section {
            NavigationLink("Tutti gli allenamenti", value: PaginaProgressi.allenamenti)
            NavigationLink("Calendario", value: PaginaProgressi.calendario)
            ForEach(stato.attivitaRecenti(5)) { voce in
                switch voce {
                case .pesi(let a): RigaRecente(allenamento: a)
                case .cardio(let c): RigaCardio(cardio: c, conData: true)
                }
            }
        } header: {
            Text("Allenamenti").textCase(nil)
        }
        .righeTema()
    }
}

// A testo di accessibilità le date sull'asse delle settimane si sovrapporrebbero: le legge VoiceOver
private struct AsseXNascosto: ViewModifier {
    let nascosto: Bool
    func body(content: Content) -> some View {
        if nascosto { content.chartXAxis(.hidden) } else { content }
    }
}

// Un record: esercizio e serie migliore. Si tocca per aprire il grafico dell'esercizio
struct RigaRecord: View {
    @Environment(Palestra.self) private var palestra
    let record: RecordEsercizio

    var body: some View {
        NavigationLink(value: palestra.esercizio(record.esercizio)) {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(palestra.nome(record.esercizio)).lineLimit(2)
                    Text("Peso massimo").font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Text("\(num(record.kg)) kg × \(record.rip)").foregroundStyle(.secondary).numero(.body)
            }
            .frame(minHeight: 44)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(palestra.nome(record.esercizio))
        .accessibilityValue("peso massimo \(num(record.kg)) kg per \(record.rip) ripetizioni")
        .accessibilityHint("Apre il grafico dell'esercizio")
        .accessibilityIdentifier("record-\(record.esercizio)")
    }
}

// Un allenamento con i pesi (o registrato dal Watch): nome, giorno e durata, kg totali. Si tocca per il dettaglio
struct RigaRecente: View {
    @Environment(\.dynamicTypeSize) private var dimensione
    let allenamento: Allenamento

    var body: some View {
        NavigationLink(value: allenamento.id) {
            (dimensione.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4)) : AnyLayout(HStackLayout(spacing: 12))) {
                Image(systemName: allenamento.soloWatch ? "applewatch" : "dumbbell")
                    .foregroundStyle(Colori.terracotta)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: allenamento.titolo).font(.headline)
                    Text(sottotitolo).font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                if !allenamento.esercizi.isEmpty {
                    Text(volumeTesto(allenamento.volume)).font(.subheadline).foregroundStyle(.secondary).monospacedDigit()
                }
            }
            .frame(minHeight: 44)
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Apre il dettaglio")
        .accessibilityIdentifier("allenamento-\(allenamento.id.uuidString)")
    }

    private var sottotitolo: String {
        let giorno = Testi.data(allenamento.inizio)
        return "\(giorno) · \(durataTesto(allenamento.durata))" + (allenamento.soloWatch ? " · Watch" : "")
    }
}

// Progressi → Palestra → Tutti i record
struct RecordView: View {
    @Environment(Palestra.self) private var palestra

    var body: some View {
        let tutti = palestra.stato.recordPerEsercizio()
        List {
            if !tutti.isEmpty {
                Section {
                    ForEach(tutti) { r in
                        RigaRecord(record: r)
                    }
                } header: {
                    Text("\(tutti.count) esercizi").textCase(nil)
                }
                .righeTema()
            }
        }
        .sfondoTema()
        .navigationTitle("Record")
        .navigationBarTitleDisplayMode(.inline)
    }
}
