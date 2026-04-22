import Foundation

struct Movimiento: Identifiable, Codable {
    var id: String = ""
    var tipoTransaccion: String = ""
    var detalle: String = ""
    var categoria: String = ""
    var subcategoria: String = ""
    var subsubcategoria: String = ""
    var valor: Double = 0
    var timestamp: Double = 0
    var cuenta: String = ""
}
