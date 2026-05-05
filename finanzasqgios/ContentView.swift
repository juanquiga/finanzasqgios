import SwiftUI
import FirebaseAuth
import LocalAuthentication

struct ContentView: View {

    @ObservedObject var theme = ThemeManager.shared
    @AppStorage("recordarSesion") var recordarSesion = false
    @AppStorage("usarFaceID")     var usarFaceID     = false

    @State private var autenticado = false
    @State private var cargando    = true

    var body: some View {
        Group {
            if cargando {
                ZStack {
                    Color.fondoApp.ignoresSafeArea()
                    VStack(spacing: 16) {
                        Text("💰").font(Font.system(size: 60))
                        Text("FinanzasQG")
                            .font(Font.title.bold()).foregroundColor(.acentoApp)
                        ProgressView().tint(.acentoApp)
                    }
                }
            } else if autenticado {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .preferredColorScheme(theme.temaOscuro ? .dark : .light)
        .onAppear { verificarSesion() }
    }

    func verificarSesion() {
        guard Auth.auth().currentUser != nil, recordarSesion else {
            if !recordarSesion {
                ConfigManager.shared.resetearSesion()
                PremiumManager.shared.resetear()
                try? Auth.auth().signOut()
            }
            cargando = false; return
        }

        let ctx     = LAContext()
        let soporta = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)

        if usarFaceID && soporta {
            ctx.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Accede a FinanzasQG"
            ) { success, _ in
                DispatchQueue.main.async {
                    cargando    = false
                    autenticado = success
                    if success {
                        ConfigManager.shared.cargar()
                        PremiumManager.shared.cargar()
                    } else {
                        ConfigManager.shared.resetearSesion()
                        PremiumManager.shared.resetear()
                        try? Auth.auth().signOut()
                    }
                }
            }
        } else {
            cargando    = false
            autenticado = true
            ConfigManager.shared.cargar()
            PremiumManager.shared.cargar()
        }
    }
}
