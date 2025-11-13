//
//  ProfitLossChart.swift
//  MakeItRain
//
//  Created by Cody Burnett on 6/2/25.
//

import SwiftUI
import Charts

struct ProfitLossChartWidget: View {
    @Bindable var vm: PayMethodViewModel
    @Bindable var payMethod: CBPaymentMethod
        
    var body: some View {
        NavigationLink {
            ProfitLossChartDetails(vm: vm, payMethod: payMethod)
        } label: {
            ProfitLossChart(
                vm: vm,
                payMethod: payMethod,
                rawSelectedDate: .constant(nil),
                selectedDate: nil,
                allowSelection: false,
                animateImmediately: false
            )
        }
        #if os(iOS)
        .navigationLinkIndicatorVisibility(.hidden)
        #endif
    }
}



struct ProfitLossChartDetails: View {
    @Local(\.useWholeNumbers) var useWholeNumbers
    @AppStorage(LocalKeys.Charts.Options.showOverviewDataPerMethodOnUnified) var showOverviewDataPerMethodOnUnifiedChart = false
    @Environment(\.colorScheme) var colorScheme
    
    @Bindable var vm: PayMethodViewModel
    @Bindable var payMethod: CBPaymentMethod
    
    @State private var rawSelectedDate: Date?
    var selectedDate: Date? {
        if let raw = rawSelectedDate {
            let breakdowns = vm.payMethods.first?.breakdowns
            if vm.viewByQuarter {
                return breakdowns?.first { $0.date.year == raw.year && $0.date.startOfQuarter == raw.startOfQuarter }?.date
            } else {
                return breakdowns?.first { raw.matchesMonth(of: $0.date) }?.date
            }
        } else {
            return nil
        }
    }
    
    var body: some View {
        StandardContainerWithToolbar(.list) {
            Section("Details \(selectedDate == nil ? "" : vm.overViewTitle(for: selectedDate))") {
                selectedDataView
            }
                            
            PaymentMethodChartDetailsSectionContainer(vm: vm, payMethod: payMethod) {
                ProfitLossChart(
                    vm: vm,
                    payMethod: payMethod,
                    rawSelectedDate: $rawSelectedDate,
                    selectedDate: selectedDate,
                    allowSelection: true,
                    animateImmediately: true
                )
            }
                                            
            Section {
                ChartOptionsSheet(vm: vm, payMethod: payMethod)
            }
        }
        .navigationTitle("Net Worth")
        .navigationSubtitle(payMethod.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { PaymentMethodChartStyleMenu(vm: vm) }
        }
        #endif
    }
    
    
    
    @ViewBuilder
    var selectedDataView: some View {
        if let selectedDate = selectedDate {
            ChartSelectedDataContainer(
                vm: vm,
                payMethod: payMethod,
                columnCount: (payMethod.isCreditOrLoan || payMethod.isUnifiedCredit) ? 5 : 4
            ) {
                Text("Account")
                Text("Begin")
                Text("End")
                Text("PL $")
                Text("PL %")
            } rows: {
                ForEach(vm.breakdownPerMethod(on: selectedDate)) { breakdown in
                    GridRow(alignment: .top) {
                        HStack(spacing: 5) {
                            CircleDot(color: breakdown.color, width: 5)
                            Text(breakdown.title)
                        }
                        
                        Text(breakdown.startingAmounts.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                        Text(breakdown.monthEnd.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                        
                        Text(breakdown.profitLoss.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                            .foregroundStyle(breakdown.profitLoss < 0 ? . red : .green)
                        
                        Text("\(breakdown.profitLossPercentage.decimals(1))%")
                            .foregroundStyle(breakdown.profitLossPercentage < 0 ? . red : .green)
                    }
                }
            } summary: {
                let breakdown = vm.breakdownForMethod(method: vm.mainPayMethod, on: selectedDate)
                Text(breakdown.startingAmounts.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                Text(breakdown.monthEnd.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                Text(breakdown.profitLoss.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                    .foregroundStyle(breakdown.profitLoss < 0 ? . red : .green)
                Text("\(breakdown.profitLossPercentage.decimals(1))%")
                    .foregroundStyle(breakdown.profitLossPercentage < 0 ? . red : .green)
            }
        } else {
            Text("Drag across the chart to see details")
                .foregroundStyle(.gray)
        }
    }
}



struct ProfitLossChart: View {
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Local(\.threshold) var threshold
    
    @AppStorage(LocalKeys.Charts.ProfitLoss.metrics) private var metrics: MetricStyle = .summary
    @AppStorage(LocalKeys.Charts.ProfitLoss.style) private var style: DisplayStyle = .amount
    @AppStorage(LocalKeys.Charts.Options.showOverviewDataPerMethodOnUnified) var showOverviewDataPerMethodOnUnifiedChart = false

    @Bindable var vm: PayMethodViewModel
    @Bindable var payMethod: CBPaymentMethod
    @Binding var rawSelectedDate: Date?
    
    var selectedDate: Date?
    var allowSelection: Bool
    var animateImmediately: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if payMethod.isUnified && !allowSelection {
                if metrics == .summary {
                    ChartLegendView(items: [
                        (id: UUID(), title: "Profit", color: Color.green),
                        (id: UUID(), title: "Loss", color: Color.red),
                    ])
                } else {
                    ChartLegendView(items: vm.payMethods.map { (id: UUID(), title: $0.title, color: $0.color) })
                }
            }
                                                    
            chart(showLines: true)
                //.animatedLineChart(beginAnimation: animateImmediately ? true : !vm.isLoadingHistory) { chart(showLines: $0) }
        }
        .sensoryFeedback(.selection, trigger: selectedDate) { $0 != nil && $1 != nil }
    }
    
    @ViewBuilder func chart(showLines: Bool) -> some View {
        Chart {
            /// WARNING! This cannot be a computed property.
            let positionForNewColor: Double? = vm.getGradientPosition(for: style == .amount ? .amount : .percentage, flipAt: 0)
            
            if let selectedDate {
                vm.selectionRectangle(for: selectedDate, color: Color.secondary)
            }
        
            if metrics == .summary {
                ForEach(vm.relevantBreakdowns()) {
                    profitLossLine(meth: payMethod, breakdown: $0, positionForNewColor: positionForNewColor, showLines: showLines)
                }
            } else {
                ForEach(vm.payMethods) { meth in
                    ForEach(vm.relevantBreakdowns(for: meth)) {
                        profitLossLine(meth: meth, breakdown: $0, positionForNewColor: positionForNewColor, showLines: showLines)
                    }
                }
            }
        }
        .frame(minHeight: 150)
        .chartYAxis { vm.yAxis(color: showLines ? .gray : .clear, symbol: style == .amount ? "$" : "%") }
        .chartXAxis { vm.xAxis(color: showLines ? .gray : .clear) }
        .if(allowSelection) {
            $0
            .chartXScale(domain: vm.chartXScale)
            .chartXSelection(value: $rawSelectedDate)
        }
    }
    
    @ChartContentBuilder
    func profitLossLine(meth: CBPaymentMethod, breakdown: PayMethodMonthlyBreakdown, positionForNewColor: Double?, showLines: Bool) -> some ChartContent {
        let isGreaterThanZero = (style == .amount ? breakdown.profitLoss : breakdown.profitLossPercentage) >= 0
        
        if payMethod.isUnified {
            if metrics == .summary {
                summaryLine(meth: meth, breakdown: breakdown, positionForNewColor: positionForNewColor, isGreaterThanZero: isGreaterThanZero, showLines: showLines)
            } else {
                individualLine(meth: meth, breakdown: breakdown, positionForNewColor: positionForNewColor, isGreaterThanZero: isGreaterThanZero, showLines: showLines)
            }
        } else {
            summaryLine(meth: meth, breakdown: breakdown, positionForNewColor: positionForNewColor, isGreaterThanZero: isGreaterThanZero, showLines: showLines)
        }
    }
    
    @ChartContentBuilder
    func summaryLine(meth: CBPaymentMethod, breakdown: PayMethodMonthlyBreakdown, positionForNewColor: Double?, isGreaterThanZero: Bool, showLines: Bool) -> some ChartContent {
        LineMark(
            x: .value("Date", breakdown.date, unit: .month),
            y: .value("Amount5", style == .amount ? breakdown.profitLoss : breakdown.profitLossPercentage),
            series: .value("", "Amount5\(meth.id)")
        )
        .foregroundStyle(
            .linearGradient(
                Gradient(
                    stops: [
                        //.init(color: .red, location: 0),
                        //.init(color: .red, location: positionForNewColor - 0.00001),
                        //.init(color: .green, location: positionForNewColor + 0.00001),
                        //.init(color: .green, location: 1)
                        .init(color: .red, location: 0),
                        .init(color: .red, location: positionForNewColor ?? 0.5 - 0.00001),
                        .init(color: .green, location: positionForNewColor ?? 0.5 + 0.00001),
                        .init(color: .green, location: 1)
                    ]
                ),
                startPoint: .bottom,
                endPoint: .top
            )
        )
        .interpolationMethod(.catmullRom)
        .symbol {
            Circle()
                .fill(isGreaterThanZero ? .green : .red)
                .frame(width: 6, height: 6)
                .opacity(showLines ? 1 : 0)
        }
        .opacity(showLines ? 1 : 0)
    }
    
    @ChartContentBuilder
    func individualLine(meth: CBPaymentMethod, breakdown: PayMethodMonthlyBreakdown, positionForNewColor: Double?, isGreaterThanZero: Bool, showLines: Bool) -> some ChartContent {
        LineMark(
            x: .value("Date", breakdown.date, unit: .month),
            y: .value("Amount5", style == .amount ? breakdown.profitLoss : breakdown.profitLossPercentage),
            series: .value("", "Amount5\(meth.id)")
        )
        .foregroundStyle(meth.color)
        .interpolationMethod(.catmullRom)
        .opacity(showLines ? 1 : 0)
    }
}




fileprivate struct ChartOptionsSheet: View {
    @AppStorage(LocalKeys.Charts.ProfitLoss.metrics) private var metrics: MetricStyle = .summary
    @AppStorage(LocalKeys.Charts.ProfitLoss.style) private var style: DisplayStyle = .amount
    
    @Bindable var vm: PayMethodViewModel
    @Bindable var payMethod: CBPaymentMethod
    
    let styleDesc: LocalizedStringKey = "View the difference between the start of the month and the end of the month as either a dollar amount, or percentage."
    let metricDesc: LocalizedStringKey = "View a summary of profit/loss or split by each payment method."
    
    
    var body: some View {
        ChartOptionMenu(description: styleDesc, title: "Profit Loss Style", menu: profitLossStyleMenu)
        
        if payMethod.isUnified {
            ChartOptionMenu(description: metricDesc, title: "Metric Style", menu: profitLossMetricsMenu)
        }
    }
        
    var profitLossStyleMenu: some View {
        Menu(style.prettyValue) {
            ForEach(DisplayStyle.allCases) { opt in
                Button(opt.prettyValue) {
                    withAnimation {
                        style = opt
                    }
                }
            }
        }
    }
        
    var profitLossMetricsMenu: some View {
        Menu(metrics.prettyValue) {
            ForEach(MetricStyle.allCases) { opt in
                Button(opt.prettyValue) { metrics = opt }
            }
        }
    }
}


fileprivate enum DisplayStyle: String, CaseIterable, Identifiable {
    var id: DisplayStyle { self }
    case amount, percentage
    
    var prettyValue: String {
        switch self {
        case .amount: return "As amount"
        case .percentage: return "As percentage"
        }
    }
    
    static func fromString(_ string: String) -> Self {
        switch string {
        case "amount": return .amount
        case "percentage": return .percentage
        default: return .amount
        }
    }
}

fileprivate enum MetricStyle: String, CaseIterable, Identifiable {
    var id: MetricStyle { self }
    case byMethod, summary
    
    var prettyValue: String {
        switch self {
        case .byMethod: return "By payment method"
        case .summary: return "As summary"
        }
    }
    
    static func fromString(_ string: String) -> Self {
        switch string {
        case "byMethod": return .byMethod
        case "summary": return .summary
        default: return .byMethod
        }
    }
}

