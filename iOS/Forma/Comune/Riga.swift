import SwiftUI

// SISTEMA VISIVO — riga di lista standard (dentro una List raggruppata). Alta almeno Misure.riga (52 pt).
//
//   [inizio]  Titolo                       valore  [fine]
//             dettaglio (grigio, va a capo)
//
// - titolo: .body, oppure .headline con `evidente: true` (nomi di pasto, esercizio, scheda)
// - dettaglio: .subheadline .secondary, va a capo (mai troncato: grammature e alimenti si leggono interi);
//   `righeDettaglio:` limita le righe solo a testo normale (a testo di accessibilità sempre tutte)
// - valore: a destra, cifre fisse, .secondary; non si tronca mai
// - inizio/fine: viste facoltative (CerchioSpunta, icona .secondary, PulsanteAccento). La freccia di una
//   riga che apre una pagina la mette il NavigationLink di sistema: non disegnarla.
// - fatta: true → titolo e dettaglio in grigio (secondo segno dello stato «fatto», insieme a CerchioSpunta)
// A testo di accessibilità il valore e la vista `fine` vanno sotto il testo invece che a destra.
// Titolo, dettaglio e valore sono un solo elemento per VoiceOver; inizio e fine restano a sé.
//
// Esempi:
//   Riga("Leg press", dettaglio: "3 serie", valore: "77,5 kg")
//   Riga(Text(pasto.nome), dettaglio: Text(opzione.riassunto), evidente: true, fatta: s.fatto,
//        inizio: CerchioSpunta(fatta: s.fatto, etichetta: Text("Segna \(pasto.nome)")) { … })   // spunta a sinistra
//   Riga(Text(scheda.nome), dettaglio: Text("6 esercizi · circa 55 min"), evidente: true) {        // closure = a destra
//       Button("Inizia") { … }.buttonStyle(PulsanteAccento())
//   }
//   Riga(…, inizio: { icona }, fine: { CerchioSpunta(…) })                                        // tutte e due
//   NavigationLink(value: scheda) { Riga(Text(scheda.nome), dettaglio: Text("6 esercizi · circa 55 min"), evidente: true) }
struct Riga<Inizio: View, Fine: View>: View {
    private let titolo: Text
    private let dettaglio: Text?
    private let valore: Text?
    private let evidente: Bool
    private let fatta: Bool
    private let righeDettaglio: Int?
    private let inizio: Inizio
    private let fine: Fine
    @Environment(\.dynamicTypeSize) private var dimensione

    init(_ titolo: Text, dettaglio: Text? = nil, valore: Text? = nil, evidente: Bool = false, fatta: Bool = false,
         righeDettaglio: Int? = nil,
         @ViewBuilder inizio: () -> Inizio, @ViewBuilder fine: () -> Fine) {
        self.titolo = titolo
        self.dettaglio = dettaglio
        self.valore = valore
        self.evidente = evidente
        self.fatta = fatta
        self.righeDettaglio = righeDettaglio
        self.inizio = inizio()
        self.fine = fine()
    }

    var body: some View {
        HStack(spacing: Spazio.m) {
            inizio
            if dimensione.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Spazio.xs) {
                    testi
                    if valore != nil || Fine.self != EmptyView.self {
                        HStack(spacing: Spazio.m) { valoreVista; fine }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(spacing: Spazio.m) {
                    testi.frame(maxWidth: .infinity, alignment: .leading)
                    valoreVista
                }
                fine
            }
        }
        .frame(minHeight: Misure.riga)
    }

    private var testi: some View {
        VStack(alignment: .leading, spacing: 2) {
            titolo
                .font(evidente ? .headline : .body)
                .foregroundStyle(fatta ? .secondary : .primary)
            if let dettaglio {
                dettaglio
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(dimensione.isAccessibilitySize ? nil : righeDettaglio)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(fatta ? .isSelected : [])
    }

    @ViewBuilder private var valoreVista: some View {
        if let valore {
            valore
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: !dimensione.isAccessibilitySize, vertical: true)
        }
    }
}

// Senza viste ai lati, o con una sola
extension Riga where Inizio == EmptyView, Fine == EmptyView {
    init(_ titolo: Text, dettaglio: Text? = nil, valore: Text? = nil, evidente: Bool = false, fatta: Bool = false,
         righeDettaglio: Int? = nil) {
        self.init(titolo, dettaglio: dettaglio, valore: valore, evidente: evidente, fatta: fatta,
                  righeDettaglio: righeDettaglio, inizio: { EmptyView() }, fine: { EmptyView() })
    }

    // Testi del catalogo: Riga("Olio", dettaglio: "2 di 3 cucchiaini")
    init(_ titolo: LocalizedStringKey, dettaglio: LocalizedStringKey? = nil, valore: LocalizedStringKey? = nil,
         evidente: Bool = false, fatta: Bool = false) {
        self.init(Text(titolo), dettaglio: dettaglio.map { Text($0) }, valore: valore.map { Text($0) },
                  evidente: evidente, fatta: fatta)
    }
}

extension Riga where Inizio == EmptyView {
    init(_ titolo: Text, dettaglio: Text? = nil, valore: Text? = nil, evidente: Bool = false, fatta: Bool = false,
         righeDettaglio: Int? = nil, @ViewBuilder fine: () -> Fine) {
        self.init(titolo, dettaglio: dettaglio, valore: valore, evidente: evidente, fatta: fatta,
                  righeDettaglio: righeDettaglio, inizio: { EmptyView() }, fine: fine)
    }
}

// Solo a sinistra: la vista si passa come valore (non come closure), così `Riga(…) { … }` vuol dire sempre `fine`
extension Riga where Fine == EmptyView {
    init(_ titolo: Text, dettaglio: Text? = nil, valore: Text? = nil, evidente: Bool = false, fatta: Bool = false,
         righeDettaglio: Int? = nil, inizio: Inizio) {
        self.init(titolo, dettaglio: dettaglio, valore: valore, evidente: evidente, fatta: fatta,
                  righeDettaglio: righeDettaglio, inizio: { inizio }, fine: { EmptyView() })
    }
}

#Preview {
    List {
        Riga(Text(verbatim: "Leg press"), dettaglio: Text(verbatim: "3 serie"), valore: Text(verbatim: "77,5 kg"))
        Riga(Text(verbatim: "Colazione"),
             dettaglio: Text(verbatim: "Yogurt greco 150 g, fiocchi d'avena 30 g, mirtilli 80 g, noci 15 g"),
             evidente: true, fatta: true,
             inizio: CerchioSpunta(fatta: true, etichetta: Text(verbatim: "Colazione")) {})
        Riga(Text(verbatim: "Spinta"), dettaglio: Text(verbatim: "6 esercizi · circa 55 min"), evidente: true) {
            Button(String("Inizia")) {}.buttonStyle(PulsanteAccento())
        }
    }
}
