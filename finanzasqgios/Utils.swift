import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255  // FIX: solo /255 una vez
        self.init(red: r, green: g, blue: b)
    }

    static let fondo     = Color(hex: "#0A1628")
    static let card      = Color(hex: "#111E2E")
    static let borde     = Color(hex: "#1E3A4A")
    static let verdeApp  = Color(hex: "#4CAF50")
    static let rojoApp   = Color(hex: "#FF5252")
    static let grisTexto = Color(hex: "#445566")
}

func formatCOP(_ valor: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.locale = Locale(identifier: "es_CO")
    f.maximumFractionDigits = 0
    return f.string(from: NSNumber(value: valor)) ?? "$\(Int(valor))"
}

func formatFecha(_ timestamp: Double) -> String {
    let date = Date(timeIntervalSince1970: timestamp / 1000)
    let f = DateFormatter()
    f.dateFormat = "dd/MM/yyyy  HH:mm"
    f.locale = Locale(identifier: "es_CO")
    return f.string(from: date)
}

struct BotonVerde: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(LinearGradient(
                colors: [Color(hex: "#2E7D32"), Color(hex: "#1B5E20")],
                startPoint: .top, endPoint: .bottom))
            .foregroundColor(.white)
            .cornerRadius(14)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.card)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(Color.borde, lineWidth: 1))
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}
