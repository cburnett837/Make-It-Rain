//
//  StandardRectangle.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/11/25.
//

import SwiftUI

struct StandardRectangle<Content: View>: View {
    var fill: Color = Color(.tertiarySystemFill)
    var withTrailingPadding: Bool = true
    @ViewBuilder let content: Content
    
    let minHeightMac: CGFloat = 27
    let minHeightPhone: CGFloat = 34
    
    var body: some View {
        /// Add padding to the content at the call site to make the box expand with it
        content
            #if os(macOS)
            .frame(minHeight: minHeightMac)
            #else
            .frame(minHeight: minHeightPhone)
            #endif
            .padding(.leading, 6)
            .padding(.trailing, withTrailingPadding ? 6 : 0)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    //.stroke(.gray, lineWidth: 1)
                    .fill(fill)
                    #if os(macOS)
                    .frame(minHeight: minHeightMac)
                    #else
                    .frame(minHeight: minHeightPhone)
                    #endif
            }
        
        
        
//            .overlay {
//                content
//                    .padding(.horizontal, 6)
//            }
    }
}
