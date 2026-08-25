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
    @Environment(AppStore.self) private var store
    
    @Binding var navPath: NavigationPath
    //@State private var navPath = NavigationPath()

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
    
    enum CategoryListSelection: Hashable {
        case group(CBCategoryGroup.ID)
        case category(CBCategory.ID)
    }
    
    @State private var selection: CategoryListSelection?
    
    var body: some View {
        //let _ = Self._printChanges()
        @Bindable var catModel = catModel
        //NavigationStack(path: $navPath) {
            VStack {
                if !catModel.categories.filter({ !$0.isNil }).isEmpty {
                    #if os(macOS)
                    macTable
                    #else
                    if filteredCategories.isEmpty && filteredCategoryGroups.isEmpty {
                        ContentUnavailableView("No categories found", systemImage: "exclamationmark.magnifyingglass")
                    } else {
                        listForPhoneAndMacSort
                    }
                    #endif
                } else {
                    ContentUnavailableView("No Categories", systemImage: "books.vertical", description: Text("Click the plus button above to add a category."))
                }
            }
            .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
            #if os(iOS)
            .navigationTitle("Categories\(AppState.shared.devMode ? " (Dev)" : "")")
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
                catModel.categories.sort(by: Helpers.categorySorter())
            }
            .toolbar {
                #if os(macOS)
                macToolbar()
                #else
                phoneToolbar()
                #endif
            }
            .searchable(text: $searchText)
            .onChange(of: selection) { _, newValue in
                switch newValue {
                case .group(let id):
                    groupEditID = id

                case .category(let id):
                    categoryEditID = id

                case nil:
                    break
                }
            }
            .categoryGroupEditSheetAndLogic(editId: $groupEditID) { didSave in
                selection = nil
                
            }
            .categoryEditSheetAndLogic(editId: $categoryEditID) { didSave in
                selection = nil
                if store.categoryFilterWasSetByCategoryPage {
                    calModel.sCategories.removeAll()
                    store.categoryFilterWasSetByCategoryPage = false
                }
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
    }
    
        
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
                        
        ToolbarItem(placement: .topBarTrailing) { ToolbarLongPollButton() }
                
        //ToolbarSpacer(.fixed, placement: .topBarTrailing)
        ToolbarItem(placement: .topBarTrailing) { ToolbarRefreshButton() }
        ToolbarItem(placement: .topBarTrailing) { newCategoryButton }
        ToolbarItem(placement: .topBarTrailing) { moreMenu }
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
        List(selection: $selection) {
            listForPhoneAndMacSortContent
        }
        .listStyle(.plain)
    }
    
    
    @ViewBuilder
    var listForPhoneAndMacSortContent: some View {
        Section("Category Groups") {
            ForEach(filteredCategoryGroups) { group in
                line(for: group)
                    .tag(CategoryListSelection.group(group.id))
            }
        }
        
        Section("Categories") {
            ForEach(filteredCategories) { cat in
                line(for: cat)
                    .tag(CategoryListSelection.category(cat.id))
            }
            .if(AppSettings.shared.categorySortMode == .listOrder) {
                $0.onMove(perform: move)
            }
        }
    }
    
    
    @ViewBuilder
    func line(for cat: CBCategory) -> some View {
        Label {
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(cat.title)
                        Text(cat.type.description)
                            .foregroundStyle(.secondary)
                            .font(.caption2)
                    }
                    
                    if cat.isHidden { Image(systemName: "eye.slash") }
                    
                    Spacer()
                    let isPartOfGroup = catModel.groupedCategoryIds.contains(cat.id)
                    if isPartOfGroup {
                        Text("-")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(cat.amount?.currencyWithDecimals() ?? "-")
                    }
                    
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
                categoryEditID = UUID().uuidString
            }
            
            Button("Group") {
                groupEditID = UUID().uuidString
            }
        }
    }
    
    
    @ViewBuilder
    func line(for group: CBCategoryGroup) -> some View {
        Label {
            VStack(alignment: .leading) {
                HStack {
                    Text(group.title)
                    Spacer()
                    Text(group.amount?.currencyWithDecimals() ?? "-")
                }
            }
        } icon: {
            let colors = group.categories.filter({ $0.active }).sorted(by: Helpers.categorySorter()).map { $0.color }
            GradientCircleDot(colors: colors)
        }
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


struct CategoryLine: View {
    @Environment(CategoryModel.self) private var catModel

    var category: CBCategory
    var labelWidth: Double
    var withBudget: Bool = true
    
    var body: some View {
        Label {
            VStack(alignment: .leading) {
                HStack {
                    Text(category.title)
                    if category.isHidden { Image(systemName: "eye.slash") }
                    
                    Spacer()
                    
                    if withBudget {
                        let isPartOfGroup = catModel.groupedCategoryIds.contains(category.id)
                        if isPartOfGroup {
                            Text("-")
                                .foregroundStyle(.secondary)
                        } else {
                            Text(category.amount?.currencyWithDecimals() ?? "-")
                        }
                    }                    
                }
            }
        } icon: {
            StandardCategorySymbol(cat: category, labelWidth: labelWidth)
        }
        #if os(macOS)
        .selectionDisabled()
        #endif
    }
}

struct CategoryGroupLine: View {
    var group: CBCategoryGroup
    var withBudget: Bool = true
    
    var body: some View {
        Label {
            VStack(alignment: .leading) {
                HStack {
                    Text(group.title)
                    Spacer()
                    if withBudget {
                        Text(group.amount?.currencyWithDecimals() ?? "-")
                    }
                    
                }
            }
        } icon: {
            let colors = group.categories.filter({ $0.active }).sorted(by: Helpers.categorySorter()).map { $0.color }
            GradientCircleDot(colors: colors)
        }
    }
}
