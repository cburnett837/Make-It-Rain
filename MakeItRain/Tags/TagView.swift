//
//  TagView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/21/24.
//

import SwiftUI


struct TagView: View {
    @Environment(AppStore.self) private var store
    @Environment(CalendarModel.self) private var calModel
    @Environment(TagModel.self) private var tagModel
        
    @Binding var tags: [CBTag]
    var tagLimit: Int?
    
    @State private var searchText = ""
    @State private var newTag = ""
    
    @FocusState private var focusedField: Int?
    @State private var isEditMode = false
    @State private var tagEditID: String?
    @State private var editTag: CBTag?
    
    
    var gridTags: Array<CBTag> {
        var returnTags: [CBTag] = []
        let allTags = tagModel.tags.sorted(by: { $0.title < $1.title })
        
        for each in allTags {
            if !each.isHidden {
                returnTags.append(each)
            }
        }
        
        for each in tags {
            if !returnTags.map({$0.id}).contains(each.id) {
                returnTags.append(each)
            }
        }
        
        return returnTags
    }
    
    
    var allTags: Array<CBTag> {
        tagModel.tags
            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
            .sorted(by: { $0.title < $1.title })
    }
    
    
    
    var body: some View {
        StandardContainerWithToolbar(.list) {
            if isEditMode {
                editList
            } else {
                if !tagModel.tags.isEmpty {
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
        }
        .onChange(of: newTag) { old, new in
            newTag = new.replacing(" ", with: "")
        }
        .onChange(of: tagEditID) { oldId, newId in
            if let newId {
                editTag = store.tags.first(where: { $0.id == newId })
                
            } else if let oldId, let tag = store.tags.first(where: { $0.id == oldId }) {
                Task {
                    tagModel.updateParents(store: store, tag: tag)
                    await tagModel.submit(tag)
                }
            }
        }
        .sheet(item: $editTag, onDismiss: {
            tagEditID = nil
        }) { tag in
            TagEditView(tag: tag)
        }
        #endif
    }
    
    
    
    
    // MARK: - Subviews
    @ViewBuilder
    var editList: some View {
        @Bindable var calModel = calModel
        Section("Visible") {
            ForEach(allTags.filter { !$0.isHidden }) { tag in
                EditLine(tag: tag, tagEditID: $tagEditID)
            }
        }
        
        Section("Hidden") {
            ForEach(allTags.filter { $0.isHidden }) { tag in
                EditLine(tag: tag, tagEditID: $tagEditID)
            }
        }
    }
    
    
    private struct EditLine: View {
        @Environment(CalendarModel.self) private var calModel
        @Environment(TagModel.self) private var tagModel
        var tag: CBTag
        @Binding var tagEditID: String?
        
        @State private var showDeleteAlert = false
                
        var body: some View {
            HStack {
                Text(tag.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
                    .onTapGesture {
                        tagEditID = tag.id
                    }
                
                Button {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: tag.isHidden ? "eye" : "eye.slash")
                }
                .tint(tag.isHidden ? .green : .red)
                .buttonStyle(.borderedProminent)
            }
            .alert("\(tag.isHidden ? "Unhide" : "Hide") #\(tag.title)", isPresented: $showDeleteAlert, actions: {
                Button("Yes", role: .destructive) {
                    withAnimation {
                        tagModel.tags.filter({ $0.id == tag.id }).first?.isHidden.toggle()
                    }
                    Task {
                        await tagModel.submit(tag)
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
                let exists = !tags.filter({ $0.id == tag.id }).isEmpty
                
                Button {
                    addOrRemove(tag: tag)
                } label: {
                    Text("#\(tag.title)")
                        .schemeBasedForegroundStyle()
                    
                }
                
                .buttonStyle(.borderedProminent)
                .tint(exists ? Color.theme : Color(.tertiarySystemFill))
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
            if let modelTag = tagModel.tags.filter({ $0.title == tag.title }).first {
                modelTag.isHidden = false
            } else {
                tagModel.tags.append(tag)
            }
            
            if let transTag = tags.filter({ $0.title == tag.title }).first {
                transTag.isHidden = false
            } else {
                tags.append(tag)
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
            let exists = !tags.filter { $0.id == tag.id }.isEmpty
            if exists {
                tags.removeAll(where: { $0.id == tag.id })
            } else {
                if let limit = tagLimit {
                    tags.appendWithLimit(tag, limit: limit)
                } else {
                    tags.append(tag)
                }
            }
        }
    }
}




