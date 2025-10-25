//
//  RecentFilesManager.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/29/25.
//

import Foundation
import SwiftUI

// Model for a recent file entry
struct RecentFile: Identifiable, Codable, Equatable {
    let id: UUID
    let url: URL
    let displayName: String
    var lastOpened: Date

    init(url: URL) {
        id = UUID()
        self.url = url
        displayName = url.lastPathComponent
        lastOpened = Date()
    }
}

// Manager class for handling recent files
class RecentFilesManager: ObservableObject {
    @Published var recentFiles: [RecentFile] = []

    private let maxRecentFiles = 20
    private let userDefaultsKey = "recentFiles"

    init() {
        loadRecentFiles()
    }

    // Adds a file to the recent files list
    func addRecentFile(url: URL) {
        DispatchQueue.main.async {
            // If an entry exists, update its lastOpened and move it to the front
            if let existingIndex = self.recentFiles.firstIndex(where: { $0.url == url }) {
                var existing = self.recentFiles.remove(at: existingIndex)
                existing.lastOpened = Date()
                self.recentFiles.insert(existing, at: 0)
            } else {
                // Add new entry at the beginning
                let newFile = RecentFile(url: url)
                self.recentFiles.insert(newFile, at: 0)
            }

            // Keep only the latest maxRecentFiles files
            if self.recentFiles.count > self.maxRecentFiles {
                self.recentFiles = Array(self.recentFiles.prefix(self.maxRecentFiles))
            }

            self.saveRecentFiles()
        }
    }

    // Clears all recent files
    func clearRecentFiles() {
        DispatchQueue.main.async {
            self.recentFiles = []
            self.saveRecentFiles()
        }
    }

    // Saves recent files to UserDefaults
    private func saveRecentFiles() {
        DispatchQueue.global(qos: .utility).async {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(self.recentFiles)
                UserDefaults.standard.set(data, forKey: self.userDefaultsKey)
            } catch {
                DebugLogger.logError("Failed to save recent files: \(error)")
            }
        }
    }

    // Loads recent files from UserDefaults
    private func loadRecentFiles() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }

        DispatchQueue.global(qos: .utility).async {
            do {
                let decoder = JSONDecoder()
                var loaded = try decoder.decode([RecentFile].self, from: data)

                // Remove files that no longer exist
                loaded = loaded.filter { FileManager.default.fileExists(atPath: $0.url.path) }

                // Keep only the latest maxRecentFiles
                if loaded.count > self.maxRecentFiles {
                    loaded = Array(loaded.prefix(self.maxRecentFiles))
                }

                DispatchQueue.main.async {
                    self.recentFiles = loaded
                    self.saveRecentFiles()
                }
            } catch {
                DebugLogger.logError("Failed to load recent files: \(error)")
                DispatchQueue.main.async { self.recentFiles = [] }
            }
        }
    }
}
