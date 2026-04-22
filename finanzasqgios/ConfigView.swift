import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct ConfigView: View {

    @State private var showAlert = false
    @State private var msg = ""

    var body: some View {

        VStack(spacing: 18) {

            VStack(spacing: 6) {
                Text("⚙️ Configuración")
                    .font(.title.bold())
                    .foregroundColor(.green)

                Text(Auth.auth().currentUser?.email ?? "")
                    .foregroundColor(.gray)
                    .font(.caption)
            }

            VStack(spacing: 12) {

                Button {
                    abrirWhatsApp()
                } label: {
                    fila(icon: "message.fill", titulo: "Contáctanos")
                }

                Button {
                    msg = """
Términos:

• Datos en Firebase
• Uso educativo
• Responsable el usuario
"""
                    showAlert = true
                } label: {
                    fila(icon: "doc.text.fill", titulo: "Términos")
                }

                // 🔥 BOTÓN QUE ME PEDISTE
                Button {
                    // aquí luego conectas editar categorías
                } label: {
                    fila(icon: "pencil", titulo: "Modificar registros")
                }
            }
            .padding()
            .background(Color.black.opacity(0.25))
            .cornerRadius(16)

            Button {
                logout()
            } label: {
                Text("Cerrar sesión")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(.red)
                    .cornerRadius(12)
            }

            Spacer()
        }
        .padding()
        .background(Color(red: 0.04, green: 0.08, blue: 0.16))
        .alert(msg, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        }
    }

    func fila(icon: String, titulo: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.green)

            Text(titulo)
                .foregroundColor(.white)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }

    func abrirWhatsApp() {
        let numero = "573246538855"
        let mensaje = "Hola soporte"

        if let url = URL(string: "https://wa.me/\(numero)?text=\(mensaje)") {
            UIApplication.shared.open(url)
        }
    }

    func logout() {
        try? Auth.auth().signOut()
    }
}
