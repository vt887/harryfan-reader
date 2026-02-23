//
//  TitleBar.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/26/25.
//

import SwiftUI

// View for displaying the title bar in the app
struct TitleBar: View {
    // Observed document model for the title bar
    @ObservedObject var document: TextDocument

    // Main view body rendering the title bar
    var body: some View {
        ScreenView(document: document,
                   contentToDisplay: document.getTitleBarText(),
                   displayRows: 1,
                   rowOffset: 0,
                   backgroundColor: Colors.theme.titleBarBackground,
                   fontColor: Colors.theme.titleBarForeground,
                   overlayLayers: .constant([]),
                   overlayOpacities: .constant([:]))
    }
}
