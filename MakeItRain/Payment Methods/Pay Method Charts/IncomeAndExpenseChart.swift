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
                
    var body: some View {
        NavigationLink {
            IncomeAndExpenseChartDetails(vm: vm, payMethod: payMethod)
        } label: {
            IncomeExpenseChart(
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



struct IncomeAndExpenseChartDetails: View {
    
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
                IncomeExpenseChart(
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
        .navigationTitle("Transactions")
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
            
            var startingText: String {
                vm.viewByQuarter ? (payMethod.isCreditOrUnified ? "Starting (avg)" : "Starting (sum)") : "Starting"
            }
            
            ChartSelectedDataContainer(
                vm: vm,
                payMethod: payMethod,
                columnCount: (payMethod.isCreditOrLoan || payMethod.isUnifiedCredit) ? 5 : 4
            ) {
                Text("Account")
                Text("Income")
                Text("Expenses")
                Text(startingText)
                if payMethod.isCreditOrUnified {
                    Text("Payments")
                }
            } rows: {
                ForEach(vm.breakdownPerMethod(on: selectedDate)) { breakdown in
                    GridRow {
                        HStack(spacing: 5) {
                            CircleDot(color: breakdown.color, width: 5)
                            Text(breakdown.title)
                        }
                        
                        Text(vm.getIncomeText(for: breakdown).currencyWithDecimals())
                        Text(breakdown.expenses.currencyWithDecimals())
                        Text(breakdown.startingAmounts.currencyWithDecimals())
                        
                        if payMethod.isCreditOrUnified {
                            Text(breakdown.payments.currencyWithDecimals())
                        }
                    }
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(.secondary)
                }
            } summary: {
                let breakdown = vm.breakdownForMethod(method: vm.mainPayMethod, on: selectedDate)
                Text(vm.getIncomeText(for: breakdown).currencyWithDecimals())
                Text(breakdown.expenses.currencyWithDecimals())
                Text(breakdown.startingAmounts.currencyWithDecimals())
                                            
                if payMethod.isCreditOrUnified {
                    Text(breakdown.payments.currencyWithDecimals())
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
    @AppStorage(LocalKeys.Charts.Options.showOverviewDataPerMethodOnUnified) var showOverviewDataPerMethodOnUnifiedChart = false
    @AppStorage(LocalKeys.Charts.IncomeExpense.showExpenses) var showExpenses: Bool = true
    @AppStorage(LocalKeys.Charts.IncomeExpense.showIncome) var showIncome: Bool = true
    @AppStorage(LocalKeys.Charts.IncomeExpense.showStartingAmount) var showStartingAmount: Bool = true
    @AppStorage(LocalKeys.Charts.IncomeExpense.showPayments) var showPayments: Bool = true
    
    @Bindable var vm: PayMethodViewModel
    @Bindable var payMethod: CBPaymentMethod
    @Binding var rawSelectedDate: Date?
    
    var selectedDate: Date?
    var allowSelection: Bool
    var animateImmediately: Bool
    
    @State private var legendItems: [(id: UUID, title: String, color: Color)] = []
    
    var body: some View {
        VStack(spacing: 0) {
            if !allowSelection {
                ChartLegendView(items: legendItems)
            }
            
            chart(showLines: true)
                //.animatedLineChart(beginAnimation: animateImmediately ? true : !vm.isLoadingHistory) { chart(showLines: $0) }
            
        }
        .sensoryFeedback(.selection, trigger: selectedDate) { $0 != nil && $1 != nil }
        .onChange(of: vm.incomeType, initial: true, configureLegend)
    }
    
    
    @ViewBuilder func chart(showLines: Bool) -> some View {
        Chart {
            if let selectedDate {
                vm.selectionRectangle(for: selectedDate, color: Color.secondary)
            }
            
            ForEach(vm.relevantBreakdowns()) {
                if showIncome { incomeLine($0, showLines: showLines) }
                if showExpenses { expensesLine($0, showLines: showLines) }
                if showStartingAmount { startingAmountLine($0, showLines: showLines) }
                if payMethod.isCreditOrUnified && showPayments { paymentLine($0, showLines: showLines) }
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
    
            
    @ChartContentBuilder
    func incomeLine(_ breakdown: PayMethodMonthlyBreakdown, showLines: Bool) -> some ChartContent {
        LineMark(
            x: .value("Date", breakdown.date, unit: .month),
            y: .value("Amount1", vm.getIncomeText(for: breakdown)),
            series: .value("", "Amount1\(payMethod.id)")
        )
        .foregroundStyle(.blue.gradient)
        .interpolationMethod(.catmullRom)
        .opacity(showLines ? 1 : 0)
    }
        
    @ChartContentBuilder
    func expensesLine(_ breakdown: PayMethodMonthlyBreakdown, showLines: Bool) -> some ChartContent {
        LineMark(
            x: .value("Date", breakdown.date, unit: .month),
            y: .value("Amount2", breakdown.expenses),
            series: .value("", "Amount2\(payMethod.id)")
        )
        .foregroundStyle(.red.gradient)
        .interpolationMethod(.catmullRom)
        .opacity(showLines ? 1 : 0)
    }
    
    @ChartContentBuilder
    func startingAmountLine(_ breakdown: PayMethodMonthlyBreakdown, showLines: Bool) -> some ChartContent {
        LineMark(
            x: .value("Date", breakdown.date, unit: .month),
            y: .value("Amount4", breakdown.startingAmounts),
            series: .value("", "Amount4\(payMethod.id)")
        )
        .foregroundStyle(.orange.gradient)
        .interpolationMethod(.catmullRom)
        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
        .opacity(showLines ? 1 : 0)
    }
    
    @ChartContentBuilder
    func paymentLine(_ breakdown: PayMethodMonthlyBreakdown, showLines: Bool) -> some ChartContent {
        LineMark(
            x: .value("Date", breakdown.date, unit: .month),
            y: .value("Amount3", breakdown.payments),
            series: .value("", "Amount3\(payMethod.id)")
        )
        .foregroundStyle(.green.gradient)
        .interpolationMethod(.catmullRom)
        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
        .opacity(showLines ? 1 : 0)
    }
  
    func configureLegend() {
        legendItems = [
            (id: UUID(), title: "Expenses", color: Color.red),
            (id: UUID(), title: "Month Begin", color: Color.orange),
        ]
        
        if payMethod.isCreditOrUnified {
            legendItems.append((id: UUID(), title: "Payments", color: Color.green))
        }
        
        legendItems.append((id: UUID(), title: vm.incomeType.prettyValue, color: Color.blue))
    }
}



fileprivate struct ChartOptionsSheet: View {
    //@Local(\.colorTheme) var colorTheme

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
            ChartOptionToggle(description: expenseDescription, title: Text("Expenses"), color: .red, show: $showExpenses)
            ChartOptionToggle(description: startingAmountDescription, title: Text("Month Begin"), color: .orange, show: $showStartingAmount)
            
            if payMethod.isCreditOrUnified {
                ChartOptionToggle(description: paymentDescription, title: Text("Payments"), color: .green, show: $showPayments)
            }
            
            ChartOptionToggle(description: incomeDescription, title: ChartIncomeOptionMenu(vm: vm), color: .blue, show: $showIncome)
       // }
    }
}
