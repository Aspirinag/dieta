import SwiftUI

// Timer di recupero tra le serie: parte da solo quando segni una serie; a fine recupero vibra
// e, con l'app chiusa o il telefono bloccato, arriva una notifica
@Observable
final class TimerRecupero {
    private(set) var fine: Date?
    private(set) var durata = 90
    private var compito: Task<Void, Never>?
    var finiti = 0     // cambia a ogni recupero concluso (per la vibrazione)

    var attivo: Bool { fine.map { $0 > Date() } ?? false }

    func avvia(_ secondi: Int) {
        durata = secondi
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
        Notifiche.cancella(["recupero"])
        Task { await Notifiche.traSecondi(id: "recupero", titolo: "Recupero finito", testo: "Puoi iniziare la prossima serie.", secondi: secondi) }
        compito = Task {
            try? await Task.sleep(for: .seconds(max(secondi, 0)))
            guard !Task.isCancelled else { return }
            // Se l'app era in background la notifica è già arrivata: niente vibrazione in ritardo
            if Date().timeIntervalSince(f) < 2 { finiti += 1 }
            fine = nil
        }
    }

    func ferma() {
        compito?.cancel()
        compito = nil
        fine = nil
        Notifiche.cancella(["recupero"])
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
                Image(systemName: "timer").foregroundStyle(.tint).symbolEffect(.pulse)
                Text(timerInterval: Date()...fine, countsDown: true)
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.tint)
                Spacer()
                Button("−15") { timer.cambia(-15) }
                Button("+15") { timer.cambia(15) }
                Button("Salta", systemImage: "forward.end.fill") { timer.ferma() }
                    .labelStyle(.iconOnly)
            } else if let a = palestra.stato.inCorso {
                Image(systemName: "dumbbell.fill").foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 0) {
                    Text(a.nome).font(.subheadline.weight(.semibold)).lineLimit(1)
                    Text(timerInterval: a.inizio...Date.distantFuture, countsDown: false)
                        .font(.caption)
                        .monospacedDigit()
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
