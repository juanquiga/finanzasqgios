import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct HomeView: View {

    @State private var movimientos: [Movimiento] = []
    @State private var periodo  = "Mensual"
    @State private var filtro   = "Todo"
    @State private var nombre   = "Usuario"

    let periodos = ["Diario", "Mensual", "Anual"]

    var movimientosFiltradosPorPeriodo: [Movimiento] {
        let ahora = Calendar.current
        return movimientos.filter { m in
            let fecha = Date(timeIntervalSince1970: m.timestamp / 1000)
            switch periodo {
            case "Diario":
                return ahora.isDateInToday(fecha)
            case "Mensual":
                return ahora.isDate(fecha, equalTo: Date(),
                                    toGranularity: .month)
            default: // Anual
                return ahora.isDate(fecha, equalTo: Date(),
                                    toGranularity: .year)
            }
        }
    }

    var movimientosMostrados: [Movimiento] {
        switch filtro {
        case "Ingresos": return movimientosFiltradosPorPeriodo
            .filter { $0.tipoTransaccion == "Ingreso" }
        case "Egresos":  return movimientosFiltradosPorPeriodo
            .filter { $0.tipoTransaccion == "Egreso" }
        default:         return movimientosFiltradosPorPeriodo
        }
    }

    var totalIngresos: Double {
        movimientosFiltradosPorPeriodo
            .filter { $0.tipoTransaccion == "Ingreso" }.reduce(0) { $0 + $1.valor }
    }
    var totalEgresos: Double {
        movimientosFiltradosPorPeriodo
            .filter { $0.tipoTransaccion == "Egreso" }.reduce(0) { $0 + $1.valor }
    }
    var balance: Double { totalIngresos - totalEgresos }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FinanzasQG 💰")
                            .font(.title2.bold()).foregroundColor(.verdeApp)
                        Text("Hola, \(nombre) 👋")
                            .font(.subheadline).foregroundColor(.grisTexto)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.card)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.borde, lineWidth: 1))

                // Selector período
                HStack(spacing: 8) {
                    ForEach(periodos, id: \.self) { p in
                        Button(p) { periodo = p }
                            .font(.caption.bold())
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(periodo == p
                                ? Color.verdeApp : Color.card)
                            .foregroundColor(periodo == p
                                ? Color(hex: "#050510") : Color.verdeApp)
                            .cornerRadius(10)
                    }
                    Spacer()
                }

                // Filtro Tipo
                HStack(spacing: 8) {
                    ForEach(["Todo", "Ingresos", "Egresos"], id: \.self) { f in
                        Button(f) { filtro = f }
                            .font(.caption)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(filtro == f
                                ? Color.verdeApp : Color.card)
                            .foregroundColor(filtro == f
                                ? Color(hex: "#050510") : Color.verdeApp)
                            .cornerRadius(8)
                    }
                    Spacer()
                }

                // Cards resumen
                HStack(spacing: 10) {
                    if filtro != "Egresos" {
                        cardResumen("📈 Ingresos", totalIngresos, .verdeApp)
                    }
                    if filtro != "Ingresos" {
                        cardResumen("📉 Egresos", totalEgresos, .rojoApp)
                    }
                }

                if filtro == "Todo" {
                    HStack {
                        Text("Balance neto").foregroundColor(.grisTexto)
                        Spacer()
                        Text(formatCOP(balance))
                            .font(.title3.bold())
                            .foregroundColor(balance >= 0 ? .verdeApp : .rojoApp)
                    }
                    .padding()
                    .background(Color.card).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.borde, lineWidth: 1))
                }

                // Lista
                if movimientosMostrados.isEmpty {
                    VStack(spacing: 10) {
                        Text("📭").font(.system(size: 40))
                        Text("Sin movimientos en este período")
                            .foregroundColor(.grisTexto).font(.subheadline)
                    }
                    .frame(maxWidth: .infinity).padding(30)
                    .background(Color.card).cornerRadius(16)
                } else {
                    VStack(spacing: 1) {
                        Text("Movimientos recientes")
                            .font(.caption.bold()).foregroundColor(.grisTexto)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 6)

                        ForEach(movimientosMostrados
                            .sorted { $0.timestamp > $1.timestamp }) { m in
                            itemMovimiento(m)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.fondo.ignoresSafeArea())
        .onAppear { cargarNombre(); cargarMovimientos() }
    }

    func cardResumen(_ titulo: String, _ valor: Double, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo).font(.caption.bold()).foregroundColor(color)
            Text(formatCOP(valor))
                .font(.headline.bold()).foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.card).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borde, lineWidth: 1))
    }

    func itemMovimiento(_ m: Movimiento) -> some View {
        HStack(spacing: 12) {
            Text(m.tipoTransaccion == "Ingreso" ? "📈" : "📉")
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(m.tipoTransaccion == "Ingreso"
                    ? Color(hex: "#1B4332") : Color(hex: "#4A1010"))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 3) {
                Text(m.categoria.isEmpty ? m.tipoTransaccion : m.categoria)
                    .font(.subheadline.bold()).foregroundColor(.white)
                Text(m.detalle.isEmpty ? m.subcategoria : m.detalle)
                    .font(.caption).foregroundColor(.grisTexto)
                Text(formatFecha(m.timestamp))
                    .font(.caption2).foregroundColor(Color.grisTexto.opacity(0.7))
            }

            Spacer()

            Text(formatCOP(m.valor))
                .font(.subheadline.bold())
                .foregroundColor(m.tipoTransaccion == "Ingreso"
                    ? Color(hex: "#69F0AE") : .rojoApp)
        }
        .padding()
        .background(Color.card).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borde, lineWidth: 1))
        .padding(.bottom, 4)
    }

    func cargarNombre() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Database.database().reference().child("users").child(uid)
            .observeSingleEvent(of: .value) { snap in
                let data = snap.value as? [String: Any]
                let n = data?["name"] as? String ?? ""
                nombre = n.isEmpty
                    ? (Auth.auth().currentUser?.email?
                        .components(separatedBy: "@").first ?? "Usuario")
                    : n
            }
    }

    func cargarMovimientos() {
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
