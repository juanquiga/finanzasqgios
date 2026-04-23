import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct NombreUsuarioView: View {

    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var loc   = LocalizationManager.shared

    @State private var nombre  = ""
    @State private var error   = ""
    @State private var loading = false

    let uid   : String
    let esNuevo: Bool

    var body: some View {
        ZStack {
            Color.fondoApp.ignoresSafeArea()

            VStack(spacing: 30) {

                Spacer()

                // Emoji
                Text("👤")
                    .font(Font.system(size: 70))

                // Título
                Text(t("nombre.titulo"))
                    .font(Font.title2.bold())
                    .foregroundColor(.acentoApp)
                    .multilineTextAlignment(.center)

                // Subtítulo
                Text(t("nombre.subtitulo"))
                    .font(Font.subheadline)
                    .foregroundColor(.textoSecundario)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Campo
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.fill")
                            .foregroundColor(.acentoApp)
                            .frame(width: 20)
                        TextField(t("nombre.campo"), text: $nombre)
                            .foregroundColor(.textoPrincipal)
                            .textInputAutocapitalization(.words)
                    }
                    .padding()
                    .background(Color.inputFondo)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.bordeApp, lineWidth: 1)
                    )

                    if !error.isEmpty {
                        Text(error)
                            .font(Font.caption)
                            .foregroundColor(.rojoFinanzas)
                            .padding(.leading, 4)
                    }
                }
                .padding(.horizontal)

                // Botón continuar
                Button(action: continuar) {
                    HStack {
                        if loading {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                            Text(t("nombre.boton"))
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gradienteBoton)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .disabled(loading)
                .padding(.horizontal)

                Spacer()

                Text(t("login.copyright"))
                    .font(Font.caption2)
                    .foregroundColor(Color.textoSecundario.opacity(0.5))
                    .padding(.bottom)
            }
        }
        .navigationBarHidden(true)
    }

    func continuar() {
        let n = nombre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard n.count >= 2 else {
            error = t("nombre.error"); return
        }
        loading = true

        Database.database().reference()
            .child("users").child(uid)
            .updateChildValues([
                "name":      n,
                "isNewUser": esNuevo
            ]) { _, _ in
                loading = false
                navigarSiguiente()
            }
    }

    func navigarSiguiente() {
        if let scene = UIApplication.shared.connectedScenes.first
            as? UIWindowScene, let window = scene.windows.first {
            let destino: AnyView = esNuevo
                ? AnyView(OnboardingView())
                : AnyView(MainTabView())
            window.rootViewController = UIHostingController(rootView: destino)
            window.makeKeyAndVisible()
        }
    }
}
