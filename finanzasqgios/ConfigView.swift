import SwiftUI
import FirebaseAuth
import FirebaseDatabase
import LocalAuthentication

struct ConfigView: View {

    @ObservedObject var theme   = ThemeManager.shared
    @ObservedObject var loc     = LocalizationManager.shared
    @ObservedObject var premium = PremiumManager.shared

    @AppStorage("recordarSesion") var recordarSesion = false
    @AppStorage("usarFaceID")     var usarFaceID     = false
    @AppStorage("saved_email")    var savedEmail      = ""
    @AppStorage("saved_pass")     var savedPass       = ""

    @State private var nombreActual       = ""
    @State private var showCambiarNombre  = false
    @State private var nuevoNombre        = ""
    @State private var showCerrarSesion   = false
    @State private var showTerminos       = false
    @State private var showContrasena     = false
    @State private var msg                = ""
    @State private var showMsg            = false
    @State private var irSetup            = false
    @State private var irPresupuesto      = false
    @State private var showPremium        = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fondoApp.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {

                        // Avatar
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(theme.temaOscuro ? Color(hex: "#1B4332") : Color(hex: "#DCEEFB"))
                                    .frame(width: 80, height: 80)
                                Text("💰").font(Font.system(size: 38))
                                // Badge premium
                                if premium.esPremium {
                                    Text("👑").font(Font.system(size: 16))
                                        .offset(x: 28, y: -28)
                                }
                            }
                            Text(nombreActual)
                                .font(Font.title3.bold()).foregroundColor(.textoPrincipal)
                            Text(Auth.auth().currentUser?.email ?? "")
                                .font(Font.caption).foregroundColor(.textoSecundario)
                            if premium.enPrueba {
                                Text("🎁 Prueba Premium — \(premium.diasRestantes) días restantes")
                                    .font(Font.caption2.bold()).foregroundColor(Color(hex: "#4CAF50"))
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Color(hex: "#1B4332")).cornerRadius(8)
                            } else if premium.esPremium {
                                Text("👑 Premium activo — \(premium.diasRestantes) días restantes")
                                    .font(Font.caption2.bold()).foregroundColor(Color(hex: "#FFD700"))
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Color(hex: "#1A1200")).cornerRadius(8)
                            }
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.cardApp).cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.bordeApp, lineWidth: 1))

                        // ── BANNER PREMIUM ──
                        Button { showPremium = true } label: {
                            HStack(spacing: 12) {
                                Text("👑").font(Font.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(premium.esPremium ? "Premium Activo ✅" : "Hazte Premium")
                                        .font(Font.subheadline.bold()).foregroundColor(.textoPrincipal)
                                    Text(premium.esPremium
                                         ? (premium.enPrueba ? "Prueba — expira: \(premium.labelExpiracion)" : "Expira: \(premium.labelExpiracion)")
                                         : "7 días gratis · Desbloquea todo")
                                        .font(Font.caption2).foregroundColor(.textoSecundario)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Color(hex: "#FFD700")).font(Font.caption)
                            }
                            .padding()
                            .background(LinearGradient(
                                colors: [Color(hex: "#1A1200"), Color(hex: "#2A1A00")],
                                startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(hex: "#FFD700").opacity(0.5), lineWidth: 1.5))
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Opciones
                        VStack(spacing: 0) {
                            filaBoton("person.fill", t("config.cambiar_nombre")) {
                                nuevoNombre = nombreActual; showCambiarNombre = true
                            }
                            divider()

                            filaBoton("lock.fill", t("config.cambiar_pass")) {
                                showContrasena = true
                            }
                            divider()

                            filaBoton("tag.fill", "Categorías y cuentas") { irSetup = true }
                            divider()

                            filaBoton("chart.bar.fill", "Presupuesto") { irPresupuesto = true }
                            divider()

                            if puedeFaceID() {
                                HStack(spacing: 14) {
                                    Image(systemName: "faceid")
                                        .foregroundColor(.acentoApp).frame(width: 24)
                                    Text(t("config.faceid")).foregroundColor(.textoPrincipal)
                                    Spacer()
                                    Toggle("", isOn: $usarFaceID)
                                        .toggleStyle(SwitchToggleStyle(tint: .acentoApp)).labelsHidden()
                                        .onChange(of: usarFaceID) { if $0 { registrarFaceID() } }
                                }
                                .padding()
                                divider()
                            }

                            HStack(spacing: 14) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .foregroundColor(.acentoApp).frame(width: 24)
                                Text(t("config.recordar")).foregroundColor(.textoPrincipal)
                                Spacer()
                                Toggle("", isOn: $recordarSesion)
                                    .toggleStyle(SwitchToggleStyle(tint: .acentoApp)).labelsHidden()
                            }
                            .padding()
                            divider()

                            HStack(spacing: 14) {
                                Image(systemName: theme.temaOscuro ? "moon.fill" : "sun.max.fill")
                                    .foregroundColor(.acentoApp).frame(width: 24)
                                Text(t("config.tema")).foregroundColor(.textoPrincipal)
                                Spacer()
                                Toggle("", isOn: $theme.temaOscuro)
                                    .toggleStyle(SwitchToggleStyle(tint: .acentoApp)).labelsHidden()
                            }
                            .padding()
                            divider()

                            HStack(spacing: 14) {
                                Image(systemName: "globe")
                                    .foregroundColor(.acentoApp).frame(width: 24)
                                Text(t("config.idioma")).foregroundColor(.textoPrincipal)
                                Spacer()
                                Picker("", selection: $loc.idioma) {
                                    Text("🇨🇴 Español").tag("es")
                                    Text("🇺🇸 English").tag("en")
                                }
                                .pickerStyle(.menu).accentColor(.acentoApp)
                            }
                            .padding()
                            divider()

                            filaBoton("message.fill", t("config.contacto")) { abrirWhatsApp() }
                            divider()
                            filaBoton("doc.text.fill", t("config.terminos")) { showTerminos = true }
                        }
                        .background(Color.cardApp).cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.bordeApp, lineWidth: 1))

                        // Cerrar sesión
                        Button { showCerrarSesion = true } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text(t("config.cerrar")).fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity).padding()
                            .background(Color(hex: "#4A1010"))
                            .foregroundColor(Color(hex: "#FF5252")).cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(hex: "#FF5252").opacity(0.5), lineWidth: 1))
                        }

                        Text(t("app.copyright"))
                            .font(Font.caption2).foregroundColor(Color.textoSecundario.opacity(0.4))
                    }
                    .padding()
                }
            }
            .navigationDestination(isPresented: $irSetup) {
                SetupCategoriasView(modoInicial: false)
            }
            .navigationDestination(isPresented: $irPresupuesto) {
                PresupuestoView()
            }
        }
        .sheet(isPresented: $showPremium) { PremiumView() }
        .alert(t("config.cambiar_nombre"), isPresented: $showCambiarNombre) {
            TextField(t("nombre.campo"), text: $nuevoNombre)
            Button(t("login.ingresar")) { actualizarNombre() }
            Button(t("config.cancelar"), role: .cancel) {}
        } message: { Text(t("nombre.subtitulo")) }
        .alert(t("config.cambiar_pass"), isPresented: $showContrasena) {
            Button("Enviar correo") { enviarReset() }
            Button(t("config.cancelar"), role: .cancel) {}
        } message: {
            Text("Se enviará un correo a \(Auth.auth().currentUser?.email ?? "")")
        }
        .alert(t("config.cerrar"), isPresented: $showCerrarSesion) {
            Button(t("config.cerrar_si"), role: .destructive) { logout() }
            Button(t("config.cancelar"), role: .cancel) {}
        } message: { Text(t("config.cerrar_confirm")) }
        .alert("Términos y Condiciones", isPresented: $showTerminos) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("• Datos guardados en Firebase\n• Información 100% privada\n• Sin venta de datos\n\nv1.0 — 2026")
        }
        .alert(msg, isPresented: $showMsg) { Button("OK", role: .cancel) {} }
        .onAppear { cargarNombre() }
        .preferredColorScheme(theme.temaOscuro ? .dark : .light)
    }

    func filaBoton(_ icono: String, _ titulo: String, accion: @escaping () -> Void) -> some View {
        Button(action: accion) {
            HStack(spacing: 14) {
                Image(systemName: icono).foregroundColor(.acentoApp).frame(width: 24)
                Text(titulo).foregroundColor(.textoPrincipal)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.textoSecundario).font(Font.caption)
            }
            .padding()
        }
    }

    func divider() -> some View {
        Divider().background(Color.bordeApp).padding(.leading, 54)
    }

    func puedeFaceID() -> Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    func cargarNombre() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Database.database().reference().child("users").child(uid)
            .observeSingleEvent(of: .value) { snap in
                let data = snap.value as? [String: Any]
                let n = data?["name"] as? String ?? ""
                nombreActual = n.isEmpty
                    ? (Auth.auth().currentUser?.email?.components(separatedBy: "@").first ?? "Usuario") : n
            }
    }

    func actualizarNombre() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let n = nuevoNombre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty else { return }
        Database.database().reference().child("users").child(uid).child("name").setValue(n)
        nombreActual = n; msg = t("config.nombre_actualizado"); showMsg = true
    }

    func enviarReset() {
        guard let email = Auth.auth().currentUser?.email else { return }
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            msg = error == nil ? t("config.pass_enviada") : "Error al enviar correo"
            showMsg = true
        }
    }

    func registrarFaceID() {
        LAContext().evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                   localizedReason: "Registra Face ID para FinanzasQG") { success, _ in
            DispatchQueue.main.async {
                if success {
                    if let email = Auth.auth().currentUser?.email { savedEmail = email }
                    msg = "✅ Face ID activado"
                } else { usarFaceID = false; msg = "❌ No se pudo activar" }
                showMsg = true
            }
        }
    }

    func abrirWhatsApp() {
        let numero = "573246538855"
        let mensaje = "Hola, necesito ayuda con FinanzasQG"
        if let enc = mensaje.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "https://wa.me/\(numero)?text=\(enc)") {
            UIApplication.shared.open(url)
        }
    }

    func logout() {
        UserDefaults.standard.set(false, forKey: "recordarSesion")
        UserDefaults.standard.set(false, forKey: "usarFaceID")
        savedEmail = ""; savedPass = ""
        ConfigManager.shared.resetearSesion()
        PremiumManager.shared.resetear()
        try? Auth.auth().signOut()
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController = UIHostingController(rootView: LoginView())
            window.makeKeyAndVisible()
        }
    }
}
