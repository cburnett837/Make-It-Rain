//
//  CategoryAnalysisSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/26/24.
//

import SwiftUI
import Charts

struct AnalysisSheet: View {
    @Environment(\.colorScheme) var colorScheme
    #if os(macOS)
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appearsActive) var appearsActive
    #endif
    @AppStorage("transactionSortMode") var transactionSortMode: TransactionSortMode = .title
    @AppStorage("categorySortMode") var categorySortMode: CategorySortMode = .title
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Local(\.colorTheme) var colorTheme

    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(EventModel.self) private var eventModel
    @Binding var showAnalysisSheet: Bool
        
    struct CumTotal {
        var day: Int
        var total: Double
    }
    
//    struct ChartData: Identifiable {
//        var id: String { return category.id }
//        let category: CBCategory
//        var budget: Double
//        var expenses: Double
//        var budgetObject: CBBudget?
//    }
    

    @State private var transactions: [CBTransaction] = []
    @State private var totalSpent: Double = 0.0
    @State private var spendMinusPayments: Double = 0.0
    @State private var cashOut: Double = 0.0
    @State private var income: Double = 0.0
    @State private var budget: Double = 0.0
    @State private var chartData: [ChartData] = []
    
    @State private var transEditID: String?
    @State private var editTrans: CBTransaction?
    
    @State private var transDay: CBDay?
    @State private var cumTotals: [CumTotal] = []
    @State private var showCategorySheet = false
    
    @State private var showInfo = false
    
    let columnGrid = Array(repeating: GridItem(.flexible(), spacing: 0), count: 4)
    
    var body: some View {
        @Bindable var calModel = calModel
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                detailSection
                                
                Section {
                    chartSection
                } header: {
                    Text("Chart")
                }
                
                BudgetBreakdownView(wrappedInSection: true, chartData: chartData, calculateDataFunction: prepareData)
                transactionList
            }
            .navigationTitle("Category Insights")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { showCategorySheetButton }
                ToolbarSpacer(.fixed, placement: .topBarLeading)
                ToolbarItem(placement: .topBarLeading) { showInfoButton }
                ToolbarItem(placement: .topBarTrailing) { showCalendarButton }
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            #endif
        }
        .task {
            if calModel.sCategoriesForAnalysis.isEmpty && showAnalysisSheet {
                showCategorySheet = true
            } else {
                prepareData()
                //analyzeTransactions()
            }
        }
        /// Needed for the inspector on iPad.
        .onChange(of: showAnalysisSheet) {
            if $1 && !showCategorySheet { showCategorySheet = true }
        }
        .sheet(isPresented: $showCategorySheet, onDismiss: {
            //analyzeTransactions()
        }, content: {
            MultiCategorySheet(categories: $calModel.sCategoriesForAnalysis, showAnalyticSpecificOptions: true)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
            //CategorySheet(category: $calModel.sCategory)
        })
        .onChange(of: showCategorySheet) {
            if !$1 { prepareData() }
        }
        /// Recalculate the analysis data when the month changes.
//        .onChange(of: NavigationManager.shared.selectedMonth) {
//            /// Put a slight delay so the app has time to switch all the transactions to the new month.
//            Task {
//                try? await Task.sleep(nanoseconds: UInt64(0.3 * Double(NSEC_PER_SEC)))
//                prepareData()
//            }
//        }
        /// Recalculate the analysis data when the month or year changes.
//        .onChange(of: calModel.sMonth.justTransactions) {
//            /// Put a slight delay so the app has time to switch all the transactions to the new month.
//            Task {
//                try? await Task.sleep(nanoseconds: UInt64(0.3 * Double(NSEC_PER_SEC)))
//                prepareData()
//            }
//        }
//        /// Recalculate when transaction amounts change.
//        .onChange(of: calModel.sMonth.justTransactions.map{ $0.amount }) {
//            /// Put a slight delay so the app has time to switch all the transactions to the new month.
//            Task {
//                try? await Task.sleep(nanoseconds: UInt64(0.3 * Double(NSEC_PER_SEC)))
//                prepareData()
//            }
//        }
        
        .onChange(of: DataChangeTriggers.shared.calendarDidChange) {
            /// Put a slight delay so the app has time to switch all the transactions to the new month.
            Task {
                try? await Task.sleep(nanoseconds: UInt64(0.3 * Double(NSEC_PER_SEC)))
                prepareData()
            }
        }
        
        #if os(macOS)
        .onChange(of: appearsActive) {
            if $1 { prepareData() }
        }
        #endif
        
//        .sheet(item: $editTrans) { trans in
//            TransactionEditView(trans: trans, transEditID: $transEditID, day: transDay!, isTemp: false)
//                /// This is needed for the drag to dismiss.
//                .onDisappear { transEditID = nil }
//            #warning("produces a race condition when swiping to close and opening another trans too quickly. Causes transDays to be nil and crashes the app.")
//        }
//        .onChange(of: transEditID) { transEditIdChanged(oldValue: $0, newValue: $1) }
//        .sensoryFeedback(.selection, trigger: transEditID) { $1 != nil }
        
        .transactionEditSheetAndLogic(
            calModel: calModel,
            transEditID: $transEditID,
            editTrans: $editTrans,
            selectedDay: $transDay
        )
    }
    
//    
//    var bodyOG: some View {
//        @Bindable var calModel = calModel
//        StandardContainer(AppState.shared.isIpad ? .sidebarList : .list) {
//            detailSection
//            BudgetBreakdownView(wrappedInSection: true, chartData: chartData, calculateDataFunction: prepareData)
//            transactionList
//        } header: {
//            if AppState.shared.isIpad {
//                SidebarHeader(
//                    title: "Analyze Categories",
//                    close: {
//                        #if os(iOS)
//                        withAnimation { showAnalysisSheet = false }
//                        #else
//                        dismiss()
//                        #endif
//                    },
//                    view1: { showCategorySheetButton },
//                    view2: { showCalendarButton }
//                )
//            } else {
//                SheetHeader(
//                    title: "Analyze Categories",
//                    close: {
//                        #if os(iOS)
//                        withAnimation { showAnalysisSheet = false }
//                        #else
//                        dismiss()
//                        #endif
//                    },
//                    view1: { showCategorySheetButton },
//                    view2: { showCalendarButton }
//                )
//            }
//        }
//        .task {
//            if calModel.sCategoriesForAnalysis.isEmpty {
//                showCategorySheet = true
//            } else {
//                prepareData()
//                //analyzeTransactions()
//            }
//        }
//        .sheet(isPresented: $showCategorySheet, onDismiss: {
//            //analyzeTransactions()
//        }, content: {
//            MultiCategorySheet(categories: $calModel.sCategoriesForAnalysis)
//            #if os(macOS)
//                .frame(minWidth: 300, minHeight: 500)
//                .presentationSizing(.fitted)
//            #endif
//            //CategorySheet(category: $calModel.sCategory)
//        })
//        .onChange(of: showCategorySheet) {
//            if !$1 { prepareData() }
//        }
//        
//        #if os(macOS)
//        .onChange(of: appearsActive) {
//            if $1 { prepareData() }
//        }
//        #endif
//        
////        .sheet(item: $editTrans) { trans in
////            TransactionEditView(trans: trans, transEditID: $transEditID, day: transDay!, isTemp: false)
////                /// This is needed for the drag to dismiss.
////                .onDisappear { transEditID = nil }
////            #warning("produces a race condition when swiping to close and opening another trans too quickly. Causes transDays to be nil and crashes the app.")
////        }
////        .onChange(of: transEditID) { transEditIdChanged(oldValue: $0, newValue: $1) }
////        .sensoryFeedback(.selection, trigger: transEditID) { $1 != nil }
//        
//        .transactionEditSheetAndLogic(
//            calModel: calModel,
//            transEditID: $transEditID,
//            editTrans: $editTrans,
//            selectedDay: $transDay
//        )
//    }
//            
//    
    @ViewBuilder var detailSection: some View {
        if showInfo {
            Section {
                numberOfTransactionsRow
            } footer: {
                Text("The number of transactions that are being used to calculate the metrics.")
            }
            
            Section {
                cumBudgetsRow
            } footer: {
                Text("A summary of the budget amounts from the selected categories.")
            }
            
            Section {
                incomeRow
            } footer: {
                Text("The sum of positive dollar amounts.\n(Income, Deposits, Refunds, Etc.)")
            }
            
            Section {
                cashOutRow
            } footer: {
                Text("The sum of all money that left your debit accounts. (Including credit/loan payments)")
            }
            
            Section {
                totalSpendingRow
            } footer: {
                Text("The sum of actual consumption. AKA expenses that are not offset by a credit/loan payment.")
            }
            
            Section {
                spendMinusPaymentsRow
            } footer: {
                Text("The sum of your expenses, offset by credit payments.")
            }
            
            Section {
                overUnderRow
            } footer: {
                Text("The amount left after you take the budgets and subtract the amount from the cash out row.")
            }
            
        } else {
            Section {
                numberOfTransactionsRow
                cumBudgetsRow
                incomeRow
                cashOutRow
                totalSpendingRow
                spendMinusPaymentsRow
                overUnderRow
            } header: {
                Text("Details")
            }
        }
        
    }
    
    var numberOfTransactionsRow: some View {
        HStack {
            infoButtonLabel("Number of transactions…")
            Spacer()
            Text("\(transactions.count)")
        }
    }
    
    var cumBudgetsRow: some View {
        HStack {
            infoButtonLabel("Cumulative budget…")
            Spacer()
            Text(budget.currencyWithDecimals(useWholeNumbers ? 0 : 2))
        }
    }
    
    var incomeRow: some View {
        HStack {
            infoButtonLabel("Income…")
            Spacer()
            Text((income).currencyWithDecimals(useWholeNumbers ? 0 : 2))
        }
    }
    
    var cashOutRow: some View {
        HStack {
            infoButtonLabel("Cash out…")
            Spacer()
            Text((cashOut * -1).currencyWithDecimals(useWholeNumbers ? 0 : 2))
        }
    }
    
    var totalSpendingRow: some View {
        HStack {
            infoButtonLabel("Total Spending…")
            Spacer()
            Text((totalSpent * -1).currencyWithDecimals(useWholeNumbers ? 0 : 2))
        }
    }
    
    var spendMinusPaymentsRow: some View {
        HStack {
            infoButtonLabel("Spending - Payments…")
            Spacer()
            Text((spendMinusPayments * -1).currencyWithDecimals(useWholeNumbers ? 0 : 2))
        }
    }
    
    var overUnderRow: some View {
        HStack {
            let amount = budget - (cashOut * -1)
            let isOver = amount < 0
            infoButtonLabel(isOver ? "Your spending is over-budget by…" : "Your spending is under-budget by…")
            Spacer()
            Text(abs(amount).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                .foregroundStyle(isOver ? .red : .green)
        }
    }
    
    @ViewBuilder func infoButtonLabel(_ text: String) -> some View {
        Button {
            withAnimation {
                showInfo.toggle()
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: showInfo ? "xmark.circle" : "info.circle")
                Text(text)
            }
            .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
        .tint(.none)
    }
    
    
    var showInfoButton: some View {
        Button {
            withAnimation {
                showInfo.toggle()
            }
        } label: {
            Image(systemName: "info")
        }
        .tint(.none)
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
            
            Section {
                if doesHaveTransactions {
                    ForEach(getTransactions(for: day)) { trans in
                        TransactionListLine(trans: trans)
                            .onTapGesture {
                                self.transDay = day
                                self.transEditID = trans.id
                            }
                    }
                } else {
                    Text("No Transactions")
                        .foregroundStyle(.gray)
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
                
            } footer: {
                if doesHaveTransactions {
                    SectionFooter(day: day, dailyCount: dailyCount, dailyTotal: dailyTotal, cumTotals: cumTotals)
                }
            }
            
//            if let date = day.date, date.isToday {
//                Section {
//                    if doesHaveTransactions {
//                        ForEach(getTransactions(for: day)) { trans in
//                            TransactionListLine(trans: trans)
//                                .onTapGesture {
//                                    self.transDay = day
//                                    self.transEditID = trans.id
//                                }
//                        }
//                    } else {
//                        Text("No Transactions Today")
//                            .foregroundStyle(.gray)
//                    }
//                } header: {
//                    HStack {
//                        Text("TODAY")
//                            .foregroundStyle(Color.fromName(colorTheme))
//                        VStack {
//                            Divider()
//                                .overlay(Color.fromName(colorTheme))
//                        }
//                    }
//                } footer: {
//                    if doesHaveTransactions {
//                        SectionFooter(day: day, dailyCount: dailyCount, dailyTotal: dailyTotal, cumTotals: cumTotals)
//                    }
//                }
//            } else {
//                if doesHaveTransactions {
//                    Section {
//                        ForEach(getTransactions(for: day)) { trans in
//                            TransactionListLine(trans: trans)
//                                .onTapGesture {
//                                    self.transDay = day
//                                    self.transEditID = trans.id
//                                }
//                        }
//                    } header: {
//                        Text(day.date?.string(to: .monthDayShortYear) ?? "")
//                    } footer: {
//                        SectionFooter(day: day, dailyCount: dailyCount, dailyTotal: dailyTotal, cumTotals: cumTotals)
//                    }
//                }
//            }
        }
    }
    
    
    func getTransactions(for day: CBDay) -> Array<CBTransaction> {
        transactions
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
        
    
    
    
    var chartSection: some View {
        Group {
            VStack {
                Chart(chartData) { metric in
                    BarMark(
                        x: .value("Amount", metric.budget),
                        y: .value("Key", "Budget")
                    )
                    .foregroundStyle(metric.category.color)
//                    .annotation(position: .overlay, alignment: .center) {
//                        HStack {
//                            Text(metric.budget.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                                .font(.caption2)
//                            Spacer()
//                        }
//                    }
                    
                    BarMark(
                        x: .value("Amount", (metric.expenses * -1 - metric.income)),
                        y: .value("Key", "Expenses")
                    )
                    .foregroundStyle(metric.category.color)
//                    .annotation(position: .overlay, alignment: .center) {
//                        HStack {
//                            Text(metric.expenses.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                                .font(.caption2)
//
//                            Spacer()
//                        }
//                    }
                }
                .chartLegend(.hidden)
                
                
                
                
                ScrollView(.horizontal) {
                    ZStack {
                        Spacer()
                            .containerRelativeFrame([.horizontal])
                            .frame(height: 1)
                                                    
                        HStack(spacing: 0) {
                            ForEach(chartData) { item in
                                HStack(alignment: .circleAndTitle, spacing: 5) {
                                    Circle()
                                        .fill(item.category.color)
                                        .frame(maxWidth: 8, maxHeight: 8) // 8 seems to be the default from charts
                                        .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.category.title)
                                            .foregroundStyle(Color.secondary)
                                            .font(.caption2)
                                            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//
//                                        Text(item.expenses.currencyWithDecimals(2))
//                                            .foregroundStyle(Color.secondary)
//                                            .font(.caption2)
                                    }
                                }
                                .padding(.horizontal, 4)
                                .contentShape(Rectangle())
    //                            #if os(macOS)
    //                            .onContinuousHover { phase in
    //                                switch phase {
    //                                case .active:
    //                                    selectedBudget = item.category.title
    //                                case .ended:
    //                                    selectedBudget = nil
    //                                }
    //                            }
    //                            #endif
                            }
                            Spacer()
                        }
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .contentMargins(.bottom, 10, for: .scrollContent)
            }
        }
    }
    
    
    var showCategorySheetButton: some View {
        Button {
            showCategorySheet = true
        } label: {
            Image(systemName: "books.vertical")
        }
        .tint(.none)
        //.buttonStyle(.borderedProminent)
        //.buttonStyle(.sheetHeader)
    }
    
    
    var showCalendarButton: some View {
        Button {
            calModel.sCategories = calModel.sCategoriesForAnalysis
                        
            #if os(iOS)
            if !AppState.shared.isIpad {
                withAnimation { showAnalysisSheet = false }
            }
            
            #else
            //dismiss()
            #endif
            
        } label: {
            Image(systemName: "calendar")
                .contentShape(Rectangle())
        }
        .tint(.none)
    }
    
    
    var closeButton: some View {
        Button {
            #if os(iOS)
            withAnimation { showAnalysisSheet = false }
            #else
            dismiss()
            #endif
        } label: {
            Image(systemName: "xmark")
        }
        .tint(.none)
        //.buttonStyle(.glassProminent)
    }
    
   
//    func transEditIdChanged(oldValue: String?, newValue: String?) {
//        /// When `newValue` is false, save to the server. We have to use this because `.popover(isPresented:)` has no onDismiss option.
//        if oldValue != nil && newValue == nil {
//            let theDay = transDay
//            transDay = nil
//            calModel.saveTransaction(id: oldValue!, day: theDay, eventModel: eventModel)
//            //calModel.pictureTransactionID = nil
//            PhotoModel.shared.pictureParent = nil
//            
//            calModel.editLock = false
//            
//        } else if newValue != nil {
//            if !calModel.editLock {
//                /// Prevent a transaction from being opened while another one is trying to save.
//                calModel.editLock = true
//                editTrans = calModel.getTransaction(by: newValue!, from: .normalList)
//            }
//        }
//    }
    
    
    func prepareData() {
        print("-- \(#function)")
        /// Gather only the relevant transactions.
        transactions = calModel.sMonth.justTransactions
            .filter {
                /// If the app is in multi-select mode, pay attention to only those transactions.
                calModel.isInMultiSelectMode ? calModel.multiSelectTransactions.map({ $0.id }).contains($0.id) : true
                /// Only payment methods that are allowed to be viewed by the current user.
                && ($0.payMethod?.isAllowedToBeViewedByThisUser ?? true)
                /// Only if payment method is not hidden.
                && !($0.payMethod?.isHidden ?? false)
                /// Only transactions that are not excluded from calculations.
                && $0.factorInCalculations
                /// Only transactions related to the selected categories.
                && calModel.sCategoriesForAnalysis.map{ $0.id }.contains($0.category?.id)
                /// Only transactions from the selected month.
                //&& $0.dateComponents?.month == calModel.sMonth.actualNum
                /// Only transactions from the selected year.
                //&& $0.dateComponents?.year == calModel.sMonth.year
            }
            //#warning("Don't include this filter here because it will cause the total to add up payments and mess up the money out variable")
        
            /// Ignore transactions that are the beneficiaries of payments.
//            .filter { trans in
//                if trans.relatedTransactionID != nil {
//                    if calModel.sMonth.justTransactions.filter ({ $0.id == trans.relatedTransactionID! }).first != nil {
//                        if trans.isPayment ?? false {
//                            return false
//                        }
//                    }
//                }
//                return true
//            }
            
        
            /// If the app is in multi-select mode, pay attention to those transactions.
//            .filter { calModel.isInMultiSelectMode ? calModel.multiSelectTransactions.map({ $0.id }).contains($0.id) : true }
//            /// Only payment methods that are allowed to be viewed by the current user, and that are not hidden.
//            .filter { ($0.payMethod?.isAllowedToBeViewedByThisUser ?? true) && !($0.payMethod?.isHidden ?? false) }
//            /// Only factored transactions.
//            .filter { $0.factorInCalculations }
////            .filter { $0.factorInCalculations }
////            .filter { $0.payMethod?.id == calModel.sPayMethod?.id }
////            .filter { trans in
////                if let sMethod = calModel.sPayMethod {
////                    if sMethod.isUnifiedDebit {
////                        let methods: Array<String> = payModel.paymentMethods.filter { $0.isDebit }.map { $0.id }
////                        return methods.contains(trans.payMethod?.id ?? "")
////
////                    } else if sMethod.isUnifiedCredit {
////                        let methods: Array<String> = payModel.paymentMethods.filter { $0.isCredit }.map { $0.id }
////                        return methods.contains(trans.payMethod?.id ?? "")
////
////                    } else {
////                        return trans.payMethod?.id == sMethod.id
////                    }
////                } else {
////                    return false
////                }
////            }
//            /// Only transactions related to the selected categories.
//            .filter { calModel.sCategoriesForAnalysis.map{ $0.id }.contains($0.category?.id) }
//            /// Only transactions from the selected month.
//            .filter { $0.dateComponents?.month == calModel.sMonth.actualNum && $0.dateComponents?.year == calModel.sMonth.year }
            .sorted { $0.dateComponents?.day ?? 0 < $1.dateComponents?.day ?? 0 }
        
//
//        if calModel.isInMultiSelectMode {
//            transactions.removeAll(where: { !calModel.multiSelectTransactions.map{$0.id}.contains($0.id)} )
//        }
        
        let totalCreditSpend = transactions
            .filter { $0.active }
            /// Only credit or loans.
            .filter { $0.payMethod?.isCreditOrLoan ?? false }
            /// Anything that has a positive dollar amount (expenses).
            .filter { $0.isExpense }
            /// Exclude cash advances
            .filter { !$0.isTransferOrigin }
            .map { $0.amount * -1 }
            .reduce(0.0, +)
        //print("totalCreditSpend- \(totalCreditSpend)")
        
        let totalCreditPayments = transactions
            .filter { $0.active }
            /// Only credit or loans.
            .filter { ($0.payMethod?.isCreditOrLoan ?? false) }
            /// Anything that has a negative dollar amount (payments).
            .filter { $0.isIncome }
            /// Is the destination transaction from the transfer utility.
            .filter { $0.isPaymentDest }
            .map { $0.amount }
            .reduce(0.0, +)
        //print("totalCreditPayments- \(totalCreditPayments)")
        
        let totalCreditRefundsOrPerks = transactions
            .filter { $0.active }
            /// Only credit or loans.
            .filter { $0.payMethod?.isCreditOrLoan ?? false }
            /// Anything that has a negative dollar amount (refunds, rewards, etc.).
            .filter { $0.isIncome }
            /// Is not the destination transaction from the transfer utility.
            .filter { !$0.isPaymentDest }
            .map { $0.amount * -1 }
            .reduce(0.0, +)
        //print("totalCreditRefundsOrPerks- \(totalCreditRefundsOrPerks)")
        
        let totalDebitSpend = transactions
            .filter { $0.active }
            /// Only debit or cash accounts.
            .filter { ($0.payMethod?.isDebit ?? false) }
            /// Anything that has a negative dollar amount (expenses).
            .filter { $0.isExpense }
            /// Is not the origination transaction from the transfer utility.
            .filter { !$0.isTransferOrigin }
            /// Is not the destination transaction from the transfer utility.
            .filter { !$0.isTransferDest }
            .map {
                print("\($0.title) - \($0.amount) - \(String(describing: $0.payMethod?.title))")
                //print("\($0.amount)")
                return $0.amount
            }
            .reduce(0.0, +)
        //print("totalDebitSpend- \(totalDebitSpend)")
        
        let totalDebitIncome = transactions
            .filter { $0.active }
            /// Only debit or cash accounts.
            .filter { ($0.payMethod?.isDebit ?? false) }
            /// Anything that has a positive dollar amount (income).
            .filter { $0.isIncome }
            /// Is not the origination transaction from the transfer utility.
            .filter { !$0.isTransferOrigin }
            /// Is not the destination transaction from the transfer utility.
            .filter { !$0.isTransferDest }
            .map {
                print("\($0.title) - \($0.amount) - \(String(describing: $0.payMethod?.title))")
                return $0.amount
            }
            .reduce(0.0, +)
        //print("totalDebitIncome- \(totalDebitIncome)")
                                        
        let totalIncome = totalCreditRefundsOrPerks + totalDebitIncome
        let totalSpend = totalDebitSpend + totalCreditSpend
        let spendMinusPayments = totalSpend - totalCreditPayments
        
        self.income = totalIncome
        self.totalSpent = totalSpend
        self.cashOut = totalDebitSpend
        self.spendMinusPayments = spendMinusPayments
        
        //print("totalIncome- \(totalIncome)")
        //print("totalSpend- \(totalSpend)")
        
        
//        self.totalSpent = transactions
//            .filter { $0.isExpense }
//            .filter { !$0.isTransferOrigin }
//            .filter { !$0.isPaymentDest }
//            .map { ($0.payMethod?.isCreditOrLoan ?? false) ? $0.amount * -1 : $0.amount }
//            .reduce(0.0, +)
        
//        self.income = transactions
//            .filter { $0.isIncome }
//            .filter { !$0.isTransferDest }
//            .filter { !$0.isPaymentDest }
//            .map { ($0.payMethod?.isCreditOrLoan ?? false) ? $0.amount * -1 : $0.amount }
//            .reduce(0.0, +)
        
        let relevantBudgets = calModel.justBudgets
            .filter {
                /// Only transactions related to the selected categories.
                calModel.sCategoriesForAnalysis.map { $0.id }.contains($0.category?.id)
                /// Only transactions from the selected month.
                && $0.month == calModel.sMonth.actualNum
                /// Only transactions from the selected year.
                && $0.year == calModel.sMonth.year
            }
        
        self.budget = relevantBudgets.map { $0.amount }.reduce(0.0, +)
        
        chartData = calModel.sCategoriesForAnalysis
            .sorted {
                categorySortMode == .title
                ? $0.title.lowercased() < $1.title.lowercased()
                : $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000
            }
            .map { cat in
//                let budget = calModel.justBudgets
//                    /// Only transactions from the selected month.
//                    .filter {
//                        /// Only transactions related to the mapped category.
//                        $0.category?.id == cat.id
//                        /// Only transactions from the selected month.
//                        && $0.month == calModel.sMonth.actualNum
//                        /// Only transactions from the selected year.
//                        && $0.year == calModel.sMonth.year
//                    }
//                    .first
                
                let budget = relevantBudgets.filter { $0.category?.id == cat.id }.first
                let budgetAmount = budget?.amount ?? 0.0
                
//                let expenses = calModel.justTransactions
//                    /// If the app is in multi-select mode, pay attention to those transactions.
//                    .filter {
//                        /// If the app is in multi-select mode, pay attention to those transactions.
//                        calModel.isInMultiSelectMode ? calModel.multiSelectTransactions.map({ $0.id }).contains($0.id) : true
//                        /// Only payment methods that are allowed to be viewed by the current user.
//                        && ($0.payMethod?.isAllowedToBeViewedByThisUser ?? true)
//                        /// Only if payment method is not hidden.
//                        && !($0.payMethod?.isHidden ?? false)
//                        /// Only expenses.
//                        && $0.isExpense
//                        /// Only factored transactions.
//                        && $0.factorInCalculations
//                        /// Only transactions related to the selected categories.
//                        && calModel.sCategoriesForAnalysis.map { $0.id }.contains($0.category?.id)
//                        /// Only for the mapped category.
//                        && $0.category?.id == cat.id
//                        /// Only transactions from the selected month.
//                        && $0.dateComponents?.month == calModel.sMonth.actualNum
//                        /// Only transactions from the selected year.
//                        && $0.dateComponents?.year == calModel.sMonth.year
//                    }
//                    /// Only payment methods that are allowed to be viewed by the current user, and that are not hidden.
//                    //.filter { ($0.payMethod?.isAllowedToBeViewedByThisUser ?? true) && !($0.payMethod?.isHidden ?? false) }
//                    //.filter { $0.isBudgetable && $0.isExpense && $0.factorInCalculations }
//                    /// Only expenses and factored transactions.
//                    //.filter { $0.isExpense && $0.factorInCalculations }
////                    .filter { trans in
////                        if let sMethod = calModel.sPayMethod {
////                            if sMethod.isUnifiedDebit {
////                                let methods: Array<String> = payModel.paymentMethods.filter { $0.isDebit }.map { $0.id }
////                                return methods.contains(trans.payMethod?.id ?? "")
////                                
////                            } else if sMethod.isUnifiedCredit {
////                                let methods: Array<String> = payModel.paymentMethods.filter { $0.isCredit }.map { $0.id }
////                                return methods.contains(trans.payMethod?.id ?? "")
////                                
////                            } else {
////                                return trans.payMethod?.id == sMethod.id
////                            }
////                        } else {
////                            return false
////                        }
////                    }
//                    /// Only transactions from the selected month.
////                    .filter {
////                        calModel.sCategoriesForAnalysis.map { $0.id }.contains($0.category?.id)
////                        && $0.dateComponents?.month == calModel.sMonth.actualNum
////                        && $0.dateComponents?.year == calModel.sMonth.year
////                        && $0.category?.id == cat.id
////                    }
//                    .sorted { $0.dateComponents?.day ?? 0 < $1.dateComponents?.day ?? 0 }
//                    .map { $0.payMethod?.accountType == .credit ? $0.amount * -1 : $0.amount }
//                    .reduce(0.0, +)
                                                                
                let expenses = transactions
                    .filter {
                        $0.category?.id == cat.id
                        && $0.isExpense
                        && !$0.isTransferOrigin
                        && !$0.isPaymentDest
                    }
                    .sorted { $0.dateComponents?.day ?? 0 < $1.dateComponents?.day ?? 0 }
                    .map { ($0.payMethod?.isCreditOrLoan ?? false) ? $0.amount * -1 : $0.amount }
                    .reduce(0.0, +)
                
                let income = transactions
                    .filter {
                        $0.category?.id == cat.id
                        && $0.isIncome
                        && !$0.isTransferDest
                        && !$0.isPaymentDest
                    }
                    .map { ($0.payMethod?.isCreditOrLoan ?? false) ? $0.amount * -1 : $0.amount }
                    .reduce(0.0, +)
                
//                let income = calModel.justTransactions
//                    .filter {
//                        /// If the app is in multi-select mode, pay attention to those transactions.
//                        calModel.isInMultiSelectMode ? calModel.multiSelectTransactions.map({ $0.id }).contains($0.id) : true
//                        /// Only payment methods that are allowed to be viewed by the current user.
//                        && ($0.payMethod?.isAllowedToBeViewedByThisUser ?? true)
//                        /// Only if payment method is not hidden.
//                        && !($0.payMethod?.isHidden ?? false)
//                        /// Only income.
//                        && $0.isIncome
//                        /// Only factored transactions.
//                        && $0.factorInCalculations
//                        /// Only transactions related to the selected categories.
//                        && calModel.sCategoriesForAnalysis.map{ $0.id }.contains($0.category?.id)
//                        /// Only for the mapped category.
//                        && $0.category?.id == cat.id
//                        /// Only transactions from the selected month.
//                        && $0.dateComponents?.month == calModel.sMonth.actualNum
//                        /// Only transactions from the selected year.
//                        && $0.dateComponents?.year == calModel.sMonth.year
//                    }
//                
//                
////                    .filter { ($0.payMethod?.isAllowedToBeViewedByThisUser ?? true) && ($0.payMethod?.isHidden ?? false) == false }
////                    .filter { calModel.isInMultiSelectMode ? calModel.multiSelectTransactions.map({ $0.id }).contains($0.id) : true }
////                    //.filter { $0.isBudgetable && $0.isIncome && $0.factorInCalculations }
////                    .filter { $0.isIncome && $0.factorInCalculations }
////                    //.filter { $0.payMethod?.id == calModel.sPayMethod?.id }
//////                    .filter { trans in
//////                        if let sMethod = calModel.sPayMethod {
//////                            if sMethod.isUnifiedDebit {
//////                                let methods: Array<String> = payModel.paymentMethods.filter { $0.isDebit }.map { $0.id }
//////                                return methods.contains(trans.payMethod?.id ?? "")
//////                                
//////                            } else if sMethod.isUnifiedCredit {
//////                                let methods: Array<String> = payModel.paymentMethods.filter { $0.isCredit }.map { $0.id }
//////                                return methods.contains(trans.payMethod?.id ?? "")
//////                                
//////                            } else {
//////                                return trans.payMethod?.id == sMethod.id
//////                            }
//////                        } else {
//////                            return false
//////                        }
//////                    }
////                    .filter {
////                        calModel.sCategoriesForAnalysis.map { $0.id }.contains($0.category?.id)
////                        && $0.dateComponents?.month == calModel.sMonth.actualNum
////                        && $0.dateComponents?.year == calModel.sMonth.year
////                        && $0.category?.id == cat.id
////                    }
//                    //.map { $0.amount }
//                    .map { $0.payMethod?.accountType == .credit ? $0.amount * -1 : $0.amount }
//                    .reduce(0.0, +)
                
//                let incomeMinusPayments =
//                transactions
//                    .filter { $0.isIncome && $0.category?.id == cat.id }
//                    /// Ignore transactions that are the beneficiaries of payments.
//                    .filter { trans in
//                        if trans.relatedTransactionID != nil {
//                            if calModel.sMonth.justTransactions.filter ({ $0.id == trans.relatedTransactionID! }).first != nil {
//                                if trans.isPaymentOrigin {
//                                    return false
//                                }
//                            }
//                        }
//                        return true
//                    }
//                    .map { ($0.payMethod?.isCreditOrLoan ?? false) ? $0.amount * -1 : $0.amount }
//                    .reduce(0.0, +)
                
                
                var chartPer = 0.0
                var actualPer = 0.0
                let expensesMinusIncome = (expenses + income) * -1
                
                if budgetAmount == 0 {
                    actualPer = expensesMinusIncome
                } else {
                    actualPer = (expensesMinusIncome / budgetAmount) * 100
                }
                                                
                if actualPer > 100 {
                    chartPer = 100
                } else if actualPer < 0 {
                    chartPer = 0
                } else {
                    chartPer = actualPer
                }
                                
                return ChartData(
                    category: cat,
                    budget: budgetAmount,
                    income: income,
                    incomeMinusPayments: 0,
                    expenses: expenses,
                    expensesMinusIncome: expensesMinusIncome,
                    chartPercentage: chartPer,
                    actualPercentage: actualPer,
                    budgetObject: budget
                )
            }
                    
        /// Analyze Data
        cumTotals.removeAll()
        
        var total: Double = 0.0
        calModel.sMonth.days.forEach { day in
            let doesHaveTransactions = !transactions.filter { $0.dateComponents?.day == day.date?.day }.isEmpty
            if doesHaveTransactions {
                let dailyTotal = transactions
                    .filter { ($0.payMethod?.isAllowedToBeViewedByThisUser ?? true) && ($0.payMethod?.isHidden ?? false) == false }
                    .filter { $0.dateComponents?.day == day.date?.day }
                    .map { ($0.payMethod?.isCreditOrLoan ?? false) ? $0.amount * -1 : $0.amount }
                    .reduce(0.0, +)
                
                total += dailyTotal
                cumTotals.append(CumTotal(day: day.date!.day, total: total))
            }
        }
    }
}
