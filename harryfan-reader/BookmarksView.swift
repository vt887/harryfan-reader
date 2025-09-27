//
//  BookmarksView.swift
//  harryfan-reader
//
//  Created by Vad Tymoshyk on 9/2/25.
//

import SwiftUI

struct BookmarksView: View {
    @Binding var isPresented: Bool
    @ObservedObject var document: TextDocument
    @EnvironmentObject var bookmarkManager: BookmarkManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Bookmarks")
                    .font(.headline)
                Spacer()
                Button("Close") { isPresented = false }
                    .buttonStyle(.plain)
            }
            List {
                ForEach(bookmarkManager.getBookmarks(for: document.fileName)) { bm in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Line \(bm.line + 1)")
                                .font(.body)
                            Text(bm.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Go") {
                            document.gotoLine(bm.line + 1)
                            isPresented = false
                        }
                        Button(role: .destructive) {
                            bookmarkManager.removeBookmark(bm)
                        } label: {
                            Text("Delete")
                        }
                    }
                }
            }
            HStack {
                Button("Add Current Line") {
                    let desc = document.getCurrentLine()
                    bookmarkManager.addBookmark(fileName: document.fileName, line: document.currentLine, description: desc)
                }
                Spacer()
            }
        }
        .padding()
    }
}
