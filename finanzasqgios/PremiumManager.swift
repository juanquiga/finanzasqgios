import Foundation
import Combine
import FirebaseAuth
import FirebaseDatabase
import RevenueCat

class PremiumManager: ObservableObject {
    static let shared = PremiumManager()

    @Published var esPremium      : Bool      = false
    @Published var enPrueba       : Bool      = false
    @Published var cargando       : Bool      = true
    @Published var paquetes       : [Package] = []
    @Published var fechaExpiracion: Date?     = nil
    @Published var errorMsg       : String    = ""

    // MARK: - Límites plan gratuito (todo aquí, sin extensión separada)
    enum Limites {
        static let maxCategorias     = 5
        static let maxSubcategorias  = 3
        static let maxMovimientosMes = 50
        static let maxCuentas        = 3
    }

    private init() {}

    // MARK: - Cargar
    func cargar() {
        guard let uid = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async { self.cargando = false }
            return
        }
        Purchases.shared.logIn(uid) { [weak self] info, _, _ in
            self?.actualizarEstado(info: info)
            self?.cargarPaquetes()
        }
    }

    func actualizarEstado(info: CustomerInfo?) {
        DispatchQueue.main.async {
            self.cargando = false
            guard let info else {
                self.esPremium = false; self.enPrueba = false; return
            }
            let ent    = info.entitlements["premium"]
            let activo = ent?.isActive == true
            let prueba = ent?.periodType == .trial
            self.esPremium       = activo
            self.enPrueba        = activo && prueba
            self.fechaExpiracion = ent?.expirationDate
            self.sincronizarFirebase(activo: activo, prueba: activo && prueba,
                                     expira: ent?.expirationDate)
        }
    }

    func cargarPaquetes() {
        Purchases.shared.getOfferings { [weak self] offerings, _ in
            DispatchQueue.main.async {
                self?.paquetes = offerings?.current?.availablePackages ?? []
            }
        }
    }

    func comprar(paquete: Package, completion: @escaping (Bool, String) -> Void) {
        Purchases.shared.purchase(package: paquete) { [weak self] _, info, error, cancelado in
            DispatchQueue.main.async {
                if cancelado { completion(false, ""); return }
                if let error { completion(false, error.localizedDescription); return }
                self?.actualizarEstado(info: info)
                completion(info?.entitlements["premium"]?.isActive == true, "")
            }
        }
    }

    func restaurar(completion: @escaping (Bool) -> Void) {
        Purchases.shared.restorePurchases { [weak self] info, _ in
            self?.actualizarEstado(info: info)
            DispatchQueue.main.async {
                completion(info?.entitlements["premium"]?.isActive == true)
            }
        }
    }

    func verificar() {
        Purchases.shared.getCustomerInfo { [weak self] info, _ in
            self?.actualizarEstado(info: info)
        }
    }

    func sincronizarFirebase(activo: Bool, prueba: Bool, expira: Date?) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let expTs = (expira?.timeIntervalSince1970 ?? 0) * 1000
        Database.database().reference()
            .child("users").child(uid).child("premium")
            .updateChildValues([
                "activo"  : activo,
                "enPrueba": prueba,
                "expira"  : expTs,
                "fuente"  : "revenuecat"
            ])
    }

    func resetear() {
        esPremium = false; enPrueba = false
        cargando  = true;  paquetes = []
        fechaExpiracion = nil; errorMsg = ""
        Purchases.shared.logOut { _, _ in }
    }

    // MARK: - Helpers UI
    var diasRestantes: Int {
        guard let exp = fechaExpiracion else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: exp).day ?? 0)
    }
    var labelExpiracion: String {
        guard let exp = fechaExpiracion else { return "" }
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy"
        f.locale = Locale(identifier: "es_CO")
        return f.string(from: exp)
    }
    var paqueteMensual: Package? { paquetes.first { $0.packageType == .monthly } }
    var paqueteAnual  : Package? { paquetes.first { $0.packageType == .annual  } }
    var precioMensual : String   { paqueteMensual?.localizedPriceString ?? "$2.99" }
    var precioAnual   : String   { paqueteAnual?.localizedPriceString   ?? "$19.99" }

    // MARK: - Verificar límites
    func puedeAgregarCategoria(count: Int) -> Bool {
        esPremium || count < Limites.maxCategorias
    }
    func puedeAgregarSubcategoria(count: Int) -> Bool {
        esPremium || count < Limites.maxSubcategorias
    }
    func puedeAgregarCuenta(count: Int) -> Bool {
        esPremium || count < Limites.maxCuentas
    }
    func puedeRegistrarMovimiento(countMes: Int) -> Bool {
        esPremium || countMes < Limites.maxMovimientosMes
    }
    func mensajeLimite(_ tipo: String) -> String {
        switch tipo {
        case "categoria"  : return "Plan gratuito: \(Limites.maxCategorias) categorías máx. 👑 Premium = ilimitadas"
        case "subcategoria": return "Plan gratuito: \(Limites.maxSubcategorias) subcategorías máx. 👑 Premium = ilimitadas"
        case "cuenta"     : return "Plan gratuito: \(Limites.maxCuentas) cuentas máx. 👑 Premium = ilimitadas"
        case "movimiento" : return "Plan gratuito: \(Limites.maxMovimientosMes) movimientos/mes. 👑 Premium = ilimitados"
        default           : return "Función exclusiva de 👑 Premium"
        }
    }
}
