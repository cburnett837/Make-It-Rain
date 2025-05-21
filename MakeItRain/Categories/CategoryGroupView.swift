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
        StandardContainer(.list) {
            titleTextField
            
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
        } header: {
            SheetHeader(title: title, close: { closeSheet() }, view3: { deleteButton })
        } subHeader: {
            SearchTextField(title: "Categories", searchText: $searchText, focusedField: $focusedField, focusState: _focusedField)
                .padding(.horizontal, -20)
                #if os(macOS)
                .focusable(false) /// prevent mac from auto focusing
                #endif
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        .task { prepareView() }
    }
    
    var titleTextField: some View {
        HStack {
            Text("Name")
            Spacer()
            #if os(iOS)
            UITextFieldWrapper(placeholder: "Name", text: $group.title, toolbar: {
                KeyboardToolbarView(focusedField: $focusedField)
            })
            .uiTextAlignment(layoutDirection == .leftToRight ? .right : .left)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTag(1)
            #else
            StandardTextField("Name", text: $group.title, focusedField: $focusedField, focusValue: 1)
                .onSubmit { focusedField = 2 }
            #endif
        }
        .focused($focusedField, equals: 1)
    }
    
    var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Image(systemName: "trash")
        }
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
    }
    
    func closeSheet() {
        editID = nil
        dismiss()
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
            print("doesn 't conain")
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
        focusedField = 1
        #else
        if group.action == .add {
            focusedField = 1
        }
        #endif
    }
}
