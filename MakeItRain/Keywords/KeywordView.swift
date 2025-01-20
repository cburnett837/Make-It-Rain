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
    
    var header: some View {
        Group {
            SheetHeader(
                title: title,
                close: { editID = nil; dismiss() },
                view3: { deleteButton }
            )
            .padding()
            
            Divider()
                .padding(.horizontal)
        }
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            if !AppState.shared.isLandscape { header }
            #endif
            #if os(macOS)
            VStack(alignment: .center) {
                HStack {
                    Text("If the transaction title")
                    VStack(alignment: .leading) {
                        
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
                        .frame(width: 100)
                    }
                    TextField("Keyword", text: $keyword.keyword)
                        .frame(width: 120)
                        .focused($focusedField, equals: 0)
                
                    Text("give it a category of")
                    MenuOrListButton(title: keyword.category?.title, alternateTitle: "Select Category") {
                        showCategorySheet = true
                    }
                    
//                    Menu {
//                        ForEach(catModel.categories) { cat in
//                            Button {
//                                keyword.category = cat
//                            } label: {
//                                HStack {
//                                    if let emoji = cat.emoji {
//                                        Text("\(emoji) \(cat.title)")
//                                    } else {
//                                        Text(cat.title)
//                                    }
//                                    
//                                }
//                            }
//                        }
//                    } label: {
//                        Text(keyword.category.title)
//                    }
//                    .frame(width: 100)
                }
                .padding(.bottom)
            }
            .padding(.bottom, 20)
            #else
            ScrollView {
                if AppState.shared.isLandscape { header }
                VStack(alignment: .leading, spacing: 6) {
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
                            StandardUITextFieldFancy("Keyword", text: $keyword.keyword, toolbar: {
                                /// The blank text removes the up and down arrows.
                                KeyboardToolbarView(focusedField: $focusedField, accessoryText1: "", accessoryText2: "")
                            })
                            .cbClearButtonMode(.whileEditing)
                            .cbFocused(_focusedField, equals: 0)
                            #else
                            StandardTextField("Keyword", text: $keyword.keyword, keyboardType: .text, focusedField: $focusedField, focusValue: 0)
                            #endif
                        }
                    }
                    
                    GroupBox {
                        HStack(spacing: 0) {
                            Text("give it a category of ")
                            CategorySheetButton(category: $keyword.category)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }
            .scrollDismissesKeyboard(.immediately)
            
            #endif
        }
        .frame(minWidth: 200)
        .task {
            keyword.deepCopy(.create)
            keyModel.upsert(keyword)
            focusedField = 0
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
