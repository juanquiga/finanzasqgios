import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct EditarMovimientoView: View {

    @ObservedObject var theme  = ThemeManager.shared
    @StateObject private var config = ConfigManager.shared
    let movimiento: Movimiento
    @Environment(\.dismiss) var dismiss

    @State private var categoria       = ""
    @State private var subcategoria    = ""
    @State private var subsubcategoria = ""
    @State private var detalle         = ""
    @State private var valorTexto      = ""
    @State private var cuenta          = ""
    @State private var cuentaOrigen    = ""
    @State private var cuentaDestino   = ""
    @State private var moneda          = "COP"
    @State private var fechaSelec      = Date()
    @State private var showCalendario  = false
    @State private var guardando       = false
    @State private var errorMsg        = ""

    @FocusState private var campoActivo: Bool

    let cal = Calendar.current

    var tipo: String { movimiento.tipoTransaccion }

    var arbolActual: [CategoriaItem] {
        tipo == "Egreso" ? config.egresosTree : config.ingresosTree
    }
    var catSeleccionada: CategoriaItem? {
        arbolActual.first { $0.nombre == categoria }
    }
    var subSeleccionada: SubcategoriaItem? {
        catSeleccionada?.subcategorias.first { $0.nombre == subcategoria }
    }

    var valorDouble: Double? {
        let limpio = valorTexto
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        return Double(limpio)
    }

    var puedeGuardar: Bool {
        guard let v = valorDouble, v > 0 else { return false }
        if tipo == "Transferencia" { return !cuentaOrigen.isEmpty && !cuentaDestino.isEmpty }
        return !categoria.isEmpty
    }

    var fechaLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_CO")
        if cal.isDateInToday(fechaSelec)     { f.dateFormat = "'Hoy —' dd MMM yyyy" }
        else if cal.isDateInYesterday(fechaSelec) { f.dateFormat = "'Ayer —' dd MMM yyyy" }
        else                                 { f.dateFormat = "EEEE dd 'de' MMMM yyyy" }
        return f.string(from: fechaSelec)
    }

    // Color del fondo del botón guardar — siempre LinearGradient
    var gradienteGuardar: LinearGradient {
        if !puedeGuardar {
            return LinearGradient(colors: [Color.textoSecundario.opacity(0.3),
                                            Color.textoSecundario.opacity(0.3)],
                                   startPoint: .leading, endPoint: .trailing)
        }
        switch tipo {
        case "Ingreso":
            return LinearGradient(colors: [Color(hex: "#2E7D32"), Color(hex: "#1B5E20")],
                                   startPoint: .leading, endPoint: .trailing)
        case "Transferencia":
            return LinearGradient(colors: [Color(hex: "#1565C0"), Color(hex: "#0D47A1")],
                                   startPoint: .leading, endPoint: .trailing)
        default:
            return LinearGradient(colors: [Color(hex: "#C62828"), Color(hex: "#B71C1C")],
                                   startPoint: .leading, endPoint: .trailing)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fondoApp.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {

                        // Tipo (no editable)
                        HStack {
                            Text(tipo == "Ingreso" ? "📈" : tipo == "Transferencia" ? "🔄" : "📉")
                            Text("Editando \(tipo.lowercased())")
                                .font(Font.subheadline.bold()).foregroundColor(.textoPrincipal)
                            Spacer()
                        }
                        .padding().background(Color.cardApp).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bordeApp, lineWidth: 1))

                        // Fecha
                        VStack(alignment: .leading, spacing: 6) {
                            Text("FECHA").font(Font.caption.bold()).foregroundColor(.acentoApp).kerning(1.2)
                            Button {
                                withAnimation { showCalendario.toggle(); campoActivo = false }
                            } label: {
                                HStack {
                                    Image(systemName: "calendar.circle.fill")
                                        .foregroundColor(.acentoApp).font(Font.title3)
                                    Text(fechaLabel.capitalized)
                                        .font(Font.subheadline).foregroundColor(.textoPrincipal)
                                    Spacer()
                                    Image(systemName: showCalendario
                                          ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                        .foregroundColor(.acentoApp)
                                }
                                .padding()
                                .background(showCalendario ? Color.acentoApp.opacity(0.1) : Color.inputFondo)
                                .cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(showCalendario ? Color.acentoApp : Color.bordeApp, lineWidth: 1.5))
                            }
                            .buttonStyle(PlainButtonStyle())

                            if showCalendario {
                                CalendarioPersonalizado(fechaSeleccionada: $fechaSelec) {
                                    withAnimation { showCalendario = false }
                                }
                            }
                        }

                        // Campos
                        VStack(spacing: 14) {
                            if tipo == "Transferencia" {
                                campoMenu("CUENTA ORIGEN", "arrow.up.circle.fill",
                                          sel: cuentaOrigen.isEmpty ? "Selecciona origen" : cuentaOrigen,
                                          ops: config.cuentas.filter { $0 != cuentaDestino }
                                ) { cuentaOrigen = $0 }

                                campoMenu("CUENTA DESTINO", "arrow.down.circle.fill",
                                          sel: cuentaDestino.isEmpty ? "Selecciona destino" : cuentaDestino,
                                          ops: config.cuentas.filter { $0 != cuentaOrigen }
                                ) { cuentaDestino = $0 }

                            } else {
                                campoMenu("CATEGORÍA", "tag.fill",
                                          sel: categoria.isEmpty ? "Selecciona categoría" : categoria,
                                          ops: arbolActual.map { $0.nombre }
                                ) { v in categoria = v; subcategoria = ""; subsubcategoria = "" }

                                if let cat = catSeleccionada, !cat.subcategorias.isEmpty {
                                    campoMenu("SUBCATEGORÍA", "list.bullet",
                                              sel: subcategoria.isEmpty ? "Selecciona subcategoría" : subcategoria,
                                              ops: cat.subcategorias.map { $0.nombre }
                                    ) { v in subcategoria = v; subsubcategoria = "" }
                                }
                                if let sub = subSeleccionada, !sub.subsubcategorias.isEmpty {
                                    campoMenu("SUBSUBCATEGORÍA", "arrow.turn.down.right",
                                              sel: subsubcategoria.isEmpty ? "Selecciona" : subsubcategoria,
                                              ops: sub.subsubcategorias.map { $0.nombre }
                                    ) { subsubcategoria = $0 }
                                }
                                if !config.cuentas.isEmpty {
                                    campoMenu("CUENTA", "creditcard.fill",
                                              sel: cuenta.isEmpty ? "Selecciona cuenta" : cuenta,
                                              ops: config.cuentas) { cuenta = $0 }
                                }
                            }

                            campoInput("DESCRIPCIÓN", "text.alignleft", texto: $detalle, keyboard: .default)

                            // Valor
                            VStack(alignment: .leading, spacing: 6) {
                                Text("VALOR").font(Font.caption.bold()).foregroundColor(.acentoApp).kerning(1.2)
                                HStack(spacing: 0) {
                                    Menu {
                                        Button("🇨🇴 COP") { moneda = "COP" }
                                        Button("🇺🇸 USD") { moneda = "USD" }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(moneda == "COP" ? "🇨🇴" : "🇺🇸")
                                            Text(moneda).font(Font.caption.bold()).foregroundColor(.acentoApp)
                                            Image(systemName: "chevron.down").font(Font.caption2)
                                                .foregroundColor(.textoSecundario)
                                        }
                                        .padding(.horizontal, 12).padding(.vertical, 14)
                                        .background(Color.inputFondo).contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    Divider().frame(height: 30).background(Color.bordeApp)
                                    TextField("0", text: $valorTexto)
                                        .keyboardType(.decimalPad).foregroundColor(.textoPrincipal)
                                        .focused($campoActivo)
                                        .padding(.horizontal, 12).padding(.vertical, 14).frame(maxWidth: .infinity)
                                    Text(moneda == "COP" ? "$" : "USD")
                                        .font(Font.caption.bold()).foregroundColor(.textoSecundario)
                                        .padding(.trailing, 12)
                                }
                                .background(Color.inputFondo).cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bordeApp, lineWidth: 1))

                                if let v = valorDouble, v > 0 {
                                    Text("= \(formatValor(v, moneda: moneda))")
                                        .font(Font.caption).foregroundColor(Color.acentoApp.opacity(0.8))
                                }
                            }

                            if !errorMsg.isEmpty {
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(Color(hex: "#FF5252"))
                                    Text(errorMsg).font(Font.caption)
                                        .foregroundColor(Color(hex: "#FF5252"))
                                }
                                .padding(10).background(Color(hex: "#4A1010")).cornerRadius(10)
                            }
                        }
                        .padding().background(Color.cardApp).cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.bordeApp, lineWidth: 1))

                        // Botón guardar — usa LinearGradient siempre
                        Button {
                            campoActivo = false; showCalendario = false; guardar()
                        } label: {
                            HStack {
                                if guardando { ProgressView().tint(.white) }
                                else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Guardar cambios").fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity).padding()
                            .background(gradienteGuardar)
                            .foregroundColor(puedeGuardar ? .white : .textoSecundario)
                            .cornerRadius(14)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(guardando || !puedeGuardar)
                    }
                    .padding()
                }
                .onTapGesture { campoActivo = false; withAnimation { showCalendario = false } }
            }
            .navigationTitle("Editar movimiento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }.foregroundColor(.acentoApp)
                }
            }
        }
        .preferredColorScheme(theme.temaOscuro ? .dark : .light)
        .onAppear { cargarValores() }
    }

    func cargarValores() {
        categoria       = movimiento.categoria
        subcategoria    = movimiento.subcategoria
        subsubcategoria = movimiento.subsubcategoria
        detalle         = movimiento.detalle
        moneda          = movimiento.moneda
        cuenta          = movimiento.cuenta
        cuentaOrigen    = movimiento.cuentaOrigen
        cuentaDestino   = movimiento.cuentaDestino
        fechaSelec      = Date(timeIntervalSince1970: movimiento.timestamp / 1000)
        let v = movimiento.valor
        valorTexto = v == Double(Int(v)) ? "\(Int(v))" : "\(v)"
    }

    func campoMenu(_ titulo: String, _ icono: String,
                   sel: String, ops: [String],
                   onSelect: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo).font(Font.caption.bold()).foregroundColor(.acentoApp).kerning(1.2)
            Menu {
                ForEach(ops, id: \.self) { op in
                    Button(op) { campoActivo = false; onSelect(op) }
                }
            } label: {
                HStack {
                    Image(systemName: icono).foregroundColor(.acentoApp).frame(width: 20)
                    Text(sel).foregroundColor(sel.contains("Selecciona")
                        ? Color.textoSecundario : Color.textoPrincipal)
                    Spacer()
                    Image(systemName: "chevron.down").foregroundColor(.textoSecundario).font(Font.caption)
                }
                .padding().background(Color.inputFondo).cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bordeApp, lineWidth: 1))
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    func campoInput(_ titulo: String, _ icono: String,
                    texto: Binding<String>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo).font(Font.caption.bold()).foregroundColor(.acentoApp).kerning(1.2)
            HStack(spacing: 12) {
                Image(systemName: icono).foregroundColor(.acentoApp).frame(width: 20)
                TextField("", text: texto).foregroundColor(.textoPrincipal).keyboardType(keyboard)
                    .focused($campoActivo).submitLabel(.done).onSubmit { campoActivo = false }
            }
            .padding().background(Color.inputFondo).cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bordeApp, lineWidth: 1))
        }
    }

    func guardar() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let valor = valorDouble, valor > 0 else { errorMsg = "Ingresa un valor válido"; return }
        if tipo != "Transferencia" && categoria.isEmpty { errorMsg = "Selecciona una categoría"; return }
        guardando = true; errorMsg = ""

        var comps = cal.dateComponents([.year, .month, .day], from: fechaSelec)
        let ahora = cal.dateComponents([.hour, .minute, .second], from: Date())
        comps.hour = ahora.hour; comps.minute = ahora.minute; comps.second = ahora.second
        let ts = (cal.date(from: comps) ?? fechaSelec).timeIntervalSince1970 * 1000

        var data: [String: Any] = [
            "id": movimiento.id, "tipoTransaccion": tipo,
            "detalle": detalle.trimmingCharacters(in: .whitespacesAndNewlines),
            "valor": valor, "moneda": moneda, "timestamp": ts
        ]
        if tipo == "Transferencia" {
            data["categoria"] = "Transferencia"; data["cuentaOrigen"] = cuentaOrigen
            data["cuentaDestino"] = cuentaDestino; data["cuenta"] = cuentaDestino
            data["subcategoria"] = ""; data["subsubcategoria"] = ""
        } else {
            data["categoria"] = categoria; data["subcategoria"] = subcategoria
            data["subsubcategoria"] = subsubcategoria; data["cuenta"] = cuenta
            data["cuentaOrigen"] = ""; data["cuentaDestino"] = ""
        }

        Database.database().reference()
            .child("movimientos").child(uid).child(movimiento.id)
            .setValue(data) { error, _ in
                DispatchQueue.main.async {
                    guardando = false
                    if error == nil { dismiss() }
                    else { errorMsg = "Error al guardar" }
                }
            }
    }
}
