import SwiftUI
import Firebase
import GoogleSignIn

@main
struct finanzasqgiosApp: App {

    init() {
        FirebaseApp.configure()
        AppLifecycleManager.shared.configurar()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
