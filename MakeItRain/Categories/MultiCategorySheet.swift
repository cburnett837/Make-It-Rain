//
//  MultiCategorySheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/3/25.
//

import SwiftUI


//
//struct MultiCategorySheetLite: View {
//    @Environment(\.colorScheme) var colorScheme
//    @Environment(\.dismiss) var dismiss
//    
//    @Environment(CalendarModel.self) private var calModel
//    @Environment(CategoryModel.self) private var catModel
//    @Environment(KeywordModel.self) private var keyModel
//    
//    @Binding var categories: Array<CBCategory>
//    @Binding var categoryGroups: Array<CBCategoryGroup>
//    var includeHidden: Bool = false
//    
//    var showAnalyticSpecificOptions = false
//                
//    @FocusState private var focusedField: Int?
//    @State private var searchText = ""
//    @State private var labelWidth: CGFloat = 20.0
//    @State private var newGroupTitle = ""
//    @State private var showDeleteAlert = false
//    @State private var showInfo = false
//    @State private var editGroup: CBCategoryGroup?
//    @State private var groupEditID: CBCategoryGroup.ID?
//    
//    var body: some View {
//        //let _ = Self._printChanges()
//        //Text("hi")
//        NavigationStack {
//            StandardContainerWithToolbar(.list) {
//                Section("My Categories") {
//                    ForEach(catModel.categories) { cat in
//                        multiCategoryPickerLineItem(cat: cat)
//                    }
//                }
//            }
//            .searchable(text: $searchText, prompt: Text("Search"))
//            .navigationTitle("Categories")
//            #if os(iOS)
//            .navigationBarTitleDisplayMode(.inline)
////            .toolbar {
////                //ToolbarItem(placement: .topBarLeading) { selectButton }
////                //DefaultToolbarItem(kind: .search, placement: .bottomBar)
////                                
////                ToolbarSpacer(.flexible, placement: AppState.shared.isIpad ? .topBarLeading : .bottomBar)
////                ToolbarItem(placement: AppState.shared.isIpad ? .topBarTrailing : .bottomBar) { CategorySortMenu() }
////                if AppState.shared.isIpad {
////                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
////                }
////                                
//////                ToolbarSpacer(.flexible, placement: .bottomBar)
//////                ToolbarItem(placement: .bottomBar) { CategorySortMenu() }
////                ToolbarItem(placement: .topBarTrailing) { closeButton }
////            }
//            #endif
//        }
//        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
//    }
//    
//    
//    
//    var closeButton: some View {
//        Button {
//            dismiss()
//        } label: {
//            Image(systemName: "xmark")
//                .schemeBasedForegroundStyle()
//        }
//        //.buttonStyle(.glassProminent)
//        //.tint(confirmButtonTint)
//        //.background(confirmButtonTint)
//        //.foregroundStyle(confirmButtonTint)
//        //}
//    }
//    
//    
//    var selectButton: some View {
//        Button {
//            withAnimation {
//                categories = categories.isEmpty ? catModel.categories : []
//            }
//        } label: {
//            //Image(systemName: categories.isEmpty ? "checklist.checked" : "checklist.unchecked")
//            Text(categories.isEmpty ? "Select All" : "Deselect All")
//            //Image(systemName: categories.isEmpty ? "checkmark.rectangle.stack" : "checklist.checked")
//                .schemeBasedForegroundStyle()
//        }
//    }
//    
//    
//    @ViewBuilder
//    func multiCategoryPickerLineItem(cat: CBCategory) -> some View {
//        StandardCategoryLabel(
//            cat: cat,
//            labelWidth: labelWidth,
//            showCheckmarkCondition: categories.filter{ $0.active }.contains(cat)
//        )
//        .onTapGesture {
//            withAnimation { doit(cat) }
//        }
//    }
//    
//    
//    func doit(_ category: CBCategory) {
//        if categories.map({ $0.id }).contains(category.id) {
//            categories.removeAll(where: { $0.id == category.id })
//        } else {
//            categories.append(category)
//        }
//    }
//}



struct MultiCategorySheet: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    //@Local(\.colorTheme) var colorTheme
    //@Local(\.lineItemIndicator) var lineItemIndicator
    @Local(\.categorySortMode) var categorySortMode
    //@Local(\.categoryIndicatorAsSymbol) var categoryIndicatorAsSymbol

    
    @Environment(CalendarModel.self) private var calModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    
    @Binding var categories: Array<CBCategory>
    @Binding var categoryGroup: Array<CBCategoryGroup>

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
            .filter { !$0.isHidden && $0.appSuiteKey != nil }
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
//                                    CategoryGroupLine(
//                                        categories: $categories,
//                                        group: group,
//                                        showDeleteAlert: $showDeleteAlert,
//                                        groupEditID: $groupEditID,
//                                        selectedCategoryIds: selectedCategoryIds,
//                                        labelWidth: labelWidth,
//                                        getReversedColors: getReversedColors
//                                    )
                                }
                                
                                if searchText.isEmpty {
                                    allExpenseCategoriesButton
                                    
                                    if !catModel.categories.filter({ $0.isIncome }).isEmpty {
                                        allIncomeCategoriesButton
                                    }
                                    
                                    if showAnalyticSpecificOptions {
                                        anythingWithAnAmountButton
                                    }
                                    
                                    //addNewGroupButton
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
            
            .searchable(text: $searchText, prompt: Text("Search"))
            .navigationTitle("Categories")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { selectButton }
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                                
                ToolbarSpacer(.flexible, placement: AppState.shared.isIpad ? .topBarLeading : .bottomBar)
                ToolbarItem(placement: AppState.shared.isIpad ? .topBarTrailing : .bottomBar) { CategorySortMenu() }
                if AppState.shared.isIpad {
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                }
                                
//                ToolbarSpacer(.flexible, placement: .bottomBar)
//                ToolbarItem(placement: .bottomBar) { CategorySortMenu() }
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            #endif
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
                        .opacity(categories.filter{ $0.active }.contains(theNil) ? 1 : 0)
                }
                .schemeBasedForegroundStyle()
                .contentShape(Rectangle())
            }
            #if os(macOS)
            .buttonStyle(.plain)
            #endif
        }
    }
    
    
    @AppStorage("hiddenCategoriesSectionIsExpanded") private var storedIsHiddenSectionExpanded: Bool = false
    @State private var isHiddenSectionExpanded = false
    
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
                Group {
                    Circle()
                        .fill(AngularGradient(gradient: Gradient(stops: getReversedColors(categories)), center: .center))
                        .frame(width: 20, height: 20)
                }
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
                Group {
                    Circle()
                        .fill(AngularGradient(gradient: Gradient(stops: getReversedColors(categories)), center: .center))
                        .frame(width: 20, height: 20)
                }
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
        let categories = calModel.sMonth.justTransactions
            .filter ({ $0.active })
            .filter ({ $0.amount != 0 && $0.category != nil })
            .compactMap ({ $0.category })
            .filter ({ !$0.isIncome })
            .sorted(by: Helpers.categorySorter())
            .uniqued(on: \.id)
        
        Button {
            withAnimation { self.categories = categories }
        } label: {
            HStack {
                Group {
                    Image(systemName: "dollarsign.circle.fill")
                        //.foregroundStyle(.green)
                }
                .frame(minWidth: labelWidth, alignment: .center)
                
                Text("Relevant Categories")
                Spacer()
                
                if selectedCategoryIds.containsSameElements(as: categories.compactMap(\.id)) {
                //if selectedCategoryIds == categories.compactMap(\.id) {
                    Image(systemName: "checkmark")
                }
                
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
    
    
//    var anythingWithAnAmountButton: some View {
//        return Button {
//            withAnimation {
//                self.categories = calModel.sMonth.justTransactions
//                    .filter ({ $0.active })
//                    .filter ({ $0.amount != 0 && $0.category != nil })
//                    .compactMap ({ $0.category })
//                    .sorted(by: {$0.id > $1.id})
//                    .uniqued(on: \.id)
//            }
//        } label: {
//            HStack {
//                Group {
//                    Image(systemName: "dollarsign.circle")
//                }
//                .frame(minWidth: labelWidth, alignment: .center)
//                
//                Text("Any category that has transactions")
//                Spacer()
//                
//                if selectedCategoryIds == calModel.sMonth.justTransactions
//                    .filter ({ $0.active })
//                    .filter ({ $0.amount != 0 && $0.category != nil })
//                    .compactMap ({ $0.category })
//                    .sorted(by: {$0.id > $1.id})
//                    .uniqued(on: \.id)
//                    .compactMap(\.id)
//                {
//                    Image(systemName: "checkmark")
//                }
//            }
//            .schemeBasedForegroundStyle()
//            .contentShape(Rectangle())
//        }
//        #if os(macOS)
//        .buttonStyle(.plain)
//        #endif
//    }
    
    
    
    
    
    var addNewGroupButton: some View {
        Button("New Group") {
            groupEditID = UUID().uuidString
        }
        #if os(macOS)
        .buttonStyle(.plain)
        #endif
    }
    
    
//    var sortMenu: some View {
//        Menu {
//            Button {
//                categorySortMode = .title
//            } label: {
//                Label {
//                    Text("Title")
//                } icon: {
//                    Image(systemName: categorySortMode == .title ? "checkmark" : "textformat.abc")
//                }
//            }
//            
//            Button {
//                categorySortMode = .listOrder
//            } label: {
//                Label {
//                    Text("Custom")
//                } icon: {
//                    Image(systemName: categorySortMode == .listOrder ? "checkmark" : "list.bullet")
//                }
//            }
//        } label: {
//            Image(systemName: "arrow.up.arrow.down")
//                .schemeBasedForegroundStyle()
//        }
//    }
    
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
        //.buttonStyle(.glassProminent)
        //.tint(confirmButtonTint)
        //.background(confirmButtonTint)
        //.foregroundStyle(confirmButtonTint)
        //}
    }
    
    
    var groupMenu: some View {
        Menu {
            ForEach(catModel.categoryGroups) { group in
                Button(group.title) {
                    self.categories = []
                    for each in group.categories {
                        self.categories.append(each)
                    }
                }
            }
            Section {
                Button("Save As Group") {
                    let alertConfig = AlertConfig(
                        title: "Create New Group",
                        subtitle: "Enter a title for the group",
                        symbol: .init(name: "rectangle.3.group", color: Color.theme),
                        primaryButton:
                            AlertConfig.AlertButton(closeOnFunction: false, showSpinnerOnClick: false, config: .init(text: "Create", role: .primary, function: {
                                Task {
                                    let group = CBCategoryGroup()
                                    group.title = newGroupTitle
                                    for each in categories {
                                        group.categories.append(each)
                                    }
                                    
                                    catModel.upsert(group)
                                    let _ = await catModel.submit(group)
                                }
                                
                                AppState.shared.closeAlert()
                            })),
                        views: [
                            AlertConfig.ViewConfig(content: AnyView(textField))
                        ]
                    )
                    
                    AppState.shared.showAlert(config: alertConfig)
                }
            }
        } label: {
            Image(systemName: "checklist.checked")
        }
    }
    
    
    var textField: some View {
        TextField("Title", text: $newGroupTitle)
            .multilineTextAlignment(.center)
    }
    
    
    var selectButton: some View {
        Button {
            withAnimation {
                categories = categories.isEmpty ? catModel.categories : []
                //calModel.sCategoryGroupsForAnalysis
            }
        } label: {
            //Image(systemName: categories.isEmpty ? "checklist.checked" : "checklist.unchecked")
            Text(categories.isEmpty ? "Select All" : "Deselect All")
            //Image(systemName: categories.isEmpty ? "checkmark.rectangle.stack" : "checklist.checked")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    @ViewBuilder
    func multiCategoryPickerLineItem(cat: CBCategory) -> some View {
        StandardCategoryLabel(
            cat: cat,
            labelWidth: labelWidth,
            showCheckmarkCondition: categories.filter{ $0.active }.contains(cat)
        )
        .onTapGesture {
            withAnimation { doit(cat) }
        }
    }



    
    
    func doit(_ category: CBCategory) {
        if !calModel.sCategoryGroupsForAnalysis.isEmpty {
            calModel.sCategoryGroupsForAnalysis.removeAll()
            categories.removeAll()
        }
        
        
        if categories.map({ $0.id }).contains(category.id) {
            categories.removeAll(where: { $0.id == category.id })
        } else {
            categories.append(category)
        }
    }
    
    
    func getReversedCategories(for group: CBCategoryGroup) -> Array<CBCategory> {
         group.categories
            .filter({ $0.active })
            .sorted(by: Helpers.categorySorter())
    }
    
    
    func getReversedColors(_ categories: Array<CBCategory>) -> Array<Gradient.Stop> {
         let colors = categories
            .filter({ $0.active })
            .sorted(by: Helpers.categorySorter())            
            .map {$0.color}
        
        
        let count = colors.count
        let step = 1.0 / Double(count)
        let epsilon = 0.00001

        // For sharp edges, we give each color two stops: start and end.
        let stops: [Gradient.Stop] = colors.enumerated().flatMap { index, color in
            let start = Double(index) * step
            let end = start + step - epsilon // Slightly before the next color's start
            return [
                Gradient.Stop(color: color, location: start),
                Gradient.Stop(color: color, location: end)
            ]
        }
        
        return stops
    }
    
    
    @ViewBuilder func categoryGroupLine(group: CBCategoryGroup) -> some View {
        Button {
            withAnimation {
                self.categories = group.categories.filter({ $0.active })
                self.categoryGroup = [group]
                dismiss()
            }
        } label: {
            HStack {
                Group {
                    Circle()
                        .fill(AngularGradient(gradient: Gradient(stops: getReversedColors(group.categories)), center: .center))
                        .frame(width: 20, height: 20)
                }
                .frame(minWidth: labelWidth, alignment: .center)
                
                
                Text(group.title)
                Spacer()
                if selectedCategoryIds == group.categories
                    //.sorted(by: {$0.id > $1.id})
                    .sorted(by: Helpers.categorySorter())
                    .compactMap(\.id) {
                    Image(systemName: "checkmark")
                }
            }
            .schemeBasedForegroundStyle()
            .contentShape(Rectangle())
        }
        #if os(macOS)
        .buttonStyle(.plain)
        #endif
//        .swipeActions(allowsFullSwipe: false) {
//            EditGroupButton(group: group, groupEditID: $groupEditID)
//        }
    }
    
//    struct CategoryGroupLine: View {
//        @Environment(\.colorScheme) var colorScheme
//        
//        @Binding var categories: Array<CBCategory>
//        @Bindable var group: CBCategoryGroup
//        @Binding var showDeleteAlert: Bool
//        @Binding var groupEditID: String?
//        var selectedCategoryIds: [String]
//        var labelWidth: CGFloat
//        
//        var getReversedColors: (_ for: Array<CBCategory>) -> Array<Gradient.Stop>
//        
//        var body: some View {
//            Button {
//                withAnimation {
//                    self.categories = group.categories.filter({ $0.active })
//                }
//            } label: {
//                HStack {
//                    Group {
//                        Circle()
//                            .fill(AngularGradient(gradient: Gradient(stops: getReversedColors(group.categories)), center: .center))
//                            .frame(width: 20, height: 20)
//                    }
//                    .frame(minWidth: labelWidth, alignment: .center)
//                    
//                    
//                    Text(group.title)
//                    Spacer()
//                    if selectedCategoryIds == group.categories
//                        //.sorted(by: {$0.id > $1.id})
//                        .sorted(by: Helpers.categorySorter())
//                        .compactMap(\.id) {
//                        Image(systemName: "checkmark")
//                    }
//                }
//                .schemeBasedForegroundStyle()
//                .contentShape(Rectangle())
//            }
//            #if os(macOS)
//            .buttonStyle(.plain)
//            #endif
//            .swipeActions(allowsFullSwipe: false) {
//                EditGroupButton(group: group, groupEditID: $groupEditID)
//            }
//        }
//    }
            
    
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



//
//
//struct MultiCategoryPickerLineItem: View {
//    var cat: CBCategory
//    @Binding var categories: [CBCategory]
//    var labelWidth: CGFloat
//    var selectFunction: () -> Void
//    
//    var body: some View {
//        StandardCategoryLabel(
//            cat: cat,
//            labelWidth: labelWidth,
//            showCheckmarkCondition: categories.filter{ $0.active }.contains(cat)
//        )
//        .onTapGesture {
//            withAnimation { selectFunction() }
//        }
//    }
//}
//
//
