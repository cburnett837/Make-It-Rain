//
//  LabeledRow.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/23/24.
//

import Foundation
import SwiftUI

struct LabeledRow<Content: View>: View {
    let text: String
    var labelWidth: CGFloat
    @ViewBuilder let content: Content
    
    init(_ text: String, _ labelWidth: CGFloat, @ViewBuilder content: () -> Content) {
        self.text = text
        self.labelWidth = labelWidth
        self.content = content()
    }
    
    var body: some View {
        HStack {
            Text(text)
                .frame(minWidth: labelWidth, alignment: .leading)
            
                /// This is the same as using `.maxLabelWidthObserver()`. But I did it this way to I could understand better when looking at this.
                .background {
                    GeometryReader { geo in
                        Color.clear.preference(key: MaxSizePreferenceKey.self, value: geo.size.width)
                    }
                }
            
            content
        }
    }
            
//    private func background(geometry: GeometryProxy) -> some View {
//        Color.clear.preference(key: LabelWidthPreferenceKey.self, value: geometry.size.width)
//    }
    
    
}


/// Alternative way, but required to be local in the view.
// func labeledRow<Content: View>(_ text: String, @ViewBuilder content: () -> Content) -> some View {
//     HStack {
//         Text(text)
//             .frame(minWidth: labelWidth, alignment: .leading)
//             .maxLabelWidthObserver()
//         content()
//     }
// }
