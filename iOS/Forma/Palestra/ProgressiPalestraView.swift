import SwiftUI
import Charts

// Pagine di Progressi → Palestra, aperte per valore: le destinazioni stanno sulla radice di Progressi
enum PaginaProgressi: Hashable {
    case allenamenti, calendario, record
}

// Progressi → Palestra: kg sollevati per settimana, record recenti, ultimi allenamenti
struct ProgressiPalestraView: View {
    @Environment(Palestra.self) private var palestra

    private static let settimane = 7

    var body: some View {
        let stato = palestra.stato
        if stato.allenamenti.isEmpty && stato.cardio.isEmpty {
            Riquadro {
                Text("Nessun allenamento").font(.headline)
                Text("Gli allenamenti finiti compaiono qui, con i kg totali e i record.")
                    .font(.subheadline).foregroundStyle(.secondary).padding(.top, 2)
            }
        } else {
            volume(stato)
            record(stato)
            allenamenti(stato)
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
        // Se questa settimana non ha ancora pesi, il titolo mostra l'ultima con dati
        let titolo = barre.last { $0.kg > 0 } ?? barre[barre.count - 1]
        return Riquadro {
            Text("Kg totali per settimana").font(.headline)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(volumeTesto(titolo.kg)).font(.system(size: 34, weight: .bold)).monospacedDigit()
                Text(titolo.ultima ? LocalizedStringKey("questa settimana") : LocalizedStringKey("settimana del \(etichetta(titolo.inizio))"))
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            if volumi.allSatisfy({ $0 == 0 }) {
                Text("Ancora nessun allenamento con i pesi nelle ultime \(Self.settimane) settimane.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
            } else {
                Chart(barre) { b in
                    BarMark(x: .value("Settimana", etichetta(b.inizio)), y: .value("Kg", b.kg))
                        .cornerRadius(4)
                        .foregroundStyle(b.ultima ? Colori.accento : Colori.accento.opacity(0.35))
                }
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks { _ in AxisValueLabel().font(.caption2) }
                }
                .frame(height: 150)
                .padding(.top, 8)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Grafico: kg totali per settimana")
                .accessibilityValue(barre.map { String(localized: "settimana del \(etichetta($0.inizio)): \(volumeTesto($0.kg))") }.joined(separator: ", "))
            }
        }
    }

    private func etichetta(_ iso: String) -> String {
        Giorni.data(iso).formatted(.dateTime.day().month(.abbreviated))
    }

    // ---------- Record ----------

    private func record(_ stato: StatoPalestra) -> some View {
        let tutti = stato.recordPerEsercizio()
        return VStack(spacing: 4) {
            intestazione("Record recenti") {
                if tutti.count > 2 { collegamento("Tutti", etichetta: "Tutti i record", pagina: .record) }
            }
            Riquadro {
                if tutti.isEmpty {
                    Text("I record compaiono dopo le prime serie con i pesi.")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                } else {
                    ForEach(Array(tutti.prefix(2).enumerated()), id: \.element.id) { i, r in
                        if i > 0 { Divider() }
                        RigaRecord(record: r)
                    }
                }
            }
        }
    }

    // ---------- Allenamenti ----------

    private func allenamenti(_ stato: StatoPalestra) -> some View {
        VStack(spacing: 4) {
            intestazione("Allenamenti") {
                HStack(spacing: 4) {
                    collegamento("Tutti", etichetta: "Tutti gli allenamenti", pagina: .allenamenti)
                    collegamento("Calendario", etichetta: "Calendario", pagina: .calendario)
                }
            }
            Riquadro {
                ForEach(Array(stato.attivitaRecenti(5).enumerated()), id: \.element.id) { i, voce in
                    if i > 0 { Divider() }
                    switch voce {
                    case .pesi(let a): RigaRecente(allenamento: a)
                    case .cardio(let c): RigaCardio(cardio: c, conData: true)
                    }
                }
            }
        }
    }

    private func intestazione<Azioni: View>(_ titolo: LocalizedStringKey, @ViewBuilder azioni: () -> Azioni) -> some View {
        HStack {
            Text(titolo).font(.headline)
            Spacer()
            azioni()
        }
        .padding(.horizontal, 4)
    }

    private func collegamento(_ testo: LocalizedStringKey, etichetta: LocalizedStringKey, pagina: PaginaProgressi) -> some View {
        NavigationLink(value: pagina) {
            Text(testo).font(.subheadline.weight(.semibold)).foregroundStyle(Colori.accento)
                .padding(.horizontal, 6)
                .frame(minHeight: 44)
                .contentShape(.rect)
        }
        .accessibilityLabel(Text(etichetta))
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
                Text("\(num(record.kg)) kg × \(record.rip)").foregroundStyle(.secondary).monospacedDigit()
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
            }
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(palestra.nome(record.esercizio))
        .accessibilityValue("peso massimo \(num(record.kg)) kg per \(record.rip) ripetizioni")
        .accessibilityHint("Apre il grafico dell'esercizio")
        .accessibilityIdentifier("record-\(record.esercizio)")
    }
}

// Un allenamento con i pesi (o registrato dal Watch): nome, giorno e durata, kg totali. Si tocca per il dettaglio
struct RigaRecente: View {
    let allenamento: Allenamento

    var body: some View {
        NavigationLink(value: allenamento.id) {
            HStack(spacing: 12) {
                Image(systemName: allenamento.soloWatch ? "applewatch" : "dumbbell")
                    .foregroundStyle(Colori.accento)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: allenamento.titolo).font(.headline)
                    Text(sottotitolo).font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                if !allenamento.esercizi.isEmpty {
                    Text(volumeTesto(allenamento.volume)).font(.subheadline).foregroundStyle(.secondary).monospacedDigit()
                }
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
            }
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Apre il dettaglio")
        .accessibilityIdentifier("allenamento-\(allenamento.id.uuidString)")
    }

    private var sottotitolo: String {
        let giorno = allenamento.inizio.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        return "\(giorno) · \(durataTesto(allenamento.durata))" + (allenamento.soloWatch ? " · Watch" : "")
    }
}

// Progressi → Palestra → Tutti i record
struct RecordView: View {
    @Environment(Palestra.self) private var palestra

    var body: some View {
        let tutti = palestra.stato.recordPerEsercizio()
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(tutti.count) esercizi")
                    .font(.subheadline).foregroundStyle(.secondary).padding(.horizontal, 4)
                if !tutti.isEmpty {
                    Riquadro {
                        ForEach(Array(tutti.enumerated()), id: \.element.id) { i, r in
                            if i > 0 { Divider() }
                            RigaRecord(record: r)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .sfondoTema()
        .navigationTitle("Record")
        .navigationBarTitleDisplayMode(.inline)
    }
}
