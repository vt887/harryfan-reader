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
            // Title bar (Line 1)
            TitleBar(document: document)

            // Empty line 2
            ScreenView(document: document, contentToDisplay: " ", displayRows: 1, rowOffset: 1)
                .environmentObject(fontManager)
                .frame(height: CGFloat(1) * CGFloat(ScreenView.charH))

            // Main content area (Lines 3-9) - 7 rows
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
                        print("Main content area appeared")
                    }
            }

            // Empty lines 10-23 (14 rows)
            ScreenView(document: document,
                       contentToDisplay: String(repeating: "\n",
                                                count: 14),
                       displayRows: 14,
                       rowOffset: 9)
                .environmentObject(fontManager)
                .frame(height: CGFloat(14) * CGFloat(ScreenView.charH))

            // Bottom menu bar (Line 24)
            MenuBar(document: document)
        }
        .frame(width: CGFloat(ScreenView.cols * ScreenView.charW),
               height: CGFloat(document.rows) * CGFloat(ScreenView.charH))
        .background(Colors.theme.background)
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
