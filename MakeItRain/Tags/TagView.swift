//
//  TagView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/21/24.
//

import SwiftUI


struct TagView: View {
    //@Local(\.colorTheme) var colorTheme
    //@Environment(\.dismiss) var dismiss
    //@Environment(\.colorScheme) var colorScheme

    @Environment(CalendarModel.self) private var calModel
    
    //@Environment(TagModel.self) private var tagModel
    @Bindable var trans: CBTransaction
    
    @State private var searchText = ""
    @State private var newTag = ""
    
    @FocusState private var focusedField: Int?
    @State private var isEditMode = false
    
    
    var gridTags: Array<CBTag> {
        var tags: [CBTag] = []
        var returnTags: [CBTag] = []
        let allTags = calModel.tags.sorted(by: { $0.tag < $1.tag })
        let transTags = trans.tags
        print(allTags)
        
        for each in allTags {
            print(each.tag)
            tags.append(each)
            if !each.isHidden {
                returnTags.append(each)
            }
        }
        
        for each in transTags {
            if !returnTags.contains(each) {
                returnTags.append(each)
            }
        }
        
        return returnTags
        
    }
    
    
    var allTags: Array<CBTag> {
        calModel.tags
            //.filter { !$0.isHidden }
            .filter { searchText.isEmpty ? true : $0.tag.localizedCaseInsensitiveContains(searchText) }
            .sorted(by: { $0.tag < $1.tag })
    }
    
//    var header: some View {
//        Group {
//            SheetHeader(title: "Tags", close: { dismiss() })
//                .padding(.bottom, 12)
//                .padding(.horizontal)
//                .padding(.top)
//        }
//    }
    
    
    var body: some View {
        //NavigationStack {
            StandardContainerWithToolbar(.list) {
                if isEditMode {
                    editList
                } else {
                    if !calModel.tags.isEmpty {
                        if gridTags.isEmpty {
                            VStack {
                                Text("No Tags…")
                                    .frame(maxWidth: .infinity)
                                addFirstTagButton
                            }
                        } else {
                            tagGrid
                        }
                    }
                    
                    Section {
                        newTagTextField
                        
                        if !newTag.isEmpty {
                            addNewTagButton
                        }
                    }
                }
                
            }
            .searchable(text: $searchText, prompt: Text("Search"))
            .navigationTitle("Tags")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { editButton }
//                if !isEditMode {
//                    ToolbarItem(placement: .topBarTrailing) { closeButton }
//                }
                
            }
            .onChange(of: newTag) { old, new in
                newTag = new.replacing(" ", with: "")
            }
            #endif
        //}
    }
    
    
    
    
    // MARK: - Subviews
    
    
    
    
    @ViewBuilder var editList: some View {
        @Bindable var calModel = calModel
        Section("Visible") {
            ForEach(allTags.filter { !$0.isHidden }) { tag in
                EditLine(tag: tag)
            }
        }
        
        Section("Hidden") {
            ForEach(allTags.filter { $0.isHidden }) { tag in
                EditLine(tag: tag)
            }
        }
    }
    
    
    private struct EditLine: View {
        @Environment(CalendarModel.self) private var calModel
        @Bindable var tag: CBTag
        
        @State private var showDeleteAlert = false
                
        var body: some View {
            HStack {
                TextField("Edit", text: $tag.tag)
                Button {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: tag.isHidden ? "eye" : "eye.slash")
                }
                .tint(tag.isHidden ? .green : .red)
                .buttonStyle(.borderedProminent)
            }
            .alert("\(tag.isHidden ? "Unhide" : "Hide") #\(tag.tag)", isPresented: $showDeleteAlert, actions: {
                Button("Yes", role: .destructive) {
                    withAnimation {
                        calModel.tags.filter({ $0.id == tag.id }).first?.isHidden.toggle()
                    }
                    Task {
                        await calModel.submit(tag)
                    }
                }
            }, message: {
                Text("This will not affect any transactions associated with this tag.")
            })
        }
    }
    
    
    
    
    var newTagTextField: some View {
        Group {
            #if os(iOS)
            UITextFieldWrapper(placeholder: "Add New Tag…", text: $newTag, onSubmit: { onSubmit() }, toolbar: {
                KeyboardToolbarView(
                    focusedField: $focusedField,
                    removeNavButtons: true
//                                accessoryText1: "Add",
//                                accessoryFunc1: {
//                                    if !newTag.isEmpty {
//                                        let newTag = CBTag(tag: newTag)
//                                        addOrFind(tag: newTag)
//                                    }
//                                    //focusedField = nil
//                                    newTag = ""
//                                }
                )
            })
            .uiTag(0)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiReturnKeyType(.done)
            #else
            TextField("Add New Tag…", text: $newTag)
                .textFieldStyle(.plain)
                .onSubmit {
                    onSubmit()
                }
            #endif
        }
        .focused($focusedField, equals: 0)
        
    }
    
    
    var tagGrid: some View {
        TagLayout(alignment: .leading, spacing: 10) {
            ForEach(gridTags) { tag in
                let exists = !trans.tags.filter { $0.id == tag.id }.isEmpty
                
                Button {
                    addOrRemove(tag: tag)
                } label: {
                    Text("#\(tag.tag)")
                }
                .buttonStyle(.borderedProminent)
                .tint(exists ? Color.theme : .gray)
                .focusable(false)
            }
        }
    }
    
    var addFirstTagButton: some View {
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
    
    var addNewTagButton: some View {
        Button("Add") {
            let newTag = CBTag(tag: newTag)
            addOrFind(tag: newTag)
            self.newTag = ""
        }
    }
    
    var editButton: some View {
        Button {
            withAnimation {
                isEditMode.toggle()
            }
            
        } label: {
            Text(isEditMode ? "Done" : "Edit")
                .schemeBasedForegroundStyle()
        }
    }
    
    
//    var closeButton: some View {
//        Button {
//            dismiss()
//        } label: {
//            Image(systemName: "xmark")
//                .schemeBasedForegroundStyle()
//        }
//    }
    
    
    
    // MARK: - Funcs
    func onSubmit() {
        if !newTag.isEmpty {
            let newTag = CBTag(tag: newTag)
            addOrFind(tag: newTag)
        }
        focusedField = nil
        newTag = ""
    }
    
    func addOrFind(tag: CBTag) {
        withAnimation {
            if let modelTag = calModel.tags.filter({ $0.tag == tag.tag }).first {
                modelTag.isHidden = false
            } else {
                calModel.tags.append(tag)
            }
            
            if let transTag = trans.tags.filter({ $0.tag == tag.tag }).first {
                transTag.isHidden = false
            } else {
                trans.tags.append(tag)
            }
        }
        
        
        
//        let existsInModel = !calModel.tags.filter { $0.tag == tag.tag }.isEmpty
//        let existsInTrans = !trans.tags.filter { $0.tag == tag.tag }.isEmpty
//        
//        if !existsInModel { calModel.tags.append(tag) }
//        if !existsInTrans { trans.tags.append(tag) }
    }
    
    func addOrRemove(tag: CBTag) {
        withAnimation {
            let exists = !trans.tags.filter { $0.id == tag.id }.isEmpty
            if exists {
                trans.tags.removeAll(where: { $0.id == tag.id })
            } else {
                trans.tags.append(tag)
            }
        }
    }
}
