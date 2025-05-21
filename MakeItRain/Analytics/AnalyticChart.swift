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
    
    var budget: Double {
        Double(budgetString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0
    }
    var budgetString: String
    
    var expenses: Double {
        Double(expensesString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0
    }
    var expensesString: String
}

enum MonthlyAnalyticChartRange: Int {
    case yearToDate = 0
    case year1 = 1
    case year2 = 2
    case year3 = 3
    case year4 = 4
    case year5 = 5
    case year10 = 10
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "yearToDate": return .yearToDate
        case "year1": return .year1
        case "year2": return .year2
        case "year3": return .year3
        case "year4": return .year4
        case "year5": return .year5
        case "year10": return .year10
        default: return .yearToDate
        }
    }
}

struct MonthlyAnalyticChartConfig {
    var enableShowExpenses: Bool
    var enableShowBudget: Bool
    var enableShowAverage: Bool
    var color: Color
    var headerLingo: String
}

struct MonthlyAnalyticChart<Content: View>: View {
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Local(\.colorTheme) var colorTheme
    @AppStorage("monthlyAnalyticChartVisibleYearCount") var chartVisibleYearCount: MonthlyAnalyticChartRange = .year1
    @AppStorage("showAverageOnMonthlyAnalyticChart") var showAverage: Bool = true
    @AppStorage("showBudgetOnMonthlyAnalyticChart") var showBudget: Bool = true
    @AppStorage("showExpensesOnMonthlyAnalyticChart") var showExpenses: Bool = true
        
    
    
    
    var data: Array<AnalyticData>
    var displayData: Array<AnalyticData>
    var config: MonthlyAnalyticChartConfig
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
    
    var visibleDateRangeForHeader: ClosedRange<Date> {
        /// Check if the date range of the data is within the visibleRange. Crop accordingly.
        let maxAvailEndDate = data.last?.date.endDateOfMonth ?? Date().endDateOfMonth
        var idealEndDate: Date = Date().endDateOfMonth
        
        if visibleYearCount != 0 {
            idealEndDate = Calendar.current.date(byAdding: .day, value: (365 * visibleYearCount), to: chartScrolledToDate)!
        }
        
        var endRange: Date
        if visibleYearCount == 0 {
            endRange = idealEndDate
        } else {
            endRange = idealEndDate > maxAvailEndDate ? maxAvailEndDate : idealEndDate
        }
        guard chartScrolledToDate < endRange else { return endRange...endRange }
        return chartScrolledToDate...endRange
    }
    
    
    var visibleDateRange: ClosedRange<Date> {
        /// Check if the date range of the data is within the visibleRange. Crop accordingly.
        let maxAvailEndDate = data.last?.date.endDateOfMonth ?? Date().endDateOfMonth
        var idealEndDate: Date = Calendar.current.date(byAdding: .day, value: 365, to: chartScrolledToDate)!
                
        var endRange: Date = idealEndDate > maxAvailEndDate ? maxAvailEndDate : idealEndDate
        
        guard chartScrolledToDate < endRange else { return endRange...endRange }
        return chartScrolledToDate...endRange
    }
    
    
    var visibleTotal: Double {
        /// Calculate the total of the data currently in the chart visible range.
        data
            .filter { visibleDateRangeForHeader.contains($0.date) }
            .map { $0.expenses }
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
        
        if chartVisibleYearCount == .yearToDate {
            let components = Calendar.current.dateComponents([.year], from: .now)
            let firstOfYear = Calendar.current.date(from: components)!
            let daysSoFarThisYear = Calendar.current.dateComponents([.day], from: firstOfYear, to: .now).day ?? 0
            idealDays = numberOfDays(daysSoFarThisYear)
        } else {
            idealDays = numberOfDays(365 * visibleYearCount)
        }
        
        if availDays == 0 {
            return numberOfDays(30)
        } else {
            let isTooManyIdealDays = idealDays > availDays
            return isTooManyIdealDays ? availDays : idealDays
        }
    }
    
    var minExpense: Double { data.map { $0.expenses }.min() ?? 0 }
    var maxExpense: Double { data.map { $0.expenses }.max() ?? 0 }
    
    
    
    
    
    var body: some View {
        chartPage
    }
    
    
    
    
    var chartPage: some View {
        Group {
            chartVisibleYearPicker
            //.rowBackground()
            
            Section {
                chartHeader
                Divider()
                
                theChart
                    .padding(.bottom, 30)
                
                Text("Options")
                    .foregroundStyle(.gray)
                    .font(.subheadline)
                
                Divider()
                
//                if config.enableShowExpenses {
//                    Toggle(isOn: $showExpenses.animation()) {
//                        Text("Show Expenses")
//                    }
//                }
                
                if config.enableShowBudget {
                    Toggle(isOn: $showBudget.animation()) {
                        Text("Show Budget")
                    }
                }
                
                if config.enableShowAverage {
                    Toggle(isOn: $showAverage.animation()) {
                        Text("Show Average")
                    }
                }
            }
            
            Divider()
            
            Spacer()
                .frame(minHeight: 10)
            
            rawDataList
        }
    }
    
    
    var chartVisibleYearPicker: some View {
        Picker("", selection: $chartVisibleYearCount) {
            Text("TY").tag(MonthlyAnalyticChartRange.yearToDate)
            Text("1Y").tag(MonthlyAnalyticChartRange.year1)
            Text("2Y").tag(MonthlyAnalyticChartRange.year2)
            Text("3Y").tag(MonthlyAnalyticChartRange.year3)
            Text("4Y").tag(MonthlyAnalyticChartRange.year4)
            Text("5Y").tag(MonthlyAnalyticChartRange.year5)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .onChange(of: chartVisibleYearCount) { setChartScrolledToDate($1) }
    }
    
    
    var chartHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(config.headerLingo)
                    .foregroundStyle(.gray)
                    .font(.title3)
                    .bold()
                
                Text("\(visibleTotal.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                
                HStack(spacing: 5) {
                    Text(visibleDateRangeForHeader.lowerBound.string(to: .monthNameYear))
                    Text("-")
                    Text(visibleDateRangeForHeader.upperBound.string(to: .monthNameYear))
                }
                .foregroundStyle(.gray)
                .font(.caption)
            }
            
            Spacer()
            
            if let selectedMonth {
                VStack(spacing: 0) {
                    Text("\(selectedMonth.date, format: .dateTime.month(.wide)) \(String(selectedMonth.date.year))")
                        .bold()
                    HStack {
                        Text("\(selectedMonth.expensesString)")
                            .bold()
                        Text("\(selectedMonth.budgetString)")
                            .bold()
                            .foregroundStyle(.secondary)
                        
                        if selectedMonth.type == "category" {
                            ChartCircleDot(budget: selectedMonth.budget, expenses: selectedMonth.expenses, color: .white, size: 20)
                        }                        
                    }
                }
                .foregroundStyle(.white)
                .padding(12)
                .frame(width: 160)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(config.color)
                )
            } else {
                dummySelectMonthViewForSpacingPurposes
            }
        }
    }
    
    
    var dummySelectMonthViewForSpacingPurposes: some View {
        VStack(spacing: 0) {
            Text("hey")
                .bold()
                .opacity(0)
            
            HStack {
                Text("hey")
                    .bold()
                    .opacity(0)
                
                ChartCircleDot(budget: 0, expenses: 0, color: .white, size: 20)
                    .background(Color.black)
                    .opacity(0)
            }
        }
        .foregroundStyle(.white)
        .padding(12)
        .frame(width: 160)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.clear)
        )
    }
        
    
    var theChart: some View {
        Chart {
            if let selectedMonth {
                RectangleMark(xStart: .value("Start Date", selectedMonth.date, unit: .month), xEnd: .value("End Date", selectedMonth.date.endDateOfMonth, unit: .day))
                    .foregroundStyle(config.color.opacity(0.5))
                    .zIndex(-5)
            }
                        
            if showAverage && config.enableShowAverage {
                RuleMark(y: .value("Average", data.map { $0.expenses }.average()))
                    .foregroundStyle(.gray.opacity(0.7))
                    .zIndex(-1)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
            }
            
            if showBudget && config.enableShowBudget {
                ForEach(displayData) { data in
                    LineMark(
                        x: .value("Date", data.date, unit: .month),
                        y: .value("Budget", data.budget),
                        series: .value("", "Budget")
                    )
                    .foregroundStyle(config.color)
                    .interpolationMethod(.catmullRom)
                    .zIndex(-1)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                }
            }
            
            //if showExpenses && config.enableShowExpenses {
            ForEach(displayData) { data in
                LineMark(
                    x: .value("Date", data.date, unit: .month),
                    y: .value("Amount", data.expenses),
                    series: .value("", "Expenses")
                )
                .foregroundStyle(config.color)
                .interpolationMethod(.catmullRom)
                .symbol {
                    //if data.expenses > 0 {
                        Circle()
                            .fill(config.color)
                            .frame(width: 6, height: 6)
                    //}
                }
                
                AreaMark(
                    x: .value("Date", data.date, unit: .month),
                    yStart: .value("Max", data.expenses),
                    yEnd: .value("Min", minExpense)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(LinearGradient(
                    colors: [config.color, .clear],
                    startPoint: .top,
                    endPoint: .bottom)
                )
            }
            //}
        }
        .frame(minHeight: 150)
        .if(chartVisibleYearCount != .yearToDate) {
            $0.chartScrollableAxes(.horizontal)
        }
        .chartXVisibleDomain(length: visibleChartAreaDomain)
        //.chartScrollPosition(initialX: data.last?.date ?? Date())
        .chartScrollPosition(x: $chartScrolledToDate)
        .chartXSelection(value: $rawSelectedDate)
        .chartYScale(domain: [minExpense, maxExpense + (maxExpense * 0.2)])
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
                AxisValueLabel(centered: chartVisibleYearCount == .yearToDate)
            }
        }
        .chartLegend(position: .top, alignment: .leading)
        .chartForegroundStyleScale([
            "Total: \((data.map { $0.expenses }.reduce(0.0, +).currencyWithDecimals(useWholeNumbers ? 0 : 2)))": config.color,
            
            "Average: \((data.map { $0.expenses }.average()).currencyWithDecimals(useWholeNumbers ? 0 : 2))": Color.gray
        ])
        .padding(.bottom, 10)
    }
    
    
    func numberOfDays(_ num: Int) -> Int { (3600 * 24) * num }
    
    
    func setChartScrolledToDate(_ newValue: MonthlyAnalyticChartRange) {
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
