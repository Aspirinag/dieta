import Foundation

// Lettura dei file dati: se un file c'è ma non si decodifica, se ne tiene una copia accanto
// (così ripartire da zero non lo sovrascrive e i dati si possono recuperare).
// Se il file c'è ma non si riesce nemmeno a leggerlo (es. telefono bloccato), non va mai sovrascritto
enum FileDati {
    enum Esito<T> {
        case ok(T)
        case assente
        case illeggibile(copia: URL)
        case bloccato               // esiste ma non si legge, o non si è potuta salvare la copia: non salvare
    }

    static let marcaCopia = ".illeggibile-"

    struct DatiVuoti: Error {}

    // Scrive i dati sul file, ma mai dati vuoti: un file buono non va sostituito con uno vuoto
    static func scrivi(_ dati: Data, su url: URL) throws {
        guard !dati.isEmpty else { throw DatiVuoti() }
        try dati.write(to: url, options: .atomic)
    }

    static func leggi<T: Decodable>(_ url: URL, come: T.Type) -> Esito<T> {
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else { return .assente }
        guard let dati = try? Data(contentsOf: url) else { return .bloccato }
        // Un file vuoto non contiene niente da salvare: niente copia (e niente copia vuota da confondere con quelle buone)
        if dati.isEmpty { return .assente }
        if let valore = try? JSONDecoder().decode(T.self, from: dati) { return .ok(valore) }
        let nomeFile = url.deletingPathExtension().lastPathComponent
        // Stesso contenuto già messo da parte a un'apertura precedente: niente copia nuova
        if let esistente = copie(in: url.deletingLastPathComponent()).first(where: {
            $0.lastPathComponent.hasPrefix(nomeFile + marcaCopia) && (try? Data(contentsOf: $0)) == dati
        }) {
            return .illeggibile(copia: esistente)
        }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd-HHmmss"
        let copia = url.deletingLastPathComponent().appending(path: "\(nomeFile)\(marcaCopia)\(f.string(from: Date())).json")
        do { try dati.write(to: copia, options: .atomic) } catch { return .bloccato }
        return .illeggibile(copia: copia)
    }

    // Copie dei file non letti in una cartella, dalla più recente
    static func copie(in cartella: URL) -> [URL] {
        let tutti = (try? FileManager.default.contentsOfDirectory(at: cartella, includingPropertiesForKeys: nil)) ?? []
        return tutti.filter { $0.lastPathComponent.contains(marcaCopia) }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }
}
