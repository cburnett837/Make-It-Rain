//
//  ColorPickerButton.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/9/24.
//

import SwiftUI

struct ColorPickerButton: View {
    @State private var showSheet = false
    @State private var menuColor: Color = Color(.tertiarySystemFill)
    @Binding var color: Color
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(menuColor)
            #if os(macOS)
            .frame(height: 27)
            #else
            .frame(height: 34)
            #endif
            .overlay {
                ColorPickerView(color: $color) {
                    //MenuOrListButton(title: color.description, alternateTitle: "Select Color") { }
                    
                    
                    
                    HStack {
                        Text(color.description.capitalized)
                            .foregroundStyle(color)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .padding(.leading, 4)
                    .focusable(false)
                    .chevronMenuOverlay()
                    
                }
            }
            .onHover { menuColor = $0 ? Color(.systemFill) : Color(.tertiarySystemFill) }
    }
}

