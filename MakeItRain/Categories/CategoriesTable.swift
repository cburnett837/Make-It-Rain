//
//  PaymentMethodsView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/20/24.
//

import SwiftUI
import Algorithms

struct CategoriesTable: View {
    //@Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @Local(\.useWholeNumbers) var useWholeNumbers
    @AppStorage("categorySortMode") var categorySortMode: SortMode = .title
    
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    @Environment(EventModel.self) private var eventModel
    
    @State private var searchText = ""
    @State private var editCategory: CBCategory?
    @State private var categoryEditID: CBCategory.ID?

    @AppStorage("categoryTableColumnOrder") private var columnCustomization: TableColumnCustomization<CBCategory>
    #if os(macOS)
    
    @State private var showReorderList = false
    #endif
    
    @State private var sortOrder = [KeyPathComparator(\CBCategory.title)]
    @State private var labelWidth: CGFloat = 20.0
    
    var filteredCategories: [CBCategory] {
        catModel.categories
            .filter { !$0.isNil }
            .filter { searchText.isEmpty ? !$0.title.isEmpty : $0.title.localizedCaseInsensitiveContains(searchText) }
            /// NOTE: Sorting must be done in the task and not in the computed property. If done in the computed property, when reording, they get all messed up.
    }
    
    var body: some View {
        //let _ = Self._printChanges()
        @Bindable var catModel = catModel
        
        Group {
            if !catModel.categories.filter({ !$0.isNil }).isEmpty {
                #if os(macOS)
                macTable
                #else
//                if AppState.shared.isIphone {
//                    listForPhoneAndMacSort
//                } else {
//                    macTable
//                }
                
                if filteredCategories.isEmpty {
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
        .navigationTitle("Categories")
        //.navigationBarTitleDisplayMode(.inline)
        #endif
        #if os(macOS)
        /// There seems to be a bug in SwiftUI `Table` that prevents the view from refreshing when adding a new category, and then trying to edit it.
        /// When I add a new category, and then update `model.categories` with the new ID from the server, the table still contains an ID of 0 on the newly created category.
        /// Setting this id forces the view to refresh and update the relevant category with the new ID.
        .id(catModel.fuckYouSwiftuiTableRefreshID)
        #endif
        .navigationBarBackButtonHidden(true)
        .task {
            /// NOTE: Sorting must be done here and not in the computed property. If done in the computed property, when reording, they get all messed up.
            //let categorySortMode = SortMode.fromString(UserDefaults.standard.string(forKey: "categorySortMode") ?? "")
                                
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
            CategoryView(category: cat, editID: $categoryEditID)
                #if os(macOS)
                .frame(minWidth: 500, minHeight: 700)
                .presentationSizing(.fitted)
                #else
                .presentationSizing(.page) // big sheet
                //.presentationSizing(.fitted) // small sheet - resizable - doesn't work on iOS
                //.presentationSizing(.form) // seems to be the same as a regular sheet
                #endif
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
        
        .onChange(of: sortOrder) { _, sortOrder in
            catModel.categories.sort(using: sortOrder)
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
                sortMenu
                    .toolbarBorder()
                    .help("This will defined the order of categories on transactions and within the category selection sheets")
                
                if categorySortMode == .listOrder {
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
                Text(cat.amount?.currencyWithDecimals(useWholeNumbers ? 0 : 2) ?? "-")
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
        ToolbarItem(placement: .topBarLeading) { CategorySortMenu() }
        ToolbarItem(placement: .topBarTrailing) { ToolbarLongPollButton() }
        ToolbarItem(placement: .topBarTrailing) { ToolbarRefreshButton() }
        ToolbarSpacer(.fixed, placement: .topBarTrailing)
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                categoryEditID = UUID().uuidString
            } label: {
                Image(systemName: "plus")
            }
            .tint(.none)
        }
    }
    #endif
    
    var listForPhoneAndMacSort: some View {
        List(selection: $categoryEditID) {
            listForPhoneAndMacSortContent
        }
        .listStyle(.plain)
    }
    
    
    var listForPhoneAndMacSortContent: some View {
        ForEach(filteredCategories) { cat in
            Label {
                VStack(alignment: .leading) {
                    HStack {
                        Text(cat.title)
                        if cat.isHidden { Image(systemName: "eye.slash") }
                        
                        Spacer()
                        Text(cat.amount?.currencyWithDecimals(useWholeNumbers ? 0 : 2) ?? "-")
                            //.foregroundStyle(.gray)
                            //.font(.caption)
                    }
                }
            } icon: {
                
                StandardCategorySymbol(cat: cat, labelWidth: labelWidth)
                
//                if let emoji = cat.emoji {
//                    Image(systemName: emoji)
//                        .foregroundStyle(cat.color.gradient)
//                        .frame(minWidth: labelWidth, alignment: .center)
//                        .maxViewWidthObserver()
//                } else {
//                    Circle()
//                        .fill(cat.color.gradient)
//                        .frame(width: 12, height: 12)
//                }
            }

//            HStack(alignment: .center) {
//                VStack(alignment: .leading) {
//                    HStack {
//                        Text(cat.title)
//                        if cat.isHidden { Image(systemName: "eye.slash") }
//                    }
//                    Text(cat.amount?.currencyWithDecimals(useWholeNumbers ? 0 : 2) ?? "-")
//                        .foregroundStyle(.gray)
//                        .font(.caption)
//                }
//                
//                Spacer()
//                
//                if let emoji = cat.emoji {
//                    Image(systemName: emoji)
//                        .foregroundStyle(cat.color.gradient)
//                        .frame(minWidth: labelWidth, alignment: .center)
//                        .maxViewWidthObserver()
//                } else {
//                    Circle()
//                        .fill(cat.color.gradient)
//                        .frame(width: 12, height: 12)
//                }
//            }
            #if os(macOS)            
            .selectionDisabled()
            #endif
        }
        .if(categorySortMode == .listOrder) {
            $0.onMove(perform: move)
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
    
    
    func move(from source: IndexSet, to destination: Int) {
        /// Create an index map of non-nil items.
        let filteredIndices = catModel.categories.enumerated()
            .filter { !$0.element.isNil }
            .map { $0.offset }

        /// Convert filtered indices to original indices.
        guard let sourceInFiltered = source.first, sourceInFiltered < filteredIndices.count, destination <= filteredIndices.count else { return }

        let ogSourceIndex = filteredIndices[sourceInFiltered]
        let ogDestIndex = destination == filteredIndices.count ? catModel.categories.count : filteredIndices[destination]

        /// Mutate the original array.
        catModel.categories.move(fromOffsets: IndexSet(integer: ogSourceIndex), toOffset: ogDestIndex)
                
         Task {
             let listOrderUpdates = await catModel.setListOrders(calModel: calModel)
             let _ = await funcModel.submitListOrders(items: listOrderUpdates, for: .categories)
         }
    }
}

