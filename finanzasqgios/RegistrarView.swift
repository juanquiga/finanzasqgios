import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct RegistrarView: View {

    @StateObject private var config = ConfigManager.shared

    @State private var tipo           = "Egreso"
    @State private var categoria      = ""
    @State private var subcategoria   = ""
    @State private var subsubcategoria = ""
    @State private var detalle        = ""
    @State private var valor          = ""
    @State private var cuenta         = ""
    @State private var guardando      = false
    @State private var guardado       = false

    var arbolActual: [CategoriaItem] {
        tipo == "Egreso" ? config.egresosTree : config.ingresosTree
    }

    var catSeleccionada: CategoriaItem? {
        arbolActual.first { $0.nombre == categoria }
    }

    var subSeleccionada: SubcategoriaItem? {
        catSeleccionada?.subcategorias.first { $0.nombre == subcategoria }
    }

    var body: some View {
        ZStack {
            Color.fondo.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {

                    // Header
                    Text("💰 Registrar Movimiento")
                        .font(.title2.bold()).foregroundColor(.verdeApp)
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.card).cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.borde, lineWidth: 1))

                    // Egreso / Ingreso
                    HStack(spacing: 0) {
                        botonTipo("📉  Egreso",  "Egreso",  .rojoApp)
                        botonTipo("📈  Ingreso", "Ingreso", .verdeApp)
                    }
                    .background(Color.card).cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.borde, lineWidth: 1))

                    VStack(spacing: 14) {

                        // Categoría
                        campoMenu("CATEGORÍA", "tag.fill",
                                  seleccion: categoria.isEmpty
                                    ? "Selecciona categoría" : categoria,
                                  opciones: arbolActual.map { $0.nombre }) { val in
                            categoria = val
                            subcategoria = ""
                            subsubcategoria = ""
                        }

                        // Subcategoría
                        if let cat = catSeleccionada,
                           !cat.subcategorias.isEmpty {
                            campoMenu("SUBCATEGORÍA", "list.bullet",
                                      seleccion: subcategoria.isEmpty
                                        ? "Selecciona subcategoría" : subcategoria,
                                      opciones: cat.subcategorias.map { $0.nombre }) { val in
                                subcategoria = val
                                subsubcategoria = ""
                            }
                        }

                        // Subsubcategoría
                        if let sub = subSeleccionada,
                           !sub.subsubcategorias.isEmpty {
                            campoMenu("SUBSUBCATEGORÍA", "arrow.turn.down.right",
                                      seleccion: subsubcategoria.isEmpty
                                        ? "Selecciona opción" : subsubcategoria,
                                      opciones: sub.subsubcategorias) { val in
                                subsubcategoria = val
                            }
                        }

                        // Detalle
                        campoInput("DETALLE (opcional)", "text.alignleft",
                                   texto: $detalle, keyboard: .default)

                        // Valor
                        campoInput("VALOR ($)", "dollarsign.circle.fill",
                                   texto: $valor, keyboard: .decimalPad)

                        // Cuenta
                        if !config.cuentas.isEmpty {
                            campoMenu("CUENTA", "creditcard.fill",
                                      seleccion: cuenta.isEmpty
                                        ? "Selecciona cuenta" : cuenta,
                                      opciones: config.cuentas) { val in
                                cuenta = val
                            }
                        }
                    }
                    .padding()
                    .background(Color.card).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.borde, lineWidth: 1))

                    // Guardar
                    Button(action: guardar) {
                        HStack {
                            if guardando { ProgressView().tint(.white) }
                            else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("GUARDAR MOVIMIENTO").fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(tipo == "Egreso"
                            ? LinearGradient(colors: [Color(hex: "#C62828"),
                                                      Color(hex: "#B71C1C")],
                                             startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color(hex: "#2E7D32"),
                                                      Color(hex: "#1B5E20")],
                                             startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white).cornerRadius(14)
                    }
                    .disabled(guardando || valor.isEmpty || categoria.isEmpty)

                    if guardado {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.verdeApp)
                            Text("¡Movimiento guardado!").foregroundColor(.verdeApp)
                        }
                        .padding()
                        .background(Color(hex: "#1B4332")).cornerRadius(12)
                        .transition(.opacity)
                    }
                }
                .padding()
            }
        }
    }

    func botonTipo(_ label: String, _ tag: String, _ color: Color) -> some View {
        Button(label) {
            tipo = tag; categoria = ""
            subcategoria = ""; subsubcategoria = ""
        }
        .font(.subheadline.bold())
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(tipo == tag ? color : Color.clear)
        .foregroundColor(tipo == tag ? .white : color)
        .cornerRadius(13)
    }

    func campoMenu(_ titulo: String, _ icono: String,
                   seleccion: String, opciones: [String],
                   onSelect: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo).font(.caption.bold()).foregroundColor(.verdeApp).kerning(1.2)
            Menu {
                ForEach(opciones, id: \.self) { op in
                    Button(op) { onSelect(op) }
                }
            } label: {
                HStack {
                    Image(systemName: icono).foregroundColor(.verdeApp).frame(width: 20)
                    Text(seleccion)
                        .foregroundColor(seleccion.contains("Selecciona")
                            ? .grisTexto : .white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.grisTexto).font(.caption)
                }
                .padding()
                .background(Color(hex: "#0D1A2A")).cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borde, lineWidth: 1))
            }
        }
    }

    func campoInput(_ titulo: String, _ icono: String,
                    texto: Binding<String>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo).font(.caption.bold()).foregroundColor(.verdeApp).kerning(1.2)
            HStack(spacing: 12) {
                Image(systemName: icono).foregroundColor(.verdeApp).frame(width: 20)
                TextField("", text: texto)
                    .foregroundColor(.white).keyboardType(keyboard)
            }
            .padding()
            .background(Color(hex: "#0D1A2A")).cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(Color.borde, lineWidth: 1))
        }
    }

    func guardar() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let valorDouble = Double(valor), valorDouble > 0 else { return }
        guard !categoria.isEmpty else { return }

        guardando = true
        let ref = Database.database().reference()
            .child("movimientos").child(uid).childByAutoId()

        let data: [String: Any] = [
            "id":               ref.key ?? "",
            "tipoTransaccion":  tipo,
            "categoria":        categoria,
            "subcategoria":     subcategoria,
            "subsubcategoria":  subsubcategoria,
            "detalle":          detalle,
            "valor":            valorDouble,
            "cuenta":           cuenta,
            "timestamp":        Date().timeIntervalSince1970 * 1000
        ]

        ref.setValue(data) { error, _ in
            guardando = false
            if error == nil {
                valor = ""; detalle = ""; subcategoria = ""
                subsubcategoria = ""; categoria = ""
                withAnimation { guardado = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { guardado = false }
                }
            }
        }
    }
}
