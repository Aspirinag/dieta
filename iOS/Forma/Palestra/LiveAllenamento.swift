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
        // Prima il riscaldamento: il primo movimento da fare, finché non si è spuntata nessuna serie
        let movimenti = Libreria.riscaldamento
        if !a.esercizi.contains(where: { $0.serie.contains(where: \.fatta) }),
           let m = movimenti.indices.first(where: { a.riscaldamento[String($0)] != true }) {
            stato.movimento = m
            stato.esercizio = movimenti[m].0
            stato.spiegazione = movimenti[m].1
            stato.riscaldamento = true
            stato.serie = m + 1
            stato.totaleSerie = movimenti.count
            if let primo = a.esercizi.first(where: { !PercorsoAllenamento.completo($0) }) {
                stato.prossimo = (libreria.first { $0.id == primo.esercizio } ?? Esercizio(id: primo.esercizio, nome: primo.esercizio, muscolo: .altro, attrezzo: .altro)).titolo
            }
            return stato
        }
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
    var haAttivita: Bool { get }                        // c'è un'attività (anche ripresa all'avvio) da tenere o chiudere
    @discardableResult func avvia(_ stato: StatoAllenamentoLive) -> Bool       // false = non è riuscita
    @discardableResult func aggiorna(_ stato: StatoAllenamentoLive) -> Bool    // false = non è riuscita
    func chiudi()
    func attendi() async                                // aspetta che gli aggiornamenti in coda siano finiti
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
        // Senza allenamento si chiude anche l'attività ripresa all'avvio, che `mostrato` non conosce
        guard voluto != mostrato || (voluto == nil && sistema.haAttivita) else { return }
        switch (mostrato, voluto) {
        case (nil, let nuovo?):
            // Se l'avvio non riesce (di solito: app in background) `mostrato` resta com'era e il prossimo giro riprova
            if sistema.avvia(nuovo) { mostrato = voluto }
        case (_?, let nuovo?):
            if sistema.aggiorna(nuovo) { mostrato = voluto }
        case (_, nil):
            sistema.chiudi()
            mostrato = nil
        }
    }

    // Dimentica quello che risulta mostrato: la prossima `applica` invia di nuovo lo stato, anche se uguale
    func riallinea() {
        mostrato = nil
    }

    // Aspetta che l'attività sia davvero aggiornata (serve all'intent: iOS può sospendere l'app appena `perform` ritorna)
    func attendi() async {
        await sistema.attendi()
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

    // Come `aggiorna`, ma ritorna solo a update fatto
    func aggiornaEAttendi() async {
        aggiorna()
        await live.attendi()
    }

    // App di nuovo attiva: l'attività può essere sparita (swipe, sistema, avvio fallito in background), si reinvia lo stato
    func riallinea() {
        live.riallinea()
        aggiorna()
    }

    private func costruisci() -> StatoAllenamentoLive? {
        StatoAllenamentoLive.da(allenamento: palestra.stato.inCorso, ultimaSerie: palestra.ultimaSerie,
                                recupero: timer.stato, libreria: palestra.stato.esercizi,
                                precedente: { palestra.precedente($0, $1) })
    }
}

// Per i test e la modalità demo: non crea attività vere
struct SistemaAttivitaNullo: SistemaAttivita {
    var haAttivita: Bool { false }
    func avvia(_ stato: StatoAllenamentoLive) -> Bool { true }
    func aggiorna(_ stato: StatoAllenamentoLive) -> Bool { true }
    func chiudi() {}
    func attendi() async {}
}

// La Live Activity vera, con ActivityKit (niente notifiche push: la aggiorna solo l'app)
final class AttivitaDiSistema: SistemaAttivita {
    private var attivita: Activity<AttivitaAllenamento>?
    private var coda: Task<Void, Never>?   // gli aggiornamenti vanno in ordine, uno dopo l'altro

    // All'avvio dell'app si riprende l'attività ancora viva (quella che l'utente sta guardando) e si chiudono le altre
    init() {
        let tutte = Activity<AttivitaAllenamento>.activities
        attivita = tutte.first { Self.viva($0) }
        let altre = tutte.filter { $0.id != attivita?.id }
        if !altre.isEmpty {
            accoda { for a in altre { await a.end(nil, dismissalPolicy: .immediate) } }
        }
    }

    var haAttivita: Bool { attivita != nil }

    // Chiusa dall'utente (swipe) o dal sistema (dopo 8 ore) non è più viva
    private static func viva(_ a: Activity<AttivitaAllenamento>) -> Bool {
        a.activityState == .active || a.activityState == .stale
    }

    // Con un'attività viva la aggiorna, altrimenti ne chiede una nuova (da background spesso non riesce)
    @discardableResult
    func avvia(_ stato: StatoAllenamentoLive) -> Bool {
        let c = contenuto(stato)
        if let a = attivita, Self.viva(a) {
            accoda { await a.update(c) }
            return true
        }
        attivita = nil
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return false }
        do {
            attivita = try Activity.request(attributes: AttivitaAllenamento(), content: c, pushType: nil)
            return true
        } catch {
            return false
        }
    }

    @discardableResult
    func aggiorna(_ stato: StatoAllenamentoLive) -> Bool {
        avvia(stato)
    }

    func chiudi() {
        guard let a = attivita else { return }
        attivita = nil
        accoda { await a.end(nil, dismissalPolicy: .immediate) }
    }

    func attendi() async {
        await coda?.value
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
