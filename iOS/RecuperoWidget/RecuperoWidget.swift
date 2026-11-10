import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

// Estensione di Forma: la Live Activity dell'allenamento in corso (schermata bloccata e Dynamic Island).
// La avvia, aggiorna e chiude l'app; qui c'è solo l'aspetto.
// Il cronometro, il conto alla rovescia e la barra scorrono da soli (Text e ProgressView con timerInterval):
// l'app non li aggiorna ogni secondo.
@main
struct RecuperoWidgetBundle: WidgetBundle {
    var body: some Widget {
        RecuperoLiveActivity()
    }
}

struct RecuperoLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AttivitaAllenamento.self) { contesto in
            VistaAllenamentoBloccata(stato: contesto.state, scaduto: contesto.isStale)
                .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { contesto in
            let stato = contesto.state
            let recupero = stato.recuperoAttivo(scaduto: contesto.isStale)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    if stato.esercizio != nil {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: stato.esercizio ?? "").font(.headline).lineLimit(1)
                            Text(verbatim: stato.rigaSerie)
                                .font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                        }
                        .padding(.leading, 4)
                    } else {
                        Text("Tutte le serie fatte").font(.headline).padding(.leading, 4)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if stato.puoSpuntare {
                        PulsanteFatta(stato: stato).padding(.trailing, 4)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        if let recupero {
                            RigaRecupero(stato: recupero, stile: .title2, compatto: true)
                        } else if stato.recupero != nil {
                            Label("Recupero finito", systemImage: "timer")
                                .font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                        }
                        if stato.esercizio == nil {
                            Text("Apri Forma per finire l'allenamento")
                                .font(.footnote).foregroundStyle(.secondary)
                        } else {
                            if !stato.puoSpuntare {
                                Text("Apri Forma per i kg").font(.footnote).foregroundStyle(.secondary)
                            }
                            HStack(alignment: .center, spacing: 8) {
                                RigaPoi(prossimo: stato.prossimo)
                                Spacer(minLength: 0)
                                if stato.movimento != nil { PulsanteSaltaRiscaldamento(compatto: true) }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                Image(systemName: recupero != nil ? "timer" : "dumbbell.fill")
            } compactTrailing: {
                if let recupero {
                    Text(timerInterval: recupero.intervallo, countsDown: true)
                        .font(.numero(.body))
                        .multilineTextAlignment(.trailing)
                        .frame(width: 48)
                } else if stato.esercizio != nil {
                    Text("\(stato.serie)/\(stato.totaleSerie)").font(.numero(.body))
                } else {
                    Image(systemName: "checkmark")
                }
            } minimal: {
                if let recupero {
                    ProgressView(timerInterval: recupero.intervallo, countsDown: true) {
                        EmptyView()
                    } currentValueLabel: {
                        Image(systemName: "timer")
                    }
                    .progressViewStyle(.circular)
                    .tint(.primary)
                } else {
                    Image(systemName: "dumbbell.fill")
                }
            }
        }
    }
}

// Schermata bloccata (e banner): allenamento e cronometro, esercizio con la serie da fare, «Fatta»; durante il recupero conto e barra
struct VistaAllenamentoBloccata: View {
    let stato: StatoAllenamentoLive
    let scaduto: Bool

    var body: some View {
        let recupero = stato.recuperoAttivo(scaduto: scaduto)
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(verbatim: stato.titolo)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(timerInterval: stato.inizio...Date.distantFuture, countsDown: false)
                    .font(.numero(.subheadline))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 90, alignment: .trailing)
            }
            if let esercizio = stato.esercizio {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(verbatim: esercizio).font(.title2.weight(.bold)).lineLimit(2)
                        Text(verbatim: stato.rigaSerie).font(.body).lineLimit(1)
                        if let spiegazione = stato.spiegazione {
                            Text(verbatim: spiegazione).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                        }
                        if scaduto && stato.recupero != nil {
                            Label("Recupero finito", systemImage: "timer")
                                .font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                        }
                        RigaPoi(prossimo: stato.prossimo)
                    }
                    Spacer(minLength: 0)
                    if stato.puoSpuntare {
                        // «Fatta» è il principale; durante il riscaldamento sotto c'è «Salta», secondario
                        VStack(alignment: .trailing, spacing: 6) {
                            PulsanteFatta(stato: stato)
                            if stato.movimento != nil { PulsanteSaltaRiscaldamento(compatto: false) }
                        }
                    } else {
                        Text("Apri Forma per i kg")
                            .font(.caption).foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 90, alignment: .trailing)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Tutte le serie fatte").font(.title2.weight(.bold))
                    Text("Apri Forma per finire l'allenamento").font(.subheadline).foregroundStyle(.secondary)
                }
            }
            if let recupero {
                RigaRecupero(stato: recupero, stile: .title, compatto: false)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// «Poi: Squat» oppure «Ultimo esercizio»
struct RigaPoi: View {
    let prossimo: String?

    var body: some View {
        Group {
            if let prossimo {
                Text("Poi: \(prossimo)")
            } else {
                Text("Ultimo esercizio")
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
}

// Il pulsante «Fatta»: l'unico verde pieno; segna il movimento del riscaldamento o la serie mostrata
// (gira nell'app, senza aprirla)
struct PulsanteFatta: View {
    let stato: StatoAllenamentoLive

    var body: some View {
        if let m = stato.movimento {
            Button(intent: SegnaRiscaldamentoIntent(movimento: m)) { etichetta }
                .buttonStyle(.plain)
                .fixedSize()
        } else if let id = stato.idSerie {
            Button(intent: SegnaSerieIntent(serie: id)) { etichetta }
                .buttonStyle(.plain)
                .fixedSize()
        }
    }

    private var etichetta: some View {
        Label("Fatta", systemImage: "checkmark")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Colori.sulAccento)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Colori.accento, in: Capsule())
    }
}

// Il conto alla rovescia m:ss, con le cifre arrotondate come nell'app
struct ContoRecupero: View {
    let stato: StatoRecupero
    let stile: Font.TextStyle
    var allineato: Alignment = .trailing

    var body: some View {
        Text(timerInterval: stato.intervallo, countsDown: true)
            .font(.numero(stile))
            .multilineTextAlignment(allineato == .leading ? .leading : .trailing)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: 140, alignment: allineato)
    }
}

// Il recupero: timer e conto alla rovescia a sinistra, «−15 s», «+15 s» e «Salta» a destra sulla stessa riga
// (nessuna riga in più: il conto non si taglia), la barra sotto
struct RigaRecupero: View {
    let stato: StatoRecupero
    let stile: Font.TextStyle
    let compatto: Bool

    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "timer").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                ContoRecupero(stato: stato, stile: stile, allineato: .leading)
                    .accessibilityLabel("Recupero")
                Spacer(minLength: 0)
                HStack(spacing: compatto ? 5 : 8) {
                    PulsanteSecondario(titolo: "−15 s", voce: "Togli 15 secondi", intent: CambiaRecuperoIntent(secondi: -15), compatto: compatto)
                    PulsanteSecondario(titolo: "+15 s", voce: "Aggiungi 15 secondi", intent: CambiaRecuperoIntent(secondi: 15), compatto: compatto)
                    PulsanteSecondario(titolo: "Salta", voce: "Salta il recupero", intent: SaltaRecuperoIntent(), compatto: compatto)
                }
            }
            BarraRecupero(stato: stato)
        }
    }
}

// «Salta» sul riscaldamento: salta i movimenti rimasti
struct PulsanteSaltaRiscaldamento: View {
    let compatto: Bool

    var body: some View {
        PulsanteSecondario(titolo: "Salta", voce: "Salta il riscaldamento", intent: SaltaRiscaldamentoIntent(), compatto: compatto)
    }
}

// Pulsante secondario: capsula chiara, testo normale. Solo «Fatta» è pieno e verde
struct PulsanteSecondario<I: AppIntent>: View {
    let titolo: LocalizedStringKey
    let voce: LocalizedStringKey
    let intent: I
    let compatto: Bool

    var body: some View {
        Button(intent: intent) {
            Text(titolo)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .padding(.horizontal, compatto ? 8 : 11)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.14), in: Capsule())
        }
        .buttonStyle(.plain)
        .fixedSize()
        .accessibilityLabel(voce)
    }
}

// La barra del recupero: si svuota man mano che il tempo passa
struct BarraRecupero: View {
    let stato: StatoRecupero

    var body: some View {
        ProgressView(timerInterval: stato.intervallo, countsDown: true) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .progressViewStyle(.linear)
        .tint(.primary)
        .accessibilityHidden(true)
    }
}

extension StatoRecupero {
    // Mai un intervallo rovesciato, anche se la fine fosse prima dell'inizio
    var intervallo: ClosedRange<Date> { inizio...max(inizio, fine) }
}

extension StatoAllenamentoLive {
    // Il recupero da mostrare: c'è e non è scaduto (con l'app sospesa iOS segna la Live Activity come «stale»)
    func recuperoAttivo(scaduto: Bool) -> StatoRecupero? {
        scaduto ? nil : recupero
    }

    // «Serie 2 di 4 · 80 kg × 8»; riscaldamento: «Riscaldamento · …»; corpo libero: «… · 8 ripetizioni»
    var rigaSerie: String {
        // Movimento del riscaldamento: «Riscaldamento 2 di 6»
        if movimento != nil { return String(localized: "Riscaldamento \(serie) di \(totaleSerie)") }
        // Il riscaldamento ha la sua numerazione, come nell'app (R): «Riscaldamento · Serie 1 di 2 · 20 kg × 10»
        var parti = riscaldamento
            ? [String(localized: "Riscaldamento"), String(localized: "Serie \(serie) di \(totaleSerie)")]
            : [String(localized: "Serie \(serie) di \(totaleSerie)")]
        let ripetizioni = rip ?? 0
        let pesi = kg ?? 0
        if pesi > 0 {
            let testoKg = pesi.formatted(.number.precision(.fractionLength(0...2)))
            parti.append(ripetizioni > 0
                ? String(localized: "\(testoKg) kg × \(ripetizioni)")
                : String(localized: "\(testoKg) kg"))
        } else if ripetizioni > 0 {
            parti.append(String(localized: "\(ripetizioni) ripetizioni"))
        }
        return parti.joined(separator: " · ")
    }
}

// MARK: - Anteprime

private extension StatoAllenamentoLive {
    static func esempio(recupero: StatoRecupero? = nil, valori: Bool = true, fatte: Bool = false) -> StatoAllenamentoLive {
        let adesso = Date.now
        return StatoAllenamentoLive(
            titolo: "Gambe",
            inizio: adesso.addingTimeInterval(-1_260),
            esercizio: fatte ? nil : "Panca piana con manubri",
            serie: 2, totaleSerie: 4,
            kg: valori ? 80 : nil, rip: valori ? 8 : nil,
            idSerie: UUID(),
            prossimo: fatte ? nil : "Squat",
            recupero: recupero)
    }
}

#Preview("Allenamento", as: .content, using: AttivitaAllenamento()) {
    RecuperoLiveActivity()
} contentStates: {
    StatoAllenamentoLive.esempio()
    StatoAllenamentoLive.esempio(recupero: StatoRecupero(inizio: .now, fine: .now.addingTimeInterval(90), esercizio: "Panca piana con manubri"))
    StatoAllenamentoLive.esempio(valori: false)
    StatoAllenamentoLive.esempio(fatte: true)
    StatoAllenamentoLive.esempio(recupero: StatoRecupero(inizio: .now, fine: .now.addingTimeInterval(605), esercizio: "Panca piana con manubri"), valori: false)
    StatoAllenamentoLive(titolo: "Gambe", inizio: .now, esercizio: "Squat a corpo libero (10 lenti)", serie: 4, totaleSerie: 6,
                         riscaldamento: true, prossimo: "Squat", movimento: 3,
                         spiegazione: "Piedi alla larghezza delle spalle, scendi lentamente e risali. Scalda ginocchia e caviglie.")
}

#Preview("Isola espansa", as: .dynamicIsland(.expanded), using: AttivitaAllenamento()) {
    RecuperoLiveActivity()
} contentStates: {
    StatoAllenamentoLive.esempio(recupero: StatoRecupero(inizio: .now, fine: .now.addingTimeInterval(90), esercizio: "Panca piana con manubri"))
    StatoAllenamentoLive(titolo: "Gambe", inizio: .now, esercizio: "Squat a corpo libero (10 lenti)", serie: 4, totaleSerie: 6,
                         riscaldamento: true, prossimo: "Squat", movimento: 3)
}
