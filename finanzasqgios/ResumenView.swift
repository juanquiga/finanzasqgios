import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct ResumenView: View {

    @State private var ingresos: Double = 0
    @State private var egresos: Double = 0
    @State private var filtro = "Todo"

    var body: some View {

        VStack(spacing: 20) {

            Text("FinanzasQG 💰")
                .foregroundColor(.green)
                .font(.title2.bold())

            // 🔥 FILTRO
            Picker("Filtro", selection: $filtro) {
                Text("Todo").tag("Todo")
                Text("Ingresos").tag("Ingreso")
                Text("Egresos").tag("Egreso")
            }
            .pickerStyle(.segmented)

            // 🔥 TARJETAS DINÁMICAS
            HStack {

                if filtro == "Todo" || filtro == "Ingreso" {
                    card("Ingresos", ingresos, .green)
                }

                if filtro == "Todo" || filtro == "Egreso" {
                    card("Egresos", egresos, .red)
                }
            }

            // 🔥 BALANCE
            if filtro == "Todo" {
                Text("Balance: \(formato(ingresos - egresos))")
                    .foregroundColor(.white)
                    .font(.title3.bold())
            }

            Spacer()
        }
        .padding()
        .background(Color(hex: "#0A1628"))
        .onAppear {
            cargar()
        }
    }

    // 🔥 TARJETA
    func card(_ title: String, _ value: Double, _ color: Color) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .foregroundColor(color)
                .font(.headline)

            Text(formato(value))
                .foregroundColor(.white)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }

    // 🔥 FORMATO DINERO
    func formato(_ valor: Double) -> String {
        return "$\(Int(valor))"
    }

    // 🔥 FIREBASE
    func cargar() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let ref = Database.database().reference()
            .child("movimientos")
            .child(uid)

        ref.observe(.value) { snapshot in

            var ing: Double = 0
            var egr: Double = 0

            for case let child as DataSnapshot in snapshot.children {

                let data = child.value as? [String: Any] ?? [:]

                let valor = data["valor"] as? Double ?? 0
                let tipo = data["tipoTransaccion"] as? String ?? ""

                if tipo == "Ingreso" {
                    ing += valor
                } else if tipo == "Egreso" {
                    egr += valor
                }
            }

            ingresos = ing
            egresos = egr
        }
    }
}
