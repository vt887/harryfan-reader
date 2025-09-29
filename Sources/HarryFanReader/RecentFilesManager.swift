//
//  RecentFilesManager.swift
//  harryfan-reader
//
//  Created by Vad Tymoshyk on 9/29/25.
//

import Foundation
import SwiftUI

// Model for a recent file entry
struct RecentFile: Identifiable, Codable, Equatable {
    let id: UUID
    let url: URL
    let displayName: String
    let lastOpened: Date
    
    init(url: URL) {
        self.id = UUID()
        self.url = url
        self.displayName = url.lastPathComponent
        self.lastOpened = Date()
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
        // Remove existing entry if file was already opened
        recentFiles.removeAll { $0.url == url }
        
        // Add new entry at the beginning
        let newFile = RecentFile(url: url)
        recentFiles.insert(newFile, at: 0)
        
        // Keep only the latest 20 files
        if recentFiles.count > maxRecentFiles {
            recentFiles = Array(recentFiles.prefix(maxRecentFiles))
        }
        
        saveRecentFiles()
    }
    
    // Clears all recent files
    func clearRecentFiles() {
        recentFiles = []
        saveRecentFiles()
    }
    
    // Saves recent files to UserDefaults
    private func saveRecentFiles() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(recentFiles)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            DebugLogger.logError("Failed to save recent files: \(error)")
        }
    }
    
    // Loads recent files from UserDefaults
    private func loadRecentFiles() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            recentFiles = try decoder.decode([RecentFile].self, from: data)
            
            // Remove files that no longer exist
            recentFiles = recentFiles.filter { FileManager.default.fileExists(atPath: $0.url.path) }
            
            // Keep only the latest 20
            if recentFiles.count > maxRecentFiles {
                recentFiles = Array(recentFiles.prefix(maxRecentFiles))
            }
            
            saveRecentFiles()
        } catch {
            DebugLogger.logError("Failed to load recent files: \(error)")
            recentFiles = []
        }
    }
}
