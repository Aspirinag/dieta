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
