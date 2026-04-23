import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// COP: $3.000  |  USD: 3USD
func formatValor(_ valor: Double, moneda: String) -> String {
    if moneda == "USD" {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        f.decimalSeparator = "."
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 0
        let num = f.string(from: NSNumber(value: valor)) ?? "\(Int(valor))"
        return "\(num)USD"
    } else {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        f.decimalSeparator = ","
        f.maximumFractionDigits = 0
        let num = f.string(from: NSNumber(value: valor)) ?? "\(Int(valor))"
        return "$\(num)"
    }
}

// Mantener compatibilidad con llamadas existentes (asume COP)
func formatCOP(_ valor: Double) -> String {
    formatValor(valor, moneda: "COP")
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
            .background(Color.cardApp)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(Color.bordeApp, lineWidth: 1))
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}
