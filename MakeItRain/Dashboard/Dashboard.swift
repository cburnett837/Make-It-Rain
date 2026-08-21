//
//  Dashboard.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/21/26.
//

import SwiftUI
import Charts

struct Dashboard: View {
    @Environment(\.colorScheme) var colorScheme
    #if os(macOS)
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appearsActive) var appearsActive
    #endif
    
    //@Local(\.colorTheme) var colorTheme
    @Environment(FuncModel.self) private var funcModel
    @Environment(CalendarProps.self) private var calProps
    @Environment(CalendarModel.self) private var calModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(PayMethodModel.self) private var payModel
    
    #if os(iOS)
    @Binding var navPath: [NavDest]
    #else
    @State private var navPath: [NavDest] = []
    #endif
    @Bindable var model: DashboardModel
    var isForSelectedMonth: Bool
    
    //@State private var showPayMethodSheet: Bool = false
    //@State private var showCategorySheet = false
    //@State private var showOptionsSheet = false
    @State private var showExpensiveViews = true
    @State private var isBreakdownExpanded = false
    let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 30, alignment: .top), count: 2)
    
    var totalExpenses: Decimal {
        let trans = calModel.getTransactions(meth: model.payMethod)
            .filter { $0.dateComponents?.month == calModel.sMonth.actualNum }
            .filter { $0.dateComponents?.year == calModel.sMonth.year }
        return TransactionHelper.All.Amount.actualSpend(from: trans)
    }
    
    
    var transWithAlerts: Array<CBTransaction> {
        calModel.getTransactions(meth: model.payMethod, includeExcluded: true)
        .filter({
            $0.notifyOnDueDate
            && $0.date?.day == Date().day
            && $0.notificationOffset == 0
        })
    }
    
    var cardsDueToday: Array<CBPaymentMethod> {
        payModel.paymentMethods.filter({ $0.dueDate == Date().day })
    }
    
    var showDivider: Bool {
        isForSelectedMonth || !transWithAlerts.isEmpty || !cardsDueToday.isEmpty
    }
    
    var body: some View {
        #if os(iOS)
        root
        #else
        NavigationStack(path: $navPath) {
            root
                .navigationDestination(for: NavDest.self) { dest in
                    switch dest {
                    case .dashboard:
                        EmptyView()
                        
                    case .dashboardTransactionList(let data, let category):
                        DashboardTransactionList(data: data, category: category)
                        
                    case .dashboardNumericBreakdown:
                        DashboardNumericDetails(model: calModel.dashboardModel, isForSelectedMonth: true)
                        
                    case .plaidRejectPage:
                        EmptyView()
//                                ClearPlaidBeforeDateView(selectedMeth: $selectedPlaidFilterMeth, navPath: $navPath)
                        
                    case .budgets:
                        MonthlyBudgetTable()
                        
                    case .transactionList:
                        EmptyView()
                        //TransactionListView(showTransactionListSheet: $showTransactionListSheet)
                        
                    case .multiTransChangeDate:
                        EmptyView()
//                                MultiSelectChangeDatePage(navPath: $navPath)
                        
                    case .budgetOverview(let budget):
                        BudgetOverview(budget: budget, location: .monthList)
                        
                    default:
                        Text("That destination is not supported from the calendar.")
                    }
                }
        }
        #endif
    }
    
    
    @ViewBuilder
    var root: some View {
        @Bindable var calModel = calModel
        
        contentContainer
            #if os(iOS)
            .onShake {
                Task {
                    await model.initialFetchIfApplicable(calModel: calModel)
                }
            }
            #endif
            .navigationTitle("Dashboard\(AppState.shared.devMode ? " (Dev)" : "")")
            .if(isForSelectedMonth) {
                $0.navigationSubtitle("\(calModel.sMonth.name) \(String(calModel.sMonth.year))")
            }
            .if(!isForSelectedMonth) {
                $0.navigationSubtitle("\(model.formattedDateRange)\(model.payMethod == nil ? "" : " (\(model.payMethod!.title))")")
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(isForSelectedMonth ? .inline : .large)
            #endif
            .task {
                model.oldChangeHash = model.changeHash
                if isForSelectedMonth {
                    model.prepareData(calModel: calModel)
                }
            }
            .toolbar {
                DashboardToolbar(
                    model: model,
                    navPath: $navPath,
                    isForSelectedMonth: isForSelectedMonth
                )
            }
            .sheet(isPresented: $model.showOptionsSheet, onDismiss: {
                model.fetchIfChange(calModel: calModel)
            }) {
                DashboardOptionsSheet(
                    model: model,
                    isForSelectedMonth: isForSelectedMonth
                )
                #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
                #else
                .presentationDetents([.large])
                #endif
            }
    }
    
    
    @ViewBuilder
    var contentContainer: some View {
        if model.categories.isEmpty && model.groups.isEmpty {
            contentUnavailableView
        } else {
            ScrollView {
                #if os(iOS)
                LazyVStack(spacing: 24) {
                    theCards
                }
                .scenePadding()
                #else
                LazyVGrid(columns: gridColumns, spacing: 30) {
                    theCards
                }
                .scenePadding()
                #endif
            }
            .scrollContentBackground(.hidden)
            #if os(iOS)
            .background(Color(.systemGroupedBackground))
            #endif
            .task {
                showExpensiveViews = true
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                    showExpensiveViews = true
//                }
                
            }
        }
    }
    
    
    @ViewBuilder
    var theCards: some View {
        if isForSelectedMonth {
            if showExpensiveViews {
                Card(title: "\(calModel.sMonth.name)'s Overall Budget") {
                    HStack {
                        BudgetChart(budgetAmount: calModel.sMonth.budget, expenseAmount: totalExpenses)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                            .font(.footnote)
                    }
                    .onTapGesture {
                        if isForSelectedMonth {
                            navPath.append(NavDest.budgets)
                        }
                    }
                }
            }
        }
        
        HStack {
            if !cardsDueToday.isEmpty {
                Card(title: "Due Today") {
                    creditCardsDueTodayView
                }
            }
            
            if isForSelectedMonth && !transWithAlerts.isEmpty {
                Card(title: "Reminders") {
                    transWithAlertsTodayView
                }
            }
        }
        
        
        
        #if os(iOS)
        if showDivider {
            Divider()
        }
        #endif
        
        if AppState.shared.isIphone {
            DashboardDetailSection(model: model, data: model.data)
        } else {
            NavigationStack(path: $navPath) {
                DashboardDetailSection(model: model, data: model.data)
            }
        }
        
        if showExpensiveViews {
            Card(
                showFilterText: !model.allCatsSelected,
                title: {
                    Text("Activity By Category")
                        .padding(.leading, 12)
                        .foregroundStyle(.secondary)
                        .font(.headline)
                },
                footer: {
                    if !model.categories.filter({ $0.type == .payment }).isEmpty {
                        Text("(Note that the spending amount contains credit payments, which you may consider a transfer. To see true spending, remove the credit payment category from the filter list.)")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            //.bold()
                    } else {
                        EmptyView()
                    }
                }) {
                    DashboardActivityByCategoryChart(
                        model: model,
                        data: model.data,
                        isForSelectedMonth: isForSelectedMonth,
                        navPath: $navPath
                    )
            }
        }
        
        if showExpensiveViews {
            if isForSelectedMonth {
                Card(showFilterText: !model.allCatsSelected, title: "Cumulative Spending") {
                    BudgetCumChart(
                        budgetAmount: model.data.categoryAndGroupBudget,
                        cumTotals: model.cumTotals,
                        type: .spend
                    )
                }
                
                Card(showFilterText: !model.allCatsSelected, title: "Spending By Day") {
                    BudgetByDayChart(data: model.spendByDateTotals, type: .spend)
                }
                
            } else {
                if model.payMethod != nil {
                    DashboardStartingAmountByMonthChart(model: model, data: model.data)
                }
            }
            
            if model.data.monthlyBreakdowns.count > 1 {
                DashboardActivityByMonthChart(model: model, data: model.data)
            }
        }
        
        
        if isForSelectedMonth {
            Card(title: "Net Worth") {
                DashboardNetWorthChange()
            }
        } else if model.data.monthlyBreakdowns.count > 1 {
            DashboardNetWorthChangeChart(model: model, data: model.data)
        }
    }
    

    var contentUnavailableView: some View {
        ContentUnavailableView {
            Label("No Categories Selected", systemImage: "books.vertical")
        } description: {
            Text("Select some categories to view the dashboard.")
        } actions: {
            Button {
                model.showOptionsSheet = true
                //showCategorySheet = true
            } label: {
                Text("Select Categories")
                    .padding(4)
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    var transWithAlertsTodayView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEachWithSeparator(transWithAlerts) { trans in
                    TransactionListLine(trans: trans) {}
                        //.padding(.vertical, 8)
                } separator: {
                    Divider().padding(.vertical, 8)
                }
            }
        }
        .contentMargins(.horizontal, 0, for: .scrollIndicators)
        .frame(maxHeight: 150)
    }
    
    var creditCardsDueTodayView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEachWithSeparator(cardsDueToday) { meth in
                    HStack {
                        #if os(iOS)
                        PayMethodLogoMashup(meth: meth)
                        #else
                        PayMethodLogoMashup(meth: meth, size: 20)
                            .padding(.trailing, 10)
                        #endif

                        VStack(alignment: .leading) {
                            Text(meth.title)
                            Text(funcModel.getPlaidBalancePrettyString(meth, withTime: false) ?? "N/A")
                                .foregroundStyle(.gray)
                                .font(.caption)
                        }
                                                                    
                        Spacer()
                    }
                    //.padding(.vertical, 8)
                } separator: {
                    Divider().padding(.vertical, 8)
                }
            }
        }
        .contentMargins(.horizontal, 0, for: .scrollIndicators)
        .frame(maxHeight: 150)
    }
    
//    
//    func prepareData() {
//        let cats = model.categories + model.groups.flatMap(\.categories)
//        let trans = calModel.getTransactions(cats: cats)
//        transactions = TransactionHelper.All.Transactions.spend(from: trans)
//            .filter { $0.dateComponents?.month == calModel.sMonth.actualNum }
//            .filter { $0.dateComponents?.year == calModel.sMonth.year }
//            //.filter { $0.isExpense }
//        
//        /// Get how much has been spend up until each day.
//        BudgetHelper.calculateCumTotals(
//            calModel: calModel,
//            transactions: transactions,
//            budgetAmount: calModel.sMonth.amount,
//            cumTotals: &self.cumTotals
//        )
//    }
}



//
//fileprivate struct DashboardCompareChartOG: View {
//    @Environment(CalendarModel.self) private var calModel
//    @Bindable var model: DashboardModel
//    @Bindable var data: DashboardData
//    
//    @State private var rawSelectedAngle: Double?
//    @State private var rawSelectedBar: Double?
//    private var selectedCategory: CBCategory? {
//        //print("\(rawSelectedBar) - \(rawSelectedAngle)")
//        var theValue: Double = 0.0
//        if rawSelectedBar == nil && rawSelectedAngle == nil { return nil }
//        if let raw = rawSelectedBar { theValue = raw }
//        if let raw = rawSelectedAngle { theValue = raw }
//        //guard let rawSelectedAngle else { return nil }
//        
//        var total = 0.0
//        for cat in categories {
//            let value = max(0, (cat.allAmounts?.totalSpend ?? 0.0))
//            let nextTotal = total + value
//            
//            if theValue >= total && theValue < nextTotal {
//                return cat
//            }
//            
//            total = nextTotal
//        }
//        
//        return nil
//    }
//    
//    var isUnderBudget: Bool {
//        return data.budgetAmount >= data.allAmounts.actualSpend
//    }
//   
//    var categories: [CBCategory] {
//        return (data.categories + data.categoryGroups.flatMap(\.categories))
//            //.filter { $0.type != XrefModel.getItem(from: .categoryTypes, byEnumID: .income) }
//            .uniqued(on: { $0.id })
//            .sorted(by: Helpers.categorySorter())
//    }
//    
//    var expenseCategories: [CBCategory] { categories.filter { !$0.isIncome } }
//    var incomeCategories: [CBCategory] { categories.filter { $0.isIncome } }
//    
//    
//    @State private var annotationHeight: CGFloat = 0
//    
//    var body: some View {
////        VStack(spacing: 10) {
////            barChart
////            HStack {
////                //barChart
////                pieChart
////                Spacer()
////                DashboardChartLegend(data: data)
////            }
////        }
//        VStack(spacing: 10) {
//            HStack {
//                barChart
//                pieChart
//            }
//            DashboardChartLegend(data: data)
//        }
//        .sensoryFeedback(.selection, trigger: selectedCategory)
//        .overlay(alignment: .top) {
//            if selectedCategory != nil {
//                categoryAnnotation
//                    .frame(maxWidth: .infinity)
//                    .padding(.horizontal)
//                    .background {
//                        GeometryReader { geo in
//                            Color.clear
//                                .onAppear {
//                                    annotationHeight = geo.size.height
//                                }
//                                .onChange(of: geo.size.height) { _, newValue in
//                                    annotationHeight = newValue
//                                }
//                        }
//                    }
//                    .offset(y: -annotationHeight - 8)
//                    .zIndex(10)
//            }
//        }
//    }
//    
//    
//    var pieChart: some View {
//        Chart(expenseCategories) { cat in
//            SectorMark(
//                angle: .value("Amount", (cat.allAmounts?.totalSpend ?? 0.0)),
//                innerRadius: .ratio(0.4),
//                angularInset: 1.0
//            )
//            .cornerRadius(5)
//            .foregroundStyle(cat.color)
//            .opacity(selectedCategory == nil ? 1 : (cat.id == selectedCategory!.id ? 1 : 0.3))
//        }
//        .chartAngleSelection(value: $rawSelectedAngle)
//        .frame(height: 150)
//    }
//            
//    
//    var barChart: some View {
//        Chart {
//            if model.groups.isEmpty {
//                ForEach(expenseCategories) { cat in
//                    BarMark(
//                        x: .value("Budget", cat.budgetAmount),
//                        y: .value("Key", "Budget")
//                    )
//                    .foregroundStyle(cat.color)
//                }
//            } else {
//                RuleMark(
//                    x: .value("Budget", data.budgetAmount),
//                    yStart: .value("Start", "Actual Spending"),
//                    yEnd: .value("End", "Actual Spending")
//                )
//                .foregroundStyle(isUnderBudget ? Color.green.gradient : Color.red.gradient)
//                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
//                .zIndex(1)
//            }
//                                    
//            ForEach(expenseCategories) { cat in
//                BarMark(
//                    x: .value("Amount", cat.allAmounts?.actualSpend ?? 0.0),
//                    y: .value("Key", "Actual Spending")
//                )
//                .foregroundStyle(cat.color)
//                .opacity(selectedCategory == nil ? 1 : (cat.id == selectedCategory!.id ? 1 : 0.3))
//                .zIndex(0)
//            }
//            
//            ForEach(incomeCategories) { cat in
//                let amount = cat.isRegularIncome ? cat.allAmounts?.regularIncome : cat.allAmounts?.irregularIncome
//                BarMark(
//                    x: .value("Amount", amount ?? 0.0),
//                    y: .value("Key", "Income")
//                )
//                .foregroundStyle(cat.color)
//                //.opacity(selectedCategory == nil ? 1 : (cat.id == selectedCategory!.id ? 1 : 0.3))
//                .zIndex(0)
//            }
//        }
//        .frame(height: 150)
//        .chartXSelection(value: $rawSelectedBar)
//        .chartXAxis {
//            AxisMarks {
//                let value = $0.as(Int.self)!
//                AxisGridLine()
//                //AxisTick()
//                //AxisValueLabel(format: .currency(code: "USD"))
//                AxisValueLabel { Text("$\(value)") }
//            }
//        }
//        .if(!model.groups.isEmpty) {
//            $0.chartYAxis {
//                AxisMarks { value in
//                    AxisGridLine()
//                    AxisTick()
//                    AxisValueLabel()
//                }
//            }
//        }
//        .chartLegend(.hidden)
//    }
//    
//    
//    var categoryAnnotation: some View {
//        VStack {
//            VStack(alignment: .leading) {
//                HStack {
//                    Text(selectedCategory!.title.capitalized)
//                        .lineLimit(1)
//                    Spacer()
//                    
//                    ChartCircleDot(
//                        budget: selectedCategory!.budgetAmount,
//                        expenses: abs(selectedCategory!.allAmounts?.totalSpend ?? 0.0),
//                        color: .white,
//                        size: 20
//                    )
//                    
//                    Image(systemName: selectedCategory!.emoji ?? "circle")
//                }
//                .font(.headline)
//                
//                Divider()
//                
//                Grid(alignment: .leading) {
//                    GridRow {
//                        Text("Budget").bold()
//                        Text(selectedCategory!.budgetAmount.currencyWithDecimals())
//                    }
//                    GridRow {
//                        Text("Income").bold()
//                        Text((selectedCategory!.allAmounts?.irregularIncome ?? 0.0).currencyWithDecimals())
//                    }
//                    GridRow {
//                        Text("Expenses").bold()
//                        Text((selectedCategory!.allAmounts?.totalSpend ?? 0.0).currencyWithDecimals())
//                    }
//                    
//                    Divider()
//                    
//                    GridRow {
//                        Text("Actual Spend").bold()
//                        Text(((selectedCategory!.allAmounts?.actualSpend ?? 0.0)).currencyWithDecimals())
//                    }
//                }
//                .font(.subheadline)
//            }
//            .if(selectedCategory!.isNil) {
//                $0.schemeBasedReversedForegroundStyle()
//            }
//            .if(!selectedCategory!.isNil) {
//                $0.schemeBasedForegroundStyle()
//            }
//            //.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
//            .padding(12)
//            .background(
//                RoundedRectangle(cornerRadius: 10)
//                    .fill(selectedCategory!.color)
//            )
//            .accessibilityHidden(true)
//        }
//        .frame(maxWidth: .infinity)
//    }
//}


//
//
//fileprivate struct DashboardActivityByMonthChartOG: View {
//    @Environment(CalendarModel.self) private var calModel
//    @Bindable var model: DashboardModel
//    @Bindable var data: DashboardData
//    
//    @State private var annotationHeight: CGFloat = 0
//
//    @State private var rawSelectedDate: Date?
//    var selectedMonth: DashboardDataByMonth? {
//        guard let rawSelectedDate else { return nil }
//        return data.monthlyBreakdowns.filter {
//            Calendar.current.isDate(rawSelectedDate, equalTo: $0.date, toGranularity: .month)
//        }.first
//    }
//    
////    var months: Int {
////        data.monthlyBreakdowns.count < 12 ? data.monthlyBreakdowns.count : 12
////    }
//    
////    var xAxisMonths: [Date] {
////        let months = data.monthlyBreakdowns.map(\.date)
////
////        if data.shouldUseQuarterly {
////            return months.enumerated().compactMap { index, date in
////                index % 12 == 0 ? date : nil
////            }
////        }
////
////        let step = data.monthlyBreakdowns.count > 6 ? 3 : 1
////
////        return months.enumerated().compactMap { index, date in
////            index % step == 0 ? date : nil
////        }
////    }
//    
//    var body: some View {
//        Chart {
//            if let selectedMonth = selectedMonth {
//                RuleMark(x: .value("Start Date", selectedMonth.date, unit: .month))
//                    .foregroundStyle(Color.secondary.opacity(0.5))
//            }
//            
//            ForEach(data.monthlyBreakdowns) { month in
//                ForEach(month.expenseCategories) { cat in
//                    BarMark(
//                        x: .value("Date", month.date, unit: .month),
//                        y: .value("Amount", (model.shouldUseTotalSpending ? cat.allAmounts?.totalSpend ?? 0 : cat.allAmounts?.actualSpend ?? 0))
//                    )
//                    .position(by: .value("Type", "Expenses"))
//                    .zIndex(-1)
//                    .foregroundStyle(cat.color)
//                }
//                                
//                ForEach(month.incomeCategories) { cat in
//                    BarMark(
//                        x: .value("Date", month.date, unit: .month),
//                        y: .value("Amount", incomeAmount(for: cat))
//                    )
//                    .position(by: .value("Type", "Income"))
//                    .zIndex(-1)
//                    .foregroundStyle(cat.color)
//                }
//            }
//
////            if data.shouldUseQuarterly {
////                ForEach(data.quarterlyBreakdowns) { quarter in
////                    let cats = quarter.flatCats
////                    let stackedCats = cats.reduce(into: [(cat: CBCategory, start: Double, end: Double)]()) { result, cat in
////                        let start = result.last?.end ?? 0.0
////                        let amount = cat.allAmounts?.actualSpend ?? 0.0
////                        let end = start + amount
////
////                        result.append((cat, start, end))
////                    }
////
////                    ForEach(stackedCats, id: \.cat.id) { item in
////                        RectangleMark(
////                            xStart: .value("Start Date", quarter.date.startDateOfQuarter, unit: .day),
////                            xEnd: .value("End Date", quarter.date.endDateOfQuarter.addingTimeInterval(-60 * 60 * 24 * 14), unit: .day),
////                            yStart: .value("Start", item.start),
////                            yEnd: .value("End", item.end)
////                        )
////                        .foregroundStyle(item.cat.color)
////                    }
////                }
////            } else {
////                ForEach(data.monthlyBreakdowns) { month in
////                    ForEach(month.flatCats) { cat in
////                        BarMark(
////                            x: .value("Date", month.date, unit: .month),
////                            y: .value("Amount", cat.allAmounts?.actualSpend ?? 0.0)
////                        )
////                        .zIndex(-1)
////                        .foregroundStyle(cat.color)
////                    }
////                }
////            }
//        }
//        .sensoryFeedback(.selection, trigger: selectedMonth)
//        .chartXSelection(value: $rawSelectedDate)
//        .if(data.monthlyBreakdowns.count > 12) {
//            $0
//            .chartXVisibleDomain(length: 3600 * 24 * 365 * 1)
//            .chartScrollableAxes(.horizontal)
//        }
//        .chartYAxis {
//            AxisMarks { axisValue in
//                AxisGridLine()
//                AxisTick()
//                AxisValueLabel {
//                    if let value = axisValue.as(Double.self) {
//                        Text("$\(value.kVersion)")
//                    }
//                }
//            }
//        }
//        .overlay(alignment: .top) {
//            selectedDataView
//        }
//        
//        
//        
//        
//        
//        
//        
////        .chartXAxis {
////            AxisMarks(values: xAxisMonths) { value in
////                AxisGridLine()
////                AxisTick()
////                AxisValueLabel {
////                    if let date = value.as(Date.self) {
////                        Text(
////                            date,
////                            format: data.shouldUseQuarterly
////                                ? .dateTime.year()
////                                : .dateTime.month(.abbreviated)
////                        )
////                    }
////                }
////            }
////        }
////        .chartXAxis {
////            AxisMarks(
////                values: .stride(
////                    by: .month,
////                    count: data.shouldUseQuarterly ? 12 : (data.monthlyBreakdowns.count > 6 ? 3 : 1)
////                )
////            ) { _ in
////                AxisGridLine()
////                AxisTick()
////                AxisValueLabel(format: data.shouldUseQuarterly ? .dateTime.year() : .dateTime.month(.abbreviated))
////            }
////        }
//    }
//    
//    @ViewBuilder
//    var selectedDataView: some View {
//        if let month = selectedMonth {
//            VStack {
//                VStack(alignment: .leading) {
//                    HStack {
//                        Text("\(DateFormatter.monthFull.string(from: month.date)) \(String(month.year))")
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                            .lineLimit(1)
//                        
//                        Spacer()
//                        
//                        Chart(month.flatCats) { cat in
//                            SectorMark(
//                                angle: .value("Amount", max(0, cat.allAmounts?.totalSpend ?? 0.0)),
//                                innerRadius: .ratio(0.2),
//                                angularInset: 0.5
//                            )
//                            .cornerRadius(2)
//                            .foregroundStyle(cat.color)
//                        }
//                        .id(month.date)
//                        .frame(width: 50, height: 50)
//                    }
//                    .font(.headline)
//                    
//                    Divider()
//                
//                    Grid(alignment: .leading) {
//                        GridRow {
//                            Text("Budget").bold()
//                            Text(month.budgetAmount.currencyWithDecimals())
//                        }
//                        
//                        GridRow {
//                            Text("Income").bold()
//                            Text((month.allAmounts?.irregularIncome ?? 0.0).currencyWithDecimals())
//                        }
//                        
//                        GridRow {
//                            Text("Expenses").bold()
//                            Text((month.allAmounts?.totalSpend ?? 0.0).currencyWithDecimals())
//                        }
//                        
//                        Divider()
//                        
//                        GridRow {
//                            Text("Actual Spend").bold()
//                            Text((month.allAmounts?.actualSpend ?? 0.0).currencyWithDecimals())
//                        }
//                    }
//                    .font(.subheadline)
//                }
//                .padding(12)
//                .background(
//                    RoundedRectangle(cornerRadius: 10)
//                        .fill(.ultraThinMaterial)
//                )
//                .accessibilityHidden(true)
//            }
//            .frame(maxWidth: .infinity)
//            .padding(.horizontal)
//            .background {
//                GeometryReader { geo in
//                    Color.clear
//                        .onAppear { annotationHeight = geo.size.height }
//                        .onChange(of: geo.size.height) { annotationHeight = $1 }
//                }
//            }
//            .offset(y: -annotationHeight - 8)
//            .zIndex(10)
//        }
//    }
//}
