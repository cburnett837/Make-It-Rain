////
////  MultiAnalyticChart.swift
////  MakeItRain
////
////  Created by Cody Burnett on 5/9/25.
////
//
//import SwiftUI
//import Charts
//
//
//struct PayMethodChartOG: View {
//    @AppStorage("incomeColor") private var incomeColor: String = Color.blue.description
//    @AppStorage("incomeType") private var incomeType: IncomeType = .income
//    
//    @AppStorage("useWholeNumbers") private var useWholeNumbers = false
//    @AppStorage("colorTheme") private var colorTheme: String = Color.blue.description
//    @AppStorage("threshold") var threshold: Double = 500.00
//    
//    @AppStorage("monthlyAnalyticChartVisibleYearCount") private var chartVisibleYearCount: CategoryAnalyticChartRange = .year1
//    
//    @AppStorage("showIncomeOnAnalyticChart") private var showIncome: Bool = true
//    @AppStorage("showIncomeAndPositiveAmountsOnAnalyticChart") private var showIncomeAndPositiveAmountsOnAnalyticChart: Bool = true
//    @AppStorage("showPositiveAmountsOnAnalyticChart") private var showPositiveAmountsOnAnalyticChart: Bool = true
//    @AppStorage("showExpensesOnAnalyticChart") private var showExpenses: Bool = true
//    @AppStorage("showPaymentsOnAnalyticChart") private var showPayments: Bool = true
//    @AppStorage("showStartingAmountsOnAnalyticChart") private var showStartingAmounts: Bool = true
//    @AppStorage("showProfitLossOnAnalyticChart") private var showProfitLoss: Bool = true
//    
//    @AppStorage("showMonthEndOnAnalyticChart") private var showMonthEnd: Bool = true
//    @AppStorage("showMinEodOnAnalyticChart") private var showMinEod: Bool = true
//    @AppStorage("showMaxEodOnAnalyticChart") private var showMaxEod: Bool = true
//    
//    
//    
//    @AppStorage("showAllCategoryChartData") private var showAllChartData = false
//    
//    @Environment(PayMethodModel.self) private var payModel
//    
//    let threeColumnGrid = Array(repeating: GridItem(.flexible(), spacing: 0, alignment: .topLeading), count: 3)
//    
//    @Bindable var viewModel: PayMethodViewModel
//    var payMethod: CBPaymentMethod
//    var config: PayMethodChartConfig
//    
//    @FocusState private var focusedField: Int?
//    @State private var showSearchBar = false
//    @State private var searchText = ""
//    @State private var selectedBreakdowns: Breakdown?
//    @State private var rawSelectedDate: Date?
//    
//    // MARK: - Computed Properties
//    var selectedDate: Date? {
//        if let rawSelectedDate {
//            return viewModel.payMethods.first?.breakdowns.first { Calendar.current.isDate(rawSelectedDate, equalTo: $0.date, toGranularity: .month) }?.date
//        } else {
//            return nil
//        }
//    }
//          
//    
//    var visibleDateRangeForHeader: ClosedRange<Date> {
//        /// Check if the date range of the data is within the visibleRange. Crop accordingly.
//        let maxAvailEndDate = viewModel.maxDate.endDateOfMonth
//        var idealEndDate: Date = Date().endDateOfMonth
//        
//        if visibleYearCount != 0 {
//            idealEndDate = Calendar.current.date(byAdding: .day, value: (365 * visibleYearCount), to: viewModel.chartScrolledToDate)!
//        }
//        
//        var endRange: Date
//        if visibleYearCount == 0 {
//            endRange = idealEndDate
//        } else {
//            endRange = idealEndDate > maxAvailEndDate ? maxAvailEndDate : idealEndDate
//        }
//        guard viewModel.chartScrolledToDate < endRange else { return endRange...endRange }
//        return viewModel.chartScrolledToDate...endRange
//    }
//        
//    
//    var visibleIncome: Double {
//        /// Calculate the total of the data currently in the chart visible range.
//        viewModel.payMethods
//            .flatMap { $0.breakdowns }
//            .filter { visibleDateRangeForHeader.contains($0.date) }
//            .map {
//                switch incomeType {
//                case .income:
//                    $0.income
//                case .incomeAndPositiveAmounts:
//                    $0.incomeAndPositiveAmounts
//                case .positiveAmounts:
//                    $0.positiveAmounts
//                case .startingAmountsAndPositiveAmounts:
//                    $0.startingAmountsAndPositiveAmounts
//                }
//            }
//            .reduce(0, +)
//    }
//    
//    
//    var visibleExpenses: Double {
//        viewModel.payMethods
//            .flatMap { $0.breakdowns }
//            .filter { visibleDateRangeForHeader.contains($0.date) }
//            .map { $0.expenses }
//            .reduce(0, +)
//    }
//    
//    
//    var visiblePayments: Double {
//        /// Calculate the total of the data currently in the chart visible range.
//        viewModel.payMethods
//            .flatMap { $0.breakdowns }
//            .filter { visibleDateRangeForHeader.contains($0.date) }
//            .map { $0.payments }
//            .reduce(0, +)
//    }
//    
//    
//    var visibleYearCount: Int {
//        return chartVisibleYearCount.rawValue == 0 ? 1 : chartVisibleYearCount.rawValue
//    }
//       
//    
//    var visibleChartAreaDomain: Int {
//        /// Check if the date range of the data is within the visibleChartAreaDomain. Crop accordingly.
//        let daysBetweenMinAndMax = Calendar.current.dateComponents([.day], from: viewModel.minDate, to: viewModel.maxDate).day ?? 0
//        let availDays = viewModel.numberOfDays(daysBetweenMinAndMax)
//        var idealDays: Int
//        
//        if chartVisibleYearCount == .yearToDate {
//            let components = Calendar.current.dateComponents([.year], from: .now)
//            let firstOfYear = Calendar.current.date(from: components)!
//            let daysSoFarThisYear = Calendar.current.dateComponents([.day], from: firstOfYear, to: .now).day ?? 0
//            idealDays = viewModel.numberOfDays(daysSoFarThisYear)
//        } else {
//            idealDays = viewModel.numberOfDays(365 * visibleYearCount)
//        }
//        
//        if availDays == 0 {
//            return viewModel.numberOfDays(30)
//        } else {
//            let isTooManyIdealDays = idealDays > availDays
//            return isTooManyIdealDays ? availDays : idealDays
//        }
//    }
//    
//    
//    var showOptions: Bool {
//        if config.incomeConfig != nil ||
//        config.expensesConfig != nil ||
//        config.paymentsConfig != nil ||
//        config.startingAmountsConfig != nil ||
//        config.profitLossConfig != nil ||
//        config.monthEndConfig != nil ||
//        config.minEodConfig != nil ||
//        config.maxEodConfig != nil
//        {
//            if (config.incomeConfig?.enabled ?? false) ||
//                (config.expensesConfig?.enabled ?? false) ||
//                (config.paymentsConfig?.enabled ?? false) ||
//                (config.startingAmountsConfig?.enabled ?? false) ||
//                (config.profitLossConfig?.enabled ?? false) ||
//                (config.monthEndConfig?.enabled ?? false) ||
//                (config.minEodConfig?.enabled ?? false) ||
//                (config.maxEodConfig?.enabled ?? false)
//            {
//                return true
//            }
//        }
//        return false
//    }
//    
//    
//    var selectedBarColor: Color {
//        viewModel.payMethods.count == 1
//        ? Color(.secondarySystemFill).opacity(0.5)
//        : Color(.secondarySystemFill)
//    }
//    
//    
//    var lastID: String? {
//        viewModel.payMethods[0].breakdowns.sorted(by: { $0.date > $1.date }).last?.id
//    }
//     
//    
//    var filteredBreakdowns: [PayMethodMonthlyBreakdown] {
//        if let first = viewModel.payMethods.first {
//            return first
//                .breakdowns
//                .filter { chartVisibleYearCount == .yearToDate ? $0.year == AppState.shared.todayYear : true }
//                .filter { searchText.isEmpty ? true : $0.date.string(to: .monthNameYear).localizedStandardContains(searchText) }
//                .sorted(by: { $0.date > $1.date })
//        } else {
//            return []
//        }
//    }
//    
//    
//    // MARK: - Views
//    var body: some View {
//        chartPage
//            .onChange(of: viewModel.payMethods) { viewModel.prepareData() }
//            .task { viewModel.prepareData() }
//    }
//    
//    
//    var chartPage: some View {
//        Group {
//            Section {
//                VStack(spacing: 5) {
//                    chartVisibleYearPicker
//                    chartHeader
//                }
//                .opacity(selectedDate == nil ? 1 : 0)
//                .overlay(selectedDataView)
//                
//                Divider()
//                if viewModel.payMethods.count > 1 {
//                    chartLegend
//                }
//                                                
//                expenseIncomeChart
//                    .padding(.bottom, 30)
//                
//                
//                
//                
//                HStack {
//                    Text("Profit/Loss")
//                        .foregroundStyle(.gray)
//                        .font(.subheadline)
//                    
//                    Spacer()
//                    
//                    profitLossStyleMenu
//                }
//                                
//                profitLossChart
//                    .padding(.bottom, 30)
//                
//                
//                
//                
//                Text("Min/Max EOD amounts")
//                    .foregroundStyle(.gray)
//                    .font(.subheadline)
//                
//                minMaxEodChart
//                    .padding(.bottom, 30)
//
//                
//                
//                
//
//                                
//                if showOptions {
//                    optionToggles
//                }
//            }
//            
//            Divider()
//                .padding(.bottom, 30)
//            
//            rawDataList
//        }
//        .sheet(item: $selectedBreakdowns) { breakdowns in
//            BreakdownView(payMethod: payMethod, breakdowns: breakdowns)
//        }
//    }
//    
//    
//    var chartHeader: some View {
//        HStack {
//            VStack(alignment: .leading) {
//                Text(config.headerLingo)
//                    .font(.title3)
//                    .bold()
//                
//                Group {
//                    if payMethod.isCredit {
//                        Text("Payments: \(visiblePayments.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
//                    } else {
//                        Text("Income: \(visibleIncome.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
//                    }
//                }
//                .foregroundStyle(.gray)
//                .font(.subheadline)
//                
//                Text("Expenses: \(visibleExpenses.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
//                    .foregroundStyle(.gray)
//                    .font(.subheadline)
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
//        }
//    }
//    
//    
//    @ViewBuilder
//    var selectedDataView: some View {
//        if let selectedDate = selectedDate {
//            VStack(spacing: 0) {
//                Text("\(selectedDate, format: .dateTime.month(.wide)) \(String(selectedDate.year))")
//                    .bold()
//                
//                Divider()
//                    .padding(.vertical, 6)
//                
//                Grid {
//                    GridRow(alignment: .top) {
//                        if viewModel.payMethods.count > 1 {
//                            Text("Meth")
//                        }
//                        
//                        if let expensesConfig = config.expensesConfig, showExpenses, expensesConfig.enabled {
//                            Text("Expenses")
//                                .foregroundStyle(expensesConfig.color)
//                        }
//                        
//                        if let startingAmountsConfig = config.startingAmountsConfig, showStartingAmounts, startingAmountsConfig.enabled {
//                            Text("Starting")
//                                .foregroundStyle(startingAmountsConfig.color)
//                        }
//                        
//                        if let profitLossConfig = config.profitLossConfig, showProfitLoss, profitLossConfig.enabled {
//                            Text("Profit/Loss")
//                                .foregroundStyle(profitLossConfig.color)
//                        }
//                        
//                        if let incomeConfig = config.incomeConfig, showIncome, incomeConfig.enabled {
//                            Text("Income")
//                                .foregroundStyle(incomeConfig.color)
//                        }
//                        
//                        if payMethod.isCredit {
//                            if let paymentsConfig = config.paymentsConfig, showPayments, paymentsConfig.enabled {
//                                Text("Payments")
//                                    .foregroundStyle(paymentsConfig.color)
//                            }
//                        }
//                        
//                        
//                        if let monthEndConfig = config.monthEndConfig, showMonthEnd, monthEndConfig.enabled {
//                            Text("Month End")
//                                .foregroundStyle(monthEndConfig.color)
//                        }
//                        
//                        if let minEodConfig = config.minEodConfig, showMinEod, minEodConfig.enabled {
//                            Text("Min EOD")
//                                .foregroundStyle(minEodConfig.color)
//                        }
//                        
//                        if let maxEodConfig = config.maxEodConfig, showMaxEod, maxEodConfig.enabled {
//                            Text("Max EOD")
//                                .foregroundStyle(maxEodConfig.color)
//                        }
//                        
//                        
//                    }
//                    .bold()
//                    .font(.caption2)
//                    
//                    Divider()
//                    
//                    ForEach(viewModel.amountPerObject(on: selectedDate)) { info in
//                        GridRow(alignment: .top) {
//                            if viewModel.payMethods.count > 1 {
//                                HStack(spacing: 0) {
//                                    CircleDot(color: info.color)
//                                    Text(info.title)
//                                }
//                            }
//                            
//                            if let expensesConfig = config.expensesConfig, showExpenses, expensesConfig.enabled {
//                                Text(info.expenses.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                            }
//                            
//                            if let startingAmountsConfig = config.startingAmountsConfig, showStartingAmounts, startingAmountsConfig.enabled {
//                                Text(info.startingAmounts.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                            }
//                            
//                            if let profitLossConfig = config.profitLossConfig, showProfitLoss, profitLossConfig.enabled {
//                                Text(info.profitLoss.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                            }
//                            
//                            if let incomeConfig = config.incomeConfig, showIncome, incomeConfig.enabled {
//                                
//                                var showMe: Double {
//                                    switch incomeType {
//                                    case .income:
//                                        info.income
//                                    case .incomeAndPositiveAmounts:
//                                        info.incomeAndPositiveAmounts
//                                    case .positiveAmounts:
//                                        info.positiveAmounts
//                                    case .startingAmountsAndPositiveAmounts:
//                                        info.startingAmountsAndPositiveAmounts
//                                    }
//                                }
//                                
//                                
//                                Text(showMe.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                            }
//                            
//                            if payMethod.isCredit {
//                                if let paymentsConfig = config.paymentsConfig, showPayments, paymentsConfig.enabled {
//                                    Text(info.payments.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                                }
//                            }
//                            
//                            if let monthEndConfig = config.monthEndConfig, showMonthEnd, monthEndConfig.enabled {
//                                Text(info.monthEnd.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                            }
//                            
//                            if let minEodConfig = config.minEodConfig, showMinEod, minEodConfig.enabled {
//                                Text(info.minEod.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                            }
//                            
//                            if let maxEodConfig = config.maxEodConfig, showMaxEod, maxEodConfig.enabled {
//                                Text(info.maxEod.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                            }
//                            
//                        }
//                        .minimumScaleFactor(0.5)
//                        .foregroundStyle(.secondary)
//                        .font(.caption2)
//                    }
//                }
//                .frame(maxHeight: .infinity)
//            }
//            .frame(maxHeight: .infinity)
//            .foregroundStyle(.primary)
//            .padding(6)
//            .background(
//                RoundedRectangle(cornerRadius: 10)
//                    //#if os(iOS)
//                    .fill(Color(.secondarySystemFill))
//                    //#endif
//            )
//        }
//    }
//    
//    
//    var expenseIncomeChart: some View {
//        Chart {
//            if let selectedDate {
//                RectangleMark(xStart: .value("Start Date", selectedDate, unit: .month), xEnd: .value("End Date", selectedDate.endDateOfMonth, unit: .day))
//                    .foregroundStyle(selectedBarColor)
//                    .zIndex(-5)
//            }
//            
//            ForEach(viewModel.payMethods) { payMethod in
//                //ForEach(payMethod.breakdowns/*.filter {$0.budget != 0 }*/) { data in
//                ForEach(payMethod.breakdowns.filter { chartVisibleYearCount == .yearToDate ? $0.date.year == AppState.shared.todayYear : true }) { breakdown in
//                    
//                    /// Payment method - Income
//                    if let incomeConfig = config.incomeConfig, showIncome, incomeConfig.enabled {
//                        var showMe: Double {
//                            switch incomeType {
//                            case .income:
//                                breakdown.income
//                            case .incomeAndPositiveAmounts:
//                                breakdown.incomeAndPositiveAmounts
//                            case .positiveAmounts:
//                                breakdown.positiveAmounts
//                            case .startingAmountsAndPositiveAmounts:
//                                breakdown.startingAmountsAndPositiveAmounts
//                            }
//                        }
//                        
//                        LineMark(
//                            x: .value("Date", breakdown.date, unit: .month),
//                            y: .value("Amount1", showMe),
//                            series: .value("", "Amount1\(payMethod.id)")
//                        )
//                        .foregroundStyle(Color.fromName(incomeColor))
//                        //.foregroundStyle(Color.green)
//                        .interpolationMethod(.catmullRom)
//                    }
//                    
//                    /// Payment method - Expenses.
//                    if let expensesConfig = config.expensesConfig, showExpenses, expensesConfig.enabled {
//                        LineMark(
//                            x: .value("Date", breakdown.date, unit: .month),
//                            y: .value("Amount2", breakdown.expenses),
//                            series: .value("", "Amount2\(payMethod.id)")
//                        )
//                        .foregroundStyle(expensesConfig.color)
//                        //.foregroundStyle(Color.red)
//                        .interpolationMethod(.catmullRom)
//                        //.zIndex(-1)
//                        //.lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
//                    }
//                                        
//                    /// Payment method - Payments (if applicable).
//                    if let paymentsConfig = config.paymentsConfig, showPayments, paymentsConfig.enabled {
//                        LineMark(
//                            x: .value("Date", breakdown.date, unit: .month),
//                            y: .value("Amount3", breakdown.payments),
//                            series: .value("", "Amount3\(payMethod.id)")
//                        )
//                        .foregroundStyle(paymentsConfig.color)
//                        //.foregroundStyle(Color.blue)
//                        .interpolationMethod(.catmullRom)
//                    }
//                    
//                    /// Payment method - Starting amounts.
//                    if let startingAmountsConfig = config.startingAmountsConfig, showStartingAmounts, startingAmountsConfig.enabled {
//                        LineMark(
//                            x: .value("Date", breakdown.date, unit: .month),
//                            y: .value("Amount4", breakdown.startingAmounts),
//                            series: .value("", "Amount4\(payMethod.id)")
//                        )
//                        .foregroundStyle(startingAmountsConfig.color)
//                        //.foregroundStyle(Color.blue)
//                        .interpolationMethod(.catmullRom)
//                    }
//                    
//                    /// Payment method - Income minus Expenses.
//                    if let profitLossConfig = config.profitLossConfig, showProfitLoss, profitLossConfig.enabled {
//                        LineMark(
//                            x: .value("Date", breakdown.date, unit: .month),
//                            y: .value("Amount5", breakdown.profitLoss),
//                            series: .value("", "Amount5\(payMethod.id)")
//                        )
//                        .foregroundStyle(profitLossConfig.color)
//                        //.foregroundStyle(Color.blue)
//                        .interpolationMethod(.catmullRom)
//                    }
//                    
//                    
//                    if let monthEndConfig = config.monthEndConfig, showMonthEnd, monthEndConfig.enabled {
//                        LineMark(
//                            x: .value("Date", breakdown.date, unit: .month),
//                            y: .value("Amount6", breakdown.monthEnd),
//                            series: .value("", "Amount6\(payMethod.id)")
//                        )
//                        .foregroundStyle(monthEndConfig.color)
//                        //.foregroundStyle(Color.blue)
//                        .interpolationMethod(.catmullRom)
//                    }
//                    
//                    
//                    
//                }
//            }
//        }
//        .frame(minHeight: 150)
//        .chartYAxis {
//            AxisMarks(values: .automatic(desiredCount: 6)) {
//                AxisGridLine()
//                let value = $0.as(Int.self)!
//                AxisValueLabel {
//                    Text("$\(value)")
//                }
//           }
//        }
//        .chartXAxis {
//            AxisMarks(position: .bottom, values: .automatic) { _ in
//                AxisTick()
//                AxisGridLine()
//                AxisValueLabel(centered: chartVisibleYearCount == .yearToDate)
//            }
//        }
//        .if(chartVisibleYearCount != .yearToDate) {
//            $0.chartScrollableAxes(.horizontal)
//        }
//        .chartXVisibleDomain(length: visibleChartAreaDomain)
//        .chartScrollPosition(x: $viewModel.chartScrolledToDate)
//        .chartXSelection(value: $rawSelectedDate)
//        //.chartYScale(domain: [minIncome, maxIncome + (maxIncome * 0.2)])
//        //.chartLegend(position: .top, alignment: .leading)
//        //.chartForegroundStyleScale(data.map {$0.color})
////        .if(data.count == 1) {
////            $0.chartForegroundStyleScale([
////                "Total: \((rawData.map { $0.income }.reduce(0.0, +).currencyWithDecimals(useWholeNumbers ? 0 : 2)))": config.color,
////                "Average: \((rawData.map { $0.income }.average()).currencyWithDecimals(useWholeNumbers ? 0 : 2))": Color.gray
////            ])
////        }
//    }
//    
//    
//    var minMaxEodChart: some View {
//        Chart {
//            if let selectedDate {
//                RectangleMark(xStart: .value("Start Date", selectedDate, unit: .month), xEnd: .value("End Date", selectedDate.endDateOfMonth, unit: .day))
//                    .foregroundStyle(selectedBarColor)
//                    .zIndex(-5)
//            }
//            
//            ForEach(viewModel.payMethods) { payMethod in
//                ForEach(payMethod.breakdowns.filter { chartVisibleYearCount == .yearToDate ? $0.date.year == AppState.shared.todayYear : true }) { breakdown in
//                    BarMark(
//                        x: .value("Date", breakdown.date, unit: .month),
//                        yStart: .value("Min Eod", breakdown.minEod),
//                        yEnd: .value("Max Eod", breakdown.maxEod),
//                        width: .ratio(0.6)
//                    )
//                    .opacity(breakdown.minEod < threshold ? 0.6 : 1)
//                    //.foregroundStyle(breakdown.minEod < threshold ? .orange : .green)
//                    .foregroundStyle(Color.fromName(colorTheme))
//                }
//            }
//        }
//        .frame(minHeight: 150)
//        .chartYAxis {
//            AxisMarks(values: .automatic(desiredCount: 6)) {
//                AxisGridLine()
//                let value = $0.as(Int.self)!
//                AxisValueLabel {
//                    Text("$\(value)")
//                }
//            }
//        }
//        .chartXAxis {
//            AxisMarks(position: .bottom, values: .automatic) { _ in
//                AxisTick()
//                AxisGridLine()
//                AxisValueLabel(centered: chartVisibleYearCount == .yearToDate)
//            }
//        }
//        .if(chartVisibleYearCount != .yearToDate) {
//            $0.chartScrollableAxes(.horizontal)
//        }
//        .chartXVisibleDomain(length: visibleChartAreaDomain)
//        .chartScrollPosition(x: $viewModel.chartScrolledToDate)
//        .chartXSelection(value: $rawSelectedDate)
//    }
//    
//    
//    @AppStorage("profitLossStyle") private var profitLossStyle: String = "amount"
//
//    var profitLossStyleMenu: some View {
//        Menu {
//            Button("As amount") {
//                profitLossStyle = "amount"
//            }
//            Button("As percentage") {
//                profitLossStyle = "percentage"
//            }
//        } label: {
//            Text(profitLossStyle)
//        }
//    }
//    
//    
//    
//    var profitLossChart: some View {
//        Chart {
//            if let selectedDate {
//                RectangleMark(xStart: .value("Start Date", selectedDate, unit: .month), xEnd: .value("End Date", selectedDate.endDateOfMonth, unit: .day))
//                    .foregroundStyle(selectedBarColor)
//                    .zIndex(-5)
//            }
//            
//            ForEach(viewModel.payMethods) { payMethod in
//                //ForEach(payMethod.breakdowns/*.filter {$0.budget != 0 }*/) { data in
//                ForEach(payMethod.breakdowns.filter { chartVisibleYearCount == .yearToDate ? $0.date.year == AppState.shared.todayYear : true }) { breakdown in
//                    
//                    if profitLossStyle == "amount" {
//                        LineMark(
//                            x: .value("Date", breakdown.date, unit: .month),
//                            y: .value("Amount5", breakdown.profitLoss),
//                            series: .value("", "Amount5\(payMethod.id)")
//                        )
//                        .foregroundStyle(Color.fromName(colorTheme))
//                        .interpolationMethod(.catmullRom)
//                    } else {
//                        let percentage = Helpers.netWorthPercentageChange(start: breakdown.startingAmounts, end: breakdown.monthEnd)
//                        let maxAmount = payMethod.breakdowns.map { Helpers.netWorthPercentageChange(start: $0.startingAmounts, end: $0.monthEnd) }.max()!
//                        let minAmount = payMethod.breakdowns.map { Helpers.netWorthPercentageChange(start: $0.startingAmounts, end: $0.monthEnd) }.min()!
//                        let positionForNewColor = (0-minAmount)/(maxAmount-minAmount)
//                        
//                        LineMark(
//                            x: .value("Date", breakdown.date, unit: .month),
//                            y: .value("Amount5", percentage),
//                            series: .value("", "Amount5\(payMethod.id)")
//                        )
//                        .foregroundStyle(
//                            .linearGradient(
//                                Gradient(
//                                    stops: [
//                                        .init(color: .red, location: 0),
//                                        .init(color: .red, location: positionForNewColor - 0.00001),
//                                        .init(color: .green, location: positionForNewColor + 0.00001),
//                                        .init(color: .green, location: 1)
//                                    ]
//                                ),
//                                startPoint: .bottom,
//                                endPoint: .top
//                            )
//                        )
//                        
//                        .interpolationMethod(.catmullRom)
//                    }
//                }
//            }
//        }
//        .frame(minHeight: 150)
//        .chartYAxis {
//            AxisMarks(values: .automatic(desiredCount: 6)) {
//                AxisGridLine()
//                
//                if profitLossStyle == "amount" {
//                    let value = $0.as(Int.self)!
//                    AxisValueLabel {
//                        Text("$\(value)")
//                    }
//                } else {
//                    let value = $0.as(Int.self)!
//                    AxisValueLabel {
//                        Text("\(value)%")
//                    }
//                }
//            }
//        }
//        .chartXAxis {
//            AxisMarks(position: .bottom, values: .automatic) { _ in
//                AxisTick()
//                AxisGridLine()
//                AxisValueLabel(centered: chartVisibleYearCount == .yearToDate)
//            }
//        }
//        .if(chartVisibleYearCount != .yearToDate) {
//            $0.chartScrollableAxes(.horizontal)
//        }
//        .chartXVisibleDomain(length: visibleChartAreaDomain)
//        .chartScrollPosition(x: $viewModel.chartScrolledToDate)
//        .chartXSelection(value: $rawSelectedDate)
//    }
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    var chartLegend: some View {
//        ScrollView(.horizontal) {
//            ZStack {
//                Spacer()
//                    .containerRelativeFrame([.horizontal])
//                    .frame(height: 1)
//                                            
//                HStack(spacing: 0) {
//                    ForEach(viewModel.payMethods) { item in
//                        HStack(alignment: .circleAndTitle, spacing: 5) {
//                            Circle()
//                                .fill(item.color)
//                                .frame(maxWidth: 8, maxHeight: 8) // 8 seems to be the default from charts
//                                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                            
//                            VStack(alignment: .leading, spacing: 2) {
//                                Text(item.title)
//                                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                                
////                                let total = item.breakdowns.map { $0.amount1 }.reduce(0.0, +).currencyWithDecimals(useWholeNumbers ? 0 : 2)
////                                let average = item.breakdowns.map { $0.amount1 }.average().currencyWithDecimals(useWholeNumbers ? 0 : 2)
////                                
////                                Text("Total: \(total)")
////                                Text("Average: \(average)")
//                            }
//                            .foregroundStyle(Color.secondary)
//                            .font(.caption2)
//                        }
//                        .padding(.trailing, 8)
//                        .contentShape(Rectangle())
//                    }
//                    Spacer()
//                }
//            }
//        }
//        .scrollBounceBehavior(.basedOnSize)
//        .contentMargins(.bottom, 10, for: .scrollContent)
//    }
//    
//    
//    var chartVisibleYearPicker: some View {
//        Picker("", selection: $chartVisibleYearCount) {
//            Text("TY").tag(CategoryAnalyticChartRange.yearToDate)
//            Text("1Y").tag(CategoryAnalyticChartRange.year1)
//            Text("2Y").tag(CategoryAnalyticChartRange.year2)
//            Text("3Y").tag(CategoryAnalyticChartRange.year3)
//            Text("4Y").tag(CategoryAnalyticChartRange.year4)
//            Text("5Y").tag(CategoryAnalyticChartRange.year5)
//        }
//        .pickerStyle(.segmented)
//        .labelsHidden()
//        .onChange(of: chartVisibleYearCount) { viewModel.setChartScrolledToDate($1) }
//    }
//            
//    
//    @ViewBuilder var optionToggles: some View {
//        Text("Options")
//            .foregroundStyle(.gray)
//            .font(.subheadline)
//        
//        Divider()
//        
//        
//        if let expensesConfig = config.expensesConfig, expensesConfig.enabled {
//            OptionToggle(description: "The sum of all negative dollar amounts.\n(Purchases, Withdrawls, Payments, Etc.)", config: expensesConfig, show: $showExpenses)
//        }
//        
//        if let startingAmountsConfig = config.startingAmountsConfig, startingAmountsConfig.enabled {
//            OptionToggle(description: "The balance at the start of each month.", config: startingAmountsConfig, show: $showStartingAmounts)
//        }
//                            
//        if let profitLossConfig = config.profitLossConfig, profitLossConfig.enabled {
//            var lingo: String {
//                if payMethod.accountType == .credit || payMethod.accountType == .unifiedCredit {
//                    "The amount of credit available after expenses have been deducted from income.\n(limit - (expenses + payments))"
//                } else {
//                    "The amount that remains after expenses have been deducted from income.\n(income - expenses)"
//                }
//            }
//            OptionToggle(description: lingo, config: profitLossConfig, show: $showProfitLoss)
//        }
//        
//        if let incomeConfig = config.incomeConfig, incomeConfig.enabled {
//            
//            let description: LocalizedStringKey = "**Only income:**\nThe sum of amounts where transactions have an ***income*** category.\n\n**Money in only (no income):**\nThe sum of positive dollar amounts ***excluding*** transactions that have an income category.\n(Deposits, Refunds, Etc.)\n\n**All money in:**\nThe sum of ***all*** positive dollar amounts.\n(Income, Deposits, Refunds, Etc.)\n\n**Starting amount & all money in:**\nThat sum of all positive dollar amounts + the amount you started the month with."
//            
//            
//            IncomeOptionToggle(description: description, config: incomeConfig, show: $showIncome)
//        }
//                                                                    
//        if let paymentsConfig = config.paymentsConfig, paymentsConfig.enabled {
//            OptionToggle(description: "Payments made for the credit card.", config: paymentsConfig, show: $showPayments)
//        }
//        
//        
//        if let monthEndConfig = config.monthEndConfig, monthEndConfig.enabled {
//            OptionToggle(description: "The balance at the end of each month.", config: monthEndConfig, show: $showMonthEnd)
//        }
//        
////        if let minEodConfig = config.minEodConfig, minEodConfig.enabled {
////            OptionToggle(description: "The lowest available amount of the month.", config: minEodConfig, show: $showMinEod)
////        }
////        
////        if let maxEodConfig = config.maxEodConfig, maxEodConfig.enabled {
////            OptionToggle(description: "The highest available amount of the month.", config: maxEodConfig, show: $showMaxEod)
////        }
//        
//        
//    }
//        
//        
//    var rawDataList: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            HStack {
//                Text("Data (\(String(viewModel.fetchYearStart)) - \(String(AppState.shared.todayYear)))")
//                    .foregroundStyle(.gray)
//                    .font(.subheadline)
//                    //.padding(.leading, 6)
//                
//                Spacer()
//                                                
//                Button {
//                    withAnimation {
//                        showAllChartData.toggle()
//                    }
//                } label: {
//                    Text(showAllChartData ? "Hide" : "Show")
//                }
//            }
//                        
//            
//            Divider()
//            
//            if showAllChartData {
//                VStack(spacing: 0) {
//                    SearchTextField(title: "Dates", searchText: $searchText, focusedField: $focusedField, focusState: _focusedField)
//                        .padding(.horizontal, -20)
//                        .padding(.bottom, 5)
//                                                                            
//                    breakdownGrid
//                }
//                .padding(.bottom, 10)
//            }
//            
//        }
//    }
//    
//    
//    var breakdownGrid: some View {
//        LazyVGrid(columns: threeColumnGrid) {
//            Text("Date").bold()
//            Text("Income").bold()
//            Text("Expenses").bold()
//            Divider()
//            Divider()
//            Divider()
//            
//            ForEach(filteredBreakdowns) { breakdown in
//                RawDataLineItem(breakdown: breakdown)
//                    .onTapGesture {
//                        let breakdowns = payMethod.breakdownsRegardlessOfPaymentMethod.filter { $0.month == breakdown.month && $0.year == breakdown.year }
//                        let selectedBreakdowns = Breakdown(date: breakdown.date, breakdowns: breakdowns)
//                        self.selectedBreakdowns = selectedBreakdowns
//                    }
//                
//                Divider()
//                Divider()
//                Divider()
//            }
//            if chartVisibleYearCount != .yearToDate {
//                Section {
//                } header: {
//                    loadMoreHistoryButton
//                }
//            }
//        }
//    }
//        
//    
//    var loadMoreHistoryButton: some View {
//        Button {
//            viewModel.fetchMoreHistory(for: payMethod, payModel: payModel, visibleYearCount: visibleYearCount)
//        } label: {
//            Text("Fetch \(String(viewModel.fetchYearStart-10))-\(String(viewModel.fetchYearEnd-11))")
//                .opacity(viewModel.isLoadingMoreHistory ? 0 : 1)
//        }
//        .disabled(viewModel.isLoadingMoreHistory)
//        .buttonStyle(.borderedProminent)
//        .overlay {
//            ProgressView()
//                .tint(.none)
//                .opacity(viewModel.isLoadingMoreHistory ? 1 : 0)
//        }
//    }
//}
//
//
//fileprivate struct RawDataLineItem: View {
//    @Local(\.incomeColor) var incomeColor
//    @Local(\.useWholeNumbers) var useWholeNumbers
//    var breakdown: PayMethodMonthlyBreakdown
//    
//    var body: some View {
//        Group {
//            Text(breakdown.date.string(to: .monthNameYear))
//            
//            Text(breakdown.income.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                .foregroundStyle(.secondary)
//                //.foregroundStyle(Color.fromName(incomeColor))
//            
//            Text(breakdown.expenses.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                .foregroundStyle(.secondary)
//                //.foregroundStyle(.red)
//        }
//        .font(.subheadline)
//        .contentShape(Rectangle())
//        
//    }
//}
//
//
//
//fileprivate struct IncomeOptionToggle: View {
//    @ChartOption(\.incomeType) var incomeType
//    @Local(\.colorTheme) var colorTheme
//    @State private var showDescription = false
//    
//    var description: LocalizedStringKey
//    var config: (title: String, enabled: Bool, color: Color)
//    @Binding var show: Bool
//    
//    /// Need this to prevent the button from animating.
//    @State private var incomeText = ""
//    
//    var body: some View {
//        VStack(alignment: .leading) {
//            Toggle(isOn: $show.animation()) {
//                Label {
//                    Menu {
//                        Button { change(to: .income) } label: {
//                            menuOptionLabel(title: "Income only", isChecked: incomeType == .income)
//                        }
//                        Button { change(to: .positiveAmounts) } label: {
//                            menuOptionLabel(title: "Money in only (no income)", isChecked: incomeType == .positiveAmounts)
//                        }
//                        Button { change(to: .incomeAndPositiveAmounts) } label: {
//                            menuOptionLabel(title: "All money in", isChecked: incomeType == .incomeAndPositiveAmounts)
//                        }
//                        Button { change(to: .startingAmountsAndPositiveAmounts) } label: {
//                            menuOptionLabel(title: "Starting amount & all money in", isChecked: incomeType == .startingAmountsAndPositiveAmounts)
//                        }
//                    } label: {
//                        HStack(spacing: 4) {
//                            Text(incomeText)
//                            Image(systemName: "chevron.up.chevron.down")
//                                .font(.footnote)
//                        }
//                        .transaction {
//                            $0.disablesAnimations = true
//                            $0.animation = nil
//                        }
//                    }
//                } icon: {
//                    Image(systemName: showDescription ? "xmark.circle" : "info.circle")
//                        .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
//                        .onTapGesture { withAnimation { showDescription.toggle() } }
//                }
//            }
//            .tint(config.color)
//            
//            if showDescription {
//                Text(description)
//                    .font(.caption2)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .foregroundStyle(.secondary)
//            }
//        }
//        .onAppear {
//            setText(incomeType: incomeType)
//        }
//    }
//    
//    @ViewBuilder func menuOptionLabel(title: String, isChecked: Bool) -> some View {
//        HStack {
//            Text(title)
//            if isChecked {
//                Image(systemName: "checkmark")
//            }
//        }
//    }
//    
//    func change(to option: IncomeType) {
//        setText(incomeType: option)
//        withAnimation {
//            incomeType = option
//        }
//    }
//    
//    func setText(incomeType: IncomeType) {
//        switch incomeType {
//        case .income:
//            self.incomeText = IncomeType.income.prettyValue
//            
//        case .incomeAndPositiveAmounts:
//            self.incomeText = IncomeType.incomeAndPositiveAmounts.prettyValue
//            
//        case .positiveAmounts:
//            self.incomeText = IncomeType.positiveAmounts.prettyValue
//            
//        case .startingAmountsAndPositiveAmounts:
//            self.incomeText = IncomeType.startingAmountsAndPositiveAmounts.prettyValue
//        }
//    }
//}
//
//
//
//fileprivate struct OptionToggle: View {
//    @Local(\.colorTheme) var colorTheme
//    @State private var showDescription = false
//    
//    var description: String
//    var config: (title: String, enabled: Bool, color: Color)
//    @Binding var show: Bool
//    
//    var body: some View {
//        VStack(alignment: .leading) {
//            Toggle(isOn: $show.animation()) {
//                Label {
//                    Text(config.title)
//                } icon: {
//                    Image(systemName: showDescription ? "xmark.circle" : "info.circle")
//                        //.foregroundStyle(Color.fromName(colorTheme))
//                }
//                .onTapGesture { withAnimation { showDescription.toggle() } }
//                .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
//                
//            }
//            .tint(config.color)
//            
//            if showDescription {
//                Text(description)
//                    .font(.caption2)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .foregroundStyle(.secondary)
//            }
//        }
//    }
//}
//
//
//
//fileprivate struct BreakdownView: View {
//    @Local(\.incomeColor) var incomeColor
//    @Local(\.useWholeNumbers) var useWholeNumbers
//    @Environment(PayMethodModel.self) private var payModel
//    var payMethod: CBPaymentMethod
//    var breakdowns: Breakdown
//    
//    var body: some View {
//        NavigationStack {
//            List {
//                ForEach(breakdowns.breakdowns) { down in
//                    Section {
//                        lineItem(title: "Expenses", value: down.expenses, color: .red)
//                        lineItem(title: "Starting Balance", value: down.startingAmounts, color: .orange)
//                        lineItem(title: "Free Cash Flow", value: down.profitLoss, color: .green)
//                        lineItem(title: "Income", value: down.income, color: Color.fromName(incomeColor))
//                        if payMethod.accountType == .unifiedCredit {
//                            lineItem(title: "Payments", value: down.payments, color: .purple)
//                        }
//                        lineItem(title: "Month End", value: down.monthEnd, color: .mint)
//                        lineItem(title: "Min EOD", value: down.minEod, color: .indigo)
//                        lineItem(title: "Max EOD", value: down.maxEod, color: .cyan)
//                        
//                    } header: {
//                        HStack {
//                            if let meth = payModel.paymentMethods.filter({ $0.id == down.payMethodID }).first {
//                                Circle()
//                                    .fill(meth.color)
//                                    .frame(width: 12, height: 12)
//                                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                                
//                                Text(meth.title)
//                            } else {
//                                Text("N/A")
//                            }
//                            
//                            Spacer()
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Details \(breakdowns.date.string(to: .monthNameYear))")
//            #if os(iOS)
//            .navigationBarTitleDisplayMode(.inline)
//            .listSectionSpacing(10)
//            #endif
//        }
//    }
//    
//    @ViewBuilder func lineItem(title: String, value: Double, color: Color) -> some View {
//        HStack {
//            Circle()
//                .fill(color)
//                .frame(width: 12, height: 12)
//            
//            Text(title)
//            Spacer()
//            Text(value.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//        }
//    }
//}
