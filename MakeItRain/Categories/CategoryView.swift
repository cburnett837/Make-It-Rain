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
    @AppStorage("monthlyAnalyticChartVisibleYearCount") var chartVisibleYearCount: MonthlyAnalyticChartRange = .year1
    @AppStorage("selectedCategoryTab") var selectedCategoryTab: String = "details"
    @AppStorage("showAllCategoryChartData") var showAllChartData = false

    
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    #endif
    @Environment(\.dismiss) var dismiss
    @Environment(EventModel.self) private var eventModel
    
    @Bindable var category: CBCategory
    @Bindable var catModel: CategoryModel
    @Bindable var calModel: CalendarModel
    @Bindable var keyModel: KeywordModel
    /// This is only here to blank out the selection hilight on the iPhone list
    @Binding var editID: String?
    
    @FocusState private var focusedField: Int?
    @State private var showDeleteAlert = false
    @State private var labelWidth: CGFloat = 20.0
    @State private var showSymbolPicker = false
    @State private var showMonth = false
    
    @State private var data: Array<AnalyticData> = []
    @State private var chartScrolledToDate: Date = Date()
    
    @State private var fetchYearStart = AppState.shared.todayYear - 10
    @State private var fetchYearEnd = AppState.shared.todayYear
    
    @State private var isLoadingHistory = true
    @State private var isLoadingMoreHistory = false
    //@State private var safeToLoadMoreHistory = false
    
    var displayData: Array<AnalyticData> {
        if chartVisibleYearCount == .yearToDate {
            return data
                .filter { $0.year == Calendar.current.dateComponents([.year], from: .now).year! }
        } else {
            return data
        }
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

    
    
    
    //@Namespace private var monthNavigationNamespace
    
    var title: String {
        if selectedCategoryTab == "details" {
            category.action == .add ? "New Category" : "Edit Category"
        } else {
            category.title
        }
    }
    
    
    var body: some View {
        Group {
            #if os(iOS)
            TabView(selection: $selectedCategoryTab) {
                Tab(value: "details") {
                    categoryPage
                } label: {
                    Label("Details", systemImage: "list.bullet")
                }
                
                Tab(value: "analytics") {
                    chartPage
                } label: {
                    Label("Insights", systemImage: "chart.xyaxis.line")
                }
            }
            .tint(category.color)
            #else
            
            VStack {
                Group {
                    if selectedCategoryTab == "details" {
                        categoryPage
                    } else {
                        chartPage
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
        .confirmationDialog("Delete \"\(category.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive) { deleteCategory() }
            Button("No", role: .cancel) { showDeleteAlert = false }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(category.title)\"?\nThis will not delete any associated transactions.")
            #else
            Text("This will not delete any associated transactions.")
            #endif
        })
    }
    
    
    var fakeMacTabBar: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(.clear)
                .frame(height: 50)
                .contentShape(Rectangle())
                .overlay {
                    Label("Details", systemImage: "list.bullet")
                        .foregroundStyle(selectedCategoryTab == "details" ? category.color : .gray)
                }
                .onTapGesture {
                    selectedCategoryTab = "details"
                }
            Rectangle()
                .fill(.clear)
                .frame(height: 50)
                .contentShape(Rectangle())
                .overlay {
                    Label("Insights", systemImage: "chart.xyaxis.line")
                        .foregroundStyle(selectedCategoryTab == "analytics" ? category.color : .gray)
                }
                .onTapGesture {
                    selectedCategoryTab = "analytics"
                }
        }
        //.fixedSize(horizontal: false, vertical: true)
        .frame(height: 50)
    }
    
    
    
    
    // MARK: - Category Edit Page Views
    var categoryPage: some View {
        StandardContainer {
            titleRow
            budgetRow
            StandardDivider()
            
            typeRow
            StandardDivider()
            
            colorRow
            StandardDivider()
            
            symbolRow
            StandardDivider()
            
        } header: {
            SheetHeader(title: title, close: { closeSheet() }, view3: { deleteButton })
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
    
    
    var titleRow: some View {
        LabeledRow("Name", labelWidth) {
            #if os(iOS)
            StandardUITextField("Title", text: $category.title, onSubmit: {
                focusedField = 1
            }, toolbar: {
                KeyboardToolbarView(focusedField: $focusedField)
            })
            .cbFocused(_focusedField, equals: 0)
            .cbClearButtonMode(.whileEditing)
            .cbSubmitLabel(.next)
            #else
            StandardTextField("Title", text: $category.title, focusedField: $focusedField, focusValue: 0)
                .onSubmit { focusedField = 1 }
            #endif
        }
    }
    
    
    var budgetRow: some View {
        LabeledRow("Budget", labelWidth) {
            #if os(iOS)
            StandardUITextField("Monthly Amount", text: $category.amountString ?? "", toolbar: {
                KeyboardToolbarView(focusedField: $focusedField, accessoryImage3: "plus.forwardslash.minus", accessoryFunc3: {
                    Helpers.plusMinus($category.amountString ?? "")
                })
            })
            .cbFocused(_focusedField, equals: 1)
            .cbClearButtonMode(.whileEditing)
            .cbKeyboardType(.decimalPad)
            #else
            StandardTextField("Monthly Amount", text: $category.amountString ?? "", focusedField: $focusedField, focusValue: 1)
            #endif
        }
    }
    
    
    var typeRow: some View {
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
    }
    
    
    var colorRow: some View {
        LabeledRow("Color", labelWidth) {
            #if os(iOS)
            StandardColorPicker(color: $category.color)
            #else
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
            #endif
        }
    }
    
    
    var symbolRow: some View {
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
        
        
//        LabeledRow("Symbol", labelWidth) {
//            #if os(macOS)
//            HStack {
//                Button {
//                    //                      Task {
//                    //                          focusedField = .emoji
//                    //                          try? await Task.sleep(for: .milliseconds(100))
//                    //                          NSApp.orderFrontCharacterPalette($category.emoji)
//                    //                      }
//                    showSymbolPicker = true
//                } label: {
//                    Image(systemName: category.emoji ?? "questionmark.circle.fill")
//                        .foregroundStyle(category.color)
//                }
//                .buttonStyle(.codyStandardWithHover)
//                Spacer()
//            }
//            
//            #else
//            HStack {
//                Image(systemName: category.emoji ?? "questionmark.circle.fill")
//                    .font(.title2)
//                    .foregroundStyle(category.color.gradient)
//                
//                Spacer()
//            }
//            .contentShape(Rectangle())
//            .onTapGesture {
//                showSymbolPicker = true
//            }
//            #endif
//        }
    }
    
    
    var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Image(systemName: "trash")
        }
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
    }
    
    
    
    
    // MARK: - Chart Page Views
    var chartPage: some View {
        Group {
            if category.action == .add {
                ContentUnavailableView("Insights are not available when adding a new category", systemImage: "square.stack.3d.up.slash.fill")
            } else {
                StandardContainer {
                    MonthlyAnalyticChart(
                        data: data,
                        displayData: displayData,
                        config: MonthlyAnalyticChartConfig(enableShowExpenses: true, enableShowBudget: true, enableShowAverage: true, color: category.color, headerLingo: headerLingo),
                        isLoadingHistory: $isLoadingHistory,
                        chartScrolledToDate: $chartScrolledToDate,
                        rawDataList: { rawDataList }
                    )
                } header: {
                    SheetHeader(
                        title: title,
                        close: { closeSheet() },
                        view1: { refreshButton },
                        //view2: { ProgressView().opacity(isLoadingMoreHistory ? 1 : 0).tint(.none) },
                        view3: { deleteButton }
                    )
                }
                .listStyle(.plain)
                #if os(iOS)
                .listSectionSpacing(50)
                #endif
                .opacity(isLoadingHistory ? 0 : 1)
                .overlay { ProgressView("Loading Insights…").tint(.none).opacity(isLoadingHistory ? 1 : 0) }
                .focusable(false)
            }
        }
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
    }
    
    
    var rawDataList: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Data (\(String(fetchYearStart)) - \(String(AppState.shared.todayYear)))")
                .foregroundStyle(.gray)
                .font(.subheadline)
                //.padding(.leading, 6)
            Divider()
            
            DisclosureGroup(isExpanded: $showAllChartData) {
                VStack(spacing: 0) {
                    Divider()
                        .padding(.leading, 25)
                    
                    LazyVStack {
                        ForEach(displayData.sorted(by: { $0.date > $1.date })) { data in
                            RawDataLineItem(category: category, data: data)
                                .padding(.leading, 25)
                                .onScrollVisibilityChange {
                                    if $0 && data.id == displayData.sorted(by: { $0.date > $1.date }).last?.id {
                                        fetchMoreHistory()
                                    }
                                }
                        }
                    }
                }
            } label: {
                Text("Show All")
                    .onTapGesture {
                        withAnimation {
                            showAllChartData.toggle()
                        }
                    }
            }
            
            //.foregroundStyle(category.color)
            .tint(category.color)
            //.padding(.vertical, 8)
            .padding(.bottom, 10)
            //.rowBackground()
            .onChange(of: calModel.showMonth) { oldValue, newValue in
                if newValue == false && oldValue == true {
                    Task {
                        await fetchHistory(setChartAsNew: false)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .updateCategoryAnalytics, object: nil)) { _ in
                Task {
                    await fetchHistory(setChartAsNew: false)
                }
            }
        }
    }    
    
    
    struct RawDataLineItem: View {
        #if os(macOS)
        @Environment(\.openWindow) private var openWindow
        @Environment(\.dismissWindow) private var dismissWindow
        #endif
        @Environment(CalendarModel.self) var calModel
        
        @Bindable var category: CBCategory
        var data: AnalyticData
        
        @State private var backgroundColor: Color = .clear
        
        var body: some View {
            VStack(spacing: 0) {
                HStack {
                    Text("\(data.date, format: .dateTime.month(.wide)) \(String(data.year))")
                    Spacer()
                    Text("\(data.expensesString)")
                }
                .padding(.vertical, 6)
                Divider()
            }
            .contentShape(Rectangle())
            .background(backgroundColor)
            .onHover { backgroundColor = $0 ? .gray.opacity(0.2) : .clear }
            .onTapGesture { openMonthlySheet() }
        }
        
        
        func openMonthlySheet() {
            calModel.sCategories = [category]
            
            calModel.categoryFilterWasSetByCategoryPage = true
            let monthEnum = NavDestination.getMonthFromInt(data.month)
            calModel.sYear = data.year
            
            #if os(iOS)
            if AppState.shared.isIpad {
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
            selectedCategoryTab = "details"
        }
        
        if category.action != .add {
            await fetchHistory(setChartAsNew: true)
        }
    }
    
    
    func deleteCategory() {
        Task {
            dismiss()
            await catModel.delete(category, andSubmit: true, calModel: calModel, keyModel: keyModel, eventModel: eventModel)
        }
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
                
        let model = AnalysisRequestModel(recordIDs: [category.id], fetchYearStart: fetchYearStart, fetchYearEnd: fetchYearEnd)
        
        if let data = await catModel.fetchExpensesByCategory(model) {
            withAnimation {
                //var localData: Array<AnalyticData> = []
                for each in data {
                    if let index = self.data.firstIndex(where: { $0.month == each.month && $0.year == each.year }) {
                        self.data[index].budgetString = each.amountString
                        self.data[index].expensesString = each.amountString2
                    } else {
                        let anal = AnalyticData(
                            record: .init(id: each.category?.id ?? UUID().uuidString, title: each.category?.title ?? "", color: each.category?.color ?? .primary),
                            type: "category",
                            month: each.month,
                            year: each.year,
                            budgetString: each.amountString,
                            expensesString: each.amountString2
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
                                
                if chartVisibleYearCount == .yearToDate {
                    let components = Calendar.current.dateComponents([.year], from: .now)
                    chartScrolledToDate = Calendar.current.date(from: components)!
                } else {
                    chartScrolledToDate = minDate < idealDate ? idealDate : minDate
                }
            
                isLoadingHistory = false
            }
        }
        
        isLoadingMoreHistory = false
    }
}
