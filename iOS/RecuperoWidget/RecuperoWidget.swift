import ActivityKit
import SwiftUI
import WidgetKit

// Estensione di Forma: la Live Activity del recupero tra le serie (schermata bloccata e Dynamic Island).
// La avvia, aggiorna e chiude l'app (Palestra/LiveRecupero.swift); qui c'è solo l'aspetto.
// Il conto alla rovescia e la barra scorrono da soli (Text e ProgressView con timerInterval): l'app non li aggiorna ogni secondo.
@main
struct RecuperoWidgetBundle: WidgetBundle {
    var body: some Widget {
        RecuperoLiveActivity()
    }
}

struct RecuperoLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AttivitaRecupero.self) { contesto in
            VistaRecuperoBloccata(stato: contesto.state, finito: contesto.isStale)
                .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { contesto in
            let stato = contesto.state
            let finito = contesto.isStale
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Recupero", systemImage: "timer")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ContoRecupero(stato: stato, finito: finito, stile: .title2)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        if finito {
                            Text("Puoi iniziare la prossima serie.").font(.headline)
                        } else if let esercizio = stato.esercizio {
                            Text(verbatim: esercizio).font(.headline).lineLimit(1)
                        }
                        BarraRecupero(stato: stato, finito: finito)
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                Image(systemName: "timer").foregroundStyle(Colore.arancio)
            } compactTrailing: {
                if finito {
                    Image(systemName: "checkmark")
                } else {
                    Text(timerInterval: stato.intervallo, countsDown: true)
                        .font(.numero(.body))
                        .multilineTextAlignment(.trailing)
                        .frame(width: 48)
                }
            } minimal: {
                if finito {
                    Image(systemName: "checkmark")
                } else {
                    ProgressView(timerInterval: stato.intervallo, countsDown: true) {
                        EmptyView()
                    } currentValueLabel: {
                        Image(systemName: "timer")
                    }
                    .progressViewStyle(.circular)
                    .tint(Colore.arancio)
                }
            }
            .keylineTint(Colore.arancio)
        }
    }
}

// Schermata bloccata (e banner): «Recupero», esercizio, conto alla rovescia grande e barra
struct VistaRecuperoBloccata: View {
    let stato: StatoRecupero
    let finito: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Group {
                        if finito {
                            Label("Recupero finito", systemImage: "timer")
                        } else {
                            Label("Recupero", systemImage: "timer")
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    if finito {
                        Text("Puoi iniziare la prossima serie.").font(.headline)
                    } else if let esercizio = stato.esercizio {
                        Text(verbatim: esercizio).font(.headline).lineLimit(2)
                    }
                }
                Spacer(minLength: 0)
                ContoRecupero(stato: stato, finito: finito, stile: .largeTitle)
            }
            BarraRecupero(stato: stato, finito: finito)
        }
        .padding(16)
    }
}

// Il conto alla rovescia m:ss, con le cifre arrotondate come nell'app
struct ContoRecupero: View {
    let stato: StatoRecupero
    let finito: Bool
    let stile: Font.TextStyle

    var body: some View {
        if finito {
            Image(systemName: "checkmark").font(.system(stile, weight: .semibold))
        } else {
            Text(timerInterval: stato.intervallo, countsDown: true)
                .font(.numero(stile))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 140, alignment: .trailing)
        }
    }
}

// La barra del recupero: si svuota man mano che il tempo passa
struct BarraRecupero: View {
    let stato: StatoRecupero
    let finito: Bool

    var body: some View {
        Group {
            if finito {
                ProgressView(value: 0)
            } else {
                ProgressView(timerInterval: stato.intervallo, countsDown: true) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
            }
        }
        .progressViewStyle(.linear)
        .tint(Colore.arancio)
        .accessibilityHidden(true)
    }
}

enum Colore {
    // Lo stesso arancio dell'app (AccentColor), chiaro e scuro
    static let arancio = Color("Arancio")
}

extension StatoRecupero {
    // Mai un intervallo rovesciato, anche se la fine fosse prima dell'inizio
    var intervallo: ClosedRange<Date> { inizio...max(inizio, fine) }
}

extension Font {
    // Come `Font.numero` dell'app: SF Rounded semibold, cifre fisse
    static func numero(_ stile: Font.TextStyle) -> Font {
        .system(stile, design: .rounded, weight: .semibold).monospacedDigit()
    }
}
