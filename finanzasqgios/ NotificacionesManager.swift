import Foundation
import UserNotifications
import FirebaseAuth
import FirebaseDatabase

class NotificacionesManager {
    static let shared = NotificacionesManager()
    private init() {}

    // MARK: - Pedir permiso
    func pedirPermiso() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, _ in
            print(granted ? "✅ Notificaciones permitidas" : "❌ Notificaciones denegadas")
        }
    }

    // MARK: - Verificar presupuesto y notificar
    func verificarPresupuesto() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let cal   = Calendar.current
        let ahora = Date()

        // Leer movimientos del mes
        Database.database().reference().child("movimientos").child(uid)
            .observeSingleEvent(of: .value) { [weak self] snap in
                var totalMes: Double = 0
                var porCategoria: [String: Double] = [:]

                for case let child as DataSnapshot in snap.children {
                    let d   = child.value as? [String: Any] ?? [:]
                    let ts  = d["timestamp"] as? Double ?? 0
                    let fec = Date(timeIntervalSince1970: ts / 1000)
                    guard cal.isDate(fec, equalTo: ahora, toGranularity: .month) else { continue }
                    guard d["tipoTransaccion"] as? String == "Egreso" else { continue }

                    let valor = d["valor"]     as? Double ?? 0
                    let cat   = d["categoria"] as? String ?? ""
                    let mon   = d["moneda"]    as? String ?? "COP"
                    if mon == "COP" {
                        totalMes += valor
                        porCategoria[cat, default: 0] += valor
                    }
                }

                // Leer config para comparar con presupuestos
                Database.database().reference().child("configuracion").child(uid)
                    .observeSingleEvent(of: .value) { snap2 in
                        let data = snap2.value as? [String: Any] ?? [:]
                        let maxCOP = data["presupuestoMaxCOP"] as? Double ?? 0

                        // Notificación presupuesto general
                        if maxCOP > 0 {
                            let pct = totalMes / maxCOP
                            if pct >= 1.0 {
                                self?.enviarNotificacion(
                                    titulo: "🚨 Presupuesto superado",
                                    cuerpo: "Has gastado \(formatCOP(totalMes)) de \(formatCOP(maxCOP)) este mes.",
                                    id: "pres_general_superado"
                                )
                            } else if pct >= 0.85 {
                                self?.enviarNotificacion(
                                    titulo: "⚠️ Casi en el límite",
                                    cuerpo: "Has gastado el \(Int(pct*100))% de tu presupuesto mensual.",
                                    id: "pres_general_85"
                                )
                            }
                        }

                        // Notificaciones por categoría
                        if let egresos = data["egresos"] as? [[String: Any]] {
                            for cat in egresos {
                                let nombre = cat["nombre"] as? String ?? ""
                                let maxCat = cat["presupuesto"] as? Double ?? 0
                                guard maxCat > 0 else { continue }
                                let gastado = porCategoria[nombre] ?? 0
                                let pct     = gastado / maxCat
                                if pct >= 1.0 {
                                    self?.enviarNotificacion(
                                        titulo: "🚨 \(nombre) superado",
                                        cuerpo: "Gastaste \(formatCOP(gastado)) de \(formatCOP(maxCat)) en \(nombre).",
                                        id: "cat_\(nombre)_superado"
                                    )
                                } else if pct >= 0.85 {
                                    self?.enviarNotificacion(
                                        titulo: "⚠️ \(nombre) casi al límite",
                                        cuerpo: "Has usado el \(Int(pct*100))% del presupuesto de \(nombre).",
                                        id: "cat_\(nombre)_85"
                                    )
                                }
                            }
                        }
                    }
            }
    }

    // MARK: - Notificación programada al inicio del mes
    func programarRecordatorioMensual() {
        let content       = UNMutableNotificationContent()
        content.title     = "📊 Nuevo mes, nuevo presupuesto"
        content.body      = "Revisa tus gastos del mes pasado y comienza el nuevo mes con control."
        content.sound     = .default

        var comps         = DateComponents()
        comps.day         = 1
        comps.hour        = 9
        comps.minute      = 0

        let trigger       = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request       = UNNotificationRequest(
            identifier: "recordatorio_mensual",
            content   : content,
            trigger   : trigger)

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Notificación al registrar un movimiento (verificar después)
    func verificarDespuesDeRegistrar() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.verificarPresupuesto()
        }
    }

    // MARK: - Helper enviar
    private func enviarNotificacion(titulo: String, cuerpo: String, id: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { pending in
            // No enviar duplicados en el mismo día
            let hoy       = Calendar.current.startOfDay(for: Date())
            let idHoy     = "\(id)_\(Int(hoy.timeIntervalSince1970))"
            let yaEnviado = pending.contains { $0.identifier == idHoy }
            guard !yaEnviado else { return }

            let content   = UNMutableNotificationContent()
            content.title = titulo
            content.body  = cuerpo
            content.sound = .default

            let trigger   = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request   = UNNotificationRequest(
                identifier: idHoy, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }

    func cancelarTodas() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
