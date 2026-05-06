import SwiftUI
import RevenueCat

struct PremiumView: View {

    @ObservedObject var theme   = ThemeManager.shared
    @ObservedObject var premium = PremiumManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var planSelec   = "anual"
    @State private var comprando   = false
    @State private var restaurando = false
    @State private var errorMsg    = ""
    @State private var showExito   = false

    let beneficios: [(String, String, String)] = [
        ("infinity",               "Movimientos ilimitados",   "Plan gratuito: solo 50/mes"),
        ("tag.fill",               "Categorías ilimitadas",    "Plan gratuito: solo 5"),
        ("list.bullet",            "Subcategorías ilimitadas", "Plan gratuito: solo 3 por categoría"),
        ("creditcard.fill",        "Cuentas ilimitadas",       "Plan gratuito: solo 3"),
        ("chart.bar.fill",         "Gráficas avanzadas",       "Análisis completo"),
        ("gauge.with.needle.fill", "Presupuestos completos",   "General + por categoría"),
        ("pencil.circle.fill",     "Editar movimientos",       "Corrige errores"),
        ("clock.fill",             "Historial ilimitado",      "Sin restricciones de fecha")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fondoApp.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        headerCard
                        if premium.esPremium {
                            premiumActivoCard
                        } else {
                            cardPrueba
                            beneficiosCard
                            selectorPlan
                            botonesCompra
                            botonRestaurar
                        }
                        preguntasFrecuentes
                    }
                    .padding()
                }
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }.foregroundColor(.acentoApp)
                }
            }
        }
        .preferredColorScheme(theme.temaOscuro ? .dark : .light)
        .alert("¡Premium activado! 🎉", isPresented: $showExito) {
            Button("¡Genial!") { dismiss() }
        } message: {
            Text("Ahora tienes acceso completo a FinanzasQG Premium.")
        }
        .onAppear { premium.cargarPaquetes() }
    }

    // MARK: - Header
    var headerCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(hex: "#FFD700"), Color(hex: "#FF9800")],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 100, height: 100)
                Text("👑").font(Font.system(size: 50))
            }
            Text("FinanzasQG Premium")
                .font(Font.title.bold()).foregroundColor(.textoPrincipal)
            Text("Toma el control total de tus finanzas")
                .font(Font.subheadline).foregroundColor(.textoSecundario)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Card prueba
    var cardPrueba: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "gift.fill").foregroundColor(Color(hex: "#FFD700"))
                        Text("7 días gratis").font(Font.title3.bold()).foregroundColor(.textoPrincipal)
                    }
                    Text("Prueba completa sin costo. Apple cobra el día 8.")
                        .font(Font.caption).foregroundColor(.textoSecundario)
                }
                Spacer()
                Text("🎁").font(Font.system(size: 34))
            }
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "#4CAF50"))
                Text("Sin cobros durante la prueba").font(Font.caption2).foregroundColor(Color(hex: "#4CAF50"))
                Spacer()
                Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "#4CAF50"))
                Text("Cancela antes del día 8 sin cargo").font(Font.caption2).foregroundColor(Color(hex: "#4CAF50"))
            }
        }
        .padding()
        .background(LinearGradient(
            colors: [Color(hex: "#0D2A1A"), Color(hex: "#1A3A1A")],
            startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18)
            .stroke(Color(hex: "#4CAF50").opacity(0.5), lineWidth: 1.5))
    }

    // MARK: - Beneficios
    var beneficiosCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("¿Qué incluye Premium?")
                .font(Font.headline.bold()).foregroundColor(.textoPrincipal)
            ForEach(beneficios, id: \.0) { icono, titulo, desc in
                HStack(spacing: 12) {
                    Image(systemName: icono)
                        .foregroundColor(Color(hex: "#FFD700")).frame(width: 22)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(titulo).font(Font.subheadline.bold()).foregroundColor(.textoPrincipal)
                        Text(desc).font(Font.caption2).foregroundColor(.textoSecundario)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "#4CAF50"))
                }
            }
        }
        .padding().background(Color.cardApp).cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.bordeApp, lineWidth: 1))
    }

    // MARK: - Selector plan
    var selectorPlan: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Elige tu plan").font(Font.headline.bold()).foregroundColor(.textoPrincipal)
            HStack(spacing: 12) {
                tarjetaPlan(
                    titulo: "Mensual",
                    precio: premium.precioMensual,
                    detalle: "por mes",
                    tag: nil,
                    selec: planSelec == "mensual"
                ) { planSelec = "mensual" }

                tarjetaPlan(
                    titulo: "Anual",
                    precio: premium.precioAnual,
                    detalle: "por año",
                    tag: "AHORRA 44%",
                    selec: planSelec == "anual"
                ) { planSelec = "anual" }
            }
        }
        .padding().background(Color.cardApp).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.bordeApp, lineWidth: 1))
    }

    func tarjetaPlan(titulo: String, precio: String, detalle: String,
                     tag: String?, selec: Bool, accion: @escaping () -> Void) -> some View {
        Button(action: accion) {
            VStack(spacing: 8) {
                if let tag {
                    Text(tag).font(Font.caption2.bold()).foregroundColor(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color(hex: "#4CAF50")).cornerRadius(6)
                }
                Text(titulo).font(Font.subheadline.bold())
                    .foregroundColor(selec ? .white : .textoPrincipal)
                Text(precio).font(Font.title3.bold())
                    .foregroundColor(selec ? .white : Color(hex: "#FF9800"))
                Text(detalle).font(Font.caption2)
                    .foregroundColor(selec ? .white.opacity(0.8) : .textoSecundario)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity).padding(14)
            .background(
                selec
                ? LinearGradient(colors: [Color(hex: "#FF9800"), Color(hex: "#FF6F00")],
                                 startPoint: .topLeading, endPoint: .bottomTrailing)
                : LinearGradient(colors: [Color.cardApp, Color.cardApp],
                                 startPoint: .leading, endPoint: .trailing))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(selec ? Color.clear : Color.bordeApp, lineWidth: 1.5))
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Botones compra
    var botonesCompra: some View {
        VStack(spacing: 10) {
            Button {
                comprar()
            } label: {
                HStack(spacing: 10) {
                    if comprando { ProgressView().tint(.white) }
                    else {
                        Image(systemName: "crown.fill").foregroundColor(Color(hex: "#FFD700"))
                        Text(planSelec == "mensual"
                             ? "Prueba gratis — luego \(premium.precioMensual)/mes"
                             : "Prueba gratis — luego \(premium.precioAnual)/año")
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity).padding()
                .background(LinearGradient(
                    colors: [Color(hex: "#FF9800"), Color(hex: "#FF6F00")],
                    startPoint: .leading, endPoint: .trailing))
                .foregroundColor(.white).cornerRadius(14)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(comprando || restaurando)

            if !errorMsg.isEmpty {
                Text(errorMsg).font(Font.caption).foregroundColor(Color(hex: "#FF5252"))
                    .multilineTextAlignment(.center)
            }

            Text("Pago seguro con Apple · Cancela en Ajustes del iPhone")
                .font(Font.caption2).foregroundColor(.textoSecundario)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Restaurar
    var botonRestaurar: some View {
        Button {
            restaurando = true; errorMsg = ""
            premium.restaurar { ok in
                restaurando = false
                if ok { showExito = true }
                else  { errorMsg = "No se encontraron compras anteriores" }
            }
        } label: {
            HStack {
                if restaurando {
                    ProgressView().tint(.acentoApp).scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.clockwise").foregroundColor(.acentoApp)
                    Text("Restaurar compras anteriores").foregroundColor(.acentoApp)
                }
            }
            .font(Font.caption)
            .frame(maxWidth: .infinity).padding(10)
            .background(Color.cardApp).cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.bordeApp, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(comprando || restaurando)
    }

    // MARK: - Premium activo
    var premiumActivoCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "crown.fill").foregroundColor(Color(hex: "#FFD700"))
                        Text(premium.enPrueba ? "Prueba activa 🎁" : "¡Eres Premium! 🎉")
                            .font(Font.title3.bold()).foregroundColor(.textoPrincipal)
                    }
                    Text(premium.enPrueba
                         ? "El día 8 se cobra automáticamente con Apple"
                         : "Renovación automática con Apple")
                        .font(Font.caption).foregroundColor(.textoSecundario)
                }
                Spacer()
                Text(premium.enPrueba ? "🎁" : "👑").font(Font.system(size: 44))
            }

            Divider().background(Color.bordeApp)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(premium.enPrueba ? "Prueba termina" : "Próximo cobro")
                        .font(Font.caption).foregroundColor(.textoSecundario)
                    Text(premium.labelExpiracion)
                        .font(Font.subheadline.bold()).foregroundColor(.textoPrincipal)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Días restantes").font(Font.caption).foregroundColor(.textoSecundario)
                    Text("\(premium.diasRestantes) días")
                        .font(Font.subheadline.bold()).foregroundColor(Color(hex: "#4CAF50"))
                }
            }

            Button {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Image(systemName: "gear")
                    Text("Gestionar en App Store")
                }
                .font(Font.caption.bold()).foregroundColor(.acentoApp)
                .frame(maxWidth: .infinity).padding(10)
                .background(Color.cardApp).cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.acentoApp.opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(LinearGradient(
            colors: [Color(hex: "#1A1200"), Color(hex: "#2A1A00")],
            startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18)
            .stroke(Color(hex: "#FFD700").opacity(0.5), lineWidth: 2))
    }

    // MARK: - FAQ
    var preguntasFrecuentes: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preguntas frecuentes")
                .font(Font.headline.bold()).foregroundColor(.textoPrincipal)
            faqItem("¿Cuándo me cobran?",
                    "Tienes 7 días gratis. El día 8 Apple cobra automáticamente.")
            faqItem("¿Cómo cancelo?",
                    "Ajustes del iPhone → Tu nombre → Suscripciones → FinanzasQG → Cancelar.")
            faqItem("¿Qué pasa si no pago?",
                    "Vuelves al plan gratuito. Tus datos se guardan siempre.")
            faqItem("¿Funciona en Android?",
                    "Sí, una suscripción activa ambas plataformas.")
        }
        .padding().background(Color.cardApp).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.bordeApp, lineWidth: 1))
    }

    func faqItem(_ p: String, _ r: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("❓ \(p)").font(Font.caption.bold()).foregroundColor(.textoPrincipal)
            Text(r).font(Font.caption2).foregroundColor(.textoSecundario).lineSpacing(3)
        }
        .padding(10).background(Color.inputFondo).cornerRadius(10)
    }

    // MARK: - Comprar
    func comprar() {
        let paquete = planSelec == "anual" ? premium.paqueteAnual : premium.paqueteMensual
        guard let paquete else {
            errorMsg = "No se pudieron cargar los planes. Intenta de nuevo."; return
        }
        comprando = true; errorMsg = ""
        premium.comprar(paquete: paquete) { ok, error in
            comprando = false
            if ok { showExito = true }
            else if !error.isEmpty { errorMsg = error }
        }
    }
}
