//
//  ContentView.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/1/25.
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
        VStack(spacing: 0) {
            TitleBar(document: document)

            MainContentScreenView(document: document)

            MenuBar(document: document)
        }
        .frame(
            width: CGFloat(AppSettings.cols * AppSettings.charW),
            height: CGFloat(AppSettings.rows * AppSettings.charH)
        )
        .background(Colors.theme.background)
        .fileImporter(isPresented: $showingFilePicker,
                      allowedContentTypes: [UTType.plainText],
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
        .applyNotifications(document: document,
                            showingSearch: $showingSearch,
                            showingBookmarks: $showingBookmarks,
                            showingFilePicker: $showingFilePicker,
                            lastSearchTerm: $lastSearchTerm)
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
}

// Private struct for the main content screen view
private struct MainContentScreenView: View {
    @ObservedObject var document: TextDocument
    @EnvironmentObject var fontManager: FontManager

    var body: some View {
        if document.shouldShowQuitMessage {
            ScreenView(document: document, contentToDisplay: Messages.quitMessage, displayRows: AppSettings.rows - 2, rowOffset: 1)
                .environmentObject(fontManager)
                .frame(height: CGFloat(AppSettings.rows - 2) * CGFloat(ScreenView.charH))
        } else {
            ScreenView(document: document, displayRows: AppSettings.rows - 2, rowOffset: 1)
                .environmentObject(fontManager)
                .frame(height: CGFloat(AppSettings.rows - 2) * CGFloat(ScreenView.charH))
                .onAppear {
                    if document.fileName.isEmpty {
                        document.loadWelcomeText()
                    }
                    DebugLogger.log("Main content area appeared")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FontManager())
        .environmentObject(BookmarkManager())
        .environmentObject(RecentFilesManager())
}
