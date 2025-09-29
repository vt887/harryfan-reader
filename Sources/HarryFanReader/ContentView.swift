//
//  ContentView.swift
//  harryfan-reader
//
//  Created by Vad Tymoshyk on 9/1/25.
//

import SwiftUI
import UniformTypeIdentifiers

// Main content view for the app
struct ContentView: View {
    @StateObject private var document = TextDocument()
    @EnvironmentObject var fontManager: FontManager
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @EnvironmentObject var recentFilesManager: RecentFilesManager

    @State private var showingFilePicker = false
    @State private var showingSearch = false
    @State private var showingBookmarks = false
    @State private var lastSearchTerm: String = ""
    @State private var showingSettings = false
    @State private var showingGotoDialog = false
    @State private var gotoLineNumber = ""

    init() {
        DebugLogger.log("ContentView initializing...")
    }

    var body: some View {
        mainLayout
            .frame(
                width: CGFloat(AppSettings.cols * AppSettings.charW),
                height: CGFloat(document.rows) * CGFloat(AppSettings.charH),
            )
            .background(Colors.theme.background)
            .fileImporter(isPresented: $showingFilePicker,
                          allowedContentTypes: [.plainText],
                          allowsMultipleSelection: false,
                          onCompletion: handleFileImport)
            .sheet(isPresented: $showingSearch) {
                SearchView(isPresented: $showingSearch,
                           document: document,
                           lastSearchTerm: $lastSearchTerm)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(fontManager)
                    .environmentObject(document)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingBookmarks) {
                BookmarksView(isPresented: $showingBookmarks,
                              document: document)
                    .environmentObject(bookmarkManager)
                    .frame(width: 400, height: 300)
            }
            .alert("Go to Line", isPresented: $showingGotoDialog) {
                gotoLineDialog
            } message: {
                Text("Enter line number to go to:")
            }
            .applyNotifications(document: document,
                                showingSearch: $showingSearch,
                                showingBookmarks: $showingBookmarks,
                                showingFilePicker: $showingFilePicker,
                                lastSearchTerm: $lastSearchTerm)
    }

    // Main layout
    private var mainLayout: some View {
        VStack(spacing: 0) {
            TitleBar(document: document)

            ScreenView(document: document,
                       contentToDisplay: " ",
                       displayRows: 1,
                       rowOffset: 1)
                .environmentObject(fontManager)
                .frame(height: CGFloat(1) * CGFloat(AppSettings.charH))

            MainContentScreenView(document: document)

            ScreenView(document: document,
                       contentToDisplay: String(repeating: "\n", count: 14),
                       displayRows: 14,
                       rowOffset: 9)
                .environmentObject(fontManager)
                .frame(height: CGFloat(14) * CGFloat(AppSettings.charH))

            MenuBar(document: document)
        }
    }

    // File Import Handler
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            if let url = urls.first {
                document.openFile(at: url)
                recentFilesManager.addRecentFile(url: url)
            }
        case let .failure(error):
            DebugLogger.logError("Error selecting file: \(error)")
        }
    }

    // Go To Line Dialog
    private var gotoLineDialog: some View {
        Group {
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
        }
    }
}

// Main content area view, displays either quit message or main content
private struct MainContentScreenView: View {
    @ObservedObject var document: TextDocument
    @EnvironmentObject var fontManager: FontManager

    var body: some View {
        if document.shouldShowQuitMessage {
            ScreenView(document: document, contentToDisplay: Messages.quitMessage, displayRows: 7, rowOffset: 2)
                .environmentObject(fontManager)
                .frame(height: CGFloat(7) * CGFloat(ScreenView.charH))
        } else {
            ScreenView(document: document, displayRows: 7, rowOffset: 2)
                .environmentObject(fontManager)
                .frame(height: CGFloat(7) * CGFloat(ScreenView.charH))
                .onAppear {
                    if document.fileName.isEmpty {
                        document.loadWelcomeText()
                    }
                    DebugLogger.log("Main content area appeared")
                }
        }
    }
}

// ViewModifier for handling notifications and commands
private struct NotificationsModifier: ViewModifier {
    @ObservedObject var document: TextDocument
    @EnvironmentObject var fontManager: FontManager
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @EnvironmentObject var recentFilesManager: RecentFilesManager
    @Binding var showingSearch: Bool
    @Binding var showingBookmarks: Bool
    @Binding var showingFilePicker: Bool
    @Binding var lastSearchTerm: String

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
                // Handle window focus
            }
            .onReceive(NotificationCenter.default.publisher(for: .openFileCommand)) { _ in
                showingFilePicker = true
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
                if let bookmark = bookmarkManager.nextBookmark(after: document.currentLine, in: document.fileName) {
                    document.gotoLine(bookmark.line + 1)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .previousBookmarkCommand)) { _ in
                guard !document.fileName.isEmpty else { return }
                if let bookmark = bookmarkManager.previousBookmark(before: document.currentLine, in: document.fileName) {
                    document.gotoLine(bookmark.line + 1)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .showBookmarksCommand)) { _ in
                guard !document.fileName.isEmpty else { return }
                showingBookmarks = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .scrollUpCommand)) { _ in
                document.gotoStart() // Use gotoStart for scroll up
            }
            .onReceive(NotificationCenter.default.publisher(for: .scrollDownCommand)) { _ in
                document.gotoEnd() // Use gotoEnd for scroll down
            }
            .onReceive(NotificationCenter.default.publisher(for: .pageUpCommand)) { _ in
                document.pageUp() // Use pageUp with default page size
            }
            .onReceive(NotificationCenter.default.publisher(for: .pageDownCommand)) { _ in
                document.pageDown() // Use pageDown with default page size
            }
            .onReceive(NotificationCenter.default.publisher(for: .openRecentFileCommand)) { notification in
                if let userInfo = notification.userInfo,
                   let url = userInfo["url"] as? URL {
                    document.openFile(at: url)
                    recentFilesManager.addRecentFile(url: url)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .clearRecentFilesCommand)) { _ in
                recentFilesManager.clearRecentFiles()
            }
    }
}

// Extension for applying notification modifier to views
private extension View {
    func applyNotifications(document: TextDocument, showingSearch: Binding<Bool>, showingBookmarks: Binding<Bool>, showingFilePicker: Binding<Bool>, lastSearchTerm: Binding<String>) -> some View {
        modifier(NotificationsModifier(document: document, showingSearch: showingSearch, showingBookmarks: showingBookmarks, showingFilePicker: showingFilePicker, lastSearchTerm: lastSearchTerm))
    }
}

// Button style for retro-themed buttons
struct RetroButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(configuration.isPressed ? Color.gray : Color(red: 0, green: 0, blue: 0.7)),
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white, lineWidth: 1),
            )
    }
}

// Button style for retro-themed menu buttons
struct RetroMenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.black)
            .font(.system(size: 12, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .fill(configuration.isPressed ? Color.gray : Color.clear),
            )
    }
}

#Preview {
    ContentView()
        .environmentObject(FontManager())
        .environmentObject(BookmarkManager())
        .environmentObject(RecentFilesManager())
}
