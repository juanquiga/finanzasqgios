import SwiftUI
import FirebaseAuth
import FirebaseDatabase

// Estructura para presupuesto jerárquico
struct ItemPresupuesto {
    let nivel    : Int
    let nombre   : String
    let gastado  : Double
    let maximo   : Double
    var porcentaje: Double { maximo > 0 ? min(gastado / maximo, 1.5) : 0 }
    var colorItem: Color {
        if porcentaje < 0.6  { return Color(hex: "#4CAF50") }
        if porcentaje < 0.85 { return Color(hex: "#FF9800") }
        return Color(hex: "#FF5252")
    }
}

struct GraficasView: View {

    @ObservedObject var theme  = ThemeManager.shared
    @ObservedObject var loc    = LocalizationManager.shared
    @StateObject private var config = ConfigManager.shared
    @State private var movimientos : [Movimiento] = []
    @State private var periodo      = "Mensual"
    @State private var filtro       = "Todo"
    @State private var monedaFiltro = "AMBAS"
    @State private var irHistorial  = false

    // MARK: - Filtros
    var porPeriodo: [Movimiento] {
        let ahora = Calendar.current
        return movimientos.filter { m in
            let fecha = Date(timeIntervalSince1970: m.timestamp / 1000)
            return periodo == "Mensual"
                ? ahora.isDate(fecha, equalTo: Date(), toGranularity: .month)
                : ahora.isDate(fecha, equalTo: Date(), toGranularity: .year)
        }
    }
    var porMoneda: [Movimiento] {
        switch monedaFiltro {
        case "COP": return porPeriodo.filter { $0.moneda == "COP" }
        case "USD": return porPeriodo.filter { $0.moneda == "USD" }
        default:    return porPeriodo
        }
    }
    var movimientosFiltrados: [Movimiento] {
        switch filtro {
        case "Ingresos":       return porMoneda.filter { $0.tipoTransaccion == "Ingreso" }
        case "Egresos":        return porMoneda.filter { $0.tipoTransaccion == "Egreso" }
        case "Transferencias": return porMoneda.filter { $0.tipoTransaccion == "Transferencia" }
        default:               return porMoneda
        }
    }
    var totalIngresos     : Double { porMoneda.filter { $0.tipoTransaccion == "Ingreso"        }.reduce(0) { $0 + $1.valor } }
    var totalEgresos      : Double { porMoneda.filter { $0.tipoTransaccion == "Egreso"         }.reduce(0) { $0 + $1.valor } }
    var totalTransferencias: Double { porMoneda.filter { $0.tipoTransaccion == "Transferencia" }.reduce(0) { $0 + $1.valor } }

    var porCategoria: [(String, Double)] {
        let ag = Dictionary(grouping: movimientosFiltrados) { $0.categoria }
        return ag.mapValues { $0.reduce(0) { $0 + $1.valor } }
            .sorted { $0.value > $1.value }.prefix(6).map { ($0.key, $0.value) }
    }

    var monMostrar: String { monedaFiltro == "USD" ? "USD" : "COP" }

    // MARK: - Presupuesto general
    var presupuestoMax: Double {
        monedaFiltro == "USD" ? config.presupuestoMaxUSD : config.presupuestoMaxCOP
    }
    var porcentajeGeneral: Double {
        guard presupuestoMax > 0 else { return 0 }
        return min(totalEgresos / presupuestoMax, 1.5)
    }
    var colorGeneral: Color {
        if porcentajeGeneral < 0.6  { return Color(hex: "#4CAF50") }
        if porcentajeGeneral < 0.85 { return Color(hex: "#FF9800") }
        return Color(hex: "#FF5252")
    }

    // MARK: - Items presupuesto jerárquico
    var itemsPresupuesto: [ItemPresupuesto] {
        var result: [ItemPresupuesto] = []
        for cat in config.egresosTree where cat.presupuestoTotal > 0 {
            let gastadoCat = porMoneda
                .filter { $0.tipoTransaccion == "Egreso" && $0.categoria == cat.nombre }
                .reduce(0) { $0 + $1.valor }
            result.append(ItemPresupuesto(nivel: 0, nombre: cat.nombre,
                                          gastado: gastadoCat, maximo: cat.presupuestoTotal))
            for sub in cat.subcategorias where sub.presupuestoTotal > 0 {
                let gastadoSub = porMoneda
                    .filter { $0.tipoTransaccion == "Egreso"
                        && $0.categoria == cat.nombre
                        && $0.subcategoria == sub.nombre }
                    .reduce(0) { $0 + $1.valor }
                result.append(ItemPresupuesto(nivel: 1, nombre: "  ↳ \(sub.nombre)",
                                              gastado: gastadoSub, maximo: sub.presupuestoTotal))
                for ssub in sub.subsubcategorias where ssub.presupuesto > 0 {
                    let gastadoSsub = porMoneda
                        .filter { $0.tipoTransaccion == "Egreso"
                            && $0.categoria == cat.nombre
                            && $0.subcategoria == sub.nombre
                            && $0.subsubcategoria == ssub.nombre }
                        .reduce(0) { $0 + $1.valor }
                    result.append(ItemPresupuesto(nivel: 2, nombre: "     ↳ \(ssub.nombre)",
                                                  gastado: gastadoSsub, maximo: ssub.presupuesto))
                }
            }
        }
        return result
    }

    // MARK: - Tabla cuentas
    struct ResumenCuenta {
        let nombre   : String
        var ingresos : Double = 0
        var egresos  : Double = 0
        var enviadas : Double = 0
        var recibidas: Double = 0
        var actividad: Double { ingresos + egresos + enviadas + recibidas }
        var balance  : Double { ingresos - egresos }
    }

    var tablaCuentas: [ResumenCuenta] {
        var mapa: [String: ResumenCuenta] = [:]
        for cta in config.cuentas { mapa[cta] = ResumenCuenta(nombre: cta) }
        for m in porMoneda {
            switch m.tipoTransaccion {
            case "Ingreso":
                if !m.cuenta.isEmpty {
                    mapa[m.cuenta, default: ResumenCuenta(nombre: m.cuenta)].ingresos += m.valor
                }
            case "Egreso":
                if !m.cuenta.isEmpty {
                    mapa[m.cuenta, default: ResumenCuenta(nombre: m.cuenta)].egresos += m.valor
                }
            case "Transferencia":
                if !m.cuentaOrigen.isEmpty {
                    mapa[m.cuentaOrigen, default: ResumenCuenta(nombre: m.cuentaOrigen)].enviadas += m.valor
                }
                let dest = m.cuentaDestino.isEmpty ? m.cuenta : m.cuentaDestino
                if !dest.isEmpty {
                    mapa[dest, default: ResumenCuenta(nombre: dest)].recibidas += m.valor
                }
            default: break
            }
        }
        return mapa.values.filter { $0.actividad > 0 }.sorted { $0.actividad > $1.actividad }
    }

    let colores: [Color] = [
        Color(hex: "#FF5252"), Color(hex: "#FF9800"), Color(hex: "#2196F3"),
        Color(hex: "#9C27B0"), Color(hex: "#00BCD4"), Color(hex: "#4CAF50")
    ]

    var filtrosDisponibles: [(String, String)] {
        [("Todo",          t("graficas.todo")),
         ("Ingresos",      t("graficas.ingresos")),
         ("Egresos",       t("graficas.egresos")),
         ("Transferencias",t("graficas.transferencias"))]
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {

                    // Header
                    Text(t("graficas.titulo"))
                        .font(Font.title2.bold()).foregroundColor(.acentoApp)
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.cardApp).cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.bordeApp, lineWidth: 1))

                    // Período
                    HStack(spacing: 8) {
                        ForEach(["Mensual","Anual"], id: \.self) { p in
                            Button(p == "Mensual" ? t("graficas.mensual") : t("graficas.anual")) {
                                periodo = p
                            }
                            .font(Font.subheadline.bold()).frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(periodo == p ? Color.acentoApp : Color.cardApp)
                            .foregroundColor(periodo == p ? Color(hex: "#050510") : Color.acentoApp)
                            .cornerRadius(12)
                        }
                    }

                    // Filtro tipo
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 6) {
                        ForEach(filtrosDisponibles, id: \.0) { key, label in
                            Button(label) { filtro = key }
                                .font(Font.caption.bold()).frame(maxWidth: .infinity).padding(.vertical, 8)
                                .background(filtro == key ? Color.acentoApp : Color.cardApp)
                                .foregroundColor(filtro == key ? Color(hex: "#050510") : Color.acentoApp)
                                .cornerRadius(10)
                        }
                    }

                    // Filtro moneda
                    HStack(spacing: 8) {
                        ForEach([("AMBAS","🌐 Ambas"),("COP","🇨🇴 COP"),("USD","🇺🇸 USD")], id: \.0) { key, label in
                            Button(label) { monedaFiltro = key }
                                .font(Font.caption.bold()).frame(maxWidth: .infinity).padding(.vertical, 8)
                                .background(monedaFiltro == key ? Color.acentoApp : Color.cardApp)
                                .foregroundColor(monedaFiltro == key ? Color(hex: "#050510") : Color.acentoApp)
                                .cornerRadius(10)
                        }
                    }

                    // Presupuesto general
                    if presupuestoMax > 0 { presupuestoGeneralCard }

                    // Presupuesto jerárquico
                    if !itemsPresupuesto.isEmpty { presupuestoCategoriaCard }

                    // Gráfica barras
                    VStack(alignment: .leading, spacing: 12) {
                        Text(tituloBarras).font(Font.subheadline.bold()).foregroundColor(.textoPrincipal)
                        if porCategoria.isEmpty {
                            Text(t("graficas.sin_datos"))
                                .foregroundColor(.textoSecundario).font(Font.caption)
                                .frame(maxWidth: .infinity).padding(20)
                        } else {
                            graficaBarras
                        }
                    }
                    .padding().background(Color.cardApp).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.bordeApp, lineWidth: 1))

                    // Gráfica donut
                    VStack(alignment: .leading, spacing: 12) {
                        Text(tituloDonut).font(Font.subheadline.bold()).foregroundColor(.textoPrincipal)
                        graficaDonut
                    }
                    .padding().background(Color.cardApp).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.bordeApp, lineWidth: 1))

                    // Tabla cuentas
                    if !tablaCuentas.isEmpty { tablaCuentasCard }

                    // Historial
                    Button { irHistorial = true } label: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text(t("graficas.historial")).fontWeight(.bold)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding().background(Color.cardApp).cornerRadius(14).foregroundColor(.acentoApp)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.acentoApp.opacity(0.5), lineWidth: 1))
                    }
                }
                .padding()
            }
            .background(Color.fondoApp.ignoresSafeArea())
            .navigationDestination(isPresented: $irHistorial) { HistorialView() }
        }
        .preferredColorScheme(theme.temaOscuro ? .dark : .light)
        .id(loc.idioma)
        .onAppear {
            cargar()
            if config.egresosTree.isEmpty { config.cargar() }
        }
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

    // MARK: - Presupuesto General Card
    var presupuestoGeneralCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gauge.with.needle.fill").foregroundColor(.acentoApp)
                Text("💳 Gastos del mes — General")
                    .font(Font.subheadline.bold()).foregroundColor(.textoPrincipal)
                Spacer()
                Text(monedaFiltro == "USD" ? "🇺🇸 USD" : "🇨🇴 COP")
                    .font(Font.caption2).foregroundColor(.textoSecundario)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8).fill(Color.bordeApp).frame(height: 20)
                    RoundedRectangle(cornerRadius: 8).fill(colorGeneral)
                        .frame(width: max(4, geo.size.width * CGFloat(min(porcentajeGeneral, 1))), height: 20)
                        .animation(.easeInOut(duration: 0.6), value: porcentajeGeneral)
                }
            }
            .frame(height: 20)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gastado").font(Font.caption2).foregroundColor(.textoSecundario)
                    Text(formatValor(totalEgresos, moneda: monMostrar))
                        .font(Font.subheadline.bold()).foregroundColor(colorGeneral)
                }
                Spacer()
                VStack(alignment: .center, spacing: 2) {
                    Text("\(Int(min(porcentajeGeneral, 1.5) * 100))%")
                        .font(Font.title3.bold()).foregroundColor(colorGeneral)
                    Text(porcentajeGeneral >= 1 ? "🚨 Superado"
                         : porcentajeGeneral >= 0.85 ? "⚠️ Casi límite" : "✅ Bien")
                        .font(Font.caption2).foregroundColor(colorGeneral)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Máximo").font(Font.caption2).foregroundColor(.textoSecundario)
                    Text(formatValor(presupuestoMax, moneda: monMostrar))
                        .font(Font.subheadline.bold()).foregroundColor(.textoPrincipal)
                }
            }
            let disponible = presupuestoMax - totalEgresos
            HStack {
                Text(disponible >= 0 ? "💚 Disponible:" : "🔴 Exceso:")
                    .font(Font.caption).foregroundColor(.textoSecundario)
                Text(formatValor(abs(disponible), moneda: monMostrar))
                    .font(Font.caption.bold())
                    .foregroundColor(disponible >= 0 ? Color(hex: "#4CAF50") : Color(hex: "#FF5252"))
                Spacer()
            }
        }
        .padding().background(Color.cardApp).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(colorGeneral.opacity(0.5), lineWidth: 1.5))
    }

    // MARK: - Presupuesto Categoría Card (jerárquico)
    var presupuestoCategoriaCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "tag.fill").foregroundColor(Color(hex: "#FF9800"))
                Text("📊 Presupuesto por categoría")
                    .font(Font.subheadline.bold()).foregroundColor(.textoPrincipal)
            }
            ForEach(Array(itemsPresupuesto.enumerated()), id: \.offset) { idx, item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.nombre)
                            .font(item.nivel == 0 ? Font.subheadline.bold() : Font.caption)
                            .foregroundColor(item.nivel == 0 ? Color.textoPrincipal : Color.textoSecundario)
                        Spacer()
                        Text("\(Int(item.porcentaje * 100))%")
                            .font(item.nivel == 0 ? Font.subheadline.bold() : Font.caption.bold())
                            .foregroundColor(item.colorItem)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.bordeApp)
                                .frame(height: item.nivel == 0 ? 14 : 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.colorItem)
                                .frame(width: max(4, geo.size.width * CGFloat(min(item.porcentaje, 1))),
                                       height: item.nivel == 0 ? 14 : 8)
                                .animation(.easeInOut(duration: 0.5), value: item.porcentaje)
                        }
                    }
                    .frame(height: item.nivel == 0 ? 14 : 8)
                    HStack {
                        Text(formatCOP(item.gastado)).font(Font.caption2).foregroundColor(item.colorItem)
                        Text("de \(formatCOP(item.maximo))")
                            .font(Font.caption2).foregroundColor(.textoSecundario)
                        Spacer()
                        let disp = item.maximo - item.gastado
                        Text(disp >= 0 ? "Disp: \(formatCOP(disp))" : "Exceso: \(formatCOP(abs(disp)))")
                            .font(Font.caption2)
                            .foregroundColor(disp >= 0 ? Color(hex: "#4CAF50") : Color(hex: "#FF5252"))
                    }
                }
                .padding(item.nivel == 0 ? 10 : 8)
                .background(item.nivel == 0 ? Color.inputFondo : Color.inputFondo.opacity(0.6))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(item.colorItem.opacity(item.nivel == 0 ? 0.3 : 0.15), lineWidth: 1))
            }
        }
        .padding().background(Color.cardApp).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(Color(hex: "#FF9800").opacity(0.4), lineWidth: 1.5))
    }

    // MARK: - Tabla Cuentas
    var tablaCuentasCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "building.columns.fill").foregroundColor(.acentoApp)
                Text("🏦 Registro de cuentas")
                    .font(Font.subheadline.bold()).foregroundColor(.textoPrincipal)
                Spacer()
                Text("Por actividad").font(Font.caption2).foregroundColor(.textoSecundario)
            }
            HStack {
                Text("Cuenta").font(Font.caption.bold()).foregroundColor(.textoSecundario)
                    .frame(width: 80, alignment: .leading)
                Spacer()
                Text("Ing.").font(Font.caption.bold()).foregroundColor(Color(hex: "#4CAF50")).frame(width: 58, alignment: .trailing)
                Text("Egr.").font(Font.caption.bold()).foregroundColor(Color(hex: "#FF5252")).frame(width: 58, alignment: .trailing)
                Text("Trsf.").font(Font.caption.bold()).foregroundColor(Color(hex: "#2196F3")).frame(width: 58, alignment: .trailing)
            }
            .padding(.horizontal, 8).padding(.vertical, 6)
            .background(Color.inputFondo).cornerRadius(8)

            ForEach(Array(tablaCuentas.enumerated()), id: \.offset) { i, cta in
                VStack(spacing: 4) {
                    HStack {
                        HStack(spacing: 4) {
                            Text(i == 0 ? "🥇" : i == 1 ? "🥈" : i == 2 ? "🥉" : "  ")
                                .font(Font.caption)
                            Text(cta.nombre).font(Font.caption.bold())
                                .foregroundColor(.textoPrincipal).lineLimit(1)
                        }
                        .frame(width: 84, alignment: .leading)
                        Spacer()
                        Text(formatValor(cta.ingresos,  moneda: monMostrar)).font(Font.caption2).foregroundColor(Color(hex: "#4CAF50")).frame(width: 58, alignment: .trailing)
                        Text(formatValor(cta.egresos,   moneda: monMostrar)).font(Font.caption2).foregroundColor(Color(hex: "#FF5252")).frame(width: 58, alignment: .trailing)
                        Text(formatValor(cta.enviadas + cta.recibidas, moneda: monMostrar)).font(Font.caption2).foregroundColor(Color(hex: "#2196F3")).frame(width: 58, alignment: .trailing)
                    }
                    if cta.enviadas > 0 || cta.recibidas > 0 {
                        HStack {
                            Text("").frame(width: 84); Spacer()
                            if cta.enviadas  > 0 { Text("↑ \(formatValor(cta.enviadas,  moneda: monMostrar))").font(Font.caption2).foregroundColor(Color(hex: "#FF5252").opacity(0.7)) }
                            if cta.recibidas > 0 { Text("↓ \(formatValor(cta.recibidas, moneda: monMostrar))").font(Font.caption2).foregroundColor(Color(hex: "#4CAF50").opacity(0.7)) }
                        }
                    }
                    HStack {
                        Text("Balance:").font(Font.caption2).foregroundColor(.textoSecundario).frame(width: 84, alignment: .leading)
                        Spacer()
                        Text(formatValor(cta.balance, moneda: monMostrar)).font(Font.caption2.bold())
                            .foregroundColor(cta.balance >= 0 ? Color(hex: "#4CAF50") : Color(hex: "#FF5252"))
                    }
                    if i < tablaCuentas.count - 1 { Divider().background(Color.bordeApp) }
                }
            }
        }
        .padding().background(Color.cardApp).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.bordeApp, lineWidth: 1))
    }

    // MARK: - Gráfica barras
    var graficaBarras: some View {
        let maxVal = porCategoria.map { $0.1 }.max() ?? 1
        return VStack(spacing: 10) {
            ForEach(Array(porCategoria.enumerated()), id: \.offset) { i, item in
                HStack(spacing: 10) {
                    Text(item.0).font(Font.caption).foregroundColor(.textoPrincipal)
                        .frame(width: 80, alignment: .leading).lineLimit(1)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6).fill(Color.bordeApp).frame(height: 18)
                            RoundedRectangle(cornerRadius: 6).fill(colores[i % colores.count])
                                .frame(width: max(8, geo.size.width * CGFloat(item.1 / maxVal)), height: 18)
                        }
                    }
                    .frame(height: 18)
                    Text(formatValor(item.1, moneda: monMostrar))
                        .font(Font.caption2).foregroundColor(.textoPrincipal).frame(width: 80, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Gráfica donut
    var graficaDonut: some View {
        let total = totalIngresos + totalEgresos + totalTransferencias
        let (pI, pE, pT): (Double, Double, Double) = {
            switch filtro {
            case "Ingresos":       return (total > 0 ? totalIngresos/total : 0, 0, 0)
            case "Egresos":        return (0, total > 0 ? totalEgresos/total : 0, 0)
            case "Transferencias": return (0, 0, total > 0 ? totalTransferencias/total : 0)
            default:
                guard total > 0 else { return (1.0/3, 1.0/3, 1.0/3) }
                return (totalIngresos/total, totalEgresos/total, totalTransferencias/total)
            }
        }()
        return HStack(spacing: 20) {
            ZStack {
                Circle().trim(from: 0, to: 1)
                    .stroke(Color.bordeApp, lineWidth: 22).rotationEffect(.degrees(-90))
                if pI > 0 {
                    Circle().trim(from: 0, to: CGFloat(pI))
                        .stroke(Color(hex: "#4CAF50"), style: StrokeStyle(lineWidth: 22, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                }
                if pE > 0 {
                    Circle().trim(from: CGFloat(pI), to: CGFloat(pI + pE))
                        .stroke(Color(hex: "#FF5252"), style: StrokeStyle(lineWidth: 22, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                }
                if pT > 0 {
                    Circle().trim(from: CGFloat(pI + pE), to: CGFloat(pI + pE + pT))
                        .stroke(Color(hex: "#2196F3"), style: StrokeStyle(lineWidth: 22, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                }
                VStack(spacing: 1) {
                    switch filtro {
                    case "Egresos":
                        Text("\(Int(pE*100))%").font(Font.headline.bold()).foregroundColor(.textoPrincipal)
                        Text(t("graficas.egresos")).font(Font.caption2).foregroundColor(.textoSecundario)
                    case "Ingresos":
                        Text("\(Int(pI*100))%").font(Font.headline.bold()).foregroundColor(.textoPrincipal)
                        Text(t("graficas.ingresos")).font(Font.caption2).foregroundColor(.textoSecundario)
                    case "Transferencias":
                        Text("\(Int(pT*100))%").font(Font.headline.bold()).foregroundColor(.textoPrincipal)
                        Text(t("graficas.transferencias")).font(Font.caption2).foregroundColor(.textoSecundario)
                    default:
                        Text("\(Int(pI*100))%").font(Font.caption.bold()).foregroundColor(Color(hex: "#4CAF50"))
                        Text("\(Int(pE*100))%").font(Font.caption.bold()).foregroundColor(Color(hex: "#FF5252"))
                    }
                }
            }
            .frame(width: 100, height: 100)
            VStack(alignment: .leading, spacing: 10) {
                leyenda(t("graficas.ingresos"), formatValor(totalIngresos, moneda: monMostrar), Color(hex: "#4CAF50"))
                leyenda(t("graficas.egresos"),  formatValor(totalEgresos,  moneda: monMostrar), Color(hex: "#FF5252"))
                if totalTransferencias > 0 {
                    leyenda(t("graficas.transferencias"), formatValor(totalTransferencias, moneda: monMostrar), Color(hex: "#2196F3"))
                }
                Divider().background(Color.bordeApp)
                let bal = totalIngresos - totalEgresos
                leyenda("Balance", formatValor(bal, moneda: monMostrar),
                        bal >= 0 ? Color(hex: "#4CAF50") : Color(hex: "#FF5252"))
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
                    var m = Movimiento()
                    m.id              = d["id"]              as? String ?? child.key
                    m.tipoTransaccion = d["tipoTransaccion"] as? String ?? ""
                    m.detalle         = d["detalle"]         as? String ?? ""
                    m.categoria       = d["categoria"]       as? String ?? ""
                    m.subcategoria    = d["subcategoria"]    as? String ?? ""
                    m.subsubcategoria = d["subsubcategoria"] as? String ?? ""
                    m.valor           = d["valor"]           as? Double ?? 0
                    m.timestamp       = d["timestamp"]       as? Double ?? 0
                    m.cuenta          = d["cuenta"]          as? String ?? ""
                    m.moneda          = d["moneda"]          as? String ?? "COP"
                    m.cuentaOrigen    = d["cuentaOrigen"]    as? String ?? ""
                    m.cuentaDestino   = d["cuentaDestino"]   as? String ?? ""
                    temp.append(m)
                }
                movimientos = temp
            }
    }
}
