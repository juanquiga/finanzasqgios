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
    @State private var valorTexto      = ""
    @State private var cuenta          = ""
    @State private var cuentaOrigen    = ""
    @State private var cuentaDestino   = ""
    @State private var moneda          = "COP"
    @State private var guardando       = false
    @State private var guardado        = false
    @State private var errorMsg        = ""
    @State private var fechaSelec      = Date()
    @State private var showCalendario  = false

    @FocusState private var campoActivo: Bool

    let calendario = Calendar.current

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
        if tipo == "Transferencia" {
            return !cuentaOrigen.isEmpty && !cuentaDestino.isEmpty
        }
        return !categoria.isEmpty
    }

    var tiposDisponibles: [(String, String, String)] {
        [("Egreso",        "📉", t("registrar.egreso")),
         ("Ingreso",       "📈", t("registrar.ingreso")),
         ("Transferencia", "🔄", t("registrar.transferencia"))]
    }

    var fechaLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_CO")
        if calendario.isDateInToday(fechaSelec) {
            return "📅 Hoy — \(fechaFormato("dd MMM yyyy"))"
        } else if calendario.isDateInYesterday(fechaSelec) {
            return "📅 Ayer — \(fechaFormato("dd MMM yyyy"))"
        }
        return "📅 \(fechaFormato("EEEE dd MMM yyyy"))"
    }

    func fechaFormato(_ formato: String) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_CO")
        f.dateFormat = formato
        return f.string(from: fechaSelec)
    }

    var body: some View {
        ZStack {
            Color.fondoApp.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {

                    // Header
                    Text("💰 \(t("registrar.titulo"))")
                        .font(Font.title2.bold()).foregroundColor(.acentoApp)
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
                                cuentaDestino = ""; errorMsg = ""
                                campoActivo = false
                            } label: {
                                Text("\(emoji) \(label)")
                                    .font(Font.caption.bold())
                                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(tipo == key ? colorParaTipo(key) : Color.cardApp)
                                    .foregroundColor(tipo == key ? .white : colorParaTipo(key))
                                    .cornerRadius(12).contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .background(Color.cardApp).cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.bordeApp, lineWidth: 1))

                    // ── SELECTOR DE FECHA ──
                    selectorFecha

                    // Formulario
                    VStack(spacing: 14) {

                        if tipo == "Transferencia" {
                            campoMenu(t("registrar.cuenta_origen"), "arrow.up.circle.fill",
                                      seleccion: cuentaOrigen.isEmpty
                                        ? t("registrar.selecciona_origen") : cuentaOrigen,
                                      opciones: config.cuentas.filter { $0 != cuentaDestino }
                            ) { cuentaOrigen = $0 }

                            campoMenu(t("registrar.cuenta_destino"), "arrow.down.circle.fill",
                                      seleccion: cuentaDestino.isEmpty
                                        ? t("registrar.selecciona_destino") : cuentaDestino,
                                      opciones: config.cuentas.filter { $0 != cuentaOrigen }
                            ) { cuentaDestino = $0 }

                            campoInput(t("registrar.detalle"), "text.alignleft",
                                       texto: $detalle, keyboard: .default)
                            selectorMonedaYValor

                        } else {
                            campoMenu(t("registrar.categoria"), "tag.fill",
                                      seleccion: categoria.isEmpty
                                        ? t("registrar.selecciona_cat") : categoria,
                                      opciones: arbolActual.map { $0.nombre }
                            ) { val in
                                categoria = val; subcategoria = ""; subsubcategoria = ""
                            }

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
                                            ? t("registrar.selecciona_subsub") : subsubcategoria,
                                          opciones: sub.subsubcategorias.map { $0.nombre }
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
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.bordeApp, lineWidth: 1))

                    // Botón guardar
                    Button {
                        campoActivo = false
                        showCalendario = false
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
                            puedeGuardar
                            ? AnyView(
                                tipo == "Transferencia"
                                ? LinearGradient(colors: [Color(hex: "#1565C0"), Color(hex: "#0D47A1")],
                                                 startPoint: .leading, endPoint: .trailing)
                                : tipo == "Egreso"
                                    ? LinearGradient(colors: [Color(hex: "#C62828"), Color(hex: "#B71C1C")],
                                                     startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [Color(hex: "#2E7D32"), Color(hex: "#1B5E20")],
                                                     startPoint: .leading, endPoint: .trailing))
                            : AnyView(Color.textoSecundario.opacity(0.3))
                        )
                        .foregroundColor(puedeGuardar ? .white : .textoSecundario)
                        .cornerRadius(14).contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(guardando || !puedeGuardar)

                    if guardado {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "#4CAF50"))
                            Text(t("registrar.guardado")).font(Font.subheadline.bold())
                                .foregroundColor(Color(hex: "#4CAF50"))
                        }
                        .padding().background(Color(hex: "#1B4332")).cornerRadius(12)
                        .transition(.opacity)
                    }
                }
                .padding()
            }
            .onTapGesture {
                campoActivo = false
                withAnimation { showCalendario = false }
            }
        }
        .preferredColorScheme(theme.temaOscuro ? .dark : .light)
        .id(loc.idioma)
    }

    // MARK: - Selector de fecha CORREGIDO
    var selectorFecha: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FECHA DEL MOVIMIENTO")
                .font(Font.caption.bold()).foregroundColor(.acentoApp).kerning(1.2)

            // Botón que muestra la fecha actual
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showCalendario.toggle()
                    if showCalendario { campoActivo = false }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.circle.fill")
                        .foregroundColor(.acentoApp).font(Font.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(fechaLabel)
                            .font(Font.subheadline).foregroundColor(.textoPrincipal)
                        if !calendario.isDateInToday(fechaSelec) {
                            Text("Fecha modificada")
                                .font(Font.caption2).foregroundColor(Color(hex: "#FF9800"))
                        }
                    }
                    Spacer()
                    Image(systemName: showCalendario ? "chevron.up.circle" : "chevron.down.circle")
                        .foregroundColor(.acentoApp).font(Font.body)
                }
                .padding()
                .background(showCalendario
                    ? Color.acentoApp.opacity(0.1) : Color.inputFondo)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(showCalendario
                        ? Color.acentoApp : Color.bordeApp, lineWidth: 1.5))
            }
            .buttonStyle(PlainButtonStyle())

            // Accesos rápidos siempre visibles
            HStack(spacing: 8) {
                botonFechaRapida("Hoy", Date())
                botonFechaRapida("Ayer", Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
                botonFechaRapida("-2d", Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date())
                botonFechaRapida("-3d", Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date())
            }

            // Calendario expandible
            if showCalendario {
                CalendarioPersonalizado(fechaSeleccionada: $fechaSelec) {
                    // Al seleccionar, cerrar el calendario
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showCalendario = false
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                    removal:   .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                ))
            }
        }
    }

    func botonFechaRapida(_ label: String, _ fecha: Date) -> some View {
        let esActual = calendario.isDate(fechaSelec, inSameDayAs: fecha)
        return Button {
            withAnimation(.spring(response: 0.3)) {
                fechaSelec   = fecha
                showCalendario = false
            }
        } label: {
            Text(label)
                .font(Font.caption.bold())
                .frame(maxWidth: .infinity).padding(.vertical, 8)
                .background(esActual ? Color.acentoApp : Color.cardApp)
                .foregroundColor(esActual ? .white : Color.acentoApp)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.acentoApp.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Selector moneda + valor
    var selectorMonedaYValor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(t("registrar.valor"))
                .font(Font.caption.bold()).foregroundColor(.acentoApp).kerning(1.2)
            HStack(spacing: 0) {
                Menu {
                    Button("🇨🇴 COP") { moneda = "COP" }
                    Button("🇺🇸 USD") { moneda = "USD" }
                } label: {
                    HStack(spacing: 4) {
                        Text(moneda == "COP" ? "🇨🇴" : "🇺🇸").font(Font.body)
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
                    .keyboardType(.decimalPad)
                    .foregroundColor(.textoPrincipal)
                    .focused($campoActivo)
                    .padding(.horizontal, 12).padding(.vertical, 14)
                    .frame(maxWidth: .infinity)

                Text(moneda == "COP" ? "$" : "USD")
                    .font(Font.caption.bold()).foregroundColor(.textoSecundario)
                    .padding(.trailing, 12)
            }
            .background(Color.inputFondo).cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bordeApp, lineWidth: 1))

            if let v = valorDouble, v > 0 {
                Text("= \(formatValor(v, moneda: moneda))")
                    .font(Font.caption).foregroundColor(Color.acentoApp.opacity(0.8))
            } else if !valorTexto.isEmpty {
                Text("⚠️ Valor inválido — usa solo números")
                    .font(Font.caption).foregroundColor(Color(hex: "#FF5252"))
            }
        }
    }

    // MARK: - Componentes
    func colorParaTipo(_ tipo: String) -> Color {
        switch tipo {
        case "Ingreso":       return Color(hex: "#4CAF50")
        case "Transferencia": return Color(hex: "#2196F3")
        default:              return Color(hex: "#FF5252")
        }
    }

    func campoMenu(_ titulo: String, _ icono: String,
                   seleccion: String, opciones: [String],
                   onSelect: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo).font(Font.caption.bold()).foregroundColor(.acentoApp).kerning(1.2)
            Menu {
                ForEach(opciones, id: \.self) { op in
                    Button(op) { campoActivo = false; onSelect(op) }
                }
            } label: {
                HStack {
                    Image(systemName: icono).foregroundColor(.acentoApp).frame(width: 20)
                    Text(seleccion).foregroundColor(
                        seleccion.contains("Selecciona") || seleccion.contains("Select")
                            ? Color.textoSecundario : Color.textoPrincipal)
                    Spacer()
                    Image(systemName: "chevron.down").foregroundColor(.textoSecundario)
                        .font(Font.caption)
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
                TextField("", text: texto)
                    .foregroundColor(.textoPrincipal).keyboardType(keyboard)
                    .focused($campoActivo).submitLabel(.done).onSubmit { campoActivo = false }
            }
            .padding().background(Color.inputFondo).cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bordeApp, lineWidth: 1))
        }
    }

    // MARK: - Firebase
    func guardar() {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMsg = "Error: sesión no válida"; return
        }
        guard let valor = valorDouble, valor > 0 else {
            errorMsg = "Ingresa un valor válido mayor a 0"; return
        }
        if tipo != "Transferencia" && categoria.isEmpty {
            errorMsg = "Selecciona una categoría"; return
        }
        if tipo == "Transferencia" {
            if cuentaOrigen.isEmpty  { errorMsg = "Selecciona cuenta origen";  return }
            if cuentaDestino.isEmpty { errorMsg = "Selecciona cuenta destino"; return }
            if cuentaOrigen == cuentaDestino {
                errorMsg = "Las cuentas no pueden ser iguales"; return
            }
        }

        errorMsg = ""; guardando = true

        let ref = Database.database().reference()
            .child("movimientos").child(uid).childByAutoId()

        // Combinar fecha elegida + hora actual
        var comps  = calendario.dateComponents([.year, .month, .day], from: fechaSelec)
        let ahora  = calendario.dateComponents([.hour, .minute, .second], from: Date())
        comps.hour   = ahora.hour
        comps.minute = ahora.minute
        comps.second = ahora.second
        let fechaFinal    = calendario.date(from: comps) ?? fechaSelec
        let timestampFinal = fechaFinal.timeIntervalSince1970 * 1000

        var data: [String: Any] = [
            "id"             : ref.key ?? UUID().uuidString,
            "tipoTransaccion": tipo,
            "detalle"        : detalle.trimmingCharacters(in: .whitespacesAndNewlines),
            "valor"          : valor,
            "moneda"         : moneda,
            "timestamp"      : timestampFinal
        ]

        if tipo == "Transferencia" {
            data["categoria"]       = "Transferencia"
            data["cuentaOrigen"]    = cuentaOrigen
            data["cuentaDestino"]   = cuentaDestino
            data["cuenta"]          = cuentaDestino
            data["subcategoria"]    = ""
            data["subsubcategoria"] = ""
        } else {
            data["categoria"]       = categoria
            data["subcategoria"]    = subcategoria
            data["subsubcategoria"] = subsubcategoria
            data["cuenta"]          = cuenta
            data["cuentaOrigen"]    = ""
            data["cuentaDestino"]   = ""
        }

        ref.setValue(data) { error, _ in
            DispatchQueue.main.async {
                guardando = false
                if let error {
                    errorMsg = "Error: \(error.localizedDescription)"
                } else {
                    valorTexto = ""; detalle = ""; categoria = ""
                    subcategoria = ""; subsubcategoria = ""; cuenta = ""
                    cuentaOrigen = ""; cuentaDestino = ""; errorMsg = ""
                    fechaSelec = Date()
                    withAnimation { guardado = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { guardado = false }
                    }
                }
            }
        }
    }
}

// MARK: - Calendario Personalizado (funciona 100% sin restricciones raras)
struct CalendarioPersonalizado: View {

    @Binding var fechaSeleccionada: Date
    var alSeleccionar: () -> Void

    @State private var mesActual = Date()
    private let cal = Calendar.current

    var diasEnMes: [Date?] {
        guard let inicio = cal.date(from: cal.dateComponents([.year, .month], from: mesActual)),
              let rango  = cal.range(of: .day, in: .month, for: mesActual) else { return [] }

        let primerDiaSemana = cal.component(.weekday, from: inicio) - 1
        var dias: [Date?] = Array(repeating: nil, count: primerDiaSemana)
        for d in rango {
            if let fecha = cal.date(byAdding: .day, value: d - 1, to: inicio) {
                dias.append(fecha)
            }
        }
        // Completar última fila
        while dias.count % 7 != 0 { dias.append(nil) }
        return dias
    }

    var nombreMes: String {
        let f = DateFormatter()
        f.locale    = Locale(identifier: "es_CO")
        f.dateFormat = "MMMM yyyy"
        return f.string(from: mesActual).capitalized
    }

    let diasSemana = ["Do","Lu","Ma","Mi","Ju","Vi","Sá"]

    var body: some View {
        VStack(spacing: 12) {

            // Navegación mes
            HStack {
                Button {
                    cambiarMes(-1)
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .foregroundColor(.acentoApp).font(Font.title3)
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                Text(nombreMes)
                    .font(Font.headline.bold()).foregroundColor(.textoPrincipal)

                Spacer()

                // Solo avanzar si no estamos en el mes actual
                Button {
                    cambiarMes(1)
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .foregroundColor(
                            esMesActual ? Color.textoSecundario.opacity(0.3) : Color.acentoApp
                        )
                        .font(Font.title3)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(esMesActual)
            }
            .padding(.horizontal, 8)

            // Cabecera días semana
            HStack(spacing: 0) {
                ForEach(diasSemana, id: \.self) { dia in
                    Text(dia)
                        .font(Font.caption2.bold())
                        .foregroundColor(.textoSecundario)
                        .frame(maxWidth: .infinity)
                }
            }

            // Grid de días
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7),
                      spacing: 6) {
                ForEach(Array(diasEnMes.enumerated()), id: \.offset) { _, fecha in
                    if let fecha {
                        let esHoy       = cal.isDateInToday(fecha)
                        let esSelec     = cal.isDate(fecha, inSameDayAs: fechaSeleccionada)
                        let esFuturo    = fecha > Date()

                        Button {
                            if !esFuturo {
                                fechaSeleccionada = fecha
                                alSeleccionar()
                            }
                        } label: {
                            Text("\(cal.component(.day, from: fecha))")
                                .font(Font.subheadline.bold())
                                .frame(width: 38, height: 38)
                                .background(
                                    esSelec ? Color.acentoApp
                                        : esHoy ? Color.acentoApp.opacity(0.2)
                                        : Color.clear
                                )
                                .foregroundColor(
                                    esFuturo ? Color.textoSecundario.opacity(0.25)
                                        : esSelec ? .white
                                        : esHoy ? Color.acentoApp
                                        : Color.textoPrincipal
                                )
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(
                                        esHoy && !esSelec
                                            ? Color.acentoApp.opacity(0.5) : Color.clear,
                                        lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(esFuturo)
                    } else {
                        Color.clear.frame(width: 38, height: 38)
                    }
                }
            }

            // Botón "Ir a hoy"
            if !esMesActual {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        mesActual      = Date()
                        fechaSeleccionada = Date()
                        alSeleccionar()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.clock")
                        Text("Ir a hoy")
                            .fontWeight(.semibold)
                    }
                    .font(Font.caption)
                    .frame(maxWidth: .infinity).padding(10)
                    .background(Color.acentoApp.opacity(0.15)).cornerRadius(10)
                    .foregroundColor(.acentoApp)
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.acentoApp.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(12)
        .background(Color.cardApp).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(Color.acentoApp.opacity(0.4), lineWidth: 1.5))
        .shadow(color: Color.black.opacity(0.18), radius: 10, y: 4)
        .onAppear {
            // Iniciar el calendario en el mes de la fecha seleccionada
            mesActual = fechaSeleccionada
        }
    }

    var esMesActual: Bool {
        cal.isDate(mesActual, equalTo: Date(), toGranularity: .month)
    }

    func cambiarMes(_ delta: Int) {
        withAnimation(.spring(response: 0.3)) {
            if let nuevo = cal.date(byAdding: .month, value: delta, to: mesActual) {
                // No permitir avanzar más allá del mes actual
                if delta > 0 && cal.isDate(nuevo, equalTo: Date(), toGranularity: .month) {
                    mesActual = nuevo
                } else if delta > 0 && nuevo > Date() {
                    return
                } else {
                    mesActual = nuevo
                }
            }
        }
    }
}
