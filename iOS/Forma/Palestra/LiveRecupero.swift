import ActivityKit
import Foundation

// Live Activity del recupero (schermata bloccata e Dynamic Island) durante l'allenamento in corso.
// Riceve lo stato del recupero da mostrare (nil se non c'è recupero o non c'è un allenamento in corso)
// e decide se avviare, aggiornare o chiudere. L'aspetto sta nell'estensione RecuperoWidget.

// Quello che serve di ActivityKit: nei test si sostituisce con un finto
protocol SistemaAttivita {
    func avvia(_ stato: StatoRecupero)
    func aggiorna(_ stato: StatoRecupero)
    func chiudi()
}

@Observable
final class LiveRecupero {
    private let sistema: SistemaAttivita
    private(set) var mostrato: StatoRecupero?

    init(sistema: SistemaAttivita = AttivitaDiSistema()) {
        self.sistema = sistema
    }

    // Chiamata a ogni cambio: avvio di un recupero, ±15 s, fine del recupero o dell'allenamento
    func applica(_ stato: StatoRecupero?, adesso: Date = Date()) {
        // Un recupero già scaduto non si mostra più
        let voluto = stato.flatMap { $0.fine > adesso ? $0 : nil }
        guard voluto != mostrato else { return }
        switch (mostrato, voluto) {
        case (nil, let nuovo?): sistema.avvia(nuovo)
        case (_?, let nuovo?): sistema.aggiorna(nuovo)
        case (_?, nil): sistema.chiudi()
        case (nil, nil): break
        }
        mostrato = voluto
    }
}

// La Live Activity vera, con ActivityKit (niente notifiche push: la aggiorna solo l'app)
final class AttivitaDiSistema: SistemaAttivita {
    private var attivita: Activity<AttivitaRecupero>?
    private var coda: Task<Void, Never>?   // gli aggiornamenti vanno in ordine, uno dopo l'altro

    // All'avvio dell'app il recupero di prima non c'è più (il timer non si salva): si chiudono le attività rimaste aperte
    static func chiudiRimaste() {
        let rimaste = Activity<AttivitaRecupero>.activities
        guard !rimaste.isEmpty else { return }
        Task { for a in rimaste { await a.end(nil, dismissalPolicy: .immediate) } }
    }

    func avvia(_ stato: StatoRecupero) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        do {
            attivita = try Activity.request(attributes: AttivitaRecupero(), content: contenuto(stato), pushType: nil)
        } catch {
            attivita = nil
        }
    }

    func aggiorna(_ stato: StatoRecupero) {
        guard let a = attivita else { return avvia(stato) }
        let c = contenuto(stato)
        accoda { await a.update(c) }
    }

    func chiudi() {
        guard let a = attivita else { return }
        attivita = nil
        accoda { await a.end(nil, dismissalPolicy: .immediate) }
    }

    // A fine recupero (anche con l'app sospesa) la Live Activity diventa «Recupero finito»
    private func contenuto(_ stato: StatoRecupero) -> ActivityContent<StatoRecupero> {
        ActivityContent(state: stato, staleDate: stato.fine)
    }

    private func accoda(_ lavoro: @escaping () async -> Void) {
        let precedente = coda
        coda = Task {
            await precedente?.value
            await lavoro()
        }
    }
}
