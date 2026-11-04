import Foundation

// «Ultima volta» che si tocca: kg e ripetizioni della serie precedente finiscono nei campi della serie (senza spuntarla)
enum UltimaVolta {
    struct Valori: Equatable {
        let kg: Double?
        let rip: Int?
    }

    static func valori(da precedente: SerieFatta?) -> Valori? {
        precedente.map { Valori(kg: $0.kg, rip: $0.rip) }
    }
}

// Quando un esercizio si chiude in una riga sola e verso quale esercizio si scorre
enum PercorsoAllenamento {
    // Tutte le serie spuntate (un esercizio senza serie non conta come finito)
    static func completo(_ e: EsercizioFatto) -> Bool {
        !e.serie.isEmpty && e.serie.allSatisfy(\.fatta)
    }

    // Si chiude se è completo, non lo si è riaperto a mano e non si sta scrivendo in una sua serie
    static func compresso(_ e: EsercizioFatto, riaperti: Set<UUID>, inModifica: UUID?) -> Bool {
        completo(e) && !riaperti.contains(e.id) && inModifica != e.id
    }

    // Il primo esercizio con serie ancora aperte dopo quello dato; se non c'è, il primo aperto prima
    static func prossimoAperto(dopo id: UUID, in esercizi: [EsercizioFatto]) -> UUID? {
        guard let i = esercizi.firstIndex(where: { $0.id == id }) else { return nil }
        let aperto = { (e: EsercizioFatto) in !completo(e) }
        return esercizi[(i + 1)...].first(where: aperto)?.id ?? esercizi[..<i].first(where: aperto)?.id
    }
}
