import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct RegistrarView: View {

    @ObservedObject var theme  = ThemeManager.shared
    @ObservedObject var loc    = LocalizationManager.shared
    @StateObject private var config = ConfigManager.shared

    @State private var tipo            = "Egreso"
    @State private var categoria       = ""
    @State private var subcategoria    = ""
    @State private var subsubcategoria = ""
    @State private var detalle         = ""
    @State private var valor           = ""
    @State private var cuenta          = ""
    @State private var cuentaOrigen    = ""
    @State private var cuentaDestino   = ""
    @State private var moneda          = "COP"
    @State private var guardando       = false
    @State private var guardado        = false

    @FocusState private var campoActivo: Bool

    var arbolActual: [CategoriaItem] {
        tipo == "Egreso" ? config.egresosTree : config.ingresosTree
    }
    var catSeleccionada: CategoriaItem? {
        arbolActual.first { $0.nombre == categoria }
    }
    var subSeleccionada: SubcategoriaItem? {
        catSeleccionada?.subcategorias.first { $0.nombre == subcategoria }
    }

    var tiposDisponibles: [(String, String, String)] {
        [
            ("Egreso",        "📉", t("registrar.egreso")),
            ("Ingreso",       "📈", t("registrar.ingreso")),
            ("Transferencia", "🔄", t("registrar.transferencia"))
        ]
    }

    // Formatea el valor con separadores de miles según moneda
    var valorFormateado: String {
        let limpio = valor.replacingOccurrences(of: ".", with: "")
                          .replacingOccurrences(of: ",", with: "")
        guard let numero = Double(limpio) else { return valor }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        f.decimalSeparator = ","
        f.maximumFractionDigits = moneda == "USD" ? 2 : 0
        return f.string(from: NSNumber(value: numero)) ?? valor
    }

    var body: some View {
        ZStack {
            Color.fondoApp.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {

                    // Header
                    Text("💰 \(t("registrar.titulo"))")
                        .font(Font.title2.bold())
                        .foregroundColor(.acentoApp)
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.cardApp).cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.bordeApp, lineWidth: 1))

                    // Selector tipo
                    HStack(spacing: 4) {
                        ForEach(tiposDisponibles, id: \.0) { key, emoji, label in
                            Button {
                                tipo = key
                                categoria = ""; subcategoria = ""
                                subsubcategoria = ""; cuentaOrigen = ""
                                cuentaDestino = ""
                                campoActivo = false
                            } label: {
                                Text("\(emoji) \(label)")
                                    .font(Font.caption.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(tipo == key
                                        ? colorParaTipo(key) : Color.cardApp)
                                    .foregroundColor(tipo == key ? .white : colorParaTipo(key))
                                    .cornerRadius(12)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .background(Color.cardApp).cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.bordeApp, lineWidth: 1))

                    // Formulario
                    VStack(spacing: 14) {

                        if tipo == "Transferencia" {
                            campoMenu(t("registrar.cuenta_origen"),
                                      "arrow.up.circle.fill",
                                      seleccion: cuentaOrigen.isEmpty
                                        ? t("registrar.selecciona_origen")
                                        : cuentaOrigen,
                                      opciones: config.cuentas) { cuentaOrigen = $0 }

                            campoMenu(t("registrar.cuenta_destino"),
                                      "arrow.down.circle.fill",
                                      seleccion: cuentaDestino.isEmpty
                                        ? t("registrar.selecciona_destino")
                                        : cuentaDestino,
                                      opciones: config.cuentas) { cuentaDestino = $0 }

                            campoInput(t("registrar.detalle"), "text.alignleft",
                                       texto: $detalle, keyboard: .default)

                            selectorMonedaYValor

                        } else {
                            campoMenu(t("registrar.categoria"), "tag.fill",
                                      seleccion: categoria.isEmpty
                                        ? t("registrar.selecciona_cat") : categoria,
                                      opciones: arbolActual.map { $0.nombre }
                            ) { val in categoria = val; subcategoria = ""; subsubcategoria = "" }

                            if let cat = catSeleccionada, !cat.subcategorias.isEmpty {
                                campoMenu(t("registrar.subcategoria"), "list.bullet",
                                          seleccion: subcategoria.isEmpty
                                            ? t("registrar.selecciona_sub") : subcategoria,
                                          opciones: cat.subcategorias.map { $0.nombre }
                                ) { val in subcategoria = val; subsubcategoria = "" }
                            }

                            if let sub = subSeleccionada, !sub.subsubcategorias.isEmpty {
                                campoMenu(t("registrar.subsubcategoria"),
                                          "arrow.turn.down.right",
                                          seleccion: subsubcategoria.isEmpty
                                            ? t("registrar.selecciona_subsub")
                                            : subsubcategoria,
                                          opciones: sub.subsubcategorias
                                ) { subsubcategoria = $0 }
                            }

                            campoInput(t("registrar.detalle"), "text.alignleft",
                                       texto: $detalle, keyboard: .default)

                            selectorMonedaYValor

                            if !config.cuentas.isEmpty {
                                campoMenu(t("registrar.cuenta"), "creditcard.fill",
                                          seleccion: cuenta.isEmpty
                                            ? t("registrar.selecciona_cta") : cuenta,
                                          opciones: config.cuentas) { cuenta = $0 }
                            }
                        }
                    }
                    .padding()
                    .background(Color.cardApp).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.bordeApp, lineWidth: 1))

                    // Botón guardar
                    Button {
                        campoActivo = false
                        guardar()
                    } label: {
                        HStack {
                            if guardando { ProgressView().tint(.white) }
                            else {
                                Image(systemName: "checkmark.circle.fill")
                                Text(t("registrar.guardar")).fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(
                            tipo == "Transferencia"
                                ? LinearGradient(
                                    colors: [Color(hex: "#1565C0"), Color(hex: "#0D47A1")],
                                    startPoint: .leading, endPoint: .trailing)
                                : tipo == "Egreso"
                                    ? LinearGradient(
                                        colors: [Color(hex: "#C62828"), Color(hex: "#B71C1C")],
                                        startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(
                                        colors: [Color(hex: "#2E7D32"), Color(hex: "#1B5E20")],
                                        startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white).cornerRadius(14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(guardando || valor.isEmpty
                              || (tipo != "Transferencia" && categoria.isEmpty)
                              || (tipo == "Transferencia"
                                  && (cuentaOrigen.isEmpty || cuentaDestino.isEmpty)))

                    if guardado {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.verdeFinanzas)
                            Text(t("registrar.guardado"))
                                .foregroundColor(Color.verdeFinanzas)
                        }
                        .padding()
                        .background(Color(hex: "#1B4332")).cornerRadius(12)
                        .transition(.opacity)
                    }
                }
                .padding()
            }
            // Tap fuera baja el teclado
            .onTapGesture { campoActivo = false }
        }
        .preferredColorScheme(theme.temaOscuro ? .dark : .light)
        .id(loc.idioma)
    }

    // MARK: - Selector moneda + valor
    var selectorMonedaYValor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(t("registrar.valor"))
                .font(Font.caption.bold())
                .foregroundColor(.acentoApp).kerning(1.2)

            HStack(spacing: 0) {
                // Selector COP / USD
                Menu {
                    Button("🇨🇴 COP") { moneda = "COP" }
                    Button("🇺🇸 USD") { moneda = "USD" }
                } label: {
                    HStack(spacing: 4) {
                        Text(moneda == "COP" ? "🇨🇴" : "🇺🇸")
                            .font(Font.body)
                        Text(moneda)
                            .font(Font.caption.bold())
                            .foregroundColor(.acentoApp)
                        Image(systemName: "chevron.down")
                            .font(Font.caption2)
                            .foregroundColor(.textoSecundario)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .background(Color.inputFondo)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                Divider()
                    .frame(height: 30)
                    .background(Color.bordeApp)

                // Campo numérico
                TextField("0", text: $valor)
                    .keyboardType(.numberPad)
                    .foregroundColor(.textoPrincipal)
                    .focused($campoActivo)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .onChange(of: valor) { nuevo in
                        // Solo dígitos
                        let soloDigitos = nuevo.filter { $0.isNumber }
                        // Separadores de miles con punto
                        if let numero = Int(soloDigitos) {
                            let f = NumberFormatter()
                            f.numberStyle = .decimal
                            f.groupingSeparator = "."
                            f.groupingSize = 3
                            valor = f.string(from: NSNumber(value: numero)) ?? soloDigitos
                        } else {
                            valor = soloDigitos
                        }
                    }

                // Símbolo moneda
                Text(moneda == "COP" ? "$" : "USD")
                    .font(Font.caption.bold())
                    .foregroundColor(.textoSecundario)
                    .padding(.trailing, 12)
            }
            .background(Color.inputFondo)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(Color.bordeApp, lineWidth: 1))
        }
    }

    // MARK: - Color según tipo
    func colorParaTipo(_ tipo: String) -> Color {
        switch tipo {
        case "Ingreso":       return Color.verdeFinanzas
        case "Transferencia": return Color(hex: "#2196F3")
        default:              return Color.rojoFinanzas
        }
    }

    // MARK: - Componentes
    func campoMenu(_ titulo: String, _ icono: String,
                   seleccion: String, opciones: [String],
                   onSelect: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo).font(Font.caption.bold())
                .foregroundColor(.acentoApp).kerning(1.2)
            Menu {
                ForEach(opciones, id: \.self) { op in
                    Button(op) {
                        campoActivo = false
                        onSelect(op)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: icono).foregroundColor(.acentoApp).frame(width: 20)
                    Text(seleccion).foregroundColor(
                        seleccion.contains("Selecciona") || seleccion.contains("Select")
                            ? Color.textoSecundario : Color.textoPrincipal)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.textoSecundario).font(Font.caption)
                }
                .padding().background(Color.inputFondo).cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.bordeApp, lineWidth: 1))
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    func campoInput(_ titulo: String, _ icono: String,
                    texto: Binding<String>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo).font(Font.caption.bold())
                .foregroundColor(.acentoApp).kerning(1.2)
            HStack(spacing: 12) {
                Image(systemName: icono).foregroundColor(.acentoApp).frame(width: 20)
                TextField("", text: texto)
                    .foregroundColor(.textoPrincipal)
                    .keyboardType(keyboard)
                    .focused($campoActivo)
                    .submitLabel(.done)
                    .onSubmit { campoActivo = false }
            }
            .padding().background(Color.inputFondo).cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(Color.bordeApp, lineWidth: 1))
        }
    }

    // MARK: - Firebase
    func guardar() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        // Limpiar puntos del valor antes de convertir a Double
        let valorLimpio = valor.replacingOccurrences(of: ".", with: "")
                               .replacingOccurrences(of: ",", with: ".")
        guard let valorDouble = Double(valorLimpio), valorDouble > 0 else { return }
        guardando = true

        let ref = Database.database().reference()
            .child("movimientos").child(uid).childByAutoId()

        var data: [String: Any] = [
            "id":              ref.key ?? "",
            "tipoTransaccion": tipo,
            "detalle":         detalle,
            "valor":           valorDouble,
            "moneda":          moneda,
            "timestamp":       Date().timeIntervalSince1970 * 1000
        ]

        if tipo == "Transferencia" {
            data["categoria"]    = "Transferencia"
            data["cuentaOrigen"] = cuentaOrigen
            data["cuenta"]       = cuentaDestino
        } else {
            data["categoria"]       = categoria
            data["subcategoria"]    = subcategoria
            data["subsubcategoria"] = subsubcategoria
            data["cuenta"]          = cuenta
        }

        ref.setValue(data) { error, _ in
            guardando = false
            if error == nil {
                valor = ""; detalle = ""; subcategoria = ""
                subsubcategoria = ""; categoria = ""
                cuentaOrigen = ""; cuentaDestino = ""
                withAnimation { guardado = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { guardado = false }
                }
            }
        }
    }
}
