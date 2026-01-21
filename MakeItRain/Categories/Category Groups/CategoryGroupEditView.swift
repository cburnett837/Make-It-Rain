//
//  CategoryGroupView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/25/25.
//

import SwiftUI

struct CategoryGroupEditView: View {
    @Environment(\.layoutDirection) private var layoutDirection: LayoutDirection
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    //@Local(\.colorTheme) var colorTheme

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
        return group.categories
            .filter { $0.active && categoryIds.contains($0.id) && $0.appSuiteKey == nil }
            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
            .sorted(by: Helpers.categorySorter())
    }
    
    var filteredAvailableCategories: Array<CBCategory> {
        return catModel.categories
            .filter { $0.active }
            .filter { !categoryIds.contains($0.id) && $0.appSuiteKey == nil }
            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
            .sorted(by: Helpers.categorySorter())
    }
    
    var isValidToSave: Bool {
        if group.title.isEmpty { return false }
        if !group.hasChanges() { return false }
        return true
    }
    
    var body: some View {
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                Section("Title & Budget") {
                    titleRow
                    budgetRow
                }
                
                if !filteredSelectedCategories.isEmpty {
                    Section("Selected Categories") {
                        ForEach(filteredSelectedCategories) { cat in
                            multiCategoryPickerLineItem(cat: cat)
                        }
                    }
                }
                                
                Section("Available Categories") {
                    ForEach(filteredAvailableCategories) { cat in
                        multiCategoryPickerLineItem(cat: cat)
                    }
                }
            }
            .searchable(text: $searchText, prompt: Text("Search"))
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) { deleteButton }                
                ToolbarItem(placement: .topBarTrailing) {
                    if isValidToSave {
                        closeButton
                            #if os(iOS)
                            .tint(Color.theme)
                            .buttonStyle(.glassProminent)
                            #endif
                    } else {
                        closeButton
                    }
                }
                #endif
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
    
    var budgetRow: some View {
        #if os(iOS)
        HStack(spacing: 0) {
            Label {
                Text("")
            } icon: {
                Image(systemName: "chart.pie")
                    .foregroundStyle(.gray)
            }
            
            UITextFieldWrapper(placeholder: "Monthly Amount", text: $group.amountString ?? "", toolbar: {
                KeyboardToolbarView(focusedField: $focusedField, accessoryImage3: "plus.forwardslash.minus", accessoryFunc3: {
                    Helpers.plusMinus($group.amountString ?? "")
                })
            })
            .uiTag(1)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.left)
            //.uiReturnKeyType(.next)
            //.uiKeyboardType(.decimalPad)
            .uiKeyboardType(.custom(.numpad))
            //.uiTextColor(.secondaryLabel)
        }
        .focused($focusedField, equals: 1)
        
        #else
        LabeledRow("Budget", labelWidth) {
            StandardTextField("Monthly Amount", text: $category.amountString ?? "", focusedField: $focusedField, focusValue: 1)
        }
        #endif
    }
    
//    var deleteButton: some View {
//        Button {
//            showDeleteAlert = true
//        } label: {
//            Image(systemName: "trash")
//                .schemeBasedForegroundStyle()
//        }
//        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
//    }
    
    
    var closeButton: some View {
        Button {
            editID = nil; dismiss()
        } label: {
            Image(systemName: isValidToSave ? "checkmark" : "xmark")
                .schemeBasedForegroundStyle()
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
        .confirmationDialog("Delete \"\(group.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Delete", role: .destructive) { deleteGroup() }
            //Button("No", role: .close) { showDeleteAlert = false }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(group.title)\"?\nThis will not delete any associated transactions.")
            #else
            Text("This will not delete any associated transactions.")
            #endif
        })
    }
    
    
    @ViewBuilder
    func multiCategoryPickerLineItem(cat: CBCategory) -> some View {
        StandardCategoryLabel(
            cat: cat,
            labelWidth: labelWidth,
            showCheckmarkCondition: group.categories.filter{ $0.active }.contains(cat)
        )
        .onTapGesture {
            withAnimation { doit(cat) }
        }
    }
    
    
    func deleteGroup() {
        //Task {
            group.action = .delete
            dismiss()
            //await catModel.delete(category, andSubmit: true, calModel: calModel, keyModel: keyModel, eventModel: eventModel)
        //}
    }
    
    
    func doit(_ category: CBCategory) {
        print("-- \(#function)")
        if categoryIds.contains(category.id) {
            print("contains")
            //group.categories.removeAll(where: { $0.id == category.id })
            if let index = group.categories.firstIndex(where: { $0.id == category.id }) {
                if group.action == .add {
                    group.categories.remove(at: index)
                } else {
                    print("Setting \(group.categories[index].title) to inactive")
                    group.categories[index].active = false
                }
                
            }
        } else {
            print("doesn't contain")
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
