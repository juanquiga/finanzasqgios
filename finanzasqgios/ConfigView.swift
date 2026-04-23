import SwiftUI
import FirebaseAuth
import FirebaseDatabase
import LocalAuthentication

struct ConfigView: View {

    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var loc   = LocalizationManager.shared

    @AppStorage("recordarSesion") var recordarSesion = false
    @AppStorage("usarFaceID")     var usarFaceID     = false
    @AppStorage("saved_email")    var savedEmail      = ""
    @AppStorage("saved_pass")     var savedPass       = ""

    @State private var nombreActual      = ""
    @State private var showCambiarNombre = false
    @State private var nuevoNombre       = ""
    @State private var showCerrarSesion  = false
    @State private var showTerminos      = false
    @State private var showContrasena    = false
    @State private var msg               = ""
    @State private var showMsg           = false
    @State private var irSetup           = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fondoApp.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {

                        // Avatar + info
                        VStack(spacing: 10) {
                            Text("💰")
                                .font(Font.system(size: 50))
                                .frame(width: 80, height: 80)
                                .background(
                                    theme.temaOscuro
                                        ? Color(hex: "#1B4332")
                                        : Color(hex: "#DCEEFB"))
                                .clipShape(Circle())

                            Text(nombreActual)
                                .font(Font.title3.bold())
                                .foregroundColor(.textoPrincipal)

                            Text(Auth.auth().currentUser?.email ?? "")
                                .font(Font.caption)
                                .foregroundColor(.textoSecundario)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cardApp)
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.bordeApp, lineWidth: 1))

                        // Opciones
                        VStack(spacing: 0) {

                            filaBoton("person.fill",
                                      t("config.cambiar_nombre")) {
                                nuevoNombre = nombreActual
                                showCambiarNombre = true
                            }
                            divider()

                            filaBoton("lock.fill",
                                      t("config.cambiar_pass")) {
                                showContrasena = true
                            }
                            divider()

                            filaBoton("pencil.circle.fill",
                                      t("config.modificar")) {
                                irSetup = true
                            }
                            divider()

                            // FaceID
                            if puedeFaceID() {
                                HStack(spacing: 14) {
                                    Image(systemName: "faceid")
                                        .foregroundColor(.acentoApp)
                                        .frame(width: 24)
                                    Text(t("config.faceid"))
                                        .foregroundColor(.textoPrincipal)
                                    Spacer()
                                    Toggle("", isOn: $usarFaceID)
                                        .toggleStyle(
                                            SwitchToggleStyle(tint: .acentoApp))
                                        .labelsHidden()
                                        .onChange(of: usarFaceID) { activado in
                                            if activado { registrarFaceID() }
                                        }
                                }
                                .padding()
                                divider()
                            }

                            // Recordar sesión
                            HStack(spacing: 14) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .foregroundColor(.acentoApp).frame(width: 24)
                                Text(t("config.recordar"))
                                    .foregroundColor(.textoPrincipal)
                                Spacer()
                                Toggle("", isOn: $recordarSesion)
                                    .toggleStyle(SwitchToggleStyle(tint: .acentoApp))
                                    .labelsHidden()
                            }
                            .padding()
                            divider()

                            // Modo oscuro
                            HStack(spacing: 14) {
                                Image(systemName: theme.temaOscuro
                                      ? "moon.fill" : "sun.max.fill")
                                    .foregroundColor(.acentoApp).frame(width: 24)
                                Text(t("config.tema"))
                                    .foregroundColor(.textoPrincipal)
                                Spacer()
                                Toggle("", isOn: $theme.temaOscuro)
                                    .toggleStyle(SwitchToggleStyle(tint: .acentoApp))
                                    .labelsHidden()
                            }
                            .padding()
                            divider()

                            // Idioma — SIN navegación al cambiar
                            HStack(spacing: 14) {
                                Image(systemName: "globe")
                                    .foregroundColor(.acentoApp).frame(width: 24)
                                Text(t("config.idioma"))
                                    .foregroundColor(.textoPrincipal)
                                Spacer()
                                Picker("", selection: $loc.idioma) {
                                    Text("🇨🇴 Español").tag("es")
                                    Text("🇺🇸 English").tag("en")
                                }
                                .pickerStyle(.menu)
                                .accentColor(.acentoApp)
                            }
                            .padding()
                            divider()

                            filaBoton("message.fill", t("config.contacto")) {
                                abrirWhatsApp()
                            }
                            divider()

                            filaBoton("doc.text.fill", t("config.terminos")) {
                                showTerminos = true
                            }
                        }
                        .background(Color.cardApp)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.bordeApp, lineWidth: 1))

                        // Cerrar sesión
                        Button { showCerrarSesion = true } label: {
                            HStack {
                                Image(systemName:
                                        "rectangle.portrait.and.arrow.right")
                                Text(t("config.cerrar")).fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "#4A1010"))
                            .foregroundColor(.rojoFinanzas)
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.rojoFinanzas.opacity(0.5),
                                        lineWidth: 1))
                        }
                    }
                    .padding()
                }
            }
            .navigationDestination(isPresented: $irSetup) {
                SetupCategoriasView()
            }
        }
        // ELIMINADO: .id(loc.idioma) — causaba que ConfigView se destruyera
        // y el TabView interpretara eso como un cambio de pestaña
        .alert(t("config.cambiar_nombre"),
               isPresented: $showCambiarNombre) {
            TextField(t("nombre.campo"), text: $nuevoNombre)
            Button(t("login.ingresar")) { actualizarNombre() }
            Button(t("config.cancelar"), role: .cancel) {}
        } message: {
            Text(t("nombre.subtitulo"))
        }
        .alert(t("config.cambiar_pass"),
               isPresented: $showContrasena) {
            Button("Enviar correo") { enviarReset() }
            Button(t("config.cancelar"), role: .cancel) {}
        } message: {
            Text("Se enviará un correo a \(Auth.auth().currentUser?.email ?? "")")
        }
        .alert(t("config.cerrar"),
               isPresented: $showCerrarSesion) {
            Button(t("config.cerrar_si"), role: .destructive) { logout() }
            Button(t("config.cancelar"), role: .cancel) {}
        } message: {
            Text(t("config.cerrar_confirm"))
        }
        .alert("Términos y Condiciones",
               isPresented: $showTerminos) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("• Datos en Firebase\n• Sin venta de info\n• Uso responsable\n\nv1.0 — 2025")
        }
        .alert(msg, isPresented: $showMsg) {
            Button("OK", role: .cancel) {}
        }
        .onAppear { cargarNombre() }
        .preferredColorScheme(theme.temaOscuro ? .dark : .light)
    }

    // MARK: - Componentes
    func filaBoton(_ icono: String, _ titulo: String,
                   accion: @escaping () -> Void) -> some View {
        Button(action: accion) {
            HStack(spacing: 14) {
                Image(systemName: icono)
                    .foregroundColor(.acentoApp).frame(width: 24)
                Text(titulo).foregroundColor(.textoPrincipal)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.textoSecundario)
                    .font(Font.caption)
            }
            .padding()
        }
    }

    func divider() -> some View {
        Divider()
            .background(Color.bordeApp)
            .padding(.leading, 54)
    }

    func puedeFaceID() -> Bool {
        LAContext().canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    // MARK: - Funciones
    func cargarNombre() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Database.database().reference()
            .child("users").child(uid)
            .observeSingleEvent(of: .value) { snap in
                let data = snap.value as? [String: Any]
                let n = data?["name"] as? String ?? ""
                nombreActual = n.isEmpty
                    ? (Auth.auth().currentUser?.email?
                        .components(separatedBy: "@").first ?? "Usuario")
                    : n
            }
    }

    func actualizarNombre() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let n = nuevoNombre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty else { return }
        Database.database().reference()
            .child("users").child(uid).child("name").setValue(n)
        nombreActual = n
        msg = t("config.nombre_actualizado")
        showMsg = true
    }

    func enviarReset() {
        guard let email = Auth.auth().currentUser?.email else { return }
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            msg = error == nil
                ? t("config.pass_enviada")
                : "Error al enviar correo"
            showMsg = true
        }
    }

    func registrarFaceID() {
        let ctx = LAContext()
        ctx.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Registra Face ID para FinanzasQG"
        ) { success, _ in
            DispatchQueue.main.async {
                if success {
                    if let email = Auth.auth().currentUser?.email {
                        savedEmail = email
                    }
                    msg = "✅ Face ID activado correctamente"
                } else {
                    usarFaceID = false
                    msg = "❌ No se pudo activar Face ID"
                }
                showMsg = true
            }
        }
    }

    func abrirWhatsApp() {
        let numero  = "573246538855"
        let mensaje = "Hola, necesito ayuda con FinanzasQG"
        if let encoded = mensaje.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "https://wa.me/\(numero)?text=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }

    func logout() {
        UserDefaults.standard.set(false, forKey: "recordarSesion")
        UserDefaults.standard.set(false, forKey: "usarFaceID")
        savedEmail = ""
        savedPass  = ""
        ConfigManager.shared.detener()
        try? Auth.auth().signOut()
        if let scene = UIApplication.shared.connectedScenes.first
            as? UIWindowScene, let window = scene.windows.first {
            window.rootViewController =
                UIHostingController(rootView: LoginView())
            window.makeKeyAndVisible()
        }
    }
}
