import SwiftUI
import Firebase

@main
struct finanzasqgiosApp: App {

    init() {
        FirebaseApp.configure()
        AppLifecycleManager.shared.configurar()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
