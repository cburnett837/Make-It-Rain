//
//  PaymentMethodsView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/20/24.
//

import SwiftUI
import Algorithms

struct CategoriesTable: View {
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    @AppStorage("categorySortMode") var categorySortMode: CategorySortMode = .title
    
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    @Environment(EventModel.self) private var eventModel
    
    @State private var searchText = ""
    
    @State private var deleteCategory: CBCategory?
    @State private var editCategory: CBCategory?
    @State private var categoryEditID: CBCategory.ID?
    
    #if os(macOS)
    @AppStorage("categoryTableColumnOrder") private var columnCustomization: TableColumnCustomization<CBCategory>
    @State private var showReorderList = false
    #endif
    
    @State private var sortOrder = [KeyPathComparator(\CBCategory.title)]
    @State private var labelWidth: CGFloat = 20.0
    @State private var showDeleteAlert = false
    
    var filteredCategories: [CBCategory] {
        catModel.categories
            .filter { searchText.isEmpty ? !$0.title.isEmpty : $0.title.localizedStandardContains(searchText) }
            //.sorted { $0.title.lowercased() < $1.title.lowercased() }
            //.sorted { $0.listOrder ?? 0 < $1.listOrder ?? 0 }
            .sorted {
                categorySortMode == .title
                ? ($0.title).lowercased() < ($1.title).lowercased()
                : $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000
            }
        
    }
    
    var body: some View {
        //let _ = Self._printChanges()
        @Bindable var catModel = catModel
        
        Group {
            if !catModel.categories.isEmpty {
                Group {
                    #if os(macOS)
                    macTable
                    #else
                    listForPhoneAndMacSort
                    #endif
                }
                .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
            } else {
                ContentUnavailableView("No Categories", systemImage: "books.vertical", description: Text("Click the plus button above to add a category."))
                    #if os(iOS)
                    .standardBackground()
                    #endif
            }
        }
        #if os(iOS)
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
        #endif
        /// There seems to be a bug in SwiftUI `Table` that prevents the view from refreshing when adding a new category, and then trying to edit it.
        /// When I add a new category, and then update `model.categories` with the new ID from the server, the table still contains an ID of 0 on the newly created category.
        /// Setting this id forces the view to refresh and update the relevant category with the new ID.
        .id(catModel.fuckYouSwiftuiTableRefreshID)
        .navigationBarBackButtonHidden(true)
//        .task {
//            let categorySortMode = CategorySortMode.fromString(UserDefaults.standard.string(forKey: "categorySortMode") ?? "")
//                                
//            catModel.categories.sort {
//                categorySortMode == .title
//                ? ($0.title).lowercased() < ($1.title).lowercased()
//                : $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000
//            }
//        }
        .toolbar {
            #if os(macOS)
            macToolbar()
            #else
            phoneToolbar()
            #endif
        }
        .searchable(text: $searchText) {
            #if os(macOS)
            let relevantTitles: Array<String> = catModel.categories
                .compactMap { $0.title }
                .uniqued()
                .filter { $0.localizedStandardContains(searchText) }
                    
            ForEach(relevantTitles, id: \.self) { title in
                Text(title)
                    .searchCompletion(title)
            }
            #endif
        }
        .onChange(of: categoryEditID) { oldValue, newValue in
            if let newValue {
                editCategory = catModel.getCategory(by: newValue)
            } else {
                catModel.saveCategory(id: oldValue!, calModel: calModel)
            }
        }
        
        #if os(iOS)
        .sheet(item: $editCategory, onDismiss: {
            categoryEditID = nil
        }, content: { cat in
            CategoryView(category: cat, catModel: catModel, calModel: calModel, keyModel: keyModel, editID: $categoryEditID)
        })
        #else
        .sheet(item: $editCategory, onDismiss: {
            categoryEditID = nil
        }, content: { cat in
            CategoryView(category: cat, catModel: catModel, calModel: calModel, keyModel: keyModel, editID: $categoryEditID)
                .frame(minWidth: 500, minHeight: 700)
                .presentationSizing(.fitted)
        })
        #endif
        
        #if os(macOS)
        .sheet(isPresented: $showReorderList) {
            VStack {
                SheetHeader(title: "Drag To Reorder", close: { showReorderList = false })
                    .padding()
                listForPhoneAndMacSort
            }
            .frame(minWidth: 300, minHeight: 500)
            .presentationSizing(.fitted)
        }
        #endif
        
        .onChange(of: sortOrder) { _, sortOrder in
            catModel.categories.sort(using: sortOrder)
        }
                
        .confirmationDialog("Delete \"\(deleteCategory == nil ? "N/A" : deleteCategory!.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive) {
                if let deleteCategory = deleteCategory {
                    Task {                                                
                        await catModel.delete(deleteCategory, andSubmit: true, calModel: calModel, keyModel: keyModel, eventModel: eventModel)
                    }
                }
            }
            
            Button("No", role: .cancel) {
                deleteCategory = nil
                showDeleteAlert = false
            }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(deleteCategory == nil ? "N/A" : deleteCategory!.title)\"?\nThis will not delete any associated transactions.")
            #else
            Text("This will not delete any associated transactions.")
            #endif
        })
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { oldValue, newValue in
            !oldValue && newValue
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
    
    var macTable: some View {
        Table(filteredCategories, selection: $categoryEditID, sortOrder: $sortOrder, columnCustomization: $columnCustomization) {
            TableColumn("Title", value: \.title) { cat in
                Text(cat.title)
            }
            .customizationID("title")
            
            TableColumn("Budget", value: \.amount.specialDefaultIfNil) { cat in
                Text(cat.amount?.currencyWithDecimals(useWholeNumbers ? 0 : 2) ?? "-")
            }
            .customizationID("budget")
            
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
            .customizationID("symbol")
            
            
            TableColumn("Custom Order", value: \.listOrder.specialDefaultIfNil) { cat in
                if let listOrder = cat.listOrder {
                    Text("\(listOrder)")
                } else {
                    Text("N/A")
                }
            }
            .customizationID("listOrder")
            
            TableColumn("Delete") { cat in
                Button {
                    deleteCategory = cat
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .width(min: 20, ideal: 30, max: 50)
        }
        .clipped()
    }
    #endif
    
    #if os(iOS)
    @ToolbarContentBuilder
    func phoneToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !AppState.shared.isIpad {
                Button {
                    dismiss() //NavigationManager.shared.selection = nil // NavigationManager.shared.navPath.removeLast()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            } else {
                HStack {
                    ToolbarRefreshButton()
                    Button {
                        categoryEditID = UUID().uuidString
                    } label: {
                        Image(systemName: "plus")
                    }
                    
                    sortMenu
                    //.disabled(catModel.isThinking)
                }
            }
        }
        
        if !AppState.shared.isIpad {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    sortMenu
                    ToolbarRefreshButton()
                    Button {
                        categoryEditID = UUID().uuidString
                    } label: {
                        Image(systemName: "plus")
                    }
                    //.disabled(catModel.isThinking)
                }
            }
        }
    }
    #endif
    
    var listForPhoneAndMacSort: some View {
        List(selection: $categoryEditID) {
            ForEach(filteredCategories) { cat in
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        Text(cat.title)
                        Text(cat.amount?.currencyWithDecimals(useWholeNumbers ? 0 : 2) ?? "-")
                            .foregroundStyle(.gray)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    if let emoji = cat.emoji {
                        Image(systemName: emoji)
                            .foregroundStyle(cat.color.gradient)
                            .frame(minWidth: labelWidth, alignment: .center)
                            .maxViewWidthObserver()
                    } else {
                        Circle()
                            .fill(cat.color.gradient)
                            .frame(width: 12, height: 12)
                    }
                }
                #if os(iOS)
                .standardRowBackgroundWithSelection(id: cat.id, selectedID: categoryEditID)
                .swipeActions(allowsFullSwipe: false) {
                    Button {
                        deleteCategory = cat
                        showDeleteAlert = true
                    } label: {
                        Label {
                            Text("Delete")
                        } icon: {
                            Image(systemName: "trash")
                        }
                    }
                    .tint(.red)
                }
                #else
                .selectionDisabled()
                #endif
            }
            .if(categorySortMode == .listOrder) {
                $0.onMove(perform: move)
            }
            
            
        }
        .listStyle(.plain)
        #if os(iOS)
        .standardBackground()
        #endif
    }
    
    
    var sortMenu: some View {
        Menu {
            Button {
                categorySortMode = .title
                withAnimation {
                    #if os(macOS)
                    sortOrder = [KeyPathComparator(\CBCategory.title)]
                    #else
                    catModel.categories.sort { ($0.title).lowercased() < ($1.title).lowercased() }
                    #endif
                }
            } label: {
                Label {
                    Text("Title")
                } icon: {
                    Image(systemName: categorySortMode == .title ? "checkmark" : "textformat.abc")
                }
            }
            
            Button {
                categorySortMode = .listOrder
                withAnimation {
                    #if os(macOS)
                    sortOrder = [KeyPathComparator(\CBCategory.listOrder.specialDefaultIfNil)]
                    #else
                    catModel.categories.sort { $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000 }
                    #endif
                }
            } label: {
                Label {
                    Text("Custom")
                } icon: {
                    Image(systemName: categorySortMode == .listOrder ? "checkmark" : "list.bullet")
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }

    }
    
    func move(from source: IndexSet, to destination: Int) {
        catModel.categories.move(fromOffsets: source, toOffset: destination)
        catModel.setListOrders(calModel: calModel)
    }
}

