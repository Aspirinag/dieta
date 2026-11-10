import SwiftUI

// Impostazioni della palestra: pagamento e Apple Watch
struct SezioniPalestra: View {
    // Nelle Impostazioni pagamento e Watch stanno in due pagine
    enum Parte { case pagamento, watch }
    let parte: Parte
    @Environment(Palestra.self) private var palestra
    @AppStorage(Salute.chiave) private var watch = true
    @State private var senzaPermesso = false

    var body: some View {
        if parte != .watch {
            sezionePalestra
                .task { await controllaPermesso() }
        }
        if parte != .pagamento {
            sezioneWatch
        }
    }

    @ViewBuilder private var sezioneWatch: some View {
        Section {
            Toggle(isOn: Binding(get: { watch }, set: { v in cambiaWatch(v) })) {
                Label("Allenamenti dall'Apple Watch", systemImage: "applewatch")
            }
        } footer: {
            Text("Le sessioni di palestra registrate sul Watch entrano da sole in Forma, con una notifica per aggiungere esercizi e pesi. Camminate, corsa, bici e nuoto di almeno \(Salute.minutiCardio) minuti diventano cardio. Forma legge da Salute, non scrive niente.")
        }
    }

    // Il promemoria del pagamento promesso nelle impostazioni ha bisogno delle notifiche
    private func controllaPermesso() async {
        if palestra.stato.pagamentoAttivo, !(await Notifiche.permesso()) { senzaPermesso = true }
    }

    private func cambiaWatch(_ v: Bool) {
        watch = v
        Task {
            if v, await Salute.shared.chiediPermesso() {
                Salute.shared.avvia(palestra)
                await Salute.shared.importa()
            } else if !v {
                Salute.shared.ferma()
            }
        }
    }

    @ViewBuilder private var sezionePalestra: some View {
        let mese = Palestra.mese(Giorni.oggi())
        let pagato = palestra.stato.pagamenti[mese]
        Section {
            Toggle(isOn: Binding(get: { palestra.stato.pagamentoAttivo }, set: { v in
                palestra.stato.pagamentoAttivo = v
                Task {
                    if v, !(await Notifiche.permesso()) { senzaPermesso = true }
                    await palestra.programmaPagamento()
                }
            })) {
                Label("Ricordami il pagamento", systemImage: "bell.badge")
            }
            if palestra.stato.pagamentoAttivo {
                Stepper("Si paga il \(palestra.stato.giornoPagamento) del mese", value: Binding(
                    get: { palestra.stato.giornoPagamento },
                    set: { v in
                        palestra.stato.giornoPagamento = v
                        Task { await palestra.programmaPagamento() }
                    }
                ), in: 1...28)
            }
            if let pagato {
                LabeledContent {
                    Text("pagato il \(Giorni.breve(pagato))")
                } label: {
                    Label("Pagamento del mese", systemImage: "creditcard")
                }
                .swipeActions {
                    Button("Annulla", systemImage: "arrow.uturn.backward", role: .destructive) { palestra.annullaPagamento(mese) }
                }
            } else {
                Button("Segna questo mese come pagato", systemImage: "creditcard") { palestra.segnaPagato(mese) }
            }
            if palestra.stato.pagamentoAttivo {
                SceltaOrario(titolo: "Promemoria del pagamento alle", minuti: palestra.stato.oraPagamento) { m in
                    palestra.stato.oraPagamento = m
                    Task { await palestra.programmaPagamento() }
                }
            }
        } header: {
            Text("Palestra")
        } footer: {
            if palestra.stato.pagamentoAttivo {
                Text("Una settimana prima compare un avviso in Oggi. Il giorno del pagamento arriva una notifica alle \(PromemoriaImpostazioni.orario(palestra.stato.oraPagamento)), se non hai già segnato il mese come pagato.")
                if senzaPermesso {
                    Text("Le notifiche di Forma sono spente: il promemoria non può arrivare. Attivale in Impostazioni → Notifiche → Forma.")
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}

struct PianoSettimanaleView: View {
    @Environment(Palestra.self) private var palestra

    var body: some View {
        List {
            Group {
                Section {
                    Toggle("Alterna settimane A e B", isOn: Binding(get: { palestra.stato.usaAB }, set: { palestra.stato.usaAB = $0 }))
                    if palestra.stato.usaAB {
                        // «Scambia» è un'azione: si annulla toccandola di nuovo
                        LabeledContent("Questa settimana", value: palestra.settimana(Giorni.oggi()))
                        Button("Scambia A e B") { palestra.stato.scambia.toggle() }
                    }
                } footer: {
                    Text(palestra.stato.usaAB
                         ? LocalizedStringKey("Le settimane A e B si alternano da sole. Il piano dice in Oggi se è giorno di pesi, cardio o riposo.")
                         : LocalizedStringKey("Ogni settimana vale lo stesso piano. Il piano dice in Oggi se è giorno di pesi, cardio o riposo."))
                }
                ForEach(palestra.stato.usaAB ? ["A", "B"] : ["A"], id: \.self) { w in
                    Section(palestra.stato.usaAB ? LocalizedStringKey("Settimana \(w)") : LocalizedStringKey("Ogni settimana")) {
                        ForEach(0..<7, id: \.self) { i in
                            Picker(Giorni.nomeGiorno(i), selection: Binding(
                                get: { palestra.stato.piani[w].flatMap { $0.indices.contains(i) ? $0[i] : nil } ?? .riposo },
                                set: { if palestra.stato.piani[w]?.indices.contains(i) == true { palestra.stato.piani[w]?[i] = $0 } }
                            )) {
                                ForEach(TipoGiorno.allCases) { t in Label(t.nome, systemImage: t.simbolo).tag(t) }
                            }
                        }
                    }
                }
            }
            .righeTema()
        }
        .tint(.primary)
        .sfondoTema()
        .navigationTitle("Programma della settimana")
        .navigationBarTitleDisplayMode(.inline)
    }
}
