import SwiftUI
import Combine

// ═══════════════════════════════════════
// MARK: - ThemeManager
// ═══════════════════════════════════════
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    @AppStorage("temaOscuro") var temaOscuro = true {
        didSet { objectWillChange.send() }
    }
    private init() {}
}

// ═══════════════════════════════════════
// MARK: - LocalizationManager
// ═══════════════════════════════════════
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    @Published var idioma: String {
        didSet {
            UserDefaults.standard.set(idioma, forKey: "idioma")
            objectWillChange.send()
        }
    }
    private init() {
        self.idioma = UserDefaults.standard.string(forKey: "idioma") ?? "es"
    }
    func t(_ key: String) -> String {
        guard let path = Bundle.main.path(forResource: idioma, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: "")
        }
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
}

// Función global
func t(_ key: String) -> String { LocalizationManager.shared.t(key) }

// ═══════════════════════════════════════
// MARK: - Color(hex:)
// ═══════════════════════════════════════
extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// ═══════════════════════════════════════
// MARK: - Colores del tema
// ═══════════════════════════════════════
extension Color {
    static var fondoApp: Color {
        ThemeManager.shared.temaOscuro
            ? Color(hex: "#0A1628") : Color(hex: "#E8F4FD")
    }
    static var cardApp: Color {
        ThemeManager.shared.temaOscuro
            ? Color(hex: "#111E2E") : Color(hex: "#FFFFFF")
    }
    static var bordeApp: Color {
        ThemeManager.shared.temaOscuro
            ? Color(hex: "#1E3A4A") : Color(hex: "#BDD7EE")
    }
    static var textoPrincipal: Color {
        ThemeManager.shared.temaOscuro
            ? Color.white : Color(hex: "#0D2137")
    }
    static var textoSecundario: Color {
        ThemeManager.shared.temaOscuro
            ? Color(hex: "#445566") : Color(hex: "#5A7A9A")
    }
    static var inputFondo: Color {
        ThemeManager.shared.temaOscuro
            ? Color(hex: "#0D1A2A") : Color(hex: "#F0F8FF")
    }
    static let verdeFinanzas = Color(hex: "#4CAF50")
    static let rojoFinanzas  = Color(hex: "#FF5252")
    static var acentoApp: Color {
        ThemeManager.shared.temaOscuro
            ? Color(hex: "#4CAF50") : Color(hex: "#1565C0")
    }
    static var gradienteBoton: LinearGradient {
        ThemeManager.shared.temaOscuro
            ? LinearGradient(
                colors: [Color(hex: "#2E7D32"), Color(hex: "#1B5E20")],
                startPoint: .leading, endPoint: .trailing)
            : LinearGradient(
                colors: [Color(hex: "#1565C0"), Color(hex: "#0D47A1")],
                startPoint: .leading, endPoint: .trailing)
    }
}

// ═══════════════════════════════════════
// MARK: - Formatters
// ═══════════════════════════════════════
func formatValor(_ valor: Double, moneda: String) -> String {
    if moneda == "USD" {
        let f = NumberFormatter()
        f.numberStyle       = .decimal
        f.groupingSeparator = ","
        f.decimalSeparator  = "."
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 0
        return "\(f.string(from: NSNumber(value: valor)) ?? "\(Int(valor))")USD"
    } else {
        let f = NumberFormatter()
        f.numberStyle       = .decimal
        f.groupingSeparator = "."
        f.decimalSeparator  = ","
        f.maximumFractionDigits = 0
        return "$\(f.string(from: NSNumber(value: valor)) ?? "\(Int(valor))")"
    }
}

func formatCOP(_ valor: Double) -> String { formatValor(valor, moneda: "COP") }

func formatFecha(_ timestamp: Double) -> String {
    let date = Date(timeIntervalSince1970: timestamp / 1000)
    let f = DateFormatter()
    f.dateFormat = "dd/MM/yyyy  HH:mm"
    f.locale = Locale(identifier: "es_CO")
    return f.string(from: date)
}

// ═══════════════════════════════════════
// MARK: - Estilos
// ═══════════════════════════════════════
struct BotonVerde: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity).padding()
            .background(LinearGradient(
                colors: [Color(hex: "#2E7D32"), Color(hex: "#1B5E20")],
                startPoint: .top, endPoint: .bottom))
            .foregroundColor(.white).cornerRadius(14)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.padding().background(Color.cardApp).cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(Color.bordeApp, lineWidth: 1))
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}
