//
//  StandardUrlTextField.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/2/25.
//

import SwiftUI

struct StandardUrlTextField: View {
    @Binding var url: String
    var symbolWidth: CGFloat
    var focusedField: FocusState<Int?>
    var focusID: Int
    var showSymbol: Bool = true
    
    var body: some View {
        VStack {
            HStack {
                Label {
                    Text("URL")
                } icon: {
                    Image(systemName: "network")
                        .foregroundStyle(.gray)
                }

                HStack {
                    #if os(iOS)
                    
                    UITextFieldWrapper(placeholder: "https://www.google.com", text: $url, onSubmit: {
                        focusedField.wrappedValue = nil
                    }, toolbar: {
                        KeyboardToolbarView(focusedField: focusedField.projectedValue)
                    })
                    .uiTag(focusID)
                    .uiClearButtonMode(.whileEditing)
                    .uiStartCursorAtEnd(true)
                    .uiTextAlignment(.right)
                    .uiAutoCorrectionDisabled(true)
                    .uiKeyboardType(.URL)

    //                    StandardUITextField("URL", text: $url, onSubmit: {
    //                        focusedField.wrappedValue = nil
    //                    }, toolbar: {
    //                        KeyboardToolbarView(focusedField: focusedField.projectedValue)
    //                    })
    //                    .cbClearButtonMode(.whileEditing)
    //                    .cbFocused(focusedField, equals: focusID)
    //                    .cbAutoCorrectionDisabled(true)
    //                    .cbKeyboardType(.URL)
                    #else
                    StandardTextField("URL", text: $url, focusedField: focusedField.projectedValue, focusValue: focusID)
                        .autocorrectionDisabled(true)
                        .onSubmit { focusedField.wrappedValue = nil }
                    #endif
                    
                    #if os(macOS)
                    if let url = URL(string: url) {
                        Link(destination: url) {
                            Image(systemName: "safari")
                        }
                    }
                    #endif
                }
            }
            
            #if os(iOS)
            if let url = URL(string: url) {
                LinkItemView(url: url)
                    .padding(.top, 5)
                
            //                    LinkPreviewView(previewURL: url)
            //                        .aspectRatio(contentMode: .fit)
            }
            #endif
        }
        .padding(.bottom, 6)
    }
}
