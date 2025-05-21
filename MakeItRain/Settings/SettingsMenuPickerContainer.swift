//
//  SettingsMenuPickerContainer.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/21/25.
//


import SwiftUI

struct SettingsMenuPickerContainer<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    @Local(\.colorTheme) var colorTheme
    
    var title: String
    var selectedTitle: String
    @ViewBuilder var picker: Content
    
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(colorScheme == .dark ? .white : .black)
            
            Spacer()
            
            Menu {
                /// Using a picker so we get the checkmark on the selected item.
                picker
                .labelsHidden()
                .pickerStyle(.inline)
                
            } label: {
                HStack(spacing: 4) {
                    Text(selectedTitle.capitalized)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.footnote)
                }
                .foregroundStyle(Color.fromName(colorTheme))
            }
        }
    }
}

