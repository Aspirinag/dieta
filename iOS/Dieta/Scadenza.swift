import Foundation
import UserNotifications

// Con l'Apple ID gratuito l'app smette di aprirsi dopo 7 giorni: la data vera è nel profilo di firma
// dentro l'app. Avvisa con una notifica due giorni e un giorno prima, e con un messaggio all'apertura.
// Nel simulatore e su App Store il profilo non c'è e non succede niente
enum Scadenza {
    private static let nomeApp = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "L'app"
    private static let identificativi = ["scadenza-2", "scadenza-1"]

    // Data di scadenza di questa installazione. Per provarla nel simulatore: -scadenza 1 (giorni che mancano)
    static var data: Date? {
        if let giorni = Avvio.valore("-scadenza").flatMap(Double.init) {
            return Date().addingTimeInterval(giorni * 86_400)
        }
        return Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision")
            .flatMap { try? Data(contentsOf: $0) }
            .flatMap(leggi)
    }

    // Il profilo è un plist XML racchiuso nella firma binaria
    static func leggi(_ profilo: Data) -> Date? {
        guard let inizio = profilo.range(of: Data("<?xml".utf8)),
              let fine = profilo.range(of: Data("</plist>".utf8)), inizio.lowerBound < fine.upperBound else { return nil }
        let plist = try? PropertyListSerialization.propertyList(from: profilo[inizio.lowerBound..<fine.upperBound], format: nil)
        return (plist as? [String: Any])?["ExpirationDate"] as? Date
    }

    // Due giorni e un giorno prima, alle 10: un'ora comoda anche se l'app scade di notte
    static func avvisi(_ scadenza: Date, adesso: Date) -> [Date] {
        let c = Giorni.calendario
        return [2, 1]
            .compactMap { c.date(byAdding: .day, value: -$0, to: scadenza) }
            .compactMap { c.date(bySettingHour: 10, minute: 0, second: 0, of: $0) }
            .filter { $0 > adesso }
    }

    // Testo da mostrare all'apertura, da due giorni prima
    static func messaggio(_ scadenza: Date, adesso: Date) -> String? {
        let c = Giorni.calendario
        let giorni = c.dateComponents([.day], from: c.startOfDay(for: adesso), to: c.startOfDay(for: scadenza)).day ?? 0
        guard (0...2).contains(giorni) else { return nil }
        let quando = ["oggi", "domani", "dopodomani"][giorni]
        let ora = scadenza.formatted(Date.FormatStyle(time: .shortened).locale(Locale(identifier: "it_IT")))
        return "\(nomeApp) smette di aprirsi \(quando) alle \(ora). Rinnovala da SideStore o rilanciando il comando di installazione: i dati restano."
    }

    static func avvisoApertura() -> String? {
        data.flatMap { messaggio($0, adesso: Date()) }
    }

    static func programma() async {
        guard let scadenza = data else { return }
        let centro = UNUserNotificationCenter.current()
        centro.removePendingNotificationRequests(withIdentifiers: identificativi)
        guard await Notifiche.permesso() else { return }
        for (id, quando) in zip(identificativi, avvisi(scadenza, adesso: Date())) {
            let c = UNMutableNotificationContent()
            c.title = "\(nomeApp) sta per scadere"
            c.body = messaggio(scadenza, adesso: quando) ?? ""
            c.sound = .default
            let parti = Giorni.calendario.dateComponents([.year, .month, .day, .hour, .minute], from: quando)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parti, repeats: false)
            try? await centro.add(UNNotificationRequest(identifier: id, content: c, trigger: trigger))
        }
    }
}
