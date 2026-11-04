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
    case oggi, dieta, allenamento, progressi
}

// Scheda selezionata e allenamento aperto: anche i pulsanti dentro le schermate possono cambiarli
@Observable
final class Navigazione {
    var scheda = Scheda(rawValue: Avvio.valore("-tab") ?? "") ?? .oggi
    // Le Impostazioni sono un foglio; `-tab profilo` resta come sinonimo di `-tab impostazioni`
    var impostazioniAperte = ["impostazioni", "profilo"].contains(Avvio.valore("-tab") ?? "")
    var allenamentoAperto = Avvio.valore("-tab") == "inCorso"
    var riepilogo: Allenamento?   // riepilogo mostrato appena finito un allenamento
    var compila: UUID?            // sessione del Watch a cui aggiungere esercizi e pesi
}

struct Radice: View {
    @Environment(Archivio.self) private var archivio
    @Environment(Palestra.self) private var palestra
    @Environment(TimerRecupero.self) private var timer
    @Environment(Navigazione.self) private var navigazione
    @State private var avvisoDati = true
    @Environment(\.scenePhase) private var fase
    @AppStorage("benvenutoVisto") private var benvenutoVisto = false

    var body: some View {
        @Bindable var navigazione = navigazione
        TabView(selection: $navigazione.scheda) {
            Tab("Oggi", systemImage: "sun.max", value: .oggi) { HomeView() }
            Tab("Dieta", systemImage: "fork.knife", value: .dieta) { DietaView() }
            Tab("Palestra", systemImage: "dumbbell", value: .allenamento) { AllenamentoView() }
            Tab("Progressi", systemImage: "chart.xyaxis.line", value: .progressi) {
                NavigationStack {
                    AndamentoPagina(conArchivioPalestra: true)
                        .destinazioniDieta()
                        .destinazioniArchivioPalestra()
                        .navigationDestination(for: PaginaPalestraDest.self) { pagina in
                            switch pagina {
                            case .calendario: PaginaPalestra(titolo: "Calendario") { CalendarioContenuto() }
                            case .storico: PaginaPalestra(titolo: "Storico") { StoricoAllenamenti() }
                            case .libreria, .modelli, .pianoSettimanale: EmptyView()
                            }
                        }
                }
            }
        }
        .sheet(isPresented: $navigazione.impostazioniAperte) {
            ImpostazioniView().applicaTema()
        }
        // La barra compare solo con un allenamento in corso o un recupero che scorre
        .accessorioAllenamento(visibile: palestra.stato.inCorso != nil || timer.attivo)
        .fullScreenCover(isPresented: Binding(
            get: { navigazione.allenamentoAperto && palestra.stato.inCorso != nil },
            set: { navigazione.allenamentoAperto = $0 }
        )) {
            AllenamentoInCorsoView().applicaTema()
        }
        .sheet(item: $navigazione.riepilogo) { a in
            RiepilogoView(allenamento: a).applicaTema()
        }
        .sheet(isPresented: Binding(get: { navigazione.compila != nil }, set: { if !$0 { navigazione.compila = nil } })) {
            if let id = navigazione.compila { SceltaSchedaView(id: id).applicaTema() }
        }
        .applicaTema()
        .onChange(of: fase) { _, f in
            if f != .active {
                archivio.salvaOra()
                palestra.salvaOra()
            }
        }
        .alert("Dati non letti", isPresented: Binding(
            get: { avvisoDati && copieIlleggibili != nil }, set: { if !$0 { avvisoDati = false } }
        )) {
            Button("OK") {}
        } message: {
            Text("I dati salvati sono danneggiati: Forma è ripartita da zero, ma ha tenuto una copia. La trovi in Impostazioni → Backup → Copie dei dati non letti.")
        }
        .alert("Dati non disponibili", isPresented: Binding(
            get: { avvisoDati && (archivio.salvataggioBloccato || palestra.salvataggioBloccato) },
            set: { if !$0 { avvisoDati = false } }
        )) {
            Button("OK") {}
        } message: {
            Text("I dati non si aprono, di solito perché l'iPhone è bloccato. Sblocca, chiudi e riapri Forma. Fino ad allora Forma non salva niente, così non perdi dati.")
        }
        .fullScreenCover(isPresented: Binding(
            get: { benvenuto }, set: { if !$0 { benvenutoVisto = true } }
        )) {
            BenvenutoView { benvenutoVisto = true }.applicaTema()
        }
        .task(id: benvenutoVisto) {
            // Alla prima apertura i permessi si chiedono nel benvenuto, con la spiegazione
            guard !palestra.demo, !benvenuto else { return }
            if await Notifiche.consentite() {
                await palestra.programmaPagamento()
                await archivio.programmaPromemoria()
            }
            if Salute.attivo, await Salute.shared.chiediPermesso() {
                Salute.shared.avvia(palestra)
                await Salute.shared.importa()
            }
        }
    }
}

extension Radice {
    // Nomi delle copie dei file dati illeggibili trovate all'avvio
    var copieIlleggibili: String? {
        let nomi = [archivio.fileIlleggibile, palestra.fileIlleggibile].compactMap { $0?.lastPathComponent }
        return nomi.isEmpty ? nil : nomi.joined(separator: ", ")
    }
}

extension View {
    // Su iOS 26 timer di recupero e allenamento in corso stanno sopra la tab bar, in vetro
    @ViewBuilder
    func accessorioAllenamento(visibile: Bool) -> some View {
        if #available(iOS 26.1, *) {
            tabViewBottomAccessory(isEnabled: visibile) { BarraAllenamento() }
        } else if #available(iOS 26.0, *) {
            tabViewBottomAccessory { BarraAllenamento() }
        } else {
            safeAreaInset(edge: .bottom) {
                if visibile { barraClassica }
            }
        }
    }

    private var barraClassica: some View {
        BarraAllenamento()
            .padding(.vertical, 10)
            .background(.bar, in: .capsule)
            .padding(.horizontal)
            .padding(.bottom, 56)
    }
}

// Scelta del profilo della dieta nella barra in alto (solo se ce n'è più di uno)
struct MenuProfilo: View {
    @Environment(Archivio.self) private var archivio

    var body: some View {
        if archivio.stato.profili.count >= 2 {
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

extension Radice {
    var benvenuto: Bool {
        BenvenutoView.daMostrare(dietaNuova: archivio.primaApertura, datiPalestra: palestra.datiPresenti, visto: benvenutoVisto)
    }
}
