import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct GraficasView: View {

    @State private var movimientos: [Movimiento] = []
    @State private var periodo  = "Mensual"
    @State private var filtro   = "Todo"
    @State private var irHistorial = false

    var movimientosPorPeriodo: [Movimiento] {
        let ahora = Calendar.current
        return movimientos.filter { m in
            let fecha = Date(timeIntervalSince1970: m.timestamp / 1000)
            if periodo == "Mensual" {
                return ahora.isDate(fecha, equalTo: Date(), toGranularity: .month)
            } else {
                return ahora.isDate(fecha, equalTo: Date(), toGranularity: .year)
            }
        }
    }

    var movimientosFiltrados: [Movimiento] {
        switch filtro {
        case "Ingresos": return movimientosPorPeriodo.filter { $0.tipoTransaccion == "Ingreso" }
        case "Egresos":  return movimientosPorPeriodo.filter { $0.tipoTransaccion == "Egreso" }
        default:         return movimientosPorPeriodo
        }
    }

    var totalIngresos: Double {
        movimientosFiltrados.filter { $0.tipoTransaccion == "Ingreso" }
            .reduce(0) { $0 + $1.valor }
    }
    var totalEgresos: Double {
        movimientosFiltrados.filter { $0.tipoTransaccion == "Egreso" }
            .reduce(0) { $0 + $1.valor }
    }

    var porCategoria: [(String, Double)] {
        let agrupado = Dictionary(grouping: movimientosFiltrados) { $0.categoria }
        return agrupado.mapValues { $0.reduce(0) { $0 + $1.valor } }
            .sorted { $0.value > $1.value }
            .prefix(6).map { ($0.key, $0.value) }
    }

    let colores: [Color] = [
        Color(hex: "#FF5252"), Color(hex: "#FF9800"), Color(hex: "#2196F3"),
        Color(hex: "#9C27B0"), Color(hex: "#00BCD4"), Color(hex: "#4CAF50")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {

                    // Header
                    Text("📊 Gráficas y Historial")
                        .font(.title2.bold()).foregroundColor(.verdeApp)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.card).cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.borde, lineWidth: 1))

                    // Período
                    HStack(spacing: 8) {
                        ForEach(["Mensual", "Anual"], id: \.self) { p in
                            Button(p) { periodo = p }
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(periodo == p ? Color.verdeApp : Color.card)
                                .foregroundColor(periodo == p
                                    ? Color(hex: "#050510") : Color.verdeApp)
                                .cornerRadius(12)
                        }
                    }

                    // Filtro
                    HStack(spacing: 8) {
                        ForEach(["Todo", "Ingresos", "Egresos"], id: \.self) { f in
                            Button(f) { filtro = f }
                                .font(.caption.bold())
                                .frame(maxWidth: .infinity).padding(.vertical, 8)
                                .background(filtro == f ? Color.verdeApp : Color.card)
                                .foregroundColor(filtro == f
                                    ? Color(hex: "#050510") : Color.verdeApp)
                                .cornerRadius(10)
                        }
                    }

                    // Gráfica de barras
                    VStack(alignment: .leading, spacing: 12) {
                        Text(filtro == "Ingresos" ? "Categorías de Ingreso"
                            : filtro == "Egresos" ? "Categorías de Egreso"
                            : "Por Categoría")
                            .font(.subheadline.bold()).foregroundColor(.white)

                        if porCategoria.isEmpty {
                            Text("Sin datos para este período")
                                .foregroundColor(.grisTexto).font(.caption)
                                .frame(maxWidth: .infinity)
                                .padding(20)
                        } else {
                            graficaBarras
                        }
                    }
                    .padding()
                    .background(Color.card).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.borde, lineWidth: 1))

                    // Gráfica donut
                    VStack(alignment: .leading, spacing: 12) {
                        Text(filtro == "Todo" ? "Ingresos vs Egresos"
                            : filtro == "Ingresos" ? "Distribución de Ingresos"
                            : "Distribución de Egresos")
                            .font(.subheadline.bold()).foregroundColor(.white)
                        graficaDonut
                    }
                    .padding()
                    .background(Color.card).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.borde, lineWidth: 1))

                    // Botón historial
                    Button {
                        irHistorial = true
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("VER HISTORIAL COMPLETO").fontWeight(.bold)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color.card).cornerRadius(14)
                        .foregroundColor(.verdeApp)
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.verdeApp.opacity(0.5), lineWidth: 1))
                    }
                }
                .padding()
            }
            .background(Color.fondo.ignoresSafeArea())
            .navigationDestination(isPresented: $irHistorial) {
                HistorialView()
            }
        }
        .onAppear { cargar() }
    }

    // Barras
    var graficaBarras: some View {
        let maxVal = porCategoria.map { $0.1 }.max() ?? 1
        return VStack(spacing: 8) {
            ForEach(Array(porCategoria.enumerated()), id: \.offset) { i, item in
                HStack(spacing: 10) {
                    Text(item.0)
                        .font(.caption).foregroundColor(.white)
                        .frame(width: 80, alignment: .leading)
                        .lineLimit(1)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.borde).frame(height: 20)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(colores[i % colores.count])
                                .frame(
                                    width: max(8, geo.size.width * CGFloat(item.1 / maxVal)),
                                    height: 20)
                        }
                    }
                    .frame(height: 20)
                    Text(formatCOP(item.1))
                        .font(.caption2).foregroundColor(.white)
                        .frame(width: 70, alignment: .trailing)
                }
            }
        }
    }

    // Donut
    var graficaDonut: some View {
        let total = totalIngresos + totalEgresos
        let angIng = total > 0 ? (totalIngresos / total) * 360 : 180
        let angEgr = 360 - angIng

        return HStack(spacing: 24) {
            ZStack {
                Circle()
                    .trim(from: 0, to: 1)
                    .stroke(Color.borde, lineWidth: 30)
                    .rotationEffect(.degrees(-90))
                Circle()
                    .trim(from: 0, to: CGFloat(angIng / 360))
                    .stroke(Color.verdeApp, style: StrokeStyle(lineWidth: 30, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
                Circle()
                    .trim(from: CGFloat(angIng / 360), to: 1)
                    .stroke(Color.rojoApp, style: StrokeStyle(lineWidth: 30, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text(total > 0 ? "\(Int(totalIngresos / total * 100))%" : "0%")
                        .font(.headline.bold()).foregroundColor(.white)
                    Text("Ing.").font(.caption2).foregroundColor(.grisTexto)
                }
            }
            .frame(width: 120, height: 120)

            VStack(alignment: .leading, spacing: 12) {
                leyenda("Ingresos", formatCOP(totalIngresos), .verdeApp)
                leyenda("Egresos",  formatCOP(totalEgresos),  .rojoApp)
                Divider().background(Color.borde)
                leyenda("Balance", formatCOP(totalIngresos - totalEgresos),
                        totalIngresos >= totalEgresos ? .verdeApp : .rojoApp)
            }
            Spacer()
        }
    }

    func leyenda(_ label: String, _ valor: String, _ color: Color) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).font(.caption).foregroundColor(.grisTexto)
            Spacer()
            Text(valor).font(.caption.bold()).foregroundColor(color)
        }
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
