//
//  CategoryGroupView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/25/25.
//

import SwiftUI

struct CategoryGroupView: View {
    @AppStorage("categorySortMode") var categorySortMode: CategorySortMode = .title
    @Environment(\.layoutDirection) private var layoutDirection: LayoutDirection
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(CategoryModel.self) private var catModel
    
    @Bindable var group: CBCategoryGroup
    @Binding var editID: String?

    @State private var searchText = ""
    @State private var showDeleteAlert = false
    @State private var labelWidth: CGFloat = 20.0
    @FocusState private var focusedField: Int?
    
    var title: String { group.action == .add ? "New Category Group" : "Edit Category Group" }
    
    var categoryIds: [String] {
        group.categories
            .filter { $0.active }
            .compactMap(\.id)
    }
    
    var filteredSelectedCategories: Array<CBCategory> {
        if searchText.isEmpty {
            return group.categories
                .filter { $0.active && categoryIds.contains($0.id) }
                .sorted {
                    categorySortMode == .title
                    ? $0.title.lowercased() < $1.title.lowercased()
                    : $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000
                }
        } else {
            return group.categories
                .filter { $0.active && categoryIds.contains($0.id) }
                .filter { $0.title.localizedStandardContains(searchText) }
                .sorted {
                    categorySortMode == .title
                    ? $0.title.lowercased() < $1.title.lowercased()
                    : $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000
                }
        }
    }
    
    var filteredAvailableCategories: Array<CBCategory> {
        if searchText.isEmpty {
            return catModel.categories
                .filter { !categoryIds.contains($0.id) }
                .sorted {
                    categorySortMode == .title
                    ? $0.title.lowercased() < $1.title.lowercased()
                    : $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000
                }
        } else {
            return catModel.categories
                .filter { !categoryIds.contains($0.id) }
                .filter { $0.title.localizedStandardContains(searchText) }
                .sorted {
                    categorySortMode == .title
                    ? $0.title.lowercased() < $1.title.lowercased()
                    : $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000
                }
        }
    }
    
    var body: some View {
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                Section("Title") {
                    titleRow
                }
                
                if !filteredSelectedCategories.isEmpty {
                    Section("Selected Categories") {
                        ForEach(filteredSelectedCategories) { cat in
                            MultiCategoryPickerLineItem(cat: cat, categories: $group.categories, labelWidth: labelWidth, selectFunction: { doit(cat) })
                        }
                    }
                }
                
                
                Section("Available Categories") {
                    ForEach(filteredAvailableCategories) { cat in
                        MultiCategoryPickerLineItem(cat: cat, categories: $group.categories, labelWidth: labelWidth, selectFunction: { doit(cat) })
                    }
                }
            }
            .searchable(text: $searchText, prompt: Text("Search"))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                //ToolbarItem(placement: .topBarLeading) { deleteButton }
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
        }
        
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        .task { prepareView() }
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
            UITextFieldWrapper(placeholder: "Name", text: $group.title, toolbar: {
                KeyboardToolbarView(focusedField: $focusedField)
            })
            //.uiTextAlignment(layoutDirection == .leftToRight ? .right : .left)
            .uiTextAlignment(.left)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTag(0)
            #else
            StandardTextField("Name", text: $group.title, focusedField: $focusedField, focusValue: 0)
                .onSubmit { focusedField = 1 }
            #endif
        }
        .focused($focusedField, equals: 0)
    }
    
//    var deleteButton: some View {
//        Button {
//            showDeleteAlert = true
//        } label: {
//            Image(systemName: "trash")
//                .foregroundStyle(colorScheme == .dark ? .white : .black)
//        }
//        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
//    }
    
    
    var closeButton: some View {
        Button {
            editID = nil; dismiss()
        } label: {
            Image(systemName: "checkmark")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }
    
    
    func doit(_ category: CBCategory) {
        print("-- \(#function)")
        if categoryIds.contains(category.id) {
            print("contains")
            //group.categories.removeAll(where: { $0.id == category.id })
            if let index = group.categories.firstIndex(where: {$0.id == category.id}) {
                group.categories[index].active = false
            }
        } else {
            print("doesn't conain")
            if let index = group.categories.firstIndex(where: {$0.id == category.id}) {
                group.categories[index].active = true
            } else {
                group.categories.append(category)
            }
            
        }
    }
    
    func prepareView() {
        group.deepCopy(.create)
        catModel.upsert(group)
        
        #if os(macOS)
        /// Focus on the title textfield.
        focusedField = 0
        #else
        if group.action == .add {
            focusedField = 0
        }
        #endif
    }
}
