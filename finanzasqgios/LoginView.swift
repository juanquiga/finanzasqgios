import SwiftUI
import FirebaseAuth
import FirebaseDatabase
import LocalAuthentication

struct LoginView: View {

    @AppStorage("recordarSesion") var recordarSesion = false
    @AppStorage("usarFaceID")     var usarFaceID     = false
    @AppStorage("saved_email")    var savedEmail      = ""
    @AppStorage("saved_pass")     var savedPass       = ""

    @State private var emailInput  = ""
    @State private var passInput   = ""
    @State private var loading     = false
    @State private var showReset   = false
    @State private var resetEmail  = ""
    @State private var alerta      = ""
    @State private var showAlerta  = false
    @State private var irRegistro  = false

    let db = Database.database().reference()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {

                    // Header
                    VStack(spacing: 10) {
                        Text("💰").font(.system(size: 70))
                        Text("FinanzasQG")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.verdeApp)
                        Text("Controla tus finanzas con inteligencia")
                            .foregroundColor(.grisTexto).font(.subheadline)
                    }
                    .padding(.top, 50)

                    VStack(spacing: 16) {

                        campoTexto("Correo o usuario", texto: $emailInput,
                                   icono: "envelope.fill", secure: false)
                        campoTexto("Contraseña", texto: $passInput,
                                   icono: "lock.fill", secure: true)

                        // Recordar sesión
                        HStack {
                            Toggle(isOn: $recordarSesion) {
                                Text("Recordar sesión")
                                    .foregroundColor(.grisTexto).font(.caption)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .verdeApp))
                            Spacer()
                            Button("¿Olvidaste la contraseña?") { showReset = true }
                                .foregroundColor(.verdeApp).font(.caption)
                        }

                        // Botón ingresar
                        Button(action: login) {
                            HStack {
                                if loading { ProgressView().tint(.white) }
                                else {
                                    Text("INGRESAR").fontWeight(.bold)
                                        .tracking(1.5)
                                }
                            }
                            .frame(maxWidth: .infinity).padding()
                            .background(LinearGradient(
                                colors: [Color(hex: "#2E7D32"), Color(hex: "#1B5E20")],
                                startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white).cornerRadius(14)
                        }
                        .disabled(loading)

                        // FaceID — solo si hay sesión guardada y dispositivo lo soporta
                        if puedeUsarFaceID() {
                            Button(action: loginConFaceID) {
                                HStack {
                                    Image(systemName: "faceid")
                                        .font(.title3)
                                    Text("Entrar con Face ID")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity).padding()
                                .background(Color.card)
                                .foregroundColor(.verdeApp)
                                .cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.verdeApp.opacity(0.5), lineWidth: 1))
                            }
                        }

                        HStack {
                            Rectangle().frame(height: 1).foregroundColor(.borde)
                            Text("o").foregroundColor(.grisTexto).font(.caption)
                            Rectangle().frame(height: 1).foregroundColor(.borde)
                        }

                        Button { irRegistro = true } label: {
                            Text("Crear cuenta nueva")
                                .frame(maxWidth: .infinity).padding()
                                .background(Color.card)
                                .foregroundColor(.verdeApp).fontWeight(.semibold)
                                .cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.borde, lineWidth: 1))
                        }

                        Text("FinanzasQG © 2025")
                            .foregroundColor(Color.grisTexto.opacity(0.5))
                            .font(.caption2).padding(.top, 4)
                    }
                    .padding(24)
                    .background(Color.card).cornerRadius(24)
                    .overlay(RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.borde, lineWidth: 1))
                    .padding(.horizontal)
                }
            }
            .background(Color.fondo.ignoresSafeArea())
            .navigationDestination(isPresented: $irRegistro) { SignUpView() }
            .alert("Mensaje", isPresented: $showAlerta) {
                Button("OK", role: .cancel) {}
            } message: { Text(alerta) }
            .alert("Recuperar contraseña", isPresented: $showReset) {
                TextField("tu@email.com", text: $resetEmail)
                    .textInputAutocapitalization(.never)
                Button("Enviar") { enviarReset() }
                Button("Cancelar", role: .cancel) {}
            } message: { Text("Ingresa tu correo registrado") }
        }
    }

    func campoTexto(_ placeholder: String, texto: Binding<String>,
                    icono: String, secure: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icono).foregroundColor(.verdeApp).frame(width: 20)
            if secure {
                SecureField(placeholder, text: texto).foregroundColor(.white)
            } else {
                TextField(placeholder, text: texto)
                    .foregroundColor(.white)
                    .textInputAutocapitalization(.never)
            }
        }
        .padding()
        .background(Color(hex: "#0D1A2A")).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borde, lineWidth: 1))
    }

    // FaceID disponible SI el dispositivo lo tiene Y hay credenciales guardadas
    func puedeUsarFaceID() -> Bool {
        let ctx = LAContext()
        let soporta = ctx.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics, error: nil)
        return soporta && !savedEmail.isEmpty && !savedPass.isEmpty
    }

    func login() {
        let input = emailInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let pass  = passInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty, !pass.isEmpty else {
            alerta = "Completa todos los campos"; showAlerta = true; return
        }
        loading = true
        if input.contains("@") { loginConEmail(input, pass) }
        else { buscarPorNombre(input, pass) }
    }

    func buscarPorNombre(_ nombre: String, _ pass: String) {
        db.child("users").observeSingleEvent(of: .value) { snap in
            var found: String?
            for case let child as DataSnapshot in snap.children {
                let data = child.value as? [String: Any] ?? [:]
                let name = data["name"] as? String ?? ""
                let mail = data["email"] as? String ?? ""
                if name.lowercased() == nombre.lowercased() { found = mail; break }
            }
            if let email = found { loginConEmail(email, pass) }
            else {
                DispatchQueue.main.async {
                    loading = false
                    alerta = "Usuario no encontrado"; showAlerta = true
                }
            }
        }
    }

    func loginConEmail(_ correo: String, _ pass: String) {
        Auth.auth().signIn(withEmail: correo, password: pass) { result, error in
            DispatchQueue.main.async { loading = false }
            if error != nil {
                alerta = "Credenciales incorrectas"; showAlerta = true; return
            }
            // Guardar credenciales si "recordar" está activo
            if recordarSesion {
                savedEmail = correo
                savedPass  = pass
            } else {
                savedEmail = ""
                savedPass  = ""
            }
            ConfigManager.shared.cargar()
            irAApp(uid: result?.user.uid ?? "")
        }
    }

    // FaceID: escanea y si hay credenciales guardadas entra directo
    func loginConFaceID() {
        let context = LAContext()
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Accede a FinanzasQG con Face ID"
        ) { success, error in
            DispatchQueue.main.async {
                if success {
                    // Usar credenciales guardadas
                    guard !savedEmail.isEmpty, !savedPass.isEmpty else {
                        alerta = "No hay sesión guardada. Ingresa con tu contraseña primero."
                        showAlerta = true
                        return
                    }
                    loading = true
                    loginConEmail(savedEmail, savedPass)
                } else {
                    alerta = "Face ID no reconocido"
                    showAlerta = true
                }
            }
        }
    }

    func irAApp(uid: String) {
        db.child("users").child(uid).observeSingleEvent(of: .value) { snap in
            let data  = snap.value as? [String: Any]
            let isNew = data?["isNewUser"] as? Bool ?? false
            DispatchQueue.main.async {
                if let scene = UIApplication.shared.connectedScenes.first
                    as? UIWindowScene, let window = scene.windows.first {
                    window.rootViewController = UIHostingController(
                        rootView: isNew ? AnyView(OnboardingView()) : AnyView(MainTabView()))
                    window.makeKeyAndVisible()
                }
            }
        }
    }

    func enviarReset() {
        guard !resetEmail.isEmpty else { return }
        Auth.auth().sendPasswordReset(withEmail: resetEmail) { error in
            alerta = error == nil
                ? "✅ Correo enviado a \(resetEmail)"
                : "No se encontró ese correo"
            showAlerta = true
        }
    }
}
