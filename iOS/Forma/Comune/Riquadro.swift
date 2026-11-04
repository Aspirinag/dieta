import SwiftUI

// Riquadro bianco arrotondato (in scuro, il grigio rialzato di sistema)
struct Riquadro<Contenuto: View>: View {
    @ViewBuilder let contenuto: Contenuto

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { contenuto }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16, style: .continuous))
    }
}
