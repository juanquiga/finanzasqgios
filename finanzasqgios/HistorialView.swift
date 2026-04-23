import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct HistorialView: View {

    @ObservedObject var theme = ThemeManager.shared
    @State private var movimientos:  [Movimiento] = []
    @State private var busqueda      = ""
    @State private var monedaFiltro  = "AMBAS"   // AMBAS | COP | USD
    @Environment(\.dismiss) var dismiss

    // Paso 1: moneda
    var porMoneda: [Movimiento] {
        switch monedaFiltro {
        case "COP": return movimientos.filter { $0.moneda == "COP" }
        case "USD": return movimientos.filter { $0.moneda == "USD" }
        default:    return movimientos
        }
    }

    // Paso 2: búsqueda
    var movimientosFiltrados: [Movimiento] {
        if busqueda.isEmpty { return porMoneda }
        return porMoneda.filter {
            $0.categoria.localizedCaseInsensitiveContains(busqueda) ||
            $0.detalle.localizedCaseInsensitiveContains(busqueda)   ||
            $0.subcategoria.localizedCaseInsensitiveContains(busqueda)
        }
    }

    var body: some View {
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
                .padding(.horizontal)
                .padding(.bottom, 6)

                // Buscador
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundColor(.textoSecundario)
                    TextField(t("historial.buscar"), text: $busqueda)
                        .foregroundColor(.textoPrincipal)
                }
                .padding()
                .background(Color.cardApp).cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.bordeApp, lineWidth: 1))
                .padding(.horizontal).padding(.bottom, 10)

                // Lista
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if movimientosFiltrados.isEmpty {
                            VStack(spacing: 12) {
                                Text("📭").font(Font.system(size: 40))
                                Text("Sin registros")
                                    .foregroundColor(.textoSecundario)
                                    .font(Font.subheadline)
                            }
                            .frame(maxWidth: .infinity).padding(40)
                        } else {
                            ForEach(movimientosFiltrados
                                .sorted { $0.timestamp > $1.timestamp }) { m in
                                itemHistorial(m)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(theme.temaOscuro ? .dark : .light)
        .onAppear { cargar() }
    }

    // MARK: - Item
    func itemHistorial(_ m: Movimiento) -> some View {
        HStack(spacing: 12) {
            Text(m.tipoTransaccion == "Ingreso" ? "📈" : "📉")
                .font(Font.title2)
                .frame(width: 44, height: 44)
                .background(m.tipoTransaccion == "Ingreso"
                    ? Color(hex: "#1B4332") : Color(hex: "#4A1010"))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 3) {
                Text(m.categoria.isEmpty ? m.tipoTransaccion : m.categoria)
                    .font(Font.subheadline.bold()).foregroundColor(.textoPrincipal)
                if !m.subcategoria.isEmpty {
                    Text(m.subcategoria)
                        .font(Font.caption).foregroundColor(.textoSecundario)
                }
                if !m.detalle.isEmpty {
                    Text(m.detalle)
                        .font(Font.caption).foregroundColor(.textoSecundario)
                }
                Text(formatFecha(m.timestamp))
                    .font(Font.caption2)
                    .foregroundColor(Color.textoSecundario.opacity(0.7))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formatValor(m.valor, moneda: m.moneda))
                    .font(Font.subheadline.bold())
                    .foregroundColor(m.tipoTransaccion == "Ingreso"
                        ? Color(hex: "#69F0AE") : Color.rojoFinanzas)
                // Badge moneda
                Text(m.moneda == "USD" ? "🇺🇸 USD" : "🇨🇴 COP")
                    .font(Font.caption2).foregroundColor(.textoSecundario)
                if !m.cuenta.isEmpty {
                    Text(m.cuenta)
                        .font(Font.caption2).foregroundColor(.textoSecundario)
                }
            }
        }
        .padding()
        .background(Color.cardApp).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(Color.bordeApp, lineWidth: 1))
    }

    // MARK: - Firebase
    func cargar() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Database.database().reference()
            .child("movimientos").child(uid)
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
