//
//  AdvancedSearchView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/7/25.
//

import SwiftUI

struct AdvancedSearchView: View {
    @Environment(\.dismiss) var dismiss
    
    @Local(\.colorTheme) var colorTheme
    @Local(\.useWholeNumbers) var useWholeNumbers
    
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(EventModel.self) private var eventModel
    
    @State private var searchModel = AdvancedSearchModel()
    @State private var showPayMethodSheet = false
    @State private var showCategorySheet = false
    @State private var showMonthSheet = false
    @State private var showYearSheet = false
    
    @State private var showMissingCriteriaAlert = false
    @State private var isSearching = false
    @State private var sortOrder: SortOrder = .forward
    @State private var transEditID: String?
    @State private var editTrans: CBTransaction?
    @State private var transDay: CBDay? = CBDay(date: Date())
    
    @State private var fuckYouSwiftuiTableRefreshID: UUID = UUID()
    
    @FocusState private var focusedField: Int?
    
    var categoryFilterTitle: String {
        let cats = searchModel.categories
        if cats.isEmpty {
            return ""
            
        } else if cats.count == 1 {
            return cats.first!.title
            
        } else if cats.count == 2 {
            return "\(cats[0].title), \(cats[1].title)"
            
        } else {
            return "\(cats[0].title), \(cats[1].title), \(cats.count - 2)+"
        }
    }
    
    var payMethodFilterTitle: String {
        let meths = searchModel.payMethods
        if meths.isEmpty {
            return ""
            
        } else if meths.count == 1 {
            return meths.first!.title
            
        } else if meths.count == 2 {
            return "\(meths[0].title), \(meths[1].title)"
            
        } else {
            return "\(meths[0].title), \(meths[1].title), \(meths.count - 2)+"
        }
    }
    
    var monthFilterTitle: String {
        let months = searchModel.months
        if months.isEmpty {
            return ""
            
        } else if months.count == 1 {
            return months.first!.name
            
        } else if months.count == 2 {
            return "\(months[0].name), \(months[1].name)"
            
        } else {
            return "\(months[0].name), \(months[1].name), \(months.count - 2)+"
        }
    }
    
    var yearFilterTitle: String {
        let years = searchModel.years
        if years.isEmpty {
            return ""
            
        } else if years.count == 1 {
            return String(years.first!)
            
        } else if years.count == 2 {
            return "\(String(years[0])), \(String(years[1]))"
            
        } else {
            return "\(String(years[0])), \(String(years[1])), \(years.count - 2)+"
        }
    }
        
    var body: some View {
        Group {
            #if os(iOS)
            phoneList
            #else
            macTable
            #endif
        }
        #if os(iOS)
        .navigationTitle("Search")
        //.navigationBarTitleDisplayMode(.inline)
        #endif
        .id(fuckYouSwiftuiTableRefreshID)
        .navigationBarBackButtonHidden(true)
        .task {
            //focusedField = 0
        }
        
        .toolbar {
            #if os(macOS)
            macToolbar()
            #else
            phoneToolbar()
            #endif
        }
                
        .onChange(of: transEditID, { oldValue, newValue in
            print(".onChange(of: transEditID)")
            /// When `newValue` is false, save to the server. We have to use this because `.popover(isPresented:)` has no onDismiss option.
            if oldValue != nil && newValue == nil {
                calModel.saveTransaction(id: oldValue!, day: transDay!, location: .searchResultList, eventModel: eventModel)
            } else {
                editTrans = calModel.getTransaction(by: transEditID!, from: .searchResultList)
            }
        })
        .sheet(item: $editTrans) { trans in
            TransactionEditView(trans: trans, transEditID: $transEditID, day: transDay!, isTemp: false, transLocation: .searchResultList)
                .onDisappear { transEditID = nil }
        }
        
        .sensoryFeedback(.selection, trigger: transEditID) { $1 != nil }
        
        .sheet(isPresented: $showPayMethodSheet) {
            MultiPayMethodSheet(payMethods: $searchModel.payMethods)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        }
        .sheet(isPresented: $showCategorySheet) {
            MultiCategorySheet(categories: $searchModel.categories)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        }
        .sheet(isPresented: $showMonthSheet) {
            MultiMonthSheet(months: $searchModel.months)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        }
        .sheet(isPresented: $showYearSheet) {
            MultiYearSheet(years: $searchModel.years)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        }
        .alert("No Criteria", isPresented: $showMissingCriteriaAlert) {
            Button("Oops") {
                
            }
        }
    }
    
    #if os(macOS)
    @ToolbarContentBuilder
    func macToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            HStack {
                ToolbarNowButton()
                ToolbarRefreshButton()
                    .toolbarBorder()
            }
        }
        
        ToolbarItem(placement: .principal) {
            ToolbarCenterView(enumID: .search)
        }
        ToolbarItem {
            Spacer()
        }
    }
    
    var macTable: some View {
        VStack {
            VStack {
                HStack {
                    Button("Categories") {
                        showCategorySheet = true
                    }
                    Button("Accounts") {
                        showPayMethodSheet = true
                    }
                    Button("Months") {
                        showMonthSheet = true
                    }
                    Button("Years") {
                        showYearSheet = true
                    }
                    
                    TextField("Search Term(s)", text: $searchModel.newSearchTerm)
                        .submitLabel(.search)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            search()
                        }
                    
                    Button("Search", action: search)
                }
                
                if !searchModel.searchTerms.isEmpty {
                    TagLayout(alignment: .leading, spacing: 10) {
                        ForEach(searchModel.searchTerms) { term in
                            Button {
                                withAnimation {
                                    searchModel.searchTerms.removeAll(where: { $0 == term })
                                }
                            } label: {
                                Text(term)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.gray)
                            .focusable(false)
                        }
                    }
                }
            }
            
            
            
            
            
            Table(calModel.searchedTransactions, selection: $transEditID) {
                TableColumn("Title") { trans in
                    Text(trans.title)
                }
                
                TableColumn("Amount") { trans in
                    Group {
                        if trans.payMethod?.accountType == .credit {
                            Text((trans.amount * -1).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                        } else {
                            Text(trans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                        }
                    }
                }
                
                TableColumn("Account") { trans in
                    HStack(spacing: 4) {
                        Circle()
                            .frame(width: 6, height: 6)
                            .foregroundStyle(trans.payMethod?.color ?? .primary)
                        
                        Text(trans.payMethod?.title ?? "")
                    }
                }
                
                TableColumn("Category") { trans in
                    HStack(spacing: 4) {
                        Circle()
                            .frame(width: 6, height: 6)
                            .foregroundStyle(trans.category?.color ?? .primary)
                        
                        Text(trans.category?.title ?? "N/A")
                    }
                }
                
                TableColumn("Date") { trans in
                    Text(trans.date?.string(to: .monthDayShortYear) ?? "N/A")
                }
            }
            .clipped()            
        }
    }
    
    #endif
    
    
    
    #if os(iOS)
    @ToolbarContentBuilder
    func phoneToolbar() -> some ToolbarContent {
//        if !AppState.shared.isIpad {
//            ToolbarItem(placement: .topBarLeading) {
////                Button {
////                    dismiss() //NavigationManager.shared.selection = nil // NavigationManager.shared.navPath.removeLast()
////                } label: {
////                    HStack(spacing: 4) {
////                        Image(systemName: "chevron.left")
////                        Text("Back")
////                    }
////                }
//                
//                Button {
//                    withAnimation {
//                        if sortOrder == .forward {
//                            calModel.searchedTransactions.sort { $0.date ?? Date() < $1.date ?? Date() }
//                            sortOrder = .reverse
//                        } else {
//                            calModel.searchedTransactions.sort { $0.date ?? Date() > $1.date ?? Date() }
//                            sortOrder = .forward
//                        }
//                    }
//                } label: {
//                    Image(systemName: "arrow.up.arrow.down")
//
//                }
//                
//                
//            }
//        }
        
        ToolbarItemGroup(placement: .topBarTrailing) {
            if !calModel.searchedTransactions.isEmpty {
                Button("Clear") {
                    withAnimation {
                        calModel.searchedTransactions.removeAll()
                    }
                }
            }
            
            if searchModel.isValid() {
                Button("Reset") {
                    withAnimation {
                        calModel.searchedTransactions.removeAll()
                        searchModel.categories.removeAll()
                        searchModel.payMethods.removeAll()
                        searchModel.months.removeAll()
                        searchModel.years.removeAll()
                        searchModel.searchTerms.removeAll()
                        searchModel.newSearchTerm = ""
                    }
                }
            }
        }
    }
    
    
    var phoneList: some View {
        List {
            Section {
                Group {
                    #if os(iOS)
                    UITextFieldWrapper(placeholder: "Search Term(s)", text: $searchModel.newSearchTerm, onSubmit: {
                        search()
                    }, toolbar: {
                        KeyboardToolbarView(
                            focusedField: $focusedField,
                            accessoryImage1: "magnifyingglass",
                            accessoryFunc1: { search() },
                            accessoryImage2: "plus",
                            accessoryFunc2: {
                                if !searchModel.newSearchTerm.isEmpty {
                                    addOrFind(searchTerm: searchModel.newSearchTerm)
                                    searchModel.newSearchTerm = ""
                                }
                            }
                        )
                    })
                    .uiTag(0)
                    //.uiTextAlignment(layoutDirection == .leftToRight ? .right : .left)
                    .uiClearButtonMode(.whileEditing)
                    .uiReturnKeyType(.search)
                    //.uiStartCursorAtEnd(false)
                    #else
                    TextField("Search Term(s)", text: $newSearchTerm)
                        .submitLabel(.search)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            search()
                        }
                    #endif
                }
                .focused($focusedField, equals: 0)
                
                if !searchModel.searchTerms.isEmpty {
                    TagLayout(alignment: .leading, spacing: 10) {
                        ForEach(searchModel.searchTerms) { term in
                            Button {
                                withAnimation {
                                    searchModel.searchTerms.removeAll(where: { $0 == term })
                                }
                            } label: {
                                Text(term)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.gray)
                            .focusable(false)
                        }
                    }
                }
                
                Button("Search", action: search)
                    .disabled(!searchModel.isValid())
            }
            Section {
                FilterLine(title: "Categories", value: categoryFilterTitle, showSheet: $showCategorySheet)
                FilterLine(title: "Accounts", value: payMethodFilterTitle, showSheet: $showPayMethodSheet)
                FilterLine(title: "Months", value: monthFilterTitle, showSheet: $showMonthSheet)
                FilterLine(title: "Years", value: yearFilterTitle, showSheet: $showYearSheet)
                
            } header: {
                HStack {
                    Text("Filter")
                    Spacer()
                    
                }
            }
            
            if !calModel.searchedTransactions.isEmpty {
                let sum = calModel.searchedTransactions
                    .map({ $0.payMethod?.accountType == .credit ? $0.amount * -1 : $0.amount })
                    .reduce(0.0, +)
                
                Section("Transaction Summary") {
                    HStack {
                        Text("Total:")
                        Spacer()
                        Text(sum.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                    }
                    
                }
            }
                        
            Section {
                Group {
                    if calModel.searchedTransactions.isEmpty {
                        ContentUnavailableView("No Transactions", systemImage: "square.stack.3d.up.slash.fill", description: Text("Choose some filters above and/or enter a search term."))
                    } else {
                        ForEach(calModel.searchedTransactions) { trans in
                            TransactionListLine(trans: trans, withDate: true)
                                .onTapGesture {
                                    //self.transDay = day
                                    self.transEditID = trans.id
                                }
                        }
                    }
                }
                .opacity(isSearching ? 0 : 1)
                .overlay {
                    Text("Searching…")
                        .opacity(isSearching ? 1 : 0)
                }
            } header: {
                HStack {
                    Text("Transactions")
                    Spacer()
                    
                    Button {
                        withAnimation {
                            if sortOrder == .forward {
                                calModel.searchedTransactions.sort { $0.date ?? Date() < $1.date ?? Date() }
                                sortOrder = .reverse
                            } else {
                                calModel.searchedTransactions.sort { $0.date ?? Date() > $1.date ?? Date() }
                                sortOrder = .forward
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.caption)
                    }
                    
                }
            }
        }
    }
    
    #endif
    
    
    func search() {
        if !searchModel.newSearchTerm.isEmpty {
            addOrFind(searchTerm: searchModel.newSearchTerm)
            searchModel.newSearchTerm = ""
        }
        focusedField = nil
        
        if searchModel.isValid() {
            Task {
                calModel.searchedTransactions.removeAll()
                isSearching = true
                await calModel.advancedSearch(model: searchModel)
                isSearching = false
            }
        } else {
            showMissingCriteriaAlert = true
        }
    }
    
    func addOrFind(searchTerm: String) {
        let exists = !searchModel.searchTerms.filter { $0 == searchTerm }.isEmpty
        if !exists { searchModel.searchTerms.append(searchTerm) }
    }
}





fileprivate struct FilterLine: View {
    var title: String
    var value: String
    @Binding var showSheet: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
                            
            Button {
                showSheet = true
            } label: {
                HStack(spacing: 4) {
                    Text(value)
                    Image(systemName: "chevron.right")
                }
            }
        }
    }
}
