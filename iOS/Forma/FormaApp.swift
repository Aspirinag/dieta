import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

@main
struct FormaApp: App {
    @State private var archivio = Archivio()
    @State private var palestra: Palestra
    @State private var timer = TimerRecupero()
    @State private var navigazione: Navigazione
    private let delegato = DelegatoNotifiche()

    init() {
        let p = Palestra()
        let n = Navigazione()
        _palestra = State(initialValue: p)
        _navigazione = State(initialValue: n)
        delegato.navigazione = n
        UNUserNotificationCenter.current().delegate = delegato
        // Subito all'avvio: iOS apre l'app in background quando il Watch salva un allenamento
        Salute.shared.avvia(p)
    }

    var body: some Scene {
        WindowGroup {
            Radice()
                .environment(archivio)
                .environment(palestra)
                .environment(timer)
                .environment(navigazione)
        }
    }
}

enum Scheda: String {
    case oggi, dieta, allenamento, progressi, profilo
}

// Scheda selezionata e allenamento aperto: anche i pulsanti dentro le schermate possono cambiarli
@Observable
final class Navigazione {
    var scheda = Scheda(rawValue: Avvio.valore("-tab") ?? "") ?? .oggi
    var allenamentoAperto = Avvio.valore("-tab") == "inCorso"
    var riepilogo: Allenamento?   // riepilogo mostrato appena finito un allenamento
    var compila: UUID?            // sessione del Watch a cui aggiungere esercizi e pesi
}

struct Radice: View {
    @Environment(Archivio.self) private var archivio
    @Environment(Palestra.self) private var palestra
    @Environment(Navigazione.self) private var navigazione
    @AppStorage(Tema.chiave) private var scelto = Tema.predefinito.rawValue

    private var tema: Tema { Tema(rawValue: scelto) ?? .predefinito }

    var body: some View {
        @Bindable var navigazione = navigazione
        TabView(selection: $navigazione.scheda) {
            Tab("Oggi", systemImage: "sun.max", value: .oggi) { HomeView() }
            Tab("Dieta", systemImage: "fork.knife", value: .dieta) { PastiView() }
            Tab("Allenamento", systemImage: "dumbbell", value: .allenamento) { AllenamentoView() }
            Tab("Progressi", systemImage: "chart.line.uptrend.xyaxis", value: .progressi) { ProgressiView() }
            Tab("Profilo", systemImage: "person.crop.circle", value: .profilo) { ProfiloView() }
        }
        .accessorioAllenamento()
        .fullScreenCover(isPresented: Binding(
            get: { navigazione.allenamentoAperto && palestra.stato.inCorso != nil },
            set: { navigazione.allenamentoAperto = $0 }
        )) {
            AllenamentoInCorsoView().applicaTema(tema)
        }
        .sheet(item: $navigazione.riepilogo) { a in
            RiepilogoView(allenamento: a).applicaTema(tema)
        }
        .sheet(isPresented: Binding(get: { navigazione.compila != nil }, set: { if !$0 { navigazione.compila = nil } })) {
            if let id = navigazione.compila { SceltaSchedaView(id: id).applicaTema(tema) }
        }
        .applicaTema(tema)
        .task {
            guard !palestra.demo else { return }
            if await Notifiche.permesso() { await palestra.programmaPagamento() }
            await archivio.programmaPromemoria()
            if Salute.attivo, await Salute.shared.chiediPermesso() {
                Salute.shared.avvia(palestra)
                await Salute.shared.importa()
            }
        }
    }
}

extension View {
    // Su iOS 26 timer di recupero e allenamento in corso stanno sopra la tab bar, in vetro
    @ViewBuilder
    func accessorioAllenamento() -> some View {
        if #available(iOS 26.0, *) {
            tabViewBottomAccessory { BarraAllenamento() }
        } else {
            safeAreaInset(edge: .bottom) {
                BarraAllenamento()
                    .padding(.vertical, 10)
                    .background(.bar, in: .capsule)
                    .padding(.horizontal)
                    .padding(.bottom, 56)
            }
        }
    }
}

// Scelta del profilo della dieta nella barra in alto (solo se ce n'è più di uno)
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

// Avviso di pagamento della palestra dal 25 al 2 del mese, finché non è segnato pagato
struct SezionePagamento: View {
    @Environment(Palestra.self) private var palestra

    var body: some View {
        if let p = palestra.promemoriaPagamento() {
            Section {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pagamento palestra").font(.headline)
                        Text(p.testo).font(.subheadline).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "creditcard.fill").foregroundStyle(.tint)
                }
                Button("Segna pagato", systemImage: "checkmark.circle") { palestra.segnaPagato(p.mese) }
            }
        }
    }
}

// Backup condivisibile come file .json
struct FileBackup: Transferable {
    let dati: Data
    let nome: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { $0.dati }
            .suggestedFileName { $0.nome }
    }
}

// Durata leggibile: 1 h 05 min · 42 min
func durataTesto(_ secondi: TimeInterval) -> String {
    let m = Int(secondi / 60)
    return m >= 60 ? "\(m / 60) h \(String(format: "%02d", m % 60)) min" : "\(m) min"
}

// Volume leggibile: 12.450 kg
func volumeTesto(_ kg: Double) -> String {
    "\(Int(kg.rounded()).formatted(.number.locale(Locale(identifier: "it_IT")))) kg"
}
