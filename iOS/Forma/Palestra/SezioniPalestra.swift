import SwiftUI

// Sezioni della palestra nella scheda Profilo: piano settimanale A/B, pagamento, libreria
struct SezioniPalestra: View {
    @Environment(Palestra.self) private var palestra
    @AppStorage(Salute.chiave) private var watch = true

    var body: some View {
        sezionePalestra
        Section {
            Toggle(isOn: Binding(get: { watch }, set: { v in cambiaWatch(v) })) {
                Label("Allenamenti dall'Apple Watch", systemImage: "applewatch")
            }
        } footer: {
            Text("Le sessioni di palestra registrate sul Watch entrano da sole in Forma, con una notifica per aggiungere esercizi e pesi. Camminate, corsa, bici e nuoto di almeno \(Salute.minutiCardio) minuti diventano cardio. Forma legge da Salute, non scrive niente.")
        }
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
            NavigationLink { PianoSettimanaleView() } label: {
                LabeledContent {
                    Text("questa settimana: \(palestra.settimana(Giorni.oggi()))")
                } label: {
                    Label("Piano settimanale A/B", systemImage: "calendar.badge.clock")
                }
            }
            NavigationLink { LibreriaView(modo: .sfoglia) } label: {
                LabeledContent {
                    Text("\(palestra.stato.esercizi.count)")
                } label: {
                    Label("Libreria esercizi", systemImage: "books.vertical")
                }
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
                Button("Segna pagato questo mese", systemImage: "creditcard") { palestra.segnaPagato(mese) }
            }
        } header: {
            Text("Palestra")
        } footer: {
            Text("Il promemoria del pagamento arriva il 1 (o il 2) del mese alle 9, solo se il mese non è già segnato pagato.")
        }
    }
}

struct PianoSettimanaleView: View {
    @Environment(Palestra.self) private var palestra

    var body: some View {
        List {
            Group {
                Section {
                    LabeledContent("Questa settimana", value: palestra.settimana(Giorni.oggi()))
                    Toggle("Scambia A e B", isOn: Binding(get: { palestra.stato.scambia }, set: { palestra.stato.scambia = $0 }))
                } footer: {
                    Text("Le settimane A e B si alternano da sole. Il piano dice in Oggi se è giorno di pesi, cardio o riposo.")
                }
                ForEach(["A", "B"], id: \.self) { w in
                    Section("Settimana \(w)") {
                        ForEach(0..<7, id: \.self) { i in
                            Picker(Giorni.nomi[i], selection: Binding(
                                get: { palestra.stato.piani[w]?[i] ?? .riposo },
                                set: { palestra.stato.piani[w]?[i] = $0 }
                            )) {
                                ForEach(TipoGiorno.allCases) { t in Label(t.nome, systemImage: t.simbolo).tag(t) }
                            }
                        }
                    }
                }
            }
            .righeTema()
        }
        .sfondoTema()
        .navigationTitle("Piano settimanale")
        .navigationBarTitleDisplayMode(.inline)
    }
}
