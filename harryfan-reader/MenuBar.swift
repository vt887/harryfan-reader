//
//  MenuBar.swift
//  harryfan-reader
//
//  Created by Vad Tymoshyk on 9/1/25.
//

import SwiftUI

struct MenuBar: View {
    @ObservedObject var document: TextDocument
    @EnvironmentObject var fontManager: FontManager

    var body: some View {
        ScreenView(document: document,
                   contentToDisplay: document.getMenuBarText(),
                   displayRows: 1,
                   rowOffset: document.numScreenRows - 1,
                   backgroundColor: Colors.menuBarColor,
                   fontColor: Colors.menuBarFontColor)
    }
}
