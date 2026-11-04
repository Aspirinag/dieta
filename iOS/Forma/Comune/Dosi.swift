import Foundation

// Una goccia vale un quarto di litro: 2 litri sono 8 gocce
enum Dosi {
    static let litriPerGoccia = 0.25

    static func gocce(dose litri: Double) -> Int {
        max(1, Int((litri / litriPerGoccia).rounded(.up)))
    }
}
