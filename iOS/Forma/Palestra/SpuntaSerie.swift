import Foundation

// Cosa succede toccando la spunta di una serie non ancora fatta
// Il campo di una serie che ha il cursore: la serie e se è quello dei kg o delle ripetizioni
struct PuntoDiFocus: Hashable {
    let serie: UUID
    let campo: EsitoSpunta.Campo
}

enum EsitoSpunta: Equatable {
    case segna(kg: Double, rip: Int)
    case manca(Campo)

    enum Campo { case kg, rip }

    // I campi vuoti prendono i valori della serie precedente; a corpo libero i kg vuoti valgono 0
    static func valuta(kg: Double?, rip: Int?, precedente: SerieFatta?, corpoLibero: Bool) -> EsitoSpunta {
        guard let r = rip ?? precedente?.rip, r > 0 else { return .manca(.rip) }
        guard let k = kg ?? precedente?.kg ?? (corpoLibero ? 0 : nil) else { return .manca(.kg) }
        return .segna(kg: k, rip: r)
    }
}

// La serie «attiva»: quella che ha sotto i ± e verso cui la schermata scorre se esce dalla vista.
// Si parte dal riferimento (l'ultima serie spuntata o toccata): se è da fare è lei; altrimenti la prima da fare dopo di lei
// nello stesso esercizio, poi una rimasta indietro nello stesso esercizio, poi il primo esercizio con serie da fare
// dopo, poi prima. Senza riferimento: la prima serie da fare dell'allenamento.
enum SerieAttiva {
    static func trova(in esercizi: [EsercizioFatto], riferimento: UUID?) -> UUID? {
        let primaDaFare = { (e: EsercizioFatto) in e.serie.first { !$0.fatta }?.id }
        guard let riferimento,
              let i = esercizi.firstIndex(where: { $0.serie.contains { $0.id == riferimento } }),
              let j = esercizi[i].serie.firstIndex(where: { $0.id == riferimento }) else {
            return esercizi.lazy.compactMap(primaDaFare).first
        }
        let serie = esercizi[i].serie
        if let s = serie[j...].first(where: { !$0.fatta }) ?? serie[..<j].first(where: { !$0.fatta }) { return s.id }
        return esercizi[(i + 1)...].lazy.compactMap(primaDaFare).first ?? esercizi[..<i].lazy.compactMap(primaDaFare).first
    }
}

// ± della serie senza tastiera: kg a passi di 2,5, ripetizioni a passi di 1, mai sotto zero.
// Il valore di partenza è quello scritto nel campo; se il campo è vuoto, quello dell'ultima volta (la base); se manca anche quello, 0
enum PassoSerie {
    static let kg = 2.5
    static let rip = 1

    static func kg(_ testo: String, base: Double?, delta: Double) -> Double {
        let partenza = leggiNumero(testo) ?? base ?? 0
        return max(0, ((partenza + delta) * 100).rounded() / 100)
    }

    static func rip(_ testo: String, base: Int?, delta: Int) -> Int {
        let partenza = Int(testo.trimmingCharacters(in: .whitespaces)) ?? base ?? 0
        return max(0, partenza + delta)
    }
}
