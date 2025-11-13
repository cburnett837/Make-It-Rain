//
//  KeywordView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/21/24.
//

import SwiftUI

struct KeywordView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    
    @Bindable var keyword: CBKeyword
    /// This is only here to blank out the selection hilight on the iPhone list
    @Binding var editID: String?
    
    @FocusState private var focusedField: Int?
    @State private var showDeleteAlert = false
    @State private var showCategorySheet = false
        
    var title: String { keyword.action == .add ? "New Rule" : "Edit Rule" }
            
    var isValidToSave: Bool {
        if keyword.action == .add {
            return !keyword.keyword.isEmpty && keyword.category != nil && !(keyword.category?.isNil ?? false)
        } else {
            return (keyword.hasChanges() && !keyword.keyword.isEmpty)
        }
    }
    
    var body: some View {
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                titleSection
                categorySection
                
            }
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { deleteButton }
                ToolbarItem(placement: .topBarTrailing) {
                    AnimatedCloseButton(isValidToSave: isValidToSave, closeButton: closeButton)                    
                }
                
                ToolbarItem(placement: .bottomBar) {
                    EnteredByAndUpdatedByView(enteredBy: keyword.enteredBy, updatedBy: keyword.updatedBy, enteredDate: keyword.enteredDate, updatedDate: keyword.updatedDate)
                }
                .sharedBackgroundVisibility(.hidden)
            }
            #endif
        }
        
        .task {
            keyword.deepCopy(.create)
            keyModel.upsert(keyword)
            //focusedField = 0
        }
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
//                Image(systemName: keyword.category?.emoji ?? "questionmark.circle")
//                    .foregroundStyle(keyword.category?.color ?? .primary)
                CategorySheetButton2(category: $keyword.category)
            }
        } header: {
            Text("give it a category of…")
        }
    }
    
    
    var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Image(systemName: "trash")
        }
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
        .tint(.none)
        .confirmationDialog("Delete \"\(keyword.keyword)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive) {
                //Task {
                    keyword.action = .delete
                    dismiss()
                    //await keyModel.delete(keyword, andSubmit: true)
                //}
            }
            
            Button("No", role: .close) { showDeleteAlert = false }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(keyword.keyword)\"?")
            #endif
        })
    }
    
    var closeButton: some View {
        Button {
            if keyword.action == .add && !keyword.keyword.isEmpty && (keyword.category == nil || keyword.category?.isNil ?? false) {
                AppState.shared.showAlert("Please select a category")
                return
            }
            editID = nil
            dismiss()
        } label: {
            Image(systemName: isValidToSave ? "checkmark" : "xmark")
                .schemeBasedForegroundStyle()
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
