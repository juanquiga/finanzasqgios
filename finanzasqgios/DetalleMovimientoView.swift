import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct DetalleMovimientoView: View {

    @ObservedObject var theme = ThemeManager.shared
    let movimiento: Movimiento
    @State private var showEliminar = false
    @Environment(\.dismiss) var dismiss

    var esTransferencia: Bool { movimiento.tipoTransaccion == "Transferencia" }
    var esIngreso      : Bool { movimiento.tipoTransaccion == "Ingreso" }

    var colorTipo: Color {
        esIngreso ? Color.verdeFinanzas
            : esTransferencia ? Color(hex: "#2196F3") : Color.rojoFinanzas
    }
    var emojiTipo: String {
        esIngreso ? "📈" : esTransferencia ? "🔄" : "📉"
    }

    var body: some View {
        ZStack {
            Color.fondoApp.ignoresSafeArea()
            VStack(spacing: 0) {

                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.acentoApp).font(Font.title3.bold())
                    }
                    Spacer()
                    Text("Detalle del movimiento")
                        .font(Font.headline.bold()).foregroundColor(.textoPrincipal)
                    Spacer()
                    // Botón eliminar
                    Button {
                        showEliminar = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(Color.rojoFinanzas).font(Font.body)
                    }
                }
                .padding()

                ScrollView {
                    VStack(spacing: 16) {

                        // Card valor principal
                        VStack(spacing: 14) {
                            Text(emojiTipo)
                                .font(Font.system(size: 56))
                                .frame(width: 90, height: 90)
                                .background(
                                    esIngreso ? Color(hex: "#1B4332")
                                        : esTransferencia ? Color(hex: "#0D2A4A")
                                        : Color(hex: "#4A1010"))
                                .clipShape(Circle())

                            Text(movimiento.tipoTransaccion.uppercased())
                                .font(Font.caption.bold())
                                .foregroundColor(colorTipo).kerning(2)

                            Text(formatValor(movimiento.valor, moneda: movimiento.moneda))
                                .font(Font.system(size: 36, weight: .bold))
                                .foregroundColor(colorTipo)

                            Text(formatFecha(movimiento.timestamp))
                                .font(Font.caption).foregroundColor(.textoSecundario)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24).background(Color.cardApp).cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20)
                            .stroke(colorTipo.opacity(0.4), lineWidth: 1.5))

                        // Filas detalle
                        VStack(spacing: 0) {

                            if !movimiento.categoria.isEmpty {
                                filaDetalle("tag.fill", "Categoría", movimiento.categoria)
                                div()
                            }
                            if !movimiento.subcategoria.isEmpty {
                                filaDetalle("list.bullet", "Subcategoría", movimiento.subcategoria)
                                div()
                            }
                            if !movimiento.subsubcategoria.isEmpty {
                                filaDetalle("arrow.turn.down.right", "Detalle categ.", movimiento.subsubcategoria)
                                div()
                            }
                            if !movimiento.detalle.isEmpty {
                                filaDetalle("text.alignleft", "Descripción", movimiento.detalle)
                                div()
                            }

                            if esTransferencia {
                                if !movimiento.cuentaOrigen.isEmpty {
                                    filaDetalle("arrow.up.circle.fill", "Cuenta origen",
                                                movimiento.cuentaOrigen, color: Color.rojoFinanzas)
                                    div()
                                }
                                let dest = movimiento.cuentaDestino.isEmpty
                                    ? movimiento.cuenta : movimiento.cuentaDestino
                                if !dest.isEmpty {
                                    filaDetalle("arrow.down.circle.fill", "Cuenta destino",
                                                dest, color: Color.verdeFinanzas)
                                    div()
                                }
                            } else if !movimiento.cuenta.isEmpty {
                                filaDetalle("creditcard.fill", "Cuenta", movimiento.cuenta)
                                div()
                            }

                            filaDetalle("calendar", "Fecha y hora", formatFecha(movimiento.timestamp))
                            div()
                            filaDetalle(
                                movimiento.moneda == "USD"
                                    ? "dollarsign.circle.fill" : "dollarsign.circle",
                                "Moneda",
                                movimiento.moneda == "USD" ? "🇺🇸 USD" : "🇨🇴 COP"
                            )
                        }
                        .background(Color.cardApp).cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.bordeApp, lineWidth: 1))

                        // Botón eliminar
                        Button {
                            showEliminar = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Eliminar registro").fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity).padding()
                            .background(Color(hex: "#4A1010"))
                            .foregroundColor(.rojoFinanzas).cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.rojoFinanzas.opacity(0.5), lineWidth: 1))
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(theme.temaOscuro ? .dark : .light)
        .alert("¿Eliminar este registro?", isPresented: $showEliminar) {
            Button("Eliminar", role: .destructive) { eliminar() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("\(movimiento.categoria.isEmpty ? movimiento.tipoTransaccion : movimiento.categoria) — \(formatValor(movimiento.valor, moneda: movimiento.moneda))")
        }
    }

    func filaDetalle(_ icono: String, _ label: String, _ valor: String,
                     color: Color = .acentoApp) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icono).foregroundColor(color).frame(width: 24)
            Text(label).font(Font.subheadline).foregroundColor(.textoSecundario)
            Spacer()
            Text(valor).font(Font.subheadline.bold()).foregroundColor(.textoPrincipal)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal).padding(.vertical, 14)
    }

    func div() -> some View {
        Divider().background(Color.bordeApp).padding(.leading, 54)
    }

    func eliminar() {
        guard let uid = Auth.auth().currentUser?.uid, !movimiento.id.isEmpty else { return }
        Database.database().reference()
            .child("movimientos").child(uid).child(movimiento.id).removeValue()
        dismiss()
    }
}
