// PrintManager.swift
// Responsible for printing the current document using AppKit's print system

import AppKit
import Foundation
import SwiftUI

final class PrintManager: ObservableObject {
    // Instance method to print the document. Runs on the main thread.
    func printDocument(_ document: TextDocument) {
        DispatchQueue.main.async {
            // If document is empty, do nothing (but we still allow fallback to image)
            let hasTextContent = document.totalLines > 0 || !document.fileName.isEmpty

            // Build plain text from document lines
            let text = document.content.joined(separator: "\n")

            // Prepare printInfo
            let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
            // Reasonable page margins
            printInfo.topMargin = 36.0
            printInfo.leftMargin = 36.0
            printInfo.rightMargin = 36.0
            printInfo.bottomMargin = 36.0

            // If we have text content, print using an NSTextView with monospaced font and header/footer
            if hasTextContent {
                // Compose header and footer
                let header = "\(document.fileName.isEmpty ? Settings.appName : document.fileName)\n"
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .short
                let now = dateFormatter.string(from: Date())
                let footer = "\n--- End of Document — Printed: \(now) ---\n"

                // Create attributed string with monospaced font
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakMode = .byWordWrapping

                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedSystemFont(ofSize: 10.0, weight: .regular),
                    .paragraphStyle: paragraphStyle
                ]

                let fullText = header + text + footer
                let attributed = NSAttributedString(string: fullText, attributes: attrs)

                // Create an NSTextView to host printable text sized to print width
                let printWidth: CGFloat = 612.0 // ~8.5 inches at 72 DPI
                let textStorage = NSTextStorage(attributedString: attributed)
                let layoutManager = NSLayoutManager()
                let textContainer = NSTextContainer(size: NSSize(width: printWidth - printInfo.leftMargin - printInfo.rightMargin, height: .greatestFiniteMagnitude))
                layoutManager.addTextContainer(textContainer)
                textStorage.addLayoutManager(layoutManager)

                let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: printWidth, height: 800))
                textView.textStorage?.setAttributedString(attributed)
                textView.isEditable = false
                textView.isSelectable = true
                textView.textContainer?.lineFragmentPadding = 0
                textView.textContainer?.widthTracksTextView = true
                textView.textContainer?.containerSize = NSSize(width: printWidth, height: .greatestFiniteMagnitude)

                // Create and run the print operation
                let printOp = NSPrintOperation(view: textView, printInfo: printInfo)
                printOp.showsPrintPanel = true
                printOp.showsProgressPanel = true
                _ = printOp.run()
                return
            }

            // Fallback: try to print the visible canvas as an image snapshot of the key window's contentView
            if let keyWindow = NSApp.keyWindow ?? NSApp.mainWindow, let contentView = keyWindow.contentView {
                // Create an image representation of the view
                let rep = contentView.bitmapImageRepForCachingDisplay(in: contentView.bounds)!
                contentView.cacheDisplay(in: contentView.bounds, to: rep)
                let nsImage = NSImage(size: contentView.bounds.size)
                nsImage.addRepresentation(rep)

                // Build an NSImageView and print it
                let imageView = NSImageView(frame: NSRect(origin: .zero, size: contentView.bounds.size))
                imageView.image = nsImage
                imageView.imageScaling = .scaleProportionallyUpOrDown

                let printOp = NSPrintOperation(view: imageView, printInfo: printInfo)
                printOp.showsPrintPanel = true
                printOp.showsProgressPanel = true
                _ = printOp.run()
                return
            }

            // Nothing to print
        }
    }

    // Convenience static accessor for quick calls
    static let shared = PrintManager()
    static func sharedPrint(_ document: TextDocument) { shared.printDocument(document) }
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
                guard let self = self else { return }
                if let text = note.userInfo?["text"] as? String {
                    // Create a temporary TextDocument-like content and print
                    let tempDoc = TextDocument()
                    tempDoc.content = text.components(separatedBy: "\n")
                    tempDoc.fileName = note.userInfo?["fileName"] as? String ?? ""
                    self.printDocument(tempDoc)
                }
            }
        }
    }
}
