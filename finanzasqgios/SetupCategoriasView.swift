import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct SetupCategoriasView: View {

    @StateObject private var config  = ConfigManager.shared
    @State private var seccion       = "egresos"
    @State private var guardando     = false
    @State private var showAgregar   = false
    @State private var catEditando   : CategoriaItem? = nil
    @State private var subEditando   : (catId: String, sub: SubcategoriaItem)? = nil
    @Environment(\.dismiss) var dismiss

    var arbolActual: Binding<[CategoriaItem]> {
        seccion == "egresos" ? $config.egresosTree : $config.ingresosTree
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fondo.ignoresSafeArea()
                VStack(spacing: 0) {

                    // Header
                    VStack(spacing: 6) {
                        Text("🎯 Personalización")
                            .font(.title2.bold()).foregroundColor(.verdeApp)
                        Text("Categorías, subcategorías y cuentas")
                            .font(.caption).foregroundColor(.grisTexto)
                    }
                    .padding(.top, 16).padding(.bottom, 12)

                    Picker("", selection: $seccion) {
                        Text("Egresos").tag("egresos")
                        Text("Ingresos").tag("ingresos")
                        Text("Cuentas").tag("cuentas")
                    }
                    .pickerStyle(.segmented).padding(.horizontal)
                    .padding(.bottom, 12)

                    ScrollView {
                        VStack(spacing: 12) {
                            if seccion == "cuentas" {
                                vistaCuentas
                            } else {
                                vistaCategorias
                            }
                        }
                        .padding()
                    }

                    // Guardar
                    Button { guardarYSalir() } label: {
                        HStack {
                            if guardando { ProgressView().tint(.white) }
                            else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("GUARDAR Y CONTINUAR").fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(LinearGradient(
                            colors: [Color(hex: "#2E7D32"), Color(hex: "#1B5E20")],
                            startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white).cornerRadius(14).padding()
                    }
                    .disabled(guardando)
                }
            }
        }
        .sheet(item: $catEditando) { cat in
            EditarCategoriaView(categoria: binding(for: cat.id), onSave: {
                catEditando = nil
            })
        }
    }

    // MARK: - Vista Categorías
    var vistaCategorias: some View {
        VStack(spacing: 10) {
            // Botón agregar categoría
            Button {
                let nueva = CategoriaItem(nombre: "Nueva categoría")
                arbolActual.wrappedValue.append(nueva)
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill").foregroundColor(.verdeApp)
                    Text("Agregar categoría").foregroundColor(.verdeApp)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding()
                .background(Color.card).cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.verdeApp.opacity(0.5), lineWidth: 1))
            }

            ForEach(arbolActual) { $cat in
                VStack(alignment: .leading, spacing: 0) {
                    // Fila categoría
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.verdeApp).frame(width: 24)
                        Text(cat.nombre)
                            .font(.subheadline.bold()).foregroundColor(.white)
                        Spacer()
                        // Editar
                        Button {
                            catEditando = cat
                        } label: {
                            Image(systemName: "pencil.circle")
                                .foregroundColor(.verdeApp.opacity(0.8))
                        }
                        // Eliminar categoría
                        Button {
                            arbolActual.wrappedValue.removeAll { $0.id == cat.id }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.rojoApp.opacity(0.7))
                        }
                    }
                    .padding()

                    Divider().background(Color.borde).padding(.leading, 44)

                    // Subcategorías
                    ForEach($cat.subcategorias) { $sub in
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Image(systemName: "chevron.right")
                                    .font(.caption).foregroundColor(.grisTexto)
                                    .padding(.leading, 20)
                                Text(sub.nombre)
                                    .font(.caption).foregroundColor(.white)
                                Spacer()
                                Button {
                                    cat.subcategorias.removeAll { $0.id == sub.id }
                                } label: {
                                    Image(systemName: "minus.circle")
                                        .foregroundColor(.rojoApp.opacity(0.6))
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 8).padding(.horizontal)

                            // Subsubcategorías
                            if !sub.subsubcategorias.isEmpty {
                                ForEach(sub.subsubcategorias, id: \.self) { ssub in
                                    HStack {
                                        Image(systemName: "arrow.turn.down.right")
                                            .font(.caption2).foregroundColor(Color.grisTexto.opacity(0.6))
                                            .padding(.leading, 36)
                                        Text(ssub).font(.caption2)
                                            .foregroundColor(Color.grisTexto.opacity(0.8))
                                        Spacer()
                                        Button {
                                            sub.subsubcategorias.removeAll { $0 == ssub }
                                        } label: {
                                            Image(systemName: "xmark.circle")
                                                .foregroundColor(.rojoApp.opacity(0.5))
                                                .font(.caption2)
                                        }
                                    }
                                    .padding(.vertical, 4).padding(.horizontal)
                                }
                            }
                        }
                    }

                    // Agregar subcategoría
                    AgregarSubView(cat: $cat)

                    Divider().background(Color.borde)
                }
                .background(Color.card).cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.borde, lineWidth: 1))
            }
        }
    }

    // MARK: - Vista Cuentas
    var vistaCuentas: some View {
        VStack(spacing: 10) {
            AgregarCuentaView(cuentas: $config.cuentas)
            ForEach($config.cuentas, id: \.self) { $cta in
                HStack(spacing: 12) {
                    Image(systemName: "creditcard.fill").foregroundColor(.verdeApp)
                    TextField("Cuenta", text: $cta).foregroundColor(.white)
                    Spacer()
                    Button { config.cuentas.removeAll { $0 == cta } } label: {
                        Image(systemName: "trash").foregroundColor(.rojoApp.opacity(0.7))
                    }
                }
                .padding()
                .background(Color.card).cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borde, lineWidth: 1))
            }
        }
    }

    func binding(for catId: String) -> Binding<CategoriaItem> {
        Binding(
            get: {
                arbolActual.wrappedValue.first { $0.id == catId }
                    ?? CategoriaItem()
            },
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
        if let uid = Auth.auth().currentUser?.uid {
            Database.database().reference()
                .child("users").child(uid).child("isNewUser").setValue(false)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            guardando = false
            if let scene = UIApplication.shared.connectedScenes.first
                as? UIWindowScene, let window = scene.windows.first {
                window.rootViewController =
                    UIHostingController(rootView: MainTabView())
                window.makeKeyAndVisible()
            }
        }
    }
}

// MARK: - Agregar subcategoría inline
struct AgregarSubView: View {
    @Binding var cat: CategoriaItem
    @State private var nuevaSub   = ""
    @State private var nuevoSsub  = ""
    @State private var subSelec   = ""
    @State private var expandido  = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation { expandido.toggle() }
            } label: {
                HStack {
                    Image(systemName: "plus.circle").foregroundColor(.verdeApp)
                        .font(.caption)
                    Text("Agregar subcategoría")
                        .font(.caption).foregroundColor(.verdeApp)
                    Spacer()
                    Image(systemName: expandido ? "chevron.up" : "chevron.down")
                        .font(.caption2).foregroundColor(.grisTexto)
                }
                .padding(.horizontal).padding(.vertical, 8)
            }

            if expandido {
                VStack(spacing: 8) {
                    // Nueva subcategoría
                    HStack {
                        TextField("Nombre subcategoría", text: $nuevaSub)
                            .font(.caption).foregroundColor(.white)
                        Button("＋") {
                            let s = nuevaSub.trimmingCharacters(in: .whitespaces)
                            guard !s.isEmpty else { return }
                            cat.subcategorias.append(SubcategoriaItem(nombre: s))
                            nuevaSub = ""
                        }
                        .foregroundColor(.verdeApp).fontWeight(.bold)
                    }
                    .padding(10)
                    .background(Color(hex: "#0D1A2A")).cornerRadius(10)

                    // Agregar subsubcategoría a una subcategoría existente
                    if !cat.subcategorias.isEmpty {
                        Picker("Subcategoría", selection: $subSelec) {
                            Text("Para subcategoría...").tag("")
                            ForEach(cat.subcategorias) { sub in
                                Text(sub.nombre).tag(sub.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(8).background(Color(hex: "#0D1A2A")).cornerRadius(10)

                        if !subSelec.isEmpty {
                            HStack {
                                TextField("Subsubcategoría", text: $nuevoSsub)
                                    .font(.caption).foregroundColor(.white)
                                Button("＋") {
                                    let s = nuevoSsub.trimmingCharacters(in: .whitespaces)
                                    guard !s.isEmpty else { return }
                                    if let idx = cat.subcategorias
                                        .firstIndex(where: { $0.id == subSelec }) {
                                        cat.subcategorias[idx].subsubcategorias.append(s)
                                    }
                                    nuevoSsub = ""
                                }
                                .foregroundColor(.verdeApp).fontWeight(.bold)
                            }
                            .padding(10)
                            .background(Color(hex: "#0D1A2A")).cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal).padding(.bottom, 8)
            }
        }
    }
}

// MARK: - Agregar cuenta
struct AgregarCuentaView: View {
    @Binding var cuentas: [String]
    @State private var nuevaCta = ""

    var body: some View {
        HStack {
            Image(systemName: "creditcard.fill").foregroundColor(.verdeApp)
            TextField("Nueva cuenta (ej: Nu, Nequi)", text: $nuevaCta)
                .foregroundColor(.white)
            Button("＋") {
                let c = nuevaCta.trimmingCharacters(in: .whitespaces)
                guard !c.isEmpty else { return }
                cuentas.append(c); nuevaCta = ""
            }
            .foregroundColor(.verdeApp).fontWeight(.bold)
        }
        .padding()
        .background(Color.card).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(Color.verdeApp.opacity(0.5), lineWidth: 1))
    }
}

// MARK: - Editar categoría (sheet)
struct EditarCategoriaView: View {
    @Binding var categoria: CategoriaItem
    var onSave: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fondo.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {

                        // Nombre categoría
                        VStack(alignment: .leading, spacing: 6) {
                            Text("NOMBRE CATEGORÍA")
                                .font(.caption.bold()).foregroundColor(.verdeApp)
                                .kerning(1.2)
                            TextField("Nombre", text: $categoria.nombre)
                                .foregroundColor(.white).padding()
                                .background(Color(hex: "#0D1A2A")).cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.borde, lineWidth: 1))
                        }

                        Divider().background(Color.borde)

                        // Subcategorías editables
                        Text("SUBCATEGORÍAS")
                            .font(.caption.bold()).foregroundColor(.verdeApp)
                            .kerning(1.2).frame(maxWidth: .infinity, alignment: .leading)

                        ForEach($categoria.subcategorias) { $sub in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    TextField("Subcategoría", text: $sub.nombre)
                                        .font(.subheadline.bold()).foregroundColor(.white)
                                    Button {
                                        categoria.subcategorias.removeAll { $0.id == sub.id }
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.rojoApp.opacity(0.7))
                                    }
                                }
                                .padding()
                                .background(Color.card).cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.borde, lineWidth: 1))

                                // Subsubcategorías
                                VStack(spacing: 4) {
                                    ForEach($sub.subsubcategorias, id: \.self) { $ssub in
                                        HStack {
                                            Image(systemName: "arrow.turn.down.right")
                                                .font(.caption2).foregroundColor(.grisTexto)
                                            TextField("Subsubcategoría", text: $ssub)
                                                .font(.caption).foregroundColor(.white)
                                            Button {
                                                sub.subsubcategorias.removeAll { $0 == ssub }
                                            } label: {
                                                Image(systemName: "xmark.circle")
                                                    .foregroundColor(.rojoApp.opacity(0.5))
                                                    .font(.caption)
                                            }
                                        }
                                        .padding(8)
                                        .background(Color(hex: "#0D1A2A")).cornerRadius(10)
                                    }

                                    // Agregar subsubcategoría
                                    AgregarSubsubView(sub: $sub)
                                }
                                .padding(.leading, 16)
                            }
                        }

                        // Agregar nueva subcategoría
                        Button {
                            categoria.subcategorias.append(SubcategoriaItem(nombre: "Nueva"))
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Agregar subcategoría")
                            }
                            .font(.caption.bold()).foregroundColor(.verdeApp)
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.card).cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.verdeApp.opacity(0.5), lineWidth: 1))
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
                        .foregroundColor(.verdeApp).fontWeight(.bold)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(.grisTexto)
                }
            }
        }
    }
}

// MARK: - Agregar subsubcategoría inline
struct AgregarSubsubView: View {
    @Binding var sub: SubcategoriaItem
    @State private var texto = ""

    var body: some View {
        HStack {
            TextField("Nueva subsubcategoría", text: $texto)
                .font(.caption).foregroundColor(.white)
            Button("＋") {
                let s = texto.trimmingCharacters(in: .whitespaces)
                guard !s.isEmpty else { return }
                sub.subsubcategorias.append(s); texto = ""
            }
            .foregroundColor(.verdeApp).fontWeight(.bold)
        }
        .padding(8)
        .background(Color(hex: "#0D1A2A")).cornerRadius(10)
    }
}
