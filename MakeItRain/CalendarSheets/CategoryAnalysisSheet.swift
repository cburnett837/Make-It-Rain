//
//  CategoryAnalysisSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/26/24.
//

import SwiftUI
import Charts

struct AnalysisSheet: View {
    #if os(macOS)
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appearsActive) var appearsActive
    #endif
    @AppStorage("transactionSortMode") var transactionSortMode: TransactionSortMode = .title
    @AppStorage("categorySortMode") var categorySortMode: CategorySortMode = .title
    @Local(\.useWholeNumbers) var useWholeNumbers
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
    @State private var budget: Double = 0.0
    @State private var chartData: [ChartData] = []
    
    @State private var transEditID: String?
    @State private var editTrans: CBTransaction?
    
    @State private var transDay: CBDay?
    @State private var cumTotals: [CumTotal] = []
    @State private var showCategorySheet = false
    
    let columnGrid = Array(repeating: GridItem(.flexible(), spacing: 0), count: 4)
    
    var body: some View {
        @Bindable var calModel = calModel        
        StandardContainer(AppState.shared.isIpad ? .sidebarList : .list) {
            detailSection
            BudgetBreakdownView(wrappedInSection: true, chartData: chartData, calculateDataFunction: prepareData)
            transactionList
        } header: {
            if AppState.shared.isIpad {
                SidebarHeader(
                    title: "Analyze Categories",
                    close: {
                        #if os(iOS)
                        withAnimation { showAnalysisSheet = false }
                        #else
                        dismiss()
                        #endif
                    },
                    view1: { showCategorySheetButton },
                    view2: { showCalendarButton }
                )
            } else {
                SheetHeader(
                    title: "Analyze Categories",
                    close: {
                        #if os(iOS)
                        withAnimation { showAnalysisSheet = false }
                        #else
                        dismiss()
                        #endif
                    },
                    view1: { showCategorySheetButton },
                    view2: { showCalendarButton }
                )
            }
        }
        .task {
            if calModel.sCategoriesForAnalysis.isEmpty {
                showCategorySheet = true
            } else {
                prepareData()
                //analyzeTransactions()
            }
        }
        .sheet(isPresented: $showCategorySheet, onDismiss: {
            //analyzeTransactions()
        }, content: {
            MultiCategorySheet(categories: $calModel.sCategoriesForAnalysis)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
            //CategorySheet(category: $calModel.sCategory)
        })
        .onChange(of: showCategorySheet) {
            if !$1 { prepareData() }
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
            
    
    var detailSection: some View {
        Section {
            HStack {
                Text("Total Items:")
                Spacer()
                Text("\(transactions.count)")
            }
            
            HStack {
                Text("Total Budget:")
                Spacer()
                Text(budget.currencyWithDecimals(useWholeNumbers ? 0 : 2))
            }
            
            HStack {
                Text("Total Expenses:")
                Spacer()
                Text((totalSpent * -1).currencyWithDecimals(useWholeNumbers ? 0 : 2))
            }
            
            HStack {
                Text("Over/Under:")
                Spacer()
                Text((budget - (totalSpent * -1)).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                    .foregroundStyle(budget - (totalSpent * -1) < 0 ? .red : .green)
            }
            
            chartSection
        } header: {
            Text("Details")
        }
    }
    
    
    var transactionList: some View {
        ForEach(calModel.sMonth.days) { day in
            let doesHaveTransactions = transactions
                .filter { $0.dateComponents?.day == day.date?.day }
                .count > 0
            
            let dailyTotal = transactions
                .filter { $0.dateComponents?.day == day.date?.day }
                .map { $0.payMethod?.accountType == .credit ? $0.amount * -1 : $0.amount }
                .reduce(0.0, +)
            
            let dailyCount = transactions
                .filter { $0.dateComponents?.day == day.date?.day }
                .count
            
            if day.date?.day == AppState.shared.todayDay && day.date?.month == AppState.shared.todayMonth && day.date?.year == AppState.shared.todayYear {
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
                        Text("No Transactions Today")
                            .foregroundStyle(.gray)
                    }
                } header: {
                    HStack {
                        Text("TODAY")
                            .foregroundStyle(.green)
                        VStack {
                            Divider()
                                .overlay(.green)
                        }
                    }
                } footer: {
                    if doesHaveTransactions {
                        SectionFooter(day: day, dailyCount: dailyCount, dailyTotal: dailyTotal, cumTotals: cumTotals)
                    }
                }
            } else {
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
                        Text(day.date?.string(to: .monthDayShortYear) ?? "")
                    } footer: {
                        SectionFooter(day: day, dailyCount: dailyCount, dailyTotal: dailyTotal, cumTotals: cumTotals)
                    }
                }
            }
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
                        x: .value("Amount", metric.expenses * -1),
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
            Image(systemName: "list.bullet")
                .contentShape(Rectangle())
        }
        .contentShape(Rectangle())
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
        transactions = calModel.justTransactions
            .filter { calModel.isInMultiSelectMode ? calModel.multiSelectTransactions.map({ $0.id }).contains($0.id) : true }
            .filter { ($0.payMethod?.isAllowedToBeViewedByThisUser ?? true) && ($0.payMethod?.isHidden ?? false) == false }
            //.filter { $0.payMethod?.id == calModel.sPayMethod?.id }
//            .filter { trans in
//                if let sMethod = calModel.sPayMethod {
//                    if sMethod.isUnifiedDebit {
//                        let methods: Array<String> = payModel.paymentMethods.filter { $0.isDebit }.map { $0.id }
//                        return methods.contains(trans.payMethod?.id ?? "")
//                        
//                    } else if sMethod.isUnifiedCredit {
//                        let methods: Array<String> = payModel.paymentMethods.filter { $0.isCredit }.map { $0.id }
//                        return methods.contains(trans.payMethod?.id ?? "")
//                        
//                    } else {
//                        return trans.payMethod?.id == sMethod.id
//                    }
//                } else {
//                    return false
//                }
//            }
            .filter { calModel.sCategoriesForAnalysis.map{ $0.id }.contains($0.category?.id) }
            .filter { $0.dateComponents?.month == calModel.sMonth.actualNum }
            .filter { $0.dateComponents?.year == calModel.sMonth.year }
            .sorted { $0.dateComponents?.day ?? 0 < $1.dateComponents?.day ?? 0 }
        
//        
//        if calModel.isInMultiSelectMode {
//            transactions.removeAll(where: { !calModel.multiSelectTransactions.map{$0.id}.contains($0.id)} )
//        }
        
        
        totalSpent = transactions
            .filter { ($0.payMethod?.isAllowedToBeViewedByThisUser ?? true) }
            .filter { !($0.payMethod?.isHidden ?? false) }
            .map { $0.payMethod?.accountType == .credit ? $0.amount * -1 : $0.amount }
            .reduce(0.0, +)
        
        self.budget = calModel.justBudgets
            //.filter { $0.month == calModel.sMonth.actualNum }
            //.filter { $0.year == calModel.sMonth.year }
            .filter { calModel.sCategoriesForAnalysis.map { $0.id }.contains($0.category?.id) }
            .map { $0.amount }
            .reduce(0.0, +)
        
        chartData = calModel.sCategoriesForAnalysis
            .sorted {
                categorySortMode == .title
                ? $0.title.lowercased() < $1.title.lowercased()
                : $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000
            }
            .map { cat in
                let budget = calModel.justBudgets
                    .filter { $0.month == calModel.sMonth.actualNum && $0.year == calModel.sMonth.year && $0.category?.id == cat.id }
                    .first
                
                let budgetAmount = budget?.amount ?? 0.0
                
                let expenses = calModel.justTransactions
                    .filter { ($0.payMethod?.isAllowedToBeViewedByThisUser ?? true) && ($0.payMethod?.isHidden ?? false) == false }
                    .filter { calModel.isInMultiSelectMode ? calModel.multiSelectTransactions.map({ $0.id }).contains($0.id) : true }
                    .filter { $0.isBudgetable && $0.isExpense && $0.factorInCalculations }
//                    .filter { trans in
//                        if let sMethod = calModel.sPayMethod {
//                            if sMethod.isUnifiedDebit {
//                                let methods: Array<String> = payModel.paymentMethods.filter { $0.isDebit }.map { $0.id }
//                                return methods.contains(trans.payMethod?.id ?? "")
//                                
//                            } else if sMethod.isUnifiedCredit {
//                                let methods: Array<String> = payModel.paymentMethods.filter { $0.isCredit }.map { $0.id }
//                                return methods.contains(trans.payMethod?.id ?? "")
//                                
//                            } else {
//                                return trans.payMethod?.id == sMethod.id
//                            }
//                        } else {
//                            return false
//                        }
//                    }
                    .filter {
                        calModel.sCategoriesForAnalysis.map { $0.id }.contains($0.category?.id)
                        && $0.dateComponents?.month == calModel.sMonth.actualNum
                        && $0.dateComponents?.year == calModel.sMonth.year
                        && $0.category?.id == cat.id
                    }
                    .sorted { $0.dateComponents?.day ?? 0 < $1.dateComponents?.day ?? 0 }
                    .map { $0.payMethod?.accountType == .credit ? $0.amount * -1 : $0.amount }
                    .reduce(0.0, +)
                
                let income = calModel.sMonth.justTransactions
                    .filter { ($0.payMethod?.isAllowedToBeViewedByThisUser ?? true) && ($0.payMethod?.isHidden ?? false) == false }
                    .filter { calModel.isInMultiSelectMode ? calModel.multiSelectTransactions.map({ $0.id }).contains($0.id) : true }
                    .filter { $0.isBudgetable && $0.isIncome && $0.factorInCalculations }
                    //.filter { $0.payMethod?.id == calModel.sPayMethod?.id }
//                    .filter { trans in
//                        if let sMethod = calModel.sPayMethod {
//                            if sMethod.isUnifiedDebit {
//                                let methods: Array<String> = payModel.paymentMethods.filter { $0.isDebit }.map { $0.id }
//                                return methods.contains(trans.payMethod?.id ?? "")
//                                
//                            } else if sMethod.isUnifiedCredit {
//                                let methods: Array<String> = payModel.paymentMethods.filter { $0.isCredit }.map { $0.id }
//                                return methods.contains(trans.payMethod?.id ?? "")
//                                
//                            } else {
//                                return trans.payMethod?.id == sMethod.id
//                            }
//                        } else {
//                            return false
//                        }
//                    }
                    .filter {
                        calModel.sCategoriesForAnalysis.map { $0.id }.contains($0.category?.id)
                        && $0.dateComponents?.month == calModel.sMonth.actualNum
                        && $0.dateComponents?.year == calModel.sMonth.year
                        && $0.category?.id == cat.id
                    }
                    //.map { $0.amount }
                    .map { $0.payMethod?.accountType == .credit ? $0.amount * -1 : $0.amount }
                    .reduce(0.0, +)
                
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
            let dailyTotal = transactions
                .filter { ($0.payMethod?.isAllowedToBeViewedByThisUser ?? true) && ($0.payMethod?.isHidden ?? false) == false }
                .filter { $0.dateComponents?.day == day.date?.day }
                .map { $0.payMethod?.accountType == .credit ? $0.amount * -1 : $0.amount }
                .reduce(0.0, +)
            
            
            if doesHaveTransactions {
                total += dailyTotal
                cumTotals.append(CumTotal(day: day.date!.day, total: total))
            }

        }
    }
   
}
