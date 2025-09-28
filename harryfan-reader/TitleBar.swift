//
//  TitleBar.swift
//  harryfan-reader
//
//  Created by Vad Tymoshyk on 9/26/25.
//

import SwiftUI

struct TitleBar: View {
    @ObservedObject var document: TextDocument

    var body: some View {
        ScreenView(document: document,
                   contentToDisplay: document.getTitleBarText(),
                   displayRows: 1,
                   rowOffset: 0,
                   backgroundColor: Colors.theme.titleBarBackground,
                   fontColor: Colors.theme.titleBarForeground)
    }
}
