//
//  ContentView.swift
//  harryfan-reader
//
//  Created by Vad Tymoshyk on 9/1/25.
//

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

    init() {
        print("ContentView initializing...")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack(alignment: .center) {
                Text(document.fileName.isEmpty ? "HarryFanReader" : document.fileName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Colors.topMenuFontColor)

                Spacer()

                // Up/Down buttons and percent
                if !document.fileName.isEmpty {
                    // Percent at top-right, based on center line index
                    let percent = document.totalLines > 0 ? Int((Double(document.currentLine + 1) / Double(document.totalLines)) * 100.0) : 0
                    Text("\(percent)%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Colors.foregroundColor)
                        .padding(.trailing, 8)

                    Button(action: { document.currentLine = max(0, document.currentLine - 1) }) {
                        Image(systemName: "chevron.up")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(Colors.foregroundColor)
                    .help("Scroll Up")

                    Button(action: { document.currentLine = min(max(0, document.totalLines - 1), document.currentLine + 1) }) {
                        Image(systemName: "chevron.down")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(Colors.foregroundColor)
                    .help("Scroll Down")

                    Divider()
                        .frame(height: 14)
                        .background(Colors.foregroundColor)
                        .padding(.horizontal, 4)

                    // Status info (center line number)
                    Text("Line \(document.currentLine + 1) of \(document.totalLines)")
                        .font(.system(size: 12))
                        .foregroundColor(Colors.foregroundColor)

                    Text("CP866")
                        .font(.system(size: 12))
                        .foregroundColor(Colors.foregroundColor)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Colors.foregroundColor)

            // Main content area
            if document.shouldShowQuitMessage {
                ScreenView(document: document, contentToDisplay: Messages.quitMessage)
                    .environmentObject(fontManager)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(Colors.foregroundColor)
            } else {
                ScreenView(document: document)
                    .environmentObject(fontManager)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(Colors.foregroundColor)
                    .onAppear {
                        if document.fileName.isEmpty {
                            document.loadWelcomeText()
                        }
                        print("Main content area appeared")
                    }
            }

            // Bottom menu bar
            BottomMenuBar(document: document)
        }
        .background(Colors.foregroundColor)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.plainText],
            allowsMultipleSelection: false,
        ) { result in
            switch result {
            case let .success(urls):
                if let url = urls.first {
                    document.openFile(at: url)
                }
            case let .failure(error):
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
                    .fill(configuration.isPressed ? Color.gray : Color(red: 0, green: 0, blue: 0.7)),
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white, lineWidth: 1),
            )
    }
}

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
}
