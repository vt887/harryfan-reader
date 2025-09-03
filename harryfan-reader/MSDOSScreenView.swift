import SwiftUI

struct MSDOSScreenView: View {
    @ObservedObject var document: TextDocument
    @EnvironmentObject var fontManager: FontManager

    // 80x24 text mode with 8x16 font
    private let cols = 80
    private let rows = 24
    private let charW = 8
    private let charH = 16

    // Colors: MS-DOS like
    private let bgColor = Color(red: 0, green: 0, blue: 0.5)
    private let fgColor = Color.white

    var body: some View {
        Canvas { context, size in
            // Fill background
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(bgColor))

            guard document.totalLines > 0 else { return }

            // Compute visible window so that document.currentLine is centered
            let half = rows / 2
            let maxStart = max(0, document.totalLines - rows)
            let startLine = max(0, min(maxStart, document.currentLine - half))

            // Precompute cell size to fit exactly 640x384; if canvas is larger, center the content
            let idealSize = CGSize(width: CGFloat(cols * charW), height: CGFloat(rows * charH))
            let offsetX = (size.width - idealSize.width) / 2.0
            let offsetY = (size.height - idealSize.height) / 2.0

            // Draw characters
            for row in 0..<rows {
                let lineIndex = startLine + row
                if lineIndex >= 0 && lineIndex < document.content.count {
                    let line = document.content[lineIndex]
                    // Loop columns up to 80
                    var column = 0
                    for ch in line {
                        if column >= cols { break }
                        drawChar(ch, at: (column, row), in: context, origin: CGPoint(x: offsetX, y: offsetY))
                        column += 1
                    }
                    // Fill the rest with spaces
                    while column < cols {
                        drawChar(" ", at: (column, row), in: context, origin: CGPoint(x: offsetX, y: offsetY))
                        column += 1
                    }
                } else {
                    // Empty line
                    for col in 0..<cols {
                        drawChar(" ", at: (col, row), in: context, origin: CGPoint(x: offsetX, y: offsetY))
                    }
                }
            }
        }
        .frame(minWidth: CGFloat(cols * charW), minHeight: CGFloat(rows * charH))
        .accessibilityHidden(true) // no cursor or focus ring
    }

    private func drawChar(_ c: Character, at pos: (Int, Int), in context: GraphicsContext, origin: CGPoint) {
        guard let bitmap = fontManager.getCharacterBitmap(for: c), bitmap.count == (charW * charH) else { return }

        let (col, row) = pos
        let baseX = origin.x + CGFloat(col * charW)
        let baseY = origin.y + CGFloat(row * charH)

        // Draw as per-pixel rectangles without antialiasing
        for y in 0..<charH {
            for x in 0..<charW {
                if bitmap[y * charW + x] {
                    let rect = CGRect(x: baseX + CGFloat(x), y: baseY + CGFloat(y), width: 1, height: 1)
                    context.fill(Path(rect), with: .color(fgColor))
                }
            }
        }
    }
}
