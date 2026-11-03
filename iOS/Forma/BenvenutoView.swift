import SwiftUI

// Prima apertura: nome del profilo e scelta di promemoria e Apple Watch, con la spiegazione
// prima che iOS chieda il permesso
struct BenvenutoView: View {
    @Environment(Archivio.self) private var archivio
    @Environment(Palestra.self) private var palestra
    let fine: () -> Void
    @State private var nome = ""
    @State private var promemoria = true
    @State private var watch = Salute.disponibile
    @State private var attesa = false

    // Solo a chi parte davvero da zero: dieta nuova e nessun file della palestra
    static func daMostrare(dietaNuova: Bool, datiPalestra: Bool, visto: Bool) -> Bool {
        dietaNuova && !datiPalestra && !visto
    }

    var body: some View {
        NavigationStack {
            Form {
                Group {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ti presento Forma").font(.largeTitle.bold())
                            Text("Dieta e palestra in un posto solo. I dati restano sul tuo iPhone.")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(Color.clear)
                    }
                    Section {
                        TextField("Il tuo nome", text: $nome)
                            .textContentType(.givenName)
                    } header: {
                        Text("Come ti chiami?")
                    } footer: {
                        Text("Serve per il profilo della dieta. Puoi aggiungere altri profili in Impostazioni.")
                    }
                    Section {
                        Toggle(isOn: $promemoria) {
                            Label("Promemoria", systemImage: "bell")
                        }
                    } footer: {
                        Text("Ogni mattina ti ricorda la dieta del giorno. In Impostazioni puoi aggiungere pasti, acqua e pagamento della palestra, e scegliere gli orari.")
                    }
                    if Salute.disponibile {
                        Section {
                            Toggle(isOn: $watch) {
                                Label("Allenamenti dall'Apple Watch", systemImage: "applewatch")
                            }
                        } footer: {
                            Text("Forma legge da Salute gli allenamenti registrati sul Watch (palestra, camminate, corsa, bici, nuoto). Non scrive niente.")
                        }
                    }
                }
                .righeTema()
            }
            .sfondoTema()
            .safeAreaInset(edge: .bottom) {
                Button {
                    Task { await inizia() }
                } label: {
                    Text("Inizia").frame(maxWidth: .infinity)
                }
                .pulsanteVetro(evidente: true)
                .controlSize(.large)
                .disabled(attesa)
                .padding()
            }
        }
        .interactiveDismissDisabled()
    }

    private func inizia() async {
        attesa = true
        let n = nome.trimmingCharacters(in: .whitespaces)
        if !n.isEmpty { archivio.profilo.nome = n }
        var p = archivio.stato.promemoria ?? Promemoria()
        let consentite = promemoria ? await Notifiche.permesso() : false
        p.mattino = consentite
        archivio.stato.promemoria = p
        palestra.stato.pagamentoAttivo = consentite
        if p.mattino {
            await archivio.programmaPromemoria()
            await palestra.programmaPagamento()
        }
        UserDefaults.standard.set(watch, forKey: Salute.chiave)
        if watch, await Salute.shared.chiediPermesso() {
            Salute.shared.avvia(palestra)
            await Salute.shared.importa()
        }
        fine()
    }
}
