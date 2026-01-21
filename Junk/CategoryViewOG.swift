////
////  CategoryViewOG.swift
////  MakeItRain
////
////  Created by Cody Burnett on 5/7/25.
////
//
//
//import SwiftUI
//import Charts
//
//struct CategoryViewOG: View {
//    
//    //@Local(\.colorTheme) var colorTheme
//    @AppStorage("chartVisibleYearCount") var chartVisibleYearCount: CategoryAnalyticChartRange = .year1
//    @AppStorage("selectedCategoryTab") var selectedCategoryTab: String = "details"
//    @AppStorage("showAverageOnCategoryChart") var showAverageOnCategoryChart: Bool = true
//    @AppStorage("showBudgetOnCategoryChart") var showBudgetOnCategoryChart: Bool = true
//    @AppStorage("showExpensesOnCategoryChart") var showExpensesOnCategoryChart: Bool = true
//    @AppStorage("showAllCategoryChartData") var showAllChartData = false
//    
//    #if os(macOS)
//    @Environment(\.openWindow) private var openWindow
//    @Environment(\.dismissWindow) private var dismissWindow
//    #endif
//    @Environment(\.dismiss) var dismiss
//    
//    
//    @Bindable var category: CBCategory
//    @Bindable var catModel: CategoryModel
//    @Bindable var calModel: CalendarModel
//    @Bindable var keyModel: KeywordModel
//    /// This is only here to blank out the selection hilight on the iPhone list
//    @Binding var editID: String?
//    
//    @FocusState private var focusedField: Int?
//    @State private var showDeleteAlert = false
//    @State private var labelWidth: CGFloat = 20.0
//    @State private var showSymbolPicker = false
//    @State private var data: Array<AnalyticData> = []
//    @State private var showMonth = false
//    @State private var rawSelectedDate: Date?
//    @State private var chartScrolledToDate: Date = Date()
//    
//    @State private var fetchYearStart = AppState.shared.todayYear - 10
//    @State private var fetchYearEnd = AppState.shared.todayYear
//    
//    @State private var isLoadingHistory = true
//    @State private var isLoadingMoreHistory = false
//    //@State private var safeToLoadMoreHistory = false
//    
//    
//    //@Namespace private var monthNavigationNamespace
//    
//    var title: String { category.action == .add ? "New Category" : "Edit Category" }
//    
//    var selectedMonth: AnalyticData? {
//        guard let rawSelectedDate else { return nil }
//        return data.first {
//            Calendar.current.isDate(rawSelectedDate, equalTo: $0.date, toGranularity: .month)
//        }
//    }
//    
//    
//    
//    var displayData: Array<AnalyticData> {
//        if chartVisibleYearCount == .yearToDate {
//            return data
//                .filter { $0.year == Calendar.current.dateComponents([.year], from: .now).year! }
//        } else {
//            return data
//        }
//    }
//    
//    var visibleDateRangeForHeader: ClosedRange<Date> {
//        /// Check if the date range of the data is within the visibleRange. Crop accordingly.
//        let maxAvailEndDate = data.last?.date.endDateOfMonth ?? Date().endDateOfMonth
//        var idealEndDate: Date = Date().endDateOfMonth
//        
//        if visibleYearCount != 0 {
//            idealEndDate = Calendar.current.date(byAdding: .day, value: (365 * visibleYearCount), to: chartScrolledToDate)!
//        }
//        
//        var endRange: Date
//        if visibleYearCount == 0 {
//            endRange = idealEndDate
//        } else {
//            endRange = idealEndDate > maxAvailEndDate ? maxAvailEndDate : idealEndDate
//        }
//        guard chartScrolledToDate < endRange else { return endRange...endRange }
//        return chartScrolledToDate...endRange
//    }
//    
//    var visibleTotal: Double {
//        /// Calculate the total of the data currently in the chart visible range.
//        data
//            .filter { visibleDateRangeForHeader.contains($0.date) }
//            .map { $0.expenses }
//            .reduce(0, +)
//    }
//    
//    var visibleYearCount: Int {
//        chartVisibleYearCount.rawValue == 0 ? 1 : chartVisibleYearCount.rawValue
//    }
//    
//    var visibleChartAreaDomain: Int {
//        /// Check if the date range of the data is within the visibleChartAreaDomain. Crop accordingly.
//        let minDate = data.first?.date ?? Date()
//        let maxDate = data.last?.date ?? Date()
//        
//        let daysBetweenMinAndMax = Calendar.current.dateComponents([.day], from: minDate, to: maxDate).day ?? 0
//        let availDays = numberOfDays(daysBetweenMinAndMax)
//        var idealDays: Int
//        
//        if chartVisibleYearCount == .yearToDate {
//            let components = Calendar.current.dateComponents([.year], from: .now)
//            let firstOfYear = Calendar.current.date(from: components)!
//            let daysSoFarThisYear = Calendar.current.dateComponents([.day], from: firstOfYear, to: .now).day ?? 0
//            idealDays = numberOfDays(daysSoFarThisYear)
//        } else {
//            idealDays = numberOfDays(365 * visibleYearCount)
//        }
//        
//        if availDays == 0 {
//            return numberOfDays(30)
//        } else {
//            let isTooManyIdealDays = idealDays > availDays
//            return isTooManyIdealDays ? availDays : idealDays
//        }
//    }
//    
//    var minExpense: Double { data.map { $0.expenses }.min() ?? 0 }
//    var maxExpense: Double { data.map { $0.expenses }.max() ?? 0 }
//    
//    
//    var body: some View {
//        Group {
//            #if os(iOS)
//            TabView(selection: $selectedCategoryTab) {
//                Tab(value: "details") {
//                    categoryPage
//                } label: {
//                    Label("Details", systemImage: "list.bullet")
//                }
//                
//                Tab(value: "analytics") {
//                    chartPage
//                } label: {
//                    Label("Insights", systemImage: "chart.xyaxis.line")
//                }
//            }
//            .tint(category.color)
//            #else
//            
//            VStack {
//                Group {
//                    if selectedCategoryTab == "details" {
//                        categoryPage
//                    } else {
//                        chartPage
//                    }
//                }
//                .frame(maxHeight: .infinity)
//                
//                fakeMacTabBar
//            }
//            
//            #endif
//        }
//        .task {
//            print("TASK")
//            await prepareCategoryView()
//        }
//        .confirmationDialog("Delete \"\(category.title)\"?", isPresented: $showDeleteAlert, actions: {
//            Button("Yes", role: .destructive) { deleteCategory() }
//            Button("No", role: .cancel) { showDeleteAlert = false }
//        }, message: {
//            #if os(iOS)
//            Text("Delete \"\(category.title)\"?\nThis will not delete any associated transactions.")
//            #else
//            Text("This will not delete any associated transactions.")
//            #endif
//        })
//    }
//    
//    
//    var fakeMacTabBar: some View {
//        HStack(spacing: 0) {
//            Rectangle()
//                .fill(.clear)
//                .frame(height: 50)
//                .contentShape(Rectangle())
//                .overlay {
//                    Label("Details", systemImage: "list.bullet")
//                        .foregroundStyle(selectedCategoryTab == "details" ? category.color : .gray)
//                }
//                .onTapGesture {
//                    selectedCategoryTab = "details"
//                }
//            Rectangle()
//                .fill(.clear)
//                .frame(height: 50)
//                .contentShape(Rectangle())
//                .overlay {
//                    Label("Insights", systemImage: "chart.xyaxis.line")
//                        .foregroundStyle(selectedCategoryTab == "analytics" ? category.color : .gray)
//                }
//                .onTapGesture {
//                    selectedCategoryTab = "analytics"
//                }
//        }
//        //.fixedSize(horizontal: false, vertical: true)
//        .frame(height: 50)
//    }
//    
//    
//    
//    
//    // MARK: - Category Edit Page Views
//    var categoryPage: some View {
//        StandardContainer {
//            titleRow
//            budgetRow
//            StandardDivider()
//            
//            typeRow
//            StandardDivider()
//            
//            colorRow
//            StandardDivider()
//            
//            symbolRow
//            StandardDivider()
//            
//        } header: {
//            SheetHeader(title: title, close: { closeSheet() }, view3: { deleteButton })
//        }
//        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
//        
//        /// Just for formatting.
//        .onChange(of: focusedField) {
//            if $1 == 1 {
//                if category.amount == 0.0 {
//                    category.amountString = ""
//                }
//            } else {
//                if $0 == 1 {
//                    category.amountString = category.amount?.currencyWithDecimals()
//                }
//            }
//        }
//        .sheet(isPresented: $showSymbolPicker) {
//            SymbolPicker(selected: $category.emoji, color: category.color)
//                #if os(macOS)
//                .frame(minWidth: 300, minHeight: 500)
//                .presentationSizing(.fitted)
//            //.frame(width: 300)
//                #endif
//        }
//    }
//    
//    
//    var titleRow: some View {
//        LabeledRow("Name", labelWidth) {
//            #if os(iOS)
//            StandardUITextField("Title", text: $category.title, onSubmit: {
//                focusedField = 1
//            }, toolbar: {
//                KeyboardToolbarView(focusedField: $focusedField)
//            })
//            .cbFocused(_focusedField, equals: 0)
//            .cbClearButtonMode(.whileEditing)
//            .cbSubmitLabel(.next)
//            #else
//            StandardTextField("Title", text: $category.title, focusedField: $focusedField, focusValue: 0)
//                .onSubmit { focusedField = 1 }
//            #endif
//        }
//    }
//    
//    
//    var budgetRow: some View {
//        LabeledRow("Budget", labelWidth) {
//            #if os(iOS)
//            StandardUITextField("Monthly Amount", text: $category.amountString ?? "", toolbar: {
//                KeyboardToolbarView(focusedField: $focusedField, accessoryImage3: "plus.forwardslash.minus", accessoryFunc3: {
//                    Helpers.plusMinus($category.amountString ?? "")
//                })
//            })
//            .cbFocused(_focusedField, equals: 1)
//            .cbClearButtonMode(.whileEditing)
//            .cbKeyboardType(.decimalPad)
//            #else
//            StandardTextField("Monthly Amount", text: $category.amountString ?? "", focusedField: $focusedField, focusValue: 1)
//            #endif
//        }
//    }
//    
//    
//    var typeRow: some View {
//        LabeledRow("Type", labelWidth) {
//            Picker("", selection: $category.isIncome) {
//                Text("Expense")
//                    .tag(false)
//                Text("Income")
//                    .tag(true)
//            }
//            .pickerStyle(.segmented)
//            .labelsHidden()
//        }
//    }
//    
//    
//    var colorRow: some View {
//        LabeledRow("Color", labelWidth) {
//            #if os(iOS)
//            StandardColorPicker(color: $category.color)
//            #else
//            HStack {
//                ColorPicker("", selection: $category.color, supportsOpacity: false)
//                    .labelsHidden()
//                Capsule()
//                    .fill(category.color)
//                    .frame(height: 30)
//                    .onTapGesture {
//                        AppState.shared.showToast(title: "Color Picker", subtitle: "Touch the circle to the left to change the color.", body: nil, symbol: category.emoji ?? "theatermask.and.paintbrush", symbolColor: category.color)
//                    }
//            }
//            #endif
//        }
//    }
//    
//    
//    var symbolRow: some View {
//        LabeledRow("Symbol", labelWidth) {
//            HStack {
//                Image(systemName: category.emoji ?? "questionmark.circle.fill")
//                    .font(.system(size: 100))
//                    .foregroundStyle(category.color.gradient)
//                Spacer()
//                
//            }
//            .contentShape(Rectangle())
//            .onTapGesture {
//                showSymbolPicker = true
//            }
//        }
//        
//        
////        LabeledRow("Symbol", labelWidth) {
////            #if os(macOS)
////            HStack {
////                Button {
////                    //                      Task {
////                    //                          focusedField = .emoji
////                    //                          try? await Task.sleep(for: .milliseconds(100))
////                    //                          NSApp.orderFrontCharacterPalette($category.emoji)
////                    //                      }
////                    showSymbolPicker = true
////                } label: {
////                    Image(systemName: category.emoji ?? "questionmark.circle.fill")
////                        .foregroundStyle(category.color)
////                }
////                .buttonStyle(.codyStandardWithHover)
////                Spacer()
////            }
////
////            #else
////            HStack {
////                Image(systemName: category.emoji ?? "questionmark.circle.fill")
////                    .font(.title2)
////                    .foregroundStyle(category.color.gradient)
////
////                Spacer()
////            }
////            .contentShape(Rectangle())
////            .onTapGesture {
////                showSymbolPicker = true
////            }
////            #endif
////        }
//    }
//    
//    
//    var deleteButton: some View {
//        Button {
//            showDeleteAlert = true
//        } label: {
//            Image(systemName: "trash")
//        }
//        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
//    }
//    
//    
//    
//    
//    // MARK: - Chart Page Views
//    var chartPage: some View {
//        Group {
//            if category.action == .add {
//                ContentUnavailableView("Insights are not available when adding a new category", systemImage: "square.stack.3d.up.slash.fill")
//            } else {
//                StandardContainer {
//                    chartVisibleYearPicker
//                        //.rowBackground()
//                    
//                    Section {
//                        chartHeader
//                        Divider()
//                        
//                        theChart
//                            .padding(.bottom, 30)
//                                                        
//                        Text("Options")
//                            .foregroundStyle(.gray)
//                            .font(.subheadline)
//                        Divider()
//                        
//                        Toggle(isOn: $showExpensesOnCategoryChart.animation()) {
//                            Text("Show Expenses")
//                        }
//                        
//                        Toggle(isOn: $showBudgetOnCategoryChart.animation()) {
//                            Text("Show Budget")
//                        }
//                        
//                        Toggle(isOn: $showAverageOnCategoryChart.animation()) {
//                            Text("Show Average")
//                        }
//                    }
//                    
//                    Divider()
//                    
//                    Spacer()
//                        .frame(minHeight: 10)
//                    
//                    rawDataList
//                } header: {
//                    SheetHeader(
//                        title: title,
//                        close: { closeSheet() },
//                        view1: { refreshButton },
//                        //view2: { ProgressView().opacity(isLoadingMoreHistory ? 1 : 0).tint(.none) },
//                        view3: { deleteButton }
//                    )
//                }
//                .listStyle(.plain)
//                #if os(iOS)
//                .listSectionSpacing(50)
//                #endif
//                .opacity(isLoadingHistory ? 0 : 1)
//                .overlay { ProgressView("Loading Insights…").tint(.none).opacity(isLoadingHistory ? 1 : 0) }
//                .focusable(false)
//            }
//        }
//    }
//    
//    
//    var chartVisibleYearPicker: some View {
//        Picker("", selection: $chartVisibleYearCount.animation()) {
//            Text("YTD").tag(CategoryAnalyticChartRange.yearToDate)
//            Text("1Y").tag(CategoryAnalyticChartRange.year1)
//            Text("2Y").tag(CategoryAnalyticChartRange.year2)
//            Text("3Y").tag(CategoryAnalyticChartRange.year3)
//            Text("4Y").tag(CategoryAnalyticChartRange.year4)
//            Text("5Y").tag(CategoryAnalyticChartRange.year5)
//        }
//        .pickerStyle(.segmented)
//        .labelsHidden()
//        .onChange(of: chartVisibleYearCount) { oldValue, newValue in
//            setChartScrolledToDate(newValue)
//        }
//    }
//    
//    
//    var chartHeader: some View {
//        HStack {
//            VStack(alignment: .leading) {
//                Text("\(category.isIncome ? "Income" : "Expenses")")
//                    .foregroundStyle(.gray)
//                    .font(.title3)
//                    .bold()
//                
//                Text("\(visibleTotal.currencyWithDecimals())")
//                
//                HStack(spacing: 5) {
//                    Text(visibleDateRangeForHeader.lowerBound.string(to: .monthNameYear))
//                    Text("-")
//                    Text(visibleDateRangeForHeader.upperBound.string(to: .monthNameYear))
//                }
//                .foregroundStyle(.gray)
//                .font(.caption)
//            }
//            
//            Spacer()
//            
//            if let selectedMonth {
//                VStack(spacing: 0) {
//                    Text("\(selectedMonth.date, format: .dateTime.month(.wide)) \(String(selectedMonth.date.year))")
//                        .bold()
//                    HStack {
//                        Text("\(selectedMonth.expensesString)")
//                            .bold()
//                        Text("\(selectedMonth.budgetString)")
//                            .bold()
//                            .foregroundStyle(.secondary)
//                        
//                        ChartCircleDot(budget: selectedMonth.budget, expenses: selectedMonth.expenses, color: .white, size: 20)
//                        
//                        //Text("\(createPercentage())%")
//                    }
//                }
//                .foregroundStyle(.white)
//                .padding(12)
//                .frame(width: 160)
//                .background(
//                    RoundedRectangle(cornerRadius: 10)
//                        .fill(category.color)
//                )
//            } else {
//                dummySelectMonthViewForSpacingPurposes
//            }
//        }
//    }
//    
//    
//    var dummySelectMonthViewForSpacingPurposes: some View {
//        VStack(spacing: 0) {
//            Text("hey")
//                .bold()
//                .opacity(0)
//            
//            HStack {
//                Text("hey")
//                    .bold()
//                    .opacity(0)
//                
//                ChartCircleDot(budget: 0, expenses: 0, color: .white, size: 20)
//                    .background(Color.black)
//                    .opacity(0)
//            }
//        }
//        .foregroundStyle(.white)
//        .padding(12)
//        .frame(width: 160)
//        .background(
//            RoundedRectangle(cornerRadius: 10)
//                .fill(.clear)
//        )
//    }
//    
//    
//    var theChart: some View {
//        Chart {
//            if let selectedMonth {
////                RuleMark(x: .value("Selected Date", selectedMonth.date, unit: .day))
////                    .foregroundStyle(category.color)
////                    .offset(yStart: -15)
////                    .zIndex(-1)
//                
//                
//                RectangleMark(xStart: .value("Start Date", selectedMonth.date, unit: .month), xEnd: .value("End Date", selectedMonth.date.endDateOfMonth, unit: .day))
//                    .foregroundStyle(category.color.opacity(0.5))
//                    //.offset(yStart: -15)
//                    .zIndex(-5)
//                
//            }
//                        
//            if showAverageOnCategoryChart {
////                RuleMark(
////                    xStart: .value("Start Date", chartScrolledToDate.startDateOfMonth, unit: .month),
////                    xEnd: .value("End Date", data.last?.date.endDateOfMonth ?? Date(), unit: .month),
////                    y: .value("Average", data.map { $0.expenses }.average())
////                )
////                .foregroundStyle(.gray.opacity(0.7))
////                .zIndex(-1)
////                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
//                
//                RuleMark(y: .value("Average", data.map { $0.expenses }.average()))
//                    //.foregroundStyle(category.color.opacity(0.5))
//                    .foregroundStyle(.gray.opacity(0.7))
//                    .zIndex(-1)
//                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
//            }
//            
//            if showBudgetOnCategoryChart {
//                ForEach(displayData) { data in
//                    LineMark(
//                        x: .value("Date", data.date, unit: .month),
//                        y: .value("Budget", data.budget),
//                        series: .value("", "Budget")
//                    )
//                    //.foregroundStyle(category.color.opacity(0.7))
//                    .foregroundStyle(category.color)
//                    .interpolationMethod(.catmullRom)
//                    .zIndex(-1)
//                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
//                }
//            }
//            
//            if showExpensesOnCategoryChart {
//                ForEach(displayData) { data in
//                    LineMark(
//                        x: .value("Date", data.date, unit: .month),
//                        y: .value("Amount", data.expenses),
//                        series: .value("", "Expenses")
//                    )
//                    .foregroundStyle(category.color)
//                    .interpolationMethod(.catmullRom)
//                    //.lineStyle(.init(lineWidth: 2))
//                    .symbol {
//                        if data.expenses > 0 {
//                            Circle()
//                                .fill(category.color)
//                                .frame(width: 6, height: 6)
//                            //.opacity(rawSelectedDate == nil || start.date == selectedStartingAmount?.date ? 1 : 0.3)
//                        }
//                    }
//                    
//                    AreaMark(
//                        x: .value("Date", data.date, unit: .month),
//                        yStart: .value("Max", data.expenses),
//                        yEnd: .value("Min", minExpense)
//                    )
//                    .interpolationMethod(.catmullRom)
//                    .foregroundStyle(LinearGradient(
//                        colors: [category.color, .clear],
//                        startPoint: .top,
//                        endPoint: .bottom)
//                    )
//                }
//            }
//        }
//        .frame(minHeight: 150)
//        .if(chartVisibleYearCount != .yearToDate) {
//            $0.chartScrollableAxes(.horizontal)
//        }
//        .chartXVisibleDomain(length: visibleChartAreaDomain)
//        //.chartScrollPosition(initialX: data.last?.date ?? Date())
//        .chartScrollPosition(x: $chartScrolledToDate)
//        .chartXSelection(value: $rawSelectedDate)
//        .chartYScale(domain: [minExpense, maxExpense + (maxExpense * 0.2)])
////        .chartScrollTargetBehavior(
////            .valueAligned(
////                matching: DateComponents(day: 1),
////                majorAlignment: .matching(DateComponents(day: 1))
////            )
////        )
//        //.chartOverlay { ChartOverlayView(selectedMonth: selectedMonth, proxy: $0) }
//        .chartYAxis {
//            AxisMarks {
//                AxisGridLine()
//            //AxisMarks(values: .automatic(desiredCount: 6)) {
//               let value = $0.as(Int.self)!
//               AxisValueLabel {
//                   Text("$\(value)")
//               }
//           }
//        }
//        .chartXAxis {
//            AxisMarks(position: .bottom, values: .automatic) { _ in
//                AxisTick()
//                AxisGridLine()
//                AxisValueLabel(centered: chartVisibleYearCount == .yearToDate)
//            }
//        }
//        .chartLegend(position: .top, alignment: .leading)
//        .chartForegroundStyleScale([
//            "Total: \((data.map { $0.expenses }.reduce(0.0, +).currencyWithDecimals()))": category.color,
//            
//            "Average: \((data.map { $0.expenses }.average()).currencyWithDecimals())": Color.gray
//        ])
//        .padding(.bottom, 10)
//    }
//    
//    
//    var refreshButton: some View {
//        Button {
//            Task {
//                fetchYearStart = AppState.shared.todayYear - 10
//                fetchYearEnd = AppState.shared.todayYear
//                data.removeAll()
//                isLoadingHistory = true
//                await fetchHistory(setChartAsNew: true)
//            }
//        } label: {
//            Image(systemName: "arrow.triangle.2.circlepath")
//        }
//    }
//    
//    
//    var rawDataList: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            Text("Data (\(String(fetchYearStart)) - \(String(AppState.shared.todayYear)))")
//                .foregroundStyle(.gray)
//                .font(.subheadline)
//                //.padding(.leading, 6)
//            Divider()
//            
//            DisclosureGroup(isExpanded: $showAllChartData) {
//                VStack(spacing: 0) {
//                    Divider()
//                        .padding(.leading, 25)
//                    
//                    LazyVStack {
//                        ForEach(displayData.sorted(by: { $0.date > $1.date })) { data in
//                            RawDataLineItem(category: category, data: data)
//                                .padding(.leading, 25)
//                                .onScrollVisibilityChange {
//                                    if $0 && data.id == displayData.sorted(by: { $0.date > $1.date }).last?.id {
//                                        fetchMoreHistory()
//                                    }
//                                }
//                        }
//                    }
//                }
//            } label: {
//                Text("Show All")
//                    .onTapGesture {
//                        withAnimation {
//                            showAllChartData.toggle()
//                        }
//                    }
//            }
//            
//            //.foregroundStyle(category.color)
//            .tint(category.color)
//            //.padding(.vertical, 8)
//            .padding(.bottom, 10)
//            //.rowBackground()
//            .onChange(of: calModel.showMonth) { oldValue, newValue in
//                if newValue == false && oldValue == true {
//                    Task {
//                        await fetchHistory(setChartAsNew: false)
//                    }
//                }
//            }
//            .onReceive(NotificationCenter.default.publisher(for: .updateCategoryAnalytics, object: nil)) { _ in
//                Task {
//                    await fetchHistory(setChartAsNew: false)
//                }
//            }
//        }
//    }
//    
//    
//    struct ChartOverlayView: View {
//        var selectedMonth: AnalyticData?
//        var proxy: ChartProxy
//        var category: CBCategory
//        
//        var body: some View {
//            GeometryReader { geometry in
//                if let selectedMonth {
//                    if let _ = proxy.position(forX: selectedMonth.date) {
//                        VStack(spacing: 0) {
//                            Text("\(selectedMonth.date, format: .dateTime.month(.wide)) \(String(selectedMonth.date.year))")
//                                .bold()
//                            HStack {
//                                Text("\(selectedMonth.expensesString)")
//                                    .bold()
//                                Text("\(selectedMonth.budgetString)")
//                                    .bold()
//                                    .foregroundStyle(.secondary)
//                                
//                                ChartCircleDot(budget: selectedMonth.budget, expenses: selectedMonth.expenses, color: .white, size: 20)
//                                
//                                //Text("\(createPercentage())%")
//                            }
//                        }
//                        .foregroundStyle(.white)
//                        .padding(12)
//                        .frame(width: 160)
//                        .background(
//                            RoundedRectangle(cornerRadius: 10)
//                                .fill(category.color)
//                        )
//                        .position(x: geometry.frame(in: .local).midX, y: -40)
//                        .zIndex(100)
//                    }
//                }
//            }
//        }
//        
//    }
//    
//    
//    struct RawDataLineItem: View {
//        #if os(macOS)
//        @Environment(\.openWindow) private var openWindow
//        @Environment(\.dismissWindow) private var dismissWindow
//        #endif
//        @Environment(CalendarModel.self) var calModel
//        
//        @Bindable var category: CBCategory
//        var data: AnalyticData
//        
//        @State private var backgroundColor: Color = .clear
//        
//        var body: some View {
//            VStack(spacing: 0) {
//                HStack {
//                    Text("\(data.date, format: .dateTime.month(.wide)) \(String(data.year))")
//                    Spacer()
//                    Text("\(data.expensesString)")
//                }
//                .padding(.vertical, 6)
//                Divider()
//            }
//            .contentShape(Rectangle())
//            .background(backgroundColor)
//            .onHover { backgroundColor = $0 ? .gray.opacity(0.2) : .clear }
//            .onTapGesture { openMonthlySheet() }
//        }
//        
//        
//        func openMonthlySheet() {
//            calModel.sCategories = [category]
//            
//            calModel.categoryFilterWasSetByCategoryPage = true
//            let monthEnum = NavDestination.getMonthFromInt(data.month)
//            calModel.sYear = data.year
//            
//            #if os(iOS)
//            if AppState.shared.isIpad {
//                calModel.isShowingFullScreenCoverOnIpad = true
//            }
//            
//            NavigationManager.shared.selectedMonth = monthEnum
//            calModel.showMonth = true
//            
//            #else
//            AppState.shared.monthlySheetWindowTitle = "\(category.title) Expenses For \(monthEnum?.displayName ?? "N/A") \(String(calModel.sYear))"
//            dismissWindow(id: "monthlyWindow")
//            openWindow(id: "monthlyWindow", value: monthEnum)
//            //calModel.windowMonth = monthEnum
//            //openWindow(id: "monthlyWindow")
//            #endif
//        }
//    }
//    
//    
//    
//        
//    // MARK: - Functions
//    func numberOfDays(_ num: Int) -> Int { (3600 * 24) * num }
//
//    
//    func createPercentage() -> Int {
//        if let selectedMonth {
//            var per = ((selectedMonth.expenses / selectedMonth.budget) * 100)
//            let rounded = per.rounded()
//            
//            return Int(rounded)
//        } else {
//            return 0
//        }
//    }
//    
//    
//    func setChartScrolledToDate(_ newValue: CategoryAnalyticChartRange) {
//        /// Set the scrollPosition to which ever is smaller, the targetDate, or the minDate.
//        let minDate = data.first?.date ?? Date()
//        let maxDate = data.last?.date ?? Date()
//        var targetDate: Date
//        /// If 0, which means it's YTD, start with the maxDate and work backwards to January 1st.
//        if newValue.rawValue == 0 {
//            let components = Calendar.current.dateComponents([.year], from: .now)
//            targetDate = Calendar.current.date(from: components)!
//        } else {
//            ///-365, -730, etc
//            let value = -(365 * newValue.rawValue)
//            /// start with the maxDate and work backwards using the value.
//            targetDate = Calendar.current.date(byAdding: .day, value: value, to: maxDate)!
//        }
//        
//        /// chartScrolledToDate is the beginning of the chart view.
//        if targetDate < minDate && newValue.rawValue != 0 {
//            chartScrolledToDate = minDate
//        } else {
//            chartScrolledToDate = targetDate
//        }
//    }
//    
//    
//    func closeSheet() {
//        if calModel.categoryFilterWasSetByCategoryPage {
//            calModel.sCategories.removeAll()
//            calModel.categoryFilterWasSetByCategoryPage = false
//        }
//        editID = nil
//        dismiss()
//        #if os(macOS)
//        dismissWindow(id: "monthlyWindow")
//        #endif
//    }
//    
//    
//    func prepareCategoryView() async {
//        category.deepCopy(.create)
//        /// Just for formatting.
//        category.amountString = category.amount?.currencyWithDecimals()
//        catModel.upsert(category)
//        
//        #if os(macOS)
//        /// Focus on the title textfield.
//        focusedField = 0
//        #else
//        if category.action == .add {
//            focusedField = 0
//        }
//        #endif
//        
//        if category.action == .add {
//            selectedCategoryTab = "details"
//        }
//        
//        if category.action != .add {
//            await fetchHistory(setChartAsNew: true)
//        }
//    }
//    
//    
//    func deleteCategory() {
//        Task {
//            dismiss()
//            await catModel.delete(category, andSubmit: true, calModel: calModel, keyModel: keyModel, eventModel: eventModel)
//        }
//    }
//    
//    
//    func fetchMoreHistory() {
//        Task {
//            isLoadingMoreHistory = true
//            fetchYearStart -= 10
//            fetchYearEnd -= 10
//            print("fetching more history... \(fetchYearStart) - \(fetchYearEnd)")
//            await fetchHistory(setChartAsNew: false)
//        }
//    }
//    
//    
//    func fetchHistory(setChartAsNew: Bool) async {
//        if setChartAsNew {
//            isLoadingHistory = true
//        }
//        
//        
//        let model = CategoryAnalysisRequestModel(categoryID: category.id, fetchYearStart: fetchYearStart, fetchYearEnd: fetchYearEnd)
//        
//        if let data = await catModel.fetchExpensesByCategory(model) {
//            
//            withAnimation {
//                //var localData: Array<AnalyticData> = []
//                for each in data {
//                    if let index = self.data.firstIndex(where: { $0.month == each.month && $0.year == each.year }) {
//                        self.data[index].budgetString = each.amountString
//                        self.data[index].expensesString = each.amountString2
//                    } else {
//                        let anal = AnalyticData(month: each.month, year: each.year, budgetString: each.amountString, expensesString: each.amountString2)
//                        self.data.append(anal)
//                    }
//                    
//                }
//                
//                
//                self.data.sort(by: { $0.date < $1.date })
//            }
//
//            
//                    
//            if setChartAsNew {
//                /// Set the scrollPosition to which ever is smaller, the idealStartDate, or the maxAvailStartDate.
//                let minDate = data.first?.date ?? Date()
//                let maxDate = data.last?.date ?? Date()
//                let idealDate = Calendar.current.date(byAdding: .day, value: -(365 * visibleYearCount), to: maxDate)!
//                                
//                if chartVisibleYearCount == .yearToDate {
//                    let components = Calendar.current.dateComponents([.year], from: .now)
//                    chartScrolledToDate = Calendar.current.date(from: components)!
//                } else {
//                    chartScrolledToDate = minDate < idealDate ? idealDate : minDate
//                }
//            
//                isLoadingHistory = false
//            }
//        }
//        
//        isLoadingMoreHistory = false
//    }
//}
