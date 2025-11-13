//
//  AnalyticChart.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/7/25.
//

import SwiftUI
import Charts

struct AnalyticRecord {
    var id: String
    var title: String
    var color: Color
}


struct AnalyticData: Identifiable {
    var id = UUID()
    //var category: CBCategory?
    var record: AnalyticRecord
    var type: String
    var month: Int
    var year: Int
    var date: Date {
        Helpers.createDate(month: month, year: year)!
    }
    
    var budgetString: String
    var budget: Double {
        Double(budgetString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0
    }
    
    var expensesString: String
    var expenses: Double {
        Double(expensesString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0
    }
    
    var incomeString: String
    var income: Double {
        Double(incomeString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0
    }
    
    var incomeMinusExpenses: Double {
        income - expenses
    }
    
    var expensesMinusIncome: Double {
        expenses - income
    }
}


enum CategoryAnalyticChartRange: Int {
    //case yearToDate = 0
    case year1 = 1
    case year2 = 2
    case year3 = 3
    case year4 = 4
    case year5 = 5
    case year10 = 10
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        //case "yearToDate": return .yearToDate
        case "year1": return .year1
        case "year2": return .year2
        case "year3": return .year3
        case "year4": return .year4
        case "year5": return .year5
        case "year10": return .year10
        default: return .year1
        }
    }
}



enum CategoryAnalyticChartDisplayedMetric: String, CaseIterable, Identifiable {
    var id: CategoryAnalyticChartDisplayedMetric { return self }
    case income, expenses, budget, incomeMinusExpenses, expensesMinusIncome
    
    var prettyValue: String {
        switch self {
        case .income:
            "Income"
        case .expenses:
            "Expenses"
        case .budget:
            "Budget"
        case .incomeMinusExpenses:
            "Income minus expenses"
        case .expensesMinusIncome:
            "Expenses minus income"
        }
    }
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "income": return .income
        case "expenses": return .expenses
        case "budget": return .budget
        case "incomeMinusExpenses": return .incomeMinusExpenses
        case "expensesMinusIncome": return .expensesMinusIncome
        default: return .expenses
        }
    }
}



struct CategoryAnalyticChartConfig {
    var enableShowExpenses: Bool
    var enableShowBudget: Bool
    var enableShowAverage: Bool
    var color: Color
    var headerLingo: String
}


struct CategoryAnalyticChart<Content: View>: View {
    @Local(\.useWholeNumbers) var useWholeNumbers
    //@Local(\.colorTheme) var colorTheme
    @AppStorage("monthlyAnalyticChartVisibleYearCount") var chartVisibleYearCount: CategoryAnalyticChartRange = .year1
    @AppStorage("showAverageOnCategoryAnalyticChart") var showAverage: Bool = true
    @AppStorage("showBudgetOnCategoryAnalyticChart") var showBudget: Bool = true
    @AppStorage("showExpensesOnCategoryAnalyticChart") var showExpenses: Bool = true
    
    @AppStorage(LocalKeys.Charts.CategoryAnalytics.displayedMetric) var displayedMetric: CategoryAnalyticChartDisplayedMetric = .expenses
    
    var data: Array<AnalyticData>
    var displayData: Array<AnalyticData>
    var config: CategoryAnalyticChartConfig
    @Binding var isLoadingHistory: Bool
    @Binding var chartScrolledToDate: Date
    @ViewBuilder var rawDataList: Content
    
    
    @State private var rawSelectedDate: Date?
    var selectedMonth: AnalyticData? {
        guard let rawSelectedDate else { return nil }
        return data.first {
            Calendar.current.isDate(rawSelectedDate, equalTo: $0.date, toGranularity: .month)
        }
    }
    
    
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
    
    
    var visibleDateRange: ClosedRange<Date> {
        /// Check if the date range of the data is within the visibleRange. Crop accordingly.
        let maxAvailEndDate = data.last?.date.endDateOfMonth ?? Date().endDateOfMonth
        let idealEndDate: Date = Calendar.current.date(byAdding: .day, value: 365, to: chartScrolledToDate)!
        
        let endRange: Date = idealEndDate > maxAvailEndDate ? maxAvailEndDate : idealEndDate
        
        guard chartScrolledToDate < endRange else { return endRange...endRange }
        return chartScrolledToDate...endRange
    }
    
    
    var visibleTotal: Double {
        /// Calculate the total of the data currently in the chart visible range.
        displayData
            .map {
                switch displayedMetric {
                case .income: $0.income
                case .expenses: $0.expenses
                case .budget: $0.budget
                case .incomeMinusExpenses: $0.incomeMinusExpenses
                case .expensesMinusIncome: $0.expensesMinusIncome
                }
            }
            .reduce(0, +)
    }
    
    
    var visibleYearCount: Int {
        chartVisibleYearCount.rawValue == 0 ? 1 : chartVisibleYearCount.rawValue
    }
    
    
    var visibleChartAreaDomain: Int {
        /// Check if the date range of the data is within the visibleChartAreaDomain. Crop accordingly.
        let minDate = data.first?.date ?? Date()
        let maxDate = data.last?.date ?? Date()
        
        let daysBetweenMinAndMax = Calendar.current.dateComponents([.day], from: minDate, to: maxDate).day ?? 0
        let availDays = numberOfDays(daysBetweenMinAndMax)
        var idealDays: Int
        
//        if chartVisibleYearCount == .yearToDate {
//            let components = Calendar.current.dateComponents([.year], from: .now)
//            let firstOfYear = Calendar.current.date(from: components)!
//            let daysSoFarThisYear = Calendar.current.dateComponents([.day], from: firstOfYear, to: .now).day ?? 0
//            idealDays = numberOfDays(daysSoFarThisYear)
//        } else {
            idealDays = numberOfDays(365 * visibleYearCount)
//        }
        
        if availDays == 0 {
            return numberOfDays(30)
        } else {
            let isTooManyIdealDays = idealDays > availDays
            return isTooManyIdealDays ? availDays : idealDays
            
            //return idealDays
        }
        
//        return idealDays
    }
    
    
    var average: Double {
        displayData
            .map {
                switch displayedMetric {
                case .income: $0.income
                case .expenses: $0.expenses
                case .budget: $0.budget
                case .incomeMinusExpenses: $0.incomeMinusExpenses
                case .expensesMinusIncome: $0.expensesMinusIncome
                }
            }
            .average()
    }
//    
//    var budgets: [Double] {
//        displayData.map { $0.budget }
//    }
//    
//    var minVal: Double {
//        let minData = data.map {
//            //min($0.income, $0.expenses, $0.budget, $0.incomeMinusExpenses)
//            switch displayedMetric {
//            case .income: $0.income
//            case .expenses: $0.expenses
//            case .budget: $0.budget
//            case .incomeMinusExpenses: $0.incomeMinusExpenses
//            }
//        }.min() ?? 0
//        
//        let min = min(average, minData, budgets.min() ?? 0)
//        print("min \(min)")
//        
//        return minData
//        //return min(average, minData)
//    }
//    
//    var maxVal: Double {
//        let maxData = data.map {
//            //max($0.income, $0.expenses, $0.budget, $0.incomeMinusExpenses)
//            switch displayedMetric {
//            case .income: $0.income
//            case .expenses: $0.expenses
//            case .budget: $0.budget
//            case .incomeMinusExpenses: $0.incomeMinusExpenses
//            }
//        }.max() ?? 0
//        
//        let max = max(average, maxData, budgets.max() ?? 0)
//        print("max \(max)")
//        
//        return maxData
//        
//        
//        
//        //return max(average, maxData)
//    }
    
//    var chartScale: KeyValuePairs<String, Color> {
//        let totalText = displayData
//            .map {
//                switch displayedMetric {
//                case .income: $0.income
//                case .expenses: $0.expenses
//                case .budget: $0.budget
//                case .incomeMinusExpenses: $0.incomeMinusExpenses
//                }
//            }
//            .reduce(0.0, +)
//            .currencyWithDecimals(useWholeNumbers ? 0 : 2)
//        
//        let averageText = average.currencyWithDecimals(useWholeNumbers ? 0 : 2)
//        
//        return [
//            "Total: \(totalText)": config.color,
//            "Average: \(averageText)": Color.gray
//        ]
//    }
    
    @ViewBuilder
    var customLegend: some View {
        let averageText = average.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        HStack {
            Circle()
                .frame(width: 8, height: 8)
                .foregroundStyle(.gray)
            
            Text("Average (month): \(averageText)")
                .contentTransition(.numericText())
                .foregroundStyle(.gray)
                .font(.caption2)
            
            Spacer()
        }
                
    }
    
    
    var body: some View {
        VStack {
            chartVisibleYearPicker
            //Divider()
            chartHeader
            Divider()
            
            customLegend
            
            theChart
        }
        
        Section {
            if config.enableShowBudget {
                Toggle(isOn: $showBudget.animation()) {
                    Text("Show Budget")
                }
                .tint(config.color)
            }
            
            if config.enableShowAverage {
                Toggle(isOn: $showAverage.animation()) {
                    Text("Show Average")
                }
                .tint(config.color)
            }
                        
            Picker("Metrics", selection: $displayedMetric.animation()) {
                /// Filter out the budget options since we have a line dedicated to that
                ForEach(CategoryAnalyticChartDisplayedMetric.allCases.filter { $0.id != .budget }) { opt in
                    Text(opt.prettyValue)
                        .tag(opt.id)
                }
            }
            .tint(config.color)
        } header: {
            Text("Options")
        }
        
        rawDataList
    }
    
    
    
    var chartVisibleYearPicker: some View {
        
//        Picker(selection: $chartVisibleYearCount) {
//            Text("TY").tag(CategoryAnalyticChartRange.yearToDate)
//            Text("1Y").tag(CategoryAnalyticChartRange.year1)
//            Text("2Y").tag(CategoryAnalyticChartRange.year2)
//            Text("3Y").tag(CategoryAnalyticChartRange.year3)
//            Text("4Y").tag(CategoryAnalyticChartRange.year4)
//            Text("5Y").tag(CategoryAnalyticChartRange.year5)
//        } label: {
//            Text("\(String(chartVisibleYearCount.rawValue))Y")
//                .foregroundStyle(.gray)
//        }
//        .pickerStyle(.menu)
//        .onChange(of: chartVisibleYearCount) { setChartScrolledToDate($1) }

        
        Picker("", selection: $chartVisibleYearCount.animation()) {
            //Text("TY").tag(CategoryAnalyticChartRange.yearToDate)
            Text("1Y").tag(CategoryAnalyticChartRange.year1)
            Text("2Y").tag(CategoryAnalyticChartRange.year2)
            Text("3Y").tag(CategoryAnalyticChartRange.year3)
            Text("4Y").tag(CategoryAnalyticChartRange.year4)
            Text("5Y").tag(CategoryAnalyticChartRange.year5)
            Text("10Y").tag(CategoryAnalyticChartRange.year10)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .onChange(of: chartVisibleYearCount) { setChartScrolledToDate($1) }
    }
    
    
    
    @ViewBuilder
    var selectedDataView: some View {
        if let selectedMonth {
            VStack(spacing: 0) {
                Text("\(selectedMonth.date, format: .dateTime.month(.wide)) \(String(selectedMonth.date.year))")
                    .bold()
                HStack {
                    
                    let metricText = switch displayedMetric {
                    case .income: selectedMonth.income
                    case .expenses: selectedMonth.expenses
                    case .budget: selectedMonth.budget
                    case .incomeMinusExpenses: selectedMonth.incomeMinusExpenses
                    case .expensesMinusIncome: selectedMonth.expensesMinusIncome
                    }
                    
                    Text(metricText.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                        .bold()
                    Text(selectedMonth.budget.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                        .bold()
                        .foregroundStyle(.secondary)
                    
                    if selectedMonth.type == "category" {
                        ChartCircleDot(budget: selectedMonth.budget, expenses: selectedMonth.expenses, color: .white, size: 20)
                    }
                }
            }
            .foregroundStyle(.white)
            .padding(12)
            //.frame(width: 160)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(config.color)
                //                        .fill(Color.theme)
            )
        }
    }
    
    
    
    var chartHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                //Text(config.headerLingo)
                HStack {
                    Text(displayedMetric.prettyValue)
                        .contentTransition(.interpolate)
                        .foregroundStyle(.gray)
                        .font(.title3)
                        .bold()
                    
                    Spacer()
                    
                    Text("\(visibleTotal.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                        .contentTransition(.numericText())
                }
                                                
                
                HStack(spacing: 5) {
                    let currentYear = Calendar.current.component(.year, from: .now)
                    let years = (0..<chartVisibleYearCount.rawValue).map { currentYear - $0 }
                    
                    Text(String(years.last!))
                    Text("-")
                        .opacity(years.last! == currentYear ? 0 : 1)
                    Text(String(currentYear))
                        .opacity(years.last! == currentYear ? 0 : 1)
                }
                .foregroundStyle(.gray)
                .font(.caption)
            }
            
            Spacer()
            
            //selectedDataView
        }
    }
    
    
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
        
    
    var theChart: some View {
        Chart {
            if let selectedMonth {
                RuleMark(x: .value("Start Date", selectedMonth.date, unit: .month))
                    .foregroundStyle(Color.secondary.opacity(0.5))
                    //.zIndex(-5)
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                        selectedDataView
                    }
                
//                RectangleMark(xStart: .value("Start Date", selectedMonth.date, unit: .month), xEnd: .value("End Date", selectedMonth.date.endDateOfMonth, unit: .day))
//                    .foregroundStyle(config.color.opacity(0.5))
//                    .zIndex(-5)
            }
                        
            
            
            //if showExpenses && config.enableShowExpenses {
            ForEach(displayData) { data in
                
                let metricToDisplay = switch displayedMetric {
                case .income: data.income
                case .expenses: data.expenses
                case .budget: data.budget
                case .incomeMinusExpenses: data.incomeMinusExpenses
                case .expensesMinusIncome: data.expensesMinusIncome
                }
                
                
                
//                LineMark(
//                    x: .value("Date", data.date, unit: .month),
//                    y: .value("Amount", metricToDisplay),
//                    series: .value("", "Expenses")
//                )
//                .foregroundStyle(config.color)
//                .interpolationMethod(.catmullRom)
                
                BarMark(
                    x: .value("Date", data.date, unit: .month),
                    y: .value("Amount", metricToDisplay)
                )
                .zIndex(-1)
                //.clipShape(Capsule())
                .foregroundStyle(config.color)
                .opacity(data.date == selectedMonth?.date ? 1 : (selectedMonth == nil ? 1 : 0.3))
                
                
//                .symbol {
//                    Circle()
//                        .fill(config.color)
//    //                            .fill(Color.theme)
//                        .frame(width: 6, height: 6)
//                }
                
//                AreaMark(
//                    x: .value("Date", data.date, unit: .month),
//                    yStart: .value("Max", metricToDisplay),
//                    yEnd: .value("Min", minVal)
//                )
//                .interpolationMethod(.catmullRom)
//                .foregroundStyle(LinearGradient(
//                    colors: [config.color, .clear],
////                    colors: [Color.theme, .clear],
//                    startPoint: .top,
//                    endPoint: .bottom)
//                )
            }
            //}
            
            if showAverage && config.enableShowAverage {
                RuleMark(y: .value("Average", average))
                    .foregroundStyle(.gray.opacity(0.7))
                    //.zIndex(-1)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
            }
            
            if showBudget && config.enableShowBudget {
                ForEach(displayData) { data in
                    LineMark(
                        x: .value("Date", data.date, unit: .month),
                        y: .value("Budget", data.budget),
                        series: .value("", "Budget")
                    )
                    .foregroundStyle(config.color.lighter(by: 20))
//                    .foregroundStyle(.white)
                    //.brightness(-0.2)
                    
                    
                    
//                    .foregroundStyle(Color.theme)
                    //.interpolationMethod(.catmullRom)
                    //.zIndex(-1)
                    //.lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selectedMonth?.id) { $0 != nil && $1 != nil }
        .frame(minHeight: 150)
        /// Even though this causes a view redraw, keep this because there is a weird animation between 1Y and YTD.
//        .if(chartVisibleYearCount != .yearToDate) {
//            $0.chartScrollableAxes(.horizontal)
//        }
        .chartXVisibleDomain(length: visibleChartAreaDomain)
        //.chartScrollPosition(initialX: data.last?.date ?? Date())
        //.chartScrollPosition(x: $chartScrolledToDate)
        .chartXSelection(value: $rawSelectedDate)
        //.chartYScale(domain: [minVal, maxVal + (maxVal * 0.2)])
//        .chartScrollTargetBehavior(
//            .valueAligned(
//                matching: DateComponents(day: 1),
//                majorAlignment: .matching(DateComponents(day: 1))
//            )
//        )
        //.chartOverlay { ChartOverlayView(selectedMonth: selectedMonth, proxy: $0) }
        .chartYAxis {
            AxisMarks {
                AxisGridLine()
            //AxisMarks(values: .automatic(desiredCount: 6)) {
               let value = $0.as(Int.self)!
               AxisValueLabel {
                   Text("$\(value)")
               }
           }
        }
        .chartXAxis {
            AxisMarks(position: .bottom, values: .automatic) { _ in
                AxisTick()
                AxisGridLine()
                //AxisValueLabel(centered: chartVisibleYearCount == .yearToDate)
                AxisValueLabel(centered: false)
            }
        }
        .chartLegend(position: .top, alignment: .leading)
        //.chartForegroundStyleScale(chartScale)
        .padding(.bottom, 10)
        
        
//        .chartOverlay { proxy in
//            GeometryReader { geo in
//                if let date = selectedMonth?.date,
//                   let xPos = proxy.position(forX: date) {
//                    selectedDataView
//                        .position(x: xPos + geo[proxy.plotAreaFrame].origin.x, y: geo[proxy.plotAreaFrame].minY)
//                }
//            }
//        }
        
    }
    
    
    func numberOfDays(_ num: Int) -> Int { (3600 * 24) * num }
    
    
    func setChartScrolledToDate(_ newValue: CategoryAnalyticChartRange) {
        /// Set the scrollPosition to which ever is smaller, the targetDate, or the minDate.
        let minDate = data.first?.date ?? Date()
        let maxDate = data.last?.date ?? Date()
        var targetDate: Date
        /// If 0, which means it's YTD, start with the maxDate and work backwards to January 1st.
        if newValue.rawValue == 0 {
            let components = Calendar.current.dateComponents([.year], from: .now)
            targetDate = Calendar.current.date(from: components)!
        } else {
            ///-365, -730, etc
            let value = -(365 * newValue.rawValue)
            /// start with the maxDate and work backwards using the value.
            targetDate = Calendar.current.date(byAdding: .day, value: value, to: maxDate)!
        }
        
        /// chartScrolledToDate is the beginning of the chart view.
        if targetDate < minDate && newValue.rawValue != 0 {
            chartScrolledToDate = minDate
        } else {
            chartScrolledToDate = targetDate
        }
    }
}



//
//
//struct CategoryAnalyticChartOG<Content: View>: View {
//    @Local(\.useWholeNumbers) var useWholeNumbers
//    //@Local(\.colorTheme) var colorTheme
//    @AppStorage("monthlyAnalyticChartVisibleYearCount") var chartVisibleYearCount: CategoryAnalyticChartRange = .year1
//    @AppStorage("showAverageOnCategoryAnalyticChart") var showAverage: Bool = true
//    @AppStorage("showBudgetOnCategoryAnalyticChart") var showBudget: Bool = true
//    @AppStorage("showExpensesOnCategoryAnalyticChart") var showExpenses: Bool = true
//        
//    var data: Array<AnalyticData>
//    var displayData: Array<AnalyticData>
//    var config: CategoryAnalyticChartConfig
//    @Binding var isLoadingHistory: Bool
//    @Binding var chartScrolledToDate: Date
//    @ViewBuilder var rawDataList: Content
//    
//    
//    @State private var rawSelectedDate: Date?
//    var selectedMonth: AnalyticData? {
//        guard let rawSelectedDate else { return nil }
//        return data.first {
//            Calendar.current.isDate(rawSelectedDate, equalTo: $0.date, toGranularity: .month)
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
//    
//    var visibleDateRange: ClosedRange<Date> {
//        /// Check if the date range of the data is within the visibleRange. Crop accordingly.
//        let maxAvailEndDate = data.last?.date.endDateOfMonth ?? Date().endDateOfMonth
//        let idealEndDate: Date = Calendar.current.date(byAdding: .day, value: 365, to: chartScrolledToDate)!
//                
//        let endRange: Date = idealEndDate > maxAvailEndDate ? maxAvailEndDate : idealEndDate
//        
//        guard chartScrolledToDate < endRange else { return endRange...endRange }
//        return chartScrolledToDate...endRange
//    }
//    
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
//    var minVal: Double { data.map { $0.expenses }.min() ?? 0 }
//    var maxVal: Double { data.map { $0.expenses }.max() ?? 0 }
//    
//    
//    
//    
//    
//    var body: some View {
//        chartPage
//    }
//    
//    
//    
//    
//    var chartPage: some View {
//        Group {
//            chartVisibleYearPicker
//            //.rowBackground()
//            
//            Section {
//                chartHeader
//                Divider()
//                
//                theChart
//                    .padding(.bottom, 30)
//                
//                Text("Options")
//                    .foregroundStyle(.gray)
//                    .font(.subheadline)
//                
//                Divider()
//                
////                if config.enableShowExpenses {
////                    Toggle(isOn: $showExpenses.animation()) {
////                        Text("Show Expenses")
////                    }
////                }
//                
//                if config.enableShowBudget {
//                    Toggle(isOn: $showBudget.animation()) {
//                        Text("Show Budget")
//                    }
//                }
//                
//                if config.enableShowAverage {
//                    Toggle(isOn: $showAverage.animation()) {
//                        Text("Show Average")
//                    }
//                }
//            }
//            
//            Divider()
//            
//            Spacer()
//                .frame(minHeight: 10)
//            
//            rawDataList
//        }
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
//        .onChange(of: chartVisibleYearCount) { setChartScrolledToDate($1) }
//    }
//    
//    
//    var chartHeader: some View {
//        HStack {
//            VStack(alignment: .leading) {
//                Text(config.headerLingo)
//                    .foregroundStyle(.gray)
//                    .font(.title3)
//                    .bold()
//                
//                Text("\(visibleTotal.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
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
//                        if selectedMonth.type == "category" {
//                            ChartCircleDot(budget: selectedMonth.budget, expenses: selectedMonth.expenses, color: .white, size: 20)
//                        }
//                    }
//                }
//                .foregroundStyle(.white)
//                .padding(12)
//                .frame(width: 160)
//                .background(
//                    RoundedRectangle(cornerRadius: 10)
//                        //.fill(config.color)
//                        .fill(Color.theme)
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
//                RectangleMark(xStart: .value("Start Date", selectedMonth.date, unit: .month), xEnd: .value("End Date", selectedMonth.date.endDateOfMonth, unit: .day))
//                    //.foregroundStyle(config.color.opacity(0.5))
//                    .foregroundStyle(Color.theme.opacity(0.5))
//                    .zIndex(-5)
//            }
//                        
//            if showAverage && config.enableShowAverage {
//                RuleMark(y: .value("Average", data.map { $0.expenses }.average()))
//                    .foregroundStyle(.gray.opacity(0.7))
//                    .zIndex(-1)
//                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
//            }
//            
//            if showBudget && config.enableShowBudget {
//                ForEach(displayData) { data in
//                    LineMark(
//                        x: .value("Date", data.date, unit: .month),
//                        y: .value("Budget", data.budget),
//                        series: .value("", "Budget")
//                    )
//                    //.foregroundStyle(config.color)
//                    .foregroundStyle(Color.theme)
//                    .interpolationMethod(.catmullRom)
//                    .zIndex(-1)
//                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
//                }
//            }
//            
//            //if showExpenses && config.enableShowExpenses {
//            ForEach(displayData) { data in
//                LineMark(
//                    x: .value("Date", data.date, unit: .month),
//                    y: .value("Amount", data.expenses),
//                    series: .value("", "Expenses")
//                )
//                //.foregroundStyle(config.color)
//                .foregroundStyle(Color.theme)
//                .interpolationMethod(.catmullRom)
//                .symbol {
//                    //if data.expenses > 0 {
//                        Circle()
//                            //.fill(config.color)
//                            .fill(Color.theme)
//                            .frame(width: 6, height: 6)
//                    //}
//                }
//                
//                AreaMark(
//                    x: .value("Date", data.date, unit: .month),
//                    yStart: .value("Max", data.expenses),
//                    yEnd: .value("Min", minVal)
//                )
//                .interpolationMethod(.catmullRom)
//                .foregroundStyle(LinearGradient(
//                    //colors: [config.color, .clear],
//                    colors: [Color.theme, .clear],
//                    startPoint: .top,
//                    endPoint: .bottom)
//                )
//            }
//            //}
//        }
//        .sensoryFeedback(.selection, trigger: selectedMonth?.id) { $0 != nil && $1 != nil }
//        .frame(minHeight: 150)
//        .if(chartVisibleYearCount != .yearToDate) {
//            $0.chartScrollableAxes(.horizontal)
//        }
//        .chartXVisibleDomain(length: visibleChartAreaDomain)
//        //.chartScrollPosition(initialX: data.last?.date ?? Date())
//        .chartScrollPosition(x: $chartScrolledToDate)
//        .chartXSelection(value: $rawSelectedDate)
//        .chartYScale(domain: [minVal, maxVal + (maxVal * 0.2)])
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
//            //"Total: \((data.map { $0.expenses }.reduce(0.0, +).currencyWithDecimals(useWholeNumbers ? 0 : 2)))": config.color,
//            "Total: \((data.map { $0.expenses }.reduce(0.0, +).currencyWithDecimals(useWholeNumbers ? 0 : 2)))": Color.theme,
//            "Average: \((data.map { $0.expenses }.average()).currencyWithDecimals(useWholeNumbers ? 0 : 2))": Color.gray
//        ])
//        .padding(.bottom, 10)
//    }
//    
//    
//    func numberOfDays(_ num: Int) -> Int { (3600 * 24) * num }
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
//}
