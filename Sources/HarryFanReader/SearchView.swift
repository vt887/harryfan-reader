//
//  SearchView.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/1/25.
//

import SwiftUI

// View for searching text in the document
struct SearchView: View {
    // Binding to control presentation of the search view
    @Binding var isPresented: Bool
    // Observed document model for searching
    @ObservedObject var document: TextDocument
    // Binding for last search term
    @Binding var lastSearchTerm: String
    // State for current search term
    @State private var searchTerm: String = ""
    // State for search direction
    @State private var searchDirection: SearchDirection = .forward
    // State for last search result line
    @State private var lastSearchResult: Int?

    // Main view body rendering the search UI
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Search")
                    .font(.headline)
                Spacer()
                Button("×") {
                    isPresented = false
                }
                .buttonStyle(.plain)
                .font(.title2)
            }

            HStack {
                TextField("Search term", text: $searchTerm)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        performSearch()
                    }

                Picker("Direction", selection: $searchDirection) {
                    Text("Forward").tag(SearchDirection.forward)
                    Text("Backward").tag(SearchDirection.backward)
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }

            HStack {
                Button("Find") {
                    performSearch()
                }
                .keyboardShortcut(.return)

                Button("Find Next") {
                    searchDirection = .forward
                    performSearch()
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Find Previous") {
                    searchDirection = .backward
                    performSearch()
                }
                .keyboardShortcut("p", modifiers: .command)

                Spacer()
            }

            if let result = lastSearchResult {
                Text("Found at line \(result + 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 400)
        .onAppear {
            // Focus the search field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Focus logic would go here
                searchTerm = lastSearchTerm
            }
        }
    }

    // Performs the search operation and updates result
    private func performSearch() {
        guard !searchTerm.isEmpty else { return }

        if let result = document.search(searchTerm, direction: searchDirection) {
            lastSearchResult = result
            lastSearchTerm = searchTerm
            document.gotoLine(result + 1)
        } else {
            lastSearchResult = nil
        }
    }
}
