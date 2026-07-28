//
//  BudgetOverview.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/9/26.
//

import SwiftUI
import Charts


struct BudgetOverview: View {
    @Environment(\.dismiss) var dismiss

    @Environment(CalendarModel.self) var calModel
    @Environment(BudgetModel.self) var budgetModel
    @Environment(AppStore.self) var store

    @Bindable var budget: CBBudgetItem
    var location: WhereToLookForBudget
    //@Binding var navPath: NavigationPath
    
    //@State private var transactions: [CBTransaction] = []
    @State private var transEditID: String?
    @State private var editTrans: CBTransaction?
    @State private var transDay: CBDay? = CBDay(date: Date())
    @State private var showDeleteAlert = false
    @State private var budgetEditID: CBBudgetItem.ID?
    @State private var editBudget: CBBudgetItem?
    @State private var isLoading = false
    @State private var transactions: [CBTransaction] = []
    @State private var searchText = ""
    @State private var cumTotals: [BudgetCumTotal] = []
    @State private var spendByDateTotals: [BudgetDailySpendTotal] = []
   

    
    var totalExpenses: Decimal {
        if budget.type == .tag {
            return TransactionHelper.All.Amount.actualSpend(from: store.tagBudgetTransactions)
            //return store.tagBudgetTransactions.map { $0.amount * -1 }.reduce(0, +)
        } else {
            return TransactionHelper.All.Amount.actualSpend(from: transactions)
//            let trans = calModel.sMonth.justTransactions
//                .filter { $0.dateComponents?.month == calModel.sMonth.actualNum }
//                .filter { $0.dateComponents?.year == calModel.sMonth.year }
//            return TransactionHelper.getActualSpend(from: trans)
//            transactions
//                .filter { !$0.isPaymentDest }
//                .map { ($0.payMethod?.isCreditOrLoan ?? false) ? $0.amount : $0.amount * -1 }
//                .reduce(0.0, +)
        }
    }
    
    var navTitle: String {
        if budget.type == .tag {
            "#\(budget.item?.title ?? "N/A")"
        } else {
            budget.item?.title ?? "N/A"
        }
        
    }
    
    var sortedTrans: [CBTransaction] {
        store.tagBudgetTransactions.sorted(by: { $0.enteredDate > $1.enteredDate })
    }
    
    var body: some View {
        List {
            Section("Budget & Expenses") {
                if budget.type == .categoryGroup {
                    if let cats = budget.categoryGroup?.categories {
                        BudgetChartForGroup(
                            categories: cats,
                            budgetAmount: budget.amount,
                            expenseAmount: totalExpenses
                        )
                    }
                    
                    ForEach(budget.categoryGroup?.categories ?? []) { category in
                        let transactions = calModel.getTransactions(cats: [category])
                        let actualSpend = TransactionHelper.All.Amount.actualSpend(from: transactions)
                        Label {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(category.title)
                                    Spacer()
                                    Text(actualSpend.currencyWithDecimals())
                                }
                            }
                        } icon: {
                            StandardCategorySymbol(cat: category, labelWidth: 20)
                        }
                        #if os(macOS)
                        .selectionDisabled()
                        #endif
                        //Text(cat.title)
                    }
                } else {
                    BudgetChart(budgetAmount: budget.amount, expenseAmount: totalExpenses)
                }
            }
            
            if budget.type != .tag {
                Section("Cumulative Spending") {
                    BudgetCumSpendingChart(budgetAmount: budget.amount, cumTotals: cumTotals)
                }
                
                Section("Spending By Day") {
                    BudgetSpendingByDayChart(data: spendByDateTotals)
                }
            }
            
            if budget.type == .tag {
                Section("Transactions") {
                    if store.tagBudgetTransactions.isEmpty {
                        ContentUnavailableView("No Transactions", systemImage: "rectangle.stack.slash")
                        
                    } else {
                        ForEach(sortedTrans) { trans in
                            TransactionListLine(trans: trans, withDate: true, withPhotos: true) {
                                self.transEditID = trans.id
                            }
                        }
                    }
                }
            } else {
                transactionListForSelectedMonth
            }
        }
        .navigationTitle(navTitle)
        .task {
            if budget.action == .add {
                budgetEditID = budget.id
            } else if budget.type == .tag {
                await fetchTransactionsFromServer(withSpinner: true)
            } else {
                prepareData(calModel: calModel)
            }
        }
        .if(budget.type == .tag) {
            $0.refreshable {
                await fetchTransactionsFromServer(withSpinner: false)
            }
        }
        .transactionEditSheetAndLogic(
            transEditID: $transEditID,
            selectedDay: $transDay,
            findTransactionWhere: budget.type == .tag ? .constant(.tagBudgetList) : .constant(.normalList),
            tag: budget.tag
        )
        .onDisappear { store.tagBudgetTransactions.removeAll() }
        .toolbar { toolbar }
        .onChange(of: budgetEditID) { oldId, newId in
            if let newId {
                if let budget = budgetModel.getBudgetItem(by: newId, from: location) {
                    editBudget = budget
                } else {
                    editBudget = CBBudgetItem(uuid: newId)
                }
            } else {
                budgetModel.saveBudget(id: oldId!, location: location)
                
                if budget.action == .delete || budget.action == .add {
                    dismiss()
                    return
                }
                
                if budget.type == .tag {
                    Task {
                        await fetchTransactionsFromServer(withSpinner: true)
                    }
                }
            }
        }
        .sheet(item: $editBudget, onDismiss: {
            budgetEditID = nil
        }) { budget in
            if budget.type == .tag || budget.action == .add {
                TagBudgetEditView(budget: budget, calModel: calModel)
                    .presentationSizing(.page)
                
            } else {
                BudgetItemEditView(
                    title: budget.item?.title ?? "N/A",
                    obj: budget,
                    showCategories: false
                )
                .presentationSizing(.page)
            }
        }
    }
    
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        if isLoading {
            #if os(iOS)
            ToolbarItem(placement: .topBarTrailing) {
                ProgressView()
                    .tint(.none)
            }
            .sharedBackgroundVisibility(.hidden)
            #else
            ToolbarItem(placement: .principal) {
                ProgressView()
                    .tint(.none)
            }
            #endif
        }
        #if os(iOS)
        ToolbarSpacer(.fixed, placement: .topBarTrailing)
        ToolbarItem(placement: .topBarTrailing) { editButton }
        ToolbarSpacer(.flexible, placement: .topBarTrailing)
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                self.transDay = store.months.getDay(by: Date())
                transEditID = UUID().uuidString
            } label: {
                Image(systemName: "plus")
                    .schemeBasedForegroundStyle()
            }
        }
        #endif
    }
    
    
    @ViewBuilder
    var editButton: some View {
        Button {
            budgetEditID = budget.id
        } label: {
            Text("Edit")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    @ViewBuilder
    var transactionListForSelectedMonth: some View {
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
                        TransactionListLine(trans: trans) {
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
    
    
    struct SectionFooter: View {
        var day: CBDay
        var dailyCount: Int
        var dailyTotal: Decimal
        var cumTotals: [BudgetCumTotal]
                
        var body: some View {
            HStack {
                Text("Cumulative Total: \((cumTotals.filter { $0.date == day.date! }.first?.total ?? 0.0).currencyWithDecimals())")
                
                Spacer()
                if dailyCount > 1 {
                    Text(dailyTotal.currencyWithDecimals())
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
    
    
//    func prepareData() {
//        if budget.type == .category {
//            if let cat = budget.category {
//                transactions = calModel.getTransactions(cats: [cat])
//                    .filter { $0.dateComponents?.month == calModel.sMonth.actualNum }
//                    .filter { $0.dateComponents?.year == calModel.sMonth.year }
//            }
//        } else if budget.type == .categoryGroup {
//            if let cats = budget.categoryGroup?.categories {
//                transactions = calModel.getTransactions(cats: cats)
//                    .filter { $0.dateComponents?.month == calModel.sMonth.actualNum }
//                    .filter { $0.dateComponents?.year == calModel.sMonth.year }
//            }
//        } else {
//            transactions = calModel.sMonth.justTransactions
//                .filter { $0.dateComponents?.month == calModel.sMonth.actualNum }
//                .filter { $0.dateComponents?.year == calModel.sMonth.year }
//        }
//        
//        let newCumTotals = BudgetHelper.calculateCumTotals(
//            calModel: calModel,
//            transactions: transactions,
//            budgetAmount: budget.amount,
//        )
//        
//        withAnimation {
//            self.cumTotals = newCumTotals
//        }        
//    }
    

    @MainActor
    func prepareData(calModel: CalendarModel) {
        let month = calModel.sMonth.actualNum
        let year = calModel.sMonth.year
        let budgetAmount = calModel.sMonth.amount

        if budget.type == .category {
            if let cat = budget.category {
                transactions = calModel.getTransactions(cats: [cat])
                    .filter { $0.dateComponents?.month == calModel.sMonth.actualNum }
                    .filter { $0.dateComponents?.year == calModel.sMonth.year }
            }
        } else if budget.type == .categoryGroup {
            if let cats = budget.categoryGroup?.categories {
                transactions = calModel.getTransactions(cats: cats)
                    .filter { $0.dateComponents?.month == calModel.sMonth.actualNum }
                    .filter { $0.dateComponents?.year == calModel.sMonth.year }
            }
        } else {
            transactions = calModel.sMonth.justTransactions
                .filter { $0.dateComponents?.month == calModel.sMonth.actualNum }
                .filter { $0.dateComponents?.year == calModel.sMonth.year }
        }
        
        let days = calModel.sMonth.legitDays

        let filteredTransactions = transactions//TransactionHelper.All.Transactions.spend(from: transactions)
            .filter {
                $0.dateComponents?.month == month &&
                $0.dateComponents?.year == year
            }

        self.transactions = filteredTransactions

        /// For the spending by day charts
        spendByDateTotals = BudgetHelper.calculateDailySpend(days: days, transactions: filteredTransactions)
        
        /// For the cumulative spending chart
        Task {
            let newCumTotals = await Task.detached(priority: .userInitiated) {
                await BudgetHelper.calculateCumTotals(days: days, transactions: filteredTransactions, budgetAmount: budgetAmount)
            }.value

            await MainActor.run {
                withAnimation {
                    self.cumTotals = newCumTotals
                }
            }
        }
    }
    
    
    
    @MainActor
    func fetchTransactionsFromServer(withSpinner: Bool) async {
        if let tag = budget.tag {
            if withSpinner {
                isLoading = true
            }
            
            let requestModel = TagRequestModel(tagId: tag.id)
            
            /// Do networking.
            let model = RequestModel(requestType: "fetch_transactions_for_tag", model: requestModel)
            typealias ResultResponse = Result<Array<CBTransaction>?, AppError>
            async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)

            switch await result {
            case .success(let model):
                if let model {
                    for each in model {
                        await each.payMethod?.loadLogoFromCoreDataIfNeeded()
                    }
                    withAnimation {
                        isLoading = false
                        store.tagBudgetTransactions = model
                    }
                }

            case .failure (let error):
                switch error {
                case .taskCancelled:
                    /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                    print("\(#function) Task Cancelled")
                default:
                    LogManager.error(error.localizedDescription)
                    AppState.shared.showAlert("There was a problem trying to fetch the dashboard.")
                }
            }
            isLoading = false
        }
        
    }
}











