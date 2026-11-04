import SwiftUI
import UserNotifications

// Notifiche locali (promemoria della dieta, pagamento della palestra, fine recupero)
enum Notifiche {
    // Notifiche già consentite (senza chiedere)
    static func consentite() async -> Bool {
        let s = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        return s == .authorized || s == .provisional || s == .ephemeral
    }

    static func permesso() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    // Ogni giorno all'orario dato in minuti dalla mezzanotte
    static func giornaliera(id: String, titolo: String, testo: String, minuti: Int) async {
        await aggiungi(id: id, titolo: titolo, testo: testo,
                       trigger: UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: minuti / 60, minute: minuti % 60), repeats: true))
    }

    static func una(id: String, titolo: String, testo: String, quando: DateComponents) async {
        await aggiungi(id: id, titolo: titolo, testo: testo, trigger: UNCalendarNotificationTrigger(dateMatching: quando, repeats: false))
    }

    static func traSecondi(id: String, titolo: String, testo: String, secondi: Int) async {
        await aggiungi(id: id, titolo: titolo, testo: testo,
                       trigger: UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(max(secondi, 1)), repeats: false))
    }

    // Subito, con l'allenamento da completare (toccandola si sceglie la scheda)
    static func sessioneWatch(id: UUID, titolo: String, testo: String) async {
        let c = UNMutableNotificationContent()
        c.title = titolo
        c.body = testo
        c.sound = .default
        c.userInfo = ["compila": id.uuidString]
        try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "watch-\(id.uuidString)", content: c, trigger: nil))
    }

    // I promemoria che si ripetono restano nella lingua in cui sono stati programmati:
    // se la lingua preferita è cambiata, vanno programmati di nuovo
    private static let chiaveLingua = "linguaPromemoria"

    static var linguaAttuale: String { Locale.preferredLanguages.first ?? "" }

    static func serveRiprogrammare(salvata: String?, attuale: String) -> Bool { salvata != attuale }

    static func riprogrammazioneNecessaria() -> Bool {
        serveRiprogrammare(salvata: UserDefaults.standard.string(forKey: chiaveLingua), attuale: linguaAttuale)
    }

    static func registraLingua() { UserDefaults.standard.set(linguaAttuale, forKey: chiaveLingua) }

    static func cancella(_ ids: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    private static func aggiungi(id: String, titolo: String, testo: String, trigger: UNNotificationTrigger) async {
        let c = UNMutableNotificationContent()
        c.title = titolo
        c.body = testo
        c.sound = .default
        try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: c, trigger: trigger))
    }
}

// Mostra le notifiche anche con l'app aperta; toccando quella del Watch si aggiungono esercizi e pesi
final class DelegatoNotifiche: NSObject, UNUserNotificationCenterDelegate {
    var navigazione: Navigazione?

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // Fine recupero con l'app aperta: c'è già la vibrazione
        notification.request.identifier == "recupero" ? [] : [.banner, .sound]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard let testo = response.notification.request.content.userInfo["compila"] as? String,
              let id = UUID(uuidString: testo) else { return }
        await MainActor.run {
            navigazione?.scheda = .allenamento
            navigazione?.compila = id
        }
    }
}

// Scelta di un orario salvato in minuti dalla mezzanotte
struct SceltaOrario: View {
    let titolo: LocalizedStringKey
    let minuti: Int
    let cambia: (Int) -> Void

    var body: some View {
        DatePicker(titolo, selection: Binding(
            get: { Giorni.calendario.date(bySettingHour: minuti / 60, minute: minuti % 60, second: 0, of: Date()) ?? Date() },
            set: { d in
                let c = Giorni.calendario.dateComponents([.hour, .minute], from: d)
                cambia((c.hour ?? 0) * 60 + (c.minute ?? 0))
            }
        ), displayedComponents: .hourAndMinute)
    }
}
