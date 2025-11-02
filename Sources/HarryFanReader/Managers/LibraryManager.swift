//
//  LibraryManager.swift
//  harryfan-reader
//
//  Created by @vt887 on 11/01/25.
//

import Foundation
import ZIPFoundation

/// Manages access to the HarryFan Library (remote or local)
final class LibraryManager: ObservableObject {
    /// The base URL for the library (Google Drive folder)
    let baseURL: URL

    @Published var isAuthenticated: Bool = false
    @Published var lastError: String? = nil
    @Published var availableFiles: [LibraryFile] = []

    init(
        baseURL: URL = URL(string: Settings.libraryURL)!
    ) {
        self.baseURL = baseURL
    }

    /// Represents a file in the library
    struct LibraryFile: Identifiable {
        let id: String
        let name: String
        let url: URL
        let size: Int?
        let modified: Date?
    }

    /// Fetch the list of files from the Library URL
    func fetchFiles(completion: @escaping ([LibraryFile]) -> Void) {
        let request = URLRequest(url: baseURL)

        let handler: (Data?, URLResponse?, Error?) -> Void = { data, _, _ in
            var result: [LibraryFile] = []
            if let data,
               let html = String(data: data, encoding: .utf8)
            {
                // Parse for file links ending in .bbs or .zip
                let pattern = "/file/d/([a-zA-Z0-9_-]+)[^>]*>([^<]+\\.(bbs|zip))<"
                let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let matches = regex?.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html)) ?? []
                for match in matches {
                    if match.numberOfRanges >= 3,
                       let idRange = Range(match.range(at: 1), in: html),
                       let nameRange = Range(match.range(at: 2), in: html)
                    {
                        let fileId = String(html[idRange])
                        let fileName = String(html[nameRange])
                        if let fileURL = URL(string: "https://drive.google.com/uc?export=download&id=\(fileId)") {
                            result.append(LibraryFile(id: fileId, name: fileName, url: fileURL, size: nil, modified: nil))
                        }
                    }
                }
            }

            DispatchQueue.main.async {
                self.availableFiles = result
                completion(result)
            }
        }

        let task = URLSession.shared.dataTask(with: request, completionHandler: handler)
        task.resume()
    }

    // MARK: - GoogleDriveService wrappers

    /// Fetch the list of files from the Google Drive API
    func fetchFilesFromDrive(completion: @escaping ([GoogleDriveFile]) -> Void) {
        GoogleDriveService.shared.listFiles(completion: completion)
    }

    /// Download a file from Google Drive by fileId
    func downloadFileFromDrive(fileId: String, completion: @escaping (URL?) -> Void) {
        GoogleDriveService.shared.downloadFile(fileId: fileId, completion: completion)
    }

    // MARK: - Download + unzip

    /// Download a file from the library to /tmp and unzip if it's a .zip
    func downloadFile(_ file: LibraryFile, completion: @escaping (Result<URL, Error>) -> Void) {
        // Ensure /tmp path
        let tmpPath = Settings.tmpDirName
        let tmpDirURL = URL(fileURLWithPath: tmpPath, isDirectory: true)
        let destURL = tmpDirURL.appendingPathComponent(file.name)
        let isZip = file.name.lowercased().hasSuffix(".zip")

        // Download the file to /tmp
        let downloadTask = URLSession.shared.downloadTask(with: file.url, completionHandler: { (tempURL: URL?, _: URLResponse?, error: Error?) in
            if let error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let tempURL else {
                DispatchQueue.main.async {
                    completion(
                        .failure(
                            NSError(
                                domain: "LibraryManager",
                                code: 1,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        "Download failed, no temp file",
                                ],
                            ),
                        ),
                    )
                }
                return
            }

            do {
                // Move downloaded file to /tmp with original name
                if FileManager.default.fileExists(atPath: destURL.path) {
                    try FileManager.default.removeItem(at: destURL)
                }
                try FileManager.default.moveItem(at: tempURL, to: destURL)

                // If it's a zip, unzip it
                if isZip {
                    let unzipDir = tmpDirURL.appendingPathComponent(file.name + "_unzipped")
                    if FileManager.default.fileExists(atPath: unzipDir.path) {
                        try FileManager.default.removeItem(at: unzipDir)
                    }
                    try FileManager.default.createDirectory(at: unzipDir, withIntermediateDirectories: true)

                    // Use throwing Archive initializer to unzip
                    let archive = try Archive(url: destURL, accessMode: .read)
                    for entry in archive {
                        let entryDest = unzipDir.appendingPathComponent(entry.path)
                        let entryDir = entryDest.deletingLastPathComponent()
                        if !FileManager.default.fileExists(atPath: entryDir.path) {
                            try FileManager.default.createDirectory(at: entryDir, withIntermediateDirectories: true)
                        }
                        _ = try archive.extract(entry, to: entryDest)
                    }
                    DispatchQueue.main.async { completion(.success(unzipDir)) }
                    return
                }
                // Not a zip, just return the file URL
                DispatchQueue.main.async { completion(.success(destURL)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        })
        downloadTask.resume()
    }
}
