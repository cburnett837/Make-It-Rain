//
//  TagEditSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 8/27/26.
//


import SwiftUI

struct TagEditView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var tag: CBTag
    
    @FocusState var focusedField: Int?
    
    var isValidToSave: Bool {
        tag.deepCopy?.title != tag.title
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Title") {
                    titleRow
                }
            }
            .navigationTitle("Edit Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AnimatedCloseButton(isValidToSave: isValidToSave, closeButton: closeButton)
                }
            }
        }
        .task {
            tag.deepCopy(.create)
            focusedField = 0
        }
    }
    
    var titleRow: some View {
        HStack(spacing: 0) {
            Label {
                Text("")
            } icon: {
                Image(systemName: "t.circle")
                    .foregroundStyle(.gray)
            }
            #if os(iOS)
            
            UITextFieldWrapper(placeholder: "Title", text: $tag.title, onSubmit: {
                focusedField = 1
            }, toolbar: {
                KeyboardToolbarView(focusedField: $focusedField)
            })
            .uiTag(0)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.left)
            .uiReturnKeyType(.next)
            //.uiFont(UIFont.systemFont(ofSize: 24.0))
            //.uiTextColor(.secondaryLabel)
            
            #else
            LabeledContent("") {
                TextField("", text: $category.title, prompt: Text("Title")
                    .foregroundColor(.gray)
                    .font(.system(size: 14, weight: .light))
                )
            }
            .labelsHidden()
            #endif
        }
        .focused($focusedField, equals: 0)
    }
    
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: isValidToSave ? "checkmark" : "xmark")
                .schemeBasedForegroundStyle()
        }
    }
}
