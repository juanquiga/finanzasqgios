import SwiftUI
import FirebaseAuth
import FirebaseCore
import FirebaseDatabase
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices
import CryptoKit

struct LoginView: View {

    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var loc   = LocalizationManager.shared

    @AppStorage("recordarSesion") var recordarSesion = false
    @AppStorage("saved_email")    var savedEmail      = ""
    @AppStorage("saved_pass")     var savedPass       = ""

    @State private var emailInput    = ""
    @State private var passInput     = ""
    @State private var mostrarPass   = false        // ← nuevo
    @State private var loading       = false
    @State private var showReset     = false
    @State private var resetEmail    = ""
    @State private var alerta        = ""
    @State private var showAlerta    = false
    @State private var irRegistro    = false
    @State private var nonce         = ""

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

                    VStack(spacing: 12) {

                        // Email
                        campoTexto(t("login.correo"), texto: $emailInput,
                                   icono: "envelope.fill", secure: false)

                        // Contraseña con ojo
                        campoContrasena

                        // Recordar + olvidé
                        HStack {
                            Toggle(isOn: $recordarSesion) {
                                Text(t("login.recordar"))
                                    .foregroundColor(.textoSecundario)
                                    .font(Font.caption)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .acentoApp))
                            Spacer()
                            Button(t("login.olvide")) { showReset = true }
                                .foregroundColor(.acentoApp)
                                .font(Font.caption)
                        }

                        // Botón ingresar
                        Button(action: login) {
                            HStack {
                                if loading { ProgressView().tint(.white) }
                                else {
                                    Text(t("login.ingresar"))
                                        .fontWeight(.bold).tracking(1.5)
                                }
                            }
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.gradienteBoton)
                            .foregroundColor(.white).cornerRadius(14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(loading)

                        separador()

                        // Google
                        Button(action: loginConGoogle) {
                            HStack(spacing: 8) {
                                Image(systemName: "g.circle.fill")
                                    .font(Font.body).foregroundColor(.red)
                                Text(t("login.google"))
                                    .font(Font.subheadline).fontWeight(.medium)
                                    .foregroundColor(.textoPrincipal)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10).padding(.horizontal, 16)
                            .background(Color.cardApp).cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.bordeApp, lineWidth: 1.2))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Apple
                        SignInWithAppleButton(
                            onRequest: { request in
                                nonce = randomNonceString()
                                request.requestedScopes = [.fullName, .email]
                                request.nonce = sha256(nonce)
                            },
                            onCompletion: { result in manejarApple(result) }
                        )
                        .signInWithAppleButtonStyle(theme.temaOscuro ? .white : .black)
                        .frame(height: 44).cornerRadius(12)

                        separador()

                        // Crear cuenta
                        Button { irRegistro = true } label: {
                            Text(t("login.crear"))
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(Color.cardApp).foregroundColor(.acentoApp)
                                .fontWeight(.semibold).cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.bordeApp, lineWidth: 1))
                                .contentShape(Rectangle())
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
            }
            .background(Color.fondoApp.ignoresSafeArea())
            .navigationDestination(isPresented: $irRegistro) { SignUpView() }
            .alert(t("login.reset.titulo"), isPresented: $showReset) {
                TextField("email", text: $resetEmail)
                    .textInputAutocapitalization(.never)
                Button(t("login.ingresar")) { enviarReset() }
                Button(t("config.cancelar"), role: .cancel) {}
            } message: { Text(t("login.reset.mensaje")) }
            .alert("", isPresented: $showAlerta) {
                Button("OK", role: .cancel) {}
            } message: { Text(alerta) }
        }
        .id(loc.idioma)
    }

    // MARK: - Campo contraseña con ojo
    var campoContrasena: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .foregroundColor(.acentoApp).frame(width: 20)

            ZStack(alignment: .trailing) {
                if mostrarPass {
                    TextField(t("login.contrasena"), text: $passInput)
                        .foregroundColor(.textoPrincipal)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    SecureField(t("login.contrasena"), text: $passInput)
                        .foregroundColor(.textoPrincipal)
                }
            }

            Button {
                mostrarPass.toggle()
            } label: {
                Image(systemName: mostrarPass ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.textoSecundario)
                    .frame(width: 24)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color.inputFondo).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(Color.bordeApp, lineWidth: 1))
    }

    // MARK: - Campo texto genérico
    func campoTexto(_ placeholder: String, texto: Binding<String>,
                    icono: String, secure: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icono).foregroundColor(.acentoApp).frame(width: 20)
            if secure {
                SecureField(placeholder, text: texto).foregroundColor(.textoPrincipal)
            } else {
                TextField(placeholder, text: texto)
                    .foregroundColor(.textoPrincipal)
                    .textInputAutocapitalization(.never)
            }
        }
        .padding()
        .background(Color.inputFondo).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(Color.bordeApp, lineWidth: 1))
    }

    func separador() -> some View {
        HStack {
            Rectangle().frame(height: 1).foregroundColor(.bordeApp)
            Text("o").foregroundColor(.textoSecundario).font(Font.caption)
            Rectangle().frame(height: 1).foregroundColor(.bordeApp)
        }
    }

    // MARK: - Login
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
            if error != nil {
                alerta = t("login.error.credenciales"); showAlerta = true; return
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
        guard let windowScene = UIApplication.shared.connectedScenes.first
                as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
            guard error == nil,
                  let user    = result?.user,
                  let idToken = user.idToken?.tokenString else { return }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString)
            Auth.auth().signIn(with: credential) { authResult, error in
                guard error == nil, let uid = authResult?.user.uid else { return }
                manejarLoginSocial(uid: uid,
                                   email: authResult?.user.email ?? "",
                                   nombreSugerido: user.profile?.name ?? "")
            }
        }
    }

    // MARK: - Apple
    func manejarApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure:
            alerta = "Apple Sign In cancelado"; showAlerta = true
        case .success(let auth):
            guard let appleCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = appleCredential.identityToken,
                  let tokenStr  = String(data: tokenData, encoding: .utf8) else { return }
            let credential = OAuthProvider.appleCredential(
                withIDToken: tokenStr, rawNonce: nonce,
                fullName: appleCredential.fullName)
            Auth.auth().signIn(with: credential) { authResult, error in
                guard error == nil, let uid = authResult?.user.uid else { return }
                let nombreApple = [
                    appleCredential.fullName?.givenName,
                    appleCredential.fullName?.familyName
                ].compactMap { $0 }.joined(separator: " ")
                manejarLoginSocial(uid: uid,
                                   email: authResult?.user.email ?? "",
                                   nombreSugerido: nombreApple)
            }
        }
    }

    func manejarLoginSocial(uid: String, email: String, nombreSugerido: String) {
        db.child("users").child(uid).observeSingleEvent(of: .value) { snap in
            let data       = snap.value as? [String: Any]
            let nombreBD   = data?["name"]      as? String ?? ""
            let isNew      = data?["isNewUser"] as? Bool   ?? true
            let existeEnBD = snap.exists() && !nombreBD.isEmpty
            DispatchQueue.main.async {
                ConfigManager.shared.cargar()
                if let scene = UIApplication.shared.connectedScenes.first
                    as? UIWindowScene, let window = scene.windows.first {
                    if !existeEnBD {
                        Database.database().reference()
                            .child("users").child(uid).setValue([
                                "email": email, "uid": uid, "isNewUser": true
                            ])
                        window.rootViewController = UIHostingController(
                            rootView: NombreUsuarioView(uid: uid, esNuevo: true))
                    } else if nombreBD.isEmpty {
                        window.rootViewController = UIHostingController(
                            rootView: NombreUsuarioView(uid: uid, esNuevo: isNew))
                    } else {
                        let destino: AnyView = isNew
                            ? AnyView(OnboardingView()) : AnyView(MainTabView())
                        window.rootViewController =
                            UIHostingController(rootView: destino)
                    }
                    window.makeKeyAndVisible()
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
            alerta = error == nil ? t("login.reset.exito") : "No se encontró ese correo"
            showAlerta = true
        }
    }

    func randomNonceString(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        return randomBytes.map { String(format: "%02x", $0) }.joined()
    }

    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hash = SHA256.hash(data: inputData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
