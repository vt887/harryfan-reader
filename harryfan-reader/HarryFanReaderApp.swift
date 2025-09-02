import SwiftUI

@main
struct HarryfanReaderApp: App {
    @StateObject private var fontManager = FontManager()
    @StateObject private var bookmarkManager = BookmarkManager()
    
    init() {
        print("HarryfanReader app initializing...")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fontManager)
                .environmentObject(bookmarkManager)
                .frame(minWidth: 600, minHeight: 480)
                .onAppear {
                    DispatchQueue.main.async {
                        NSApplication.shared.activate(ignoringOtherApps: true)
                        if let window = NSApplication.shared.windows.first {
                            window.makeKeyAndOrderFront(nil)
                            window.level = .floating
                        }
                    }
                }
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 800, height: 600)
        .defaultPosition(.center)
        
        Settings {
            SettingsView()
                .environmentObject(fontManager)
        }
    }
}
