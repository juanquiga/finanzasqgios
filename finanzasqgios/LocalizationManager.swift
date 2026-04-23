import Foundation
import SwiftUI
import Combine

class LocalizationManager: ObservableObject {

    static let shared = LocalizationManager()

    @Published var idioma: String {
        didSet {
            UserDefaults.standard.set(idioma, forKey: "idioma")
            objectWillChange.send()
        }
    }

    private init() {
        self.idioma = UserDefaults.standard.string(forKey: "idioma") ?? "es"
    }

    func t(_ key: String) -> String {
        guard let path = Bundle.main.path(forResource: idioma, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: "")
        }
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
}

func t(_ key: String) -> String {
    LocalizationManager.shared.t(key)
}
