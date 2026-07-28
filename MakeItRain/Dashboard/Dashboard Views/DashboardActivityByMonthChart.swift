//
//  DashboardActivityByMonthChart.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

struct DashboardActivityByMonthChart: View {
    enum Tabs: String { case expense, income, compare }
    @AppStorage("dashboardSelectedMonthChartPageTabThing") var selectedTab: Tabs = .expense
    
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: DashboardModel
    @Bindable var data: DashboardData
    
    @State private var annotationHeight: CGFloat = 0
    @State private var chartScroll: Date?

    private let visibleSeconds: TimeInterval = 3600 * 24 * 365 * 2



    @State private var rawSelectedDate: Date?
//    var selectedMonth: DashboardDataByMonth? {
//        guard let rawSelectedDate else { return nil }
//        return data.monthlyBreakdowns.filter {
//            Calendar.current.isDate(rawSelectedDate, equalTo: $0.date, toGranularity: .month)
//        }.first
//    }
//
    
    enum SelectedBreakdown {
        case month(DashboardDataByMonth)
        case quarter(DashboardDataByQuarter)
    }
    
    var selectedQuarter: DashboardDataByQuarter? {
        guard let rawSelectedDate else { return nil }

        return data.quarterlyBreakdowns.first { quarter in
            rawSelectedDate >= quarter.date &&
            rawSelectedDate < quarter.endDate
        }
    }

    var selectedMonth: DashboardDataByMonth? {
        guard let rawSelectedDate else { return nil }

        return data.monthlyBreakdowns.first {
            Calendar.current.isDate(
                rawSelectedDate,
                equalTo: $0.date,
                toGranularity: .month
            )
        }
    }

    var selectedSummary: (any DashboardBreakdownSummary)? {
        switch data.breakdownType {
        case .monthly:
            selectedMonth
        case .quarterly:
            selectedQuarter
        }
    }
    
    var selectedID: String? {
        switch data.breakdownType {
        case .monthly:
            selectedMonth?.id
        case .quarterly:
            selectedQuarter?.id
        }
    }
    
    
    var widgetTitle: String {
        switch selectedTab {
        case .expense:
            " Spending"
        case .income:
            " Income"
        case .compare:
            " Spend & Income"
        }
    }
    
    var annotationColor: AnyShapeStyle {
        switch selectedTab {
        case .expense: AnyShapeStyle(Color.red.gradient)
        case .income: AnyShapeStyle(Color.blue.gradient)
        case .compare: AnyShapeStyle(
            LinearGradient(
                stops: [
                    .init(color: .red, location: 0),
                    .init(color: .blue, location: 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        }
    }
    
//    private var lastChartDate: Date? {
//        data.monthlyBreakdowns.map(\.date).max()
//    }
//
//    private var chartStartDateForEnd: Date? {
//        lastChartDate?.addingTimeInterval(-visibleSeconds)
//    }
//    
//    private var visibleStartDate: Date? {
//        chartScroll
//    }
//    
//    private var visibleEndDate: Date? {
//        guard let chartScroll else { return nil }
//        return Calendar.current.date(byAdding: .year, value: 2, to: chartScroll)
//    }
//
//    private var visibleMonths: [DashboardDataByMonth] {
//        guard let start = chartScroll,
//              let end = visibleEndDate else { return [] }
//
//        return data.monthlyBreakdowns.filter {
//            $0.date >= start && $0.date < end
//        }
//    }
//
//    private var visibleSpendTotal: Double {
//        visibleMonths.reduce(0) { partial, month in
//            partial + (model.shouldUseTotalSpending ? month.allAmounts?.totalSpend ?? 0 : month.allAmounts?.actualSpend ?? 0)
//        }
//    }
//    
//    private var visibleIncomeTotal: Double {
//        visibleMonths.reduce(0) { partial, month in
//            partial + (month.allAmounts?.irregularIncome ?? 0) + (month.allAmounts?.regularIncome ?? 0)
//        }
//    }
//    
//    private var rangeText: String {
//        guard let start = visibleStartDate, let end = visibleEndDate else { return "" }
//
//        let formatter = DateFormatter()
//        formatter.dateFormat = "MMM yyyy"
//
//        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
//    }
    
    
    var body: some View {
        
        DashboardWidget(showFilterText: !model.allCatsSelected) {
            HStack(spacing: 0) {
                Menu {
                    ForEach(DashboardMontlyOrQuarterlyBreakdowns.allCases, id: \.self) { opt in
                        Button {
                            withAnimation {
                                data.breakdownType = opt
                            }
                        } label: {
                            Text(opt.rawValue)
                        }
                    }
                } label: {
                    Text(data.breakdownType.rawValue)
                        .bold()
                }
                .padding(.leading, 12)
                
                Text(widgetTitle)
                    .foregroundStyle(.secondary)
                    .font(.headline)
                    .layoutPriority(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                
//                Picker("", selection: $data.breakdownType) {
//                    ForEach(DashboardMontlyOrQuarterlyBreakdowns.allCases, id: \.self) {
//                        Text($0.rawValue)
//                            .tag($0)
//                    }
//                }
//                .labelsHidden()
//                .pickerStyle(.menu)
            }
        } content: {
            VStack {
                TabView(selection: $selectedTab) {
                    Tab("Spending", systemImage: "tray.and.arrow.up", value: Tabs.expense) {
                        VStack {
                            expenseChart2
                            Spacer()
                        }
                        .padding(.top, 10)
                    }
                    
                    Tab("Income", systemImage: "tray.and.arrow.down", value: Tabs.income) {
                        VStack {
                            incomeChart2
                            Spacer()
                        }
                        .padding(.top, 10)
                    }
                    
                    Tab("Spending and Income", systemImage: "chart.xyaxis.line", value: Tabs.compare) {
                        VStack {
                            compareChart
                            Spacer()
                        }
                        .padding(.top, 10)
                    }
                }
                .frame(height: 200)
                #if os(iOS)
                .tabViewStyle(.page)
                #endif
                .padding(.bottom, -20) /// Remove the padding under the page indicators
            }
            .overlay(alignment: .top) {
                if let selectedMonth = selectedMonth {
                    selectedDataView
                }
            }
//            .onChange(of: lastChartDate) { _, _ in
//                chartScroll = chartStartDateForEnd
//            }
//            .onAppear {
//                chartScroll = chartStartDateForEnd
//            }
        }

        
//        DashboardWidget(title: widgetTitle) {
//            
//        }
    }
    
    
    var expenseChart2: some View {
        Chart {
            if let selectedSummary = selectedSummary {
                let date = switch data.breakdownType {
                case .monthly:
                    selectedSummary.date
                case .quarterly:
                    selectedSummary.date.middleDateOfQuarter
                }
                RuleMark(x: .value("Start Date", date, unit: .month))
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
            
            switch data.breakdownType {
            case .monthly:
                ForEach(data.monthlyBreakdowns) { month in
                    BarMark(
                        x: .value("Date", month.date, unit: .month),
                        y: .value("Amount", model.shouldUseTotalSpending ? month.allAmounts?.totalSpend ?? 0 : month.allAmounts?.actualSpend ?? 0)
                    )
                    .foregroundStyle(.red.gradient)
                    //.opacity(month.date == selectedMonth?.date ? 1 : (selectedMonth == nil ? 1 : 0.3))
                }
            case .quarterly:
                ForEach(data.quarterlyBreakdowns) { quarter in
                    RectangleMark(
                        xStart: .value("Start Date", quarter.date.startDateOfQuarter, unit: .day),
                        xEnd: .value("End Date", quarter.date.endDateOfQuarter.addingTimeInterval(-60 * 60 * 24 * 14), unit: .day),
                        yStart: .value("Start", 0),
                        yEnd: .value("End", model.shouldUseTotalSpending ? quarter.allAmounts?.totalSpend ?? 0 : quarter.allAmounts?.actualSpend ?? 0)
                    )
                    .foregroundStyle(.red.gradient)
                }
            }
        }
        .frame(height: 150)
        .sensoryFeedback(.selection, trigger: selectedID)
        .chartXSelection(value: $rawSelectedDate)
        .chartYAxis { yAxis() }
    }
    
    
    
    
//    var expenseChart: some View {
//        Chart(data.monthlyBreakdowns) { month in
//            if let selectedMonth = selectedMonth {
//                RuleMark(x: .value("Start Date", selectedMonth.date, unit: .month))
//                    .foregroundStyle(Color.secondary.opacity(0.5))
//            }
//            
//            BarMark(
//                x: .value("Date", month.date, unit: .month),
//                y: .value("Amount", model.shouldUseTotalSpending ? month.allAmounts?.totalSpend ?? 0 : month.allAmounts?.actualSpend ?? 0)
//            )
//            .foregroundStyle(.green.gradient)
//            //.opacity(month.date == selectedMonth?.date ? 1 : (selectedMonth == nil ? 1 : 0.3))
//        }
//        .frame(height: 150)
//        .sensoryFeedback(.selection, trigger: selectedMonth)
//        .chartXSelection(value: $rawSelectedDate)
//        .chartYAxis { yAxis() }
////        .chartXVisibleDomain(length: visibleSeconds)
////        .chartScrollableAxes(.horizontal)
////        .chartScrollTargetBehavior(.valueAligned(matching: DateComponents(day: 1), majorAlignment: .matching(DateComponents(month: 1))))
////        .chartScrollPosition(x: Binding(
////            get: { chartScroll ?? chartStartDateForEnd ?? Date() },
////            set: { chartScroll = $0 }
////        ))
//    }
    
    
    var incomeChart2: some View {
        Chart {
            if let selectedSummary = selectedSummary {
                let date = switch data.breakdownType {
                case .monthly:
                    selectedSummary.date
                case .quarterly:
                    selectedSummary.date.middleDateOfQuarter
                }
                RuleMark(x: .value("Start Date", date, unit: .month))
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
               
            switch data.breakdownType {
            case .monthly:
                ForEach(data.monthlyBreakdowns) { month in
                    BarMark(
                        x: .value("Date", month.date, unit: .month),
                        y: .value("Amount", (month.allAmounts?.irregularIncome ?? 0) + (month.allAmounts?.regularIncome ?? 0))
                    )
                    .foregroundStyle(.blue.gradient)
                    //.opacity(month.date == selectedMonth?.date ? 1 : (selectedMonth == nil ? 1 : 0.3))
                }
            case .quarterly:
                ForEach(data.quarterlyBreakdowns) { quarter in
                    RectangleMark(
                        xStart: .value("Start Date", quarter.date.startDateOfQuarter, unit: .day),
                        xEnd: .value("End Date", quarter.date.endDateOfQuarter.addingTimeInterval(-60 * 60 * 24 * 14), unit: .day),
                        yStart: .value("Start", 0),
                        yEnd: .value("End", (quarter.allAmounts?.irregularIncome ?? 0) + (quarter.allAmounts?.regularIncome ?? 0))
                    )
                    .foregroundStyle(.blue.gradient)
                }
            }
        }
        .frame(height: 150)
        .sensoryFeedback(.selection, trigger: selectedID)
        .chartXSelection(value: $rawSelectedDate)
        .chartYAxis { yAxis() }
//        .chartXVisibleDomain(length: visibleSeconds)
//        .chartScrollableAxes(.horizontal)
//        .chartScrollTargetBehavior(.valueAligned(matching: DateComponents(day: 1), majorAlignment: .matching(DateComponents(month: 1))))
//        .chartScrollPosition(x: Binding(
//            get: { chartScroll ?? chartStartDateForEnd ?? Date() },
//            set: { chartScroll = $0 }
//        ))
    }
    
    
//    var incomeChart: some View {
//        Chart(data.monthlyBreakdowns) { month in
//            if let selectedMonth = selectedMonth {
//                RuleMark(x: .value("Start Date", selectedMonth.date, unit: .month))
//                    .foregroundStyle(Color.secondary.opacity(0.5))
//            }
//            
//            BarMark(
//                x: .value("Date", month.date, unit: .month),
//                y: .value("Amount", (month.allAmounts?.irregularIncome ?? 0) + (month.allAmounts?.regularIncome ?? 0))
//            )
//            .foregroundStyle(.blue.gradient)
//            //.opacity(month.date == selectedMonth?.date ? 1 : (selectedMonth == nil ? 1 : 0.3))
//        }
//        .frame(height: 150)
//        //.sensoryFeedback(.selection, trigger: selectedMonth)
//        .chartXSelection(value: $rawSelectedDate)
//        .chartYAxis { yAxis() }
////        .chartXVisibleDomain(length: visibleSeconds)
////        .chartScrollableAxes(.horizontal)
////        .chartScrollTargetBehavior(.valueAligned(matching: DateComponents(day: 1), majorAlignment: .matching(DateComponents(month: 1))))
////        .chartScrollPosition(x: Binding(
////            get: { chartScroll ?? chartStartDateForEnd ?? Date() },
////            set: { chartScroll = $0 }
////        ))
//    }
    
    
    var compareChart: some View {
        Chart {
            if let selectedSummary = selectedSummary {
                let date = switch data.breakdownType {
                case .monthly:
                    selectedSummary.date
                case .quarterly:
                    selectedSummary.date.startDateOfQuarter
                }
                RuleMark(x: .value("Start Date", date, unit: .day))
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
               
            switch data.breakdownType {
            case .monthly:
                ForEach(data.monthlyBreakdowns) { month in
                    LineMark(
                        x: .value("Date", month.date, unit: .day),
                        y: .value("Amount", model.shouldUseTotalSpending ? month.allAmounts?.totalSpend ?? 0 : month.allAmounts?.actualSpend ?? 0),
                        series: .value("", "Spending")
                    )
                    .foregroundStyle(.red.gradient)
                    .symbol {
                        Circle()
                            .fill(.red)
                            .frame(width: 5, height: 5)
                    }
                    
                    LineMark(
                        x: .value("Date", month.date, unit: .day),
                        y: .value("Amount", (month.allAmounts?.irregularIncome ?? 0) + (month.allAmounts?.regularIncome ?? 0)),
                        series: .value("", "Income")
                    )
                    .foregroundStyle(.blue.gradient)
                    .symbol {
                        Circle()
                            .fill(.blue)
                            .frame(width: 5, height: 5)
                    }
                }
                .interpolationMethod(.catmullRom)
                
            case .quarterly:
                ForEach(data.quarterlyBreakdowns) { quarter in
                    LineMark(
                        x: .value("Date", quarter.date.startDateOfQuarter, unit: .day),
                        y: .value("Amount", model.shouldUseTotalSpending ? quarter.allAmounts?.totalSpend ?? 0 : quarter.allAmounts?.actualSpend ?? 0),
                        series: .value("", "Spending")
                    )
                    .foregroundStyle(.red.gradient)
                    .symbol {
                        Circle()
                            .fill(.red)
                            .frame(width: 5, height: 5)
                    }
                    
                    LineMark(
                        x: .value("Date", quarter.date.startDateOfQuarter, unit: .day),
                        y: .value("Amount", (quarter.allAmounts?.irregularIncome ?? 0) + (quarter.allAmounts?.regularIncome ?? 0)),
                        series: .value("", "Income")
                    )
                    .foregroundStyle(.blue.gradient)
                    .symbol {
                        Circle()
                            .fill(.blue)
                            .frame(width: 5, height: 5)
                    }
                }
                .interpolationMethod(.catmullRom)
            }
        }
        .frame(height: 150)
        .sensoryFeedback(.selection, trigger: selectedID)
        .chartXSelection(value: $rawSelectedDate)
        .chartYAxis { yAxis() }
        .chartForegroundStyleScale(
            domain: ["Spending", "Income"],
            range: [.red, .blue]
        )
//        .chartXVisibleDomain(length: visibleSeconds)
//        .chartScrollableAxes(.horizontal)
//        .chartScrollTargetBehavior(.valueAligned(matching: DateComponents(day: 1), majorAlignment: .matching(DateComponents(month: 1))))
//        .chartScrollPosition(x: Binding(
//            get: { chartScroll ?? chartStartDateForEnd ?? Date() },
//            set: { chartScroll = $0 }
//        ))
    }
    
    
    @AxisContentBuilder
    func yAxis() -> some AxisContent {
        AxisMarks { axisValue in
            AxisGridLine()
            AxisTick()
            AxisValueLabel {
                if let value = axisValue.as(Double.self) {
                    Text("$\(value.kVersion)")
                }
            }
        }
    }
    
    @ViewBuilder
    var selectedDataView: some View {
        if let item = selectedSummary {
            VStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(item.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)

                        Spacer()

//                        Chart(item.flatCats) { cat in
//                            SectorMark(
//                                angle: .value("Amount", max(0, cat.allAmounts?.totalSpend ?? 0.0)),
//                                innerRadius: .ratio(0.2),
//                                angularInset: 0.5
//                            )
//                            .cornerRadius(2)
//                            .foregroundStyle(cat.color)
//                        }
//                        .id(item.date)
//                        .frame(width: 50, height: 50)
                    }
                    .font(.headline)

                    Divider()

                    Grid(alignment: .leading) {
                        GridRow {
                            Text("Budget").bold()
                            Text(item.categoryAndGroupBudget.currencyWithDecimals())
                        }

                        GridRow {
                            Text("Income").bold()
                            Text(
                                (
                                    (item.allAmounts?.irregularIncome ?? 0.0) +
                                    (item.allAmounts?.regularIncome ?? 0.0)
                                )
                                .currencyWithDecimals()
                            )
                        }

                        GridRow {
                            Text("Expenses").bold()
                            Text((item.allAmounts?.totalSpend ?? 0.0).currencyWithDecimals())
                        }

                        Divider()

                        GridRow {
                            Text("Actual Spend").bold()
                            Text((item.allAmounts?.actualSpend ?? 0.0).currencyWithDecimals())
                        }
                    }
                    .font(.subheadline)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(annotationColor)
                )
                .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .background {
                GeometryReader { geo in
                    Color.clear
                        .onAppear { annotationHeight = geo.size.height }
                        .onChange(of: geo.size.height) { annotationHeight = $1 }
                }
            }
            .offset(y: -annotationHeight - 8)
            .zIndex(10)
        }
    }
}
