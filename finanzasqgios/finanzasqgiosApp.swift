import SwiftUI
import FirebaseCore
import GoogleSignIn
import RevenueCat

@main
struct finanzasqgiosApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Firebase
        FirebaseApp.configure()

        // RevenueCat
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: "test_dpLWVOomytKHFrxoEdadnSrRdhu")

        // Pedir permiso para notificaciones
        NotificacionesManager.shared.pedirPermiso()

        // Programar recordatorio mensual
        NotificacionesManager.shared.programarRecordatorioMensual()

        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
}
