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

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Firebase
        FirebaseApp.configure()

        // RevenueCat — pon tu API Key aquí
        Purchases.logLevel = .debug  // quitar en producción
        Purchases.configure(withAPIKey: "test_iHQjiPzcuDpWFWukVGIVHDQQzun")

        return true
    }

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
}
