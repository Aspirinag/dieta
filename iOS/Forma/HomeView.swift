import SwiftUI

// Oggi, la panoramica: pasti del giorno, allenamento (se c'è), acqua e olio, ultimo peso.
// Il dettaglio di ognuno sta nelle schede Dieta e Palestra
struct HomeView: View {
    @Environment(Archivio.self) private var archivio
    @Environment(Palestra.self) private var palestra
    @Environment(Navigazione.self) private var navigazione
    @State private var richiesta: TipoPDF?
    @AppStorage("oggiPastiAperti") private var pastiAperti = false

    private var titolo: String {
        Date().formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "it_IT"))).capitalized
    }

    var body: some View {
        NavigationStack {
            List {
                Group {
                    SezionePagamento()
                    dieta
                    allenamento
                    if archivio.profilo.piano(per: Giorni.oggi()) != nil {
                        SezioneOlioAcqua(giorno: Giorni.oggi())
                    }
                    peso
                }
                .righeTema()
            }
            .sfondoTema()
            .navigationTitle("Oggi")
            .navigationSubtitleSePossibile(titolo)
            .importaPDF($richiesta)
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
                Button(t == .cardio ? "Vai al cardio" : "Apri Palestra", systemImage: "dumbbell") {
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
        if let piano = archivio.profilo.piano(per: oggi) {
            let pasti = piano.giorni[Giorni.indice(oggi)].pasti
            let fatti = pasti.indices.filter { archivio.slot(oggi, $0).fatto }
            Section {
                // Toccando si aprono o chiudono i pasti; la scelta resta salvata
                Button { withAnimation { pastiAperti.toggle() } } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        LabeledContent {
                            HStack(spacing: 6) {
                                Text("\(fatti.count) di \(pasti.count)")
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .rotationEffect(.degrees(pastiAperti ? 90 : 0))
                            }
                        } label: {
                            Text("Pasti segnati").foregroundStyle(.primary)
                        }
                        ProgressView(value: Double(fatti.count), total: Double(max(pasti.count, 1)))
                    }
                }
                .accessibilityIdentifier("pasti-segnati")
                .accessibilityValue(pastiAperti ? "aperta" : "chiusa")
                if pastiAperti {
                    righePasti(pasti, oggi: oggi)
                }
                Button("Dettagli e quantità", systemImage: "fork.knife") { navigazione.scheda = .dieta }
            } header: {
                Text("Dieta · \(archivio.profilo.nome)")
            }
        } else {
            Section {
                Text("Non c'è ancora un piano alimentare.").foregroundStyle(.secondary)
                Button("Carica schema dietetico (PDF)", systemImage: "doc.badge.plus") { richiesta = .schema }
            } header: {
                Text("Dieta · \(archivio.profilo.nome)")
            }
        }
    }

    private func righePasti(_ pasti: [Pasto], oggi: String) -> some View {
                ForEach(pasti.indices, id: \.self) { i in
                    let s = archivio.slot(oggi, i)
                    let p = pasti[i]
                    let opz = p.opzioni.indices.contains(s.opt) ? p.opzioni[s.opt] : p.opzioni.first
                    RigaSpunta(fatto: s.fatto, azione: { archivio.cambiaSlot(oggi, i) { $0.fatto.toggle() } }) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.nome).font(.subheadline.weight(.semibold))
                            Text(opz?.alimenti.map(\.nome).joined(separator: ", ") ?? "")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .opacity(s.fatto ? 0.5 : 1)
                    }
                    .accessibilityIdentifier("riga-pasto")
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
                NavigationLink { AndamentoPagina() } label: {
                    Label("Andamento", systemImage: "chart.line.uptrend.xyaxis")
                }
            }
        }
    }
}

extension View {
    // Sottotitolo con la data sotto "Oggi" (iOS 26 in poi)
    @ViewBuilder
    func navigationSubtitleSePossibile(_ testo: String) -> some View {
        if #available(iOS 26.0, *) { navigationSubtitle(testo) } else { self }
    }
}
