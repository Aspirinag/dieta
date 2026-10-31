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

// Va fatto qui e non in DietaApp.init: là UIKit parte troppo presto e l'app perde il colore principale
final class AvvioApp: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions opzioni: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        AspettoUIKit.applica()
        return true
    }
}

enum Scheda: String, CaseIterable {
    case oggi, dieta, allenamento, progressi, profilo

    var titolo: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }

    var icona: String {
        switch self {
        case .oggi: "house"
        case .dieta: "fork.knife"
        case .allenamento: "dumbbell"
        case .progressi: "chart.line.uptrend.xyaxis"
        case .profilo: "person"
        }
    }
}

// Barra delle schede del tema. Quella di sistema da iOS 26 è di vetro e ignora sfondo e colori:
// il tema non la raggiungerebbe, né cambierebbe colore scegliendone un altro in Profilo
struct BarraSchede: View {
    static let altezza: CGFloat = 64
    static let staccoDalFondo: CGFloat = 18

    @Binding var scheda: Scheda
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Scheda.allCases, id: \.self) { s in
                let scelta = s == scheda
                Button {
                    scheda = s
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: s.icona)
                            .font(.system(size: 20))
                            .frame(height: 24)
                        Text(s.titolo)
                            .font(.georgiaFissa(10, grassetto: true))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(scelta ? palette.accento : palette.secondario)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(s.titolo)
                .accessibilityAddTraits(scelta ? .isSelected : [])
                .accessibilityShowsLargeContentViewer { Label(s.titolo, systemImage: s.icona) }
            }
        }
        .frame(height: Self.altezza)
        .background(palette.barra, in: .capsule)
        .overlay { Capsule().strokeBorder(palette.traccia) }   // staccata dalle schede che le scorrono sotto
        .padding(.horizontal, 12)
        .padding(.bottom, Self.staccoDalFondo)
        .sensoryFeedback(.selection, trigger: scheda)
    }
}

struct Radice: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.scenePhase) private var fase
    @State private var scheda = Scheda(rawValue: Avvio.valore("-tab") ?? "") ?? .oggi
    @State private var giornoDieta = Giorni.oggi()   // sta qui perché Oggi apre Dieta sul giorno che sta guardando
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
        .font(.georgia())
        .foregroundStyle(palette.testo)
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
            Tab(Scheda.oggi.titolo, systemImage: Scheda.oggi.icona, value: .oggi) {
                OggiView { giorno in
                    giornoDieta = giorno
                    scheda = .dieta
                }
                .sottoLaBarra()
            }
            Tab(Scheda.dieta.titolo, systemImage: Scheda.dieta.icona, value: .dieta) {
                DietaView(giorno: $giornoDieta).sottoLaBarra()
            }
            Tab(Scheda.allenamento.titolo, systemImage: Scheda.allenamento.icona, value: .allenamento) {
                AllenamentoView().sottoLaBarra()
            }
            Tab(Scheda.progressi.titolo, systemImage: Scheda.progressi.icona, value: .progressi) {
                ProgressiView().sottoLaBarra()
            }
            Tab(Scheda.profilo.titolo, systemImage: Scheda.profilo.icona, value: .profilo) {
                ProfiloView().sottoLaBarra()
            }
        }
        .overlay(alignment: .bottom) {
            BarraSchede(scheda: $scheda).ignoresSafeArea(edges: .bottom)
        }
    }
}

private extension View {
    // Nasconde la barra di sistema e lascia in fondo il posto per quella del tema, che le sta sopra
    func sottoLaBarra() -> some View {
        toolbar(.hidden, for: .tabBar)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: BarraSchede.altezza + BarraSchede.staccoDalFondo)
            }
    }
}

// Scelta del profilo in alto: un cerchio con l'iniziale (solo se c'è più di un profilo)
struct MenuProfilo: View {
    var conSfondo = true   // nella barra in alto il cerchio c'è già: da iOS 26 le voci hanno un fondo di vetro
    @Environment(Archivio.self) private var archivio
    @Environment(\.palette) private var palette

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
                Text(String(archivio.profilo.nome.prefix(1)).uppercased())
                    .font(.georgiaFissa(17, grassetto: true))
                    .foregroundStyle(palette.testo)
                    .frame(width: 44, height: 44)
                    .background(conSfondo ? palette.riempimento : .clear, in: .circle)
                    .accessibilityLabel("Cambia profilo, ora \(archivio.profilo.nome)")
            }
        }
    }
}
