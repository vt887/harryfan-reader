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
        ScreenView(document: document,
                   contentToDisplay: document.fileName.isEmpty ? "HarryFanReader" : document.fileName,
                   displayRows: 1,
                   rowOffset: 0,
                   backgroundColor: Colors.titleBarColor,
                   fontColor: Colors.black)
    }
}
