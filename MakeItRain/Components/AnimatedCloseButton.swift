//
//  AnimatedCloseButton.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/6/25.
//

import SwiftUI

struct AnimatedCloseButton<CloseButton: View>: View {
    var isValidToSave: Bool
    var color: Color?
    var closeButton: CloseButton
    
    init(isValidToSave: Bool, color: Color? = nil, closeButton: CloseButton) {
        self.isValidToSave = isValidToSave
        self.color = color == .primary ? Color.theme : color ?? Color.theme
        self.closeButton = closeButton
    }
        
    var body: some View {
        ZStack {
            if isValidToSave {
                closeButton
                    #if os(iOS)
                    .tint(color == .primary ? Color.theme : color)
                    .buttonStyle(.glassProminent)
                    #endif
                    .transition(.scale.combined(with: .opacity))
                    #if os(macOS)
                    .buttonStyle(.roundMacButton)
                    #endif
            } else {
                closeButton
                    .transition(.scale.combined(with: .opacity))
                    #if os(macOS)
                    .buttonStyle(.roundMacButton)
                    #endif
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isValidToSave)
    }
}
