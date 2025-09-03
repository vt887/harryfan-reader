import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var document = TextDocument()
    @EnvironmentObject var fontManager: FontManager
    @EnvironmentObject var bookmarkManager: BookmarkManager
    
    @State private var showingFilePicker = false
    @State private var showingSearch = false
    @State private var showingBookmarks = false
    @State private var lastSearchTerm: String = ""
    @State private var showingSettings = false
    @State private var showingGotoDialog = false
    @State private var gotoLineNumber = ""
    
    // MS-DOS style colors
    private let backgroundColor = Color(red: 0, green: 0, blue: 0.5) // Dark blue
    private let textColor = Color.white
    private let highlightColor = Color(red: 0, green: 1, blue: 1) // Cyan
    
    init() {
        print("ContentView initializing...")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar (inverted: white background, blue letters)
            HStack(alignment: .center) {
                Text(document.fileName.isEmpty ? "HarryFanReader" : document.fileName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 0, green: 0, blue: 0.5))
                
                Spacer()
                
                // Up/Down buttons and percent
                if !document.fileName.isEmpty {
                    // Percent at top-right, based on center line index
                    let percent = document.totalLines > 0 ? Int((Double(document.currentLine + 1) / Double(document.totalLines)) * 100.0) : 0
                    Text("\(percent)%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0, green: 0, blue: 0.5))
                        .padding(.trailing, 8)
                    
                    Button(action: { document.currentLine = max(0, document.currentLine - 1) }) {
                        Image(systemName: "chevron.up")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(Color(red: 0, green: 0, blue: 0.5))
                    .help("Scroll Up")
                    
                    Button(action: { document.currentLine = min(max(0, document.totalLines - 1), document.currentLine + 1) }) {
                        Image(systemName: "chevron.down")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(Color(red: 0, green: 0, blue: 0.5))
                    .help("Scroll Down")
                    
                    Divider()
                        .frame(height: 14)
                        .background(Color(red: 0, green: 0, blue: 0.5).opacity(0.5))
                        .padding(.horizontal, 4)
                    
                    // Status info (center line number)
                    Text("Line \(document.currentLine + 1) of \(document.totalLines)")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0, green: 0, blue: 0.5))
                    
                    Text("CP866")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0, green: 0, blue: 0.5))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white)
            
            // Main content area
            if document.fileName.isEmpty {
                // Welcome screen
                VStack(spacing: 20) {
                    Text("HarryFan Reader")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(highlightColor)
                    
                    Text("Retro MS-DOS Style Text Viewer from Fidonet era")
                        .font(.system(size: 14))
                        .foregroundColor(textColor)
                    
                    Button("Open File") {
                        showingFilePicker = true
                    }
                    .buttonStyle(RetroButtonStyle())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(backgroundColor)
                .onAppear {
                    print("Welcome screen appeared")
                }
            } else {
                // Text content rendered in 80x24 using vdu.8x16.raw
                MSDOSScreenView(document: document)
                    .environmentObject(fontManager)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(backgroundColor)
            }
            
            // Bottom menu bar (MS-DOS style)
            HStack(spacing: 20) {
                Button("1Help") {
                    // Show help
                }
                .buttonStyle(RetroMenuButtonStyle())

                Button("2Wrap") {
                    document.wordWrap.toggle()
                    if !document.fileName.isEmpty {
                        document.reloadWithNewSettings()
                    }
                }
                .buttonStyle(RetroMenuButtonStyle())
                .disabled(document.fileName.isEmpty)

                
                Button("3Open") {
                    showingFilePicker = true
                }
                .buttonStyle(RetroMenuButtonStyle())

                Button("4Search") {
                    showingSearch = true
                }
                .buttonStyle(RetroMenuButtonStyle())
                
                Button("5Goto") {
                    showingGotoDialog = true
                }
                .buttonStyle(RetroMenuButtonStyle())
                
                Button("6Bookm") {
                    showingBookmarks = true
                }
                .buttonStyle(RetroMenuButtonStyle())
                
                Button("7Start") {
                    document.gotoStart()
                }
                .buttonStyle(RetroMenuButtonStyle())
                
                Button("8End") {
                    document.gotoEnd()
                }
                .buttonStyle(RetroMenuButtonStyle())

                Button("9Menu") {
                    showingSettings = true
                }
                .buttonStyle(RetroMenuButtonStyle())
                
                Button("10Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(RetroMenuButtonStyle())
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
        }
        .background(backgroundColor)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    document.openFile(at: url)
                }
            case .failure(let error):
                print("Error selecting file: \(error)")
            }
        }
        .sheet(isPresented: $showingSearch) {
            SearchView(isPresented: $showingSearch, document: document, lastSearchTerm: $lastSearchTerm)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(fontManager)
                .environmentObject(document)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingBookmarks) {
            BookmarksView(isPresented: $showingBookmarks, document: document)
                .environmentObject(bookmarkManager)
                .frame(width: 400, height: 300)
        }
        .alert("Go to Line", isPresented: $showingGotoDialog) {
            TextField("Line number", text: $gotoLineNumber)
            
            Button("Go") {
                if let lineNumber = Int(gotoLineNumber) {
                    document.gotoLine(lineNumber - 1)
                }
                gotoLineNumber = ""
            }
            
            Button("Cancel", role: .cancel) {
                gotoLineNumber = ""
            }
        } message: {
            Text("Enter line number to go to:")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            // Handle window focus
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSearchCommand)) { _ in
            if document.fileName.isEmpty { return }
            showingSearch = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .findNextCommand)) { _ in
            guard !lastSearchTerm.isEmpty else { showingSearch = true; return }
            if let idx = document.search(lastSearchTerm, direction: .forward) {
                document.gotoLine(idx + 1)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .findPreviousCommand)) { _ in
            guard !lastSearchTerm.isEmpty else { showingSearch = true; return }
            if let idx = document.search(lastSearchTerm, direction: .backward) {
                document.gotoLine(idx + 1)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .addBookmarkCommand)) { _ in
            guard !document.fileName.isEmpty else { return }
            let desc = document.getCurrentLine()
            bookmarkManager.addBookmark(fileName: document.fileName, line: document.currentLine, description: desc)
        }
        .onReceive(NotificationCenter.default.publisher(for: .nextBookmarkCommand)) { _ in
            guard !document.fileName.isEmpty else { return }
            if let bm = bookmarkManager.nextBookmark(after: document.currentLine, in: document.fileName) {
                document.gotoLine(bm.line + 1)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .previousBookmarkCommand)) { _ in
            guard !document.fileName.isEmpty else { return }
            if let bm = bookmarkManager.previousBookmark(before: document.currentLine, in: document.fileName) {
                document.gotoLine(bm.line + 1)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showBookmarksCommand)) { _ in
            guard !document.fileName.isEmpty else { return }
            showingBookmarks = true
        }
    }
    
    // Keyboard handling will be implemented with proper key event monitoring
    // For now, we'll use menu items and buttons for navigation
}

struct RetroButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(configuration.isPressed ? Color.gray : Color(red: 0, green: 0, blue: 0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white, lineWidth: 1)
            )
    }
}

struct RetroMenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .font(.system(size: 12, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .fill(configuration.isPressed ? Color.gray : Color.clear)
            )
    }
}

#Preview {
    ContentView()
        .environmentObject(FontManager())
        .environmentObject(BookmarkManager())
}
