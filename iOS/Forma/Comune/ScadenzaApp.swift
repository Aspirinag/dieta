import Foundation

// Con l'Apple ID gratuito l'app installata dal Mac scade dopo 7 giorni: due giorni prima arriva un avviso.
// La data di scadenza si legge dal profilo di firma dentro l'app (assente su simulatore e App Store: nessun avviso).
enum ScadenzaApp {
    static let idAvviso = "scadenza-app"
    static let giorniPrima = 2
    static let oraAvviso = 9

    // Data di fine validità del profilo di firma, se l'app ne ha uno
    static func scadenzaProfilo(_ bundle: Bundle = .main) -> Date? {
        guard let url = bundle.url(forResource: "embedded", withExtension: "mobileprovision"),
              let dati = try? Data(contentsOf: url) else { return nil }
        return scadenza(dalProfilo: dati)
    }

    // Il profilo è un messaggio firmato che contiene un plist XML: si estrae il plist
    static func scadenza(dalProfilo dati: Data) -> Date? {
        guard let inizio = dati.range(of: Data("<?xml".utf8)),
              let fine = dati.range(of: Data("</plist>".utf8), in: inizio.lowerBound..<dati.endIndex) else { return nil }
        let plist = dati.subdata(in: inizio.lowerBound..<fine.upperBound)
        guard let oggetto = try? PropertyListSerialization.propertyList(from: plist, format: nil) as? [String: Any] else { return nil }
        return oggetto["ExpirationDate"] as? Date
    }

    // Quando mostrare l'avviso: alle 9 di due giorni prima della scadenza; se quel momento è già passato
    // ma l'app non è ancora scaduta, tra un minuto; se è già scaduta, mai.
    static func momentoAvviso(scadenza: Date, adesso: Date, calendario: Calendar = .current) -> Date? {
        guard scadenza > adesso else { return nil }
        guard let giorno = calendario.date(byAdding: .day, value: -giorniPrima, to: scadenza),
              let alle9 = calendario.date(bySettingHour: oraAvviso, minute: 0, second: 0, of: giorno) else { return nil }
        return alle9 > adesso ? alle9 : adesso.addingTimeInterval(60)
    }

    // Da chiamare quando l'app è attiva e le notifiche sono consentite: sostituisce l'avviso precedente
    static func programma(adesso: Date = Date(), calendario: Calendar = .current, scadenza: Date? = scadenzaProfilo()) async {
        Notifiche.cancella([idAvviso])
        guard let scadenza, let quando = momentoAvviso(scadenza: scadenza, adesso: adesso, calendario: calendario) else { return }
        let c = calendario.dateComponents([.year, .month, .day, .hour, .minute, .second], from: quando)
        await Notifiche.una(id: idAvviso,
                            titolo: String(localized: "inForma sta per scadere"),
                            testo: String(localized: "Collega l'iPhone al Mac e rinnova l'app: i dati restano."),
                            quando: c)
    }
}
