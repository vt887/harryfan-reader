import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var document = TextDocument()
    @EnvironmentObject var fontManager: FontManager
    @EnvironmentObject var bookmarkManager: BookmarkManager
    
    @State private var showingFilePicker = false
    @State private var showingSearch = false
    @State private var showingBookmarks = false
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
            // Title bar
            HStack {
                Text(document.fileName.isEmpty ? "TxtViewer" : document.fileName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(textColor)
                
                Spacer()
                
                // Status info
                if !document.fileName.isEmpty {
                    Text("Line \(document.currentLine + 1) of \(document.totalLines)")
                        .font(.system(size: 12))
                        .foregroundColor(textColor)
                    
                    Text("CP866")
                        .font(.system(size: 12))
                        .foregroundColor(highlightColor)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            
            // Main content area
            if document.fileName.isEmpty {
                // Welcome screen
                VStack(spacing: 20) {
                    Text("TXT VIEWER")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(highlightColor)
                    
                    Text("Retro-style text viewer for CP866 encoded files")
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
                // Text content
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(document.content.enumerated()), id: \.offset) { index, line in
                                Text(line.isEmpty ? " " : line)
                                    .font(.system(size: fontManager.fontSize, weight: .regular, design: .monospaced))
                                    .foregroundColor(textColor)
                                    .background(index == document.currentLine ? highlightColor.opacity(0.3) : Color.clear)
                                    .id(index)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                            }
                        }
                    }
                    .onChange(of: document.currentLine) { _, newLine in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            proxy.scrollTo(newLine, anchor: .center)
                        }
                    }
                }
                .background(backgroundColor)
            }
            
            // Bottom menu bar (MS-DOS style)
            HStack(spacing: 20) {
                Button("1Help") {
                    // Show help
                }
                .buttonStyle(RetroMenuButtonStyle())
                
                Button("2Open") {
                    showingFilePicker = true
                }
                .buttonStyle(RetroMenuButtonStyle())
                
                Button("3Close") {
                    document.closeFile()
                }
                .buttonStyle(RetroMenuButtonStyle())
                .disabled(document.fileName.isEmpty)
                
                Button("4Search") {
                    showingSearch = true
                }
                .buttonStyle(RetroMenuButtonStyle())
                
                Button("5Goto") {
                    showingGotoDialog = true
                }
                .buttonStyle(RetroMenuButtonStyle())
                
                Button("6Bookmarks") {
                    showingBookmarks = true
                }
                .buttonStyle(RetroMenuButtonStyle())
                
                Button("7Home") {
                    document.gotoStart()
                }
                .buttonStyle(RetroMenuButtonStyle())
                
                Button("8End") {
                    document.gotoEnd()
                }
                .buttonStyle(RetroMenuButtonStyle())
                
                Button("9Wrap") {
                    document.wordWrap.toggle()
                    if !document.fileName.isEmpty {
                        document.reloadWithNewSettings()
                    }
                }
                .buttonStyle(RetroMenuButtonStyle())
                .disabled(document.fileName.isEmpty)
                
                Button("0Settings") {
                    showingSettings = true
                }
                .buttonStyle(RetroMenuButtonStyle())
                
                Spacer()
                
                Button("QQuit") {
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
            SearchView(isPresented: $showingSearch, document: document)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(fontManager)
                .environmentObject(document)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
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
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { notification in
            // Handle window focus
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
