import SwiftUI
import FirebaseAuth

struct PremiumView: View {

    @ObservedObject var theme   = ThemeManager.shared
    @ObservedObject var premium = PremiumManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var planSelec    = "anual"
    @State private var showContacto = false
    @State private var iniciandoPrueba = false
    @State private var pruebaError     = ""
    @State private var showPruebaOk    = false

    let beneficios: [(String, String, String)] = [
        ("infinity",               "Movimientos ilimitados",      "Sin límite de registros mensuales"),
        ("tag.fill",               "Categorías ilimitadas",       "Crea todas las que necesites"),
        ("chart.bar.fill",         "Gráficas avanzadas",          "Análisis completo de tus finanzas"),
        ("gauge.with.needle.fill", "Presupuestos completos",       "General, por categoría y subcategoría"),
        ("arrow.up.doc.fill",      "Exportar datos",              "Descarga tus movimientos en Excel o PDF"),
        ("clock.fill",             "Historial ilimitado",         "Accede a todos tus registros"),
        ("pencil.circle.fill",     "Editar movimientos",          "Corrige errores en tus registros"),
        ("bell.badge.fill",        "Notificaciones inteligentes", "Alertas cuando superas tu presupuesto"),
        ("headphones.circle.fill", "Soporte prioritario",         "Respuesta en menos de 24 horas")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fondoApp.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {

                        // Header
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

                        // Estado actual
                        if premium.esPremium {
                            premiumActivoCard
                        } else {
                            // Prueba gratuita
                            cardPrueba

                            // Beneficios
                            VStack(alignment: .leading, spacing: 10) {
                                Text("¿Qué incluye Premium?")
                                    .font(Font.headline.bold()).foregroundColor(.textoPrincipal)
                                ForEach(beneficios, id: \.0) { icono, titulo, desc in
                                    beneficioFila(icono, titulo, desc)
                                }
                            }
                            .padding().background(Color.cardApp).cornerRadius(18)
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.bordeApp, lineWidth: 1))

                            // Selector plan
                            selectorPlan

                            // Botón suscribirse
                            Button { showContacto = true } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "crown.fill").foregroundColor(Color(hex: "#FFD700"))
                                    Text(planSelec == "mensual"
                                         ? "Suscribirse — $2.99 USD/mes"
                                         : "Suscribirse — $19.99 USD/año")
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity).padding()
                                .background(LinearGradient(
                                    colors: [Color(hex: "#FF9800"), Color(hex: "#FF6F00")],
                                    startPoint: .leading, endPoint: .trailing))
                                .foregroundColor(.white).cornerRadius(14)
                            }
                            .buttonStyle(PlainButtonStyle())

                            if planSelec == "anual" {
                                HStack {
                                    Image(systemName: "tag.fill").foregroundColor(Color(hex: "#4CAF50"))
                                    Text("Ahorras $15.89 USD vs plan mensual (44% descuento)")
                                        .font(Font.caption.bold()).foregroundColor(Color(hex: "#4CAF50"))
                                }
                                .padding(10).background(Color(hex: "#1B4332")).cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(hex: "#4CAF50").opacity(0.4), lineWidth: 1))
                            }

                            // Garantía
                            HStack(spacing: 10) {
                                Image(systemName: "shield.checkered").foregroundColor(.acentoApp)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Sin compromisos").font(Font.caption.bold())
                                        .foregroundColor(.textoPrincipal)
                                    Text("Cancela cuando quieras. Tus datos siempre seguros.")
                                        .font(Font.caption2).foregroundColor(.textoSecundario)
                                }
                            }
                            .padding(12).background(Color.cardApp).cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bordeApp, lineWidth: 1))
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
        .sheet(isPresented: $showContacto) {
            ContactoPagoView(plan: planSelec)
        }
        .alert("¡Prueba iniciada! 🎉", isPresented: $showPruebaOk) {
            Button("¡Genial!", role: .cancel) {}
        } message: {
            Text("Tienes 7 días de acceso completo a Premium. Disfrútalo sin compromisos.")
        }
    }

    // MARK: - Card prueba gratuita
    var cardPrueba: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "gift.fill").foregroundColor(Color(hex: "#FFD700"))
                        Text("7 días gratis")
                            .font(Font.title3.bold()).foregroundColor(.textoPrincipal)
                    }
                    Text("Prueba Premium completo sin costo ni compromiso")
                        .font(Font.caption).foregroundColor(.textoSecundario)
                }
                Spacer()
                Text("🎁").font(Font.system(size: 36))
            }

            if !pruebaError.isEmpty {
                Text(pruebaError).font(Font.caption).foregroundColor(Color(hex: "#FF5252"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                iniciarPrueba()
            } label: {
                HStack {
                    if iniciandoPrueba { ProgressView().tint(.white) }
                    else {
                        Image(systemName: "play.circle.fill")
                        Text("Iniciar prueba gratuita").fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity).padding()
                .background(LinearGradient(
                    colors: [Color(hex: "#4CAF50"), Color(hex: "#2E7D32")],
                    startPoint: .leading, endPoint: .trailing))
                .foregroundColor(.white).cornerRadius(14)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(iniciandoPrueba)

            Text("Sin tarjeta de crédito. Sin cobros automáticos.")
                .font(Font.caption2).foregroundColor(.textoSecundario)
        }
        .padding()
        .background(LinearGradient(
            colors: [Color(hex: "#0D2A1A"), Color(hex: "#1A3A1A")],
            startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18)
            .stroke(Color(hex: "#4CAF50").opacity(0.5), lineWidth: 1.5))
    }

    // MARK: - Card premium activo
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
                         ? "Disfruta todas las funciones gratis"
                         : "Tu suscripción está activa")
                        .font(Font.subheadline).foregroundColor(.textoSecundario)
                }
                Spacer()
                Text(premium.enPrueba ? "🎁" : "👑").font(Font.system(size: 44))
            }

            Divider().background(Color.bordeApp)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(premium.enPrueba ? "Prueba termina el" : "Expira el")
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

            if premium.enPrueba {
                Button { showContacto = true } label: {
                    Text("Suscribirme para continuar después de la prueba")
                        .font(Font.caption.bold()).foregroundColor(Color(hex: "#FFD700"))
                        .frame(maxWidth: .infinity).padding(10)
                        .background(Color(hex: "#1A1200")).cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "#FF9800").opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Button { showContacto = true } label: {
                    Text("Renovar suscripción")
                        .font(Font.caption.bold()).foregroundColor(Color(hex: "#FF9800"))
                        .frame(maxWidth: .infinity).padding(10)
                        .background(Color(hex: "#1A1200")).cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "#FF9800").opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(LinearGradient(
            colors: [Color(hex: "#1A1200"), Color(hex: "#2A1A00")],
            startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18)
            .stroke(Color(hex: "#FFD700").opacity(0.5), lineWidth: 2))
    }

    // MARK: - Selector plan
    var selectorPlan: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Elige tu plan").font(Font.headline.bold()).foregroundColor(.textoPrincipal)
            HStack(spacing: 12) {
                planCard("Mensual", "$2.99 USD", "por mes", nil, planSelec == "mensual") {
                    planSelec = "mensual"
                }
                planCard("Anual", "$19.99 USD", "por año · $1.67/mes", "AHORRA 44%",
                         planSelec == "anual") {
                    planSelec = "anual"
                }
            }
        }
        .padding().background(Color.cardApp).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.bordeApp, lineWidth: 1))
    }

    func planCard(_ titulo: String, _ precio: String, _ detalle: String,
                  _ tag: String?, _ selec: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
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
                                 startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(selec ? Color.clear : Color.bordeApp, lineWidth: 1.5))
        }
        .buttonStyle(PlainButtonStyle())
    }

    func beneficioFila(_ icono: String, _ titulo: String, _ desc: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icono).foregroundColor(Color(hex: "#FFD700")).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(titulo).font(Font.subheadline.bold()).foregroundColor(.textoPrincipal)
                Text(desc).font(Font.caption2).foregroundColor(.textoSecundario)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "#4CAF50"))
        }
    }

    var preguntasFrecuentes: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preguntas frecuentes")
                .font(Font.headline.bold()).foregroundColor(.textoPrincipal)
            faqItem("¿Cómo funciona la prueba de 7 días?",
                    "Al tocar \"Iniciar prueba gratuita\" activas inmediatamente el acceso completo por 7 días. No necesitas tarjeta de crédito.")
            faqItem("¿Qué pasa después de los 7 días?",
                    "La app vuelve al plan gratuito. Tus datos se conservan siempre. Solo pierdes las funciones Premium hasta que te suscribas.")
            faqItem("¿Cómo pago la suscripción?",
                    "Escríbenos por WhatsApp y te guiamos. Aceptamos transferencias y pagos digitales. Te activamos en menos de 1 hora.")
            faqItem("¿Funciona en Android también?",
                    "Sí. Una sola suscripción activa Premium en iOS y Android simultáneamente.")
            faqItem("¿Puedo cancelar?",
                    "Sí, en cualquier momento. Tus datos permanecen guardados siempre.")
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

    func iniciarPrueba() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        iniciandoPrueba = true
        PremiumManager.shared.iniciarPrueba(uid: uid) { ok in
            DispatchQueue.main.async {
                iniciandoPrueba = false
                if ok { showPruebaOk = true }
                else { pruebaError = "Ya usaste tu prueba gratuita anteriormente." }
            }
        }
    }
}

// MARK: - Contacto pago
struct ContactoPagoView: View {
    let plan: String
    @Environment(\.dismiss) var dismiss
    @ObservedObject var theme = ThemeManager.shared

    var mensajeWA: String {
        switch plan {
        case "mensual":  return "Hola, quiero suscribirme al plan mensual ($2.99 USD) de FinanzasQG Premium 👑"
        case "anual":    return "Hola, quiero suscribirme al plan anual ($19.99 USD) de FinanzasQG Premium 👑"
        case "renovar":  return "Hola, quiero renovar mi suscripción de FinanzasQG Premium 👑"
        default:         return "Hola, quiero información sobre FinanzasQG Premium 👑"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fondoApp.ignoresSafeArea()
                VStack(spacing: 24) {
                    Text("👑").font(Font.system(size: 60))
                    Text("¡Activa tu Premium!")
                        .font(Font.title2.bold()).foregroundColor(.textoPrincipal)
                    Text("Contáctanos y te activamos en menos de 1 hora.")
                        .font(Font.subheadline).foregroundColor(.textoSecundario)
                        .multilineTextAlignment(.center).padding(.horizontal)

                    VStack(spacing: 12) {
                        // Plan seleccionado
                        HStack(spacing: 10) {
                            Image(systemName: "lightbulb.fill").foregroundColor(Color(hex: "#FF9800"))
                            Text("Plan: \(plan == "mensual" ? "Mensual — $2.99 USD" : plan == "anual" ? "Anual — $19.99 USD" : "Renovación")")
                                .font(Font.caption2).foregroundColor(.textoSecundario)
                        }
                        .padding(10).background(Color(hex: "#1A1200")).cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "#FF9800").opacity(0.3), lineWidth: 1))

                        Button { abrirWhatsApp() } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "message.fill")
                                Text("Contactar por WhatsApp").fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity).padding()
                            .background(Color(hex: "#25D366"))
                            .foregroundColor(.white).cornerRadius(14)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Text("También puedes escribirnos:\nfinanzasqg@gmail.com")
                            .font(Font.caption).foregroundColor(.textoSecundario)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Activar Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }.foregroundColor(.acentoApp)
                }
            }
        }
        .preferredColorScheme(theme.temaOscuro ? .dark : .light)
    }

    func abrirWhatsApp() {
        let numero = "573246538855"
        if let enc = mensajeWA.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "https://wa.me/\(numero)?text=\(enc)") {
            UIApplication.shared.open(url)
        }
    }
}
