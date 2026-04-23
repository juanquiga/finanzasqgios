import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct SignUpView: View {

    @ObservedObject var theme = ThemeManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var name         = ""
    @State private var email        = ""
    @State private var pass         = ""
    @State private var mostrarPass  = false      // ← nuevo
    @State private var mensaje      = ""
    @State private var loading      = false
    @State private var cuentaCreada = false

    @FocusState private var campoActivo: Bool

    let db = Database.database().reference()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                VStack(spacing: 8) {
                    Text("💰").font(Font.system(size: 60))
                    Text("FinanzasQG")
                        .font(Font.title.bold()).foregroundColor(.acentoApp)
                    Text(t("signup.titulo"))
                        .foregroundColor(.textoSecundario).font(Font.subheadline)
                }
                .padding(.top, 40)

                VStack(spacing: 14) {

                    campoTexto("👤  \(t("signup.nombre"))",
                               texto: $name, secure: false, keyboard: .default)
                    campoTexto("✉️  \(t("signup.correo"))",
                               texto: $email, secure: false, keyboard: .emailAddress)

                    // Contraseña con ojo
                    campoContrasena

                    if !mensaje.isEmpty {
                        HStack {
                            Image(systemName: cuentaCreada
                                  ? "checkmark.circle.fill"
                                  : "exclamationmark.circle.fill")
                            Text(mensaje).font(Font.subheadline)
                        }
                        .foregroundColor(cuentaCreada
                            ? Color.verdeFinanzas : Color.rojoFinanzas)
                        .padding()
                        .background(cuentaCreada
                            ? Color(hex: "#1B4332") : Color(hex: "#4A1010"))
                        .cornerRadius(12).transition(.opacity)
                    }

                    Button {
                        campoActivo = false
                        registrar()
                    } label: {
                        HStack {
                            if loading { ProgressView().tint(.white) }
                            else {
                                Image(systemName: "person.badge.plus")
                                Text(t("signup.boton")).fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(cuentaCreada
                            ? AnyView(Color.gray) : AnyView(Color.gradienteBoton))
                        .foregroundColor(.white).cornerRadius(14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(loading || cuentaCreada)

                    if cuentaCreada {
                        Button {
                            campoActivo = false; dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.left.circle.fill")
                                Text(t("signup.ir_login")).fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.gradienteBoton)
                            .foregroundColor(.white).cornerRadius(14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    HStack {
                        Rectangle().frame(height: 1).foregroundColor(Color.bordeApp)
                        Text("o").foregroundColor(.textoSecundario).font(Font.caption)
                        Rectangle().frame(height: 1).foregroundColor(Color.bordeApp)
                    }

                    Button {
                        campoActivo = false; dismiss()
                    } label: {
                        Text(t("signup.volver"))
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.cardApp).foregroundColor(.acentoApp)
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.bordeApp, lineWidth: 1))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(loading)
                }
                .padding(24)
                .background(Color.cardApp).cornerRadius(24)
                .overlay(RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.bordeApp, lineWidth: 1))
                .padding(.horizontal)

                Text(t("login.copyright"))
                    .foregroundColor(Color.textoSecundario.opacity(0.4))
                    .font(Font.caption2)
            }
        }
        .background(Color.fondoApp.ignoresSafeArea())
        .navigationBarHidden(true)
        .preferredColorScheme(theme.temaOscuro ? .dark : .light)
        .onTapGesture { campoActivo = false }
    }

    // MARK: - Campo contraseña con ojo
    var campoContrasena: some View {
        HStack(spacing: 12) {
            Text("🔒").frame(width: 28)

            ZStack {
                if mostrarPass {
                    TextField(t("signup.contrasena"), text: $pass)
                        .foregroundColor(.textoPrincipal)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($campoActivo)
                } else {
                    SecureField(t("signup.contrasena"), text: $pass)
                        .foregroundColor(.textoPrincipal)
                        .focused($campoActivo)
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
                    secure: Bool, keyboard: UIKeyboardType) -> some View {
        Group {
            if secure {
                SecureField(placeholder, text: texto)
                    .focused($campoActivo)
            } else {
                TextField(placeholder, text: texto)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(
                        keyboard == .emailAddress ? .never : .words)
                    .focused($campoActivo)
                    .submitLabel(.next)
            }
        }
        .foregroundColor(.textoPrincipal).padding()
        .background(Color.inputFondo).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(Color.bordeApp, lineWidth: 1))
    }

    // MARK: - Firebase
    func registrar() {
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = pass.trimmingCharacters(in: .whitespacesAndNewlines)
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !e.isEmpty, !p.isEmpty, !n.isEmpty else {
            mensaje = t("login.error.campos"); cuentaCreada = false; return
        }
        guard p.count >= 6 else {
            mensaje = "La contraseña debe tener mínimo 6 caracteres"
            cuentaCreada = false; return
        }

        loading = true

        Auth.auth().createUser(withEmail: e, password: p) { result, error in
            DispatchQueue.main.async { loading = false }

            if let err = error as NSError? {
                withAnimation {
                    cuentaCreada = false
                    switch err.code {
                    case 17007: mensaje = "Este correo ya está registrado"
                    case 17008: mensaje = "Correo inválido"
                    case 17026: mensaje = "Contraseña muy débil"
                    default:    mensaje = err.localizedDescription
                    }
                }
                return
            }

            guard let uid = result?.user.uid else { return }
            db.child("users").child(uid).setValue([
                "name": n, "email": e, "uid": uid, "isNewUser": true
            ])
            try? Auth.auth().signOut()
            withAnimation { cuentaCreada = true; mensaje = t("signup.exito") }
        }
    }
}
