//
//  AdvancedSearchView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/7/25.
//

import SwiftUI

struct AdvancedSearchView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("advancedSearchFilterIsExpanded") private var storedFilterIsExpanded: Bool = true
    @State private var filterIsExpanded: Bool = true
    //@Local(\.colorTheme) var colorTheme    
    
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    
    @Binding var navPath: NavigationPath
    
    
    @State private var searchModel = AdvancedSearchModel()
    @State private var showPayMethodSheet = false
    @State private var showCategorySheet = false
    @State private var showMonthSheet = false
    @State private var showYearSheet = false
    
    @State private var isSearching = false
    @State private var sortOrder: SortOrder = .forward
    @State private var transEditID: String?
    @State private var editTrans: CBTransaction?
    @State private var transDay: CBDay? = CBDay(date: Date())
    
    @State private var fuckYouSwiftuiTableRefreshID: UUID = UUID()
    
    @Namespace var namespace
    
    
    @FocusState private var focusedField: Int?
    
    @State private var searchTerm = ""
    
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
    
    var dateFilterTitle: String {
        if searchModel.cutOffDate == nil && searchModel.beginDate == nil && searchModel.endDate == nil {
            return ""
        } else if searchModel.cutOffDate != nil {
            return searchModel.cutOffDate!.string(to: .monthDayShortYear)
            
        } else if searchModel.beginDate != nil && searchModel.endDate != nil {
            return "\(searchModel.beginDate!.string(to: .monthDayShortYear)) …to… \(searchModel.endDate!.string(to: .monthDayShortYear))"
        }
        return ""
    }
    
    var filterCount: Int {
        return (
            searchModel.categories.count
            + searchModel.payMethods.count
            + searchModel.months.count
            + searchModel.years.count
            + (searchModel.amountType == .all ? 0 : 1)
            + (searchModel.includeExcluded ? 0 : 1)
            + (searchModel.onlyWithPhotos ? 1 : 0)
            + ((searchModel.cutOffDate != nil || (searchModel.beginDate != nil && searchModel.endDate != nil)) ? 1 : 0)
        )
    }
    
//    var searchPrompt: String {
//        focusedField == 0 ? "Search Terms (Separate by comma)" : "Search"
//    }
        
    var body: some View {
        Group {
            #if os(iOS)
            phoneList
            #else
            macTable
            #endif
        }
        #if os(iOS)
        .navigationTitle("Transaction Search")
        .navigationDestination(for: String.self, destination: { dest in
            DatePickerPage(searchModel: searchModel, navPath: $navPath)
        })
        .onShake { resetForm() }
        //.navigationBarTitleDisplayMode(.inline)
        #endif
        .id(fuckYouSwiftuiTableRefreshID)
        
//        .searchable(text: $searchTerm, prompt: searchPrompt)
//        .searchFocused($focusedField, equals: 0)
//        .searchPresentationToolbarBehavior(.avoidHidingContent)
//        .onSubmit(of: .search) {
//            let terms = searchTerm
//                .split(separator: ",")                // split by comma
//                .map { $0.trimmingCharacters(in: .whitespaces) } // trim spaces
//            searchModel.searchTerms.append(contentsOf: terms)
//            searchTerm = ""
//            search()
//        }
        .toolbar {
            #if os(macOS)
            macToolbar()
            #else
            phoneToolbar()
            #endif
        }
        .transactionEditSheetAndLogic(
            transEditID: $transEditID,
            selectedDay: $transDay,
            findTransactionWhere: .constant(.searchResultList)
        )
        .sheet(isPresented: $showPayMethodSheet) {
            MultiPayMethodSheet(payMethods: $searchModel.payMethods, includeHidden: true)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        }
        .sheet(isPresented: $showCategorySheet) {
            MultiCategorySheet(categories: $searchModel.categories, categoryGroup: .constant([]), includeHidden: true)
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
                        if trans.payMethod?.accountType == .credit || trans.payMethod?.accountType == .loan {
                            Text((trans.amount * -1).currencyWithDecimals())
                        } else {
                            Text(trans.amount.currencyWithDecimals())
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
        ToolbarItemGroup(placement: .topBarTrailing) { resetSearchFormButton }
    }
    
    
    var resetSearchFormButton: some View {
        Button("Reset", action: resetForm)
            .schemeBasedForegroundStyle()
    }
    

    @ViewBuilder
    var phoneList: some View {
        
        @Bindable var photoModel = FileModel.shared

        List {
            Section {
                HStack {
                    searchTextField
                    HStack {
                        addSearchTermButton
                        convertToTagButton
                    }
                    .fixedSize(horizontal: true, vertical: true)
                    
                }
                
                if !searchModel.searchTerms.isEmpty {
                    searchTermCluster
                }
                
                Button("Search", action: search)
                    .disabled(!searchModel.isValid())
            } footer: {
                Text("Search by transaction titles, or tags. Touch # to turn the current search term into a tag. Touch + to add the current search term to the search list.")
            }
            
            filterSections
            
            if !calModel.searchedTransactions.isEmpty {
                transactionSummaryLine
            }
                        
            Section {
                Group {
                    if calModel.searchedTransactions.isEmpty {
                        ContentUnavailableView("No Transactions", systemImage: "square.stack.3d.up.slash.fill", description: Text("Choose some filters above and/or enter a search term."))
                    } else {
                        ForEach(calModel.searchedTransactions) { trans in
                            TransactionListLine(trans: trans, withDate: true, withTags: true, withPhotos: true) {
                                self.transEditID = trans.id
                            }
                        }
                    }
                }
                .opacity(isSearching ? 0 : 1)
                .overlay {
                    ProgressView {
                        Text("Searching…")
                    }
                    .tint(.none)
                    .opacity(isSearching ? 1 : 0)
                }
            } header: {
                transactionSectionHeader
            }
        }
    }
    
    
    var searchTextField: some View {
        Group {
            #if os(iOS)
            UITextFieldWrapper(placeholder: "Search Term(s)", text: $searchModel.newSearchTerm, onSubmit: {
                search()
            }, toolbar: {
                KeyboardToolbarView(
                    focusedField: $focusedField,
                    accessoryImage1: "plus",
                    accessoryFunc1: { addSearchTerm() },
                    accessoryImage2: "number",
                    accessoryFunc2: { prependHashtag() }
                )
            })
            .uiTag(1)
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
        .focused($focusedField, equals: 1)
    }
    #endif
    
    
    var addSearchTermButton: some View {
        Button {
            addSearchTerm()
        } label: {
            Image(systemName: "plus")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(searchModel.newSearchTerm.isEmpty)
    }
    
    
    var convertToTagButton: some View {
        Button {
            prependHashtag()
        } label: {
            Image(systemName: "number")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(searchModel.newSearchTerm.isEmpty)
    }
    
    
    var searchTermCluster: some View {
        TagLayout(alignment: .leading, spacing: 10) {
            ForEach(searchModel.searchTerms) { term in
                Button {
                    withAnimation {
                        searchModel.searchTerms.removeAll { $0 == term }
                        calModel.searchedTransactions.removeAll { $0.title.localizedCaseInsensitiveContains(term) }
                    }
                } label: {
                    HStack {
                        Text(term)
                        Image(systemName: "trash")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.gray)
                .focusable(false)
            }
        }
    }
            
    
    @ViewBuilder
    var filterSections: some View {
        Section {
            if filterIsExpanded {
                FilterLine(title: "Categories", value: categoryFilterTitle, showSheet: $showCategorySheet)
                FilterLine(title: "Accounts", value: payMethodFilterTitle, showSheet: $showPayMethodSheet)
            } else {
                Section {
                    Text(filterCount == 0 ? "No filters applied" : "\(filterCount) filter\(filterCount == 1 ? "" : "s") applied")
                        .foregroundStyle(filterCount == 0 ? .gray : .primary)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation { filterIsExpanded.toggle() }
                        }
                }
            }
        } header: {
            filterSectionHeader
        }
        #if os(iOS)
        .listSectionSpacing(5)
        #endif
        
        if filterIsExpanded {
            Section {
                if searchModel.cutOffDate == nil && searchModel.beginDate == nil && searchModel.endDate == nil {
                    FilterLine(title: "Months", value: monthFilterTitle, showSheet: $showMonthSheet)
                    FilterLine(title: "Years", value: yearFilterTitle, showSheet: $showYearSheet)
                }
                    
                cutOffDatePickerAndTypePicker
            }
            #if os(iOS)
            .listSectionSpacing(5)
            #endif
            
            Section {
                amountTypePicker
                excludedToggle
                onlyWithPhotosToggle
            }
            #if os(iOS)
            .listSectionSpacing(5)
            #endif
        }
//        Section {
//            if filterIsExpanded {
//                FilterLine(title: "Categories", value: categoryFilterTitle, showSheet: $showCategorySheet)
//                FilterLine(title: "Accounts", value: payMethodFilterTitle, showSheet: $showPayMethodSheet)
//                FilterLine(title: "Months", value: monthFilterTitle, showSheet: $showMonthSheet)
//                FilterLine(title: "Years", value: yearFilterTitle, showSheet: $showYearSheet)
//                amountTypePicker
//                excludedToggle
//                onlyWithPhotosToggle
//            } else {
//                Text(filterCount == 0 ? "No filters applied" : "\(filterCount) filter\(filterCount == 1 ? "" : "s") applied")
//                    .foregroundStyle(filterCount == 0 ? .gray : .primary)
//                    .contentShape(Rectangle())
//                    .onTapGesture {
//                        withAnimation { filterIsExpanded.toggle() }
//                    }
//            }
//        } header: {
//            filterSectionHeader
//        }
    }
    
    
    var filterSectionHeader: some View {
        HStack {
            HStack {
                Text("Filter")
                Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(filterIsExpanded ? 90 : 0))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation { filterIsExpanded.toggle() }
            }
            Spacer()
        }
        .onAppear { filterIsExpanded = storedFilterIsExpanded }
        .onChange(of: filterIsExpanded) { storedFilterIsExpanded = $1 }
    }
    
    
    @ViewBuilder
    var transactionSummaryLine: some View {
        let sum = calModel.searchedTransactions
            .map({ ($0.payMethod?.accountType == .credit || $0.payMethod?.accountType == .loan) ? $0.amount * -1 : $0.amount })
            .reduce(0.0, +)
        
        Section("Transaction Summary") {
            HStack {
                Text("Total:")
                Spacer()
                Text(sum.currencyWithDecimals())
            }
        }
    }
    
    
    var transactionSectionHeader: some View {
        HStack {
            Text("Transactions")
            Spacer()
            HStack {
                transactionExportCsvButton
                transactionClearResultsButton
                transactionSortButton
            }
            .fixedSize(horizontal: true, vertical: false)
            
        }
    }
    
    
    var transactionSortButton: some View {
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
            Image(systemName: "arrow.up")
                .frame(maxHeight: .infinity)
                .rotationEffect(.degrees(sortOrder == .forward ? 0 : 180))
        }
        .buttonStyle(.borderedProminent)
    }
    
    
    var transactionClearResultsButton: some View {
        Button {
            withAnimation {
                calModel.searchedTransactions.removeAll()
            }
        } label: {
            Text("Clear")
                //.schemeBasedForegroundStyle()
                .frame(maxHeight: .infinity)
                .opacity(isSearching ? 0 : 1)
                .overlay {
                    ProgressView()
                        .opacity(isSearching ? 1 : 0)
                        .tint(.none)
                }
        }
        .buttonStyle(.borderedProminent)
        .disabled(calModel.searchedTransactions.isEmpty)
        
    }
    
    
    var transactionExportCsvButton: some View {
        let rows = calModel.searchedTransactions
            .filter { $0.active && $0.isPermitted }
            .map { $0.convertToCsvRecord() }
        
        func generateCsv() -> URL {
            return Helpers.generateCsv(
                fileName: "Search-Results-\(AppState.shared.todayMonth)-\(AppState.shared.todayDay)-\(AppState.shared.todayYear).csv",
                headers: CBTransaction.getCsvHeaders(),
                rows: rows
            )
        }
            
        return ShareLink(item: generateCsv()) {
            Text("CSV")
                .frame(maxHeight: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .font(.subheadline)
        .disabled(calModel.searchedTransactions.isEmpty)
    }
    
        
    var amountTypePicker: some View {
        Picker(selection: $searchModel.amountType) {
            ForEach(AmountType.allCases) {
                Text($0.prettyValue)
                    .tag($0)
            }
        } label: {
            Text("Amount Type")
        }
    }
    
    
    var excludedToggle: some View {
        Toggle(isOn: $searchModel.includeExcluded) {
            Text("Include Ignored")
        }
    }
    
    
    var onlyWithPhotosToggle: some View {
        Toggle(isOn: $searchModel.onlyWithPhotos) {
            Text("Only with Photos/Files")
        }
    }
    
    
    @ViewBuilder
    var cutOffDatePickerAndTypePicker: some View {
        Button {
            searchModel.months.removeAll()
            searchModel.years.removeAll()
            navPath.append("Date_picker")
        } label: {
            HStack {
                Text("Date Range")
                    .schemeBasedForegroundStyle()
                Spacer()
                
                HStack(spacing: 4) {
                    
                    Text(dateFilterTitle)
                        .schemeBasedForegroundStyle()
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                }
            }
        }
    }
    
    
    
    // MARK: - Functions
    func prependHashtag() {
        //if !searchModel.newSearchTerm.isEmpty {
            searchModel.newSearchTerm = "#" + searchModel.newSearchTerm
        //}
    }
    
    
    func addSearchTerm() {
        if !searchModel.newSearchTerm.isEmpty {
            addOrFind(searchTerm: searchModel.newSearchTerm)
            searchModel.newSearchTerm = ""
        }
    }
    
    
    func search() {
        addSearchTerm()
        focusedField = nil
        
        if searchModel.isValid() {
            Task {
                searchModel.newSearchTerm = ""
                calModel.searchedTransactions.removeAll()
                isSearching = true
                await search(calModel: calModel, sortOrder: sortOrder)
                isSearching = false
            }
        } else {
            let config = AlertConfig(title: "No Search Criteria", subtitle: "Please enter a search term or select some filters.", symbol: .init(name: "exclamationmark.magnifyingglass", color: .orange))
            
            AppState.shared.showAlert(config: config)
        }
    }
    
    
    func addOrFind(searchTerm: String) {
        let cleanTerm = searchTerm.lowercased().trimmingCharacters(in: .whitespaces)
        let exists = !searchModel.searchTerms.filter { $0 == cleanTerm }.isEmpty
        if !exists { searchModel.searchTerms.append(cleanTerm) }
    }
    
    
    func resetForm() {
        withAnimation {
            calModel.searchedTransactions.removeAll()
            searchModel.categories.removeAll()
            searchModel.payMethods.removeAll()
            searchModel.months.removeAll()
            searchModel.years.removeAll()
            searchModel.searchTerms.removeAll()
            searchModel.includeExcluded = true
            searchModel.amountType = .all
            searchModel.onlyWithPhotos = false
            searchModel.newSearchTerm = ""
            searchModel.cutOffDate = nil
            searchModel.cutOffDateType = .on
            searchModel.beginDate = nil
            searchModel.endDate = nil
        }
    }
    
    
    @MainActor
    func search(calModel: CalendarModel, sortOrder: SortOrder) async {
        print("-- \(#function)")
        LogManager.log()
        
        let model = RequestModel(requestType: "new_advanced_search", model: searchModel)
        typealias ResultResponse = Result<Array<CBTransaction>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            if let model {
                if sortOrder == .forward {
                    calModel.searchedTransactions = model.sorted { $0.date ?? Date() > $1.date ?? Date() }
                } else {
                    calModel.searchedTransactions = model.sorted { $0.date ?? Date() < $1.date ?? Date() }
                }
            }
            
        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("calModel fetchFrom Server Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch transactions.")
            }
        }
    }
}





fileprivate struct FilterLine: View {
    var title: String
    var value: String
    @Binding var showSheet: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .schemeBasedForegroundStyle()
            Spacer()
                            
            Button {
                showSheet = true
            } label: {
                HStack(spacing: 4) {
                    Text(value)
                        .schemeBasedForegroundStyle()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                }
            }
        }
    }
}


fileprivate struct DatePickerPage: View {
    @Bindable var searchModel: AdvancedSearchModel
    @Binding var navPath: NavigationPath
    @State private var dateRangeType: DateRangeType? = nil
    
    enum DateRangeType {
        case single, range
    }
            
    var body: some View {
        List {
            if let dateRangeType {
                switch dateRangeType {
                case .single:
                    singleDateSection
                case .range:
                    dateRangeSection
                }
            }
                        
            Section("Options") {
                optionButtons
            }
        }
        .navigationTitle("Search Date Filter")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            if searchModel.beginDate != nil && searchModel.endDate != nil {
                dateRangeType = .range
            } else if searchModel.cutOffDate != nil {
                dateRangeType = .single
            }
        }
    }
    
    
    @ViewBuilder
    var optionButtons: some View {
        Button("Search a Date Range") {
            searchModel.cutOffDate = nil
            searchModel.beginDate = Date()
            searchModel.endDate = Date()
            dateRangeType = .range
        }
        .disabled(dateRangeType == .range)
        
        Button("Search a Specific Date") {
            searchModel.cutOffDate = Date()
            searchModel.beginDate = nil
            searchModel.endDate = nil
            dateRangeType = .single
        }
        .disabled(dateRangeType == .single)
        
        Button("Clear Date Filter") {
            searchModel.cutOffDate = nil
            searchModel.beginDate = nil
            searchModel.endDate = nil
            dateRangeType = nil
            navPath.removeLast()
        }
        .disabled(dateRangeType == nil)
        .tint(.red)
    }
        
    
    var singleDateSection: some View {
        Section {
            HStack {
                cutOffDateTypePicker
                DatePicker("", selection: $searchModel.cutOffDate ?? Date(), displayedComponents: [.date])
                    .labelsHidden()
            }
        } header: {
            Text("Single Date")
        } footer: {
            Text("Only search for transactions that come before, on, or after this date.")
        }
    }
    
    
    var dateRangeSection: some View {
        Section {
            HStack {
                DatePicker("", selection: $searchModel.beginDate ?? Date(), displayedComponents: [.date])
                    .labelsHidden()
                
                Text("…to…")
                    .frame(maxWidth: .infinity)
                
                DatePicker("", selection: $searchModel.endDate ?? Date(), displayedComponents: [.date])
                    .labelsHidden()
            }
        } header: {
            Text("Date Range")
        } footer: {
            Text("Only search for transactions that fall within this date range.")
        }
    }
    
    
    var cutOffDateTypePicker: some View {
        Picker("", selection: $searchModel.cutOffDateType) {
            ForEach(BeforeAfterOrOn.allCases, id: \.self) {
                Text($0.rawValue.capitalized)
                    .tag($0)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
    }
}
