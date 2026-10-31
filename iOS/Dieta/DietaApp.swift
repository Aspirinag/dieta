import SwiftUI
import UserNotifications

@main
struct DietaApp: App {
    @State private var archivio = Archivio()
    private let delegato = DelegatoNotifiche()

    @UIApplicationDelegateAdaptor private var avvio: AvvioApp

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

// Titoli delle schermate con il font arrotondato: più morbido, senza diventare giocoso.
// Va fatto qui e non in DietaApp.init: là UIKit parte troppo presto e l'app perde il colore principale
final class AvvioApp: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions opzioni: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let barra = UINavigationBar.appearance()
        for (stile, peso) in [(UIFont.TextStyle.largeTitle, UIFont.Weight.bold), (.headline, .semibold)] {
            let base = UIFont.preferredFont(forTextStyle: stile)
            let descrittore = base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor
            let font = UIFont(descriptor: descrittore.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: peso]]), size: base.pointSize)
            if stile == .largeTitle { barra.largeTitleTextAttributes = [.font: font] } else { barra.titleTextAttributes = [.font: font] }
        }
        return true
    }
}

enum Scheda: String {
    case oggi, settimana, andamento, dati
}

struct Radice: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.scenePhase) private var fase
    @State private var scheda = Scheda(rawValue: Avvio.valore("-tab") ?? "") ?? .oggi
    @State private var avvisoScadenza = Scadenza.avvisoApertura()

    private var tema: Tema { Tema.scelto(Avvio.valore("-tema") ?? archivio.stato.tema) }

    var body: some View {
        let palette = tema.palette
        Group {
            // Senza profili le altre schermate non hanno dati su cui lavorare: si vede solo la prima apertura
            if archivio.senzaProfili {
                PrimaApertura()
            } else {
                schede
            }
        }
        .importatore()
        .environment(\.palette, palette)
        .tint(palette.accento)
        .fontDesign(.rounded)
        .scrollContentBackground(.hidden)
        .background(palette.fondo.ignoresSafeArea())
        .preferredColorScheme(tema.schemaColori)
        .task {
            await archivio.programmaPromemoria()
            await Scadenza.programma()
        }
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
        .alert("Dati non letti", isPresented: Binding(
            get: { archivio.avvisoDati != nil }, set: { if !$0 { archivio.avvisoDati = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(archivio.avvisoDati ?? "")
        }
        .alert("App in scadenza", isPresented: Binding(
            get: { avvisoScadenza != nil }, set: { if !$0 { avvisoScadenza = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(avvisoScadenza ?? "")
        }
    }

    private var schede: some View {
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
            Tab("Profilo", systemImage: "person.crop.circle", value: .dati) {
                DatiView()
            }
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
