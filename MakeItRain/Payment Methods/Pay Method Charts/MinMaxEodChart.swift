//
//  MinMaxEodChart.swift
//  MakeItRain
//
//  Created by Cody Burnett on 6/2/25.
//


import SwiftUI
import Charts

struct MinMaxEodChartWidget: View {
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Local(\.threshold) var threshold

    @AppStorage(LocalKeys.Charts.Options.showOverviewDataPerMethodOnUnified) var showOverviewDataPerMethodOnUnifiedChart = false
    @Environment(\.colorScheme) var colorScheme
    
    @Bindable var vm: PayMethodViewModel
    @Bindable var payMethod: CBPaymentMethod
    @State private var showChartSheet = false
    
    @State private var rawSelectedDate: Date?
    @State private var persistedDate: Date?
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
        Section {
            
            NavigationLink {
                detailsSheet
                    .onDisappear {
                        rawSelectedDate = nil
                        persistedDate = nil
                    }
            } label: {
                MinMaxEodChart(vm: vm, payMethod: payMethod, rawSelectedDate: $rawSelectedDate, persistedDate: persistedDate, allowSelection: false, showChartSheet: $showChartSheet)
            }
            .navigationLinkIndicatorVisibility(.hidden)
            
            
//            MinMaxEodChart(vm: vm, payMethod: payMethod, rawSelectedDate: $rawSelectedDate, persistedDate: persistedDate, allowSelection: false, showChartSheet: $showChartSheet)
//                .sheet(isPresented: $showChartSheet, onDismiss: {
//                    rawSelectedDate = nil
//                    persistedDate = nil
//                }) {
//                    detailsSheet
//                }
        } header: {
            Text("Min/Max EOD Amounts")
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            if newValue != nil {
                self.persistedDate = newValue
            }
        }
    }
    
    
    var detailsSheet: some View {
        //NavigationStack {
            StandardContainerWithToolbar(.list) {
                Section("Details \(persistedDate == nil ? "" : vm.overViewTitle(for: persistedDate))") {
                    selectedDataView
                }
                                
                PaymentMethodChartDetailsSectionContainer(vm: vm, payMethod: payMethod) {
                    MinMaxEodChart(vm: vm, payMethod: payMethod, rawSelectedDate: $rawSelectedDate, persistedDate: persistedDate, allowSelection: true, showChartSheet: $showChartSheet)
                }
            }
            .navigationTitle("Min/Max EOD Amounts")
            .navigationSubtitle(payMethod.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { PaymentMethodChartStyleMenu(vm: vm) }
                //ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
        //}
    }
    
    var closeButton: some View {
        Button {
            showChartSheet = false
        } label: {
            Image(systemName: "xmark")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }
    
    @ViewBuilder
    var selectedDataView: some View {
        if let persistedDate = persistedDate {
            ChartSelectedDataContainer(
                vm: vm,
                payMethod: payMethod,
                columnCount: (payMethod.isCreditOrLoan || payMethod.isUnifiedCredit) ? 5 : 4,
                showOverviewDataPerMethodOnUnifiedChart: showOverviewDataPerMethodOnUnifiedChart
            ) {
                Text("Account")
                Text("Min EOD")
                Text("Max EOD")
            } rows: {
                ForEach(vm.breakdownPerMethod(on: persistedDate)) { info in
                    GridRow(alignment: .top) {
                        HStack(spacing: 5) {
                            CircleDot(color: info.color, width: 5)
                            Text(info.title)
                        }
                        
                        Text(info.minEod.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                            .foregroundStyle(info.minEod < threshold ? .orange : .secondary)
                        
                        Text(info.maxEod.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                            .foregroundStyle(info.maxEod < threshold ? .orange : .secondary)
                    }
                }
            } summary: {
                let breakdown = vm.breakdownForMethod(method: vm.mainPayMethod, on: persistedDate)
                Text(breakdown.minEod.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                    .foregroundStyle(breakdown.minEod < threshold ? .orange : .secondary)
                
                Text(breakdown.maxEod.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                    .foregroundStyle(breakdown.maxEod < threshold ? .orange : .secondary)
            }
        } else {
            Text("Drag across the chart to see details")
                .foregroundStyle(.gray)
        }
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
    
    @Binding var rawSelectedDate: Date?
    var persistedDate: Date?
    var allowSelection: Bool
    @Binding var showChartSheet: Bool
        
    var body: some View {
        VStack(spacing: 0) {
            ChartLegendView(items: [
                (id: UUID(), title: "Above Threshold", color: Color.green),
                (id: UUID(), title: "Under Threshold", color: Color.orange),
            ])
            
            Chart {
                if let persistedDate {
                    vm.selectionRectangle(for: persistedDate, color: .clear)
                }
                
                ForEach(vm.relevantBreakdowns()) {
                    minMaxLine($0)
                }
            }
            .frame(minHeight: 150)
            .chartYAxis { vm.yAxis() }
            .chartXAxis { vm.xAxis() }
            .if(allowSelection) {
                $0
                .chartXScale(domain: vm.chartXScale)
                .chartXSelection(value: $rawSelectedDate)
            }
        }
        .sensoryFeedback(.selection, trigger: persistedDate) { $0 != nil && $1 != nil }
//        .if(!allowSelection) {
//            $0.onTapGesture {
//                showChartSheet = true
//            }
//        }
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
            if let persistedDate {
                breakdown.date == persistedDate ? 1 : 0.3
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
}
