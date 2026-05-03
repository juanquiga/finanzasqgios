import SwiftUI
import FirebaseAuth
import FirebaseCore
import FirebaseDatabase
import GoogleSignIn
import CryptoKit

struct LoginView: View {

    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var loc   = LocalizationManager.shared

    @AppStorage("recordarSesion") var recordarSesion = false
    @AppStorage("saved_email")    var savedEmail      = ""
    @AppStorage("saved_pass")     var savedPass       = ""

    @State private var emailInput  = ""
    @State private var passInput   = ""
    @State private var mostrarPass = false
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
                VStack(spacing: 24) {

                    // Header
                    VStack(spacing: 10) {
                        Text("💰").font(Font.system(size: 70))
                        Text(t("login.titulo"))
                            .font(Font.system(size: 34, weight: .bold))
                            .foregroundColor(.acentoApp)
                        Text(t("login.subtitulo"))
                            .foregroundColor(.textoSecundario)
                            .font(Font.subheadline)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 50)

                    VStack(spacing: 14) {

                        campoTexto(t("login.correo"), texto: $emailInput,
                                   icono: "envelope.fill", secure: false)
                        campoContrasena

                        HStack {
                            Toggle(isOn: $recordarSesion) {
                                Text(t("login.recordar"))
                                    .foregroundColor(.textoSecundario)
                                    .font(Font.caption)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .acentoApp))
                            Spacer()
                            Button(t("login.olvide")) { showReset = true }
                                .foregroundColor(.acentoApp).font(Font.caption)
                        }

                        // Botón ingresar
                        Button(action: login) {
                            HStack {
                                if loading { ProgressView().tint(.white) }
                                else {
                                    Text(t("login.ingresar"))
                                        .fontWeight(.bold).tracking(1.2)
                                }
                            }
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.gradienteBoton)
                            .foregroundColor(.white).cornerRadius(14)
                        }
                        .disabled(loading).buttonStyle(PlainButtonStyle())

                        separador()

                        // Google
                        Button(action: loginConGoogle) {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle().fill(Color.white).frame(width: 26, height: 26)
                                    Text("G").font(Font.system(size: 15, weight: .bold))
                                        .foregroundColor(Color(hex: "#DB4437"))
                                }
                                Text(t("login.google"))
                                    .font(Font.subheadline).fontWeight(.semibold)
                                    .foregroundColor(.textoPrincipal)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 13)
                            .padding(.horizontal, 16)
                            .background(Color.cardApp).cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.bordeApp, lineWidth: 1.5))
                        }
                        .buttonStyle(PlainButtonStyle())

                        separador()

                        // Crear cuenta
                        Button { irRegistro = true } label: {
                            Text(t("login.crear"))
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity).padding()
                                .background(Color.cardApp).foregroundColor(.acentoApp)
                                .cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.bordeApp, lineWidth: 1))
                        }
                        .buttonStyle(PlainButtonStyle())

                        Text(t("app.copyright"))
                            .foregroundColor(Color.textoSecundario.opacity(0.5))
                            .font(Font.caption2).padding(.top, 4)
                    }
                    .padding(24)
                    .background(Color.cardApp).cornerRadius(24)
                    .overlay(RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.bordeApp, lineWidth: 1))
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
            .background(Color.fondoApp.ignoresSafeArea())
            .navigationDestination(isPresented: $irRegistro) { SignUpView() }
            .alert(t("login.reset.titulo"), isPresented: $showReset) {
                TextField(t("login.correo"), text: $resetEmail)
                    .textInputAutocapitalization(.never)
                Button(t("login.ingresar")) { enviarReset() }
                Button(t("config.cancelar"), role: .cancel) { resetEmail = "" }
            } message: { Text(t("login.reset.mensaje")) }
            .alert(alerta, isPresented: $showAlerta) {
                Button("OK", role: .cancel) {}
            }
        }
        .id(loc.idioma)
    }

    // MARK: - UI
    var campoContrasena: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .foregroundColor(.acentoApp).frame(width: 20)
            if mostrarPass {
                TextField(t("login.contrasena"), text: $passInput)
                    .foregroundColor(.textoPrincipal)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
            } else {
                SecureField(t("login.contrasena"), text: $passInput)
                    .foregroundColor(.textoPrincipal)
            }
            Button {
                mostrarPass.toggle()
            } label: {
                Image(systemName: mostrarPass ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.textoSecundario).frame(width: 24)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding().background(Color.inputFondo).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bordeApp, lineWidth: 1))
    }

    func campoTexto(_ placeholder: String, texto: Binding<String>,
                    icono: String, secure: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icono).foregroundColor(.acentoApp).frame(width: 20)
            TextField(placeholder, text: texto)
                .foregroundColor(.textoPrincipal)
                .textInputAutocapitalization(.never).keyboardType(.emailAddress)
        }
        .padding().background(Color.inputFondo).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bordeApp, lineWidth: 1))
    }

    func separador() -> some View {
        HStack(spacing: 8) {
            Rectangle().frame(height: 1).foregroundColor(Color.bordeApp)
            Text("o").foregroundColor(.textoSecundario).font(Font.caption)
            Rectangle().frame(height: 1).foregroundColor(Color.bordeApp)
        }
    }

    // MARK: - Login email/usuario
    func login() {
        let input = emailInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let pass  = passInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty, !pass.isEmpty else {
            alerta = t("login.error.campos"); showAlerta = true; return
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
                let name = data["name"]  as? String ?? ""
                if name.lowercased() == nombre.lowercased() {
                    found = data["email"] as? String; break
                }
            }
            DispatchQueue.main.async {
                if let email = found { loginConEmail(email, pass) }
                else {
                    loading = false
                    alerta = t("login.error.usuario"); showAlerta = true
                }
            }
        }
    }

    func loginConEmail(_ correo: String, _ pass: String) {
        Auth.auth().signIn(withEmail: correo, password: pass) { result, error in
            DispatchQueue.main.async { loading = false }
            if let error {
                let code = (error as NSError).code
                alerta = (code == 17004 || code == 17009)
                    ? t("login.error.credenciales") : error.localizedDescription
                showAlerta = true; return
            }
            if recordarSesion { savedEmail = correo; savedPass = pass }
            else { savedEmail = ""; savedPass = "" }
            ConfigManager.shared.cargar()
            irAApp(uid: result?.user.uid ?? "")
        }
    }

    // MARK: - Google
    func loginConGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
            if let error {
                let code = (error as NSError).code
                if code != -5 {
                    DispatchQueue.main.async {
                        alerta = "Error Google: \(error.localizedDescription)"
                        showAlerta = true
                    }
                }
                return
            }
            guard let user    = result?.user,
                  let idToken = user.idToken?.tokenString else { return }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken, accessToken: user.accessToken.tokenString)
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error {
                    DispatchQueue.main.async {
                        alerta = "Error: \(error.localizedDescription)"; showAlerta = true
                    }
                    return
                }
                guard let uid = authResult?.user.uid else { return }
                manejarLoginSocial(uid: uid, email: authResult?.user.email ?? "",
                                   nombreSugerido: user.profile?.name ?? "")
            }
        }
    }

    // MARK: - Login social
    func manejarLoginSocial(uid: String, email: String, nombreSugerido: String) {
        db.child("users").child(uid).observeSingleEvent(of: .value) { snap in
            let data       = snap.value as? [String: Any]
            let nombreBD   = data?["name"]      as? String ?? ""
            let isNew      = data?["isNewUser"] as? Bool   ?? true
            let existeEnBD = snap.exists() && !nombreBD.isEmpty
            DispatchQueue.main.async {
                ConfigManager.shared.cargar()
                guard let scene = UIApplication.shared.connectedScenes.first
                        as? UIWindowScene,
                      let window = scene.windows.first else { return }
                if !existeEnBD {
                    Database.database().reference().child("users").child(uid)
                        .setValue(["email": email, "uid": uid, "isNewUser": true])
                    window.rootViewController = UIHostingController(
                        rootView: NombreUsuarioView(uid: uid, esNuevo: true))
                } else if nombreBD.isEmpty {
                    window.rootViewController = UIHostingController(
                        rootView: NombreUsuarioView(uid: uid, esNuevo: isNew))
                } else {
                    window.rootViewController = UIHostingController(
                        rootView: isNew ? AnyView(OnboardingView()) : AnyView(MainTabView()))
                }
                window.makeKeyAndVisible()
            }
        }
    }

    func irAApp(uid: String) {
        db.child("users").child(uid).observeSingleEvent(of: .value) { snap in
            let data  = snap.value as? [String: Any]
            let isNew = data?["isNewUser"] as? Bool ?? false
            DispatchQueue.main.async {
                guard let scene = UIApplication.shared.connectedScenes.first
                        as? UIWindowScene,
                      let window = scene.windows.first else { return }
                window.rootViewController = UIHostingController(
                    rootView: isNew ? AnyView(OnboardingView()) : AnyView(MainTabView()))
                window.makeKeyAndVisible()
            }
        }
    }

    func enviarReset() {
        let correo = resetEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !correo.isEmpty else { return }
        Auth.auth().sendPasswordReset(withEmail: correo) { error in
            DispatchQueue.main.async {
                resetEmail = ""
                alerta = error == nil ? t("login.reset.exito") : "Correo no encontrado"
                showAlerta = true
            }
        }
    }
}
