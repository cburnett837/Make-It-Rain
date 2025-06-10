//
//  MinMaxEodChart.swift
//  MakeItRain
//
//  Created by Cody Burnett on 6/2/25.
//


import SwiftUI
import Charts


struct MinMaxEodChartWidget: View {
    @Bindable var vm: PayMethodViewModel
    @Bindable var payMethod: CBPaymentMethod
    //@State private var showOptions = false
    
    var body: some View {
        VStack(alignment: .leading) {
            WidgetLabel(title: "Min/Max EOD Amounts")
            MinMaxEodChart(vm: vm, payMethod: payMethod)
                .padding()
                .widgetShape()
        }
        .padding(.bottom, 30)
    }
    
}


struct MinMaxEodChart: View {
    @Local(\.colorTheme) var colorTheme
    @Local(\.threshold) var threshold
    @Local(\.useWholeNumbers) var useWholeNumbers
    //@ChartOption(\.showOverviewDataPerMethodOnUnifiedChart) var showOverviewDataPerMethodOnUnifiedChart
    @AppStorage(LocalKeys.Charts.Options.showOverviewDataPerMethodOnUnified) var showOverviewDataPerMethodOnUnifiedChart = false


    @Bindable var vm: PayMethodViewModel
    @Bindable var payMethod: CBPaymentMethod
    
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
            ChartLegendView(items: [
                (id: UUID(), title: "Above Threshold", color: Color.green),
                (id: UUID(), title: "Under Threshold", color: Color.orange),
            ])
            
            Chart {
                if let selectedDate {
                    vm.selectionRectangle(for: selectedDate, color: .clear, content: selectedDataView)
                }
                
                ForEach(vm.relevantBreakdowns()) {
                    minMaxLine($0)
                }
            }
            .frame(minHeight: 150)
            .chartYAxis { vm.yAxis() }
            .chartXAxis { vm.xAxis() }
            //.chartXVisibleDomain(length: vm.visibleChartAreaDomain)
            .chartXScale(domain: vm.chartXScale)
            .chartXSelection(value: $rawSelectedDate)
            .maxChartWidthObserver()
            .onPreferenceChange(MaxChartSizePreferenceKey.self) { chartWidth = max(chartWidth, $0) }
        }
        .sensoryFeedback(.selection, trigger: selectedDate) { $0 != nil && $1 != nil }
        //.gesture(vm.moveYearGesture)
    }
    
    @ChartContentBuilder
    func minMaxLine(_ breakdown: PayMethodMonthlyBreakdown) -> some ChartContent {
        let startColor: Color = breakdown.minEod < threshold ? .orange : .green
        let min = breakdown.minEod
        let max = breakdown.maxEod
        let positionForNewColor: Double? = vm.getGradientPosition(for: .minMaxEod, flipAt: threshold, min: min, max: max)
        let gradient = Gradient(
            stops: [
                .init(color: startColor, location: 0),
                .init(color: startColor, location: positionForNewColor ?? 0.5 - 0.00001),
                .init(color: .green, location: positionForNewColor ?? 0.5 + 0.00001),
                .init(color: .green, location: 1)
            ]
        )
        
        var opacity: Double {
            if let selectedDate {
                breakdown.date == selectedDate ? 1 : 0.3
            } else {
                1
            }
        }
        
        if vm.viewByQuarter {
            RectangleMark(
                xStart: .value("Start Date", breakdown.date.startOfQuarter, unit: .day),
                xEnd: .value("End Date", breakdown.date.endOfQuarter.addingTimeInterval(-60 * 60 * 24 * 14), unit: .day),
                yStart: .value("Min Eod", breakdown.minEod),
                yEnd: .value("Max Eod", breakdown.maxEod),
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(.linearGradient(gradient, startPoint: .bottom, endPoint: .top))
            .opacity(opacity)
        } else {
            RectangleMark(
                x: .value("Start Date", breakdown.date, unit: .month),
                yStart: .value("Min Eod", breakdown.minEod),
                yEnd: .value("Max Eod", breakdown.maxEod),
                width: .ratio(0.6)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(.linearGradient(gradient, startPoint: .bottom, endPoint: .top))
            .opacity(opacity)
        }
    }
    
    @ViewBuilder
    var selectedDataView: some View {
        if let selectedDate = selectedDate {
            ChartSelectedDataContainer(vm: vm, payMethod: payMethod, selectedDate: selectedDate, chartWidth: chartWidth, showOverviewDataPerMethodOnUnifiedChart: showOverviewDataPerMethodOnUnifiedChart) {
                if showOverviewDataPerMethodOnUnifiedChart { Text("Method") }
                Text("Min EOD")
                Text("Max EOD")
            } rows: {
                if showOverviewDataPerMethodOnUnifiedChart {
                    ForEach(vm.breakdownPerMethod(on: selectedDate)) { info in
                        GridRow(alignment: .top) {
                            HStack(spacing: 0) {
                                CircleDot(color: info.color)
                                Text(info.title)
                            }
                            
                            Text(info.minEod.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                                .foregroundStyle(info.minEod < threshold ? .orange : .secondary)
                            
                            Text(info.maxEod.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                                .foregroundStyle(info.maxEod < threshold ? .orange : .secondary)
                            
                        }
                    }
                } else {
                    EmptyView()
                }
            } summary: {
                let breakdown = vm.breakdownForMethod(method: vm.mainPayMethod, on: selectedDate)
                Text(breakdown.minEod.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                    .foregroundStyle(breakdown.minEod < threshold ? .orange : .secondary)
                
                Text(breakdown.maxEod.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                    .foregroundStyle(breakdown.maxEod < threshold ? .orange : .secondary)
            }
        }
    }
}
