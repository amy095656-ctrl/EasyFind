import CoreText
import SwiftUI

@main struct MyApp: App {
    init() {
        registerCustomFont()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .font(.custom("jf-openhuninn-2.1", size: 16))
        }
    }

    private func registerCustomFont() {
        guard let fontURL = Bundle.main.url(forResource: "jf-openhuninn-2.1", withExtension: "ttf") else {
            return
        }
        var error: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
    }
}
