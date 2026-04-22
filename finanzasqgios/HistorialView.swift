import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct HistorialView: View {

    @State private var movimientos: [Movimiento] = []
    @State private var busqueda = ""
    @Environment(\.dismiss) var dismiss

    var movimientosFiltrados: [Movimiento] {
        if busqueda.isEmpty { return movimientos }
        return movimientos.filter {
            $0.categoria.localizedCaseInsensitiveContains(busqueda) ||
            $0.detalle.localizedCaseInsensitiveContains(busqueda) ||
            $0.subcategoria.localizedCaseInsensitiveContains(busqueda)
        }
    }

    var body: some View {
        ZStack {
            Color.fondo.ignoresSafeArea()
            VStack(spacing: 0) {

                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.verdeApp).font(.title3)
                    }
                    Spacer()
                    Text("📋 Historial")
                        .font(.title2.bold()).foregroundColor(.verdeApp)
                    Spacer()
                    Text("\(movimientos.count) reg.")
                        .font(.caption).foregroundColor(.grisTexto)
                }
                .padding()

                // Buscador
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.grisTexto)
                    TextField("Buscar categoría o detalle...", text: $busqueda)
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.card).cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borde, lineWidth: 1))
                .padding(.horizontal)
                .padding(.bottom, 10)

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(movimientosFiltrados
                            .sorted { $0.timestamp > $1.timestamp }) { m in
                            itemHistorial(m)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { cargar() }
    }

    func itemHistorial(_ m: Movimiento) -> some View {
        HStack(spacing: 12) {
            Text(m.tipoTransaccion == "Ingreso" ? "📈" : "📉")
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(m.tipoTransaccion == "Ingreso"
                    ? Color(hex: "#1B4332") : Color(hex: "#4A1010"))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 3) {
                Text(m.categoria.isEmpty ? m.tipoTransaccion : m.categoria)
                    .font(.subheadline.bold()).foregroundColor(.white)
                if !m.detalle.isEmpty {
                    Text(m.detalle).font(.caption).foregroundColor(.grisTexto)
                }
                if !m.subcategoria.isEmpty {
                    Text(m.subcategoria)
                        .font(.caption2).foregroundColor(Color.grisTexto.opacity(0.7))
                }
                // Fecha Y HORA del registro
                Text(formatFecha(m.timestamp))
                    .font(.caption2).foregroundColor(Color.grisTexto.opacity(0.6))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formatCOP(m.valor))
                    .font(.subheadline.bold())
                    .foregroundColor(m.tipoTransaccion == "Ingreso"
                        ? Color(hex: "#69F0AE") : .rojoApp)
                if !m.cuenta.isEmpty {
                    Text(m.cuenta).font(.caption2).foregroundColor(.grisTexto)
                }
            }
        }
        .padding()
        .background(Color.card).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borde, lineWidth: 1))
    }

    func cargar() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Database.database().reference().child("movimientos").child(uid)
            .observe(.value) { snap in
                var temp: [Movimiento] = []
                for case let child as DataSnapshot in snap.children {
                    let d = child.value as? [String: Any] ?? [:]
                    temp.append(Movimiento(
                        id: d["id"] as? String ?? "",
                        tipoTransaccion: d["tipoTransaccion"] as? String ?? "",
                        detalle: d["detalle"] as? String ?? "",
                        categoria: d["categoria"] as? String ?? "",
                        subcategoria: d["subcategoria"] as? String ?? "",
                        valor: d["valor"] as? Double ?? 0,
                        timestamp: d["timestamp"] as? Double ?? 0,
                        cuenta: d["cuenta"] as? String ?? ""
                    ))
                }
                movimientos = temp
            }
    }
}
