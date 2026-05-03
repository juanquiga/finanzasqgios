import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct SetupCategoriasView: View {

    var modoInicial: Bool = true

    @ObservedObject var theme  = ThemeManager.shared
    @StateObject private var config = ConfigManager.shared
    @State private var seccion    = "egresos"
    @State private var guardando  = false
    @State private var catEditando: CategoriaItem? = nil
    @Environment(\.dismiss) var dismiss

    var arbolActual: Binding<[CategoriaItem]> {
        seccion == "egresos" ? $config.egresosTree : $config.ingresosTree
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fondoApp.ignoresSafeArea()
                VStack(spacing: 0) {

                    VStack(spacing: 4) {
                        Text("🎯 Personalización")
                            .font(Font.title2.bold()).foregroundColor(.acentoApp)
                        Text("Categorías y cuentas — solo tuyas")
                            .font(Font.caption).foregroundColor(.textoSecundario)
                    }
                    .padding(.top, 16).padding(.bottom, 12)

                    // Solo 3 tabs: Egresos, Ingresos, Cuentas
                    // Los presupuestos se editan en "Presupuesto" desde Configuración
                    Picker("", selection: $seccion) {
                        Text("Egresos").tag("egresos")
                        Text("Ingresos").tag("ingresos")
                        Text("Cuentas").tag("cuentas")
                    }
                    .pickerStyle(.segmented).padding(.horizontal).padding(.bottom, 4)

                    // Aviso presupuesto
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill").foregroundColor(Color(hex: "#2196F3"))
                        Text("Para modificar presupuestos ve a Configuración → Presupuesto")
                            .font(Font.caption2).foregroundColor(.textoSecundario)
                    }
                    .padding(.horizontal).padding(.bottom, 10)

                    ScrollView {
                        VStack(spacing: 12) {
                            switch seccion {
                            case "cuentas": vistaCuentas
                            default:        vistaCategorias
                            }
                        }
                        .padding()
                    }

                    Button { guardarYSalir() } label: {
                        HStack {
                            if guardando { ProgressView().tint(.white) }
                            else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("GUARDAR Y CONTINUAR").fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.gradienteBoton)
                        .foregroundColor(.white).cornerRadius(14).padding()
                    }
                    .disabled(guardando)
                }
            }
        }
        .preferredColorScheme(theme.temaOscuro ? .dark : .light)
        .sheet(item: $catEditando) { cat in
            EditarCategoriaView(
                categoria: bindingParaCat(cat.id),
                onSave: { catEditando = nil })
        }
    }

    // MARK: - Vista Categorías (sin presupuesto — solo estructura)
    var vistaCategorias: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill").foregroundColor(.acentoApp)
                Text("Estas categorías son exclusivamente tuyas. Los presupuestos se configuran en la sección Presupuesto.")
                    .font(Font.caption2).foregroundColor(.textoSecundario)
            }
            .padding(10).background(Color(hex: "#0D2A1A")).cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.acentoApp.opacity(0.3), lineWidth: 1))

            Button {
                arbolActual.wrappedValue.append(CategoriaItem(nombre: "Nueva categoría"))
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill").foregroundColor(.acentoApp)
                    Text("Agregar categoría").foregroundColor(.acentoApp).fontWeight(.semibold)
                    Spacer()
                }
                .padding().background(Color.cardApp).cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.acentoApp.opacity(0.5), lineWidth: 1))
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
                        VStack(alignment: .leading, spacing: 0) {
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

                            if !sub.subsubcategorias.isEmpty {
                                ForEach(sub.subsubcategorias, id: \.id) { ssub in
                                    HStack {
                                        Image(systemName: "arrow.turn.down.right")
                                            .font(Font.caption2)
                                            .foregroundColor(Color.textoSecundario.opacity(0.6)).padding(.leading, 36)
                                        Text(ssub.nombre).font(Font.caption2)
                                            .foregroundColor(Color.textoSecundario.opacity(0.8))
                                        Spacer()
                                        Button { sub.subsubcategorias.removeAll { $0.id == ssub.id } } label: {
                                            Image(systemName: "xmark.circle")
                                                .foregroundColor(Color(hex: "#FF5252").opacity(0.5)).font(Font.caption2)
                                        }
                                    }
                                    .padding(.vertical, 4).padding(.horizontal)
                                }
                            }
                        }
                    }

                    AgregarSubView(cat: $cat)
                    Divider().background(Color.bordeApp)
                }
                .background(Color.cardApp).cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bordeApp, lineWidth: 1))
            }
        }
    }

    // MARK: - Vista Cuentas
    var vistaCuentas: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill").foregroundColor(.acentoApp)
                Text("Tus cuentas son privadas. Solo tú las ves.")
                    .font(Font.caption2).foregroundColor(.textoSecundario)
            }
            .padding(10).background(Color(hex: "#0D2A1A")).cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.acentoApp.opacity(0.3), lineWidth: 1))

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

    // MARK: - Helpers
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

    func guardarYSalir() {
        guardando = true
        config.guardar()
        if modoInicial {
            if let uid = Auth.auth().currentUser?.uid {
                Database.database().reference()
                    .child("users").child(uid).child("isNewUser").setValue(false)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            guardando = false
            if modoInicial {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = scene.windows.first {
                    window.rootViewController = UIHostingController(rootView: MainTabView())
                    window.makeKeyAndVisible()
                }
            } else {
                dismiss()
            }
        }
    }
}

// MARK: - AgregarSubView
struct AgregarSubView: View {
    @Binding var cat: CategoriaItem
    @State private var nuevaSub  = ""
    @State private var nuevoSsub = ""
    @State private var subSelec  = ""
    @State private var expandido = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button { withAnimation { expandido.toggle() } } label: {
                HStack {
                    Image(systemName: "plus.circle").foregroundColor(.acentoApp).font(Font.caption)
                    Text("Agregar subcategoría").font(Font.caption).foregroundColor(.acentoApp)
                    Spacer()
                    Image(systemName: expandido ? "chevron.up" : "chevron.down")
                        .font(Font.caption2).foregroundColor(.textoSecundario)
                }
                .padding(.horizontal).padding(.vertical, 8)
            }

            if expandido {
                VStack(spacing: 8) {
                    // Nueva subcategoría
                    HStack {
                        TextField("Nombre subcategoría", text: $nuevaSub)
                            .font(Font.caption).foregroundColor(.textoPrincipal)
                        Button("＋") {
                            let s = nuevaSub.trimmingCharacters(in: .whitespaces)
                            guard !s.isEmpty else { return }
                            cat.subcategorias.append(SubcategoriaItem(nombre: s))
                            nuevaSub = ""
                        }
                        .foregroundColor(.acentoApp).fontWeight(.bold)
                    }
                    .padding(10).background(Color.inputFondo).cornerRadius(10)

                    // Subsubcategoría
                    if !cat.subcategorias.isEmpty {
                        Picker("Subcategoría", selection: $subSelec) {
                            Text("Para subcategoría...").tag("")
                            ForEach(cat.subcategorias) { sub in Text(sub.nombre).tag(sub.id) }
                        }
                        .pickerStyle(.menu).padding(8).background(Color.inputFondo)
                        .cornerRadius(10).accentColor(.acentoApp)

                        if !subSelec.isEmpty {
                            HStack {
                                TextField("Subsubcategoría", text: $nuevoSsub)
                                    .font(Font.caption).foregroundColor(.textoPrincipal)
                                Button("＋") {
                                    let s = nuevoSsub.trimmingCharacters(in: .whitespaces)
                                    guard !s.isEmpty else { return }
                                    if let idx = cat.subcategorias.firstIndex(where: { $0.id == subSelec }) {
                                        cat.subcategorias[idx].subsubcategorias
                                            .append(SubsubcategoriaItem(nombre: s))
                                    }
                                    nuevoSsub = ""
                                }
                                .foregroundColor(.acentoApp).fontWeight(.bold)
                            }
                            .padding(10).background(Color.inputFondo).cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal).padding(.bottom, 8)
            }
        }
    }
}

// MARK: - AgregarCuentaView
struct AgregarCuentaView: View {
    @Binding var cuentas: [String]
    @State private var nuevaCta = ""

    var body: some View {
        HStack {
            Image(systemName: "creditcard.fill").foregroundColor(.acentoApp)
            TextField("Nueva cuenta (ej: Nu, Nequi)", text: $nuevaCta).foregroundColor(.textoPrincipal)
            Button("＋") {
                let c = nuevaCta.trimmingCharacters(in: .whitespaces)
                guard !c.isEmpty else { return }
                cuentas.append(c); nuevaCta = ""
            }
            .foregroundColor(.acentoApp).fontWeight(.bold)
        }
        .padding().background(Color.cardApp).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.acentoApp.opacity(0.5), lineWidth: 1))
    }
}

// MARK: - EditarCategoriaView (solo estructura, SIN campos de presupuesto)
struct EditarCategoriaView: View {
    @ObservedObject var theme = ThemeManager.shared
    @Binding var categoria: CategoriaItem
    var onSave: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fondoApp.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {

                        // Nombre
                        VStack(alignment: .leading, spacing: 6) {
                            Text("NOMBRE CATEGORÍA")
                                .font(Font.caption.bold()).foregroundColor(.acentoApp).kerning(1.2)
                            TextField("Nombre", text: $categoria.nombre)
                                .foregroundColor(.textoPrincipal).padding()
                                .background(Color.inputFondo).cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bordeApp, lineWidth: 1))
                        }

                        // Aviso presupuesto
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill").foregroundColor(Color(hex: "#2196F3"))
                            Text("Para modificar presupuestos de esta categoría ve a Configuración → Presupuesto")
                                .font(Font.caption2).foregroundColor(.textoSecundario)
                        }
                        .padding(10).background(Color(hex: "#0D1A2A")).cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "#2196F3").opacity(0.3), lineWidth: 1))

                        Divider().background(Color.bordeApp)

                        Text("SUBCATEGORÍAS").font(Font.caption.bold())
                            .foregroundColor(.acentoApp).kerning(1.2)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach($categoria.subcategorias) { $sub in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    TextField("Subcategoría", text: $sub.nombre)
                                        .font(Font.subheadline.bold()).foregroundColor(.textoPrincipal)
                                    Button {
                                        categoria.subcategorias.removeAll { $0.id == sub.id }
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(Color(hex: "#FF5252").opacity(0.7))
                                    }
                                }
                                .padding().background(Color.cardApp).cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bordeApp, lineWidth: 1))

                                VStack(spacing: 4) {
                                    ForEach($sub.subsubcategorias) { $ssub in
                                        HStack {
                                            Image(systemName: "arrow.turn.down.right")
                                                .font(Font.caption2).foregroundColor(.textoSecundario)
                                            TextField("Nombre", text: $ssub.nombre)
                                                .font(Font.caption).foregroundColor(.textoPrincipal)
                                            Spacer()
                                            Button {
                                                sub.subsubcategorias.removeAll { $0.id == ssub.id }
                                            } label: {
                                                Image(systemName: "xmark.circle")
                                                    .foregroundColor(Color(hex: "#FF5252").opacity(0.5))
                                                    .font(Font.caption)
                                            }
                                        }
                                        .padding(8).background(Color.inputFondo).cornerRadius(10)
                                    }
                                    AgregarSubsubView(sub: $sub)
                                }
                                .padding(.leading, 16)
                            }
                        }

                        Button {
                            categoria.subcategorias.append(SubcategoriaItem(nombre: "Nueva"))
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Agregar subcategoría")
                            }
                            .font(Font.caption.bold()).foregroundColor(.acentoApp)
                            .frame(maxWidth: .infinity).padding().background(Color.cardApp).cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.acentoApp.opacity(0.5), lineWidth: 1))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Editar categoría")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { onSave(); dismiss() }
                        .foregroundColor(.acentoApp).fontWeight(.bold)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }.foregroundColor(.textoSecundario)
                }
            }
        }
        .preferredColorScheme(theme.temaOscuro ? .dark : .light)
    }
}

// MARK: - AgregarSubsubView
struct AgregarSubsubView: View {
    @Binding var sub: SubcategoriaItem
    @State private var texto = ""

    var body: some View {
        HStack {
            TextField("Nueva subsubcategoría", text: $texto)
                .font(Font.caption).foregroundColor(.textoPrincipal)
            Button("＋") {
                let s = texto.trimmingCharacters(in: .whitespaces)
                guard !s.isEmpty else { return }
                sub.subsubcategorias.append(SubsubcategoriaItem(nombre: s))
                texto = ""
            }
            .foregroundColor(.acentoApp).fontWeight(.bold)
        }
        .padding(8).background(Color.inputFondo).cornerRadius(10)
    }
}
