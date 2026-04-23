import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct HomeView: View {

    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var loc   = LocalizationManager.shared

    @State private var movimientos: [Movimiento] = []
    @State private var periodo   = "Mensual"
    @State private var filtro    = "Todo"
    @State private var monedaFiltro = "AMBAS"   // AMBAS | COP | USD
    @State private var nombre    = "Usuario"

    var periodosDisponibles: [(String, String)] {
        [
            ("Diario",  t("resumen.diario")),
            ("Mensual", t("resumen.mensual")),
            ("Anual",   t("resumen.anual"))
        ]
    }

    var filtrosDisponibles: [(String, String)] {
        [
            ("Todo",     t("resumen.todo")),
            ("Ingresos", t("resumen.ingresos")),
            ("Egresos",  t("resumen.egresos"))
        ]
    }

    // Paso 1: filtrar por periodo
    var porPeriodo: [Movimiento] {
        let ahora = Calendar.current
        return movimientos.filter { m in
            let fecha = Date(timeIntervalSince1970: m.timestamp / 1000)
            switch periodo {
            case "Diario":   return ahora.isDateInToday(fecha)
            case "Mensual":  return ahora.isDate(fecha, equalTo: Date(), toGranularity: .month)
            default:         return ahora.isDate(fecha, equalTo: Date(), toGranularity: .year)
            }
        }
    }

    // Paso 2: filtrar por moneda
    var porMoneda: [Movimiento] {
        switch monedaFiltro {
        case "COP": return porPeriodo.filter { $0.moneda == "COP" }
        case "USD": return porPeriodo.filter { $0.moneda == "USD" }
        default:    return porPeriodo
        }
    }

    // Paso 3: filtrar por tipo
    var movimientosMostrados: [Movimiento] {
        switch filtro {
        case "Ingresos": return porMoneda.filter { $0.tipoTransaccion == "Ingreso" }
        case "Egresos":  return porMoneda.filter { $0.tipoTransaccion == "Egreso" }
        default:         return porMoneda
        }
    }

    var totalIngresos: Double {
        porMoneda.filter { $0.tipoTransaccion == "Ingreso" }.reduce(0) { $0 + $1.valor }
    }
    var totalEgresos: Double {
        porMoneda.filter { $0.tipoTransaccion == "Egreso" }.reduce(0) { $0 + $1.valor }
    }
    var balance: Double { totalIngresos - totalEgresos }

    // Moneda a mostrar en los totales (si filtra una sola, usa esa; si AMBAS usa COP)
    var monedaMostrar: String {
        monedaFiltro == "USD" ? "USD" : "COP"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(t("resumen.titulo"))
                            .font(.title2.bold()).foregroundColor(Color.acentoApp)
                        Text("\(t("resumen.hola")), \(nombre) 👋")
                            .font(.subheadline).foregroundColor(Color.textoSecundario)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.cardApp).cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.bordeApp, lineWidth: 1))

                // Selector período
                HStack(spacing: 8) {
                    ForEach(periodosDisponibles, id: \.0) { key, label in
                        Button(label) { periodo = key }
                            .font(.caption.bold())
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(periodo == key ? Color.acentoApp : Color.cardApp)
                            .foregroundColor(periodo == key
                                ? Color(hex: "#050510") : Color.textoSecundario)
                            .cornerRadius(10)
                    }
                    Spacer()
                }

                // Filtro tipo
                HStack(spacing: 8) {
                    ForEach(filtrosDisponibles, id: \.0) { key, label in
                        Button(label) { filtro = key }
                            .font(.caption)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(filtro == key ? Color.acentoApp : Color.cardApp)
                            .foregroundColor(filtro == key
                                ? Color(hex: "#050510") : Color.acentoApp)
                            .cornerRadius(8)
                    }
                    Spacer()
                }

                // Filtro moneda
                HStack(spacing: 8) {
                    ForEach([("AMBAS","🌐 Ambas"),("COP","🇨🇴 COP"),("USD","🇺🇸 USD")],
                            id: \.0) { key, label in
                        Button(label) { monedaFiltro = key }
                            .font(.caption)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(monedaFiltro == key ? Color.acentoApp : Color.cardApp)
                            .foregroundColor(monedaFiltro == key
                                ? Color(hex: "#050510") : Color.acentoApp)
                            .cornerRadius(8)
                    }
                    Spacer()
                }

                // Cards resumen
                HStack(spacing: 10) {
                    if filtro != "Egresos" {
                        cardResumen("📈 \(t("resumen.ingresos"))",
                                    totalIngresos, monedaMostrar, Color.acentoApp)
                    }
                    if filtro != "Ingresos" {
                        cardResumen("📉 \(t("resumen.egresos"))",
                                    totalEgresos, monedaMostrar, Color.rojoFinanzas)
                    }
                }

                if filtro == "Todo" {
                    HStack {
                        Text(t("resumen.balance")).foregroundColor(Color.rojoFinanzas)
                        Spacer()
                        Text(formatValor(balance, moneda: monedaMostrar))
                            .font(.title3.bold())
                            .foregroundColor(balance >= 0 ? Color.acentoApp : Color.rojoFinanzas)
                    }
                    .padding()
                    .background(Color.cardApp).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.bordeApp, lineWidth: 1))
                }

                // Lista
                if movimientosMostrados.isEmpty {
                    VStack(spacing: 10) {
                        Text("📭").font(.system(size: 40))
                        Text(t("resumen.vacio"))
                            .foregroundColor(Color.textoSecundario).font(.subheadline)
                    }
                    .frame(maxWidth: .infinity).padding(30)
                    .background(Color.cardApp).cornerRadius(16)
                } else {
                    VStack(spacing: 1) {
                        Text(t("resumen.recientes"))
                            .font(.caption.bold()).foregroundColor(Color.textoSecundario)
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
        .background(Color.fondoApp.ignoresSafeArea())
        .onAppear { cargarNombre(); cargarMovimientos() }
        .id(loc.idioma)
    }

    func cardResumen(_ titulo: String, _ valor: Double,
                     _ moneda: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo).font(.caption.bold()).foregroundColor(color)
            Text(formatValor(valor, moneda: moneda))
                .font(.headline.bold()).foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.cardApp).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.bordeApp, lineWidth: 1))
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
                    .font(.caption).foregroundColor(Color.textoSecundario)
                Text(formatFecha(m.timestamp))
                    .font(.caption2).foregroundColor(Color.textoSecundario.opacity(0.7))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formatValor(m.valor, moneda: m.moneda))
                    .font(.subheadline.bold())
                    .foregroundColor(m.tipoTransaccion == "Ingreso"
                        ? Color(hex: "#69F0AE") : Color.rojoFinanzas)
                Text(m.moneda)
                    .font(.caption2)
                    .foregroundColor(.textoSecundario)
            }
        }
        .padding()
        .background(Color.cardApp).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bordeApp, lineWidth: 1))
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
                        id:              d["id"]              as? String ?? "",
                        tipoTransaccion: d["tipoTransaccion"] as? String ?? "",
                        detalle:         d["detalle"]         as? String ?? "",
                        categoria:       d["categoria"]       as? String ?? "",
                        subcategoria:    d["subcategoria"]    as? String ?? "",
                        subsubcategoria: d["subsubcategoria"] as? String ?? "",
                        valor:           d["valor"]           as? Double ?? 0,
                        timestamp:       d["timestamp"]       as? Double ?? 0,
                        cuenta:          d["cuenta"]          as? String ?? "",
                        moneda:          d["moneda"]          as? String ?? "COP"
                    ))
                }
                movimientos = temp
            }
    }
}
