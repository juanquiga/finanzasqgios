import Foundation
import Combine
import FirebaseDatabase
import FirebaseAuth

// Estructura jerárquica: Categoria → Subcategoria → [SubsubCategoria]
struct CategoriaItem: Identifiable, Codable {
    var id: String = UUID().uuidString
    var nombre: String = ""
    var subcategorias: [SubcategoriaItem] = []
}

struct SubcategoriaItem: Identifiable, Codable {
    var id: String = UUID().uuidString
    var nombre: String = ""
    var subsubcategorias: [String] = []
}

class ConfigManager: ObservableObject {

    static let shared = ConfigManager()

    @Published var egresosTree  : [CategoriaItem] = []
    @Published var ingresosTree : [CategoriaItem] = []
    @Published var cuentas      : [String] = []

    private var handle: DatabaseHandle?
    private var ref: DatabaseReference?

    private init() {
        // Defaults
        egresosTree = [
            CategoriaItem(nombre: "Comida", subcategorias: [
                SubcategoriaItem(nombre: "Almuerzo",   subsubcategorias: ["Restaurante", "Casa", "Delivery"]),
                SubcategoriaItem(nombre: "Mercado",    subsubcategorias: ["Supermercado", "Tienda", "Plaza"]),
                SubcategoriaItem(nombre: "Cafetería",  subsubcategorias: ["Café", "Snack"])
            ]),
            CategoriaItem(nombre: "Casa", subcategorias: [
                SubcategoriaItem(nombre: "Servicios",  subsubcategorias: ["Luz", "Agua", "Gas", "Internet"]),
                SubcategoriaItem(nombre: "Arriendo",   subsubcategorias: []),
                SubcategoriaItem(nombre: "Mercado",    subsubcategorias: [])
            ]),
            CategoriaItem(nombre: "Transporte", subcategorias: [
                SubcategoriaItem(nombre: "Gasolina",   subsubcategorias: ["Carro", "Moto"]),
                SubcategoriaItem(nombre: "Transporte público", subsubcategorias: ["Transmilenio", "Bus", "Metro"]),
                SubcategoriaItem(nombre: "Taxi/Uber",  subsubcategorias: [])
            ]),
            CategoriaItem(nombre: "Salud", subcategorias: [
                SubcategoriaItem(nombre: "Medicamentos", subsubcategorias: []),
                SubcategoriaItem(nombre: "Consulta",   subsubcategorias: ["Médico", "Odontólogo", "Especialista"]),
                SubcategoriaItem(nombre: "Gym",        subsubcategorias: [])
            ]),
            CategoriaItem(nombre: "Familia", subcategorias: [
                SubcategoriaItem(nombre: "Mesada",     subsubcategorias: []),
                SubcategoriaItem(nombre: "Salidas",    subsubcategorias: ["Restaurante", "Cine", "Parque"]),
                SubcategoriaItem(nombre: "Mascotas",   subsubcategorias: ["Veterinario", "Comida", "Accesorios"])
            ]),
            CategoriaItem(nombre: "Ocio", subcategorias: [
                SubcategoriaItem(nombre: "Entretenimiento", subsubcategorias: ["Streaming", "Juegos", "Música"]),
                SubcategoriaItem(nombre: "Viajes",     subsubcategorias: ["Tiquetes", "Hotel", "Comida"]),
                SubcategoriaItem(nombre: "Ropa",       subsubcategorias: [])
            ])
        ]
        ingresosTree = [
            CategoriaItem(nombre: "Salario", subcategorias: [
                SubcategoriaItem(nombre: "Nómina",     subsubcategorias: ["Quincenal", "Mensual"]),
                SubcategoriaItem(nombre: "Prima",      subsubcategorias: [])
            ]),
            CategoriaItem(nombre: "Negocio", subcategorias: [
                SubcategoriaItem(nombre: "Ventas",     subsubcategorias: []),
                SubcategoriaItem(nombre: "Servicios",  subsubcategorias: [])
            ]),
            CategoriaItem(nombre: "Inmuebles", subcategorias: [
                SubcategoriaItem(nombre: "Arriendo",   subsubcategorias: []),
                SubcategoriaItem(nombre: "Venta",      subsubcategorias: [])
            ]),
            CategoriaItem(nombre: "Otros", subcategorias: [
                SubcategoriaItem(nombre: "Regalo",     subsubcategorias: []),
                SubcategoriaItem(nombre: "Premio",     subsubcategorias: []),
                SubcategoriaItem(nombre: "Préstamo",   subsubcategorias: [])
            ])
        ]
        cuentas = ["Bancolombia", "Nu", "Nequi", "Efectivo", "Tarjeta crédito"]
    }

    func cargar() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        ref = Database.database().reference().child("configuracion").child(uid)
        handle = ref?.observe(.value) { [weak self] snap in
            guard let self = self else { return }
            if let data = snap.value as? [String: Any] {
                if let eg = data["egresos"]  as? [[String: Any]] {
                    self.egresosTree  = self.parseTree(eg)
                }
                if let ig = data["ingresos"] as? [[String: Any]] {
                    self.ingresosTree = self.parseTree(ig)
                }
                if let ct = data["cuentas"]  as? [String] {
                    self.cuentas = ct
                }
            }
        }
    }

    func guardar() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Database.database().reference()
            .child("configuracion").child(uid)
            .setValue([
                "egresos":  serializeTree(egresosTree),
                "ingresos": serializeTree(ingresosTree),
                "cuentas":  cuentas
            ])
    }

    func detener() {
        if let h = handle { ref?.removeObserver(withHandle: h) }
    }

    // Helpers de serialización
    private func serializeTree(_ items: [CategoriaItem]) -> [[String: Any]] {
        items.map { cat in
            [
                "id": cat.id,
                "nombre": cat.nombre,
                "subcategorias": cat.subcategorias.map { sub in
                    [
                        "id": sub.id,
                        "nombre": sub.nombre,
                        "subsubcategorias": sub.subsubcategorias
                    ] as [String: Any]
                }
            ] as [String: Any]
        }
    }

    private func parseTree(_ arr: [[String: Any]]) -> [CategoriaItem] {
        arr.compactMap { d in
            guard let nombre = d["nombre"] as? String else { return nil }
            let subs = (d["subcategorias"] as? [[String: Any]] ?? []).compactMap { s -> SubcategoriaItem? in
                guard let sNombre = s["nombre"] as? String else { return nil }
                let subsubs = s["subsubcategorias"] as? [String] ?? []
                return SubcategoriaItem(
                    id: s["id"] as? String ?? UUID().uuidString,
                    nombre: sNombre,
                    subsubcategorias: subsubs
                )
            }
            return CategoriaItem(
                id: d["id"] as? String ?? UUID().uuidString,
                nombre: nombre,
                subcategorias: subs
            )
        }
    }
}
