// AboutOverlay.swift
// harryfan-reader

import SwiftUI

struct AboutOverlay: View {
    @Binding var isPresented: Bool
    @State private var escMonitor: Any?
    private var aboutText: String {
        let lines = Messages.aboutMessage.components(separatedBy: "\n")
        let versionLineIndex = lines.firstIndex(where: { $0.contains("Version") })
        var newLines = lines
        if let idx = versionLineIndex {
            let versionString = "Version \(ReleaseInfo.version).\(ReleaseInfo.build)"
            let originalLine = lines[idx]
            // Find left border (all leading whitespace and border chars)
            let leftBorderEnd = originalLine.firstIndex(where: { !$0.isWhitespace && $0 != "║" }) ?? originalLine.startIndex
            let left = originalLine[..<leftBorderEnd]
            // Find right border (all trailing whitespace and border chars)
            let rightBorderStart = originalLine.lastIndex(where: { !$0.isWhitespace && $0 != "║" })
            let right = rightBorderStart != nil ? originalLine[(originalLine.index(after: rightBorderStart!))...] : ""
            let contentWidth = originalLine.count - left.count - right.count
            let paddedVersion = versionString.padding(toLength: contentWidth, withPad: " ", startingAt: 0)
            newLines[idx] = String(left) + paddedVersion + String(right)
        }
        return newLines.joined(separator: "\n")
    }
    var body: some View {
        ZStack {
            Color.black.opacity(0.8).edgesIgnoringSafeArea(.all)
            VStack {
                Text(aboutText)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white)
                    .padding()
                Button("Close") {
                    isPresented = false
                }
                .padding(.top, 8)
            }
            .frame(width: 420)
            .background(Color(.windowBackgroundColor))
            .cornerRadius(16)
            .shadow(radius: 20)
        }
        .onAppear {
            escMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 53 { // ESC key
                    isPresented = false
                    return nil
                }
                return event
            }
        }
        .onDisappear {
            if let monitor = escMonitor {
                NSEvent.removeMonitor(monitor)
                escMonitor = nil
            }
        }
    }
}

#Preview {
    AboutOverlay(isPresented: .constant(true))
}
