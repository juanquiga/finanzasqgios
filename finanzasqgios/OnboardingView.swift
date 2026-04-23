import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct OnboardingView: View {

    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var loc   = LocalizationManager.shared
    @State private var page    = 0
    @State private var irSetup = false

    let paginas: [(String, String, String)] = [
        ("💰", "Bienvenido a FinanzasQG",
         "Tu app personal para controlar ingresos y gastos de forma fácil e inteligente."),
        ("📝", "Registra tus movimientos",
         "Agrega ingresos o egresos en segundos. Selecciona la categoría, subcategoría y valor."),
        ("📊", "Visualiza tus finanzas",
         "Gráficas de barras y donut para ver exactamente en qué gastas más cada mes."),
        ("📅", "Resumen inteligente",
         "Filtra por Diario, Mensual o Anual. Ve solo Ingresos o Egresos según necesites."),
        ("🎯", "Personaliza tu app",
         "Crea tus propias categorías, subcategorías y cuentas.")
    ]

    var body: some View {
        ZStack {
            Color.fondoApp.ignoresSafeArea()

            VStack(spacing: 0) {

                // TabView con swipe
                TabView(selection: $page) {
                    ForEach(0..<paginas.count, id: \.self) { i in
                        pantallaOnboarding(paginas[i])
                            .tag(i)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                // Indicador de página
                HStack(spacing: 8) {
                    ForEach(0..<paginas.count, id: \.self) { i in
                        Button {
                            withAnimation { page = i }
                        } label: {
                            Circle()
                                .fill(i == page ? Color.acentoApp : Color.bordeApp)
                                .frame(width: i == page ? 10 : 6,
                                       height: i == page ? 10 : 6)
                                .contentShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .animation(.easeInOut, value: page)
                    }
                }
                .padding(.bottom, 20)

                // Botones
                VStack(spacing: 12) {

                    // Botón Siguiente / Personalizar — TODO el área es tappable
                    Button {
                        withAnimation {
                            if page < paginas.count - 1 { page += 1 }
                            else { irSetup = true }
                        }
                    } label: {
                        Text(page < paginas.count - 1 ? "Siguiente →" : "¡PERSONALIZAR!")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gradienteBoton)
                            .cornerRadius(14)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)

                    if page < paginas.count - 1 {
                        Button {
                            irSetup = true
                        } label: {
                            Text("Saltar")
                                .foregroundColor(.textoSecundario)
                                .font(Font.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(theme.temaOscuro ? .dark : .light)
        .fullScreenCover(isPresented: $irSetup) { SetupCategoriasView() }
    }

    func pantallaOnboarding(_ data: (String, String, String)) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Text(data.0).font(Font.system(size: 80))
            Text(data.1)
                .font(Font.title2.bold()).foregroundColor(.acentoApp)
                .multilineTextAlignment(.center)
            Text(data.2)
                .foregroundColor(.textoPrincipal.opacity(0.8))
                .multilineTextAlignment(.center)
                .font(Font.body).padding(.horizontal, 20)
            Spacer()
        }
        .padding()
    }
}
