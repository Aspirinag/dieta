import Foundation

// Backup di Forma: dieta e palestra insieme. L'importazione accetta anche i backup
// delle web app e delle app Dieta e Palestra
enum Backup {
    private struct Completo: Codable {
        var forma = 1
        var dieta: Stato
        var palestra: StatoPalestra
    }

    static func esporta(archivio: Archivio, palestra: Palestra) -> Data {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? e.encode(Completo(dieta: archivio.stato, palestra: palestra.stato))) ?? Data()
    }

    static func importa(_ dati: Data, archivio: Archivio, palestra: Palestra) throws {
        let chiavi = (try? JSONSerialization.jsonObject(with: dati) as? [String: Any])?.keys.map { $0 } ?? []
        if chiavi.contains("forma") {
            let c = try JSONDecoder().decode(Completo.self, from: dati)
            archivio.stato = c.dieta
            palestra.stato = c.palestra
        } else if chiavi.contains("profili") {
            try archivio.importa(dati)                 // backup di Dieta
        } else if chiavi.contains("plans") {
            try palestra.importaVecchia(dati)          // backup della vecchia Palestra
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
}
