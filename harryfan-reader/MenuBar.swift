//
//  MenuBar.swift
//  harryfan-reader
//
//  Created by Vad Tymoshyk on 9/25/25.
//

import SwiftUI

struct MenuBar: View {
    @ObservedObject var document: TextDocument
    @EnvironmentObject var fontManager: FontManager

    var body: some View {
        ScreenView(document: document,
                   contentToDisplay: document.getMenuBarText(),
                   displayRows: 1,
                   rowOffset: document.rows - 1,
                   backgroundColor: Colors.theme.menuBarBackground,
                   fontColor: Colors.theme.menuBarForeground)
    }
}
