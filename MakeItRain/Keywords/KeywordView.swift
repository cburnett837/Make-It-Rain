//
//  KeywordView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/21/24.
//

import SwiftUI

struct KeywordView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var keyword: CBKeyword
    @Bindable var keyModel: KeywordModel
    @Bindable var catModel: CategoryModel
    
    /// This is only here to blank out the selection hilight on the iPhone list
    @Binding var editID: String?
    
    @FocusState private var focusedField: Int?
    @State private var showDeleteAlert = false
    @State private var showCategorySheet = false
        
    var title: String { keyword.action == .add ? "New Keyword" : "Edit Keyword" }
    
    var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Image(systemName: "trash")
        }
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
    }
    
//    var header: some View {
//        Group {
//            SheetHeader(
//                title: title,
//                close: { editID = nil; dismiss() },
//                view3: { deleteButton }
//            )
//            .padding()
//        }
//    }
    
    
    var body: some View {
        StandardContainer(.list) {
            titleSection
            categorySection
            
        } header: {
            SheetHeader(title: title, close: { editID = nil; dismiss() }, view3: { deleteButton })
        }
        .frame(minWidth: 200)
        .task {
            keyword.deepCopy(.create)
            keyModel.upsert(keyword)
            //focusedField = 0
        }
        
        .confirmationDialog("Delete \"\(keyword.keyword)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive) {
                Task {
                    dismiss()
                    await keyModel.delete(keyword, andSubmit: true)
                }
            }
            
            Button("No", role: .cancel) {
                showDeleteAlert = false
            }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(keyword.keyword)\"?")
            #endif
        })
        
        .sheet(isPresented: $showCategorySheet) {
            CategorySheet(category: $keyword.category)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        }
    }
    
    var titleRow: some View {
        GroupBox {
            HStack(spacing: 0) {
                Text("If the transaction title ")
                Menu {
                    Button {
                        keyword.triggerType = .equals
                    } label: {
                        Text("equals")
                    }
                    Button {
                        keyword.triggerType = .contains
                    } label: {
                        Text("contains")
                    }
                } label: {
                    HStack {
                        Text(keyword.triggerType.rawValue)
                        Spacer()
                    }
                }
            }
            
            Group {
                #if os(iOS)
                StandardUITextField("Keyword", text: $keyword.keyword, toolbar: {
                    /// The blank text removes the up and down arrows.
                    KeyboardToolbarView(focusedField: $focusedField, removeNavButtons: true)
                })
                .cbClearButtonMode(.whileEditing)
                .cbFocused(_focusedField, equals: 0)
                #else
                StandardTextField("Keyword", text: $keyword.keyword, focusedField: $focusedField, focusValue: 0)
                #endif
            }
        }
    }
    
    
    var titleSection: some View {
        Section {
            criteriaRow
            titleRow2
        } header: {
            Text("If the transaction title…")
        }
    }
    
    
    var titleRow2: some View {
        HStack {
            Text("Keyword")
            Spacer()
            Group {
                #if os(iOS)
                UITextFieldWrapper(placeholder: "Keyword", text: $keyword.keyword, toolbar: {
                    KeyboardToolbarView(focusedField: $focusedField)
                })
                .uiTag(0)
                .uiClearButtonMode(.whileEditing)
                .uiStartCursorAtEnd(true)
                .uiTextAlignment(.left)
                .uiTextAlignment(.right)
                .uiTextColor(.secondaryLabel)
                #else
                StandardTextField("Keyword", text: $keyword.keyword, focusedField: $focusedField, focusValue: 0)
                #endif
            }
            .focused($focusedField, equals: 0)
        }
        
    }
    
    
    var criteriaRow: some View {
        HStack {
            Text("Criteria")
            Spacer()
            Menu {
                Button {
                    keyword.triggerType = .equals
                } label: {
                    Text("equals")
                }
                Button {
                    keyword.triggerType = .contains
                } label: {
                    Text("contains")
                }
            } label: {
                Text(keyword.triggerType.rawValue)
            }
        }
    }
    
    
    var categoryMenu: some View {
        GroupBox {
            HStack(spacing: 0) {
                Text("give it a category of ")
                CategorySheetButton(category: $keyword.category)
            }
        }
    }
    
    var categorySection: some View {
        Section {
            HStack {
                Text("Category")
                Spacer()
                CategorySheetButton2(category: $keyword.category)
            }
        } header: {
            Text("give it a category of…")
        }
    }
    
    
    
//    func save() {
//        dismiss()
//        Task {
//            guard !keyword.keyword.isEmpty, !keyword.category.title.isEmpty else { return }
//            keyModel.upsert(keyword)
//            if keyword.hasChanges() {
//                print("HAS CHANGES")
//                await keyModel.submit(keyword)
//                
//            } else {
//                print("NO CHANGES")
//            }
//        }
//    }
}
