import SwiftUI
import FirebaseAuth

struct SettingsView: View {

    var body: some View {
        VStack(spacing: 20) {

            Text("Configuración")
                .foregroundColor(.white)
                .font(.title)

            Button("Cerrar sesión") {
                try? Auth.auth().signOut()
            }
            .foregroundColor(.red)

            Spacer()
        }
        .padding()
        .background(Color(hex: "#0A1628"))
    }
}
