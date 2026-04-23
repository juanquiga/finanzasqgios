import SwiftUI

struct MainTabView: View {

    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var loc   = LocalizationManager.shared
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text(t("tab.resumen"))
                }
                .tag(0)

            RegistrarView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text(t("tab.registrar"))
                }
                .tag(1)

            GraficasView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text(t("tab.graficas"))
                }
                .tag(2)

            ConfigView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text(t("tab.config"))
                }
                .tag(3)
        }
        .accentColor(.acentoApp)
        .onAppear { ConfigManager.shared.cargar() }
        .preferredColorScheme(theme.temaOscuro ? .dark : .light)
        // ELIMINADO: .id(loc.idioma) — esto destruía el TabView al cambiar idioma
    }
}
