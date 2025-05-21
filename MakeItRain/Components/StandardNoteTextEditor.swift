//
//  StandardNoteTextEditor.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/2/25.
//

import SwiftUI

struct StandardNoteTextEditor: View {
    @Binding var notes: String
    var symbolWidth: CGFloat
    var focusedField: FocusState<Int?>
    var focusID: Int
    var showSymbol: Bool = true
    
    var body: some View {
        HStack(alignment: .top) {
            if showSymbol {
                Image(systemName: "note.text")
                    .foregroundColor(.gray)
                    .frame(width: symbolWidth)
            }
            
            TextEditor(text: $notes)
                .writingToolsBehavior(.complete)
                .foregroundStyle(notes.isEmpty ? .gray : .primary)
                .scrollContentBackground(.hidden)
                .background(.clear)
                .frame(minHeight: 100)
                .focused(focusedField.projectedValue, equals: focusID)
                #if os(iOS)
                .offset(y: -10)
                #else
                .offset(y: 1)
                #endif
                .overlay {
                    Text("Notes…")
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .opacity(!notes.isEmpty || focusedField.wrappedValue == focusID ? 0 : 1)
                        .allowsHitTesting(false)
                        #if os(iOS)
                        .padding(.top, -2)
                        #else
                        .offset(y: -1)
                        #endif
                        .padding(.leading, 0)
                }
        }
    }
}

