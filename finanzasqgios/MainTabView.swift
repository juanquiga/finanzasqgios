import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Resumen")
                }
            RegistrarView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Registrar")
                }
            GraficasView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Gráficas")
                }
            ConfigView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Config")
                }
        }
        .accentColor(.verdeApp)
        .onAppear { ConfigManager.shared.cargar() }
    }
}
