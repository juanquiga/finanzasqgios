import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct SetupCompletoView: View {

    @ObservedObject var theme = ThemeManager.shared
    @State private var paso   = 1

    var body: some View {
        ZStack {
            Color.fondoApp.ignoresSafeArea()
            if paso == 1 {
                SetupPaso1View(onContinuar: {
                    withAnimation(.spring(response: 0.4)) { paso = 2 }
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal:   .move(edge: .leading)))
            } else {
                SetupPaso2View(onContinuar: {
                    irAApp()
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal:   .move(edge: .leading)))
            }
        }
        .preferredColorScheme(theme.temaOscuro ? .dark : .light)
    }

    func irAApp() {
        if let uid = Auth.auth().currentUser?.uid {
            Database.database().reference()
                .child("users").child(uid).child("isNewUser").setValue(false)
        }
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController = UIHostingController(rootView: MainTabView())
            window.makeKeyAndVisible()
        }
    }
}

// ─────────────────────────────────────────────────────
// PASO 1: Categorías y cuentas
// ─────────────────────────────────────────────────────
struct SetupPaso1View: View {

    @ObservedObject var theme  = ThemeManager.shared
    @StateObject private var config = ConfigManager.shared
    @State private var seccion     = "egresos"
    @State private var guardando   = false
    @State private var catEditando : CategoriaItem? = nil
    var onContinuar: () -> Void

    var arbolActual: Binding<[CategoriaItem]> {
        seccion == "egresos" ? $config.egresosTree : $config.ingresosTree
    }

    var body: some View {
        VStack(spacing: 0) {

            pasoHeader(actual: 1, total: 2,
                       titulo: "🗂️ Tus categorías",
                       subtitulo: "Personaliza cómo organizas tus finanzas")

            Picker("", selection: $seccion) {
                Text("Egresos").tag("egresos")
                Text("Ingresos").tag("ingresos")
                Text("Cuentas").tag("cuentas")
            }
            .pickerStyle(.segmented).padding(.horizontal).padding(.bottom, 12)

            ScrollView {
                VStack(spacing: 12) {
                    switch seccion {
                    case "cuentas": vistaCuentas
                    default:        vistaCategorias
                    }
                }
                .padding()
            }

            Button {
                guardando = true
                config.guardar()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    guardando = false
                    onContinuar()
                }
            } label: {
                HStack {
                    if guardando { ProgressView().tint(.white) }
                    else {
                        Text("Continuar al presupuesto").fontWeight(.bold)
                        Image(systemName: "arrow.right")
                    }
                }
                .frame(maxWidth: .infinity).padding()
                .background(Color.gradienteBoton)
                .foregroundColor(.white).cornerRadius(14).padding()
            }
            .disabled(guardando)
        }
        .background(Color.fondoApp.ignoresSafeArea())
        .sheet(item: $catEditando) { cat in
            EditarCategoriaView(
                categoria: bindingParaCat(cat.id),
                onSave: { catEditando = nil })
        }
    }

    var vistaCategorias: some View {
        VStack(spacing: 10) {
            infoCard("Estas son tus categorías predeterminadas. Puedes editarlas, agregar nuevas o eliminarlas. Los presupuestos los configuras en el siguiente paso.")

            Button {
                arbolActual.wrappedValue.append(CategoriaItem(nombre: "Nueva categoría"))
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill").foregroundColor(.acentoApp)
                    Text("Agregar categoría").foregroundColor(.acentoApp).fontWeight(.semibold)
                    Spacer()
                }
                .padding().background(Color.cardApp).cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.acentoApp.opacity(0.5), lineWidth: 1))
            }

            ForEach(arbolActual) { $cat in
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Image(systemName: "folder.fill").foregroundColor(.acentoApp).frame(width: 24)
                        Text(cat.nombre).font(Font.subheadline.bold()).foregroundColor(.textoPrincipal)
                        Spacer()
                        Button { catEditando = cat } label: {
                            Image(systemName: "pencil.circle").foregroundColor(Color.acentoApp.opacity(0.8))
                        }
                        Button { arbolActual.wrappedValue.removeAll { $0.id == cat.id } } label: {
                            Image(systemName: "trash").foregroundColor(Color(hex: "#FF5252").opacity(0.7))
                        }
                    }
                    .padding()

                    Divider().background(Color.bordeApp).padding(.leading, 44)

                    ForEach($cat.subcategorias) { $sub in
                        HStack {
                            Image(systemName: "chevron.right")
                                .font(Font.caption).foregroundColor(.textoSecundario).padding(.leading, 20)
                            Text(sub.nombre).font(Font.caption).foregroundColor(.textoPrincipal)
                            Spacer()
                            Button { cat.subcategorias.removeAll { $0.id == sub.id } } label: {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(Color(hex: "#FF5252").opacity(0.6)).font(Font.caption)
                            }
                        }
                        .padding(.vertical, 8).padding(.horizontal)
                    }

                    AgregarSubView(cat: $cat)
                }
                .background(Color.cardApp).cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bordeApp, lineWidth: 1))
            }
        }
    }

    var vistaCuentas: some View {
        VStack(spacing: 10) {
            infoCard("Agrega tus cuentas bancarias o de efectivo. Podrás registrar en qué cuenta entra o sale cada movimiento.")
            AgregarCuentaView(cuentas: $config.cuentas)
            ForEach($config.cuentas, id: \.self) { $cta in
                HStack(spacing: 12) {
                    Image(systemName: "creditcard.fill").foregroundColor(.acentoApp)
                    TextField("Cuenta", text: $cta).foregroundColor(.textoPrincipal)
                    Spacer()
                    Button { config.cuentas.removeAll { $0 == cta } } label: {
                        Image(systemName: "trash").foregroundColor(Color(hex: "#FF5252").opacity(0.7))
                    }
                }
                .padding().background(Color.cardApp).cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bordeApp, lineWidth: 1))
            }
        }
    }

    func bindingParaCat(_ catId: String) -> Binding<CategoriaItem> {
        Binding(
            get: { arbolActual.wrappedValue.first { $0.id == catId } ?? CategoriaItem() },
            set: { nuevo in
                if let idx = arbolActual.wrappedValue.firstIndex(where: { $0.id == catId }) {
                    arbolActual.wrappedValue[idx] = nuevo
                }
            }
        )
    }
}

// ─────────────────────────────────────────────────────
// PASO 2: Presupuesto
// ─────────────────────────────────────────────────────
struct SetupPaso2View: View {

    @ObservedObject var theme  = ThemeManager.shared
    @StateObject private var config = ConfigManager.shared
    @State private var guardando    = false
    @State private var catExpandida = ""
    var onContinuar: () -> Void

    // Total calculado desde presupuestoTotal (computed, solo lectura)
    var presupuestoTotal: Double {
        config.egresosTree.reduce(0) { $0 + $1.presupuestoTotal }
    }

    var body: some View {
        VStack(spacing: 0) {

            pasoHeader(actual: 2, total: 2,
                       titulo: "💰 Tu presupuesto",
                       subtitulo: "Define tus límites de gasto mensuales")

            ScrollView {
                VStack(spacing: 16) {

                    infoCard("Los presupuestos son opcionales — puedes dejarlos en 0 y configurarlos después en Configuración → Presupuesto. Se sincronizan con Android automáticamente.")

                    // Resumen total (solo lectura, calculado automáticamente)
                    if presupuestoTotal > 0 {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TOTAL PRESUPUESTADO").font(Font.caption.bold())
                                    .foregroundColor(.textoSecundario).kerning(1.2)
                                Text(formatCOP(presupuestoTotal))
                                    .font(Font.title2.bold()).foregroundColor(.acentoApp)
                            }
                            Spacer()
                            Image(systemName: "checkmark.seal.fill")
                                .font(Font.title).foregroundColor(.acentoApp.opacity(0.3))
                        }
                        .padding().background(Color.cardApp).cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.acentoApp.opacity(0.4), lineWidth: 1.5))
                    }

                    // ── GENERAL ──
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "gauge.with.needle.fill").foregroundColor(.acentoApp)
                            Text("PRESUPUESTO GENERAL").font(Font.subheadline.bold())
                                .foregroundColor(.textoPrincipal)
                        }
                        campoPres("🇨🇴 Máximo mensual COP",
                                  valor: $config.presupuestoMaxCOP,
                                  preview: config.presupuestoMaxCOP > 0
                                    ? formatCOP(config.presupuestoMaxCOP) + "/mes" : nil)
                        campoPres("🇺🇸 Máximo mensual USD",
                                  valor: $config.presupuestoMaxUSD,
                                  preview: config.presupuestoMaxUSD > 0
                                    ? formatValor(config.presupuestoMaxUSD, moneda: "USD") + "/mes" : nil)
                    }
                    .padding().background(Color.cardApp).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.acentoApp.opacity(0.4), lineWidth: 1.5))

                    // ── POR CATEGORÍA ──
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "tag.fill").foregroundColor(Color(hex: "#FF9800"))
                            Text("POR CATEGORÍA DE EGRESO").font(Font.subheadline.bold())
                                .foregroundColor(.textoPrincipal)
                        }
                        Text("Expande cada categoría para ver y configurar sus subcategorías. El total se calcula automáticamente.")
                            .font(Font.caption2).foregroundColor(.textoSecundario)

                        if config.egresosTree.isEmpty {
                            Text("No hay categorías de egresos configuradas.")
                                .font(Font.caption).foregroundColor(.textoSecundario)
                                .padding(10).frame(maxWidth: .infinity)
                                .background(Color.inputFondo).cornerRadius(10)
                        } else {
                            // Iterar con índice para poder modificar via $config.egresosTree[idx]
                            ForEach(config.egresosTree.indices, id: \.self) { catIdx in
                                filaCategoriaPresupuesto(catIdx: catIdx)
                            }
                        }
                    }
                    .padding().background(Color.cardApp).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "#FF9800").opacity(0.4), lineWidth: 1.5))

                    HStack(spacing: 8) {
                        Image(systemName: "info.circle").foregroundColor(.textoSecundario)
                        Text("Puedes modificar estos presupuestos después en Configuración → Presupuesto")
                            .font(Font.caption2).foregroundColor(.textoSecundario)
                    }
                    .padding(10).background(Color.cardApp).cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.bordeApp, lineWidth: 1))
                }
                .padding()
            }

            VStack(spacing: 10) {
                Button {
                    guardando = true
                    config.guardar()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        guardando = false
                        onContinuar()
                    }
                } label: {
                    HStack {
                        if guardando { ProgressView().tint(.white) }
                        else {
                            Image(systemName: "checkmark.circle.fill")
                            Text("¡Guardar y empezar!").fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity).padding()
                    .background(LinearGradient(
                        colors: [Color(hex: "#4CAF50"), Color(hex: "#2E7D32")],
                        startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.white).cornerRadius(14)
                }
                .disabled(guardando)

                Button { onContinuar() } label: {
                    Text("Configurar presupuesto después")
                        .font(Font.caption).foregroundColor(.textoSecundario)
                }
            }
            .padding(.horizontal, 24).padding(.bottom, 30)
        }
        .background(Color.fondoApp.ignoresSafeArea())
    }

    // ── Fila categoría expandible ──
    // Usa índice directo para modificar $config.egresosTree[catIdx].presupuesto
    func filaCategoriaPresupuesto(catIdx: Int) -> some View {
        let cat = config.egresosTree[catIdx]

        return VStack(spacing: 0) {
            // Cabecera categoría
            Button {
                withAnimation(.spring(response: 0.3)) {
                    catExpandida = catExpandida == cat.id ? "" : cat.id
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: catExpandida == cat.id ? "chevron.down" : "chevron.right")
                        .foregroundColor(.acentoApp).font(Font.caption).frame(width: 16)
                    Image(systemName: "folder.fill").foregroundColor(.acentoApp).frame(width: 18)
                    Text(cat.nombre).font(Font.subheadline.bold()).foregroundColor(.textoPrincipal)
                    Spacer()
                    // Mostrar total calculado (read-only)
                    if cat.presupuestoTotal > 0 {
                        Text(formatCOP(cat.presupuestoTotal))
                            .font(Font.caption.bold()).foregroundColor(.acentoApp)
                    } else {
                        Text("Sin límite").font(Font.caption2).foregroundColor(.textoSecundario)
                    }
                }
                .padding(12).background(Color.inputFondo).cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())

            if catExpandida == cat.id {
                VStack(spacing: 8) {

                    // Presupuesto propio de la categoría — usa .presupuesto (writable)
                    campoPresInline(
                        label: "Presupuesto de \"\(cat.nombre)\"",
                        valor: Binding(
                            get: { config.egresosTree[catIdx].presupuesto },
                            set: { config.egresosTree[catIdx].presupuesto = $0 }
                        )
                    )

                    // Subcategorías
                    ForEach(cat.subcategorias.indices, id: \.self) { subIdx in
                        filaSubcategoriaPresupuesto(catIdx: catIdx, subIdx: subIdx)
                    }
                }
                .padding(.leading, 16).padding(.vertical, 8)
            }
        }
        .background(Color.cardApp).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(catExpandida == cat.id
                    ? Color.acentoApp.opacity(0.3) : Color.bordeApp, lineWidth: 1))
    }

    // ── Fila subcategoría ──
    func filaSubcategoriaPresupuesto(catIdx: Int, subIdx: Int) -> some View {
        let sub = config.egresosTree[catIdx].subcategorias[subIdx]

        return VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet").foregroundColor(.textoSecundario).frame(width: 16)
                Text(sub.nombre).font(Font.subheadline).foregroundColor(.textoPrincipal)
                Spacer()
                if sub.presupuestoTotal > 0 {
                    Text(formatCOP(sub.presupuestoTotal))
                        .font(Font.caption2.bold()).foregroundColor(.acentoApp)
                }
            }

            // Presupuesto propio subcategoría — usa .presupuesto (writable)
            campoPresInline(
                label: "Presupuesto subcategoría",
                valor: Binding(
                    get: { config.egresosTree[catIdx].subcategorias[subIdx].presupuesto },
                    set: { config.egresosTree[catIdx].subcategorias[subIdx].presupuesto = $0 }
                )
            )

            // Subsubcategorías
            if !sub.subsubcategorias.isEmpty {
                VStack(spacing: 4) {
                    ForEach(sub.subsubcategorias.indices, id: \.self) { ssubIdx in
                        let ssub = config.egresosTree[catIdx].subcategorias[subIdx].subsubcategorias[ssubIdx]
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.turn.down.right")
                                .font(Font.caption2).foregroundColor(.textoSecundario.opacity(0.6))
                            Text(ssub.nombre)
                                .font(Font.caption).foregroundColor(.textoPrincipal).frame(minWidth: 60)
                            Spacer()
                            // TextField directo con índice — presupuesto (writable)
                            TextField("0",
                                value: Binding(
                                    get: { config.egresosTree[catIdx].subcategorias[subIdx].subsubcategorias[ssubIdx].presupuesto },
                                    set: { config.egresosTree[catIdx].subcategorias[subIdx].subsubcategorias[ssubIdx].presupuesto = $0 }
                                ),
                                format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.textoPrincipal)
                                .frame(width: 90)
                                .padding(6)
                                .background(Color.inputFondo).cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8)
                                    .stroke(ssub.presupuesto > 0
                                            ? Color.acentoApp : Color.bordeApp, lineWidth: 1))
                            Text("$").font(Font.caption2).foregroundColor(.textoSecundario)
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(8).background(Color.inputFondo.opacity(0.5)).cornerRadius(8)
            }
        }
        .padding(8).background(Color.inputFondo.opacity(0.5)).cornerRadius(10)
    }

    // ── Campos de presupuesto ──
    func campoPres(_ titulo: String, valor: Binding<Double>, preview: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo).font(Font.caption.bold()).foregroundColor(.acentoApp)
            HStack(spacing: 10) {
                Image(systemName: "dollarsign.circle.fill").foregroundColor(.acentoApp).frame(width: 20)
                TextField("0", value: valor, format: .number)
                    .foregroundColor(.textoPrincipal).keyboardType(.decimalPad)
                if valor.wrappedValue > 0 {
                    Button { valor.wrappedValue = 0 } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.textoSecundario)
                    }
                }
            }
            .padding().background(Color.inputFondo).cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bordeApp, lineWidth: 1))
            if let p = preview {
                Label(p, systemImage: "checkmark.circle.fill")
                    .font(Font.caption).foregroundColor(Color(hex: "#4CAF50"))
            }
        }
    }

    func campoPresInline(label: String, valor: Binding<Double>) -> some View {
        HStack(spacing: 8) {
            Text(label).font(Font.caption).foregroundColor(.textoSecundario)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("0", value: valor, format: .number)
                .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                .foregroundColor(.textoPrincipal).frame(width: 100)
                .padding(8).background(Color.inputFondo).cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(valor.wrappedValue > 0
                            ? Color.acentoApp : Color.bordeApp, lineWidth: 1))
            Text("$").font(Font.caption2).foregroundColor(.textoSecundario)
        }
        .padding(8).background(Color.inputFondo.opacity(0.4)).cornerRadius(8)
    }
}

// ─────────────────────────────────────────────────────
// MARK: - Helpers globales
// ─────────────────────────────────────────────────────
func pasoHeader(actual: Int, total: Int, titulo: String, subtitulo: String) -> some View {
    VStack(spacing: 8) {
        HStack(spacing: 8) {
            ForEach(1...total, id: \.self) { paso in
                HStack(spacing: 4) {
                    Circle()
                        .fill(paso <= actual ? Color.acentoApp : Color.bordeApp)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text("\(paso)").font(Font.caption.bold())
                                .foregroundColor(paso <= actual ? .white : .textoSecundario)
                        )
                    if paso < total {
                        Rectangle()
                            .fill(paso < actual ? Color.acentoApp : Color.bordeApp)
                            .frame(height: 2).frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.horizontal, 40).padding(.top, 16)

        Text(titulo).font(Font.title2.bold()).foregroundColor(.acentoApp)
        Text(subtitulo).font(Font.caption).foregroundColor(.textoSecundario)
    }
    .padding(.bottom, 12)
}

func infoCard(_ texto: String) -> some View {
    HStack(spacing: 10) {
        Image(systemName: "lightbulb.fill").foregroundColor(Color(hex: "#FF9800"))
        Text(texto).font(Font.caption2).foregroundColor(.textoSecundario)
    }
    .padding(10)
    .background(Color(hex: "#1A1200"))
    .cornerRadius(10)
    .overlay(RoundedRectangle(cornerRadius: 10)
        .stroke(Color(hex: "#FF9800").opacity(0.3), lineWidth: 1))
}
