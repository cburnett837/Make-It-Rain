//
//  DashboardModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

@Observable
class DashboardModel {
    //var shouldUseTotalSpending: Bool = false
    
    @ObservationIgnored private let store: AppStore
    init(store: AppStore, isForSelectedMonth: Bool) {
        self.store = store
        self.isForSelectedMonth = isForSelectedMonth
    }
    
    public var shouldUseTotalSpending: Bool {
        get { appStorageGetter(\.shouldUseTotalSpending, key: "dashboardShouldUseTotalSpending", default: false) }
        set { appStorageSetter(\.shouldUseTotalSpending, key: "dashboardShouldUseTotalSpending", new: newValue) }
    }
    
    public var shouldUseTotalIncome: Bool {
        get { appStorageGetter(\.shouldUseTotalIncome, key: "dashboardShouldUseTotalIncome", default: false) }
        set { appStorageSetter(\.shouldUseTotalIncome, key: "dashboardShouldUseTotalIncome", new: newValue) }
    }
    
    var isForSelectedMonth: Bool
    var beginDate: Date = Date().startDateOfMonth
    var endDate: Date = Date().endDateOfMonth
    
    /// NOTE! These will not contain the data for the dashboard. These are just the selected options.
    var categories: [CBCategory] = []
    var groups: [CBCategoryGroup] = []
    var payMethod: CBPaymentMethod?
    var payMethodIds: Array<String>?
        
    @MainActor
    func setMethodIds(payModel: PayMethodModel) {
        if let meth = payMethod {
            if meth.isUnifiedDebit {
                payMethodIds = payModel.getMethodsFor(section: .debit, type: .allExceptUnified).map {$0.id}
            } else if meth.isUnifiedCredit {
                payMethodIds = payModel.getMethodsFor(section: .credit, type: .allExceptUnified).map {$0.id}
            } else {
                payMethodIds = [meth.id]
            }
        } else {
            payMethodIds = nil
        }
    }
    
//    var methsIds: Array<String>? {
//        
//        
//        
//        if calModel?.sPayMethod?.accountType == .unifiedChecking { return meth.isDebitOrCash }
//        else if calModel?.sPayMethod?.accountType == .unifiedCredit { return meth.isCreditOrLoan }
//        else { return (!meth.isDebitOrUnified && !meth.isCreditOrUnified) }
//        
//        if let meth = payMethod {
//            if meth.isUnified {
//                return store.paymentMethods.map(\.id)
//            } else {
//                return [meth.id]
//            }
//        } else {
//            return nil
//        }
//    }
    
    
    var cumTotals: [BudgetCumTotal] = []
    var spendByDateTotals: [BudgetDailyTotal] = []
    //var transactions: [CBTransaction] = []
    
    var data = DashboardData() {
        didSet {
            //print("Dashbaord data set")
        }
    }
    var isLoading = false
    var showOptionsSheet = false
    private let formatter = DateFormatter()
    
    var isDirty = false
//    var isDirty = false {
//        didSet {
//            if isDirty {
//                Task { @MainActor in
//                    await self.fetchDashboard()
//                }
//            }
//        }
//    }
    
    
    var isUnderBudget: Bool {
        data.categoryAndGroupBudget >= (shouldUseTotalSpending ? data.allAmounts.totalSpend : data.allAmounts.actualSpend)
    }
    
    var uniqueCategories: [CBCategory] {
        (data.categories + data.categoryGroups.flatMap(\.categories))
            .uniqued(on: { $0.id })
            .sorted(by: Helpers.categorySorter())
    }
    
    var expenseCategories: [CBCategory] {
        uniqueCategories.filter {
            !$0.isIncome && (shouldUseTotalSpending ? $0.allAmounts?.totalSpend ?? 0 : $0.allAmounts?.actualSpend ?? 0) > 0
        }
    }
    var incomeCategories: [CBCategory] {
        //categories.filter { $0.isIncome || ($0.allAmounts?.actualSpend ?? 0.0) < 0 }
        uniqueCategories.filter { $0.isIncome || ($0.debitAmounts?.regularIncome ?? 0.0) > 0 || ($0.debitAmounts?.irregularIncome ?? 0.0) > 0 }
    }
    
    
    var oldChangeHash: Int = 0
    var changeHash: Int {
        var hasher = Hasher()
        hasher.combine(beginDate)
        hasher.combine(endDate)
        hasher.combine(categories)
        hasher.combine(groups)
        hasher.combine(payMethod)
        hasher.combine(AppSettings.shared.paymentMethodFilterMode)
        return hasher.finalize()
    }
        
    var categoryFilterTitle: LocalizedStringKey {
        let baseText = "Data is only for"
        if categories.isEmpty {
            return ""
            
        } else if categories.count == 1 {
            return "(\(baseText) **\(categories[0].title)**)"
            
        } else if categories.count == 2 {
            return "(\(baseText) **\(categories[0].title)** & **\(categories[1].title)**)"
            
        } else {
            return "(\(baseText) **\(categories[0].title)**, **\(categories[1].title)**, and **\(categories.count - 2)** others)"
        }
    }
    

    var formattedDateRange: String {
        let calendar = Calendar.current
        
        let start = min(beginDate, endDate)
        let end = max(beginDate, endDate)
        
        let today = Date()
        let todayDay = calendar.component(.day, from: today)
        let todayMonth = calendar.component(.month, from: today)
        let todayYear = calendar.component(.year, from: today)
        
        let startDay = calendar.component(.day, from: start)
        let startMonth = calendar.component(.month, from: start)
        let startYear = calendar.component(.year, from: start)
        
        let endDay = calendar.component(.day, from: end)
        let endMonth = calendar.component(.month, from: end)
        let endYear = calendar.component(.year, from: end)
        
        let startIsFirstDayOfMonth = startDay == 1
        let endIsLastDayOfMonth = calendar.isDate(
            end,
            inSameDayAs: calendar.dateInterval(of: .month, for: end)!.end.addingTimeInterval(-1)
        )
        
        let sameYear = startYear == endYear
        
        /// Full year: Jan 1 -> Dec 31
        if sameYear,
           startIsFirstDayOfMonth,
           endIsLastDayOfMonth,
           startMonth == 1,
           endMonth == 12 {
            return "\(startYear)"
        }
        
        /// Full quarter: Jan-Mar, Apr-Jun, Jul-Sep, Oct-Dec
        if sameYear,
           startIsFirstDayOfMonth,
           endIsLastDayOfMonth {
            
            let quarterRanges: [(start: Int, end: Int, label: String)] = [
                (1, 3, "Q1"),
                (4, 6, "Q2"),
                (7, 9, "Q3"),
                (10, 12, "Q4")
            ]
            
            if let quarter = quarterRanges.first(where: { $0.start == startMonth && $0.end == endMonth }) {
                return "\(quarter.label) \(startYear)"
            }
        }
        
        /// Full month
        if sameYear,
           startIsFirstDayOfMonth,
           endIsLastDayOfMonth,
           startMonth == endMonth {
            self.formatter.dateFormat = "MMMM yyyy"
            return self.formatter.string(from: start)
        }
        
        if sameYear,
           startIsFirstDayOfMonth,
           startMonth == 1,
           endMonth == todayMonth,
           endDay == todayDay {
            return "YTD"
        }
        
        /// Fallback
        return "\(start.string(to: .datePickerDateOnlyDefault)) - \(end.string(to: .datePickerDateOnlyDefault))"
    }
    
    
    @MainActor
    var isAnalyzingAtLeastOneCreditCategory: Bool {
        self.categories
            .filter { $0.type == .payment }
            //.filter { $0.type.enumID == XrefModel.getItem(from: .categoryTypes, byEnumID: .payment).enumID }
            .isEmpty
    }
      
    
    func resetSelf() {
        self.categories = []
        self.groups = []
        self.beginDate = Date().startDateOfMonth
        self.endDate = Date().endDateOfMonth
        self.data = DashboardData()
        self.isDirty = false
    }
    
    
//    @MainActor
//    func initialFetchIfApplicable(calModel: CalendarModel, catModel: CategoryModel) async {
//        if !calModel.sMonth.isPlaceholder {
//            for group in catModel.categoryGroups {
//                let groupCatIds = group.categories.map { $0.id }
//                let hasTrans = !calModel.sMonth.justTransactions
//                    .filter ({ $0.active })
//                    .filter ({ $0.amount != 0 && groupCatIds.contains($0.category?.id ?? "0") })
//                    .isEmpty
//                
//                if hasTrans {
//                    groups.append(group)
//                }
//            }
//            
//            //categoryGroups = catModel.categoryGroups
//            
//            let relevantCategories = calModel.sMonth.justTransactions
//                .filter ({ $0.active })
//                .filter ({ $0.amount != 0 && $0.category != nil })
//                .compactMap ({ $0.category })
//                //.filter ({ !$0.isIncome })
//                .sorted(by: Helpers.categorySorter())
//                .uniqued(on: \.id)
//            
//            
//            for cat in relevantCategories/*.filter({ $0.appSuiteKey == nil })*/ {
//                if groups
//                    .flatMap({ $0.categories })
//                    .map({ $0.id })
//                    .contains(cat.id) {
//                        continue
//                    }
//                
//                if categories.map({ $0.id }).contains(cat.id) { continue }
//                
//                categories.append(cat)
//            }
//                                                
//            await fetchDashboard()
//            prepareData(calModel: calModel)
//        }
//    }
    
    var allCatsSelected: Bool {
        let groupCatIds = store.categoryGroups.flatMap { $0.categories.map { $0.id } }
        let groupMatches = store.categoryGroups.map { $0.id }.sorted() == self.groups.map { $0.id }.sorted()
        let catMatches = store.categories.filter { !groupCatIds.contains($0.id) }.map { $0.id }.sorted() == self.categories.filter { !groupCatIds.contains($0.id) }.map { $0.id }.sorted()
        return groupMatches && catMatches
    }
    
    
    @MainActor
    func initialFetchIfApplicable(calModel: CalendarModel) async {
        if !calModel.sMonth.isPlaceholder {
            self.payMethod = nil
            self.beginDate = Date().startDateOfMonth
            self.endDate = Date().endDateOfMonth
            
            for group in store.categoryGroups {
                let groupCatIds = group.categories.map { $0.id }
                let hasTrans = !calModel.sMonth.justTransactions
                    .filter ({ $0.active })
                    .filter ({ $0.amount != 0 && groupCatIds.contains($0.category?.id ?? "0") })
                    .isEmpty
                
                if hasTrans {
                    groups.append(group)
                }
            }
            
            //categoryGroups = catModel.categoryGroups
            
            let relevantCategories = calModel.sMonth.justTransactions
                .filter ({ $0.active })
                .filter ({ $0.amount != 0 && $0.category != nil })
                .compactMap ({ $0.category })
                //.filter ({ !$0.isIncome })
                .sorted(by: Helpers.categorySorter())
                .uniqued(on: \.id)
            
            
            for cat in relevantCategories/*.filter({ $0.appSuiteKey == nil })*/ {
                if groups
                    .flatMap({ $0.categories })
                    .map({ $0.id })
                    .contains(cat.id) {
                        continue
                    }
                
                if categories.map({ $0.id }).contains(cat.id) { continue }
                
                categories.append(cat)
            }
            
            let areThereTransWithNoCat = calModel.sMonth.justTransactions
                .filter ({ $0.active })
                .filter ({ $0.amount != 0 && $0.category == nil })
            
            if !areThereTransWithNoCat.isEmpty {
                if let theNil = store.categories.filter({ $0.isNil }).first {
                    categories.append(theNil)
                }
            }
            
            
            
            if isForSelectedMonth {
                localVersionOfServerCode(calModel: calModel)
            } else {
                await fetchDashboard()
            }
            
            prepareData(calModel: calModel)
        }
    }
    
    
    @MainActor
    func fetchIfChange(calModel: CalendarModel) {
        Task {
            if !categories.isEmpty || !groups.isEmpty {
                if changeHash != oldChangeHash {
                    oldChangeHash = changeHash
                    if isForSelectedMonth {
                        self.localVersionOfServerCode(calModel: calModel)
                    } else {
                        await self.fetchDashboard()
                    }
                    
                    
                    prepareData(calModel: calModel)
                }
            }
        }
        
    }
    
    
    @MainActor
    func fetchDashboard(file: String = #file, line: Int = #line, function: String = #function) async {
        //print("-- \(#function)")
        //print("-- \(#function) - \(file):\(line) : \(function)")
        if categories.isEmpty && groups.isEmpty {
            //AppState.shared.showAlert("Please select some categories first.")
            return
        }
        //print("Loading \(beginDate) to \(endDate)")
        isLoading = true
        let requestModel = DashboardRequestModel(
            beginDate: beginDate,
            endDate: endDate,
            categories: self.categories,
            categoryGroups: self.groups,
            payMethod: self.payMethod,
            payMethodIds: self.payMethodIds
        )
        
        /// Do networking.
        let model = RequestModel(requestType: "fetch_dashboard", model: requestModel)
        typealias ResultResponse = Result<DashboardData?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)

        switch await result {
        case .success(let model):
            if let model {
                withAnimation {
                    model.beginDate = self.beginDate
                    model.endDate = self.endDate
                    self.data = model
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
    
    
//    @MainActor
//    func prepareData(calModel: CalendarModel) {
//        let cats = self.categories + self.groups.flatMap(\.categories)
//        let trans = calModel.getTransactions(cats: cats)
//        transactions = TransactionHelper.All.Transactions.spend(from: trans)
//            .filter { $0.dateComponents?.month == calModel.sMonth.actualNum }
//            .filter { $0.dateComponents?.year == calModel.sMonth.year }
//                            
//        let newCumTotals = BudgetHelper.calculateCumTotals(
//            calModel: calModel,
//            transactions: transactions,
//            budgetAmount: calModel.sMonth.amount
//        )
//        
//        withAnimation {
//            self.cumTotals = newCumTotals
//        }
//    }
    
    
    
    
    @MainActor
    func prepareData(calModel: CalendarModel) {
        //print("-- \(#function)")
        let cats = self.categories + self.groups.flatMap(\.categories)

        let month = calModel.sMonth.actualNum
        let year = calModel.sMonth.year
        let budgetAmount = calModel.sMonth.amount

        let trans = calModel.getTransactions(meth: payMethod, cats: cats)
            .filter {
                $0.dateComponents?.month == month &&
                $0.dateComponents?.year == year
            }
        
        let days = calModel.sMonth.legitDays


        //self.transactions = filteredTransactions
        
        withAnimation {
            /// For the spending by day charts
            spendByDateTotals = BudgetHelper.calculateDailyAmount(
                days: days,
                transactions: trans,
                type: .spend
            )
        }
        
        /// For the cumulative spending chart
        Task {
            let newCumTotals = await Task.detached(priority: .userInitiated) {
                await BudgetHelper.calculateCumTotals(
                    days: days,
                    transactions: trans,
                    budgetAmount: budgetAmount,
                    type: .spend
                )
            }.value

            await MainActor.run {
                withAnimation {
                    self.cumTotals = newCumTotals
                }
            }
        }
    }
    
    
    @MainActor
    func localVersionOfServerCode(calModel: CalendarModel, file: String = #file, line: Int = #line, function: String = #function) {
        //print("-- \(#function)")
        //print("-- \(#function) - \(file):\(line) : \(function)")
        func buildData(for cat: CBCategory) -> CBCategory {
            let trans = transByCategory[cat.id] ?? []
            //let catData = CBCategory()
            
            let debit = DashboardAmounts()
            debit.regularIncome = TransactionHelper.Debit.Amount.regularIncome(from: trans)
            debit.irregularIncome = TransactionHelper.Debit.Amount.irregularIncome(from: trans)
            debit.totalSpend = TransactionHelper.Debit.Amount.totalSpend(from: trans) * -1
            debit.actualSpend = TransactionHelper.Debit.Amount.actualSpend(from: trans) * -1
            debit.actualSpendMinusRegularIncome = TransactionHelper.Debit.Amount.actualSpendMinusRegularIncome(from: trans) * -1
            debit.actualSpendMinusPayment = TransactionHelper.Debit.Amount.actualSpendMinusPayment(from: trans) * -1
            
            let credit = DashboardAmounts()
            credit.regularIncome = 0
            credit.irregularIncome = TransactionHelper.Credit.Amount.refundOrPerk(from: trans)
            credit.totalSpend = TransactionHelper.Credit.Amount.totalSpend(from: trans)
            credit.actualSpend = TransactionHelper.Credit.Amount.actualSpend(from: trans)
            credit.actualSpendMinusRegularIncome = 0
            credit.actualSpendMinusPayment = 0
            credit.creditPayment = TransactionHelper.Credit.Amount.payments(from: trans) * -1
            
            let all = DashboardAmounts()
            all.regularIncome = TransactionHelper.All.Amount.regularIncome(from: trans)
            all.irregularIncome = TransactionHelper.All.Amount.irregularIncome(from: trans)
            all.totalSpend = TransactionHelper.All.Amount.totalSpend(from: trans) * -1
            all.actualSpend = TransactionHelper.All.Amount.actualSpend(from: trans)
            all.actualSpendMinusRegularIncome = TransactionHelper.All.Amount.spendMinusRegularIncome(from: trans) * -1
            all.actualSpendMinusPayment = TransactionHelper.All.Amount.spendMinusPayments(from: trans) * -1
            
            /// Create a copy, otherwise we will end up with a reference to the original `store.categories`. When the categories get downloaded from the server, this can cause a data conflict.
            let catData = CBCategory()
            catData.id = cat.id
            catData.title = cat.title
            catData.amountString = cat.amount?.currencyWithDecimals()
            catData.color = cat.color
            catData.emoji = cat.emoji
            catData.active = cat.active
            catData.type = cat.type
            catData.listOrder = cat.listOrder
            catData.topTitles = cat.topTitles
            catData.isHidden = cat.isHidden
            catData.isNil = cat.isNil
            catData.debitAmounts = debit
            catData.creditAmounts = credit
            catData.allAmounts = all
            return catData
        }
        
        let allCats = (self.categories + self.groups.flatMap(\.categories)).uniqued(on: { $0.id })
        let transactions = calModel.getTransactions(meth: self.payMethod, cats: allCats, includeHiddenPaymentMethods: true)
        //let transCount = transactions.count
        let sMonth = calModel.sMonth
        
        let categoriesIds = self.categories.map(\.id)
        let groupsIds = self.groups.map(\.id)
        
        /// Budgets & Groups for the selected categories/groups
        let categoricalBudgets = sMonth.budgets.filter({ $0.type == .category && categoriesIds.contains($0.item?.id ?? "") })
        let groupBudgets = sMonth.budgets.filter({ $0.type == .categoryGroup && groupsIds.contains($0.item?.id ?? "") })
                        
        //let budget = sMonth.amount
        
        /// Budget amounts for the selected categories/groups
        let overallCategoricalBudgetAmount = categoricalBudgets.map({ $0.amount }).reduce(0, +)
        let overallGroupBudgetAmount = groupBudgets.map({ $0.amount }).reduce(0, +)
        let overallCatAndGroupBudgetAmount = overallCategoricalBudgetAmount + overallGroupBudgetAmount
        
        let transByCategory = Dictionary(grouping: transactions, by: \.category?.id)
        
        let allCatData: [CBCategory] = self.categories.map { cat in
            let catData = buildData(for: cat)
            
            /// Budget for the category
            let catBudget = categoricalBudgets.filter({ $0.item?.id == cat.id }).map({ $0.amount }).reduce(0, +)
            catData.budgetAmount = catBudget
            
            /// Variance
            catData.allAmounts?.variance = catBudget - ((catData.allAmounts?.totalSpend ?? 0) - (catData.allAmounts?.irregularIncome ?? 0))
            
            return catData
        }
        
        let allGroupData: [CBCategoryGroup] = self.groups.map { group in
            let groupCats: [CBCategory] = group.categories.map { cat in
                return buildData(for: cat)
            }
                    
            let allIncomeAmount = groupCats.map({ $0.allAmounts?.irregularIncome ?? 0 }).reduce(0, +)
            let allExpenseAmount = groupCats.map({ $0.allAmounts?.totalSpend ?? 0 }).reduce(0, +)
            let groupBudgetAmount = groupBudgets.filter({ $0.item?.id == group.id }).map({ $0.amount }).reduce(0, +)
            
            //print("\(group.title) - \(groupBudgetAmount)")
            
            let debit = DashboardAmounts()
            debit.regularIncome = groupCats.map({ $0.debitAmounts?.regularIncome ?? 0 }).reduce(0, +)
            debit.irregularIncome = groupCats.map({ $0.debitAmounts?.irregularIncome ?? 0 }).reduce(0, +)
            debit.totalSpend = groupCats.map({ $0.debitAmounts?.totalSpend ?? 0 }).reduce(0, +) * -1
            debit.actualSpend = groupCats.map({ $0.debitAmounts?.actualSpend ?? 0 }).reduce(0, +) * -1
            debit.actualSpendMinusRegularIncome = groupCats.map({ $0.debitAmounts?.actualSpendMinusRegularIncome ?? 0 }).reduce(0, +) * -1
            debit.actualSpendMinusPayment = groupCats.map({ $0.debitAmounts?.actualSpendMinusPayment ?? 0 }).reduce(0, +) * -1
            
            let credit = DashboardAmounts()
            credit.regularIncome = groupCats.map({ $0.creditAmounts?.regularIncome ?? 0 }).reduce(0, +)
            credit.irregularIncome = groupCats.map({ $0.creditAmounts?.irregularIncome ?? 0 }).reduce(0, +)
            credit.totalSpend = groupCats.map({ $0.creditAmounts?.totalSpend ?? 0 }).reduce(0, +) * -1
            credit.actualSpend = groupCats.map({ $0.creditAmounts?.actualSpend ?? 0 }).reduce(0, +) * -1
            credit.actualSpendMinusRegularIncome = groupCats.map({ $0.creditAmounts?.actualSpendMinusRegularIncome ?? 0 }).reduce(0, +) * -1
            credit.actualSpendMinusPayment = groupCats.map({ $0.creditAmounts?.actualSpendMinusPayment ?? 0 }).reduce(0, +) * -1
            credit.creditPayment = groupCats.map({ $0.creditAmounts?.creditPayment ?? 0 }).reduce(0, +) * -1
            
            let all = DashboardAmounts()
            all.regularIncome = groupCats.map({ $0.allAmounts?.regularIncome ?? 0 }).reduce(0, +)
            all.irregularIncome = groupCats.map({ $0.allAmounts?.irregularIncome ?? 0 }).reduce(0, +)
            all.totalSpend = groupCats.map({ $0.allAmounts?.totalSpend ?? 0 }).reduce(0, +)
            all.actualSpend = groupCats.map({ $0.allAmounts?.actualSpend ?? 0 }).reduce(0, +)
            all.actualSpendMinusRegularIncome = groupCats.map({ $0.allAmounts?.actualSpendMinusRegularIncome ?? 0 }).reduce(0, +) * -1
            all.actualSpendMinusPayment = groupCats.map({ $0.allAmounts?.actualSpendMinusPayment ?? 0 }).reduce(0, +) * -1
            all.variance = groupBudgetAmount - (allExpenseAmount - allIncomeAmount)
            
            

            /// Create a copy, otherwise we will end up with a reference to the original `store.categoryGroups`. When the groups get downloaded from the server, this can cause a data conflict.
            let newGroup = CBCategoryGroup()
            newGroup.categories = groupCats
            newGroup.id = group.id
            newGroup.title = group.title
            newGroup.amountString = group.amount?.currencyWithDecimals()
            //newGroup.categories = group.categories
            newGroup.budgetAmount = groupBudgetAmount
            newGroup.debitAmounts = debit
            newGroup.creditAmounts = credit
            newGroup.allAmounts = all
            return newGroup
        }
        
        
        let final = DashboardData()
        final.budget = sMonth.amount
        final.categoryAndGroupBudget = overallCatAndGroupBudgetAmount
        
        let debit = DashboardAmounts()
        debit.regularIncome = TransactionHelper.Debit.Amount.regularIncome(from: transactions)
        debit.irregularIncome = TransactionHelper.Debit.Amount.irregularIncome(from: transactions)
        debit.totalSpend = TransactionHelper.Debit.Amount.totalSpend(from: transactions) * -1
        debit.actualSpend = TransactionHelper.Debit.Amount.actualSpend(from: transactions) * -1
        debit.actualSpendMinusRegularIncome = TransactionHelper.Debit.Amount.actualSpendMinusRegularIncome(from: transactions) * -1
        debit.actualSpendMinusPayment = TransactionHelper.Debit.Amount.actualSpendMinusPayment(from: transactions) * -1
        
        let credit = DashboardAmounts()
        credit.regularIncome = 0
        credit.irregularIncome = TransactionHelper.Credit.Amount.refundOrPerk(from: transactions)
        credit.totalSpend = TransactionHelper.Credit.Amount.totalSpend(from: transactions) * -1
        credit.actualSpend = TransactionHelper.Credit.Amount.actualSpend(from: transactions)
        credit.actualSpendMinusRegularIncome = 0
        credit.actualSpendMinusPayment = TransactionHelper.Credit.Amount.actualSpendMinusPayment(from: transactions)
        credit.creditPayment = TransactionHelper.Credit.Amount.payments(from: transactions) * -1
        
        let all = DashboardAmounts()
        all.regularIncome = TransactionHelper.All.Amount.regularIncome(from: transactions)
        all.irregularIncome = TransactionHelper.All.Amount.irregularIncome(from: transactions)
        all.totalSpend = TransactionHelper.All.Amount.totalSpend(from: transactions) * -1
        all.actualSpend = TransactionHelper.All.Amount.actualSpend(from: transactions)
        all.actualSpendMinusRegularIncome = TransactionHelper.All.Amount.spendMinusRegularIncome(from: transactions) * -1
        all.actualSpendMinusPayment = TransactionHelper.All.Amount.spendMinusPayments(from: transactions) * -1
        
        final.debitAmounts = debit
        final.creditAmounts = credit
        final.allAmounts = all
        final.categoryGroups = allGroupData
        final.categories = allCatData
        
        
        withAnimation {
            final.beginDate = self.beginDate
            final.endDate = self.endDate
            self.data = final
        }
        
        for each in allGroupData {
            if let index = self.data.categoryGroups.firstIndex(where: {$0.id == each.id}) {
                self.data.categoryGroups[index].budgetAmount = each.budgetAmount
            }
        }
    }
}





extension DashboardModel {
    private func appStorageGetter<T: Decodable>(_ keyPath: KeyPath<DashboardModel, T>, key: String, default defaultValue: T) -> T {
        access(keyPath: keyPath)
        if let data = UserDefaults.standard.data(forKey: key) {
            return try! JSONDecoder().decode(T.self, from: data)
        } else {
            return defaultValue
        }
    }
    
    private func appStorageSetter<T: Encodable>(_ keyPath: KeyPath<DashboardModel, T>, key: String, new: T) {
        withMutation(keyPath: keyPath) {
            let data = try? JSONEncoder().encode(new)
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}



