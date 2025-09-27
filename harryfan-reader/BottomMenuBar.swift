//
//  BottomMenuBar.swift
//  harryfan-reader
//
//  Created by Vad Tymoshyk on 9/1/25.
//

import SwiftUI

struct BottomMenuBar: View {
    @ObservedObject var document: TextDocument
    @EnvironmentObject var fontManager: FontManager

    var body: some View {
        ScreenView(document: document, contentToDisplay: document.getMenuBarText())
            .environmentObject(fontManager)
            .frame(maxWidth: .infinity, maxHeight: 16, alignment: .center)
            .background(Colors.textColor)
    }
}
