//
//  DashboardActivityByMonthChart.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

struct DashboardStartingAmountByMonthChart: View {
    enum Tabs: String { case balance, payments, compare }
    @AppStorage("dashboardSelectedMonthChartPageTabThing2") var selectedTab: Tabs = .balance
    
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
        if model.payMethod?.isCreditOrUnified == true {
            switch selectedTab {
            case .balance:
                " Balance"
            case .payments:
                " Payments"
            case .compare:
                " Balance & Payments"
            }
        } else {
            " Balance"
        }
    }
    
    var annotationColor: AnyShapeStyle {
        if model.payMethod?.isCreditOrUnified == true {
            switch selectedTab {
            case .balance: AnyShapeStyle(Color.orange.gradient)
            case .payments: AnyShapeStyle(Color.green.gradient)
            case .compare: AnyShapeStyle(
                LinearGradient(
                    stops: [
                        .init(color: .orange, location: 0),
                        .init(color: .green, location: 1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            }
        } else {
            AnyShapeStyle(Color.orange.gradient)
        }
    }

    
    var body: some View {
        Card(showFilterText: !model.allCatsSelected) {
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
            }
        } content: {
            VStack {
                if model.payMethod?.isCreditOrUnified == true {
                    TabView(selection: $selectedTab) {
                        Tab("Balance", systemImage: "tray.and.arrow.up", value: Tabs.balance) {
                            VStack {
                                balanceChart
                                Spacer()
                            }
                            .padding(.top, 10)
                        }
                        
                        
                        Tab("Payments", systemImage: "tray.and.arrow.down", value: Tabs.payments) {
                            VStack {
                                paymentChart
                                Spacer()
                            }
                            .padding(.top, 10)
                        }
                        
                        
                        Tab("Balance & Payments", systemImage: "chart.xyaxis.line", value: Tabs.compare) {
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
                    
                } else {
                    VStack {
                        balanceChart
                        Spacer()
                    }
                    .padding(.top, 10)
                }
                    
            }
            .overlay(alignment: .top) {
                if let _ = selectedMonth {
                    selectedDataView
                }
            }
            
//            VStack {
//                expenseChart2
//                Spacer()
//            }
//            .overlay(alignment: .top) {
//                if let _ = selectedMonth {
//                    selectedDataView
//                }
//            }
        }
    }
    
    
//    var body: some View {
//        VStack {
//            expenseChart2
//            Spacer()
//        }
//        .overlay(alignment: .top) {
//            if let selectedMonth = selectedMonth {
//                selectedDataView
//            }
//        }
//    }
    
    var balanceChart: some View {
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
                        y: .value("Amount", month.startingAmount ?? 0),
                    )
                    .foregroundStyle(.orange.gradient)
                    //.opacity(month.date == selectedMonth?.date ? 1 : (selectedMonth == nil ? 1 : 0.3))
                }
            case .quarterly:
                ForEach(data.quarterlyBreakdowns) { quarter in
                    RectangleMark(
                        xStart: .value("Start Date", quarter.date.startDateOfQuarter, unit: .day),
                        xEnd: .value("End Date", quarter.date.endDateOfQuarter.addingTimeInterval(-60 * 60 * 24 * 14), unit: .day),
                        yStart: .value("Start", 0),
                        yEnd: .value("End", quarter.startingAmount ?? 0)
                    )
                    .foregroundStyle(.orange.gradient)
                }
            }
        }
        .frame(height: 150)
        .sensoryFeedback(.selection, trigger: selectedID)
        .chartXSelection(value: $rawSelectedDate)
        .chartYAxis { yAxis() }
    }
    
    
    var paymentChart: some View {
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
                        y: .value("Amount", (month.paymentAmount ?? 0) * -1)
                    )
                    .foregroundStyle(.green.gradient)
                    //.opacity(month.date == selectedMonth?.date ? 1 : (selectedMonth == nil ? 1 : 0.3))
                }
            case .quarterly:
                ForEach(data.quarterlyBreakdowns) { quarter in
                    RectangleMark(
                        xStart: .value("Start Date", quarter.date.startDateOfQuarter, unit: .day),
                        xEnd: .value("End Date", quarter.date.endDateOfQuarter.addingTimeInterval(-60 * 60 * 24 * 14), unit: .day),
                        yStart: .value("Start", 0),
                        yEnd: .value("End", (quarter.paymentAmount ?? 0) * -1)
                    )
                    .foregroundStyle(.green.gradient)
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
                        y: .value("Amount", month.startingAmount ?? 0),
                        series: .value("Type", "Starting")
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.orange.gradient)
                    .symbol {
                        Circle()
                            .fill(.orange)
                            .frame(width: 5, height: 5)
                    }
                    
                    if model.payMethod?.isCreditOrUnified == true {
                        LineMark(
                            x: .value("Date", month.date, unit: .day),
                            y: .value("Amount", (month.paymentAmount ?? 0) * -1),
                            series: .value("Type", "Payment")
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.green.gradient)
                        .symbol {
                            Circle()
                                .fill(.green)
                                .frame(width: 5, height: 5)
                        }
                    }
                    
                }
            case .quarterly:
                ForEach(data.quarterlyBreakdowns) { quarter in
                    LineMark(
                        x: .value("Start Date", quarter.date.startDateOfQuarter, unit: .day),
                        y: .value("Amount", quarter.startingAmount ?? 0),
                        series: .value("Type", "Balance")
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.orange.gradient)
                    .symbol {
                        Circle()
                            .fill(.orange)
                            .frame(width: 5, height: 5)
                    }
                    
                    LineMark(
                        x: .value("Date", quarter.date.startDateOfQuarter, unit: .day),
                        y: .value("Amount", (quarter.paymentAmount ?? 0) * -1),
                        series: .value("Type", "Payment")
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.green.gradient)
                    .symbol {
                        Circle()
                            .fill(.green)
                            .frame(width: 5, height: 5)
                    }
                }
            }
        }
        .frame(height: 150)
        .sensoryFeedback(.selection, trigger: selectedID)
        .chartXSelection(value: $rawSelectedDate)
        .chartYAxis { yAxis() }
        //.chartLegend(position: .top, alignment: .leading, spacing: 8)
        .chartForegroundStyleScale(
            domain: ["Balance", "Payment"],
            range: [.orange, .green]
        )
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
                    }
                    .font(.headline)

                    Divider()

                    Grid(alignment: .leading) {
                        GridRow {
                            Text("Beginning Balance").bold()
                            Text((item.startingAmount ?? 0).currencyWithDecimals())
                        }
                        
                        if model.payMethod?.isCreditOrUnified == true {
                            GridRow {
                                Text("Payments").bold()
                                Text(((item.paymentAmount ?? 0) * -1).currencyWithDecimals())
                            }
                        }
                    }
                    .font(.subheadline)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(annotationColor)
//                        .fill(.orange.gradient)
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
