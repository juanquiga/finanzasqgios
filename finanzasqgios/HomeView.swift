import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct HomeView: View {

    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var loc   = LocalizationManager.shared

    @State private var movimientos  : [Movimiento] = []
    @State private var periodo       = "Mensual"
    @State private var filtro        = "Todo"
    @State private var monedaFiltro  = "AMBAS"
    @State private var nombre        = "Usuario"
    @State private var seleccionado  : Movimiento? = nil
    @State private var showDetalle   = false
    @State private var movAEliminar  : Movimiento? = nil
    @State private var showEliminar  = false

    var periodosDisponibles: [(String, String)] {
        [("Diario",  t("resumen.diario")),
         ("Mensual", t("resumen.mensual")),
         ("Anual",   t("resumen.anual"))]
    }
    var filtrosDisponibles: [(String, String)] {
        [("Todo",     t("resumen.todo")),
         ("Ingresos", t("resumen.ingresos")),
         ("Egresos",  t("resumen.egresos"))]
    }

    var porPeriodo: [Movimiento] {
        let ahora = Calendar.current
        return movimientos.filter { m in
            let fecha = Date(timeIntervalSince1970: m.timestamp / 1000)
            switch periodo {
            case "Diario":  return ahora.isDateInToday(fecha)
            case "Mensual": return ahora.isDate(fecha, equalTo: Date(), toGranularity: .month)
            default:        return ahora.isDate(fecha, equalTo: Date(), toGranularity: .year)
            }
        }
    }
    var porMoneda: [Movimiento] {
        switch monedaFiltro {
        case "COP": return porPeriodo.filter { $0.moneda == "COP" }
        case "USD": return porPeriodo.filter { $0.moneda == "USD" }
        default:    return porPeriodo
        }
    }
    var movimientosMostrados: [Movimiento] {
        switch filtro {
        case "Ingresos": return porMoneda.filter { $0.tipoTransaccion == "Ingreso" }
        case "Egresos":  return porMoneda.filter { $0.tipoTransaccion == "Egreso"  }
        default:         return porMoneda
        }
    }
    var totalIngresos: Double { porMoneda.filter { $0.tipoTransaccion == "Ingreso" }.reduce(0) { $0 + $1.valor } }
    var totalEgresos : Double { porMoneda.filter { $0.tipoTransaccion == "Egreso"  }.reduce(0) { $0 + $1.valor } }
    var balance      : Double { totalIngresos - totalEgresos }
    var monedaMostrar: String { monedaFiltro == "USD" ? "USD" : "COP" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {

                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(t("resumen.titulo"))
                                .font(Font.title2.bold()).foregroundColor(.acentoApp)
                            Text("\(t("resumen.hola")), \(nombre) 👋")
                                .font(Font.subheadline).foregroundColor(.textoSecundario)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.cardApp).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.bordeApp, lineWidth: 1))

                    // Período
                    HStack(spacing: 8) {
                        ForEach(periodosDisponibles, id: \.0) { key, label in
                            Button(label) { periodo = key }
                                .font(Font.caption.bold())
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(periodo == key ? Color.acentoApp : Color.cardApp)
                                .foregroundColor(periodo == key ? Color(hex: "#050510") : .textoSecundario)
                                .cornerRadius(10)
                        }
                        Spacer()
                    }

                    // Filtro tipo
                    HStack(spacing: 8) {
                        ForEach(filtrosDisponibles, id: \.0) { key, label in
                            Button(label) { filtro = key }
                                .font(Font.caption)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(filtro == key ? Color.acentoApp : Color.cardApp)
                                .foregroundColor(filtro == key ? Color(hex: "#050510") : .acentoApp)
                                .cornerRadius(8)
                        }
                        Spacer()
                    }

                    // Filtro moneda
                    HStack(spacing: 8) {
                        ForEach([("AMBAS","🌐 Ambas"),("COP","🇨🇴 COP"),("USD","🇺🇸 USD")],
                                id: \.0) { key, label in
                            Button(label) { monedaFiltro = key }
                                .font(Font.caption)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(monedaFiltro == key ? Color.acentoApp : Color.cardApp)
                                .foregroundColor(monedaFiltro == key ? Color(hex: "#050510") : .acentoApp)
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
                                .font(Font.title3.bold())
                                .foregroundColor(balance >= 0 ? Color.acentoApp : Color.rojoFinanzas)
                        }
                        .padding()
                        .background(Color.cardApp).cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.bordeApp, lineWidth: 1))
                    }

                    // Lista movimientos
                    if movimientosMostrados.isEmpty {
                        VStack(spacing: 10) {
                            Text("📭").font(Font.system(size: 40))
                            Text(t("resumen.vacio"))
                                .foregroundColor(.textoSecundario).font(Font.subheadline)
                        }
                        .frame(maxWidth: .infinity).padding(30)
                        .background(Color.cardApp).cornerRadius(16)
                    } else {
                        VStack(spacing: 8) {
                            HStack {
                                Text(t("resumen.recientes"))
                                    .font(Font.caption.bold()).foregroundColor(.textoSecundario)
                                Spacer()
                                Text("← Desliza para eliminar")
                                    .font(Font.caption2)
                                    .foregroundColor(Color.textoSecundario.opacity(0.6))
                            }
                            .padding(.bottom, 2)

                            ForEach(movimientosMostrados.sorted { $0.timestamp > $1.timestamp }) { m in
                                itemMovimiento(m)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            movAEliminar = m
                                            showEliminar = true
                                        } label: {
                                            Label("Eliminar", systemImage: "trash")
                                        }
                                    }
                                    .onTapGesture {
                                        seleccionado = m
                                        showDetalle  = true
                                    }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.fondoApp.ignoresSafeArea())
            .navigationDestination(isPresented: $showDetalle) {
                if let m = seleccionado {
                    DetalleMovimientoView(movimiento: m)
                }
            }
        }
        .alert("¿Eliminar este registro?", isPresented: $showEliminar) {
            Button("Eliminar", role: .destructive) {
                if let m = movAEliminar { eliminarMovimiento(m) }
            }
            Button("Cancelar", role: .cancel) { movAEliminar = nil }
        } message: {
            if let m = movAEliminar {
                Text("\(m.categoria.isEmpty ? m.tipoTransaccion : m.categoria) — \(formatValor(m.valor, moneda: m.moneda))")
            }
        }
        .onAppear { cargarNombre(); cargarMovimientos() }
        .id(loc.idioma)
        .preferredColorScheme(theme.temaOscuro ? .dark : .light)
    }

    // MARK: - Card resumen
    func cardResumen(_ titulo: String, _ valor: Double,
                     _ moneda: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo).font(Font.caption.bold()).foregroundColor(color)
            Text(formatValor(valor, moneda: moneda))
                .font(Font.headline.bold()).foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding()
        .background(Color.cardApp).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.bordeApp, lineWidth: 1))
    }

    // MARK: - Item movimiento
    func itemMovimiento(_ m: Movimiento) -> some View {
        let esTransf = m.tipoTransaccion == "Transferencia"
        let esIng    = m.tipoTransaccion == "Ingreso"
        return HStack(spacing: 12) {
            Text(esIng ? "📈" : esTransf ? "🔄" : "📉")
                .font(Font.title2)
                .frame(width: 44, height: 44)
                .background(esIng ? Color(hex: "#1B4332")
                            : esTransf ? Color(hex: "#0D2A4A") : Color(hex: "#4A1010"))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 3) {
                Text(m.categoria.isEmpty ? m.tipoTransaccion : m.categoria)
                    .font(Font.subheadline.bold()).foregroundColor(.textoPrincipal)
                if !m.detalle.isEmpty {
                    Text(m.detalle).font(Font.caption).foregroundColor(.textoSecundario)
                } else if !m.subcategoria.isEmpty {
                    Text(m.subcategoria).font(Font.caption).foregroundColor(.textoSecundario)
                } else if esTransf {
                    let dest = m.cuentaDestino.isEmpty ? m.cuenta : m.cuentaDestino
                    Text("\(m.cuentaOrigen) → \(dest)")
                        .font(Font.caption).foregroundColor(.textoSecundario)
                }
                Text(formatFecha(m.timestamp))
                    .font(Font.caption2).foregroundColor(Color.textoSecundario.opacity(0.7))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(formatValor(m.valor, moneda: m.moneda))
                    .font(Font.subheadline.bold())
                    .foregroundColor(esIng ? Color(hex: "#69F0AE")
                                    : esTransf ? Color(hex: "#2196F3") : Color.rojoFinanzas)
                Text(m.moneda).font(Font.caption2).foregroundColor(.textoSecundario)
                Image(systemName: "chevron.right")
                    .font(Font.caption2).foregroundColor(Color.bordeApp)
            }
        }
        .padding()
        .background(Color.cardApp).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bordeApp, lineWidth: 1))
    }

    // MARK: - Firebase
    func eliminarMovimiento(_ m: Movimiento) {
        guard let uid = Auth.auth().currentUser?.uid, !m.id.isEmpty else { return }
        Database.database().reference()
            .child("movimientos").child(uid).child(m.id).removeValue()
    }

    func cargarNombre() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Database.database().reference().child("users").child(uid)
            .observeSingleEvent(of: .value) { snap in
                let data = snap.value as? [String: Any]
                let n = data?["name"] as? String ?? ""
                nombre = n.isEmpty
                    ? (Auth.auth().currentUser?.email?.components(separatedBy: "@").first ?? "Usuario") : n
            }
    }

    func cargarMovimientos() {
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
