import SwiftUI
import Combine

class ThemeManager: ObservableObject {

    static let shared = ThemeManager()

    @AppStorage("temaOscuro") var temaOscuro = true {
        didSet { objectWillChange.send() }
    }

    private init() {}
}

// MARK: - Colores de la app (un solo lugar)
extension Color {

    // Fondo principal
    static var fondoApp: Color {
        ThemeManager.shared.temaOscuro
            ? Color(hex: "#0A1628")
            : Color(hex: "#E8F4FD")
    }

    // Card / contenedor
    static var cardApp: Color {
        ThemeManager.shared.temaOscuro
            ? Color(hex: "#111E2E")
            : Color(hex: "#FFFFFF")
    }

    // Borde
    static var bordeApp: Color {
        ThemeManager.shared.temaOscuro
            ? Color(hex: "#1E3A4A")
            : Color(hex: "#BDD7EE")
    }

    // Texto principal
    static var textoPrincipal: Color {
        ThemeManager.shared.temaOscuro
            ? Color.white
            : Color(hex: "#0D2137")
    }

    // Texto secundario / gris
    static var textoSecundario: Color {
        ThemeManager.shared.temaOscuro
            ? Color(hex: "#445566")
            : Color(hex: "#5A7A9A")
    }

    // Input background
    static var inputFondo: Color {
        ThemeManager.shared.temaOscuro
            ? Color(hex: "#0D1A2A")
            : Color(hex: "#F0F8FF")
    }

    // Verde (solo egresos/ingresos, igual en ambos temas)
    static let verdeFinanzas = Color(hex: "#4CAF50")

    // Rojo
    static let rojoFinanzas  = Color(hex: "#FF5252")

    // Acento principal según tema
    static var acentoApp: Color {
        ThemeManager.shared.temaOscuro
            ? Color(hex: "#4CAF50")   // verde oscuro
            : Color(hex: "#1565C0")   // azul claro
    }

    // Gradiente del botón principal
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
