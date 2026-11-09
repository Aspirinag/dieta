import ActivityKit
import Foundation

// Live Activity dell'allenamento in corso (schermata bloccata e Dynamic Island): serie da fare, prossimo esercizio,
// recupero e pulsante «Fatta». Qui: come si costruisce lo stato da mostrare, chi avvia/aggiorna/chiude l'attività
// e come la tiene allineata ai dati anche con l'app in background. L'aspetto sta nell'estensione RecuperoWidget.

extension StatoAllenamentoLive {
    // Lo stato da mostrare per l'allenamento in corso (nil se non c'è).
    // - `ultimaSerie`: l'ultima serie spuntata (dall'app o dalla Live Activity), da cui si cerca la serie attiva
    // - `libreria`: per il titolo localizzato dell'esercizio e per sapere se è a corpo libero
    // - `precedente`: la serie corrispondente dell'ultima volta, come nella spunta dell'app (esercizio, posizione tra quelle di lavoro)
    static func da(allenamento: Allenamento?, ultimaSerie: UUID?, recupero: StatoRecupero?, libreria: [Esercizio],
                   precedente: (String, Int) -> SerieFatta? = { _, _ in nil }) -> StatoAllenamentoLive? {
        guard let a = allenamento else { return nil }
        var stato = StatoAllenamentoLive(titolo: a.titolo, inizio: a.inizio, recupero: recupero)
        guard let id = SerieAttiva.trova(in: a.esercizi, riferimento: ultimaSerie),
              let i = a.esercizi.firstIndex(where: { $0.serie.contains { $0.id == id } }),
              let j = a.esercizi[i].serie.firstIndex(where: { $0.id == id }) else { return stato }
        let e = a.esercizi[i]
        let s = e.serie[j]
        let ex = libreria.first { $0.id == e.esercizio } ?? Esercizio(id: e.esercizio, nome: e.esercizio, muscolo: .altro, attrezzo: .altro)
        let corpoLibero = ex.attrezzo == .corpoLibero
        // Come nell'app, la posizione per la serie dell'ultima volta non conta il riscaldamento
        let prec = precedente(e.esercizio, e.serie[..<j].filter { !$0.riscaldamento }.count)

        stato.esercizio = ex.titolo
        stato.serie = j + 1
        stato.totaleSerie = e.serie.count
        stato.riscaldamento = s.riscaldamento
        stato.corpoLibero = corpoLibero
        stato.idSerie = s.id
        switch EsitoSpunta.valuta(kg: s.kg, rip: s.rip, precedente: prec, corpoLibero: corpoLibero) {
        case .segna(let k, let r):
            stato.kg = k
            stato.rip = r
        case .manca:
            // Manca qualcosa: si mostra quello che c'è e il pulsante «Fatta» non compare
            stato.kg = s.kg ?? prec?.kg ?? (corpoLibero ? 0 : nil)
            stato.rip = s.rip ?? prec?.rip
        }
        if let p = PercorsoAllenamento.prossimoAperto(dopo: e.id, in: a.esercizi),
           let pe = a.esercizi.first(where: { $0.id == p }) {
            stato.prossimo = (libreria.first { $0.id == pe.esercizio } ?? Esercizio(id: pe.esercizio, nome: pe.esercizio, muscolo: .altro, attrezzo: .altro)).titolo
        }
        return stato
    }
}

// Quello che serve di ActivityKit: nei test si sostituisce con un finto
protocol SistemaAttivita {
    func avvia(_ stato: StatoAllenamentoLive)
    func aggiorna(_ stato: StatoAllenamentoLive)
    func chiudi()
}

// Decide se avviare, aggiornare o chiudere l'attività. Riceve lo stato voluto (nil = nessun allenamento in corso)
@Observable
final class LiveAllenamento {
    private let sistema: SistemaAttivita
    private(set) var mostrato: StatoAllenamentoLive?

    init(sistema: SistemaAttivita = AttivitaDiSistema()) {
        self.sistema = sistema
    }

    // Chiamata a ogni cambio: nuova serie, recupero, ±15 s, fine dell'allenamento
    func applica(_ stato: StatoAllenamentoLive?, adesso: Date = Date()) {
        var voluto = stato
        // Un recupero già scaduto non si mostra più (ma l'attività resta: c'è ancora la serie da fare)
        if let fine = voluto?.recupero?.fine, fine <= adesso { voluto?.recupero = nil }
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

// Tiene la Live Activity allineata ai dati anche con l'app in background (le viste lì non si aggiornano):
// osserva l'allenamento in corso, l'ultima serie e il recupero, e a ogni cambio ricalcola lo stato
final class CollegamentoLive {
    private let palestra: Palestra
    private let timer: TimerRecupero
    private let live: LiveAllenamento

    init(palestra: Palestra, timer: TimerRecupero, live: LiveAllenamento) {
        self.palestra = palestra
        self.timer = timer
        self.live = live
    }

    // Applica lo stato di adesso e si riarma: `withObservationTracking` avvisa una volta sola, alla prima modifica
    func osserva() {
        let stato = withObservationTracking {
            costruisci()
        } onChange: { [weak self] in
            // Avvisa prima della modifica: si rilegge un momento dopo, a valori già cambiati
            Task { @MainActor in self?.osserva() }
        }
        live.applica(stato)
    }

    // Per l'azione dell'intent: rilegge subito, senza aspettare l'osservazione
    func aggiorna() {
        live.applica(costruisci())
    }

    private func costruisci() -> StatoAllenamentoLive? {
        StatoAllenamentoLive.da(allenamento: palestra.stato.inCorso, ultimaSerie: palestra.ultimaSerie,
                                recupero: timer.stato, libreria: palestra.stato.esercizi,
                                precedente: { palestra.precedente($0, $1) })
    }
}

// Per i test e la modalità demo: non crea attività vere
struct SistemaAttivitaNullo: SistemaAttivita {
    func avvia(_ stato: StatoAllenamentoLive) {}
    func aggiorna(_ stato: StatoAllenamentoLive) {}
    func chiudi() {}
}

// La Live Activity vera, con ActivityKit (niente notifiche push: la aggiorna solo l'app)
final class AttivitaDiSistema: SistemaAttivita {
    private var attivita: Activity<AttivitaAllenamento>?
    private var coda: Task<Void, Never>?   // gli aggiornamenti vanno in ordine, uno dopo l'altro

    // All'avvio dell'app le attività rimaste aperte si chiudono: se c'è un allenamento in corso se ne avvia una nuova
    static func chiudiRimaste() {
        let rimaste = Activity<AttivitaAllenamento>.activities
        guard !rimaste.isEmpty else { return }
        Task { for a in rimaste { await a.end(nil, dismissalPolicy: .immediate) } }
    }

    func avvia(_ stato: StatoAllenamentoLive) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        do {
            attivita = try Activity.request(attributes: AttivitaAllenamento(), content: contenuto(stato), pushType: nil)
        } catch {
            attivita = nil
        }
    }

    func aggiorna(_ stato: StatoAllenamentoLive) {
        guard let a = attivita else { return avvia(stato) }
        let c = contenuto(stato)
        accoda { await a.update(c) }
    }

    func chiudi() {
        guard let a = attivita else { return }
        attivita = nil
        accoda { await a.end(nil, dismissalPolicy: .immediate) }
    }

    // A fine recupero (anche con l'app sospesa) l'attività diventa «vecchia» e perde il conto alla rovescia
    private func contenuto(_ stato: StatoAllenamentoLive) -> ActivityContent<StatoAllenamentoLive> {
        ActivityContent(state: stato, staleDate: stato.recupero?.fine)
    }

    private func accoda(_ lavoro: @escaping () async -> Void) {
        let precedente = coda
        coda = Task {
            await precedente?.value
            await lavoro()
        }
    }
}
