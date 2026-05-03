import Foundation
import Combine
import FirebaseDatabase
import FirebaseAuth

struct SubsubcategoriaItem: Identifiable, Codable {
    var id          : String = UUID().uuidString
    var nombre      : String = ""
    var presupuesto : Double = 0
    init(nombre: String = "", presupuesto: Double = 0) {
        self.nombre = nombre; self.presupuesto = presupuesto
    }
}

struct SubcategoriaItem: Identifiable, Codable {
    var id               : String                   = UUID().uuidString
    var nombre           : String                   = ""
    var presupuesto      : Double                   = 0
    var subsubcategorias : [SubsubcategoriaItem]    = []
    init(nombre: String = "", presupuesto: Double = 0) {
        self.nombre = nombre; self.presupuesto = presupuesto
    }
    // Suma automática de subsubcategorías
    var presupuestoTotal: Double {
        let sumaSub = subsubcategorias.reduce(0) { $0 + $1.presupuesto }
        return sumaSub > 0 ? sumaSub : presupuesto
    }
}

struct CategoriaItem: Identifiable, Codable {
    var id            : String             = UUID().uuidString
    var nombre        : String             = ""
    var subcategorias : [SubcategoriaItem] = []
    var presupuesto   : Double             = 0
    init(nombre: String = "", presupuesto: Double = 0) {
        self.nombre = nombre; self.presupuesto = presupuesto
    }
    // Suma automática de subcategorías
    var presupuestoTotal: Double {
        let sumaSubs = subcategorias.reduce(0) { $0 + $1.presupuestoTotal }
        return sumaSubs > 0 ? sumaSubs : presupuesto
    }
}

class ConfigManager: ObservableObject {
    static let shared = ConfigManager()

    @Published var egresosTree      : [CategoriaItem] = []
    @Published var ingresosTree     : [CategoriaItem] = []
    @Published var cuentas          : [String]        = []
    @Published var presupuestoMaxCOP: Double          = 0
    @Published var presupuestoMaxUSD: Double          = 0

    private var handle   : DatabaseHandle?
    private var ref      : DatabaseReference?
    private var uidActual: String = ""

    private init() { aplicarDefaults() }

    private func aplicarDefaults() {
        egresosTree = [
            CategoriaItem(nombre: "Comida"),
            CategoriaItem(nombre: "Casa"),
            CategoriaItem(nombre: "Transporte"),
            CategoriaItem(nombre: "Salud"),
            CategoriaItem(nombre: "Familia"),
            CategoriaItem(nombre: "Ocio")
        ]
        ingresosTree = [
            CategoriaItem(nombre: "Salario"),
            CategoriaItem(nombre: "Negocio"),
            CategoriaItem(nombre: "Inmuebles"),
            CategoriaItem(nombre: "Otros")
        ]
        cuentas           = ["Bancolombia","Nu","Nequi","Efectivo","Tarjeta crédito"]
        presupuestoMaxCOP = 0
        presupuestoMaxUSD = 0
    }

    func cargar() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if uid != uidActual { detener(); aplicarDefaults(); uidActual = uid }
        ref = Database.database().reference().child("configuracion").child(uid)
        handle = ref?.observe(.value) { [weak self] snap in
            guard let self else { return }
            DispatchQueue.main.async {
                guard let data = snap.value as? [String: Any] else { return }
                if let eg = data["egresos"]           as? [[String: Any]] { self.egresosTree  = self.parseTree(eg) }
                if let ig = data["ingresos"]          as? [[String: Any]] { self.ingresosTree = self.parseTree(ig) }
                if let ct = data["cuentas"]           as? [String]        { self.cuentas      = ct }
                if let pc = data["presupuestoMaxCOP"] as? Double { self.presupuestoMaxCOP = pc }
                else if let pc = data["presupuestoMaxCOP"] as? Int { self.presupuestoMaxCOP = Double(pc) }
                if let pu = data["presupuestoMaxUSD"] as? Double { self.presupuestoMaxUSD = pu }
                else if let pu = data["presupuestoMaxUSD"] as? Int { self.presupuestoMaxUSD = Double(pu) }
            }
        }
    }

    func guardar() {
        guard let uid = Auth.auth().currentUser?.uid, uid == uidActual else { return }
        Database.database().reference().child("configuracion").child(uid).setValue([
            "egresos"          : serializeTree(egresosTree),
            "ingresos"         : serializeTree(ingresosTree),
            "cuentas"          : cuentas,
            "presupuestoMaxCOP": presupuestoMaxCOP,
            "presupuestoMaxUSD": presupuestoMaxUSD
        ])
    }

    func detener() {
        if let h = handle { ref?.removeObserver(withHandle: h) }
        handle = nil; ref = nil
    }

    func resetearSesion() {
        detener(); uidActual = ""
        egresosTree = []; ingresosTree = []; cuentas = []
        presupuestoMaxCOP = 0; presupuestoMaxUSD = 0
    }

    private func serializeTree(_ items: [CategoriaItem]) -> [[String: Any]] {
        items.map { cat in [
            "id": cat.id, "nombre": cat.nombre, "presupuesto": cat.presupuesto,
            "subcategorias": cat.subcategorias.map { sub in [
                "id": sub.id, "nombre": sub.nombre, "presupuesto": sub.presupuesto,
                "subsubcategorias": sub.subsubcategorias.map { ssub in [
                    "id": ssub.id, "nombre": ssub.nombre, "presupuesto": ssub.presupuesto
                ] as [String: Any] }
            ] as [String: Any] }
        ] as [String: Any] }
    }

    private func parseTree(_ arr: [[String: Any]]) -> [CategoriaItem] {
        arr.compactMap { d in
            guard let nombre = d["nombre"] as? String else { return nil }
            var cat = CategoriaItem(nombre: nombre)
            cat.id = d["id"] as? String ?? UUID().uuidString
            if let p = d["presupuesto"] as? Double { cat.presupuesto = p }
            else if let p = d["presupuesto"] as? Int { cat.presupuesto = Double(p) }
            cat.subcategorias = (d["subcategorias"] as? [[String: Any]] ?? []).compactMap { s in
                guard let sn = s["nombre"] as? String else { return nil }
                var sub = SubcategoriaItem(nombre: sn)
                sub.id = s["id"] as? String ?? UUID().uuidString
                if let p = s["presupuesto"] as? Double { sub.presupuesto = p }
                else if let p = s["presupuesto"] as? Int { sub.presupuesto = Double(p) }
                // Parse subsubcategorias como objetos (nuevo) o como strings (legado)
                if let ssubs = s["subsubcategorias"] as? [[String: Any]] {
                    sub.subsubcategorias = ssubs.compactMap { ss in
                        guard let ssn = ss["nombre"] as? String else { return nil }
                        var ssub = SubsubcategoriaItem(nombre: ssn)
                        ssub.id = ss["id"] as? String ?? UUID().uuidString
                        if let p = ss["presupuesto"] as? Double { ssub.presupuesto = p }
                        else if let p = ss["presupuesto"] as? Int { ssub.presupuesto = Double(p) }
                        return ssub
                    }
                } else if let ssubs = s["subsubcategorias"] as? [String] {
                    // Compatibilidad con formato legacy (strings)
                    sub.subsubcategorias = ssubs.map { SubsubcategoriaItem(nombre: $0) }
                }
                return sub
            }
            return cat
        }
    }
}
