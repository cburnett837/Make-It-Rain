//
//  TagView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/21/24.
//

import SwiftUI


struct TagView: View {
    @AppStorage("appColorTheme") var appColorTheme: String = Color.green.description
    @Environment(\.dismiss) var dismiss
    @Environment(CalendarModel.self) private var calModel
    //@Environment(TagModel.self) private var tagModel
    @Bindable var trans: CBTransaction
    
    @State private var searchText = ""
    @State private var newTag = ""
    
    @FocusState private var focusedField: Int?
    
    
    var filteredTags: Array<CBTag> {
        if searchText.isEmpty {
            return calModel.tags
        } else {
            return calModel.tags.filter { $0.tag.localizedStandardContains(searchText) }
        }
    }
    
    var header: some View {
        Group {
            SheetHeader(title: "Tags", close: { dismiss() })
                .padding(.bottom, 12)
                .padding(.horizontal)
                .padding(.top)
        }
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            if !AppState.shared.isLandscape { header }
            #else
            header
            #endif
            ScrollView {
                #if os(iOS)
                if AppState.shared.isLandscape { header }
                #endif
                StandardTextField("Search Tags", text: $searchText, isSearchField: true, focusedField: $focusedField, focusValue: 0)
                    //.focused($focusedField, equals: .search)
                    //.submitLabel(.search)
                
                Divider()
                
                
//                GroupBox {
//                    TextField("Search Tags", text: $searchText)
//                        .focused($focusedField, equals: .search)
//                        .submitLabel(.search)
//                        .textFieldStyle(.plain)
//                }
                
                
                
                if !calModel.tags.isEmpty {
                    GroupBox {
                        if filteredTags.isEmpty {
                            VStack {
                                Text("No Tags...")
                                    .frame(maxWidth: .infinity)
                                Button("Add") {
                                    newTag = searchText
                                    if !newTag.isEmpty {
                                        let newTag = CBTag(tag: newTag)
                                        addOrFind(tag: newTag)
                                    }
                                    focusedField = nil
                                    newTag = ""
                                    searchText = ""
                                }
                                .buttonStyle(.borderedProminent)
                                .focusable(false)
                            }
                            
                            
                        } else {
                            TagLayout(alignment: .leading, spacing: 10) {
                                ForEach(filteredTags) { tag in
                                    let exists = !trans.tags.filter { $0.id == tag.id }.isEmpty
                                    
                                    Button {
                                        addOrRemove(tag: tag)
                                    } label: {
                                        Text("#\(tag.tag)")
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(exists ? Color.fromName(appColorTheme) : .gray)
                                    .focusable(false)
                                }
                            }
                        }
                        
                    }
                }
                
                
                GroupBox {
                    TextField("Add New Tag...", text: $newTag)
                        .onSubmit {
                            if !newTag.isEmpty {
                                let newTag = CBTag(tag: newTag)
                                addOrFind(tag: newTag)
                            }
                            focusedField = nil
                            newTag = ""
                        }
                    
                        .onChange(of: newTag) { old, new in
                            newTag = new.replacingOccurrences(of: " ", with: "")
                        }
                        .focused($focusedField, equals: 0)
                        .submitLabel(.done)
                        .textFieldStyle(.plain)
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .padding(.horizontal, 15)
            //.navigationTitle("Tags")
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        if focusedField == 0 {
                            Button("Add") {
                                if !newTag.isEmpty {
                                    let newTag = CBTag(tag: newTag)
                                    addOrFind(tag: newTag)
                                }
                                //focusedField = nil
                                newTag = ""
                            }
                            .disabled(newTag.isEmpty)
                        }
                        
                        
                        Spacer()
                                                
                        Button {
                            focusedField = nil
                        } label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .foregroundStyle(.gray)
                        }
                    }
                    
                    //KeyboardToolbarView2(amountString: .constant(""), focusedField: _focusedField, fields: [.title])
                }
            }
        }
        
        
    }
    
    func addOrFind(tag: CBTag) {
        let existsInModel = !calModel.tags.filter { $0.tag == tag.tag }.isEmpty
        let existsInTrans = !trans.tags.filter { $0.tag == tag.tag }.isEmpty
        
        if !existsInModel { calModel.tags.append(tag) }
        if !existsInTrans { trans.tags.append(tag) }
    }
    
    func addOrRemove(tag: CBTag) {
        let exists = !trans.tags.filter { $0.id == tag.id }.isEmpty
        if exists {
            trans.tags.removeAll(where: { $0.id == tag.id })
        } else {
            trans.tags.append(tag)
        }
    }
}
