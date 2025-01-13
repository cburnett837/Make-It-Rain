//
//  ColorPickerView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/9/24.
//

import SwiftUI

struct ColorPickerView<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var color: Color
    
    @ViewBuilder let content: Content
    
    var body: some View {
        Menu {
            ForEach(AppState.shared.colorMenuOptions.filter { $0 != .white && $0 != .black }, id: \.self) { color in
                Button {
                    self.color = color
                } label: {
                    HStack {
                        Text(color.description.capitalized)
                        Image(systemName: "circle.fill")
                            .foregroundStyle(color, .primary, .secondary)
                      }
                }
            }
        } label: {
            content
        }
    }
}

