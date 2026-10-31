import SwiftUI

// Cosa fare oggi: tre anelli e il prossimo pasto. Con le frecce si torna ai giorni passati;
// l'elenco completo dei pasti di un giorno è in Dieta
struct OggiView: View {
    var apriDieta: (String) -> Void = { _ in }

    @Environment(Archivio.self) private var archivio
    @Environment(\.importa) private var importa
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var testo
    @State private var giorno = Giorni.oggi()

    private var titolo: String {
        let oggi = Giorni.oggi()
        if giorno == oggi { return "Oggi" }
        if giorno == Giorni.aggiungi(oggi, -1) { return "Ieri" }
        return Giorni.nomi[Giorni.indice(giorno)]
    }

    private var notaCalorie: String {
        var t = "Calorie stimate con valori medi (tabelle CREA), olio compreso: sono un ordine di grandezza."
        if let bmr = archivio.profilo.bia.max(by: { $0.data < $1.data })?.bmr {
            t += " Metabolismo basale dall'ultima misurazione: \(numeroKcal(bmr)) kcal."
        }
        return t
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    intestazione
                    if let piano = archivio.profilo.piano(per: giorno) {
                        giornata(piano)
                    } else {
                        senzaPiano
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .animation(.spring(duration: 0.35), value: archivio.registro(giorno))
            }
            .scorrimentoTema()
            .sfondoTema()
            .toolbar(.hidden, for: .navigationBar)
            .animation(.default, value: giorno)
        }
        .seguiMezzanotte($giorno)
    }

    // ---------- Intestazione ----------

    @ViewBuilder private var intestazione: some View {
        let titoli = VStack(alignment: .leading, spacing: 2) {
            Text(Giorni.estesa(giorno))
                .font(.georgia(.subheadline, grassetto: true))
                .foregroundStyle(palette.secondario)
            TestoIntero(testo: titolo)
                .font(.georgia(.largeTitle, grassetto: true))
                .accessibilityAddTraits(.isHeader)
        }
        let comandi = HStack(spacing: 6) {
            freccia("Giorno precedente", "chevron.left") { giorno = Giorni.aggiungi(giorno, -1) }
            freccia("Giorno successivo", "chevron.right") { giorno = Giorni.aggiungi(giorno, 1) }
                .disabled(giorno >= Giorni.oggi())
                .opacity(giorno >= Giorni.oggi() ? 0.4 : 1)
            MenuProfilo()
        }
        VStack(alignment: .leading, spacing: 8) {
            if testo.isAccessibilitySize {
                titoli
                comandi
            } else {
                HStack(alignment: .bottom) {
                    titoli
                    Spacer(minLength: 8)
                    comandi
                }
            }
            if giorno != Giorni.oggi() {
                Button("Torna a oggi") { giorno = Giorni.oggi() }
                    .font(.georgia(.subheadline, grassetto: true))
                    .foregroundStyle(palette.accento)
                    .frame(minHeight: 44)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func freccia(_ etichetta: String, _ icona: String, azione: @escaping () -> Void) -> some View {
        Button(action: azione) {
            Image(systemName: icona)
                .font(.georgiaFissa(17, grassetto: true))
                .foregroundStyle(palette.testo)
                .frame(width: 44, height: 44)
                .background(palette.riempimento, in: .circle)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(etichetta)
    }

    // ---------- Contenuto ----------

    @ViewBuilder private func giornata(_ piano: Piano) -> some View {
        let pasti = piano.giorni[Giorni.indice(giorno)].pasti
        RiepilogoGiorno(giorno: giorno, piano: piano)
        if let i = archivio.registro(giorno).prossimoPasto(pasti) {
            SchedaProssimoPasto(giorno: giorno, indice: i, pasto: pasti[i])
        } else if !pasti.isEmpty {
            StatoVuoto(titolo: "Pasti segnati", icona: "checkmark.circle",
                       descrizione: "Non resta nessun pasto da segnare in questo giorno.")
        }
        Button { apriDieta(giorno) } label: {
            Text("Vedi tutti i pasti")
                .font(.georgia(.subheadline, grassetto: true))
                .foregroundStyle(palette.accento)
                .frame(minHeight: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        VStack(alignment: .leading, spacing: 8) {
            if !archivio.profilo.testoNote.isEmpty {
                Label(archivio.profilo.testoNote, systemImage: "lightbulb")
            }
            Text(notaCalorie)
        }
        .font(.georgia(.footnote))
        .foregroundStyle(palette.secondario)
        .padding(.horizontal, 6)
    }

    @ViewBuilder private var senzaPiano: some View {
        let prossimo = archivio.profilo.prossimoPiano(dopo: giorno)
        StatoVuoto(titolo: "Nessun piano per questo giorno", icona: "fork.knife",
                   descrizione: prossimo.map { "Il piano «\($0.nome)» inizia il \(Giorni.breve($0.dal))." }
                       ?? "Carica il piano alimentare in PDF: diventa il piano di Oggi e Dieta.") {
            if prossimo == nil {
                Button("Carica piano alimentare") { importa(.schema) }
                    .buttonStyle(TastoTema())
            }
        }
    }
}

// Tre anelli: calorie dei pasti segnati, pasti segnati, acqua bevuta
struct RiepilogoGiorno: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var testo
    let giorno: String
    let piano: Piano

    var body: some View {
        let pasti = piano.giorni[Giorni.indice(giorno)].pasti
        let fatti = pasti.indices.filter { archivio.slot(giorno, $0).fatto }.count
        let r = archivio.registro(giorno)
        let p = archivio.profilo
        let misure = Group {
            if let kcal = p.calorie(giorno) {
                misura(Anello(valore: kcal.previste > 0 ? kcal.segnate / kcal.previste : 0,
                              testo: numeroKcal(kcal.segnate),
                              descrizione: "Calorie dei pasti segnati: circa \(numeroKcal(kcal.segnate)) su \(numeroKcal(kcal.previste))"),
                       titolo: "di \(numeroKcal(kcal.previste)) kcal")
            }
            misura(Anello(valore: pasti.isEmpty ? 0 : Double(fatti) / Double(pasti.count),
                          testo: "\(fatti)/\(pasti.count)",
                          descrizione: "Pasti segnati: \(fatti) su \(pasti.count)", colore: palette.caldo),
                   titolo: "pasti")
            misura(Anello(valore: p.acqua > 0 ? r.acqua / p.acqua : 0, testo: num(r.acqua),
                          descrizione: "Acqua: \(num(r.acqua)) litri su \(num(p.acqua))", colore: palette.freddo),
                   titolo: "di \(num(p.acqua)) litri")
        }
        // Tre anelli in fila non ci stanno con il testo molto grande
        Group {
            if testo.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) { misure }
            } else {
                HStack(alignment: .top, spacing: 4) { misure }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(palette.scheda, in: .rect(cornerRadius: 22))
    }

    @ViewBuilder private func misura(_ anello: Anello, titolo: String) -> some View {
        let etichetta = Text(titolo)
            .font(.georgia(.footnote))
            .foregroundStyle(palette.secondario)
            .multilineTextAlignment(.center)
        if testo.isAccessibilitySize {
            HStack(spacing: 12) {
                anello
                etichetta
            }
        } else {
            VStack(spacing: 6) {
                anello
                etichetta
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// Il prossimo pasto: alimenti, «Mangiato» e «Altro» (alternative e fuori piano)
struct SchedaProssimoPasto: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var testo
    let giorno: String
    let indice: Int
    let pasto: Pasto
    @State private var foglio = false
    @State private var segnati = 0   // la scheda passa subito al pasto dopo: la vibrazione non può seguire il suo stato

    var body: some View {
        let s = archivio.slot(giorno, indice)
        let opz = pasto.opzione(s)
        VStack(alignment: .leading, spacing: 10) {
            intestazione(opz)
            ForEach(Array((opz?.alimenti ?? []).enumerated()), id: \.offset) { _, a in
                HStack(alignment: .firstTextBaseline) {
                    Text(a.nome)
                    Spacer(minLength: 12)
                    Text(a.quantita)
                        .foregroundStyle(palette.secondario)
                        .multilineTextAlignment(.trailing)
                }
                .font(.georgia(.callout))
            }
            tasti.padding(.top, 4)
        }
        .scheda()
        .sheet(isPresented: $foglio) {
            FoglioPasto(giorno: giorno, indice: indice, pasto: pasto)
        }
    }

    @ViewBuilder private func intestazione(_ opz: Opzione?) -> some View {
        let nome = VStack(alignment: .leading, spacing: 2) {
            Text(giorno == Giorni.oggi() ? "Prossimo pasto" : "Da segnare")
                .font(.georgia(.footnote, grassetto: true))
                .foregroundStyle(palette.accento)
            TestoIntero(testo: pasto.nome)
                .font(.georgia(.title2, grassetto: true))
        }
        if let opz, opz.kcal > 0 {
            let calorie = Text(kcal(opz.kcal, incompleto: !opz.calorie.ignoti.isEmpty))
                .font(.georgia(.subheadline))
                .foregroundStyle(palette.secondario)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if testo.isAccessibilitySize {
                nome
                calorie
            } else {
                HStack(alignment: .firstTextBaseline) {
                    nome
                    Spacer(minLength: 8)
                    calorie.fixedSize()
                }
            }
        } else {
            nome
        }
    }

    @ViewBuilder private var tasti: some View {
        let mangiato = Button("Mangiato") {
            archivio.cambiaSlot(giorno, indice) { $0.fatto = true; $0.altro = nil }
            segnati += 1
        }
        .buttonStyle(TastoTema())
        .sensoryFeedback(.success, trigger: segnati)
        let altro = Button("Altro") { foglio = true }
            .buttonStyle(TastoTema(principale: false))
            .accessibilityHint("Alternative e «Ho mangiato altro»")
        if testo.isAccessibilitySize {
            VStack(spacing: 8) {
                mangiato
                altro
            }
        } else {
            HStack(spacing: 8) {
                mangiato
                altro.fixedSize()
            }
        }
    }
}
