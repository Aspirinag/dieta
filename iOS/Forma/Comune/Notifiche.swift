import UserNotifications

// Notifiche locali (promemoria della dieta, pagamento della palestra, fine recupero)
enum Notifiche {
    static func permesso() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func giornaliera(id: String, titolo: String, testo: String, ora: Int) async {
        await aggiungi(id: id, titolo: titolo, testo: testo,
                       trigger: UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: ora, minute: 0), repeats: true))
    }

    static func una(id: String, titolo: String, testo: String, quando: DateComponents) async {
        await aggiungi(id: id, titolo: titolo, testo: testo, trigger: UNCalendarNotificationTrigger(dateMatching: quando, repeats: false))
    }

    static func traSecondi(id: String, titolo: String, testo: String, secondi: Int) async {
        await aggiungi(id: id, titolo: titolo, testo: testo,
                       trigger: UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(max(secondi, 1)), repeats: false))
    }

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

// Mostra le notifiche anche con l'app aperta
final class DelegatoNotifiche: NSObject, UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
