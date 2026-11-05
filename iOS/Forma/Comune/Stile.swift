import SwiftUI

// SISTEMA VISIVO — misure, testo dei numeri, date.
// Nessuna schermata scrive a mano spaziature, raggi, dimensioni di testo o formati di data: usa questi.
//
// Spazio      .xs 4 · .s 8 · .m 12 · .l 16 · .xl 24 (24 tra gruppi fuori dalle liste)
//               VStack(spacing: Spazio.s) { … }.padding(.horizontal, Spazio.l)
// Misure      .raggio 16 (riquadri fuori dalle liste; pulsanti a capsula) · .tocco 44 (area minima di ogni
//             cosa toccabile) · .riga 52 (altezza minima di una Riga) · .spunta 26 (cerchio di CerchioSpunta)
//               .frame(minWidth: Misure.tocco, minHeight: Misure.tocco)
//               .background(…, in: .rect(cornerRadius: Misure.raggio, style: .continuous))
// .numero(_:) numeri importanti: SF Rounded semibold a cifre fisse SULLO STILE DI SISTEMA, quindi cresce
//             con il testo grande. Mai `.font(.system(size:))`.
//               Text(num(kg)).numero(.largeTitle)      // peso
//               Text(tempo).numero(.title2)            // cronometro
//               Text("150 g").numero()                 // grammi in una riga (.body)
//             Esiste anche come Font: `.font(.numero(.title))`.
// Testi       Testi.data(data)            «giovedì 5 novembre» (formato di sistema, mese minuscolo in italiano)
//             Testi.data(data, anno: true) «giovedì 5 novembre 2026»
//             Testi.data(iso: "2026-11-05")  stesso formato da una data salvata come stringa
//             Testi.periodo(da:a:)        «2–8 novembre» (estremi compresi)
//             Testi.conSegno(-0.8, unita: "kg")  «−0,8 kg» · «+0,3 kg» · «0 kg» (variazioni neutre, sempre .secondary)
//             Mai «05/11/2026» né `.capitalized` sulle date.

enum Spazio {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
}

enum Misure {
    // Un solo raggio per i riquadri fuori dalle liste (dentro una lista vale quello di sistema)
    static let raggio: CGFloat = 16
    // Area minima di tocco (HIG): 44 × 44
    static let tocco: CGFloat = 44
    // Altezza minima di una riga di lista standard
    static let riga: CGFloat = 52
    // Diametro del cerchio di spunta (cresce con il testo grande, vedi CerchioSpunta)
    static let spunta: CGFloat = 26
    // Spessore del contorno degli elementi vuoti (cerchi, cucchiaini, gocce)
    static let contorno: CGFloat = 1.5
}

extension View {
    // Vedi Font.numero: `Text(num(kg)).numero(.largeTitle)`
    func numero(_ stile: Font.TextStyle = .body) -> some View {
        font(.numero(stile))
    }
}

enum Testi {
    // «giovedì 5 novembre» in italiano, «Thursday, November 5» in inglese: il formato è quello di sistema
    static func data(_ data: Date, anno: Bool = false, locale: Locale = .current) -> String {
        var stile = Date.FormatStyle.dateTime.weekday(.wide).day().month(.wide).locale(locale)
        if anno { stile = stile.year() }
        return data.formatted(stile)
    }

    // Stessa cosa da una data salvata come «2026-11-05» (vedi Giorni)
    static func data(iso: String, anno: Bool = false, locale: Locale = .current) -> String {
        data(Giorni.data(iso), anno: anno, locale: locale)
    }

    // «2–8 novembre», «30 novembre – 6 dicembre»: intervallo di giorni, estremi compresi
    static func periodo(da inizio: Date, a fine: Date, locale: Locale = .current) -> String {
        var stile = Date.IntervalFormatStyle(date: .omitted, time: .omitted).day().month(.wide)
        stile.locale = locale
        return (inizio..<max(inizio, fine)).formatted(stile)
    }

    // Variazione con il segno vero: «−0,8 kg», «+0,3 kg», «0 kg». Da mostrare sempre in `.secondary`:
    // una variazione del corpo non si colora mai (né verde né rosso)
    static func conSegno(_ valore: Double, unita: String, locale: Locale = .current) -> String {
        let arrotondato = (valore * 100).rounded() / 100
        let segno = arrotondato > 0 ? "+" : (arrotondato < 0 ? "\u{2212}" : "")
        return "\(segno)\(num(abs(arrotondato), locale: locale)) \(unita)"
    }
}
