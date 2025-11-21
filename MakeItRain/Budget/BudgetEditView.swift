//
//  CategoryViewMac.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/21/24.
//

import SwiftUI
import Charts

struct BudgetEditView: View {
    @Local(\.transactionSortMode) var transactionSortMode
    @Local(\.categorySortMode) var categorySortMode
    @Local(\.useWholeNumbers) var useWholeNumbers
    //@Local(\.colorTheme) var colorTheme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) var dismiss
    @Bindable var budget: CBBudget
    @Bindable var calModel: CalendarModel
    
    @Environment(PayMethodModel.self) private var payModel

    
    @State private var showDeleteAlert = false
//    @State private var labelWidth: CGFloat = 20.0
        
    var budgetHeader: String {
        //budget.action == .add ? "New Budget" : "Edit Budget"
        calModel.isPlayground ? "\(calModel.sMonth.name) (Playground)" : "\(calModel.sMonth.name) \(String(calModel.sMonth.year))"
    }
    @State private var cumTotals: [CumTotal] = []

    @FocusState private var focusedField: Int?
    @State private var showKeyboardToolbar = false
    @State private var searchText = ""
    
    @State private var transEditID: String?
    @State private var editTrans: CBTransaction?
    @State private var transDay: CBDay?
    
    @State private var transactions: [CBTransaction] = []

    
    struct CumTotal {
        var day: Int
        var total: Double
    }
    
    var totalExpenses: Double {
        transactions
            .map { ($0.payMethod ?? CBPaymentMethod()).isCreditOrLoan ? $0.amount : $0.amount * -1 }
            .reduce(0.0, +)
    }

    
//    var transactions: Array<CBTransaction> {
//        /// This will look at both the transaction, and its deepCopy.
//        /// The reason being - in case we change a transction category or payment method from what is currently being viewed. This will allow the transaction sheet to remain on screen until we close it, at which point the save function will clear the deepCopy.
//        calModel.sMonth.days.flatMap {
//            $0.transactions.filter { trans in
//                trans.categoryIdsInCurrentAndDeepCopy.contains(budget.category?.id)
//                && !trans.hasHiddenMethodInCurrentOrDeepCopy
//                && !trans.hasPrivateMethodInCurrentOrDeepCopy
//            }
//        }
//        .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
//    }

    var body: some View {
        #if os(iOS)
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                Section("Budget for \(budgetHeader)") {
                    titleRow
                }
                
                Section("Details") {
                    theChart
                }
                                
                transactionList
            }
            .searchable(text: $searchText, prompt: Text("Search"))
            .navigationTitle(budget.category?.title ?? "N/A")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: AppState.shared.isIphone ? .topBarTrailing : .topBarLeading) { closeButton }
            }
        }
        .transactionEditSheetAndLogic(transEditID: $transEditID, selectedDay: $transDay)
        .task {
            budget.deepCopy(.create)
            /// Just for formatting.
            budget.amountString = budget.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
            prepareData()
        }
    
        #endif
    }
    
    
    var theChart: some View {
        Chart {
            BarMark(
                x: .value("Amount", budget.amount),
                y: .value("Key", "Budget \(budget.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
            )
            .foregroundStyle(budget.category?.color ?? .gray)
        
            BarMark(
                x: .value("Amount", totalExpenses),
                y: .value("Key", "Expenses \(totalExpenses.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
            )
            .foregroundStyle(.gray)
        }
        .chartLegend(.hidden)
        .chartXAxis { xAxis() }
    }
    
    @AxisContentBuilder
    func xAxis() -> some AxisContent {
        AxisMarks(values: .automatic) {
            AxisGridLine()
            if let value = $0.as(Int.self) {
                AxisValueLabel {
                    Text("$\(value)")
                }
            }
            
        }
    }
    
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    var titleRow: some View {
        HStack(spacing: 0) {
            Label("", systemImage: "t.circle")
                .foregroundStyle(.gray)
            
            #if os(iOS)
            UITextFieldWrapper(placeholder: "Budget", text: $budget.amountString, toolbar: {
                KeyboardToolbarView(focusedField: $focusedField)
            })
            .uiTag(0)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.left)
            //.uiReturnKeyType(.next)
            //.uiFont(UIFont.systemFont(ofSize: 24.0))
            //.uiTextColor(.secondaryLabel)
            #else
            StandardTextField("Name", text: $budget.amountString, focusedField: $focusedField, focusValue: 0)
                .onSubmit { focusedField = 1 }
            #endif
        }
        .focused($focusedField, equals: 0)
    }
    
    
    var transactionList: some View {
        ForEach(calModel.sMonth.days.filter { $0.date != nil }) { day in
            let doesHaveTransactions = transactions
                .filter { $0.dateComponents?.day == day.date?.day }
                .count > 0
            
            let dailyTotal = transactions
                .filter { $0.dateComponents?.day == day.date?.day }
                .map { ($0.payMethod?.isCreditOrLoan ?? false) ? $0.amount * -1 : $0.amount }
                .reduce(0.0, +)
            
            let dailyCount = transactions
                .filter { $0.dateComponents?.day == day.date?.day }
                .count
                   
            if doesHaveTransactions {
                Section {
                    ForEach(getTransactions(for: day)) { trans in
                        TransactionListLine(trans: trans)
                            .onTapGesture {
                                self.transDay = day
                                self.transEditID = trans.id
                            }
                    }
                } header: {
                    if let date = day.date, date.isToday {
                        HStack {
                            Text("TODAY")
                                .foregroundStyle(Color.theme)
                            VStack {
                                Divider()
                                    .overlay(Color.theme)
                            }
                        }
                    } else {
                        Text(day.date?.string(to: .monthDayShortYear) ?? "")
                    }
                    
                } footer: {
                    if doesHaveTransactions {
                        SectionFooter(day: day, dailyCount: dailyCount, dailyTotal: dailyTotal, cumTotals: cumTotals)
                    }
                }
            }
        }
    }
    
  
    func getTransactions(for day: CBDay) -> Array<CBTransaction> {
        transactions
            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
            .filter { $0.dateComponents?.day == day.date?.day }
            .sorted(by: Helpers.transactionSorter())
    }
    
//    func getTransactionsOG(for day: CBDay) -> Array<CBTransaction> {
//        transactions
//            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
//            .filter { $0.dateComponents?.day == day.date?.day }
//            .filter { ($0.payMethod?.isPermitted ?? true) }
//            .filter { !($0.payMethod?.isHidden ?? false) }
//            .sorted {
//                if transactionSortMode == .title {
//                    return $0.title < $1.title
//                    
//                } else if transactionSortMode == .enteredDate {
//                    return $0.enteredDate < $1.enteredDate
//                    
//                } else {
//                    if categorySortMode == .title {
//                        return ($0.category?.title ?? "").lowercased() < ($1.category?.title ?? "").lowercased()
//                    } else {
//                        return $0.category?.listOrder ?? 10000000000 < $1.category?.listOrder ?? 10000000000
//                    }
//                }
//            }
//    }
    
    
    
    func prepareData() {
        if let cat = budget.category {
            transactions = calModel.getTransactions(cats: [cat])
                .filter { $0.dateComponents?.month == calModel.sMonth.actualNum }
                .filter { $0.dateComponents?.year == calModel.sMonth.year }
            
            //        transactions = calModel.justTransactions
            //            .filter { calModel.isInMultiSelectMode ? calModel.multiSelectTransactions.map({ $0.id }).contains($0.id) : true }
            //            //.filter { $0.payMethod?.id == calModel.sPayMethod?.id }
            ////            .filter { trans in
            ////                if let sMethod = calModel.sPayMethod {
            ////                    if sMethod.isUnifiedDebit {
            ////                        let methods: Array<String> = payModel.paymentMethods
            ////                            .filter { $0.isPermitted }
            ////                            .filter { !$0.isHidden }
            ////                            .filter { $0.isDebit }
            ////                            .map { $0.id }
            ////                        return methods.contains(trans.payMethod?.id ?? "")
            ////
            ////                    } else if sMethod.isUnifiedCredit {
            ////                        let methods: Array<String> = payModel.paymentMethods
            ////                            .filter { $0.isPermitted }
            ////                            .filter { !$0.isHidden }
            ////                            .filter { $0.isCredit }
            ////                            .map { $0.id }
            ////                        return methods.contains(trans.payMethod?.id ?? "")
            ////
            ////                    } else {
            ////                        return trans.payMethod?.id == sMethod.id && (trans.payMethod?.isPermitted ?? true) && !(trans.payMethod?.isHidden ?? false)
            ////                    }
            ////                } else {
            ////                    return false
            ////                }
            ////            }
            //            .filter { $0.dateComponents?.month == calModel.sMonth.actualNum }
            //            .filter { $0.dateComponents?.year == calModel.sMonth.year }
            //            .filter {
            //                $0.categoryIdsInCurrentAndDeepCopy.contains(budget.category?.id)
            //                && $0.payMethod?.isPermitted ?? true
            //                && !$0.hasHiddenMethodInCurrentOrDeepCopy
            //                //&& !$0.hasPrivateMethodInCurrentOrDeepCopy
            //            }
            //            .sorted { $0.dateComponents?.day ?? 0 < $1.dateComponents?.day ?? 0 }
            
            
            /// Get how much has been spend up until each day.
            self.cumTotals.removeAll()
            var total: Double = 0.0
            
            calModel.sMonth.days.forEach { day in
                let trans = transactions.filter { $0.dateComponents?.day == day.date?.day }
                if !trans.isEmpty {
                    let dailySpend = calModel.getSpend(from: trans)
                    let dailyIncome = calModel.getIncome(from: trans)
                    
                    total += (dailySpend + dailyIncome)
                    self.cumTotals.append(CumTotal(day: day.date!.day, total: total))
                }
            }
        }
    }
    
    
    struct SectionFooter: View {
        @Local(\.useWholeNumbers) var useWholeNumbers
        var day: CBDay
        var dailyCount: Int
        var dailyTotal: Double
        var cumTotals: [CumTotal]
                
        var body: some View {
            HStack {
                Text("Cumulative Total: \((cumTotals.filter { $0.day == day.date!.day }.first?.total ?? 0.0).currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                
                Spacer()
                if dailyCount > 1 {
                    Text(dailyTotal.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                }
            }
        }
    }
}
