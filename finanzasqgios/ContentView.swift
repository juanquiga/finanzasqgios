import SwiftUI
import FirebaseAuth
import LocalAuthentication

struct ContentView: View {

    @AppStorage("recordarSesion") var recordarSesion = false
    @AppStorage("usarFaceID")     var usarFaceID     = false
    @AppStorage("saved_email")    var savedEmail      = ""
    @AppStorage("saved_pass")     var savedPass       = ""

    @State private var autenticado = false
    @State private var cargando    = true

    var body: some View {
        Group {
            if cargando {
                ZStack {
                    Color.fondo.ignoresSafeArea()
                    VStack(spacing: 16) {
                        Text("💰").font(.system(size: 60))
                        Text("FinanzasQG")
                            .font(.title.bold()).foregroundColor(.verdeApp)
                        ProgressView().tint(.verdeApp)
                    }
                }
            } else if autenticado {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .onAppear { verificarSesion() }
    }

    func verificarSesion() {
        // Sin sesión guardada → login
        guard Auth.auth().currentUser != nil, recordarSesion else {
            if !recordarSesion { try? Auth.auth().signOut() }
            cargando = false; return
        }

        // Con sesión + FaceID activado
        if usarFaceID && !savedEmail.isEmpty {
            let ctx = LAContext()
            guard ctx.canEvaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics, error: nil) else {
                // Dispositivo no soporta → dejar pasar
                cargando = false; autenticado = true; return
            }
            ctx.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Accede a FinanzasQG") { success, _ in
                DispatchQueue.main.async {
                    cargando = false
                    autenticado = success
                }
            }
        } else {
            // Solo recordar, sin FaceID
            cargando = false; autenticado = true
        }
    }
}
