import SwiftUI

@main
struct WebViewAppApp: App {
    @AppStorage("webURL") private var webURL: String = "http://47.115.132.109:8081/"
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        #endif
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
