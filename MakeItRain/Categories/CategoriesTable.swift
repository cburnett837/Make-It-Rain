//
//  PaymentMethodsView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/20/24.
//

import SwiftUI
import Algorithms

struct CategoriesTable: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Local(\.categoryIndicatorAsSymbol) var categoryIndicatorAsSymbol

    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    
    @State private var navPath = NavigationPath()

    @State private var searchText = ""
    @State private var editCategory: CBCategory?
    @State private var categoryEditID: CBCategory.ID?
    
    @State private var editGroup: CBCategoryGroup?
    @State private var groupEditID: CBCategoryGroup.ID?

    @AppStorage("categoryTableColumnOrder") private var columnCustomization: TableColumnCustomization<CBCategory>
    #if os(macOS)
    
    @State private var showReorderList = false
    #endif
    
    @State private var sortOrder = [KeyPathComparator(\CBCategory.title)]
    @State private var labelWidth: CGFloat = 20.0
    
    var filteredCategoryGroups: Array<CBCategoryGroup> {
        catModel.categoryGroups
            .filter { !$0.title.isEmpty }
            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
            //.sorted { $0.title.lowercased() < $1.title.lowercased() }
    }
    
    var filteredCategories: [CBCategory] {
        catModel.categories
            .filter { !$0.isNil && $0.appSuiteKey == nil }
            .filter { searchText.isEmpty ? !$0.title.isEmpty : $0.title.localizedCaseInsensitiveContains(searchText) }
            /// NOTE: Sorting must be done in the task and not in the computed property. If done in the computed property, when reording, they get all messed up.
    }
    
    var filteredSpecialCategories: [CBCategory] {
        catModel.categories
            .filter { !$0.isNil && $0.appSuiteKey != nil }
            .filter { searchText.isEmpty ? !$0.title.isEmpty : $0.title.localizedCaseInsensitiveContains(searchText) }
            /// NOTE: Sorting must be done in the task and not in the computed property. If done in the computed property, when reording, they get all messed up.
    }
    
    var body: some View {
        //let _ = Self._printChanges()
        @Bindable var catModel = catModel
        NavigationStack(path: $navPath) {
            VStack {
                if !catModel.categories.filter({ !$0.isNil }).isEmpty {
                    #if os(macOS)
                    macTable
                    #else
                    if filteredCategories.isEmpty
                    && filteredCategoryGroups.isEmpty
                    && filteredSpecialCategories.isEmpty {
                        ContentUnavailableView("No categories found", systemImage: "exclamationmark.magnifyingglass")
                    } else {
                        if AppState.shared.isIphone {
                            listForPhoneAndMacSort
                        } else {
                            padList
                        }
                    }
                    #endif
                } else {
                    ContentUnavailableView("No Categories", systemImage: "books.vertical", description: Text("Click the plus button above to add a category."))
                }
            }
            .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
            #if os(iOS)
            .navigationTitle("Categories")
            //.navigationBarTitleDisplayMode(.inline)
            #endif
            #if os(macOS)
            /// There seems to be a bug in SwiftUI `Table` that prevents the view from refreshing when adding a new category, and then trying to edit it.
            /// When I add a new category, and then update `model.categories` with the new ID from the server, the table still contains an ID of 0 on the newly created category.
            /// Setting this id forces the view to refresh and update the relevant category with the new ID.
            .id(catModel.fuckYouSwiftuiTableRefreshID)
            #endif
            //.navigationBarBackButtonHidden(true)
            .task {
                /// NOTE: Sorting must be done here and not in the computed property. If done in the computed property, when reording, they get all messed up.
                //let categorySortMode = SortMode.fromString(UserDefaults.standard.string(forKey: "categorySortMode") ?? "")
                
                catModel.categories.sort(by: Helpers.categorySorter())
            }
            .navigationDestination(for: CBCategory.self) { cat in
                CategoryOverView(category: cat, navPath: $navPath, calModel: calModel, catModel: catModel)
            }
            .navigationDestination(for: CBCategoryGroup.self) { group in
                CategoryGroupOverView(group: group, navPath: $navPath, calModel: calModel, catModel: catModel)
            }
            .toolbar {
                #if os(macOS)
                macToolbar()
                #else
                phoneToolbar()
                #endif
            }
            .searchable(text: $searchText)
            .onChange(of: categoryEditID) { oldValue, newValue in
                if let newValue {
                    editCategory = catModel.getCategory(by: newValue)
                } else {
                    catModel.saveCategory(id: oldValue!, calModel: calModel, keyModel: keyModel)
                    //catModel.categories.sort(by: Helpers.categorySorter())
                }
            }            
            .sheet(item: $editCategory, onDismiss: {
                categoryEditID = nil
                
                if calModel.categoryFilterWasSetByCategoryPage {
                    calModel.sCategories.removeAll()
                    calModel.categoryFilterWasSetByCategoryPage = false
                }
            }) { cat in
                CategoryOverViewWrapperIpad(category: cat, calModel: calModel, catModel: catModel)
                    #if os(macOS)
                    .presentationSizing(.page)
                    #endif

//                CategoryView(category: cat, editID: $categoryEditID)
//                    #if os(macOS)
//                    .frame(minWidth: 500, minHeight: 700)
//                    .presentationSizing(.fitted)
//                    #else
//                    .presentationSizing(.page) // big sheet
//                    //.presentationSizing(.fitted) // small sheet - resizable - doesn't work on iOS
//                    //.presentationSizing(.form) // seems to be the same as a regular sheet
//                    #endif
            }
            #if os(macOS)
            .sheet(isPresented: $showReorderList) {
                StandardContainer(.plainList) {
                    listForPhoneAndMacSortContent
                } header: {
                    SheetHeader(title: "Drag To Reorder", close: { showReorderList = false })
                }
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            }
            #endif
            .onChange(of: AppSettings.shared.categorySortMode) {
                catModel.categories.sort(by: Helpers.categorySorter())
            }
            .onChange(of: sortOrder) { _, sortOrder in
                catModel.categories.sort(using: sortOrder)
            }
            .onChange(of: groupEditID) { oldValue, newValue in
                if let newValue {
                    editGroup = catModel.getCategoryGroup(by: newValue)
                } else {
                    catModel.saveCategoryGroup(id: oldValue!)
                }
            }
            
            .sheet(item: $editGroup, onDismiss: {
                groupEditID = nil
            }, content: { group in
                CategoryGroupOverViewWrapperIpad(group: group, calModel: calModel, catModel: catModel)
                
                //CategoryGroupEditView(group: group, editID: $groupEditID)
                #if os(macOS)
                    .frame(minWidth: 500, minHeight: 700)
                    .presentationSizing(.fitted)
                #endif
            })
        }
    }
    
    
//    func sortBy(comparator: KeyPathComparator<CBCategory>) {
//        let keyPath = comparator.keyPath
//        let isForwardSort = comparator.order == .forward
//        
//        if keyPath == \CBCategory.title {
//            if isForwardSort {
//                return catModel.categories.sort { ($0.title).lowercased() < ($1.title).lowercased() }
//            } else {
//                return catModel.categories.sort { ($0.title).lowercased() > ($1.title).lowercased() }
//            }
//        } else {
//            return catModel.categories.sort { $0.listOrder.sortOrder < $1.listOrder.sortOrder }
//        }
//    }
    
    #if os(macOS)
    @ToolbarContentBuilder
    func macToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            HStack {
                Button {
                    categoryEditID = UUID().uuidString
                } label: {
                    Image(systemName: "plus")
                }
                .toolbarBorder()
                
                ToolbarNowButton()
                ToolbarRefreshButton()
                    .toolbarBorder()
                CategorySortMenu(displayStyle: .inlineWithMenu)
                    .toolbarBorder()
                    .help("This will defined the order of categories on transactions and within the category selection sheets")
                
                if AppSettings.shared.categorySortMode == .listOrder {
                    Button("Reorder") {
                        showReorderList = true
                    }
                    .toolbarBorder()
                }
            }
        }
        
        ToolbarItem(placement: .principal) {
            ToolbarCenterView(enumID: .categories)
        }
        ToolbarItem {
            Spacer()
        }
    }
    #endif
    
    var macTable: some View {
        Table(filteredCategories, selection: $categoryEditID, sortOrder: $sortOrder, columnCustomization: $columnCustomization) {
            TableColumn("Color / Symbol") { cat in
                if let emoji = cat.emoji {
                    Image(systemName: emoji)
                        .foregroundStyle(cat.color)
                        .frame(minWidth: labelWidth, alignment: .center)
                        .maxViewWidthObserver()
                } else {
                    Circle()
                        .fill(cat.color)
                        .frame(width: 12, height: 12)
                }
            }
            .width(min: 20, ideal: 30, max: 50)
            .customizationID("symbol")
            
            TableColumn("Title", value: \.title) { cat in
                Text(cat.title)
                    .schemeBasedForegroundStyle()
            }
            .customizationID("title")
            
            TableColumn("Budget", value: \.amount.specialDefaultIfNil) { cat in
                Text(cat.amount?.currencyWithDecimals() ?? "-")
            }
            .customizationID("budget")
            
            TableColumn("Custom Order", value: \.listOrder.specialDefaultIfNil) { cat in
                if let listOrder = cat.listOrder {
                    Text("\(listOrder)")
                } else {
                    Text("N/A")
                }
            }
            .customizationID("listOrder")                        
        }
        .clipped()
    }    
    //#endif
    
    #if os(iOS)
    @ToolbarContentBuilder
    func phoneToolbar() -> some ToolbarContent {
        //ToolbarItem(placement: .topBarLeading) { CategorySortMenu() }
        //ToolbarSpacer(.fixed, placement: .topBarLeading)
        ToolbarItem(placement: .topBarLeading) { moreMenu }
                        
        ToolbarItem(placement: .topBarTrailing) { ToolbarLongPollButton() }
                
        //ToolbarSpacer(.fixed, placement: .topBarTrailing)
        ToolbarItem(placement: .topBarTrailing) { ToolbarRefreshButton() }
        ToolbarItem(placement: .topBarTrailing) { newCategoryButton }
        //ToolbarSpacer(.fixed, placement: .topBarTrailing)
//        ToolbarItem(placement: .topBarTrailing) { moreMenu }
    }
    #endif
    
//    
//    var newButton: some View {
//        Button {
//            categoryEditID = UUID().uuidString
//        } label: {
//            Image(systemName: "plus")
//        }
//        .tint(.none)
//    }
//    
    var moreMenu: some View {
        Menu {
            CategorySortMenu(displayStyle: .inlineWithMenu)
            
            Section("Display Mode") {
                Toggle(isOn: $categoryIndicatorAsSymbol) {
                    Text("Use Symbols")
                }
            }
            
        } label: {
            Image(systemName: "ellipsis")
        }
        .tint(.none)
    }
    
    
    var listForPhoneAndMacSort: some View {
        List {
            listForPhoneAndMacSortContent
        }
        .listStyle(.plain)
    }
    
    
    @ViewBuilder
    var listForPhoneAndMacSortContent: some View {
        Section("Category Groups") {
            ForEach(filteredCategoryGroups) { group in
                NavigationLink(value: group) {
                    categoryGroupLine(group: group)
                }
            }
        }
        
        Section("My Categories") {
            ForEach(filteredCategories) { cat in
                NavigationLink(value: cat) {
                    line(for: cat)
                }
            }
            .if(AppSettings.shared.categorySortMode == .listOrder) {
                $0.onMove(perform: move)
            }
        }
        
        Section("Special Categories") {
            ForEach(filteredSpecialCategories) { cat in
                NavigationLink(value: cat) {
                    line(for: cat)
                }
            }
        }
        
    }
    
    
    @ViewBuilder
    var padList: some View {
//        List(selection: $groupEditID) {
//            Section("Category Groups") {
//                ForEach(filteredCategoryGroups) { group in
//                    NavigationLink(value: group) {
//                        categoryGroupLine(group: group)
//                    }
//                }
//            }
//        }
//        .listStyle(.plain)
//        
        List {
            Section("Category Groups") {
                ForEach(filteredCategoryGroups) { group in
                    categoryGroupLine(group: group)
                        .contentShape(.rect)
                        .onTapGesture {
                            groupEditID = group.id
                        }
                }
            }
            Section("Categories") {
                ForEach(filteredCategories) { cat in
                    line(for: cat)
                        .onTapGesture {
                            categoryEditID = cat.id
                        }
                }
            }
            
            Section("Special Categories") {
                ForEach(filteredSpecialCategories) { cat in
                    line(for: cat)
                        .onTapGesture {
                            categoryEditID = cat.id
                        }
                }
            }
        }
        .listStyle(.plain)
    }
    
    @ViewBuilder
    func line(for cat: CBCategory) -> some View {
        Label {
            VStack(alignment: .leading) {
                HStack {
                    Text(cat.title)
                    if cat.isHidden { Image(systemName: "eye.slash") }
                    
                    Spacer()
                    Text(cat.amount?.currencyWithDecimals() ?? "-")
                }
            }
        } icon: {
            StandardCategorySymbol(cat: cat, labelWidth: labelWidth)
        }
        #if os(macOS)
        .selectionDisabled()
        #endif
    }
    
    @State private var showAddNewDialog = false
    var newCategoryButton: some View {
        Button {
            showAddNewDialog = true
        } label: {
            Image(systemName: "plus")
        }
        .tint(.none)
        .confirmationDialog("Add New", isPresented: $showAddNewDialog) {
            Button("Category") {
                let newId = UUID().uuidString
                
                /// On iPhone, push the details page to the nav, which will auto-open the edit sheet.
                if AppState.shared.isIphone {
                    let newCat = catModel.getCategory(by: newId)
                    navPath.append(newCat)
                } else {
                    /// On iPad, trigger the details sheet to open, which will then open the edit sheet.
                    //#error("On Ipad, when closing the edit sheet, the details sheet freaks out.")
                    categoryEditID = newId
                }
            }
            
            Button("Group") {
                let newId = UUID().uuidString
                
                /// On iPhone, push the details page to the nav, which will auto-open the edit sheet.
                if AppState.shared.isIphone {
                    let newGroup = catModel.getCategoryGroup(by: newId)
                    navPath.append(newGroup)
                } else {
                    /// On iPad, trigger the details sheet to open, which will then open the edit sheet.
                    //#error("On Ipad, when closing the edit sheet, the details sheet freaks out.")
                    groupEditID = newId
                }
            }
        }
    }
    
    
    @ViewBuilder func categoryGroupLine(group: CBCategoryGroup) -> some View {
        Label {
            VStack(alignment: .leading) {
                HStack {
                    Text(group.title)
                    Spacer()
                    Text(group.amount?.currencyWithDecimals() ?? "-")
                }
            }
        } icon: {
            Circle()
                .fill(AngularGradient(gradient: Gradient(stops: getReversedColors(group.categories)), center: .center))
                .frame(width: 20, height: 20)
        }
        
    }
    
//    var sortMenu: some View {
//        Menu {
//            Button {
//                categorySortMode = .title
//                withAnimation {
//                    #if os(macOS)
//                    sortOrder = [KeyPathComparator(\CBCategory.title)]
//                    #else
//                    catModel.categories.sort(by: Helpers.categorySorter())
//                    //catModel.categories.sort { ($0.title).lowercased() < ($1.title).lowercased() }
//                    #endif
//                }
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
//                withAnimation {
//                    #if os(macOS)
//                    sortOrder = [KeyPathComparator(\CBCategory.listOrder.specialDefaultIfNil)]
//                    #else
//                    catModel.categories.sort(by: Helpers.categorySorter())
//                    #endif
//                }
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
//        
//
//    }
//    
    
//    func move(from source: IndexSet, to destination: Int) {
//        print("\(source.map { $0.id }) - \(destination)")
//        print(catModel.categories[source.map { $0.id }.first!].title)
//        catModel.categories.filter { !$0.isNil }.move(fromOffsets: source, toOffset: destination)
////        Task {
////            let listOrderUpdates = await catModel.setListOrders(calModel: calModel)
////            let _ = await funcModel.submitListOrders(items: listOrderUpdates, for: .categories)
////        }
//        
//    }
    
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
    
    
    func move(from source: IndexSet, to destination: Int) {
        /// Create an index map of non-nil items.
        let filteredIndices = catModel.categories.enumerated()
            .filter { !$0.element.isNil && $0.element.appSuiteKey == nil }
            .map { $0.offset }

        print(filteredIndices)
        
        /// Convert filtered indices to original indices.
        guard let
                sourceInFiltered = source.first,
                sourceInFiltered < filteredIndices.count,
                destination <= filteredIndices.count
        else {
            return
        }

        let ogSourceIndex = filteredIndices[sourceInFiltered]
        let ogDestIndex = destination == filteredIndices.count ? catModel.categories.filter { !$0.isNil && $0.appSuiteKey == nil }.count : filteredIndices[destination]

        /// Mutate the original array.
        catModel.categories.move(fromOffsets: IndexSet(integer: ogSourceIndex), toOffset: ogDestIndex)
                
         Task {
             let listOrderUpdates = await catModel.setListOrders(calModel: calModel)
             let _ = await funcModel.submitListOrders(items: listOrderUpdates, for: .categories)
         }
    }
}

