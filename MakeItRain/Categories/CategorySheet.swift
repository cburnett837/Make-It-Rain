//
//  CategorySheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/21/24.
//

import SwiftUI

struct CategorySheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(CalendarModel.self) private var calModel    
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    
    @State private var editCategory: CBCategory?
    @State private var categoryEditID: CBCategory.ID?
    @State private var labelWidth: CGFloat = 20.0
    
    @Binding var category: CBCategory?
    var trans: CBTransaction? = nil
    var saveOnChange: Bool = false
    //var includeHidden: Bool = false

        
//    init(category: Binding<CBCategory?>) {
//        self._category = category
//        self.trans = nil
//        self.saveOnChange = false
//    }
//    
//    init(category: Binding<CBCategory?>, trans: CBTransaction?, saveOnChange: Bool) {
//        self._category = category
//        self.trans = trans
//        self.saveOnChange = saveOnChange
//    }
//    
    @FocusState private var focusedField: Int?
    @State private var searchText = ""
    
    var filteredCategories: Array<CBCategory> {
        catModel.categories
            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
            .filter { !$0.isHidden && $0.appSuiteKey == nil }
            .filter { !$0.isNil }
            .sorted(by: Helpers.categorySorter())
    }
    
    var filteredHiddenCategories: Array<CBCategory> {
        catModel.categories
            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
            .filter { $0.isHidden && $0.appSuiteKey == nil }
            .filter { !$0.isNil }
            .sorted(by: Helpers.categorySorter())
    }
    
    var filteredSpecialCategories: Array<CBCategory> {
        catModel.categories
            .filter { !$0.isNil }
            .filter { !$0.isHidden && $0.appSuiteKey != nil }
            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
            .sorted(by: Helpers.categorySorter())
    }
    
    var showMyCategories: Bool {
        (!searchText.isEmpty && !filteredCategories.isEmpty) || searchText.isEmpty
    }
    
    var showHiddenCategories: Bool {
        (!searchText.isEmpty && !filteredHiddenCategories.isEmpty) || searchText.isEmpty
    }
    
    var showSpecialCategories: Bool {
        (!searchText.isEmpty && !filteredSpecialCategories.isEmpty) || searchText.isEmpty
    }
    
    var body: some View {        
        NavigationStack {
            Group {
                if filteredCategories.isEmpty && filteredHiddenCategories.isEmpty && filteredSpecialCategories.isEmpty {
                    ContentUnavailableView("No categories found", systemImage: "exclamationmark.magnifyingglass")
                } else {
                    StandardContainerWithToolbar(.list) {
                        if showMyCategories && !filteredCategories.isEmpty { yourCategoriesSection }
                        if showHiddenCategories && !filteredHiddenCategories.isEmpty { hiddenCategoriesSections }
                        if showSpecialCategories && !filteredSpecialCategories.isEmpty { specialCategoriesSections }
                        if searchText.isEmpty { noneSection }
                    }
                }
            }
            //.scrollEdgeEffectStyle(.hard, for: .all)
            .searchable(text: $searchText, prompt: Text("Search"))
            #if os(iOS)
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                
                ToolbarSpacer(.flexible, placement: AppState.shared.isIpad ? .topBarLeading : .bottomBar)
                ToolbarItem(placement: AppState.shared.isIpad ? .topBarLeading : .bottomBar) { CategorySortMenu() }
                
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            #endif
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        .sheet(item: $editCategory, onDismiss: {
            categoryEditID = nil
        }, content: { cat in
            CategoryEditView(category: cat, editID: $categoryEditID)
            //#if os(iOS)
            //.presentationDetents([.medium, .large])
            //#endif
            #if os(macOS)
                .frame(maxWidth: 300)
            #endif
        })
        
        .onChange(of: categoryEditID) { oldValue, newValue in
            if let newValue {
                editCategory = catModel.getCategory(by: newValue)
            } else {
                catModel.saveCategory(id: oldValue!, calModel: calModel, keyModel: keyModel)
            }
        }
    }
    
    @ViewBuilder
    var noneSection: some View {
        let theNil = catModel.categories.filter { $0.isNil }.first!
        HStack {
            Text("None")
                .strikethrough(true)
            Spacer()
            if category?.id == theNil.id {
                Image(systemName: "checkmark")
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { doIt(theNil) }
    }
    
    
    var yourCategoriesSection: some View {
        Section("My Categories") {
            ForEach(filteredCategories) { cat in
                StandardCategoryLabel(
                    cat: cat,
                    labelWidth: labelWidth,
                    showCheckmarkCondition: category?.id == cat.id
                )
                .onTapGesture { doIt(cat) }
                
            }
            
            Button("New Category") {
                categoryEditID = UUID().uuidString
            }
        }
    }
    
    @AppStorage("hiddenCategoriesSectionIsExpanded") private var storedIsHiddenSectionExpanded: Bool = false
    @State private var isHiddenSectionExpanded = false
    
    @ViewBuilder
    var hiddenCategoriesSections: some View {
        Section {
            if isHiddenSectionExpanded {
                ForEach(filteredHiddenCategories) { cat in
                    StandardCategoryLabel(
                        cat: cat,
                        labelWidth: labelWidth,
                        showCheckmarkCondition: category?.id == cat.id
                    )
                    .onTapGesture { doIt(cat) }
                }
            } else {
                Button("Show All") {
                    withAnimation { isHiddenSectionExpanded.toggle() }
                }
            }
        } header: {
            hiddenSectionHeader
        }
    }
    
    
    
    var hiddenSectionHeader: some View {
        HStack {
            HStack {
                Text("Hidden Categories")
                Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(isHiddenSectionExpanded ? 90 : 0))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation { isHiddenSectionExpanded.toggle() }
            }
            Spacer()
        }
        .onAppear { isHiddenSectionExpanded = storedIsHiddenSectionExpanded }
        .onChange(of: isHiddenSectionExpanded) { storedIsHiddenSectionExpanded = $1 }
    }
    
    
    @ViewBuilder
    var specialCategoriesSections: some View {
        Section {
            ForEach(filteredSpecialCategories) { cat in
                StandardCategoryLabel(
                    cat: cat,
                    labelWidth: labelWidth,
                    showCheckmarkCondition: category?.id == cat.id
                )
                .onTapGesture { doIt(cat) }
            }
        } header: {
            Text("Special Categories")
        }
    }
    
  
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    func doIt(_ cat: CBCategory?) {
        category = cat
        if saveOnChange && trans != nil {
            //trans!.updatedBy = AppState.shared.user!
            //Task { await calModel.submit(trans!) }
            Task {
                await calModel.saveTransaction(id: trans!.id)
            }
        }
        dismiss()
    }
}





