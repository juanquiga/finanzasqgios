import SwiftUI
import FirebaseAuth

struct PresupuestoView: View {

    @ObservedObject var theme  = ThemeManager.shared
    @StateObject private var config = ConfigManager.shared
    @State private var guardando = false
    @State private var guardado  = false
    @State private var catExpandida: String = ""
    @State private var subExpandida: String = ""
    @Environment(\.dismiss) var dismiss

    var presupuestoTotalCategorias: Double {
        config.egresosTree.reduce(0) { $0 + $1.presupuestoTotal }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fondoApp.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {

                        // Info
                        HStack(spacing: 10) {
                            Image(systemName: "lock.shield.fill").foregroundColor(.acentoApp)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Presupuestos personales")
                                    .font(Font.caption.bold()).foregroundColor(.textoPrincipal)
                                Text("Los presupuestos de subcategorías se suman automáticamente para mostrar el total de la categoría.")
                                    .font(Font.caption2).foregroundColor(.textoSecundario)
                            }
                        }
                        .padding(12).background(Color(hex: "#0D2A1A")).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.acentoApp.opacity(0.3), lineWidth: 1))

                        // ── RESUMEN TOTAL ──
                        if presupuestoTotalCategorias > 0 {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("TOTAL PRESUPUESTADO").font(Font.caption.bold())
                                        .foregroundColor(.textoSecundario).kerning(1.2)
                                    Text(formatCOP(presupuestoTotalCategorias))
                                        .font(Font.title2.bold()).foregroundColor(.acentoApp)
                                }
                                Spacer()
                                Image(systemName: "chart.pie.fill")
                                    .font(Font.title).foregroundColor(.acentoApp.opacity(0.3))
                            }
                            .padding().background(Color.cardApp).cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.acentoApp.opacity(0.4), lineWidth: 1.5))
                        }

                        // ── PRESUPUESTO GENERAL ──
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "gauge.with.needle.fill").foregroundColor(.acentoApp)
                                Text("PRESUPUESTO GENERAL MENSUAL")
                                    .font(Font.subheadline.bold()).foregroundColor(.textoPrincipal)
                            }
                            campoPresupuesto(titulo: "🇨🇴 Máximo total COP",
                                            valor: $config.presupuestoMaxCOP,
                                            preview: config.presupuestoMaxCOP > 0
                                                ? "Máx: \(formatCOP(config.presupuestoMaxCOP))/mes" : nil)
                            campoPresupuesto(titulo: "🇺🇸 Máximo total USD",
                                            valor: $config.presupuestoMaxUSD,
                                            preview: config.presupuestoMaxUSD > 0
                                                ? "Máx: \(formatValor(config.presupuestoMaxUSD, moneda: "USD"))/mes" : nil)
                        }
                        .padding().background(Color.cardApp).cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.acentoApp.opacity(0.4), lineWidth: 1.5))

                        // ── PRESUPUESTO JERÁRQUICO ──
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "tag.fill").foregroundColor(Color(hex: "#FF9800"))
                                Text("PRESUPUESTO POR CATEGORÍA / SUBCATEGORÍA")
                                    .font(Font.subheadline.bold()).foregroundColor(.textoPrincipal)
                            }
                            Text("Expande cada categoría para configurar el presupuesto de sus subcategorías y subsubcategorías. El total se calcula automáticamente.")
                                .font(Font.caption2).foregroundColor(.textoSecundario)

                            ForEach($config.egresosTree) { $cat in
                                VStack(spacing: 0) {

                                    // Fila categoría
                                    Button {
                                        withAnimation {
                                            catExpandida = catExpandida == cat.id ? "" : cat.id
                                        }
                                    } label: {
                                        HStack(spacing: 10) {
                                            Image(systemName: catExpandida == cat.id
                                                  ? "chevron.down" : "chevron.right")
                                                .foregroundColor(.acentoApp).font(Font.caption)
                                                .frame(width: 16)
                                            Image(systemName: "folder.fill")
                                                .foregroundColor(.acentoApp).frame(width: 18)
                                            Text(cat.nombre)
                                                .font(Font.subheadline.bold()).foregroundColor(.textoPrincipal)
                                            Spacer()
                                            // Total automático
                                            VStack(alignment: .trailing, spacing: 1) {
                                                Text(formatCOP(cat.presupuestoTotal))
                                                    .font(Font.caption.bold()).foregroundColor(.acentoApp)
                                                if cat.presupuestoTotal != cat.presupuesto && cat.presupuesto > 0 {
                                                    Text("propio: \(formatCOP(cat.presupuesto))")
                                                        .font(Font.caption2).foregroundColor(.textoSecundario)
                                                }
                                            }
                                        }
                                        .padding(12)
                                        .background(Color.inputFondo).cornerRadius(10)
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    // Presupuesto propio de categoría
                                    if catExpandida == cat.id {
                                        VStack(spacing: 8) {
                                            campoPresupuestoInline(
                                                label: "Presupuesto propio de \"\(cat.nombre)\"",
                                                valor: $cat.presupuesto
                                            )

                                            ForEach($cat.subcategorias) { $sub in
                                                VStack(spacing: 0) {

                                                    // Fila subcategoría
                                                    Button {
                                                        withAnimation {
                                                            subExpandida = subExpandida == sub.id ? "" : sub.id
                                                        }
                                                    } label: {
                                                        HStack(spacing: 10) {
                                                            Text("").frame(width: 16)
                                                            Image(systemName: sub.subsubcategorias.isEmpty
                                                                  ? "minus" : (subExpandida == sub.id
                                                                               ? "chevron.down" : "chevron.right"))
                                                                .foregroundColor(.textoSecundario).font(Font.caption)
                                                                .frame(width: 16)
                                                            Image(systemName: "list.bullet")
                                                                .foregroundColor(.textoSecundario).frame(width: 16)
                                                            Text(sub.nombre)
                                                                .font(Font.subheadline).foregroundColor(.textoPrincipal)
                                                            Spacer()
                                                            Text(formatCOP(sub.presupuestoTotal))
                                                                .font(Font.caption.bold())
                                                                .foregroundColor(sub.presupuestoTotal > 0
                                                                                 ? Color.acentoApp : .textoSecundario)
                                                        }
                                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                                        .background(Color.cardApp).cornerRadius(8)
                                                    }
                                                    .buttonStyle(PlainButtonStyle())

                                                    // Presupuesto subcategoría expandida
                                                    if subExpandida == sub.id {
                                                        VStack(spacing: 6) {
                                                            campoPresupuestoInline(
                                                                label: "Presupuesto de \"\(sub.nombre)\"",
                                                                valor: $sub.presupuesto
                                                            )

                                                            // Subsubcategorías
                                                            if !sub.subsubcategorias.isEmpty {
                                                                VStack(spacing: 4) {
                                                                    Text("Subsubcategorías:")
                                                                        .font(Font.caption2.bold())
                                                                        .foregroundColor(.textoSecundario)
                                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                                        .padding(.leading, 8)

                                                                    ForEach($sub.subsubcategorias) { $ssub in
                                                                        HStack(spacing: 8) {
                                                                            Image(systemName: "arrow.turn.down.right")
                                                                                .font(Font.caption2)
                                                                                .foregroundColor(.textoSecundario.opacity(0.6))
                                                                            Text(ssub.nombre)
                                                                                .font(Font.caption)
                                                                                .foregroundColor(.textoPrincipal)
                                                                                .frame(minWidth: 70, alignment: .leading)
                                                                            Spacer()
                                                                            TextField("0",
                                                                                      value: $ssub.presupuesto,
                                                                                      format: .number)
                                                                                .keyboardType(.decimalPad)
                                                                                .multilineTextAlignment(.trailing)
                                                                                .foregroundColor(.textoPrincipal)
                                                                                .frame(width: 90)
                                                                                .padding(6)
                                                                                .background(Color.inputFondo)
                                                                                .cornerRadius(8)
                                                                                .overlay(RoundedRectangle(cornerRadius: 8)
                                                                                    .stroke(ssub.presupuesto > 0
                                                                                            ? Color.acentoApp : Color.bordeApp,
                                                                                            lineWidth: 1))
                                                                            Text("$").font(Font.caption2)
                                                                                .foregroundColor(.textoSecundario)
                                                                        }
                                                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                                                    }
                                                                }
                                                                .padding(8).background(Color.inputFondo).cornerRadius(8)
                                                            }
                                                        }
                                                        .padding(.leading, 32).padding(.vertical, 6)
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.leading, 16).padding(.top, 6)
                                    }
                                }
                                .padding(8).background(Color.cardApp).cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(catExpandida == cat.id
                                            ? Color.acentoApp.opacity(0.4) : Color.bordeApp,
                                            lineWidth: 1))
                            }
                        }
                        .padding().background(Color.cardApp).cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#FF9800").opacity(0.4), lineWidth: 1.5))

                        // Confirmación
                        if guardado {
                            HStack {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(Color.verdeFinanzas)
                                Text("Presupuesto guardado ✅").font(Font.subheadline.bold())
                                    .foregroundColor(Color.verdeFinanzas)
                            }
                            .padding().background(Color(hex: "#1B4332")).cornerRadius(12)
                            .transition(.opacity)
                        }

                        // Botón guardar
                        Button { guardar() } label: {
                            HStack {
                                if guardando { ProgressView().tint(.white) }
                                else {
                                    Image(systemName: "icloud.and.arrow.up.fill")
                                    Text("GUARDAR PRESUPUESTO").fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.gradienteBoton)
                            .foregroundColor(.white).cornerRadius(14)
                        }
                        .disabled(guardando)
                    }
                    .padding()
                }
            }
            .navigationTitle("💰 Presupuesto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }.foregroundColor(.acentoApp)
                }
            }
        }
        .preferredColorScheme(theme.temaOscuro ? .dark : .light)
    }

    func campoPresupuesto(titulo: String, valor: Binding<Double>, preview: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo).font(Font.caption.bold()).foregroundColor(.acentoApp)
            HStack(spacing: 10) {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.acentoApp).frame(width: 20)
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
                    .font(Font.caption).foregroundColor(Color.verdeFinanzas)
            }
        }
    }

    func campoPresupuestoInline(label: String, valor: Binding<Double>) -> some View {
        HStack(spacing: 8) {
            Text(label).font(Font.caption).foregroundColor(.textoSecundario)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("0", value: valor, format: .number)
                .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                .foregroundColor(.textoPrincipal).frame(width: 100)
                .padding(8).background(Color.inputFondo).cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(valor.wrappedValue > 0 ? Color.acentoApp : Color.bordeApp, lineWidth: 1))
            Text("$").font(Font.caption2).foregroundColor(.textoSecundario)
        }
        .padding(8).background(Color.inputFondo.opacity(0.5)).cornerRadius(8)
    }

    func guardar() {
        guardando = true
        config.guardar()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            guardando = false
            withAnimation { guardado = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { guardado = false }
            }
        }
    }
}
