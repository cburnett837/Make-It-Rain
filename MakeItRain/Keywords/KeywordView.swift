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
    @State private var showCategorySection = false
    @State private var showRenameSection = false

        
    var title: String { keyword.action == .add ? "New Rule" : "Edit Rule" }
            
    var isValidToSave: Bool {
        if keyword.action == .add {
            return !keyword.keyword.isEmpty && (keyword.category != nil || keyword.renameTo != nil) && !(keyword.category?.isNil ?? false)
        } else {
            return (keyword.hasChanges() && !keyword.keyword.isEmpty)
        }
    }
    
    var body: some View {
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                titleRow2
                categorySection
                renameSection
                
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
            
            if keyword.category != nil {
                showCategorySection = true
            }
            
            if keyword.renameTo != nil {
                showRenameSection = true
            }
            
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
    
    
    var criteriaRow: some View {
        Section("If the transaction title…") {
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
    
    
    var titleRow2: some View {
        Section {
            Group {
                #if os(iOS)
                UITextFieldWrapper(placeholder: "Keyword", text: $keyword.keyword, toolbar: {
                    KeyboardToolbarView(focusedField: $focusedField)
                })
                .uiTag(0)
                .uiClearButtonMode(.whileEditing)
                .uiStartCursorAtEnd(true)
                .uiTextAlignment(.left)
                //.uiTextColor(.secondaryLabel)
                #else
                StandardTextField("Keyword", text: $keyword.keyword, focusedField: $focusedField, focusValue: 0)
                #endif
            }
            .focused($focusedField, equals: 0)
        } header: {
            titleSectionHeader
        }
    }
    
    
    var titleSectionHeader: some View {
        HStack(spacing: 0) {
            Text("If the transaction title ")
            Menu {
                Button("is") { keyword.triggerType = .equals }
                Button("contains") { keyword.triggerType = .contains }
            } label: {
                switch keyword.triggerType {
                case .equals:
                    Text("is")
                case .contains:
                    Text("contains")
                }
            }
            Text("…")
        }
    }
    
    
    @ViewBuilder
    var categorySection: some View {
        if showCategorySection {
            Section {
                HStack {
                    #if os(iOS)
                    CategorySheetButtonWithNoSymbol(category: $keyword.category, alignment: .leading)
                    #endif
                    Spacer()
                    removeCategoryConditionButton
                }
            } header: {
                Text("give it a category of…")
            }
        } else {
            Button("Add Category") {
                withAnimation {
                    showCategorySection = true
                }
            }
        }
    }
    
    
    var removeCategoryConditionButton: some View {
        Button {
            withAnimation {
                keyword.category = nil
                showCategorySection = false
            }
        } label: {
            Image(systemName: "xmark")
        }
        .clipShape(.circle)
        .tint(.gray)
        .buttonStyle(.borderedProminent)
    }
    
    
    @ViewBuilder
    var renameSection: some View {
        if showRenameSection {
            Section {
                HStack {
                    renameTextfield
                    Spacer()
                    removeRenameConditionButton
                }
            } header: {
                Text(showCategorySection ? "and rename it to…" : "rename it to…")
            } footer: {
                Text("When accepting a transaction from Plaid, choose to rename it to something more friendly.")
            }
        } else {
            Button("Add Rename") {
                withAnimation {
                    showRenameSection = true
                }
            }
        }
    }
    
    
    var renameTextfield: some View {
        Group {
            #if os(iOS)
            UITextFieldWrapper(placeholder: "Friendly title", text: $keyword.renameTo ?? "", toolbar: {
                KeyboardToolbarView(focusedField: $focusedField)
            })
            .uiTag(1)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.left)
            //.uiTextColor(.secondaryLabel)
            #else
            StandardTextField("Friendly title", text: $keyword.keyword, focusedField: $focusedField, focusValue: 0)
            #endif
        }
        .focused($focusedField, equals: 0)
    }
    
    
    var removeRenameConditionButton: some View {
        Button {
            withAnimation {
                keyword.renameTo = nil
                showRenameSection = false
            }
        } label: {
            Image(systemName: "xmark")
        }
        .clipShape(.circle)
        .tint(.gray)
        .buttonStyle(.borderedProminent)
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
            #if os(iOS)
            Button("No", role: .close) { showDeleteAlert = false }
            #else
            Button("No") { showDeleteAlert = false }
            #endif
        }, message: {
            #if os(iOS)
            Text("Delete \"\(keyword.keyword)\"?")
            #endif
        })
    }
    
    
    var closeButton: some View {
        Button {
            if keyword.action == .add && !keyword.keyword.isEmpty && ((keyword.category == nil && keyword.renameTo == nil) || keyword.category?.isNil ?? false) {
                AppState.shared.showAlert("Please add a condition")
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
