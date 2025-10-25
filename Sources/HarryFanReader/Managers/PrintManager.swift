//
//  PrintManager.swift
//  harryfan-reader
//
//  Created by @vt887 on 10/25/25.
//

import AppKit
import Foundation
import SwiftUI

final class PrintManager: ObservableObject {
    // Public entry point - prints the given document on the main thread
    func printDocument(_ document: TextDocument) {
        DispatchQueue.main.async {
            DebugLogger.log("PrintManager.printDocument: starting print for file=\(document.fileName) totalLines=\(document.totalLines)")

            // If document is empty, do nothing (but we still allow fallback to image)
            let hasTextContent = document.totalLines > 0 || !document.fileName.isEmpty

            // Build plain text from document lines
            let text = document.content.joined(separator: "\n")

            // Prepare printInfo and default margins
            let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
            printInfo.topMargin = 36.0
            printInfo.leftMargin = 36.0
            printInfo.rightMargin = 36.0
            printInfo.bottomMargin = 36.0

            if hasTextContent {
                DebugLogger.log("PrintManager.printDocument: printing text content (chars=\(text.count))")

                // Prepare measurement parameters
                let paperWidth = printInfo.paperSize.width
                let printableWidth = paperWidth - printInfo.leftMargin - printInfo.rightMargin
                let printableHeight = max(1.0, printInfo.paperSize.height - printInfo.topMargin - printInfo.bottomMargin)

                // Build the final attributed string and determine page count
                let (attributed, pages) = self.buildFinalAttributedString(document: document, bodyText: text, printableWidth: printableWidth, printableHeight: printableHeight)

                DebugLogger.log("PrintManager.printDocument: final attributed length=\(attributed.length) pages=\(pages)")

                // Create an NSTextView sized to the paper width that will host the attributed text
                let textView = self.makeTextView(with: attributed, paperWidth: paperWidth, printableWidth: printableWidth)

                // Run print operation
                self.runPrintOperation(view: textView, printInfo: printInfo)

                return
            }

            // Fallback: try to print the visible canvas as an image snapshot of the key window's contentView
            if let keyWindow = NSApp.keyWindow ?? NSApp.mainWindow, let contentView = keyWindow.contentView {
                DebugLogger.log("PrintManager.printDocument: no text content; printing window snapshot for window=\(keyWindow.title)")
                guard let rep = contentView.bitmapImageRepForCachingDisplay(in: contentView.bounds) else {
                    DebugLogger.log("PrintManager.printDocument: failed to create bitmap rep for contentView")
                    return
                }
                contentView.cacheDisplay(in: contentView.bounds, to: rep)
                let nsImage = NSImage(size: contentView.bounds.size)
                nsImage.addRepresentation(rep)

                let imageView = NSImageView(frame: NSRect(origin: .zero, size: contentView.bounds.size))
                imageView.image = nsImage
                imageView.imageScaling = .scaleProportionallyUpOrDown

                self.runPrintOperation(view: imageView, printInfo: printInfo)
                return
            }

            DebugLogger.log("PrintManager.printDocument: nothing to print")
        }
    }

    // Build the final attributed string including header/footer and return page count
    private func buildFinalAttributedString(document: TextDocument, bodyText: String, printableWidth: CGFloat, printableHeight: CGFloat) -> (NSAttributedString, Int) {
        let nameOrApp = document.fileName.isEmpty ? Settings.appName : document.fileName
        let baseHeaderPrefix = "\(nameOrApp) (\(document.byteSize) bytes)"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let now = dateFormatter.string(from: Date())
        let footer = "\n\n--- End of Document — Generated on \(now) ---\n"

        // Text attributes for printing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 10.0, weight: .regular),
            .paragraphStyle: paragraphStyle,
        ]

        // Two-pass approach: first compute pages without "Pages" in header, then inject pages and recompute if needed
        let headerCandidate = baseHeaderPrefix + "\n\n"
        let fullCandidate = headerCandidate + bodyText + footer
        var pages = pagesForFullText(fullCandidate, attrs: attrs, printableWidth: printableWidth, printableHeight: printableHeight)

        // Recompute with pages included (handles digit-width changes)
        let headerWithPages = baseHeaderPrefix + " — Pages: \(pages)\n\n"
        let fullWithPages = headerWithPages + bodyText + footer
        let pages2 = pagesForFullText(fullWithPages, attrs: attrs, printableWidth: printableWidth, printableHeight: printableHeight)
        if pages2 != pages {
            pages = pages2
        }

        let finalHeader = baseHeaderPrefix + " — Pages: \(pages)\n\n"
        let finalFullText = finalHeader + bodyText + footer
        let attributed = NSAttributedString(string: finalFullText, attributes: attrs)
        return (attributed, pages)
    }

    // Measure the number of pages required to render the given fullText with attrs
    // (made internal so unit tests can verify pagination behavior)
    func pagesForFullText(_ fullText: String, attrs: [NSAttributedString.Key: Any], printableWidth: CGFloat, printableHeight: CGFloat) -> Int {
        let attributed = NSAttributedString(string: fullText, attributes: attrs)
        let ts = NSTextStorage(attributedString: attributed)
        let lm = NSLayoutManager()
        ts.addLayoutManager(lm)
        let tc = NSTextContainer(size: NSSize(width: printableWidth, height: .greatestFiniteMagnitude))
        lm.addTextContainer(tc)
        // Force layout and measure used rect
        lm.glyphRange(for: tc)
        let used = lm.usedRect(for: tc)
        let pages = max(1, Int(ceil(used.height / printableHeight)))
        return pages
    }

    // Create a text view to host the attributed string for printing
    private func makeTextView(with attributed: NSAttributedString, paperWidth: CGFloat, printableWidth: CGFloat) -> NSTextView {
        let textStorage = NSTextStorage(attributedString: attributed)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: NSSize(width: printableWidth, height: .greatestFiniteMagnitude))
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Use paper width for the view frame so the print system has correct page size
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: paperWidth, height: 800))
        textView.textStorage?.setAttributedString(attributed)
        textView.isEditable = false
        textView.isSelectable = true
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: printableWidth, height: .greatestFiniteMagnitude)
        return textView
    }

    // Run the print operation for a given view
    private func runPrintOperation(view: NSView, printInfo: NSPrintInfo) {
        DebugLogger.log("PrintManager: about to run print operation")
        let printOp = NSPrintOperation(view: view, printInfo: printInfo)
        printOp.showsPrintPanel = true
        printOp.showsProgressPanel = true
        NSApp.activate(ignoringOtherApps: true)
        DebugLogger.log("PrintManager: NSApp.activate called before printOp.run()")
        _ = printOp.run()
        DebugLogger.log("PrintManager: printOp.run() returned")
    }

    // Convenience static accessor for quick calls
    static let shared = PrintManager(registerForNotifications: true)
    static func sharedPrint(_ document: TextDocument) {
        DebugLogger.log("PrintManager.sharedPrint: forwarding to shared.printDocument for file=\(document.fileName) lines=\(document.totalLines)")
        shared.printDocument(document)
    }
}

// Bootstrap: ensure the shared instance is initialized at module load so the
// manager can register for notifications (if it chooses to). This avoids
// requiring callers to reference PrintManager directly.
private let _printManager_bootstrap: Void = {
    _ = PrintManager.shared
}()

// Extend PrintManager to observe 'AppCommand.printRequest' notifications and
// handle printing requests that arrive with userInfo containing text & filename.
extension PrintManager {
    convenience init(registerForNotifications: Bool = true) {
        self.init()
        if registerForNotifications {
            NotificationCenter.default.addObserver(forName: Notification.Name("AppCommand.printRequest"), object: nil, queue: .main) { [weak self] note in
                guard let self else { return }
                let keys = note.userInfo?.keys.map { "\($0)" } ?? []
                DebugLogger.log("PrintManager: received AppCommand.printRequest notification userInfoKeys=\(keys)")
                if let text = note.userInfo?["text"] as? String {
                    DebugLogger.log("PrintManager: printRequest text length=\(text.count)")
                    // Create a temporary TextDocument-like content and print
                    let tempDoc = TextDocument()
                    tempDoc.content = text.components(separatedBy: "\n")
                    tempDoc.fileName = note.userInfo?["fileName"] as? String ?? ""
                    printDocument(tempDoc)
                } else {
                    DebugLogger.log("PrintManager: printRequest missing text in userInfo")
                }
            }
        }
    }
}
