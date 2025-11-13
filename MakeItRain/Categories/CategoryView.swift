//
//  CategoryViewMac.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/21/24.
//

import SwiftUI
import Charts


struct CategoryView: View {
    @Local(\.useWholeNumbers) var useWholeNumbers
    //@Local(\.colorTheme) var colorTheme

    @AppStorage("monthlyAnalyticChartVisibleYearCount") var chartVisibleYearCount: CategoryAnalyticChartRange = .year1
    @AppStorage("selectedCategoryTab") var selectedTab: DetailsOrInsights = .details
    @AppStorage("showAllCategoryChartData") var showAllChartData = false

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    #endif
    @Environment(CalendarModel.self) private var calModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    @Environment(EventModel.self) private var eventModel
    
    @Bindable var category: CBCategory
//    @Bindable var catModel: CategoryModel
//    @Bindable var calModel: CalendarModel
//    @Bindable var keyModel: KeywordModel
    /// This is only here to blank out the selection hilight on the iPhone list
    @Binding var editID: String?
    
    @FocusState private var focusedField: Int?
    @State private var showDeleteAlert = false
    @State private var labelWidth: CGFloat = 20.0
    @State private var showSymbolPicker = false
    @State private var showColorPicker = false

    @State private var showMonth = false
    
    @State private var data: Array<AnalyticData> = []
    @State private var chartScrolledToDate: Date = Date()
    
    @State private var fetchYearStart = AppState.shared.todayYear - 10
    @State private var fetchYearEnd = AppState.shared.todayYear
    
    @State private var isLoadingHistory = true
    @State private var isLoadingMoreHistory = false
    //@State private var safeToLoadMoreHistory = false
    
    @Namespace private var namespace
        
    var displayData: Array<AnalyticData> {
//        if chartVisibleYearCount == .yearToDate {
//            return data
//                .filter { $0.year == Calendar.current.component(.year, from: .now) }
//        } else {
            let currentYear = Calendar.current.component(.year, from: .now)
            let years = (0..<chartVisibleYearCount.rawValue).map { currentYear - $0 }
            return data
                .filter { years.contains($0.year) }
//        }
    }
    
    var headerLingo: String {
        if category.isExpense {
            "Expenses"
        } else if category.isIncome {
            "Income"
        } else {
            "Payments"
        }
    }
    
    var title: String {
        if selectedTab == .details {
            category.action == .add ? "New Category" : "Edit Category"
        } else {
            category.title
        }
    }
   
    var isValidToSave: Bool {
        (category.action == .add && !category.title.isEmpty)
        || (category.hasChanges() && !category.title.isEmpty)
    }
    
    
    var body: some View {
        //let _ = Self._printChanges()
        Group {
        #if os(iOS)
            NavigationStack {
                VStack {
                    if category.action != .add {
                        Picker("", selection: $selectedTab.animation()) {
                            Text("Details")
                                .tag(DetailsOrInsights.details)
                            Text("Insights")
                                .tag(DetailsOrInsights.insights)
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .scenePadding(.horizontal)
                        //.background(Color(.systemBackground))
                    }
                    
                    switch selectedTab {
                    case .details: categoryPagePhone
                    case .insights: chartPage
                    case .edit: EmptyView()
                    }
                }
                .background(Color(.systemBackground))
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if selectedTab != .insights {
                        ToolbarItem(placement: .topBarLeading) {
                            GlassEffectContainer {
                                deleteButton
                                    .glassEffectID("delete", in: namespace)
                            }
                        }
                    }
                    
                    if selectedTab == .insights {
                        ToolbarSpacer(.fixed, placement: .topBarLeading)
                        
                        ToolbarItem(placement: .topBarLeading) {
                            GlassEffectContainer {
                                refreshButton
                                    .glassEffectID("refresh", in: namespace)
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        AnimatedCloseButton(isValidToSave: isValidToSave, color: category.color, closeButton: closeButton)
                    }
                    
                    ToolbarItem(placement: .bottomBar) {
                        EnteredByAndUpdatedByView(enteredBy: category.enteredBy, updatedBy: category.updatedBy, enteredDate: category.enteredDate, updatedDate: category.updatedDate)
                    }
                    .sharedBackgroundVisibility(.hidden)
                }
                
            }
            #else
            VStack {
                Group {
                    switch selectedTab {
                    case .details: categoryPagePhone
                    case .insights: chartPage
                    }
                }
                .frame(maxHeight: .infinity)
                
                fakeMacTabBar
            }
            #endif
        }
        .task {
            print("TASK")
            await prepareCategoryView()
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        
        /// Just for formatting.
        .onChange(of: focusedField) {
            if $1 == 1 {
                if category.amount == 0.0 {
                    category.amountString = ""
                }
            } else {
                if $0 == 1 {
                    category.amountString = category.amount?.currencyWithDecimals(useWholeNumbers ? 0 : 2)
                }
            }
        }
        .sheet(isPresented: $showSymbolPicker) {
            SymbolPicker(selected: $category.emoji, color: category.color)
                #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            //.frame(width: 300)
                #endif
        }
    }
    
    
    
    #if os(iOS)
//    @ToolbarContentBuilder
//    func phoneToolbar() -> some ToolbarContent {
//        
//        
//        ToolbarItemGroup(placement: .topBarTrailing) {
//            //HStack(spacing: 20) {
//                deleteButton
//            //ToolbarSpacer(.fixed)
//                Button {
//                    closeSheet()
//                } label: {
//                    Image(systemName: "xmark")
//                }
//            //}
//        }
//    }
    #endif

    
    
    var fakeMacTabBar: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(.clear)
                .frame(height: 50)
                .contentShape(Rectangle())
                .overlay {
                    Label("Details", systemImage: "list.bullet")
                        .foregroundStyle(selectedTab == .details ? category.color : .gray)
                }
                .onTapGesture {
                    selectedTab = .details
                }
            Rectangle()
                .fill(.clear)
                .frame(height: 50)
                .contentShape(Rectangle())
                .overlay {
                    Label("Insights", systemImage: "chart.xyaxis.line")
                        .foregroundStyle(selectedTab == .insights ? category.color : .gray)
                }
                .onTapGesture {
                    selectedTab = .insights
                }
        }
        //.fixedSize(horizontal: false, vertical: true)
        .frame(height: 50)
    }
    
    
    
    
    // MARK: - Category Edit Page Views
    var categoryPageMac: some View {
        StandardContainer {
            titleRow
            budgetRow
            StandardDivider()
            
            typeRow
            StandardDivider()
            
            Section {
                isHiddenRow
            } footer: {
                Text("Hide this category from **my** menus. (This will not delete any data).")
            }
            
            colorRow
            StandardDivider()
            
            symbolRow
            StandardDivider()
            
        } header: {
            SheetHeader(title: title, close: { closeSheet() }, view3: { deleteButton })
        }
    }
    
    
    var categoryPagePhone: some View {
        StandardContainerWithToolbar(.list) {
            Section("Title & Budget") {
                titleRow
                budgetRow
            }
            
            
            Section("Details") {
                typeRow
                symbolRow
            }
                        
//            Section {
//                colorRow
//            }
            
//            Section("Symbol & Color") {
//                symbolRow
//                //colorRow
//            }
            
            Section {
                isHiddenRow
            } footer: {
                Text("Hide this category from **my** menus. (This will not delete any data).")
            }
            
        }
//        header: {
//            SheetHeader(title: title, close: { closeSheet() }, view3: { deleteButton })
//        }
    }
    
    
    var titleRow: some View {
        #if os(iOS)
        HStack(spacing: 0) {
            Label {
                Text("")
            } icon: {
                Image(systemName: "t.circle")
                    .foregroundStyle(.gray)
            }
            
            UITextFieldWrapper(placeholder: "Title", text: $category.title, onSubmit: {
                focusedField = 1
            }, toolbar: {
                KeyboardToolbarView(focusedField: $focusedField)
            })
            .uiTag(0)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.left)
            .uiReturnKeyType(.next)
            //.uiFont(UIFont.systemFont(ofSize: 24.0))
            //.uiTextColor(.secondaryLabel)
        }
        .focused($focusedField, equals: 0)
        
        #else
        LabeledRow("Name", labelWidth) {
            StandardTextField("Title", text: $category.title, focusedField: $focusedField, focusValue: 0)
                .onSubmit { focusedField = 1 }
        }
        #endif
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
            
            UITextFieldWrapper(placeholder: "Monthly Amount", text: $category.amountString ?? "", toolbar: {
                KeyboardToolbarView(focusedField: $focusedField, accessoryImage3: "plus.forwardslash.minus", accessoryFunc3: {
                    Helpers.plusMinus($category.amountString ?? "")
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
    
        
    var typeRow: some View {
        #if os(iOS)
        
        Picker(selection: $category.type) {
            Text("Expense")
                .tag(XrefModel.getItem(from: .categoryTypes, byEnumID: .expense))
            Text("Income")
                .tag(XrefModel.getItem(from: .categoryTypes, byEnumID: .income))
            Text("Payment")
                .tag(XrefModel.getItem(from: .categoryTypes, byEnumID: .payment))
            Text("Savings")
                .tag(XrefModel.getItem(from: .categoryTypes, byEnumID: .savings))
        } label: {
            Label {
                Text("Category Type")
            } icon: {
                Image(systemName: "creditcard")
                    .foregroundStyle(.gray)
            }
        }
        .pickerStyle(.menu)
        .tint(.secondary)

        
        
//        Picker("Category Type", selection: $category.type) {
//            Text("Expense")
//                .tag(XrefModel.getItem(from: .categoryTypes, byEnumID: .expense))
//            Text("Income")
//                .tag(XrefModel.getItem(from: .categoryTypes, byEnumID: .income))
//            Text("Payment")
//                .tag(XrefModel.getItem(from: .categoryTypes, byEnumID: .payment))
//            Text("Savings")
//                .tag(XrefModel.getItem(from: .categoryTypes, byEnumID: .savings))
//        }
//        .pickerStyle(.menu)
//        .tint(.secondary)
        
        #else
        LabeledRow("Type", labelWidth) {
            Picker("", selection: $category.type) {
                Text("Expense")
                    .tag(XrefModel.getItem(from: .categoryTypes, byEnumID: .expense))
                Text("Income")
                    .tag(XrefModel.getItem(from: .categoryTypes, byEnumID: .income))
                Text("Payment")
                    .tag(XrefModel.getItem(from: .categoryTypes, byEnumID: .payment))
                Text("Savings")
                    .tag(XrefModel.getItem(from: .categoryTypes, byEnumID: .savings))
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        #endif
        
    }
    
    
    var isHiddenRow: some View {
        #if os(iOS)
        Toggle(isOn: $category.isHidden.animation()) {
            Label {
                Text("Mark as Hidden")
                    .schemeBasedForegroundStyle()
            } icon: {
                Image(systemName: "eye.slash")
                    .foregroundStyle(.gray)
            }
        }
        .tint(category.color == .primary ? Color.theme : category.color)
        
        #else
        LabeledRow("Hidden", labelWidth) {
            Toggle(isOn: $category.isHidden.animation()) {
                Text("Mark as Hidden")
            }
        } subContent: {
            Text("Hide this category from view (This will not delete any data).")
        }
        #endif
        
    }
    
    
    var colorRow: some View {
        #if os(iOS)
        HStack {
            Text("Color")
            Spacer()
            StandardColorPicker(color: $category.color)
        }
        
        #else
        LabeledRow("Color", labelWidth) {
            HStack {
                ColorPicker("", selection: $category.color, supportsOpacity: false)
                    .labelsHidden()
                Capsule()
                    .fill(category.color)
                    .frame(height: 30)
                    .onTapGesture {
                        AppState.shared.showToast(title: "Color Picker", subtitle: "Touch the circle to the left to change the color.", body: nil, symbol: category.emoji ?? "theatermask.and.paintbrush", symbolColor: category.color)
                    }
            }
        }
        #endif
    }
      
    
    var symbolRow: some View {
        #if os(iOS)
        Menu {
            Button("Change Symbol") {
                showSymbolPicker = true
            }
            Button("Change Color") {
                showColorPicker = true
            }
        } label: {
            HStack {
                Label {
                    Text("Symbol")
                        .schemeBasedForegroundStyle()
                } icon: {
                    Image(systemName: "tree")
                        .foregroundStyle(.gray)
                }
                
                //Text("Symbol")
                    //.schemeBasedForegroundStyle()
                Spacer()
                Image(systemName: category.emoji ?? "questionmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(category.color.gradient)
                //Spacer()
            }
        }
        .colorPickerSheet(isPresented: $showColorPicker, selection: $category.color, supportsAlpha: false)

        
        
//        Button {
//            showSymbolPicker = true
//        } label: {
//            HStack {
//                Text("Symbol")
//                    .schemeBasedForegroundStyle()
//                Spacer()
//                Image(systemName: category.emoji ?? "questionmark.circle.fill")
//                    .font(.system(size: 24))
//                    .foregroundStyle(category.color.gradient)
//                //Spacer()
//            }
//        }
        
        #else
        LabeledRow("Symbol", labelWidth) {
            HStack {
                Image(systemName: category.emoji ?? "questionmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(category.color.gradient)
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showSymbolPicker = true
            }
        }
        #endif
    }
   
    
    var closeButton: some View {
        Button {
            closeSheet()
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
        .confirmationDialog("Delete \"\(category.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Delete", role: .destructive) { deleteCategory() }
            //Button("No", role: .close) { showDeleteAlert = false }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(category.title)\"?\nThis will not delete any associated transactions.")
            #else
            Text("This will not delete any associated transactions.")
            #endif
        })
    }
    
    
    
    
    // MARK: - Chart Page Views
    var chartPage: some View {
        StandardContainerWithToolbar(.list) {
            if category.action == .add {
                ContentUnavailableView("Insights are not available when adding a new category", systemImage: "square.stack.3d.up.slash.fill")
            } else {
                CategoryAnalyticChart(
                    data: data,
                    displayData: displayData,
                    config: CategoryAnalyticChartConfig(enableShowExpenses: true, enableShowBudget: true, enableShowAverage: true, color: category.color, headerLingo: headerLingo),
                    isLoadingHistory: $isLoadingHistory,
                    chartScrolledToDate: $chartScrolledToDate,
                    rawDataList: { rawDataList }
                )
            }
        }
        .opacity(isLoadingHistory ? 0 : 1)
        .overlay { ProgressView("Loading Insights…").tint(.none).opacity(isLoadingHistory ? 1 : 0) }
        .focusable(false)
    }
    
    
    var refreshButton: some View {
        Button {
            Task {
                fetchYearStart = AppState.shared.todayYear - 10
                fetchYearEnd = AppState.shared.todayYear
                data.removeAll()
                isLoadingHistory = true
                await fetchHistory(setChartAsNew: true)
            }
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
        }
        .tint(.none)
        .symbolEffect(.rotate, options: SymbolEffectOptions.repeat(.continuous).speed(3), isActive: isLoadingHistory)
        .symbolEffect(.rotate, options: SymbolEffectOptions.repeat(.continuous).speed(3), isActive: isLoadingMoreHistory)
    }
    
    
    @ViewBuilder
    var rawDataList: some View {
        var displayRange: ClosedRange<Int> {
            let years = data.map { $0.year }
            return min((years.min() ?? 0), fetchYearStart)...max((years.max() ?? 0), fetchYearEnd)
        }
        
        Section {
            NavigationLink {
                List {
                    /// Don't use `displayData` here since when viewing YTD, it will ommit the rest of the data and will look like it's missing.
                    ForEach(Array(displayRange.reversed()), id: \.self) { year in
                        let data = data.filter {$0.year == year}.sorted(by: { $0.date > $1.date })
                        
                        Section(String(year)) {
                            if data.isEmpty {
                                Text("No Transactions")
                                    .foregroundStyle(.gray)
                            } else {
                                ForEach(data) { data in
                                    RawDataLineItem(category: category, data: data)
                                }
                            }
                        }
                    }
                    
                    Section {
                        Button("Fetch \(String(fetchYearStart - 10)) - \(String(fetchYearEnd - 10))", action: fetchMoreHistory)
                            .tint(category.color)
                    }
                    
                    
                    
                }
                .navigationTitle("\(category.title) Data")
                .navigationSubtitle("\(String(fetchYearStart)) - \(String(AppState.shared.todayYear))")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        refreshButton
                    }
                }
                #endif
            } label: {
                Text("Show All")
            }
            .tint(Color.theme)
            .onChange(of: calModel.showMonth) {
                if !$1 && $0 {
                    Task { await fetchHistory(setChartAsNew: false) }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .updateCategoryAnalytics, object: nil)) { _ in
                Task { await fetchHistory(setChartAsNew: false) }
            }
        } header: {
            Text("Data By Month")
        }
    }    
    
    
    struct RawDataLineItem: View {
        @Environment(\.colorScheme) var colorScheme

        #if os(macOS)
        @Environment(\.openWindow) private var openWindow
        @Environment(\.dismissWindow) private var dismissWindow
        #endif
        @Environment(CalendarModel.self) var calModel
        
        @Bindable var category: CBCategory
        var data: AnalyticData
        
        @State private var backgroundColor: Color = .clear
        
        var body: some View {
            Button {
                openMonthlySheet()
            } label: {
                HStack {
                    Text("\(data.date, format: .dateTime.month(.wide)) \(String(data.year))")
                    Spacer()
                    Text("\(data.expensesString)")
                }
            }
            .tint(.none)
            .schemeBasedForegroundStyle()
            .background(backgroundColor)
            .onHover { backgroundColor = $0 ? .gray.opacity(0.2) : .clear }
        }
        
        
        func openMonthlySheet() {
            calModel.sCategories = [category]
            
            calModel.categoryFilterWasSetByCategoryPage = true
            let monthEnum = NavDestination.getMonthFromInt(data.month)
            calModel.sYear = data.year
            
            #if os(iOS)
            if AppState.shared.isIpad {
                /// Block the navigation stack from trying to change to the calendar section on iPad.
                calModel.isShowingFullScreenCoverOnIpad = true
            }
            
            NavigationManager.shared.selectedMonth = monthEnum
            calModel.showMonth = true
            
            #else
            AppState.shared.monthlySheetWindowTitle = "\(category.title) Expenses For \(monthEnum?.displayName ?? "N/A") \(String(calModel.sYear))"
            dismissWindow(id: "monthlyWindow")
            openWindow(id: "monthlyWindow", value: monthEnum)
            //calModel.windowMonth = monthEnum
            //openWindow(id: "monthlyWindow")
            #endif
        }
    }
    
    
    
        
    // MARK: - Functions
    
    func closeSheet() {
        /// Moved to onDismiss of this sheet.
//        if calModel.categoryFilterWasSetByCategoryPage {
//            calModel.sCategories.removeAll()
//            calModel.categoryFilterWasSetByCategoryPage = false
//        }
        editID = nil
        dismiss()
        #if os(macOS)
        dismissWindow(id: "monthlyWindow")
        #endif
    }
    
    
    func prepareCategoryView() async {
        category.deepCopy(.create)
        /// Just for formatting.
        category.amountString = category.amount?.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        catModel.upsert(category)
        
        #if os(macOS)
        /// Focus on the title textfield.
        focusedField = 0
        #else
        if category.action == .add {
            focusedField = 0
        }
        #endif
       
        if category.action == .add {
            selectedTab = .details
        } else {
            await fetchHistory(setChartAsNew: true)
        }
    }
    
    
    func deleteCategory() {
        //Task {
            category.action = .delete
            dismiss()
            //await catModel.delete(category, andSubmit: true, calModel: calModel, keyModel: keyModel, eventModel: eventModel)
        //}
    }
    
    
    func fetchMoreHistory() {
        Task {
            isLoadingMoreHistory = true
            fetchYearStart -= 10
            fetchYearEnd -= 10
            print("fetching more history... \(fetchYearStart) - \(fetchYearEnd)")
            await fetchHistory(setChartAsNew: false)
        }
    }
    
    
    func fetchHistory(setChartAsNew: Bool) async {
        if setChartAsNew {
            isLoadingHistory = true
        }
                
        let model = AnalysisRequestModel(recordIDs: [category.id], fetchYearStart: fetchYearStart, fetchYearEnd: fetchYearEnd, isUnifiedRequest: false)
        
        if let data = await catModel.fetchExpensesByCategory(model) {
            withAnimation {
                //var localData: Array<AnalyticData> = []
                for each in data {
                    print(each.date)
                    if let index = self.data.firstIndex(where: { $0.month == each.month && $0.year == each.year }) {
                        self.data[index].budgetString = each.budgetString
                        self.data[index].expensesString = each.expensesString
                        self.data[index].incomeString = each.incomeString
                    } else {
                        let anal = AnalyticData(
                            record: .init(id: each.category?.id ?? UUID().uuidString, title: each.category?.title ?? "", color: each.category?.color ?? .primary),
                            type: "category",
                            month: each.month,
                            year: each.year,
                            budgetString: each.budgetString,
                            expensesString: each.expensesString,
                            incomeString: each.incomeString
                        )
                        self.data.append(anal)
                    }
                }
                                
                self.data.sort(by: { $0.date < $1.date })
            }
                    
            if setChartAsNew {
                var visibleYearCount: Int {
                    chartVisibleYearCount.rawValue == 0 ? 1 : chartVisibleYearCount.rawValue
                }
                
                /// Set the scrollPosition to which ever is smaller, the idealStartDate, or the maxAvailStartDate.
                let minDate = data.first?.date ?? Date()
                let maxDate = data.last?.date ?? Date()
                let idealDate = Calendar.current.date(byAdding: .day, value: -(365 * visibleYearCount), to: maxDate)!
                                
//                if chartVisibleYearCount == .yearToDate {
//                    let components = Calendar.current.dateComponents([.year], from: .now)
//                    chartScrolledToDate = Calendar.current.date(from: components)!
//                } else {
                    chartScrolledToDate = minDate < idealDate ? idealDate : minDate
//                }
            
                isLoadingHistory = false
            }
        }
        
        isLoadingMoreHistory = false
    }
}
