//
//  MultiCategorySheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/3/25.
//

import SwiftUI


struct MultiCategorySheet: View {
    @AppStorage("hiddenCategoriesSectionIsExpanded") private var storedIsHiddenSectionExpanded: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(CalendarModel.self) private var calModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    
    @Binding var categories: Array<CBCategory>
    @Binding var categoryGroups: Array<CBCategoryGroup>

    var includeHidden: Bool = false
    
    var showAnalyticSpecificOptions = false
                
    @FocusState private var focusedField: Int?
    @State private var searchText = ""
    @State private var labelWidth: CGFloat = 20.0
    @State private var newGroupTitle = ""
    @State private var showDeleteAlert = false
    @State private var showInfo = false
    @State private var editGroup: CBCategoryGroup?
    @State private var groupEditID: CBCategoryGroup.ID?
    @State private var isHiddenSectionExpanded = false
    
    
    var filteredCategories: Array<CBCategory> {
        catModel.categories
            .filter { !$0.isNil }
            .filter { !$0.isHidden && $0.appSuiteKey == nil }
            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
            .sorted(by: Helpers.categorySorter())
    }
    
    
    var filteredHiddenCategories: Array<CBCategory> {
        catModel.categories
            .filter { !$0.isNil }
            .filter { $0.isHidden && $0.appSuiteKey == nil }
            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
            .sorted(by: Helpers.categorySorter())
    }
    
    
    var filteredSpecialCategories: Array<CBCategory> {
        catModel.categories
            .filter { !$0.isNil }
            //.filter { !$0.isHidden && $0.appSuiteKey != nil }
            .filter { $0.appSuiteKey != nil }
            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
            .sorted(by: Helpers.categorySorter())
    }
    
    
    var filteredCategoryGroups: Array<CBCategoryGroup> {
        catModel.categoryGroups
            .filter { !$0.title.isEmpty }
            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.title.lowercased() < $1.title.lowercased() }
    }
    
    
    var selectedCategoryIds: [String] {
        categories
            //.filter { $0.active }
            //.filter { !$0.isHidden }
            //.sorted(by: Helpers.categorySorter())
            //.sorted { $0.id > $1.id }
            .compactMap(\.id)
    }
    
    
    var showCategoryGroups: Bool {
        (!searchText.isEmpty && !filteredCategoryGroups.isEmpty) || searchText.isEmpty
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
        //let _ = Self._printChanges()
        //Text("hi")
        NavigationStack {
            Group {
                if filteredCategories.isEmpty
                && filteredHiddenCategories.isEmpty
                && filteredSpecialCategories.isEmpty
                && filteredCategoryGroups.isEmpty {
                    ContentUnavailableView("No categories found", systemImage: "exclamationmark.magnifyingglass")
                } else {
                    StandardContainerWithToolbar(.list) {
                        if showCategoryGroups {
                            Section("Category Groups") {
                                ForEach(filteredCategoryGroups) { group in
                                    categoryGroupLine(group: group)
                                }
                                
                                if searchText.isEmpty {
                                    allExpenseCategoriesButton
                                    
                                    if !catModel.categories.filter({ $0.isIncome }).isEmpty {
                                        allIncomeCategoriesButton
                                    }
                                    
                                    if showAnalyticSpecificOptions {
                                        anythingWithAnAmountButton
                                    }
                                }
                            }
                        }
                        
                        if showMyCategories {
                            Section("My Categories") {
                                ForEach(filteredCategories) { cat in
                                    multiCategoryPickerLineItem(cat: cat)
                                }
                            }
                        }
                        
                        if showHiddenCategories { hiddenCategoriesSections }
                        if showSpecialCategories { specialCategoriesSection }
                        
                        
                        if searchText.isEmpty {
                            noneSection
                        }
                    }
                }
            }
            .navigationTitle("Categories")
            #if os(iOS)
            .searchable(text: $searchText, prompt: Text("Search"))
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) { selectButton }
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                                
                ToolbarSpacer(.flexible, placement: AppState.shared.isIpad ? .topBarLeading : .bottomBar)
                ToolbarItem(placement: AppState.shared.isIpad ? .topBarTrailing : .bottomBar) { CategorySortMenu() }
                if AppState.shared.isIpad {
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                }
                ToolbarItem(placement: .topBarTrailing) { closeButton }
                #else
                ToolbarItemGroup(placement: .destructiveAction) {
                    HStack {
                        selectButton
                    }
                }
                ToolbarItemGroup(placement: .confirmationAction) {
                    HStack {
                        CategorySortMenu()
                        closeButton
                    }
                }
                #endif
            }
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        
//        .onChange(of: groupEditID) { oldValue, newValue in
//            if let newValue {
//                editGroup = catModel.getCategoryGroup(by: newValue)
//            } else {
//                catModel.saveCategoryGroup(id: oldValue!)
//            }
//        }
//        
//        .sheet(item: $editGroup, onDismiss: {
//            groupEditID = nil
//        }, content: { group in
//            CategoryGroupEditView(group: group, editID: $groupEditID)
//            #if os(macOS)
//                .frame(minWidth: 500, minHeight: 700)
//                .presentationSizing(.fitted)
//            #endif
//        })
    }
    
    var noneSection: some View {
        let theNil = catModel.categories.filter { $0.isNil }.first!
        return Section("None") {
            Button {
                doit(theNil)
            } label: {
                HStack {
                    Text("None")
                        .strikethrough(true)
                    Spacer()
                    
                    Image(systemName: "checkmark")
                        .opacity(categories.filter{ $0.active }.map {$0.id}.contains(theNil.id) ? 1 : 0)
                }
                .schemeBasedForegroundStyle()
                .contentShape(Rectangle())
            }
            #if os(macOS)
            .buttonStyle(.plain)
            #endif
        }
    }
    
    
    @ViewBuilder
    var hiddenCategoriesSections: some View {
        Section {
            if isHiddenSectionExpanded {
                ForEach(filteredHiddenCategories) { cat in
                    multiCategoryPickerLineItem(cat: cat)
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
    
    
    @ViewBuilder
    var specialCategoriesSection: some View {
        if !filteredSpecialCategories.isEmpty {
            Section("Special Categories") {
                ForEach(filteredSpecialCategories) { cat in
                    multiCategoryPickerLineItem(cat: cat)
                }
            }
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
    var allExpenseCategoriesButton: some View {
        /// Sort order is reversed to account for the offset of the circles
        let categories = catModel.categories
            .filter ({ $0.active })
            .filter ({ !$0.isHidden })
            .filter ({ !$0.isIncome })
            .sorted(by: Helpers.categorySorter())
        
        Button {
            withAnimation { self.categories = categories }
            
            print(self.categories.map {$0.id})
            print(selectedCategoryIds)
            
        } label: {
            HStack {
                GradientCircleDot(colors: categories.map { $0.color })
                    .frame(minWidth: labelWidth, alignment: .center)
                
                Text("Expenses")
                Spacer()
                
                if selectedCategoryIds.containsSameElements(as: categories.compactMap(\.id)) {
                
                //if selectedCategoryIds == categories.compactMap(\.id) {
                    Image(systemName: "checkmark")
                }
            }
            .schemeBasedForegroundStyle()
            .contentShape(Rectangle())
        }
        #if os(macOS)
        .buttonStyle(.plain)
        #endif
    }
    
    
    @ViewBuilder
    var allIncomeCategoriesButton: some View {
        /// Sort order is reversed to account for the offset of the circles
        let categories = catModel.categories
            .filter { $0.active }
            .filter({ $0.isIncome })
            .filter { !$0.isHidden }
            .sorted(by: Helpers.categorySorter())
        
        Button {
            withAnimation { self.categories = categories }
        } label: {
            HStack {
                GradientCircleDot(colors: categories.map { $0.color })
                    .frame(minWidth: labelWidth, alignment: .center)
                
                Text("Income")
                Spacer()
                
                if selectedCategoryIds.containsSameElements(as: categories.compactMap(\.id)) {
                //if selectedCategoryIds == categories.compactMap(\.id) {
                    Image(systemName: "checkmark")
                }
            }
            .schemeBasedForegroundStyle()
            .contentShape(Rectangle())
        }
        #if os(macOS)
        .buttonStyle(.plain)
        #endif
    }
    
    
    @ViewBuilder
    var anythingWithAnAmountButton: some View {
//        let categories = calModel.sMonth.justTransactions
//            .filter ({ $0.active })
//            .filter ({ $0.amount != 0 && $0.category != nil })
//            .compactMap ({ $0.category })
//            //.filter ({ !$0.isIncome })
//            .sorted(by: Helpers.categorySorter())
//            .uniqued(on: \.id)
        
        Button {
            withAnimation {
                //self.categories = categories
                
                for group in catModel.categoryGroups {
                    if categoryGroups.map({ $0.id }).contains(group.id) { continue }
                    
                    let groupCatIds = group.categories.map { $0.id }
                    let hasTrans = !calModel.sMonth.justTransactions
                        .filter ({ $0.active })
                        .filter ({ $0.amount != 0 && groupCatIds.contains($0.category?.id ?? "0") })
                        .isEmpty
                    
                    if hasTrans {
                        self.categoryGroups.append(group)
                    }
                }
                
                //categoryGroups = catModel.categoryGroups
                for cat in catModel.categories.filter({ $0.appSuiteKey == nil }) {
                    if categoryGroups
                        .flatMap({ $0.categories })
                        .map({ $0.id })
                        .contains(cat.id) {
                            continue
                        }
                    
                    if categories.map({ $0.id }).contains(cat.id) { continue }
                    
                    self.categories.append(cat)
                }
            }
        } label: {
            HStack {
                Group {
                    Image(systemName: "dollarsign.circle.fill")
                        //.foregroundStyle(.green)
                }
                .frame(minWidth: labelWidth, alignment: .center)
                
                Text("Relevant Categories")
                Spacer()
                
//                if selectedCategoryIds.containsSameElements(as: categories.compactMap(\.id)) {
//                //if selectedCategoryIds == categories.compactMap(\.id) {
//                    Image(systemName: "checkmark")
//                }
                
                Button {
                    showInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Color.theme)
                }
                .popover(isPresented: $showInfo) {
                    Text("Include all expense categories that have transactions.")
                        .frame(width: 200)
                        .padding()
                        .presentationCompactAdaptation(.popover)
                }
            }
            .schemeBasedForegroundStyle()
            .contentShape(Rectangle())
        }
        #if os(macOS)
        .buttonStyle(.plain)
        #endif
    }
    
    
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
        #if os(macOS)
        .buttonStyle(.roundMacButton)
        #endif
    }
    
    
    var selectButton: some View {
        Button {
            withAnimation {
//                for each in catModel.categoryGroups {
//                    categoryGroups
//                }
                if categoryGroups.isEmpty || categories.isEmpty {
                    categoryGroups = catModel.categoryGroups
                    for cat in catModel.categories.filter({ $0.appSuiteKey == nil }) {
                        if categoryGroups
                            .flatMap({ $0.categories })
                            .map({ $0.id })
                            .contains(cat.id) {
                                continue
                            }
                        
                        categories.append(cat)
                    }
                } else {
                    categoryGroups = []
                    categories = []
                }
                
                
//                if categories.isEmpty {
//                    for cat in catModel.categories.filter({ $0.appSuiteKey == nil }) {
//                        if categoryGroups
//                            .flatMap({ $0.categories })
//                            .map({ $0.id })
//                            .contains(cat.id) {
//                                continue
//                            }
//                        
//                        categories.append(cat)
//                    }
//                } else {
//                    categories = []
//                }
                
                
                
//                
//                let groupCatIds =
//                
//                categories = catModel.categories.filter {}
//                
//                categories = categories.isEmpty ? catModel.categories : []
//                categoryGroups = []
//                //calModel.sCategoryGroupsForAnalysis
            }
        } label: {
            //Image(systemName: categories.isEmpty ? "checklist.checked" : "checklist.unchecked")
            Text(categories.isEmpty ? "Select All" : "Deselect All")
            //Image(systemName: categories.isEmpty ? "checkmark.rectangle.stack" : "checklist.checked")
                .schemeBasedForegroundStyle()
        }
        #if os(macOS)
        .buttonStyle(.roundMacButton(horizontalPadding: 10))
        #endif
    }
    
    
    var disabledCategoryIds: [String] {
        categoryGroups.flatMap { $0.categories }.map { $0.id }
    }
    
    
    @ViewBuilder
    func multiCategoryPickerLineItem(cat: CBCategory) -> some View {
        StandardCategoryLabel(
            cat: cat,
            labelWidth: labelWidth,
            showCheckmarkCondition: categories.filter { $0.active }.map{$0.id}.contains(cat.id),
            isDisabled: disabledCategoryIds.contains(cat.id)
        )
        .onTapGesture {
            withAnimation { doit(cat) }
        }
        //.foregroundStyle(disabledCategoryIds.contains(cat.id) ? .gray : .primary)
        .disabled(disabledCategoryIds.contains(cat.id))
    }



    
    
    func doit(_ category: CBCategory) {
        if categories.map({ $0.id }).contains(category.id) {
            categories.removeAll(where: { $0.id == category.id })
        } else {
            categories.append(category)
        }
    }
    
    func doit(_ group: CBCategoryGroup) {
        print("-- \(#function)")
        
        categories.removeAll(where: { group.categories.map({ $0.id }).contains($0.id) })
        
        
        if categoryGroups.map({ $0.id }).contains(group.id) {
            print("Removing")
            categoryGroups.removeAll(where: { $0.id == group.id })
        } else {
            print("Adding")
            categoryGroups.append(group)
        }
    }
    
    
    func getReversedCategories(for group: CBCategoryGroup) -> Array<CBCategory> {
         group.categories
            .filter({ $0.active })
            .sorted(by: Helpers.categorySorter())
    }
    
    
    
    
    @ViewBuilder
    func categoryGroupLine(group: CBCategoryGroup) -> some View {
        Button {
            withAnimation {
                doit(group)
            }
        } label: {
            HStack {
                Group {
                    let colors = group.categories.filter({ $0.active }).sorted(by: Helpers.categorySorter()).map(\.color)
                    GradientCircleDot(colors: colors)
                }
                .frame(minWidth: labelWidth, alignment: .center)
                
                
                Text(group.title)
                Spacer()
                if self.categoryGroups.map({ $0.id }).contains(group.id) {
                    Image(systemName: "checkmark")
                }
            }
            .schemeBasedForegroundStyle()
            .contentShape(Rectangle())
        }
        #if os(macOS)
        .buttonStyle(.plain)
        #endif
    }
    
            
    
    struct EditGroupButton: View {
        @Bindable var group: CBCategoryGroup
        @Binding var groupEditID: String?
        
        var body: some View {
            Button {
                groupEditID = group.id
            } label: {
                Label {
                    Text("Edit")
                } icon: {
                    Image(systemName: "pencil")
                }
            }
        }
    }
}
