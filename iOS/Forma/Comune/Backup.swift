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

    // Un backup della web app non ha i promemoria di Forma (la web app salva solo acqua e pasti):
    // si tengono quelli attuali, così non si riaccende il promemoria del mattino
    static func dietaImportata(_ dati: Data, promemoria: Promemoria?) throws -> Stato {
        var stato = try JSONDecoder().decode(Stato.self, from: dati)
        stato.promemoria = promemoria
        return stato
    }

    static func importa(_ dati: Data, archivio: Archivio, palestra: Palestra) throws {
        let chiavi = (try? JSONSerialization.jsonObject(with: dati) as? [String: Any])?.keys.map { $0 } ?? []
        if chiavi.contains("forma") {
            let c = try JSONDecoder().decode(Completo.self, from: dati)
            archivio.stato = c.dieta
            palestra.stato = c.palestra
        } else if chiavi.contains("profili") {
            archivio.stato = try dietaImportata(dati, promemoria: archivio.stato.promemoria)  // backup di Dieta
        } else if chiavi.contains("plans") {
            try palestra.importaVecchia(dati)          // backup della vecchia Palestra
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
}
