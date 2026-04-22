import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct OnboardingView: View {

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
         "Crea tus propias categorías, subcategorías y cuentas. ¡Ahora vamos a configurarlas!")
    ]

    var body: some View {
        ZStack {
            Color.fondo.ignoresSafeArea()

            VStack(spacing: 0) {

                TabView(selection: $page) {
                    ForEach(0..<paginas.count, id: \.self) { i in
                        pantallaOnboarding(paginas[i], index: i)
                            .tag(i)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                // Indicador de página
                HStack(spacing: 8) {
                    ForEach(0..<paginas.count, id: \.self) { i in
                        Circle()
                            .fill(i == page ? Color.verdeApp : Color.borde)
                            .frame(width: i == page ? 10 : 6,
                                   height: i == page ? 10 : 6)
                            .animation(.easeInOut, value: page)
                    }
                }
                .padding(.bottom, 20)

                // Botones
                VStack(spacing: 12) {
                    Button(page < paginas.count - 1 ? "Siguiente →" : "¡PERSONALIZAR!") {
                        withAnimation {
                            if page < paginas.count - 1 { page += 1 }
                            else { irSetup = true }
                        }
                    }
                    .buttonStyle(BotonVerde())
                    .padding(.horizontal)

                    if page < paginas.count - 1 {
                        Button("Saltar") { irSetup = true }
                            .foregroundColor(.grisTexto)
                            .font(.subheadline)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $irSetup) {
            SetupCategoriasView()
        }
    }

    func pantallaOnboarding(_ data: (String, String, String),
                             index: Int) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Text(data.0).font(.system(size: 80))
            Text(data.1)
                .font(.title2.bold()).foregroundColor(.verdeApp)
                .multilineTextAlignment(.center)
            Text(data.2)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .font(.body)
                .padding(.horizontal, 20)
            Spacer()
        }
        .padding()
    }
}
