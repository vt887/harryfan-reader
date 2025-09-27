//
//  TitleBar.swift
//  harryfan-reader
//
//  Created by Vad Tymoshyk on 9/1/25.
//

import SwiftUI

struct TitleBar: View {
    @ObservedObject var document: TextDocument
    
    var body: some View {
        HStack(alignment: .center) {
            Text(document.fileName.isEmpty ? "HarryFanReader" : document.fileName)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Colors.titleBarFontColor)
            
            Spacer()
            
            // Up/Down buttons and percent
            if !document.fileName.isEmpty {
                // Percent at top-right, based on center line index
                let percent = document.totalLines > 0 ? Int((Double(document.currentLine + 1) / Double(document.totalLines)) * 100.0) : 0
                Text("\(percent)%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Colors.foregroundColor)
                    .padding(.trailing, 8)
                
                Button(action: { document.currentLine = max(0, document.currentLine - 1) }) {
                    Image(systemName: "chevron.up")
                }
                .buttonStyle(.plain)
                .foregroundColor(Colors.foregroundColor)
                .help("Scroll Up")
                
                Button(action: { document.currentLine = min(max(0, document.totalLines - 1), document.currentLine + 1) }) {
                    Image(systemName: "chevron.down")
                }
                .buttonStyle(.plain)
                .foregroundColor(Colors.foregroundColor)
                .help("Scroll Down")
                
                Divider()
                    .frame(height: 14)
                    .background(Colors.foregroundColor)
                    .padding(.horizontal, 4)
                
                // Status info (center line number)
                Text("Line \(document.currentLine + 1) of \(document.totalLines)")
                    .font(.system(size: 12))
                    .foregroundColor(Colors.foregroundColor)
                
                Text("CP866")
                    .font(.system(size: 12))
                    .foregroundColor(Colors.foregroundColor)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Colors.foregroundColor)
    }
}
