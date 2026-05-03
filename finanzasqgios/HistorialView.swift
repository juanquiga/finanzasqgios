import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct HistorialView: View {

    @ObservedObject var theme = ThemeManager.shared
    @State private var movimientos  : [Movimiento] = []
    @State private var busqueda      = ""
    @State private var monedaFiltro  = "AMBAS"
    @State private var modoFiltro    = "Todo"
    @State private var mesSelec      = Calendar.current.component(.month, from: Date())
    @State private var anioSelec     = Calendar.current.component(.year,  from: Date())
    @State private var seleccionado  : Movimiento? = nil
    @State private var showDetalle   = false
    @State private var movAEliminar  : Movimiento? = nil
    @State private var showEliminar  = false
    @Environment(\.dismiss) var dismiss

    let aniosDisponibles = Array(2025...2035)
    let meses = ["Enero","Febrero","Marzo","Abril","Mayo","Junio",
                 "Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre"]

    var porMoneda: [Movimiento] {
        switch monedaFiltro {
        case "COP": return movimientos.filter { $0.moneda == "COP" }
        case "USD": return movimientos.filter { $0.moneda == "USD" }
        default:    return movimientos
        }
    }

    var porPeriodo: [Movimiento] {
        let cal = Calendar.current
        return porMoneda.filter { m in
            let fecha = Date(timeIntervalSince1970: m.timestamp / 1000)
            switch modoFiltro {
            case "Mes":
                return cal.component(.month, from: fecha) == mesSelec &&
                       cal.component(.year,  from: fecha) == anioSelec
            case "Año":
                return cal.component(.year, from: fecha) == anioSelec
            default:
                return true
            }
        }
    }

    var movimientosFiltrados: [Movimiento] {
        if busqueda.isEmpty { return porPeriodo }
        return porPeriodo.filter {
            $0.categoria.localizedCaseInsensitiveContains(busqueda)   ||
            $0.detalle.localizedCaseInsensitiveContains(busqueda)     ||
            $0.subcategoria.localizedCaseInsensitiveContains(busqueda)
        }
    }

    var resumenPeriodo: (ing: Double, egr: Double, bal: Double) {
        let ing = porPeriodo.filter { $0.tipoTransaccion == "Ingreso" }.reduce(0) { $0 + $1.valor }
        let egr = porPeriodo.filter { $0.tipoTransaccion == "Egreso"  }.reduce(0) { $0 + $1.valor }
        return (ing, egr, ing - egr)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fondoApp.ignoresSafeArea()
                VStack(spacing: 0) {

                    // Header
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.acentoApp).font(Font.title3)
                        }
                        Spacer()
                        Text("📋 \(t("historial.titulo"))")
                            .font(Font.title2.bold()).foregroundColor(.acentoApp)
                        Spacer()
                        Text("\(movimientosFiltrados.count) \(t("historial.registros"))")
                            .font(Font.caption).foregroundColor(.textoSecundario)
                    }
                    .padding()

                    // Filtro período
                    VStack(spacing: 8) {

                        HStack(spacing: 8) {
                            ForEach(["Todo","Mes","Año"], id: \.self) { modo in
                                Button(modo) { withAnimation { modoFiltro = modo } }
                                    .font(Font.caption.bold())
                                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                                    .background(modoFiltro == modo ? Color.acentoApp : Color.cardApp)
                                    .foregroundColor(modoFiltro == modo
                                        ? Color(hex: "#050510") : Color.acentoApp)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)

                        if modoFiltro == "Mes" {
                            HStack(spacing: 8) {
                                Menu {
                                    ForEach(1...12, id: \.self) { i in
                                        Button(meses[i-1]) { mesSelec = i }
                                    }
                                } label: {
                                    HStack {
                                        Text(meses[mesSelec - 1])
                                            .font(Font.subheadline.bold()).foregroundColor(.textoPrincipal)
                                        Image(systemName: "chevron.down")
                                            .font(Font.caption).foregroundColor(.textoSecundario)
                                    }
                                    .frame(maxWidth: .infinity).padding(10)
                                    .background(Color.cardApp).cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.acentoApp.opacity(0.5), lineWidth: 1))
                                }

                                Menu {
                                    ForEach(aniosDisponibles, id: \.self) { a in
                                        Button("\(a)") { anioSelec = a }
                                    }
                                } label: {
                                    HStack {
                                        Text("\(anioSelec)")
                                            .font(Font.subheadline.bold()).foregroundColor(.textoPrincipal)
                                        Image(systemName: "chevron.down")
                                            .font(Font.caption).foregroundColor(.textoSecundario)
                                    }
                                    .frame(maxWidth: .infinity).padding(10)
                                    .background(Color.cardApp).cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.acentoApp.opacity(0.5), lineWidth: 1))
                                }
                            }
                            .padding(.horizontal)
                        }

                        if modoFiltro == "Año" {
                            Menu {
                                ForEach(aniosDisponibles, id: \.self) { a in
                                    Button("\(a)") { anioSelec = a }
                                }
                            } label: {
                                HStack {
                                    Text("📅 Año \(anioSelec)")
                                        .font(Font.subheadline.bold()).foregroundColor(.textoPrincipal)
                                    Image(systemName: "chevron.down")
                                        .font(Font.caption).foregroundColor(.textoSecundario)
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity).padding(10)
                                .background(Color.cardApp).cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.acentoApp.opacity(0.5), lineWidth: 1))
                            }
                            .padding(.horizontal)
                        }

                        // Resumen del período si hay filtro
                        if modoFiltro != "Todo" {
                            let r = resumenPeriodo
                            HStack(spacing: 0) {
                                VStack(spacing: 2) {
                                    Text("Ingresos").font(Font.caption2).foregroundColor(.textoSecundario)
                                    Text(formatCOP(r.ing)).font(Font.caption.bold())
                                        .foregroundColor(Color.verdeFinanzas)
                                }
                                .frame(maxWidth: .infinity)
                                Divider().frame(height: 30)
                                VStack(spacing: 2) {
                                    Text("Egresos").font(Font.caption2).foregroundColor(.textoSecundario)
                                    Text(formatCOP(r.egr)).font(Font.caption.bold())
                                        .foregroundColor(Color.rojoFinanzas)
                                }
                                .frame(maxWidth: .infinity)
                                Divider().frame(height: 30)
                                VStack(spacing: 2) {
                                    Text("Balance").font(Font.caption2).foregroundColor(.textoSecundario)
                                    Text(formatCOP(r.bal)).font(Font.caption.bold())
                                        .foregroundColor(r.bal >= 0 ? Color.verdeFinanzas : Color.rojoFinanzas)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(10)
                            .background(Color.cardApp).cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.bordeApp, lineWidth: 1))
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 6)

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
                    .padding(.horizontal).padding(.bottom, 6)

                    // Buscador
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").foregroundColor(.textoSecundario)
                        TextField(t("historial.buscar"), text: $busqueda)
                            .foregroundColor(.textoPrincipal)
                    }
                    .padding()
                    .background(Color.cardApp).cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bordeApp, lineWidth: 1))
                    .padding(.horizontal).padding(.bottom, 10)

                    // Lista
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            if movimientosFiltrados.isEmpty {
                                VStack(spacing: 12) {
                                    Text("📭").font(Font.system(size: 40))
                                    Text(modoFiltro == "Todo"
                                         ? "Sin registros"
                                         : "Sin registros para este período")
                                        .foregroundColor(.textoSecundario).font(Font.subheadline)
                                }
                                .frame(maxWidth: .infinity).padding(40)
                            } else {
                                Text("← Desliza para eliminar")
                                    .font(Font.caption2)
                                    .foregroundColor(Color.textoSecundario.opacity(0.6))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.bottom, 4)

                                ForEach(movimientosFiltrados.sorted { $0.timestamp > $1.timestamp }) { m in
                                    itemHistorial(m)
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
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
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
        .preferredColorScheme(theme.temaOscuro ? .dark : .light)
        .onAppear { cargar() }
    }

    // MARK: - Item historial
    func itemHistorial(_ m: Movimiento) -> some View {
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
                if !m.subcategoria.isEmpty {
                    Text(m.subcategoria).font(Font.caption).foregroundColor(.textoSecundario)
                }
                if !m.detalle.isEmpty {
                    Text(m.detalle).font(Font.caption).foregroundColor(.textoSecundario)
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
                Text(m.moneda == "USD" ? "🇺🇸 USD" : "🇨🇴 COP")
                    .font(Font.caption2).foregroundColor(.textoSecundario)
                if !m.cuenta.isEmpty && !esTransf {
                    Text(m.cuenta).font(Font.caption2).foregroundColor(.textoSecundario)
                }
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
