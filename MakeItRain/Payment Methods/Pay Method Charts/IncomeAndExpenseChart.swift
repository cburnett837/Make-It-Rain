//
//  IncomeAndExpenseChart.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/30/25.
//

import SwiftUI
import Charts

struct IncomeExpenseChartWidget: View {
    @Local(\.useWholeNumbers) var useWholeNumbers
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
    
    @State private var navPath = NavigationPath()
                
    var body: some View {
        Section {
            NavigationLink {
                detailsSheet
                    .onDisappear {
                        rawSelectedDate = nil
                        persistedDate = nil
                    }
            } label: {
                IncomeExpenseChart(vm: vm, payMethod: payMethod, rawSelectedDate: $rawSelectedDate, persistedDate: persistedDate, allowSelection: false, showChartSheet: $showChartSheet)
            }
            .navigationLinkIndicatorVisibility(.hidden)

            
//            IncomeExpenseChart(vm: vm, payMethod: payMethod, rawSelectedDate: $rawSelectedDate, persistedDate: persistedDate, allowSelection: false, showChartSheet: $showChartSheet)
//                .sheet(isPresented: $showChartSheet, onDismiss: {
//                    rawSelectedDate = nil
//                    persistedDate = nil
//                }) {
//                    detailsSheet
//                }
        } header: {
            Text("All Expenses/Income")
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
                    IncomeExpenseChart(vm: vm, payMethod: payMethod, rawSelectedDate: $rawSelectedDate, persistedDate: persistedDate, allowSelection: true, showChartSheet: $showChartSheet)
                }
                
                Section {
                    ChartOptionsSheet(vm: vm, payMethod: payMethod)
                }
            }
            .navigationTitle("All Expenses/Income")
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
            
            var startingText: String {
                vm.viewByQuarter ? (payMethod.isCredit ? "Starting (avg)" : "Starting (sum)") : "Starting"
            }
            
            ChartSelectedDataContainer(
                vm: vm,
                payMethod: payMethod,
                columnCount: (payMethod.isCreditOrLoan || payMethod.isUnifiedCredit) ? 5 : 4,
                showOverviewDataPerMethodOnUnifiedChart: showOverviewDataPerMethodOnUnifiedChart
            ) {
                Text("Account")
                Text("Income")
                Text("Expenses")
                Text(startingText)
                if payMethod.isCredit {
                    Text("Payments")
                }
            } rows: {
                ForEach(vm.breakdownPerMethod(on: persistedDate)) { breakdown in
                    GridRow {
                        HStack(spacing: 5) {
                            CircleDot(color: breakdown.color, width: 5)
                            Text(breakdown.title)
                        }
                        
                        Text(vm.getIncomeText(for: breakdown).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                        Text(breakdown.expenses.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                        Text(breakdown.startingAmounts.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                        
                        if payMethod.isCredit {
                            Text(breakdown.payments.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                        }
                    }
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(.secondary)
                }
            } summary: {
                let breakdown = vm.breakdownForMethod(method: vm.mainPayMethod, on: persistedDate)
                Text(vm.getIncomeText(for: breakdown).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                Text(breakdown.expenses.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                Text(breakdown.startingAmounts.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                                            
                if payMethod.isCredit {
                    Text(breakdown.payments.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                }
            }
        } else {
            Text("Drag across the chart to see details")
                .foregroundStyle(.gray)
        }
    }
}


struct IncomeExpenseChart: View {
    @Environment(\.dismiss) var dismiss
    @Local(\.incomeColor) var incomeColor
    @Local(\.colorTheme) var colorTheme
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
    
    @State private var legendItems: [(id: UUID, title: String, color: Color)] = []
    @Binding var rawSelectedDate: Date?
    var persistedDate: Date?
    var allowSelection: Bool
    @Binding var showChartSheet: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if !allowSelection {
                ChartLegendView(items: legendItems)
            }
            
            Chart {
                if let persistedDate {
                    vm.selectionRectangle(for: persistedDate, color: Color.fromName(colorTheme))
                }
                
                ForEach(vm.relevantBreakdowns()) {
                    if showIncome { incomeLine($0) }
                    if showExpenses { expensesLine($0) }
                    if showStartingAmount { startingAmountLine($0) }
                    if payMethod.isCredit && showPayments { paymentLine($0) }
                }
            }
            //.frame(minHeight: allowSelection ? 250 : 150)
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
        .onChange(of: vm.incomeType, initial: true, configureLegend)
//        .if(!allowSelection) {
//            $0.onTapGesture {
//                showChartSheet = true
//            }
//        }
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
    @Local(\.colorTheme) var colorTheme

    @AppStorage(LocalKeys.Charts.IncomeExpense.showExpenses) var showExpenses: Bool = true
    @AppStorage(LocalKeys.Charts.IncomeExpense.showIncome) var showIncome: Bool = true
    @AppStorage(LocalKeys.Charts.IncomeExpense.showStartingAmount) var showStartingAmount: Bool = true
    @AppStorage(LocalKeys.Charts.IncomeExpense.showPayments) var showPayments: Bool = true
    
    @Bindable var vm: PayMethodViewModel
    @Bindable var payMethod: CBPaymentMethod
    
    let expenseDescription: LocalizedStringKey = "Sum of all negative dollar amounts. (Expenses, Withdrawals, Etc.)"
    let incomeDescription: LocalizedStringKey = "**Income only:**\nThe sum of amounts where transactions have an ***income*** category.\n\n**Money in only (no income):**\nThe sum of positive dollar amounts ***excluding*** transactions that have an income category.\n(Deposits, Refunds, Etc.)\n\n**All money in:**\nThe sum of ***all*** positive dollar amounts.\n(Income, Deposits, Refunds, Etc.)\n\n**Starting amount & all money in:**\nThat sum of all positive dollar amounts + the amount you started the month with."
    let startingAmountDescription: LocalizedStringKey = "Your balance at the beginning of the month."
    let paymentDescription: LocalizedStringKey = "Any payments made."
    
    var body: some View {
        //VStack(spacing: 20) {
            ChartOptionToggle(description: expenseDescription, title: Text("Show Expenses"), color: .red, show: $showExpenses)
            ChartOptionToggle(description: startingAmountDescription, title: Text("Show Month Begin"), color: .orange, show: $showStartingAmount)
            
            if payMethod.isCredit {
                ChartOptionToggle(description: paymentDescription, title: Text("Show Payments"), color: .green, show: $showPayments)
            }
            
            ChartOptionToggle(description: incomeDescription, title: ChartIncomeOptionMenu(vm: vm), color: .blue, show: $showIncome)
       // }
    }
}
