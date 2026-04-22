import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct SignUpView: View {

    @Environment(\.dismiss) var dismiss

    @State private var name    = ""
    @State private var email   = ""
    @State private var pass    = ""
    @State private var mensaje = ""
    @State private var loading = false
    @State private var cuentaCreada = false

    let db = Database.database().reference()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                VStack(spacing: 8) {
                    Text("💰").font(.system(size: 60))
                    Text("FinanzasQG")
                        .font(.title.bold()).foregroundColor(.verdeApp)
                    Text("Crea tu cuenta")
                        .foregroundColor(.grisTexto).font(.subheadline)
                }
                .padding(.top, 40)

                VStack(spacing: 14) {

                    campoTexto("👤  Nombre de usuario", texto: $name,
                               secure: false, keyboard: .default)
                    campoTexto("✉️  Correo electrónico", texto: $email,
                               secure: false, keyboard: .emailAddress)
                    campoTexto("🔒  Contraseña (mín. 6)", texto: $pass,
                               secure: true, keyboard: .default)

                    // Mensaje de éxito o error
                    if !mensaje.isEmpty {
                        HStack {
                            Image(systemName: cuentaCreada
                                  ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            Text(mensaje).font(.subheadline)
                        }
                        .foregroundColor(cuentaCreada ? .verdeApp : .rojoApp)
                        .padding()
                        .background(cuentaCreada
                            ? Color(hex: "#1B4332") : Color(hex: "#4A1010"))
                        .cornerRadius(12)
                        .transition(.opacity)
                    }

                    Button(action: registrar) {
                        HStack {
                            if loading { ProgressView().tint(.white) }
                            else {
                                Image(systemName: "person.badge.plus")
                                Text("CREAR CUENTA").fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(
                            Group {
                                if cuentaCreada {
                                    AnyView(Color.gray)
                                } else {
                                    AnyView(LinearGradient(
                                        colors: [Color(hex: "#2E7D32"), Color(hex: "#1B5E20")],
                                        startPoint: .leading, endPoint: .trailing))
                                }
                            }
                        )
                        .foregroundColor(.white).cornerRadius(14)
                    }
                    .disabled(loading || cuentaCreada)
                    .disabled(loading || cuentaCreada)

                    if cuentaCreada {
                        Button {
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.left.circle.fill")
                                Text("IR AL LOGIN").fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity).padding()
                            .background(LinearGradient(
                                colors: [Color(hex: "#2E7D32"), Color(hex: "#1B5E20")],
                                startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white).cornerRadius(14)
                        }
                    }

                    HStack {
                        Rectangle().frame(height: 1).foregroundColor(.borde)
                        Text("o").foregroundColor(.grisTexto).font(.caption)
                        Rectangle().frame(height: 1).foregroundColor(.borde)
                    }

                    Button { dismiss() } label: {
                        Text("← Volver al Login")
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.card).foregroundColor(.verdeApp)
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.borde, lineWidth: 1))
                    }
                    .disabled(loading)
                }
                .padding(24)
                .background(Color.card).cornerRadius(24)
                .overlay(RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.borde, lineWidth: 1))
                .padding(.horizontal)

                Text("FinanzasQG © 2025")
                    .foregroundColor(Color.grisTexto.opacity(0.4))
                    .font(.caption2)
            }
        }
        .background(Color.fondo.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    func campoTexto(_ placeholder: String, texto: Binding<String>,
                    secure: Bool, keyboard: UIKeyboardType) -> some View {
        Group {
            if secure { SecureField(placeholder, text: texto) }
            else {
                TextField(placeholder, text: texto)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(
                        keyboard == .emailAddress ? .never : .words)
            }
        }
        .foregroundColor(.white).padding()
        .background(Color(hex: "#0D1A2A")).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borde, lineWidth: 1))
    }

    func registrar() {
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = pass.trimmingCharacters(in: .whitespacesAndNewlines)
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !e.isEmpty, !p.isEmpty, !n.isEmpty else {
            mensaje = "Completa todos los campos"
            cuentaCreada = false; return
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

            // Guardar en Firebase
            db.child("users").child(uid).setValue([
                "name": n, "email": e, "uid": uid, "isNewUser": true
            ])

            // Cerrar sesión inmediatamente — el usuario debe iniciar sesión manual
            try? Auth.auth().signOut()

            withAnimation {
                cuentaCreada = true
                mensaje = "¡Cuenta creada exitosamente! 🎉\nInicia sesión para continuar."
            }
        }
    }
}
