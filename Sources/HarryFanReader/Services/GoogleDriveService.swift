//
//  GoogleDriveService.swift
//  harryfan-reader
//
//  Created by automated-refactor on 11/01/25.
//

import Foundation

class GoogleDriveService {
    static let shared = GoogleDriveService()
    // Use static libraryURL from Settings
    private var folderURL: String {
        Settings.libraryURL
    }

    // Extract folderId from the URL if needed
    private var folderId: String {
        // Example: extract last path component
        URL(string: Settings.libraryURL)?.lastPathComponent ?? ""
    }

    private var downloadBase: String {
        "https://drive.google.com/uc"
    }

    private init() {}

    // MARK: - List Files (HTML scraping for public folder)

    func listFiles(completion: @escaping ([GoogleDriveFile]) -> Void) {
        guard let url = URL(string: folderURL) else {
            completion([])
            return
        }
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data, error == nil, let html = String(data: data, encoding: .utf8) else {
                completion([])
                return
            }
            // Scrape file IDs and names from HTML
            let regex = try? NSRegularExpression(
                pattern: "/file/d/([a-zA-Z0-9_-]+)[^>]*>([^<]+)<",
                options: [.caseInsensitive],
            )
            let matches = regex?.matches(
                in: html,
                options: [],
                range: NSRange(html.startIndex..., in: html),
            ) ?? []
            var files: [GoogleDriveFile] = []
            for match in matches {
                if match.numberOfRanges >= 3,
                   let idRange = Range(match.range(at: 1), in: html),
                   let nameRange = Range(match.range(at: 2), in: html)
                {
                    let fileId = String(html[idRange])
                    let fileName = String(html[nameRange])
                    files.append(GoogleDriveFile(id: fileId, name: fileName, mimeType: "", size: nil))
                }
            }
            completion(files)
        }
        task.resume()
    }

    // MARK: - Download File (direct public link)

    func downloadFile(fileId: String, completion: @escaping (URL?) -> Void) {
        let downloadURL = downloadBase + "?export=download&id=\(fileId)"
        guard let url = URL(string: downloadURL) else {
            completion(nil)
            return
        }
        let task = URLSession.shared.downloadTask(with: url) { tempURL, _, error in
            guard let tempURL, error == nil else {
                completion(nil)
                return
            }
            completion(tempURL)
        }
        task.resume()
    }
}

struct GoogleDriveFile {
    let id: String
    let name: String
    let mimeType: String
    let size: Int?
}
