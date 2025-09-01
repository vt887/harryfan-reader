import SwiftUI

@main
struct TxtViewerApp: App {
    @StateObject private var fontManager = FontManager()
    @StateObject private var bookmarkManager = BookmarkManager()
    
    init() {
        print("TxtViewer app initializing...")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fontManager)
                .environmentObject(bookmarkManager)
                .frame(minWidth: 600, minHeight: 480)
                .onAppear {
                    print("ContentView appeared")
                    // Bring window to front and make it visible
                    DispatchQueue.main.async {
                        NSApplication.shared.activate(ignoringOtherApps: true)
                        if let window = NSApplication.shared.windows.first {
                            window.makeKeyAndOrderFront(nil)
                            window.level = .floating
                            print("Window should be visible now")
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
