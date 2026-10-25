import SwiftUI
import UserNotifications

@main
struct DietaApp: App {
    @State private var archivio = Archivio()
    private let delegato = DelegatoNotifiche()

    init() {
        UNUserNotificationCenter.current().delegate = delegato
    }

    var body: some Scene {
        WindowGroup {
            Radice()
                .environment(archivio)
        }
    }
}

enum Scheda: String {
    case oggi, settimana, andamento, dati
}

struct Radice: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.scenePhase) private var fase
    @State private var scheda = Scheda(rawValue: Avvio.valore("-tab") ?? "") ?? .oggi

    var body: some View {
        TabView(selection: $scheda) {
            Tab("Oggi", systemImage: "fork.knife", value: .oggi) {
                OggiView()
            }
            Tab("Settimana", systemImage: "calendar", value: .settimana) {
                SettimanaView()
            }
            Tab("Andamento", systemImage: "chart.line.uptrend.xyaxis", value: .andamento) {
                AndamentoView()
            }
            Tab("Dati", systemImage: "gearshape", value: .dati) {
                DatiView()
            }
        }
        .task { await archivio.programmaPromemoria() }
        .onChange(of: fase) { _, nuova in
            if nuova != .active { archivio.salvaSubito() }
        }
        .alert("Dati non salvati", isPresented: Binding(
            get: { archivio.erroreSalvataggio != nil }, set: { if !$0 { archivio.erroreSalvataggio = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(archivio.erroreSalvataggio ?? "")
        }
    }
}

// Scelta del profilo nella barra in alto (solo se ce n'è più di uno)
struct MenuProfilo: View {
    @Environment(Archivio.self) private var archivio

    var body: some View {
        if archivio.stato.profili.count > 1 {
            Menu {
                Picker("Profilo", selection: Binding(
                    get: { archivio.stato.attivo },
                    set: { archivio.stato.attivo = $0 }
                )) {
                    ForEach(archivio.idProfili, id: \.self) { id in
                        Text(archivio.stato.profili[id]?.nome ?? "").tag(id)
                    }
                }
            } label: {
                Label(archivio.profilo.nome, systemImage: "person.crop.circle")
                    .labelStyle(.titleAndIcon)
            }
        }
    }
}
