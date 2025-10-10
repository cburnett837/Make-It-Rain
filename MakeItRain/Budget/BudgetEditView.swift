//
//  CategoryViewMac.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/21/24.
//

import SwiftUI

struct BudgetEditView: View {
    @AppStorage("transactionSortMode") var transactionSortMode: TransactionSortMode = .title
    @AppStorage("categorySortMode") var categorySortMode: CategorySortMode = .title
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Local(\.colorTheme) var colorTheme
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
//        .filter { searchText.isEmpty ? true : $0.title.localizedStandardContains(searchText) }
//    }

    var body: some View {
        #if os(iOS)
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                Section("Budget for \(budgetHeader)") {
                    titleRow
                }
                transactionList
            }
            .searchable(text: $searchText, prompt: Text("Search Transactions"))
            .navigationTitle(budget.category?.title ?? "N/A")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
        }
        .transactionEditSheetAndLogic(
            calModel: calModel,
            transEditID: $transEditID,
            editTrans: $editTrans,
            selectedDay: $transDay
        )
        
        //        StandardContainer {
        //            LabeledRow("Name", labelWidth) {
        //                Text(budget.category?.title ?? "")
        //            }
        //
        //            LabeledRow("Budget", labelWidth) {
        //                StandardTextField("Monthly Amount", text: $budget.amountString, focusedField: $focusedField, focusValue: 0)
        //                    #if os(iOS)
        //                    .keyboardType(.decimalPad)
        //                    #endif
        //                    //.focused($focusedField, equals: .amount)
        //            }
        //
        //
        //            StandardDivider()
        //            ForEach(transactions) { trans in
        //                VStack(spacing: 0) {
        //                    LineItemView(trans: trans, day: .init(date: Date()), isOnCalendarView: false)
        //                    Divider()
        //                }
        //            }
        //        } header: {
        //            SheetHeader(title: title, close: { dismiss() })
        //        }
        //        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        .task {
            budget.deepCopy(.create)
            /// Just for formatting.
            budget.amountString = budget.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
            prepareData()
        }
        //        .alert("Delete \(budget.category?.title)?", isPresented: $showDeleteAlert, actions: {
        //            Button("Yes", role: .destructive) {
        //                Task {
        //                    calModel.months.forEach { month in
        //                        month.days.forEach { day in
        //                            day.transactions.filter { $0.budget?.id == budget.id }.forEach { trans in
        //                                trans.category = nil
        //                            }
        //                        }
        //                    }
        //                    dismiss()
        //                    await catModel.delete(category)
        //                }
        //            }
        //
        //            Button("Cancel", role: .cancel) {
        //                showDeleteAlert = false
        //            }
        //        }, message: {
        //            Text("This will not delete any associated transactions.")
        //        })
    
        #endif
    }
    
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "checkmark")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }
    
    
    var titleRow: some View {
        HStack(spacing: 0) {
            Label {
                Text("")
            } icon: {
                Image(systemName: "t.circle")
                    .foregroundStyle(.gray)
            }
            
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
            StandardTextField("Name", text: $group.title, focusedField: $focusedField, focusValue: 0)
                .onSubmit { focusedField = 1 }
            #endif
        }
        .focused($focusedField, equals: 0)
    }
    
    
    var transactionList: some View {
        ForEach(calModel.sMonth.days.filter { $0.date != nil }) { day in
            let filteredTrans = getTransactions(for: day)
            
            let doesHaveTransactions = filteredTrans
                .filter { $0.dateComponents?.day == day.date?.day }
                .count > 0
            
//            let dailyTotal = transactions
//                .filter { $0.dateComponents?.day == day.date?.day }
//                .map { $0.payMethod?.accountType == .credit ? $0.amount * -1 : $0.amount }
//                .reduce(0.0, +)
//            
//            let dailyCount = transactions
//                .filter { $0.dateComponents?.day == day.date?.day }
//                .count
                   
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
                                .foregroundStyle(Color.fromName(colorTheme))
                            VStack {
                                Divider()
                                    .overlay(Color.fromName(colorTheme))
                            }
                        }
                    } else {
                        Text(day.date?.string(to: .monthDayShortYear) ?? "")
                    }
                    
                }
//                footer: {
//                    if doesHaveTransactions {
//                        SectionFooter(day: day, dailyCount: dailyCount, dailyTotal: dailyTotal, cumTotals: cumTotals)
//                    }
//                }
            }
        }
    }
    
    
//    struct SectionFooter: View {
//        @Local(\.useWholeNumbers) var useWholeNumbers
//        @Local(\.threshold) var threshold
//
//        var day: CBDay
//        var dailyCount: Int
//        var dailyTotal: Double
//        var cumTotals: [CumTotal]
//        
//        private var eodColor: Color {
//            if day.eodTotal > threshold {
//                return .gray
//            } else if day.eodTotal < 0 {
//                return .red
//            } else {
//                return .orange
//            }
//        }
//                
//        var body: some View {
//            HStack {
//                Text("EOD: \(day.eodTotal.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
//                    .foregroundStyle(eodColor)
//                
//                Spacer()
//                if dailyCount > 1 {
//                    Text(dailyTotal.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                }
//            }
//        }
//    }
    
    
    func getTransactions(for day: CBDay) -> Array<CBTransaction> {
        transactions
            .filter { searchText.isEmpty ? true : $0.title.localizedStandardContains(searchText) }
            .filter { $0.dateComponents?.day == day.date?.day }
            .filter { ($0.payMethod?.isAllowedToBeViewedByThisUser ?? true) }
            .filter { !($0.payMethod?.isHidden ?? false) }
            .sorted {
                if transactionSortMode == .title {
                    return $0.title < $1.title
                    
                } else if transactionSortMode == .enteredDate {
                    return $0.enteredDate < $1.enteredDate
                    
                } else {
                    if categorySortMode == .title {
                        return ($0.category?.title ?? "").lowercased() < ($1.category?.title ?? "").lowercased()
                    } else {
                        return $0.category?.listOrder ?? 10000000000 < $1.category?.listOrder ?? 10000000000
                    }
                }
            }
    }
    
    
    
    func prepareData() {
        transactions = calModel.justTransactions
            .filter { calModel.isInMultiSelectMode ? calModel.multiSelectTransactions.map({ $0.id }).contains($0.id) : true }
            //.filter { $0.payMethod?.id == calModel.sPayMethod?.id }
//            .filter { trans in
//                if let sMethod = calModel.sPayMethod {
//                    if sMethod.isUnifiedDebit {
//                        let methods: Array<String> = payModel.paymentMethods
//                            .filter { $0.isAllowedToBeViewedByThisUser }
//                            .filter { !$0.isHidden }
//                            .filter { $0.isDebit }
//                            .map { $0.id }
//                        return methods.contains(trans.payMethod?.id ?? "")
//
//                    } else if sMethod.isUnifiedCredit {
//                        let methods: Array<String> = payModel.paymentMethods
//                            .filter { $0.isAllowedToBeViewedByThisUser }
//                            .filter { !$0.isHidden }
//                            .filter { $0.isCredit }
//                            .map { $0.id }
//                        return methods.contains(trans.payMethod?.id ?? "")
//
//                    } else {
//                        return trans.payMethod?.id == sMethod.id && (trans.payMethod?.isAllowedToBeViewedByThisUser ?? true) && !(trans.payMethod?.isHidden ?? false)
//                    }
//                } else {
//                    return false
//                }
//            }
            .filter { $0.dateComponents?.month == calModel.sMonth.actualNum }
            .filter { $0.dateComponents?.year == calModel.sMonth.year }
            .filter {
                $0.categoryIdsInCurrentAndDeepCopy.contains(budget.category?.id)
                && $0.payMethod?.isAllowedToBeViewedByThisUser ?? true
                && !$0.hasHiddenMethodInCurrentOrDeepCopy
                //&& !$0.hasPrivateMethodInCurrentOrDeepCopy
            }
            .sorted { $0.dateComponents?.day ?? 0 < $1.dateComponents?.day ?? 0 }
    }
}
