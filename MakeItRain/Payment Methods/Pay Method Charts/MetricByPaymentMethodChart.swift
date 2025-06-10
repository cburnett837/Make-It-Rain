//
//  ExpensesByPaymentMethodChart.swift
//  MakeItRain
//
//  Created by Cody Burnett on 6/2/25.
//


import SwiftUI
import Charts


@Observable
class MetricByPaymentMethodChartModel: NSObject {
    public var metric: MetricByPaymentMethodType {
        get { MetricByPaymentMethodType.fromString(
            appStorageGetter(\.metric.rawValue, key: "\(MetricByPaymentMethodChartModel.className)_metric", default: MetricByPaymentMethodType.expenses.rawValue)) }
        set { appStorageSetter(\.metric.rawValue, key: "\(MetricByPaymentMethodChartModel.className)_metric", new: newValue.rawValue) }
    }
    
    private func appStorageGetter<T: Decodable>(_ keyPath: KeyPath<MetricByPaymentMethodChartModel, T>, key: String, default defaultValue: T) -> T {
        access(keyPath: keyPath)
        if let data = UserDefaults.standard.data(forKey: key) {
            return try! JSONDecoder().decode(T.self, from: data)
        } else {
            return defaultValue
        }
    }
    
    private func appStorageSetter<T: Encodable>(_ keyPath: KeyPath<MetricByPaymentMethodChartModel, T>, key: String, new: T) {
        withMutation(keyPath: keyPath) {
            let data = try? JSONEncoder().encode(new)
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}


struct MetricByPaymentMethodChartWidget: View {
    @Bindable var vm: PayMethodViewModel
    @Bindable var payMethod: CBPaymentMethod
    @State private var showOptions = false
    
    @State private var model = MetricByPaymentMethodChartModel()
    
    var body: some View {
        VStack(alignment: .leading) {
            WidgetLabelButton(title: "\(model.metric.prettyValue) By Payment Method") {
                showOptions.toggle()
            }
            
            MetricByPaymentMethodChart(vm: vm, model: model, payMethod: payMethod, showOptions: $showOptions, detailStyle: .overlay)
                .padding()
                .widgetShape()
        }
        .padding(.bottom, 30)
    }
}


struct MetricByPaymentMethodChart: View {
    @Local(\.useWholeNumbers) var useWholeNumbers
    //@ChartOption(\.showOverviewDataPerMethodOnUnifiedChart) var showOverviewDataPerMethodOnUnifiedChart
    @AppStorage(LocalKeys.Charts.Options.showOverviewDataPerMethodOnUnified) var showOverviewDataPerMethodOnUnifiedChart = false


    @Bindable var vm: PayMethodViewModel
    @Bindable var model: MetricByPaymentMethodChartModel
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
            ChartLegendView(items: vm.payMethods.map { (id: UUID(), title: $0.title, color: $0.color) })
            
            Chart {
                if let selectedDate {
                    vm.selectionRectangle(for: selectedDate, content: selectedDataView)
                }
                
                ForEach(vm.payMethods) { meth in
                    
                    ForEach(vm.relevantBreakdowns(for: meth)) {
                        switch model.metric {
                        case .expenses:
                            expensesLine(meth: meth, breakdown: $0)
                        case .income:
                            incomeLine(meth: meth, breakdown: $0)
                        case .startingAmounts:
                            startingAmountLine(meth: meth, breakdown: $0)
                        case .payments:
                            paymentLine(meth: meth, breakdown: $0)
                        }
                    }
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
        .sheet(isPresented: $showOptions) {
            ChartOptionsSheet(vm: vm, model: model, payMethod: payMethod, showOptions: $showOptions)
        }
    }
    
    @ChartContentBuilder
    func incomeLine(meth: CBPaymentMethod, breakdown: PayMethodMonthlyBreakdown) -> some ChartContent {
        LineMark(
            x: .value("Date", breakdown.date, unit: .month),
            y: .value("Amount1", vm.getIncomeText(for: breakdown)),
            series: .value("", "Amount1\(meth.id)")
        )
        .foregroundStyle(meth.color)
        .interpolationMethod(.catmullRom)
    }
            
    @ChartContentBuilder
    func expensesLine(meth: CBPaymentMethod, breakdown: PayMethodMonthlyBreakdown) -> some ChartContent {
        LineMark(
            x: .value("Date", breakdown.date, unit: .month),
            y: .value("Amount2", breakdown.expenses),
            series: .value("", "Amount2\(meth.id)")
        )
        .foregroundStyle(meth.color)
        .interpolationMethod(.catmullRom)
    }
    
    @ChartContentBuilder
    func startingAmountLine(meth: CBPaymentMethod, breakdown: PayMethodMonthlyBreakdown) -> some ChartContent {
        LineMark(
            x: .value("Date", breakdown.date, unit: .month),
            y: .value("Amount4", breakdown.startingAmounts),
            series: .value("", "Amount4\(meth.id)")
        )
        .foregroundStyle(meth.color)
        .interpolationMethod(.catmullRom)
    }
    
    @ChartContentBuilder
    func paymentLine(meth: CBPaymentMethod, breakdown: PayMethodMonthlyBreakdown) -> some ChartContent {
        LineMark(
            x: .value("Date", breakdown.date, unit: .month),
            y: .value("Amount3", breakdown.payments),
            series: .value("", "Amount3\(meth.id)")
        )
        .foregroundStyle(meth.color)
        .interpolationMethod(.catmullRom)
    }
            
    
    
    @ViewBuilder
    var selectedDataView: some View {
        if let selectedDate = selectedDate {
            ChartSelectedDataContainer(vm: vm, payMethod: payMethod, selectedDate: selectedDate, chartWidth: chartWidth, showOverviewDataPerMethodOnUnifiedChart: true) {
                Text("Method")
                Text(model.metric.prettyValue)
            } rows: {
                ForEach(vm.breakdownPerMethod(on: selectedDate)) { info in
                    GridRow(alignment: .top) {
                        HStack(spacing: 0) {
                            CircleDot(color: info.color)
                            Text(info.title)
                        }
                        
                        switch model.metric {
                        case .expenses:
                            Text(info.expenses.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                        case .income:
                            Text(info.income.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                        case .startingAmounts:
                            Text(info.startingAmounts.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                        case .payments:
                            Text(info.payments.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                        }
                    }
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(.secondary)
                }
                
            } summary: {
                let breakdown = vm.breakdownForMethod(method: vm.mainPayMethod, on: selectedDate)
                Text(breakdown.expenses.currencyWithDecimals(useWholeNumbers ? 0 : 2))
            }
        }

    }
}


fileprivate struct ChartOptionsSheet: View {
    @Bindable var vm: PayMethodViewModel
    @Bindable var model: MetricByPaymentMethodChartModel
    @Bindable var payMethod: CBPaymentMethod
    @Binding var showOptions: Bool
        
    var body: some View {
        LittleBottomSheetContainer {
            HStack {
                Text("Metric")
                Spacer()
                MetricByPaymentMethodChartMenu(vm: vm, model: model)
            }
        } header: {
            SheetHeader(title: "Options", close: { showOptions = false })
        }
    }
}



fileprivate struct MetricByPaymentMethodChartMenu: View {
    @Local(\.colorTheme) var colorTheme
    @Bindable var vm: PayMethodViewModel
    @Bindable var model: MetricByPaymentMethodChartModel
    
    /// Need this to prevent the button from animating.
    @State private var text = ""
    
    var body: some View {
        VStack(alignment: .trailing) {
            HStack {
                Menu {
                    Button { change(to: .expenses) } label: {
                        menuOptionLabel(title: "Expenses", isChecked: model.metric == .expenses)
                    }
                    Button { change(to: .income) } label: {
                        menuOptionLabel(title: "Income", isChecked: model.metric == .income)
                    }
                    Button { change(to: .startingAmounts) } label: {
                        menuOptionLabel(title: "Starting Amounts", isChecked: model.metric == .startingAmounts)
                    }
                    Button { change(to: .payments) } label: {
                        menuOptionLabel(title: "Payments", isChecked: model.metric == .payments)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(text)
                            .lineLimit(1)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.footnote)
                    }
                    .transaction {
                        $0.disablesAnimations = true
                        $0.animation = nil
                    }
                }
            }
        }
        .onAppear {
            setText(metric: model.metric)
        }
    }
    
    @ViewBuilder func menuOptionLabel(title: String, isChecked: Bool) -> some View {
        HStack {
            Text(title)
            if isChecked {
                Image(systemName: "checkmark")
            }
        }
    }
    
    func change(to option: MetricByPaymentMethodType) {
        setText(metric: option)
        //withAnimation {
            model.metric = option
        //}
    }
    
    func setText(metric: MetricByPaymentMethodType) {
        switch metric {
        case .expenses:
            self.text = MetricByPaymentMethodType.expenses.prettyValue
        case .income:
            self.text = MetricByPaymentMethodType.income.prettyValue
        case .startingAmounts:
            self.text = MetricByPaymentMethodType.startingAmounts.prettyValue
        case .payments:
            self.text = MetricByPaymentMethodType.payments.prettyValue
        }
    }
}
