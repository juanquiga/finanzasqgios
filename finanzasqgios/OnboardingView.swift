import SwiftUI

struct OnboardingView: View {

    @ObservedObject var theme = ThemeManager.shared
    @State private var paginaActual = 0
    @State private var irSetup      = false
    @State private var irApp        = false

    let paginas: [PaginaOnboarding] = [
        PaginaOnboarding(
            emoji: "💰",
            titulo: "Bienvenido a FinanzasQG",
            subtitulo: "Tu asistente financiero personal",
            descripcion: "Controla tus finanzas de forma inteligente. Registra ingresos, egresos y transferencias en segundos. Todo sincronizado entre iOS y Android en tiempo real.",
            color: "#4CAF50",
            bullets: [
                "✅ Sincronización en tiempo real",
                "✅ Disponible en iOS y Android",
                "✅ Datos 100% privados y seguros",
                "✅ Sin anuncios, sin costos ocultos"
            ]
        ),
        PaginaOnboarding(
            emoji: "📊",
            titulo: "Visualiza tu dinero",
            subtitulo: "Gráficas y reportes inteligentes",
            descripcion: "Entiende en dónde gastas tu dinero con gráficas claras. Compara ingresos vs egresos, analiza por categoría y lleva un historial completo de todos tus movimientos.",
            color: "#2196F3",
            bullets: [
                "📈 Gráfica de barras por categoría",
                "🍩 Donut de ingresos vs egresos",
                "🏦 Resumen por cuenta bancaria",
                "📋 Historial filtrable por mes y año"
            ]
        ),
        PaginaOnboarding(
            emoji: "🎯",
            titulo: "Presupuestos inteligentes",
            subtitulo: "Ponle límite a tus gastos",
            descripcion: "Define un presupuesto general mensual y también por categoría. Recibe alertas visuales cuando estés cerca del límite. Los presupuestos se suman automáticamente.",
            color: "#FF9800",
            bullets: [
                "💳 Presupuesto general COP y USD",
                "🗂️ Presupuesto por categoría",
                "📂 Por subcategoría y subsubcategoría",
                "🚨 Alerta visual al superar el límite"
            ]
        ),
        PaginaOnboarding(
            emoji: "🔄",
            titulo: "Registra cualquier movimiento",
            subtitulo: "Egresos, ingresos y transferencias",
            descripcion: "Registra tus gastos e ingresos en segundos. Elige la fecha exacta del movimiento con el calendario integrado. Organiza todo por categorías que tú mismo defines.",
            color: "#9C27B0",
            bullets: [
                "📉 Egresos con categoría jerárquica",
                "📈 Ingresos por fuente de dinero",
                "🔄 Transferencias entre cuentas",
                "📅 Elige la fecha de cada movimiento"
            ]
        ),
        PaginaOnboarding(
            emoji: "🔒",
            titulo: "Tu información es tuya",
            subtitulo: "Privacidad y seguridad total",
            descripcion: "Cada cuenta es completamente independiente. Tus categorías, cuentas y presupuestos son exclusivamente tuyos. Protege el acceso con Face ID y nunca compartas datos con otros usuarios.",
            color: "#F44336",
            bullets: [
                "🔐 Face ID para mayor seguridad",
                "👤 Datos aislados por usuario",
                "☁️ Respaldo automático en la nube",
                "🚫 Sin acceso de terceros a tus datos"
            ]
        ),
        PaginaOnboarding(
            emoji: "⚙️",
            titulo: "Personaliza tu experiencia",
            subtitulo: "Todo a tu manera",
            descripcion: "Crea tus propias categorías de egresos e ingresos con subcategorías y subsubcategorías. Agrega tus cuentas bancarias. Luego configura tus presupuestos para tener control total.",
            color: "#00BCD4",
            bullets: [
                "🗂️ Categorías completamente personalizables",
                "🏦 Agrega todas tus cuentas bancarias",
                "💰 Presupuestos por nivel jerárquico",
                "🌐 Español e Inglés disponibles"
            ]
        )
    ]

    var body: some View {
        ZStack {
            Color.fondoApp.ignoresSafeArea()

            VStack(spacing: 0) {

                // Indicadores de página
                HStack(spacing: 6) {
                    ForEach(0..<paginas.count, id: \.self) { i in
                        Capsule()
                            .fill(i == paginaActual
                                  ? Color(hex: paginas[paginaActual].color)
                                  : Color.bordeApp)
                            .frame(width: i == paginaActual ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.4), value: paginaActual)
                            .onTapGesture { withAnimation { paginaActual = i } }
                    }
                }
                .padding(.top, 20).padding(.bottom, 8)

                // Número de página
                Text("\(paginaActual + 1) / \(paginas.count)")
                    .font(Font.caption2).foregroundColor(.textoSecundario)
                    .padding(.bottom, 12)

                // TabView de páginas
                TabView(selection: $paginaActual) {
                    ForEach(Array(paginas.enumerated()), id: \.offset) { i, pagina in
                        ScrollView(showsIndicators: false) {
                            vistaPagina(pagina)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 20)
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: paginaActual)

                // Botones
                VStack(spacing: 10) {
                    if paginaActual < paginas.count - 1 {
                        // Siguiente
                        Button {
                            withAnimation(.spring(response: 0.4)) {
                                paginaActual += 1
                            }
                        } label: {
                            HStack {
                                Text("Siguiente")
                                    .fontWeight(.bold)
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity).padding()
                            .background(LinearGradient(
                                colors: [Color(hex: paginas[paginaActual].color),
                                         Color(hex: paginas[paginaActual].color).opacity(0.7)],
                                startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white).cornerRadius(14)
                        }

                        // Saltar
                        Button {
                            withAnimation { irSetup = true }
                        } label: {
                            Text("Saltar tutorial")
                                .font(Font.caption).foregroundColor(.textoSecundario)
                        }
                    } else {
                        // Última página → Personalizar
                        Button {
                            withAnimation { irSetup = true }
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("¡Personalizar mi app!")
                                    .fontWeight(.bold)
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity).padding()
                            .background(LinearGradient(
                                colors: [Color(hex: "#4CAF50"), Color(hex: "#2E7D32")],
                                startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white).cornerRadius(14)
                        }
                    }
                }
                .padding(.horizontal, 24).padding(.bottom, 30)
            }
        }
        .preferredColorScheme(theme.temaOscuro ? .dark : .light)
        .fullScreenCover(isPresented: $irSetup) {
            SetupCompletoView()
        }
    }

    func vistaPagina(_ p: PaginaOnboarding) -> some View {
        VStack(spacing: 24) {

            // Emoji grande
            ZStack {
                Circle()
                    .fill(Color(hex: p.color).opacity(0.15))
                    .frame(width: 130, height: 130)
                Circle()
                    .stroke(Color(hex: p.color).opacity(0.3), lineWidth: 2)
                    .frame(width: 130, height: 130)
                Text(p.emoji)
                    .font(Font.system(size: 64))
            }
            .padding(.top, 16)

            // Título
            VStack(spacing: 8) {
                Text(p.titulo)
                    .font(Font.title2.bold())
                    .foregroundColor(Color(hex: p.color))
                    .multilineTextAlignment(.center)

                Text(p.subtitulo)
                    .font(Font.subheadline)
                    .foregroundColor(.textoSecundario)
                    .multilineTextAlignment(.center)
            }

            // Descripción
            Text(p.descripcion)
                .font(Font.body)
                .foregroundColor(.textoPrincipal)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 8)

            // Bullets
            VStack(alignment: .leading, spacing: 10) {
                ForEach(p.bullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 10) {
                        Text(bullet)
                            .font(Font.subheadline)
                            .foregroundColor(.textoPrincipal)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
            .background(Color(hex: p.color).opacity(0.08))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: p.color).opacity(0.2), lineWidth: 1))
        }
    }
}

struct PaginaOnboarding {
    let emoji     : String
    let titulo    : String
    let subtitulo : String
    let descripcion: String
    let color     : String
    let bullets   : [String]
}
