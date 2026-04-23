import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct GraficasView: View {

    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var loc   = LocalizationManager.shared
    @State private var movimientos: [Movimiento] = []
    @State private var periodo      = "Mensual"
    @State private var filtro       = "Todo"
    @State private var monedaFiltro = "AMBAS"    // AMBAS | COP | USD
    @State private var irHistorial  = false

    // Paso 1: periodo
    var porPeriodo: [Movimiento] {
        let ahora = Calendar.current
        return movimientos.filter { m in
            let fecha = Date(timeIntervalSince1970: m.timestamp / 1000)
            return periodo == "Mensual"
                ? ahora.isDate(fecha, equalTo: Date(), toGranularity: .month)
                : ahora.isDate(fecha, equalTo: Date(), toGranularity: .year)
        }
    }

    // Paso 2: moneda
    var porMoneda: [Movimiento] {
        switch monedaFiltro {
        case "COP": return porPeriodo.filter { $0.moneda == "COP" }
        case "USD": return porPeriodo.filter { $0.moneda == "USD" }
        default:    return porPeriodo
        }
    }

    // Paso 3: tipo
    var movimientosFiltrados: [Movimiento] {
        switch filtro {
        case "Ingresos":       return porMoneda.filter { $0.tipoTransaccion == "Ingreso" }
        case "Egresos":        return porMoneda.filter { $0.tipoTransaccion == "Egreso" }
        case "Transferencias": return porMoneda.filter { $0.tipoTransaccion == "Transferencia" }
        default:               return porMoneda
        }
    }

    var totalIngresos: Double {
        porMoneda.filter { $0.tipoTransaccion == "Ingreso" }.reduce(0) { $0 + $1.valor }
    }
    var totalEgresos: Double {
        porMoneda.filter { $0.tipoTransaccion == "Egreso" }.reduce(0) { $0 + $1.valor }
    }
    var totalTransferencias: Double {
        porMoneda.filter { $0.tipoTransaccion == "Transferencia" }.reduce(0) { $0 + $1.valor }
    }

    var porCategoria: [(String, Double)] {
        let agrupado = Dictionary(grouping: movimientosFiltrados) { $0.categoria }
        return agrupado.mapValues { $0.reduce(0) { $0 + $1.valor } }
            .sorted { $0.value > $1.value }
            .prefix(6).map { ($0.key, $0.value) }
    }

    // Moneda para formatear totales
    var monedaMostrar: String { monedaFiltro == "USD" ? "USD" : "COP" }

    let colores: [Color] = [
        Color(hex: "#FF5252"), Color(hex: "#FF9800"), Color(hex: "#2196F3"),
        Color(hex: "#9C27B0"), Color(hex: "#00BCD4"), Color(hex: "#4CAF50")
    ]

    var filtrosDisponibles: [(String, String)] {
        [
            ("Todo",           t("graficas.todo")),
            ("Ingresos",       t("graficas.ingresos")),
            ("Egresos",        t("graficas.egresos")),
            ("Transferencias", t("graficas.transferencias"))
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {

                    // Header
                    Text(t("graficas.titulo"))
                        .font(Font.title2.bold()).foregroundColor(.acentoApp)
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.cardApp).cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.bordeApp, lineWidth: 1))

                    // Período
                    HStack(spacing: 8) {
                        ForEach(["Mensual","Anual"], id: \.self) { p in
                            Button(p == "Mensual"
                                   ? t("graficas.mensual") : t("graficas.anual")) {
                                periodo = p
                            }
                            .font(Font.subheadline.bold())
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(periodo == p ? Color.acentoApp : Color.cardApp)
                            .foregroundColor(periodo == p
                                ? Color(hex: "#050510") : Color.acentoApp)
                            .cornerRadius(12)
                        }
                    }

                    // Filtro tipo
                    LazyVGrid(columns: [
                        GridItem(.flexible()), GridItem(.flexible()),
                        GridItem(.flexible()), GridItem(.flexible())
                    ], spacing: 6) {
                        ForEach(filtrosDisponibles, id: \.0) { key, label in
                            Button(label) { filtro = key }
                                .font(Font.caption.bold())
                                .frame(maxWidth: .infinity).padding(.vertical, 8)
                                .background(filtro == key ? Color.acentoApp : Color.cardApp)
                                .foregroundColor(filtro == key
                                    ? Color(hex: "#050510") : Color.acentoApp)
                                .cornerRadius(10)
                        }
                    }

                    // Filtro moneda
                    HStack(spacing: 8) {
                        ForEach([("AMBAS","🌐 Ambas"),("COP","🇨🇴 COP"),("USD","🇺🇸 USD")],
                                id: \.0) { key, label in
                            Button(label) { monedaFiltro = key }
                                .font(Font.caption.bold())
                                .frame(maxWidth: .infinity).padding(.vertical, 8)
                                .background(monedaFiltro == key ? Color.acentoApp : Color.cardApp)
                                .foregroundColor(monedaFiltro == key
                                    ? Color(hex: "#050510") : Color.acentoApp)
                                .cornerRadius(10)
                        }
                    }

                    // Gráfica barras
                    VStack(alignment: .leading, spacing: 12) {
                        Text(tituloBarras)
                            .font(Font.subheadline.bold()).foregroundColor(.textoPrincipal)

                        if porCategoria.isEmpty {
                            Text(t("graficas.sin_datos"))
                                .foregroundColor(.textoSecundario).font(Font.caption)
                                .frame(maxWidth: .infinity).padding(20)
                        } else {
                            graficaBarras
                        }
                    }
                    .padding()
                    .background(Color.cardApp).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.bordeApp, lineWidth: 1))

                    // Gráfica donut
                    VStack(alignment: .leading, spacing: 12) {
                        Text(tituloDonut)
                            .font(Font.subheadline.bold()).foregroundColor(.textoPrincipal)
                        graficaDonut
                    }
                    .padding()
                    .background(Color.cardApp).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.bordeApp, lineWidth: 1))

                    // Botón historial
                    Button { irHistorial = true } label: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text(t("graficas.historial")).fontWeight(.bold)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color.cardApp).cornerRadius(14)
                        .foregroundColor(.acentoApp)
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.acentoApp.opacity(0.5), lineWidth: 1))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
            }
            .background(Color.fondoApp.ignoresSafeArea())
            .navigationDestination(isPresented: $irHistorial) { HistorialView() }
        }
        .preferredColorScheme(theme.temaOscuro ? .dark : .light)
        .id(loc.idioma)
        .onAppear { cargar() }
    }

    // MARK: - Títulos
    var tituloBarras: String {
        switch filtro {
        case "Ingresos":       return t("graficas.ingresos")
        case "Egresos":        return t("graficas.egresos")
        case "Transferencias": return t("graficas.transferencias")
        default:               return t("graficas.por_categoria")
        }
    }
    var tituloDonut: String {
        switch filtro {
        case "Ingresos":       return t("graficas.ingreso_porc")
        case "Egresos":        return t("graficas.egreso_porc")
        case "Transferencias": return t("graficas.transferencias")
        default:               return t("graficas.vs")
        }
    }

    // MARK: - Gráfica barras
    var graficaBarras: some View {
        let maxVal = porCategoria.map { $0.1 }.max() ?? 1
        return VStack(spacing: 10) {
            ForEach(Array(porCategoria.enumerated()), id: \.offset) { i, item in
                HStack(spacing: 10) {
                    Text(item.0)
                        .font(Font.caption).foregroundColor(.textoPrincipal)
                        .frame(width: 80, alignment: .leading).lineLimit(1)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.bordeApp).frame(height: 18)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(colores[i % colores.count])
                                .frame(width: max(8, geo.size.width
                                    * CGFloat(item.1 / maxVal)), height: 18)
                        }
                    }
                    .frame(height: 18)
                    Text(formatValor(item.1, moneda: monedaMostrar))
                        .font(Font.caption2).foregroundColor(.textoPrincipal)
                        .frame(width: 80, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Gráfica donut
    var graficaDonut: some View {
        let total = totalIngresos + totalEgresos + totalTransferencias

        let (porcIng, porcEgr, porcTra): (Double, Double, Double) = {
            switch filtro {
            case "Ingresos":
                return (total > 0 ? totalIngresos/total : 0, 0, 0)
            case "Egresos":
                return (0, total > 0 ? totalEgresos/total : 0, 0)
            case "Transferencias":
                return (0, 0, total > 0 ? totalTransferencias/total : 0)
            default:
                guard total > 0 else { return (1.0/3, 1.0/3, 1.0/3) }
                return (totalIngresos/total, totalEgresos/total,
                        totalTransferencias/total)
            }
        }()

        return HStack(spacing: 20) {
            ZStack {
                Circle().trim(from: 0, to: 1)
                    .stroke(Color.bordeApp, lineWidth: 24)
                    .rotationEffect(.degrees(-90))
                if porcIng > 0 {
                    Circle().trim(from: 0, to: CGFloat(porcIng))
                        .stroke(Color.verdeFinanzas,
                                style: StrokeStyle(lineWidth: 24, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                }
                if porcEgr > 0 {
                    Circle()
                        .trim(from: CGFloat(porcIng),
                              to: CGFloat(porcIng + porcEgr))
                        .stroke(Color.rojoFinanzas,
                                style: StrokeStyle(lineWidth: 24, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                }
                if porcTra > 0 {
                    Circle()
                        .trim(from: CGFloat(porcIng + porcEgr),
                              to: CGFloat(porcIng + porcEgr + porcTra))
                        .stroke(Color(hex: "#2196F3"),
                                style: StrokeStyle(lineWidth: 24, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                }
                VStack(spacing: 2) {
                    switch filtro {
                    case "Ingresos":
                        Text("\(Int(porcIng * 100))%")
                            .font(Font.headline.bold()).foregroundColor(.textoPrincipal)
                        Text(t("graficas.ingresos"))
                            .font(Font.caption2).foregroundColor(.textoSecundario)
                    case "Egresos":
                        Text("\(Int(porcEgr * 100))%")
                            .font(Font.headline.bold()).foregroundColor(.textoPrincipal)
                        Text(t("graficas.egresos"))
                            .font(Font.caption2).foregroundColor(.textoSecundario)
                    case "Transferencias":
                        Text("\(Int(porcTra * 100))%")
                            .font(Font.headline.bold()).foregroundColor(.textoPrincipal)
                        Text(t("graficas.transferencias"))
                            .font(Font.caption2).foregroundColor(.textoSecundario)
                    default:
                        VStack(spacing: 1) {
                            Text("\(Int(porcIng * 100))%")
                                .font(Font.caption.bold())
                                .foregroundColor(Color.verdeFinanzas)
                            Text("\(Int(porcEgr * 100))%")
                                .font(Font.caption.bold())
                                .foregroundColor(Color.rojoFinanzas)
                        }
                    }
                }
            }
            .frame(width: 100, height: 100)

            // Leyenda
            VStack(alignment: .leading, spacing: 10) {
                leyenda(t("graficas.ingresos"),
                        formatValor(totalIngresos, moneda: monedaMostrar),
                        Color.verdeFinanzas)
                leyenda(t("graficas.egresos"),
                        formatValor(totalEgresos, moneda: monedaMostrar),
                        Color.rojoFinanzas)
                if totalTransferencias > 0 {
                    leyenda(t("graficas.transferencias"),
                            formatValor(totalTransferencias, moneda: monedaMostrar),
                            Color(hex: "#2196F3"))
                }
                Divider().background(Color.bordeApp)
                let balance = totalIngresos - totalEgresos
                leyenda("Balance",
                        formatValor(balance, moneda: monedaMostrar),
                        balance >= 0 ? Color.verdeFinanzas : Color.rojoFinanzas)
            }
            Spacer()
        }
    }

    func leyenda(_ label: String, _ valor: String, _ color: Color) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).font(Font.caption).foregroundColor(.textoSecundario)
            Spacer()
            Text(valor).font(Font.caption.bold()).foregroundColor(color)
        }
    }

    // MARK: - Firebase
    func cargar() {
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
