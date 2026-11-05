import SwiftUI

// Condiviso tra app e Live Activity: i colori del sistema visivo e il font dei numeri, scritti una volta sola
// SISTEMA VISIVO — colori. Ogni colore ha un solo significato; nessuna schermata scrive colori a mano.
//
// Colori.accento     verde #2F6B4F (scuro #7FB89A): SOLO pulsante principale pieno e stato «fatto»
//                    (spunta, serie fatta). Mai nomi, link, titoli, icone di riga, «Precedente», variazioni di peso.
// Colori.sulAccento  testo e segni sopra l'accento
// Colori.sfondoFatto sfondo di una riga fatta (serie dell'allenamento): accento al 25 % in chiaro, 35 % in scuro
// Colori.olio        giallo olio: SOLO cucchiaini pieni
// Colori.acqua       blu acqua: SOLO gocce piene
// Colori.oltre       arancione: SOLO oltre la dose, sempre insieme a un «+N» scritto
// Colori.vuoto       contorno degli elementi vuoti (cerchi, cucchiaini, gocce), spessore Misure.contorno;
// Colori.riempimentoVuoto  riempimento leggero sotto quel contorno
//   Tutti hanno varianti chiaro, scuro e Aumenta contrasto; contrasti controllati in SistemaVisivoTests.
// Testi solo .primary/.secondary/.tertiary; sfondi solo quelli raggruppati di sistema (sfondoTema, righeTema).
// Variazioni del corpo (peso, grasso, vita): .secondary con il segno (Testi.conSegno), mai verde o rosso.
//
// Modificatori: .applicaTema() (radice e fogli a schermo intero), .sfondoTema() (dietro List/Form/ScrollView),
// .righeTema() (sulle righe di una List). Pulsante pieno: `Button("Inizia") { … }.buttonStyle(PulsanteAccento())`,
// al massimo uno per schermata.
enum Colori {
    static let accento = Color(chiaro: 0x2F6B4F, scuro: 0x7FB89A, chiaroContrasto: 0x245A40, scuroContrasto: 0x9FD0B5)
    // Il bianco sul verde chiaro dello scuro si legge male: lì il segno è verde scurissimo
    static let sulAccento = Color(chiaro: 0xFFFFFF, scuro: 0x0F2218)
    static let sfondoFatto = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(esa: t.accessibilityContrast == .high ? 0x9FD0B5 : 0x7FB89A).withAlphaComponent(0.35)
            : UIColor(esa: t.accessibilityContrast == .high ? 0x245A40 : 0x2F6B4F).withAlphaComponent(0.25)
    })
    // Giallo più scuro in chiaro per arrivare a 3:1 sul bianco (#D6A21E era 2,3:1)
    static let olio = Color(chiaro: 0xB07F0C, scuro: 0xD6A21E, chiaroContrasto: 0x8C6508, scuroContrasto: 0xE8BC4A)
    // In scuro un po' più chiaro, per restare sopra 3:1 anche sul grigio dei fogli
    static let acqua = Color(chiaro: 0x3D7FA6, scuro: 0x5A9CC4, chiaroContrasto: 0x2C6688, scuroContrasto: 0x7DB4D6)
    // L'arancione di sistema è 2,2:1 sul bianco: in chiaro uno più scuro
    static let oltre = Color(chiaro: 0xC4610A, scuro: 0xFF9F0A, chiaroContrasto: 0xA34F06, scuroContrasto: 0xFFB340)
    // Grigio secondario di sistema (≈ 3,4:1 sul bianco, ≈ 5,9:1 sul grigio scuro; più scuro con Aumenta contrasto)
    static let vuoto = Color(.secondaryLabel)
    static let riempimentoVuoto = Color(.quaternarySystemFill)
}

extension Color {
    init(esa: UInt32) {
        self.init(red: Double((esa >> 16) & 0xFF) / 255, green: Double((esa >> 8) & 0xFF) / 255, blue: Double(esa & 0xFF) / 255)
    }

    // Colore che segue chiaro/scuro e, se dati, Aumenta contrasto
    init(chiaro: UInt32, scuro: UInt32, chiaroContrasto: UInt32? = nil, scuroContrasto: UInt32? = nil) {
        self.init(UIColor { t in
            let alto = t.accessibilityContrast == .high
            if t.userInterfaceStyle == .dark { return UIColor(esa: alto ? (scuroContrasto ?? scuro) : scuro) }
            return UIColor(esa: alto ? (chiaroContrasto ?? chiaro) : chiaro)
        })
    }
}

extension UIColor {
    convenience init(esa: UInt32) {
        self.init(red: CGFloat((esa >> 16) & 0xFF) / 255, green: CGFloat((esa >> 8) & 0xFF) / 255, blue: CGFloat(esa & 0xFF) / 255, alpha: 1)
    }
}

extension Font {
    // Numero importante: arrotondato, semibold, cifre a larghezza fissa, sullo stile di sistema (Dynamic Type)
    static func numero(_ stile: Font.TextStyle = .body) -> Font {
        .system(stile, design: .rounded, weight: .semibold).monospacedDigit()
    }
}

