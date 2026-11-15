import SwiftUI

// `StatoRecupero` (inizio, fine, esercizio) sta in Condiviso/AttivitaRecupero.swift: lo legge anche la Live Activity dell'allenamento

// Timer di recupero tra le serie: parte da solo quando segni una serie; a fine recupero vibra
// e, con l'app chiusa o il telefono bloccato, arriva una notifica.
// `stato` (inizio, fine, esercizio) è il dato da esporre a una Live Activity: cambia a ogni avvio, ±15 s e fine
@Observable
final class TimerRecupero {
    private(set) var fine: Date?
    private(set) var inizio: Date?
    private(set) var esercizio: String?
    private(set) var durata = 90
    private var compito: Task<Void, Never>?
    private var compitoNotifica: Task<Void, Never>?   // l'aggiunta della notifica (è asincrona)
    private let aggiungiNotifica: (Int) async -> Void
    private let cancellaNotifica: () -> Void

    init(aggiungiNotifica: @escaping (Int) async -> Void = { secondi in
             await Notifiche.traSecondi(id: "recupero", titolo: String(localized: "Recupero finito"), testo: String(localized: "Puoi iniziare la prossima serie."), secondi: secondi,
                                        categoria: Notifiche.categoriaRecupero)
         },
         cancellaNotifica: @escaping () -> Void = { Notifiche.cancella(["recupero"]) }) {
        self.aggiungiNotifica = aggiungiNotifica
        self.cancellaNotifica = cancellaNotifica
    }
    var finiti = 0     // cambia a ogni recupero concluso (per la vibrazione)

    var attivo: Bool { fine.map { $0 > Date() } ?? false }

    var stato: StatoRecupero? {
        guard let fine, let inizio else { return nil }
        return StatoRecupero(inizio: inizio, fine: fine, esercizio: esercizio)
    }

    private var avviatoDa: UUID?   // la serie la cui spunta ha fatto partire il recupero

    func avvia(_ secondi: Int, serie: UUID? = nil, esercizio: String? = nil) {
        avviatoDa = serie
        durata = secondi
        inizio = Date()
        self.esercizio = esercizio
        programma(Date().addingTimeInterval(TimeInterval(secondi)))
    }

    // Aggiunge o toglie secondi al recupero in corso
    func cambia(_ secondi: Int) {
        guard let f = fine else { return }
        let nuova = f.addingTimeInterval(TimeInterval(secondi))
        if nuova <= Date() { ferma() } else { programma(nuova) }
    }

    private func programma(_ f: Date) {
        compito?.cancel()
        fine = f
        let secondi = Int(f.timeIntervalSinceNow.rounded())
        cancellaNotifica()
        // Le aggiunte vanno una dopo l'altra; se nel frattempo il recupero è stato fermato, la notifica appena aggiunta si toglie
        let precedente = compitoNotifica
        precedente?.cancel()
        compitoNotifica = Task {
            await precedente?.value
            guard !Task.isCancelled else { return }
            await aggiungiNotifica(secondi)
            if fine == nil { cancellaNotifica() }
        }
        compito = Task {
            try? await Task.sleep(for: .seconds(max(secondi, 0)))
            guard !Task.isCancelled else { return }
            // Se l'app era in background la notifica è già arrivata: niente vibrazione in ritardo
            if Date().timeIntervalSince(f) < 2 { finiti += 1 }
            fine = nil
            inizio = nil
            esercizio = nil
        }
    }

    // «Ancora 30 s» dalla notifica di fine recupero: riparte un recupero di 30 s
    func ancora30() {
        avvia(30)
    }

    // Aspetta che la notifica di fine recupero sia stata aggiunta (per l'intent: iOS può sospendere l'app appena ritorna)
    func attendiNotifica() async {
        await compitoNotifica?.value
    }

    // Se la serie tolta è quella che ha fatto partire il recupero, lo ferma (e toglie la notifica)
    func fermaSeAvviatoDa(_ serie: UUID) {
        if avviatoDa == serie { ferma() }
    }

    func ferma() {
        avviatoDa = nil
        compito?.cancel()
        compito = nil
        // L'aggiunta in corso si annulla ma si tiene: chi aspetta (`attendiNotifica`) la vede finita e già tolta
        compitoNotifica?.cancel()
        fine = nil
        inizio = nil
        esercizio = nil
        cancellaNotifica()
    }
}

// Sopra la tab bar (su iOS 26 è l'accessorio Liquid Glass): timer di recupero, oppure l'allenamento in corso
struct BarraAllenamento: View {
    @Environment(TimerRecupero.self) private var timer
    @Environment(Palestra.self) private var palestra
    @Environment(Navigazione.self) private var navigazione

    var body: some View {
        HStack(spacing: 10) {
            if let fine = timer.fine, timer.attivo {
                // Conto alla rovescia che si aggiorna ogni secondo (anche per VoiceOver); con un allenamento in corso lo si tocca per riaprirlo
                TimelineView(.periodic(from: .now, by: 1)) { ctx in
                    let resto = testoRecupero(fine.timeIntervalSince(ctx.date))
                    let conto = HStack(spacing: 10) {
                        Image(systemName: "timer").foregroundStyle(.secondary).symbolEffect(.pulse)
                        Text(verbatim: resto)
                            .numero(.title3)
                            .foregroundStyle(.primary)
                        Spacer(minLength: 0)
                    }
                    if palestra.stato.inCorso != nil {
                        Button { navigazione.allenamentoAperto = true } label: { conto.contentShape(.rect) }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("Riapri allenamento")
                            .accessibilityLabel("Recupero")
                            .accessibilityValue(resto)
                    } else {
                        conto
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Recupero")
                            .accessibilityValue(resto)
                    }
                }
                Button("−15") { timer.cambia(-15) }
                Button("+15") { timer.cambia(15) }
                Button("Salta", systemImage: "forward.end.fill") { timer.ferma() }
                    .labelStyle(.iconOnly)
            } else if let a = palestra.stato.inCorso {
                Image(systemName: "dumbbell.fill").foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: a.titolo).font(.subheadline.weight(.semibold)).lineLimit(1)
                    Text(timerInterval: a.inizio...Date.distantFuture, countsDown: false)
                        .font(.numero(.caption))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Riprendi") { navigazione.allenamentoAperto = true }
                    .font(.subheadline.weight(.semibold))
            } else {
                Label("Recupero", systemImage: "timer").foregroundStyle(.secondary)
                Spacer()
                ForEach([60, 90, 120], id: \.self) { s in
                    Button("\(s) s") { timer.avvia(s) }
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .padding(.horizontal, 16)
        .sensoryFeedback(.success, trigger: timer.finiti)
    }
}

// Conto alla rovescia m:ss (per eccesso, mai sotto zero)
func testoRecupero(_ secondi: TimeInterval) -> String {
    let s = max(0, Int(secondi.rounded(.up)))
    return "\(s / 60):\(String(format: "%02d", s % 60))"
}
