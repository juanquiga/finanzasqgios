import Foundation
import Combine
import FirebaseAuth
import FirebaseDatabase
import RevenueCat

class PremiumManager: ObservableObject {
    static let shared = PremiumManager()

    @Published var esPremium      : Bool   = false
    @Published var enPrueba       : Bool   = false
    @Published var cargando       : Bool   = true
    @Published var paquetes       : [Package] = []
    @Published var fechaExpiracion: Date?  = nil
    @Published var errorMsg       : String = ""

    private init() {}

    // MARK: - Cargar estado al abrir la app
    func cargar() {
        guard let uid = Auth.auth().currentUser?.uid else {
            cargando = false; return
        }

        // Identificar usuario en RevenueCat con el UID de Firebase
        Purchases.shared.logIn(uid) { [weak self] info, _, error in
            guard let self else { return }
            if let error {
                print("RevenueCat login error: \(error)")
            }
            self.actualizarEstado(info: info)
            self.cargarPaquetes()
        }
    }

    // MARK: - Actualizar estado premium desde CustomerInfo
    func actualizarEstado(info: CustomerInfo?) {
        DispatchQueue.main.async {
            self.cargando = false
            guard let info else {
                self.esPremium = false; self.enPrueba = false; return
            }

            let entitlement = info.entitlements["premium"]
            let activo      = entitlement?.isActive == true
            let prueba      = entitlement?.periodType == .trial

            self.esPremium       = activo
            self.enPrueba        = activo && prueba
            self.fechaExpiracion = entitlement?.expirationDate

            // Sincronizar con Firebase para Android
            self.sincronizarFirebase(activo: activo, prueba: activo && prueba,
                                      expira: entitlement?.expirationDate)
        }
    }

    // MARK: - Cargar paquetes disponibles
    func cargarPaquetes() {
        Purchases.shared.getOfferings { [weak self] offerings, error in
            DispatchQueue.main.async {
                if let paquetes = offerings?.current?.availablePackages {
                    self?.paquetes = paquetes
                }
            }
        }
    }

    // MARK: - Comprar suscripción
    func comprar(paquete: Package, completion: @escaping (Bool, String) -> Void) {
        Purchases.shared.purchase(package: paquete) { [weak self] transaction, info, error, cancelado in
            DispatchQueue.main.async {
                if cancelado { completion(false, ""); return }
                if let error {
                    completion(false, error.localizedDescription); return
                }
                self?.actualizarEstado(info: info)
                let exito = info?.entitlements["premium"]?.isActive == true
                completion(exito, "")
            }
        }
    }

    // MARK: - Restaurar compras
    func restaurar(completion: @escaping (Bool) -> Void) {
        Purchases.shared.restorePurchases { [weak self] info, error in
            DispatchQueue.main.async {
                self?.actualizarEstado(info: info)
                let activo = info?.entitlements["premium"]?.isActive == true
                completion(activo)
            }
        }
    }

    // MARK: - Verificar estado actual
    func verificar() {
        Purchases.shared.getCustomerInfo { [weak self] info, _ in
            self?.actualizarEstado(info: info)
        }
    }

    // MARK: - Sincronizar con Firebase (para Android)
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

    // MARK: - Reset al hacer logout
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
        f.locale     = Locale(identifier: "es_CO")
        return f.string(from: exp)
    }

    // Paquete mensual y anual
    var paqueteMensual: Package? { paquetes.first { $0.packageType == .monthly } }
    var paqueteAnual  : Package? { paquetes.first { $0.packageType == .annual  } }

    var precioMensual: String { paqueteMensual?.localizedPriceString ?? "$2.99" }
    var precioAnual  : String { paqueteAnual?.localizedPriceString   ?? "$19.99" }
}
