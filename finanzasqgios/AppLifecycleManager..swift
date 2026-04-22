import UIKit
import FirebaseAuth

class AppLifecycleManager: NSObject {

    static let shared = AppLifecycleManager()

    func configurar() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    @objc func appBackground() {
        let recordar = UserDefaults.standard.bool(forKey: "recordarSesion")
        if !recordar {
            try? Auth.auth().signOut()
        }
    }
}
