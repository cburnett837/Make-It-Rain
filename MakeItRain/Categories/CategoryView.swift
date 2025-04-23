//
//  CategoryViewMac.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/21/24.
//

import SwiftUI
import Charts

struct CategoryView: View {
    enum ChartRange: Int {
        case yearToDate = 0
        case year1 = 1
        case year2 = 2
        case year3 = 3
        case year4 = 4
        case year5 = 5
    }
    
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
   
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
    
    @State private var showDeleteAlert = false
    @State private var labelWidth: CGFloat = 20.0
    
    var title: String { category.action == .add ? "New Category" : "Edit Category" }
    
    @FocusState private var focusedField: Int?
    @State private var showSymbolPicker = false
    
    @State private var isLoadingHistory = true
    @State private var expenses: Array<CBBudget> = []
    @AppStorage("chartVisibleYearCount") var chartVisibleYearCount: ChartRange = .year1
    @AppStorage("selectedCategoryTab") var selectedCategoryTab: String = "details"
    @AppStorage("showAverageOnCategoryChart") var showAverageOnCategoryChart: Bool = true
    @AppStorage("showBudgetOnCategoryChart") var showBudgetOnCategoryChart: Bool = true
    
    @State private var showMonth = false
    
    @State private var rawSelectedDate: Date?
    @State private var chartScrollPosition: Date = Date()
    @AppStorage("showAllCategoryChartData") var showAllChartData = false
    
    @Namespace private var monthNavigationNamespace
    
    var selectedMonth: CBBudget? {
        guard let rawSelectedDate else { return nil }
        return expenses.first {
            Calendar.current.isDate(rawSelectedDate, equalTo: $0.date, toGranularity: .month)
        }
    }
    
//    var visibleRange: ClosedRange<Date> {
//        /// Check if the date range of the expenses is within the visibleRange. Crop accordingly.
//        let maxAvailEndDate = expenses.last?.date ?? Date()
//        let idealEndDate = Calendar.current.date(byAdding: .day, value: (365 * chartVisibleYearCount.rawValue), to: chartScrollPosition)!
//        
//        let endRange = idealEndDate > maxAvailEndDate ? maxAvailEndDate : idealEndDate
//        
//        print("Visible Range: \(chartScrollPosition) -- \(endRange)")
//        
//        guard chartScrollPosition < endRange else { return endRange...endRange }
//        
//        return chartScrollPosition...endRange
//    }
    
    var visibleRange: ClosedRange<Date> {
        /// Check if the date range of the expenses is within the visibleRange. Crop accordingly.
        let maxAvailEndDate = expenses.last?.date ?? Date()
        var idealEndDate: Date = Date()
        
        if visibleYearCount != 0 {
            idealEndDate = Calendar.current.date(byAdding: .day, value: (365 * visibleYearCount), to: chartScrollPosition)!
        }
        
        var endRange: Date
        
        if visibleYearCount == 0 {
            endRange = idealEndDate
        } else {
            endRange = idealEndDate > maxAvailEndDate ? maxAvailEndDate : idealEndDate
        }
        
        
        
        print("\(chartScrollPosition) -- \(maxAvailEndDate) -- \(idealEndDate)")
        
        guard chartScrollPosition < endRange else { return endRange...endRange }
        
        return chartScrollPosition...endRange
    }
    
    var visibleTotal: Double {
        /// Calculate the total of the expenses currently in the chart visible range.
        expenses
            .filter { visibleRange.contains($0.date) }
            .map { $0.amount }
            .reduce(0, +)
    }
    
    var visibleYearCount: Int {
        chartVisibleYearCount.rawValue == 0 ? 1 : chartVisibleYearCount.rawValue
    }
    
    var visibleDomain: Int {
        /// Check if the date range of the expenses is within the visibleDomain. Crop accordingly.
        let firstExpense = expenses.first?.date ?? Date()
        let lastExpense = expenses.last?.date ?? Date()
        
        let maxAvailDomain = 3600 * 24 * (Calendar.current.dateComponents([.day], from: firstExpense, to: lastExpense).day ?? 0)
        
        let idealDomain = 3600 * 24 * (365 * visibleYearCount)
        
        print("DOMAIN \(idealDomain) -- \(maxAvailDomain) -- \(firstExpense) -- \(lastExpense)")
        
        if maxAvailDomain == 0 {
            return  3600 * 24 * 30
        } else {
            return idealDomain > maxAvailDomain ? maxAvailDomain : idealDomain
        }
                
        
    }
        
    var minExpense: Double {
        expenses.map {$0.amount}.min() ?? 0
    }
    
    var maxExpense: Double {
        expenses.map {$0.amount}.max() ?? 0
    }
    
    var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Image(systemName: "trash")
        }
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
    }
    
    var body: some View {
        Group {
            #if os(iOS)
            TabView(selection: $selectedCategoryTab) {
                categoryPage
                    .tabItem { Label("Details", systemImage: "list.bullet") }
                    .tag("details")
                    //.standardBackground()
                chartPage
                    .tabItem { Label("Analytics", systemImage: "chart.xyaxis.line") }
                    .tag("analytics")
                    //.standardBackground()
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
                            Label("Analytics", systemImage: "chart.xyaxis.line")
                                .foregroundStyle(selectedCategoryTab == "analytics" ? category.color : .gray)
                        }
                        .onTapGesture {
                            selectedCategoryTab = "analytics"
                        }
                }
                //.fixedSize(horizontal: false, vertical: true)
                .frame(height: 50)
            }
            
            #endif
        }
        .task {
            await prepareCategoryView()
        }
        .confirmationDialog("Delete \"\(category.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive) {
                Task {
                    dismiss()
                    await catModel.delete(category, andSubmit: true, calModel: calModel, keyModel: keyModel, eventModel: eventModel)
                }
            }
            
            Button("No", role: .cancel) {
                showDeleteAlert = false
            }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(category.title)\"?\nThis will not delete any associated transactions.")
            #else
            Text("This will not delete any associated transactions.")
            #endif
        })
        
    }
    
    
    var categoryPage: some View {
        StandardContainer {
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
                                
            StandardDivider()
            
            LabeledRow("Type", labelWidth) {
                Picker("", selection: $category.isIncome) {
                    Text("Expense")
                        .tag(false)
                    Text("Income")
                        .tag(true)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            
            StandardDivider()
            
            LabeledRow("Color", labelWidth) {
                //ColorPickerButton(color: $category.color)
                HStack {
                    ColorPicker("", selection: $category.color, supportsOpacity: false)
                        .labelsHidden()
                    Capsule()
                        .fill(category.color)
                        .onTapGesture {
                            AppState.shared.showToast(title: "Color Picker", subtitle: "Click the circle to the left to change the color.", body: nil, symbol: category.emoji ?? "theatermask.and.paintbrush", symbolColor: category.color)
                        }
                }
            }
                        
            StandardDivider()
            
            LabeledRow("Symbol", labelWidth) {
                #if os(macOS)
                HStack {
                    Button {
//                      Task {
//                          focusedField = .emoji
//                          try? await Task.sleep(for: .milliseconds(100))
//                          NSApp.orderFrontCharacterPalette($category.emoji)
//                      }
                        showSymbolPicker = true
                    } label: {
                        Image(systemName: category.emoji ?? "questionmark.circle.fill")
                            .foregroundStyle(category.color)
                    }
                    .buttonStyle(.codyStandardWithHover)
                    Spacer()
                }
                
                #else
                HStack {
                    Image(systemName: category.emoji ?? "questionmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(category.color.gradient)
                    
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    showSymbolPicker = true
                }
                #endif
            }
            
            StandardDivider()
          
            
        } header: {
            SheetHeader(title: title, close: { closeSheet() }, view3: { deleteButton })
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
                
        /// Just for formatting.
        .onChange(of: focusedField) { oldValue, newValue in
            if newValue == 1 {
                if category.amount == 0.0 {
                    category.amountString = ""
                }
            } else {
                if oldValue == 1 {
                    category.amountString = category.amount?.currencyWithDecimals(useWholeNumbers ? 0 : 2)
                }
            }
        }
        .sheet(isPresented: $showSymbolPicker) {
            SymbolPicker(selected: $category.emoji)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
                //.frame(width: 300)
            #endif
        }
    }
    
    
    var chartHeader: some View {
        VStack(alignment: .leading) {
            Text("Total \(category.isIncome ? "Income" : "Expenses")")
                .foregroundStyle(.gray)
                .font(.title3)
                .bold()
            
            Text("\(visibleTotal.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
            
            HStack(spacing: 5) {
                Text(visibleRange.lowerBound.string(to: .date))
                Text("-")
                Text(visibleRange.upperBound.string(to: .date))
            }
            .foregroundStyle(.gray)
            .font(.caption)
        }
    }
    
    
    var chartBody: some View {
        Chart {
            if let selectedMonth {
                RuleMark(x: .value("Selected Date", selectedMonth.date, unit: .month))
                    .foregroundStyle(selectedMonth.category?.color ?? .primary)
                    .offset(yStart: -15)
                    .zIndex(-1)
            }
            
            if let amount = category.amount {
                /// Show the budget line.
                if showBudgetOnCategoryChart {
                    RuleMark(y: .value("Budget", amount))
                        .foregroundStyle(category.color.opacity(0.7))
                        .zIndex(-1)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                }
                
                /// Show the average expense line.
                if showAverageOnCategoryChart {
                    RuleMark(y: .value("Average", expenses.map { $0.amount }.average()))
                        //.foregroundStyle(category.color.opacity(0.5))
                        .foregroundStyle(.gray.opacity(0.7))
                        .zIndex(-1)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                }
            }
                                                
            ForEach(expenses) { expense in
                LineMark(
                    x: .value("Date", expense.date, unit: .month),
                    y: .value("Amount", expense.amount)
                )
                .foregroundStyle(expense.category?.color ?? .primary)
                .interpolationMethod(.catmullRom)
                //.lineStyle(.init(lineWidth: 2))
                .symbol {
                    if expense.amount > 0 {
                        Circle()
                            .fill(expense.category?.color ?? .primary)
                            .frame(width: 6, height: 6)
                            //.opacity(rawSelectedDate == nil || start.date == selectedStartingAmount?.date ? 1 : 0.3)
                    }
                }
                                
                AreaMark(
                    x: .value("Date", expense.date, unit: .month),
                    yStart: .value("Max", expense.amount),
                    yEnd: .value("Min", minExpense)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(LinearGradient(
                    colors: [expense.category?.color ?? .primary, .clear],
                    startPoint: .top,
                    endPoint: .bottom)
                )
            }
        }
        .frame(minHeight: 150)
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: visibleDomain)
        //.chartScrollPosition(initialX: expenses.last?.date ?? Date())
        .chartScrollPosition(x: $chartScrollPosition)
        .chartXSelection(value: $rawSelectedDate)
        .chartYScale(domain: [minExpense, maxExpense + (maxExpense * 0.2)])
//        .chartScrollTargetBehavior(
//            .valueAligned(
//                matching: DateComponents(day: 1),
//                majorAlignment: .matching(DateComponents(day: 1))
//            )
//        )
        .chartOverlay { proxy in
            GeometryReader { geometry in
                if let selectedMonth {
                    if let _ = proxy.position(forX: selectedMonth.date) {
                        VStack {
                            Text("\(selectedMonth.date, format: .dateTime.month(.wide)) \(String(selectedMonth.date.year))")
                                .bold()
                            Text("\(selectedMonth.amountString)")
                                .bold()
                        }
                        .foregroundStyle(.white)
                        .padding(12)
                        .frame(width: 160)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill((selectedMonth.category?.color ?? .primary)/*.gradient*/)
                        )
//                                    .position(
//                                        x: min(max(positionX, 80), geometry.size.width - 80), // Keep annotation within bounds horizontally
//                                        y: -40 // Fixed Y position to stay above the chart
//                                    )
                        .position(x: geometry.frame(in: .local).midX, y: -40)
                        .zIndex(100)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks {
            //AxisMarks(values: .automatic(desiredCount: 6)) {
               let value = $0.as(Int.self)!
               AxisValueLabel {
                   Text("$\(value)")
               }
           }
        }
        .chartLegend(position: .top, alignment: .leading)
        .chartForegroundStyleScale([
            "\(category.isIncome ? "Income" : "Expenses"): \((expenses.map { $0.amount }.reduce(0.0, +).currencyWithDecimals(useWholeNumbers ? 0 : 2)))": category.color,
            "Budget: \((category.amount ?? 0).currencyWithDecimals(useWholeNumbers ? 0 : 2))": category.color.opacity(0.7),
            "Average: \((expenses.map { $0.amount }.average()).currencyWithDecimals(useWholeNumbers ? 0 : 2))": Color.gray
        ])
        .padding(.bottom, 10)
    }
    
    
    var chartVisibleYearPicker: some View {
        Picker("", selection: $chartVisibleYearCount.animation()) {
            Text("YTD").tag(ChartRange.yearToDate)
            Text("1Y").tag(ChartRange.year1)
            Text("2Y").tag(ChartRange.year2)
            Text("3Y").tag(ChartRange.year3)
            Text("4Y").tag(ChartRange.year4)
            Text("5Y").tag(ChartRange.year5)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .onChange(of: chartVisibleYearCount) { oldValue, newValue in
            /// Set the scrollPosition to which ever is smaller, the targetDate, or the minDate.
            let minDate = expenses.first?.date ?? Date()
            let targetDate = Calendar.current.date(byAdding: .day, value: -(365 * (newValue.rawValue == 0 ? 1 : newValue.rawValue)), to: expenses.last?.date ?? Date())!
            
            if targetDate < minDate {
                chartScrollPosition = minDate
            } else {
                chartScrollPosition = targetDate
            }
            
            
        }
    }
        
    
    var chartPage: some View {
        Group {
            if category.action == .add {
                ContentUnavailableView("Analytics are not available when adding a new category", systemImage: "square.stack.3d.up.slash.fill")
            } else {
                StandardContainer {
                    chartVisibleYearPicker
                        //.rowBackground()
                    
                    Section {
                        chartHeader
                            //.rowBackground()
                                    
                        Divider()
                        
                        chartBody
                            //.rowBackground()
                            .padding(.vertical, 30)
                                                        
                        Text("Options")
                            .foregroundStyle(.gray)
                            .font(.subheadline)
                            //.padding(.leading, 6)
                        Divider()
                        
                        Toggle(isOn: $showAverageOnCategoryChart.animation()) {
                            Text("Show Average")
                        }
                        //.rowBackground()
                        
                        Toggle(isOn: $showBudgetOnCategoryChart.animation()) {
                            Text("Show Budget")
                        }
                        //.rowBackground()
                    }
                    
                    Divider()
                    
                    Spacer()
                        .frame(minHeight: 10)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Data")
                            .foregroundStyle(.gray)
                            .font(.subheadline)
                            //.padding(.leading, 6)
                        Divider()
                        
                        DisclosureGroup(isExpanded: $showAllChartData) {
                            VStack(spacing: 0) {
                                Divider()
                                    .padding(.leading, 25)
                                
                                ForEach(expenses) { expense in
                                    RawDataLineItem(category: category, expense: expense)
                                        .padding(.leading, 25)
                                }
                            }
                            
                        } label: {
                            Text("Show All")
                                .onTapGesture {
                                    showAllChartData.toggle()
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
                } header: {
                    SheetHeader(title: title, close: { closeSheet() }, view3: { deleteButton })
                }
                .listStyle(.plain)
                #if os(iOS)
                .listSectionSpacing(50)
                #endif
                .opacity(isLoadingHistory ? 0 : 1)
                .overlay { ProgressView("Loading Analytics…").tint(.none).opacity(isLoadingHistory ? 1 : 0) }
                .focusable(false)
            }
        }
        
        
        
    }
    
    
    func closeSheet() {
        if calModel.categoryFilterWasSetByCategoryPage {
            calModel.sCategories.removeAll()
        }
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
    
    
    func fetchHistory(setChartAsNew: Bool) async {
        if setChartAsNew {
            isLoadingHistory = true
        }
        
        if let expenses = await catModel.fetchExpensesByCategory(category) {
            self.expenses = expenses
        
            
            if setChartAsNew {
                /// Set the scrollPosition to which ever is smaller, the idealStartDate, or the maxAvailStartDate.
                let maxAvailStartDate = expenses.first?.date ?? Date()
                let idealStartDate = Calendar.current.date(byAdding: .day, value: -(365 * visibleYearCount), to: expenses.last?.date ?? Date())!
                
                
                
                
                chartScrollPosition = maxAvailStartDate < idealStartDate ? idealStartDate : maxAvailStartDate
                
                print("\(chartScrollPosition) -- \(maxAvailStartDate) -- \(idealStartDate)")
                
                isLoadingHistory = false
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
        var expense: CBBudget
        
        @State private var backgroundColor: Color = .clear
        
        var body: some View {
            VStack(spacing: 0) {
                HStack {
                    Text("\(expense.date, format: .dateTime.month(.wide)) \(String(expense.date.year))")
                    Spacer()
                    Text("\(expense.amountString)")
                }
                .padding(.vertical, 6)
                Divider()
            }
            .contentShape(Rectangle())
            .background(backgroundColor)
            .onHover { backgroundColor = $0 ? .gray.opacity(0.2) : .clear }
            .onTapGesture {
                calModel.sCategories = [category]
                
                calModel.categoryFilterWasSetByCategoryPage = true
                let monthEnum = NavDestination.getMonthFromInt(expense.date.month)
                calModel.sYear = expense.date.year
                
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
    }
    
}
