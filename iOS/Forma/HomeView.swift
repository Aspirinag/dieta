import SwiftUI

// Oggi: allenamento del giorno, pasti, acqua e olio, ultimo peso
struct HomeView: View {
    @Environment(Archivio.self) private var archivio
    @Environment(Palestra.self) private var palestra
    @Environment(Navigazione.self) private var navigazione

    private var titolo: String {
        Date().formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "it_IT"))).capitalized
    }

    var body: some View {
        NavigationStack {
            List {
                SezionePagamento()
                allenamento
                dieta
                SezioneOlioAcqua(giorno: Giorni.oggi())
                peso
            }
            .navigationTitle("Oggi")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { MenuProfilo() }
            }
            .navigationDestination(for: UUID.self) { DettaglioAllenamentoView(id: $0) }
            .navigationDestination(for: Esercizio.self) { DettaglioEsercizioView(idEsercizio: $0.id) }
        }
    }

    // ---------- Allenamento ----------

    @ViewBuilder private var allenamento: some View {
        let oggi = Giorni.oggi()
        let t = palestra.programmato(oggi)
        let fatti = palestra.allenamenti(del: oggi)
        let cardio = palestra.cardio(del: oggi)
        Section {
            LabeledContent {
                Text("settimana \(palestra.settimana(oggi))")
            } label: {
                Label(t == .riposo ? "Oggi riposo" : "Oggi \(t.nome.lowercased())", systemImage: t.simbolo)
                    .font(.headline)
            }
            ForEach(fatti) { a in
                NavigationLink(value: a.id) { RigaAllenamento(allenamento: a) }
            }
            ForEach(cardio) { c in
                Label("\(c.tipo) · \(c.minuti) min" + (c.km > 0 ? " · \(num(c.km)) km" : ""), systemImage: "checkmark.circle.fill")
            }
            if let a = palestra.stato.inCorso {
                Button { navigazione.allenamentoAperto = true } label: {
                    Label("Riprendi \(a.nome)", systemImage: "play.fill").frame(maxWidth: .infinity)
                }
                .pulsanteVetro(evidente: true)
            } else if fatti.isEmpty && cardio.isEmpty {
                if t == .pesi, let r = palestra.stato.routine.first {
                    Button {
                        palestra.inizia(r)
                        navigazione.allenamentoAperto = true
                    } label: {
                        Label("Inizia \(r.nome)", systemImage: "play.fill").frame(maxWidth: .infinity)
                    }
                    .pulsanteVetro(evidente: true)
                }
                Button(t == .cardio ? "Vai al cardio" : "Altri allenamenti", systemImage: "dumbbell") {
                    navigazione.scheda = .allenamento
                }
            }
        } header: {
            Text("Allenamento")
        }
    }

    // ---------- Dieta ----------

    @ViewBuilder private var dieta: some View {
        let oggi = Giorni.oggi()
        Section {
            if let piano = archivio.profilo.piano(per: oggi) {
                let pasti = piano.giorni[Giorni.indice(oggi)].pasti
                let fatti = pasti.indices.filter { archivio.slot(oggi, $0).fatto }
                VStack(alignment: .leading, spacing: 6) {
                    LabeledContent("Pasti", value: "\(fatti.count) di \(pasti.count)")
                    ProgressView(value: Double(fatti.count), total: Double(max(pasti.count, 1)))
                }
                if let prossimo = pasti.indices.first(where: { !archivio.slot(oggi, $0).fatto }) {
                    let s = archivio.slot(oggi, prossimo)
                    let p = pasti[prossimo]
                    let opz = p.opzioni.indices.contains(s.opt) ? p.opzioni[s.opt] : p.opzioni.first
                    RigaSpunta(fatto: false, azione: { archivio.cambiaSlot(oggi, prossimo) { $0.fatto = true } }) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Prossimo: \(p.nome)").font(.subheadline.weight(.semibold))
                            Text(opz?.alimenti.map(\.nome).joined(separator: ", ") ?? "")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                } else {
                    Label("Tutti i pasti di oggi sono segnati", systemImage: "checkmark.seal.fill").foregroundStyle(.tint)
                }
                Button("Apri la dieta di oggi", systemImage: "fork.knife") { navigazione.scheda = .dieta }
            } else {
                Text("Nessun piano alimentare: caricalo dalla scheda Profilo.").foregroundStyle(.secondary)
            }
        } header: {
            Text("Dieta · \(archivio.profilo.nome)")
        }
    }

    // ---------- Peso ----------

    @ViewBuilder private var peso: some View {
        let bia = archivio.profilo.bia.filter { $0.peso != nil }.sorted { $0.data < $1.data }
        if let ultimo = bia.last {
            Section("Corpo") {
                LabeledContent("Ultimo peso (\(Giorni.breve(ultimo.data)))", value: "\(num(ultimo.peso)) kg")
                if let primo = bia.first, primo.data != ultimo.data, let a = primo.peso, let b = ultimo.peso {
                    LabeledContent("Dall'inizio", value: "\(b - a > 0 ? "+" : "")\(num(((b - a) * 10).rounded() / 10)) kg")
                }
                Button("Vedi i progressi", systemImage: "chart.line.uptrend.xyaxis") { navigazione.scheda = .progressi }
            }
        }
    }
}
