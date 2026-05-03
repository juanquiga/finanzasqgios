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

    let cal = Calendar.current

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
        if cal.isDateInToday(fechaSelec) {
            f.dateFormat = "'Hoy —' dd MMM yyyy"
        } else if cal.isDateInYesterday(fechaSelec) {
            f.dateFormat = "'Ayer —' dd MMM yyyy"
        } else {
            f.dateFormat = "EEEE dd 'de' MMMM yyyy"
        }
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
                                ? LinearGradient(
                                    colors: [Color(hex: "#1565C0"), Color(hex: "#0D47A1")],
                                    startPoint: .leading, endPoint: .trailing)
                                : tipo == "Egreso"
                                    ? LinearGradient(
                                        colors: [Color(hex: "#C62828"), Color(hex: "#B71C1C")],
                                        startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(
                                        colors: [Color(hex: "#2E7D32"), Color(hex: "#1B5E20")],
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
        // Actualizar fecha a hoy cada vez que se abre la vista
        .onAppear {
            fechaSelec = Date()
        }
    }

    // MARK: - Selector de fecha
    var selectorFecha: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FECHA DEL MOVIMIENTO")
                .font(Font.caption.bold()).foregroundColor(.acentoApp).kerning(1.2)

            // Botón principal
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
                        Text(fechaLabel.capitalized)
                            .font(Font.subheadline).foregroundColor(.textoPrincipal)
                        Text(cal.isDateInToday(fechaSelec)
                             ? "Toca para cambiar la fecha"
                             : "Fecha personalizada — toca para cambiar")
                            .font(Font.caption2)
                            .foregroundColor(cal.isDateInToday(fechaSelec)
                                             ? Color.textoSecundario
                                             : Color(hex: "#FF9800"))
                    }
                    Spacer()
                    Image(systemName: showCalendario
                          ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .foregroundColor(.acentoApp).font(Font.body)
                }
                .padding()
                .background(showCalendario
                    ? Color.acentoApp.opacity(0.1) : Color.inputFondo)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(showCalendario ? Color.acentoApp : Color.bordeApp, lineWidth: 1.5))
            }
            .buttonStyle(PlainButtonStyle())

            // Calendario expandible
            if showCalendario {
                CalendarioPersonalizado(fechaSeleccionada: $fechaSelec) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showCalendario = false
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.97, anchor: .top)),
                    removal:   .opacity.combined(with: .scale(scale: 0.97, anchor: .top))
                ))
            }
        }
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
                    .focused($campoActivo).submitLabel(.done)
                    .onSubmit { campoActivo = false }
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

        // Combinar fecha elegida + hora actual para el timestamp
        var comps  = cal.dateComponents([.year, .month, .day], from: fechaSelec)
        let ahora  = cal.dateComponents([.hour, .minute, .second], from: Date())
        comps.hour   = ahora.hour
        comps.minute = ahora.minute
        comps.second = ahora.second
        let fechaFinal     = cal.date(from: comps) ?? fechaSelec
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
                    subcategoria = ""; subsubcategoria = ""
                    cuenta = ""; cuentaOrigen = ""; cuentaDestino = ""
                    errorMsg = ""
                    fechaSelec = Date() // reset a hoy
                    withAnimation { guardado = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { guardado = false }
                    }
                }
            }
        }
    }
}

// MARK: - Calendario Personalizado
struct CalendarioPersonalizado: View {

    @Binding var fechaSeleccionada: Date
    var alSeleccionar: () -> Void

    @State private var mesVisible = Date()
    private let cal = Calendar.current

    // Días del mes incluyendo espacios vacíos al inicio
    var diasEnMes: [Date?] {
        guard
            let inicioDeMes = cal.date(
                from: cal.dateComponents([.year, .month], from: mesVisible)),
            let cantDias = cal.range(of: .day, in: .month, for: mesVisible)
        else { return [] }

        // weekday: 1=domingo ... 7=sábado
        let offset = cal.component(.weekday, from: inicioDeMes) - 1
        var lista: [Date?] = Array(repeating: nil, count: offset)

        for d in cantDias {
            if let fecha = cal.date(byAdding: .day, value: d - 1, to: inicioDeMes) {
                lista.append(fecha)
            }
        }
        // Completar la última fila para que sea múltiplo de 7
        while lista.count % 7 != 0 { lista.append(nil) }
        return lista
    }

    var tituloMes: String {
        let f = DateFormatter()
        f.locale     = Locale(identifier: "es_CO")
        f.dateFormat = "MMMM  yyyy"
        return f.string(from: mesVisible).capitalized
    }

    var esMesActual: Bool {
        cal.isDate(mesVisible, equalTo: Date(), toGranularity: .month)
    }

    let cabecera = ["Do","Lu","Ma","Mi","Ju","Vi","Sá"]

    var body: some View {
        VStack(spacing: 10) {

            // ── Navegación de mes ──
            HStack {
                // Retroceder — sin límite
                Button {
                    mover(-1)
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(Font.title2).foregroundColor(.acentoApp)
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                Text(tituloMes)
                    .font(Font.headline.bold()).foregroundColor(.textoPrincipal)

                Spacer()

                // Avanzar — bloqueado en mes actual
                Button {
                    mover(1)
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(Font.title2)
                        .foregroundColor(esMesActual
                            ? Color.textoSecundario.opacity(0.25) : Color.acentoApp)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(esMesActual)
            }
            .padding(.horizontal, 4)

            // ── Cabecera días semana ──
            HStack(spacing: 0) {
                ForEach(cabecera, id: \.self) { d in
                    Text(d)
                        .font(Font.caption2.bold())
                        .foregroundColor(.textoSecundario)
                        .frame(maxWidth: .infinity)
                }
            }

            // ── Grid días ──
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
                spacing: 8
            ) {
                ForEach(Array(diasEnMes.enumerated()), id: \.offset) { _, diaOpt in
                    if let dia = diaOpt {
                        diaBoton(dia)
                    } else {
                        Color.clear.frame(height: 38)
                    }
                }
            }

            // ── Botón "Ir a hoy" (solo si no estamos en el mes actual) ──
            if !esMesActual {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        mesVisible         = Date()
                        fechaSeleccionada  = Date()
                        alSeleccionar()
                    }
                } label: {
                    Label("Ir a hoy", systemImage: "calendar.badge.clock")
                        .font(Font.caption.bold()).foregroundColor(.acentoApp)
                        .frame(maxWidth: .infinity).padding(10)
                        .background(Color.acentoApp.opacity(0.1)).cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.acentoApp.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(14)
        .background(Color.cardApp)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18)
            .stroke(Color.acentoApp.opacity(0.35), lineWidth: 1.5))
        .shadow(color: Color.black.opacity(0.2), radius: 12, y: 5)
        .onAppear {
            // Abrir en el mes de la fecha actualmente seleccionada
            mesVisible = fechaSeleccionada
        }
    }

    // MARK: - Botón de día individual
    @ViewBuilder
    func diaBoton(_ dia: Date) -> some View {
        let esHoy    = cal.isDateInToday(dia)
        let esSelec  = cal.isDate(dia, inSameDayAs: fechaSeleccionada)
        let esFuturo = dia > Date()
        let numero   = cal.component(.day, from: dia)

        Button {
            guard !esFuturo else { return }
            withAnimation(.spring(response: 0.2)) {
                fechaSeleccionada = dia
            }
            // Pequeño delay para que se vea la selección antes de cerrar
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                alSeleccionar()
            }
        } label: {
            ZStack {
                // Fondo seleccionado
                if esSelec {
                    Circle()
                        .fill(Color.acentoApp)
                        .frame(width: 36, height: 36)
                }
                // Borde "hoy" (solo si no está seleccionado)
                if esHoy && !esSelec {
                    Circle()
                        .stroke(Color.acentoApp, lineWidth: 1.5)
                        .frame(width: 36, height: 36)
                }
                Text("\(numero)")
                    .font(esSelec ? Font.subheadline.bold() : Font.subheadline)
                    .foregroundColor(
                        esFuturo ? Color.textoSecundario.opacity(0.2)
                            : esSelec ? .white
                            : esHoy   ? Color.acentoApp
                            : Color.textoPrincipal
                    )
            }
            .frame(width: 38, height: 38)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(esFuturo)
    }

    func mover(_ delta: Int) {
        withAnimation(.spring(response: 0.3)) {
            if let nuevo = cal.date(byAdding: .month, value: delta, to: mesVisible) {
                // Si intenta avanzar más allá del mes actual, bloquear
                if delta > 0 && nuevo > Date() { return }
                mesVisible = nuevo
            }
        }
    }
}
