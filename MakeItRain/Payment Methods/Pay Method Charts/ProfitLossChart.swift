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
    @State private var showOptions = false
        
    var body: some View {
        VStack(alignment: .leading) {
            WidgetLabelButton(title: "Profit/Loss") {
                showOptions.toggle()
            }
            
            ProfitLossChart(vm: vm, payMethod: payMethod, showOptions: $showOptions, detailStyle: .overlay)
                .padding()
                .widgetShape()
        }
        .padding(.bottom, 30)
    }
}


struct ProfitLossChart: View {
    @Local(\.colorTheme) var colorTheme
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Local(\.threshold) var threshold
    
    @AppStorage(LocalKeys.Charts.ProfitLoss.metrics) private var metrics: MetricStyle = .summary
    @AppStorage(LocalKeys.Charts.ProfitLoss.style) private var style: DisplayStyle = .amount
    @AppStorage(LocalKeys.Charts.Options.showOverviewDataPerMethodOnUnified) var showOverviewDataPerMethodOnUnifiedChart = false

    @Bindable var vm: PayMethodViewModel
    @Bindable var payMethod: CBPaymentMethod
    @Binding var showOptions: Bool
    var detailStyle: DetailStyle
    
    @State private var chartWidth: CGFloat = 0
    @State private var showDetailsSheet = false
    
    @State private var rawSelectedDate: Date?
    var selectedDate: Date? {
        if let raw = rawSelectedDate {
            let breakdowns = vm.payMethods.first?.breakdowns
            if vm.viewByQuarter {
                return breakdowns?.first {
                    $0.date.year == raw.year && $0.date.startOfQuarter == raw.startOfQuarter
                }?.date
            } else {
                return breakdowns?.first { raw.matchesMonth(of: $0.date) }?.date
            }
        } else {
            return nil
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if payMethod.isUnified {
                if metrics == .summary {
                    ChartLegendView(items: [
                        (id: UUID(), title: "Profit", color: Color.green),
                        (id: UUID(), title: "Loss", color: Color.red),
                    ])
                } else {
                    ChartLegendView(items: vm.payMethods.map { (id: UUID(), title: $0.title, color: $0.color) })
                }
            }
                                                    
            Chart {
                /// WARNING! This cannot be a computed property.
                let positionForNewColor: Double? = vm.getGradientPosition(for: style == .amount ? .amount : .percentage, flipAt: 0)
                
                if let selectedDate {
                    vm.selectionRectangle(for: selectedDate, content: selectedDataView)
                }
                     
                if metrics == .summary {
                    ForEach(vm.relevantBreakdowns()) {
                        profitLossLine(meth: payMethod, breakdown: $0, positionForNewColor: positionForNewColor)
                    }
                } else {
                    ForEach(vm.payMethods) { meth in
                        ForEach(vm.relevantBreakdowns(for: meth)) {
                            profitLossLine(meth: meth, breakdown: $0, positionForNewColor: positionForNewColor)
                        }
                    }
                }
            }
            .frame(minHeight: 150)
            .chartYAxis { vm.yAxis(symbol: style == .amount ? "$" : "%") }
            .chartXAxis { vm.xAxis() }
            //.chartXVisibleDomain(length: vm.visibleChartAreaDomain)
            .chartXScale(domain: vm.chartXScale)
            .chartXSelection(value: $rawSelectedDate)
            .maxChartWidthObserver()
            .onPreferenceChange(MaxChartSizePreferenceKey.self) { chartWidth = max(chartWidth, $0) }
        }
        //.gesture(vm.moveYearGesture)
        .sensoryFeedback(.selection, trigger: selectedDate) { $0 != nil && $1 != nil }
        .sheet(isPresented: $showOptions) {
            ChartOptionsSheet(vm: vm, payMethod: payMethod, showOptions: $showOptions)
        }
    }
    
    @ChartContentBuilder
    func profitLossLine(meth: CBPaymentMethod, breakdown: PayMethodMonthlyBreakdown, positionForNewColor: Double?) -> some ChartContent {
        let isGreaterThanZero = (style == .amount ? breakdown.profitLoss : breakdown.profitLossPercentage) >= 0
        
        if payMethod.isUnified {
            if metrics == .summary {
                summaryLine(meth: meth, breakdown: breakdown, positionForNewColor: positionForNewColor, isGreaterThanZero: isGreaterThanZero)
            } else {
                individualLine(meth: meth, breakdown: breakdown, positionForNewColor: positionForNewColor, isGreaterThanZero: isGreaterThanZero)
            }
        } else {
            summaryLine(meth: meth, breakdown: breakdown, positionForNewColor: positionForNewColor, isGreaterThanZero: isGreaterThanZero)
        }
    }
    
    @ChartContentBuilder
    func summaryLine(meth: CBPaymentMethod, breakdown: PayMethodMonthlyBreakdown, positionForNewColor: Double?, isGreaterThanZero: Bool) -> some ChartContent {
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
        }
    }
    
    @ChartContentBuilder
    func individualLine(meth: CBPaymentMethod, breakdown: PayMethodMonthlyBreakdown, positionForNewColor: Double?, isGreaterThanZero: Bool) -> some ChartContent {
        LineMark(
            x: .value("Date", breakdown.date, unit: .month),
            y: .value("Amount5", style == .amount ? breakdown.profitLoss : breakdown.profitLossPercentage),
            series: .value("", "Amount5\(meth.id)")
        )
        .foregroundStyle(meth.color)
        .interpolationMethod(.catmullRom)
    }
    
    @ViewBuilder
    var selectedDataView: some View {
        if let selectedDate = selectedDate {
            ChartSelectedDataContainer(vm: vm, payMethod: payMethod, selectedDate: selectedDate, chartWidth: chartWidth, showOverviewDataPerMethodOnUnifiedChart: showOverviewDataPerMethodOnUnifiedChart) {
                if showOverviewDataPerMethodOnUnifiedChart { Text("Method") }
                Text("Begin")
                Text("End")
                Text("PL $")
                Text("PL %")
            } rows: {
                if showOverviewDataPerMethodOnUnifiedChart {
                    ForEach(vm.breakdownPerMethod(on: selectedDate)) { breakdown in
                        GridRow(alignment: .top) {
                            HStack(spacing: 0) {
                                CircleDot(color: breakdown.color)
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
                } else {
                    EmptyView()
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
        }
    }
}




fileprivate struct ChartOptionsSheet: View {
    @AppStorage(LocalKeys.Charts.ProfitLoss.metrics) private var metrics: MetricStyle = .summary
    @AppStorage(LocalKeys.Charts.ProfitLoss.style) private var style: DisplayStyle = .amount
    
    @Bindable var vm: PayMethodViewModel
    @Bindable var payMethod: CBPaymentMethod
    @Binding var showOptions: Bool
    
    let styleDesc: LocalizedStringKey = "View the difference between the start of the month and the end of the month as either a dollar amount, or percentage."
    let metricDesc: LocalizedStringKey = "View a summary of profit/loss or split by each payment method."
    
    
    var body: some View {
        LittleBottomSheetContainer {
            
            //let thing = vm.relevantBreakdowns()
            
//            ForEach(vm.relevantBreakdowns()) { thing in
//                Text("\(thing.payMethodID)-\(thing.profitLossString)-\(thing.profitLossPercentage)")
//            }
            
//            Text("Calculations are made using the difference between the balance at the start of the month and the end of the month.")
//                .multilineTextAlignment(.center)
//                .font(.caption2)
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .foregroundStyle(.secondary)
//            
//            Divider()
            
            ChartOptionMenu(description: styleDesc, title: "Profit Loss Style", menu: profitLossStyleMenu)
                .padding(.bottom, 6)
            
            if payMethod.isUnified {
                ChartOptionMenu(description: metricDesc, title: "Metric Style", menu: profitLossMetricsMenu)
                    .padding(.bottom, 6)
            }
        } header: {
            SheetHeader(title: "Profit/Loss Details", close: { showOptions = false })
        }
    }
        
    var profitLossStyleMenu: some View {
        Menu(style.prettyValue) {
            ForEach(DisplayStyle.allCases) { opt in
                Button(opt.prettyValue) { style = opt }
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

