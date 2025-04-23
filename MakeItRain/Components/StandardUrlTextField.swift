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
        HStack(alignment: .circleAndTitle) {
            if showSymbol {
                Image(systemName: "network")
                    .foregroundColor(.gray)
                    .frame(width: symbolWidth)
                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
            }
                     
            VStack(alignment: .leading) {
                HStack {
                    #if os(iOS)
                    StandardUITextField("URL", text: $url, onSubmit: {
                        focusedField.wrappedValue = nil
                    }, toolbar: {
                        KeyboardToolbarView(focusedField: focusedField.projectedValue)
                    })
                    .cbClearButtonMode(.whileEditing)
                    .cbFocused(focusedField, equals: focusID)
                    .cbAutoCorrectionDisabled(true)
                    .cbKeyboardType(.URL)
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
                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                                
                #if os(iOS)
                if let url = URL(string: url) {
                    LinkItemView(url: url)
                    
//                    LinkPreviewView(previewURL: url)
//                        .aspectRatio(contentMode: .fit)
                }
                #endif
                                                
            }
        }
        .padding(.bottom, 6)
    }
}
