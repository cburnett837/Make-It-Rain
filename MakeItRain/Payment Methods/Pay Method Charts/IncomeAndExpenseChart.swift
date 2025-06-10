//
//  IncomeAndExpenseChart.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/30/25.
//

import SwiftUI
import Charts

struct IncomeExpenseChartWidget: View {
    @Bindable var vm: PayMethodViewModel
    @Bindable var payMethod: CBPaymentMethod
    @State private var showOptions = false
        
    var body: some View {
        VStack(alignment: .leading) {
            WidgetLabelButton(title: "All Expenses/Income") {
                showOptions.toggle()
            }
            
            IncomeExpenseChart(vm: vm, payMethod: payMethod, showOptions: $showOptions, detailStyle: .overlay)
                .padding()
                .widgetShape()
        }
        .padding(.bottom, 30)
    }
}



struct IncomeExpenseChart: View {
    @Environment(\.dismiss) var dismiss
    @Local(\.incomeColor) var incomeColor
    @Local(\.useWholeNumbers) var useWholeNumbers
    //@Local(\.showOverviewDataPerMethodOnUnifiedChart) var showOverviewDataPerMethodOnUnifiedChart
    @AppStorage(LocalKeys.Charts.Options.showOverviewDataPerMethodOnUnified) var showOverviewDataPerMethodOnUnifiedChart = false

    
    @AppStorage(LocalKeys.Charts.IncomeExpense.showExpenses) var showExpenses: Bool = true
    @AppStorage(LocalKeys.Charts.IncomeExpense.showIncome) var showIncome: Bool = true
    @AppStorage(LocalKeys.Charts.IncomeExpense.showStartingAmount) var showStartingAmount: Bool = true
    @AppStorage(LocalKeys.Charts.IncomeExpense.showPayments) var showPayments: Bool = true
    
    //@Local(\.incomeAndExpenseChartShowExpenses) var showExpenses
    //@Local(\.incomeAndExpenseChartShowIncome) var showIncome
    //@Local(\.incomeAndExpenseChartShowStartingAmount) var showStartingAmount
    //@Local(\.incomeAndExpenseChartShowPayments) var showPayments
    
    @Bindable var vm: PayMethodViewModel
    @Bindable var payMethod: CBPaymentMethod
    @Binding var showOptions: Bool
    var detailStyle: DetailStyle
    
    @State private var chartWidth: CGFloat = 0
    @State private var legendItems: [(id: UUID, title: String, color: Color)] = []
    @State private var showDetailsSheet = false
    
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
        VStack(spacing: 0) {
            if detailStyle == .inline {
                selectedDataView
            }
            
            ChartLegendView(items: legendItems)
            Chart {
                if let selectedDate {
                    if detailStyle == .overlay {
                        vm.selectionRectangle(for: selectedDate, content: selectedDataView)
                    } else {
                        vm.selectionRectangle(for: selectedDate, content: EmptyView())
                    }
                }
                
                ForEach(vm.relevantBreakdowns()) {
                    if showIncome { incomeLine($0) }
                    if showExpenses { expensesLine($0) }
                    if showStartingAmount { startingAmountLine($0) }
                    if payMethod.isCredit && showPayments { paymentLine($0) }
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
        .onChange(of: vm.incomeType, initial: true, configureLegend)
        .sheet(isPresented: $showOptions) {
            ChartOptionsSheet(vm: vm, payMethod: payMethod, showOptions: $showOptions)
        }
    }
            
    @ChartContentBuilder
    func incomeLine(_ breakdown: PayMethodMonthlyBreakdown) -> some ChartContent {
        LineMark(
            x: .value("Date", breakdown.date, unit: .month),
            y: .value("Amount1", vm.getIncomeText(for: breakdown)),
            series: .value("", "Amount1\(payMethod.id)")
        )
        .foregroundStyle(.blue.gradient)
        .interpolationMethod(.catmullRom)
    }
        
    @ChartContentBuilder
    func expensesLine(_ breakdown: PayMethodMonthlyBreakdown) -> some ChartContent {
        LineMark(
            x: .value("Date", breakdown.date, unit: .month),
            y: .value("Amount2", breakdown.expenses),
            series: .value("", "Amount2\(payMethod.id)")
        )
        .foregroundStyle(.red.gradient)
        .interpolationMethod(.catmullRom)
    }
    
    @ChartContentBuilder
    func startingAmountLine(_ breakdown: PayMethodMonthlyBreakdown) -> some ChartContent {
        LineMark(
            x: .value("Date", breakdown.date, unit: .month),
            y: .value("Amount4", breakdown.startingAmounts),
            series: .value("", "Amount4\(payMethod.id)")
        )
        .foregroundStyle(.orange.gradient)
        .interpolationMethod(.catmullRom)
        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
    }
    
    @ChartContentBuilder
    func paymentLine(_ breakdown: PayMethodMonthlyBreakdown) -> some ChartContent {
        LineMark(
            x: .value("Date", breakdown.date, unit: .month),
            y: .value("Amount3", breakdown.payments),
            series: .value("", "Amount3\(payMethod.id)")
        )
        .foregroundStyle(.green.gradient)
        .interpolationMethod(.catmullRom)
        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
    }
            
    @ViewBuilder
    var selectedDataView: some View {
        if let selectedDate = selectedDate {
            
            var startingText: String {
                vm.viewByQuarter ? (payMethod.isCredit ? "Starting (avg)" : "Starting (sum)") : "Starting"
            }
            
            ChartSelectedDataContainer(
                vm: vm,
                payMethod: payMethod,
                selectedDate: selectedDate,
                chartWidth: chartWidth,
                showOverviewDataPerMethodOnUnifiedChart: showOverviewDataPerMethodOnUnifiedChart
            ) {
                if showOverviewDataPerMethodOnUnifiedChart { Text("Method") }
                Text("Income").foregroundStyle(.blue.gradient)
                Text("Expenses").foregroundStyle(.red.gradient)
                Text(startingText).foregroundStyle(.orange.gradient)
                if payMethod.isCredit {
                    Text("Payments").foregroundStyle(.green.gradient)
                }
            } rows: {
                if showOverviewDataPerMethodOnUnifiedChart {
                    ForEach(vm.breakdownPerMethod(on: selectedDate)) { breakdown in
                        GridRow(alignment: .top) {
                            HStack(spacing: 0) {
                                CircleDot(color: breakdown.color)
                                Text(breakdown.title)
                            }
                            
                            Text(vm.getIncomeText(for: breakdown).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                            Text(breakdown.expenses.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                            Text(breakdown.startingAmounts.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                            
                            if payMethod.isCredit {
                                Text(breakdown.payments.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                            }
                        }
                    }
                } else {
                    EmptyView()
                }
                
            } summary: {
                let breakdown = vm.breakdownForMethod(method: vm.mainPayMethod, on: selectedDate)
                Text(vm.getIncomeText(for: breakdown).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                Text(breakdown.expenses.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                Text(breakdown.startingAmounts.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                                            
                if payMethod.isCredit {
                    Text(breakdown.payments.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                }
            }
        }
    }
  
    
    func configureLegend() {
        legendItems = [
            (id: UUID(), title: "Expenses", color: Color.red),
            (id: UUID(), title: "Month Begin", color: Color.orange),
        ]
        
        if payMethod.isCredit {
            legendItems.append((id: UUID(), title: "Payments", color: Color.green))
        }
        
        legendItems.append((id: UUID(), title: vm.incomeType.prettyValue, color: Color.blue))
    }
}



fileprivate struct ChartOptionsSheet: View {
    @AppStorage(LocalKeys.Charts.IncomeExpense.showExpenses) var showExpenses: Bool = true
    @AppStorage(LocalKeys.Charts.IncomeExpense.showIncome) var showIncome: Bool = true
    @AppStorage(LocalKeys.Charts.IncomeExpense.showStartingAmount) var showStartingAmount: Bool = true
    @AppStorage(LocalKeys.Charts.IncomeExpense.showPayments) var showPayments: Bool = true
    
    @Bindable var vm: PayMethodViewModel
    @Bindable var payMethod: CBPaymentMethod
    @Binding var showOptions: Bool
    
    let expenseDescription: LocalizedStringKey = "Sum of all negative dollar amounts. (Expenses, Withdrawals, Etc.)"
    
    let incomeDescription: LocalizedStringKey = "**Income only:**\nThe sum of amounts where transactions have an ***income*** category.\n\n**Money in only (no income):**\nThe sum of positive dollar amounts ***excluding*** transactions that have an income category.\n(Deposits, Refunds, Etc.)\n\n**All money in:**\nThe sum of ***all*** positive dollar amounts.\n(Income, Deposits, Refunds, Etc.)\n\n**Starting amount & all money in:**\nThat sum of all positive dollar amounts + the amount you started the month with."
    
    let startingAmountDescription: LocalizedStringKey = "Your balance at the beginning of the month."
    
    let paymentDescription: LocalizedStringKey = "Any payments made."
    
    
    var body: some View {
        LittleBottomSheetContainer {
            ChartOptionToggle(description: expenseDescription, title: Text("Show Expenses"), color: .red, show: $showExpenses)
            ChartOptionToggle(description: startingAmountDescription, title: Text("Show Month Begin"), color: .orange, show: $showStartingAmount)
            
            if payMethod.isCredit {
                ChartOptionToggle(description: paymentDescription, title: Text("Show Payments"), color: .green, show: $showPayments)
            }
            
            ChartOptionToggle(description: incomeDescription, title: ChartIncomeOptionMenu(vm: vm), color: .blue, show: $showIncome)
            
        } header: {
            SheetHeader(title: "Options", close: { showOptions = false })
        }
    }
}
