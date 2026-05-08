//
//  Dashboard.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/21/26.
//

import SwiftUI
import Charts

struct DashboardUtils {
    static func summarizeCategories(_ categories: [CBCategory]) -> [CBCategory] {
        let groupedCats = Dictionary(grouping: categories, by: \.id)

        return groupedCats.values.map { related in
            let new = CBCategory()
            new.setFromAnotherInstance(category: related[0])

            new.allAmounts = DashboardAmounts()
            new.debitAmounts = DashboardAmounts()
            new.creditAmounts = DashboardAmounts()

            new.budgetAmount = related.map { $0.budgetAmount }.reduce(0.0, +)

            for cat in related {
                new.allAmounts?.add(cat.allAmounts)
                new.debitAmounts?.add(cat.debitAmounts)
                new.creditAmounts?.add(cat.creditAmounts)
            }

            return new
        }
        .sorted(by: Helpers.categorySorter())
    }

    static func summarizeGroups(_ groups: [CBCategoryGroup]) -> [CBCategoryGroup] {
        let groupedGroups = Dictionary(grouping: groups, by: \.id)

        return groupedGroups.values.map { relatedGroups in
            let newGroup = CBCategoryGroup()
            newGroup.setFromAnotherInstance(group: relatedGroups[0])

            newGroup.allAmounts = DashboardAmounts()
            newGroup.debitAmounts = DashboardAmounts()
            newGroup.creditAmounts = DashboardAmounts()

            newGroup.budgetAmount = relatedGroups.map { $0.budgetAmount }.reduce(0.0, +)

            for group in relatedGroups {
                newGroup.allAmounts?.add(group.allAmounts)
                newGroup.debitAmounts?.add(group.debitAmounts)
                newGroup.creditAmounts?.add(group.creditAmounts)
            }

            newGroup.categories = summarizeCategories(
                relatedGroups.flatMap(\.categories)
            )

            return newGroup
        }
    }

    static func incomeAmount(for cat: CBCategory) -> Double {
        if cat.isRegularIncome {
            return cat.allAmounts?.regularIncome ?? 0.0
        } else {
            return cat.allAmounts?.irregularIncome ?? 0.0
        }
    }

    static func categoryOwningXRange(
        selectedXAmount: Double,
        categories: [CBCategory],
        amountForCategory: (CBCategory) -> Double
    ) -> CBCategory? {
        var runningTotal = 0.0
        
        for category in categories {
            let amount = amountForCategory(category)
            
            guard amount > 0 else { continue }
            
            let start = runningTotal
            let end = runningTotal + amount
            
            if selectedXAmount >= start && selectedXAmount < end {
                return category
            }
            
            runningTotal = end
        }
        
        return nil
    }
}


enum DashboardMontlyOrQuarterlyBreakdowns: String, CaseIterable {
    case monthly = "Month"
    case quarterly = "Quarter"
}

protocol DashboardBreakdownSummary {
    var title: String { get }
    var date: Date { get }
    var budgetAmount: Double { get }
    var allAmounts: DashboardAmounts? { get }
    var flatCats: [CBCategory] { get }
}


enum DashboardNavDest {
    case numericBreakdown, transactionList
}


struct DashboardDataByQuarter: Hashable, Identifiable, DashboardBreakdownSummary {
    var id: String { "Q\(quarter)-\(year)" }

    var quarter: Int
    var year: Int
    var months: [DashboardDataByMonth]

    var budgetAmount: Double
    var debitAmounts: DashboardAmounts?
    var creditAmounts: DashboardAmounts?
    var allAmounts: DashboardAmounts?
    var categories: [CBCategory]
    var categoryGroups: [CBCategoryGroup]
    var flatCats: [CBCategory]

    init(
        quarter: Int,
        year: Int,
        months: [DashboardDataByMonth]
    ) {
        self.quarter = quarter
        self.year = year
        self.months = months

        self.budgetAmount = months.reduce(0) { $0 + $1.budgetAmount }
        self.debitAmounts = DashboardDataByQuarter.summarizeAmounts(months.map(\.debitAmounts))
        self.creditAmounts = DashboardDataByQuarter.summarizeAmounts(months.map(\.creditAmounts))
        self.allAmounts = DashboardDataByQuarter.summarizeAmounts(months.map(\.allAmounts))

        self.categories = DashboardUtils.summarizeCategories(months.flatMap(\.categories))
        self.categoryGroups = DashboardUtils.summarizeGroups(months.flatMap(\.categoryGroups))

        self.flatCats = (categories + categoryGroups.flatMap(\.categories))
            .uniqued(on: { $0.id })
            .sorted(by: Helpers.categorySorter())
    }

    private static func summarizeAmounts(_ amounts: [DashboardAmounts?]) -> DashboardAmounts {
        let result = DashboardAmounts()
        amounts.forEach { result.add($0) }
        return result
    }

    var title: String {
        "Q\(quarter) \(year)"
    }

    var date: Date {
        Helpers.createDate(month: startingMonth, year: year)!
    }

    private var startingMonth: Int {
        switch quarter {
        case 1: 1
        case 2: 4
        case 3: 7
        case 4: 10
        default: 1
        }
    }

    var endDate: Date {
        Calendar.current.date(byAdding: .month, value: 3, to: date)!
    }
}


struct DashboardDataByMonth: Hashable, Identifiable, Decodable, Equatable, DashboardBreakdownSummary {
    var id: String { "\(month)-\(year)" }
    var categories: [CBCategory] = []
    var categoryGroups: [CBCategoryGroup] = []
    var budgetAmount: Double = 0.0
    var debitAmounts: DashboardAmounts?
    var creditAmounts: DashboardAmounts?
    var allAmounts: DashboardAmounts?
    var month: Int
    var year: Int
    var date: Date {
        Helpers.createDate(month: month, year: year)!
    }
    
    var title: String {

        "\(DateFormatter.monthFull.string(from: date)) \(year)"

    }
//    var expenseCategories: [CBCategory] { flatCats.filter { !$0.isIncome && $0.allAmounts?.actualSpend ?? 0 > 0 } }
//    var incomeCategories: [CBCategory] {
//        //categories.filter { $0.isIncome || ($0.allAmounts?.actualSpend ?? 0.0) < 0 }
//        flatCats.filter { $0.isIncome || ($0.debitAmounts?.regularIncome ?? 0.0) > 0 || ($0.debitAmounts?.irregularIncome ?? 0.0) > 0 }
//    }
//    
//    var flatCats: [CBCategory] {
//        return (categories + categoryGroups.flatMap(\.categories))
//            //.filter { $0.type != XrefModel.getItem(from: .categoryTypes, byEnumID: .income) }
//            .uniqued(on: { $0.id })
//            .sorted(by: Helpers.categorySorter())
//    }
    
    var flatCats: [CBCategory]
    var expenseCategories: [CBCategory]
    var incomeCategories: [CBCategory]
    
    
    enum CodingKeys: CodingKey { case categories, category_groups, month, year, budget_amount, debit_amounts, credit_amounts, all_amounts }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.month = try container.decode(Int.self, forKey: .month)
        self.year = try container.decode(Int.self, forKey: .year)
        self.categories = try container.decode([CBCategory].self, forKey: .categories)
        self.categoryGroups = try container.decode([CBCategoryGroup].self, forKey: .category_groups)
        self.budgetAmount = try container.decodeIfPresent(Double.self, forKey: .budget_amount) ?? 0.0
        self.debitAmounts = try container.decodeIfPresent(DashboardAmounts.self, forKey: .debit_amounts)
        self.creditAmounts = try container.decodeIfPresent(DashboardAmounts.self, forKey: .credit_amounts)
        self.allAmounts = try container.decodeIfPresent(DashboardAmounts.self, forKey: .all_amounts)
        
        let flatCats = (categories + categoryGroups.flatMap(\.categories))
            .uniqued(on: { $0.id })
            .sorted(by: Helpers.categorySorter())
        self.flatCats = flatCats
        
        self.expenseCategories = flatCats.filter { !$0.isIncome && $0.allAmounts?.actualSpend ?? 0 > 0 }
        self.incomeCategories = flatCats.filter { $0.isIncome || ($0.debitAmounts?.regularIncome ?? 0.0) > 0 || ($0.debitAmounts?.irregularIncome ?? 0.0) > 0 }
    }
    
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(month)
//        hasher.combine(year)
//        hasher.combine(categories)
//        hasher.combine(categoryGroups)
//        hasher.combine(budgetAmount)
//        hasher.combine(debitAmounts)
//        hasher.combine(creditAmounts)
//        hasher.combine(allAmounts)
//    }
    
    var quarter: Int {
        ((month - 1) / 3) + 1
    }
}


@Observable
class DashboardAmounts: Decodable, Hashable, Equatable {
    var regularIncome: Double = 0.0 /// Salary, calculated by any category that is of type "income".
    var irregularIncome: Double = 0.0 /// Reimbursements, refunds, gifts, etc.
    var actualIncome: Double = 0.0
    
    var totalSpend: Double = 0.0 /// Any normal expenses
    var actualSpend: Double = 0.0 /// actual spending (totalSpend - irregularIncome)
    var actualSpendMinusRegularIncome: Double = 0.0 /// left over money between salary and expenses
    var actualSpendMinusPayment: Double = 0.0
    
    var creditPayment: Double?
    
    var variance: Double?
    
    init() {
        self.regularIncome = 0.0
        self.irregularIncome = 0.0
        self.totalSpend = 0.0
        self.actualSpend = 0.0
        self.actualSpendMinusRegularIncome = 0.0
        self.actualSpendMinusPayment = 0.0
        self.variance = nil
    }
    
    enum CodingKeys: CodingKey { case regular_income, irregular_income, actual_income, total_spend, actual_spend, actual_spend_minus_regular_income, actual_spend_minus_payment, variance, credit_payment }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
                        
        self.regularIncome = try container.decode(Double.self, forKey: .regular_income)
        self.irregularIncome = try container.decode(Double.self, forKey: .irregular_income)
        self.actualIncome = try container.decodeIfPresent(Double.self, forKey: .actual_income) ?? 0.0
        
        self.totalSpend = try container.decode(Double.self, forKey: .total_spend)
        self.actualSpend = try container.decode(Double.self, forKey: .actual_spend)
        self.actualSpendMinusRegularIncome = try container.decode(Double.self, forKey: .actual_spend_minus_regular_income)
        self.actualSpendMinusPayment = try container.decode(Double.self, forKey: .actual_spend_minus_payment)
        
        self.variance = try container.decodeIfPresent(Double.self, forKey: .variance)
        self.creditPayment = try container.decodeIfPresent(Double.self, forKey: .credit_payment)
    }
    
    convenience init(copying other: DashboardAmounts?) {
        self.init()
        self.add(other)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(regularIncome)
        hasher.combine(irregularIncome)
        hasher.combine(actualIncome)
        hasher.combine(totalSpend)
        hasher.combine(actualSpend)
        hasher.combine(actualSpendMinusRegularIncome)
        hasher.combine(actualSpendMinusPayment)
        hasher.combine(creditPayment)
        hasher.combine(variance)
    }
    
    static func == (lhs: DashboardAmounts, rhs: DashboardAmounts) -> Bool {
        lhs.regularIncome == rhs.regularIncome &&
        lhs.irregularIncome == rhs.irregularIncome &&
        lhs.actualIncome == rhs.actualIncome &&
        lhs.totalSpend == rhs.totalSpend &&
        lhs.actualSpend == rhs.actualSpend &&
        lhs.actualSpendMinusRegularIncome == rhs.actualSpendMinusRegularIncome &&
        lhs.actualSpendMinusPayment == rhs.actualSpendMinusPayment &&
        lhs.creditPayment == rhs.creditPayment &&
        lhs.variance == rhs.variance
    }
    
    func add(_ other: DashboardAmounts?) {
        guard let other else { return }
        regularIncome += other.regularIncome
        irregularIncome += other.irregularIncome
        actualIncome += other.actualIncome
        totalSpend += other.totalSpend
        actualSpend += other.actualSpend
        actualSpendMinusRegularIncome += other.actualSpendMinusRegularIncome
        actualSpendMinusPayment += other.actualSpendMinusPayment
        creditPayment = (creditPayment ?? 0) + (other.creditPayment ?? 0)
        variance = (variance ?? 0) + (other.variance ?? 0)
    }
}


struct DashboardRequestModel: Encodable {
    var beginDate: Date
    var endDate: Date
    var categories: [CBCategory]
    var categoryGroups: [CBCategoryGroup]
    
    enum CodingKeys: CodingKey { case categories, category_groups, user_id, account_id, device_uuid, begin_date, end_date }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(categories, forKey: .categories)
        try container.encode(categoryGroups, forKey: .category_groups)
        try container.encode(beginDate.string(to: .serverDate), forKey: .begin_date)
        try container.encode(endDate.string(to: .serverDate), forKey: .end_date)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
    }
}


@Observable
class DashboardData: Decodable, Hashable {
    var beginDate: Date = Date().startDateOfMonth
    var endDate: Date = Date().endDateOfMonth
    
    var budgetAmount: Double = 0.0
    var debitAmounts: DashboardAmounts = DashboardAmounts()
    var creditAmounts: DashboardAmounts = DashboardAmounts()
    var allAmounts: DashboardAmounts = DashboardAmounts()
    
    var categories: [CBCategory] = []
    var categoryGroups: [CBCategoryGroup] = []
    var monthlyBreakdowns: [DashboardDataByMonth] = [] {
        didSet {
            quarterlyBreakdowns = Self.makeQuarterlyBreakdowns(from: monthlyBreakdowns)
        }
    }
    
    
    var breakdownType: DashboardMontlyOrQuarterlyBreakdowns = .monthly
    
    
    private(set) var quarterlyBreakdowns: [DashboardDataByQuarter] = []

    static func makeQuarterlyBreakdowns(
        from monthlyBreakdowns: [DashboardDataByMonth]
    ) -> [DashboardDataByQuarter] {
        let grouped = Dictionary(grouping: monthlyBreakdowns) { monthData in
            "\(monthData.year)-\(monthData.quarter)"
        }

        return grouped.values.map { months in
            let months = months.sorted { $0.date < $1.date }
            let first = months[0]
            return DashboardDataByQuarter(
                quarter: first.quarter,
                year: first.year,
                months: months
            )
        }
        .sorted { $0.date < $1.date }
    }
    
    var monthSpan: Int {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.month], from: beginDate, to: endDate)
        return comps.month ?? 0
    }
  
    init() {}
    
    enum CodingKeys: CodingKey { case categories, category_groups, user_id, account_id, device_uuid, begin_date, end_date, budget_amount, debit_amounts, credit_amounts, all_amounts, monthly_breakdowns }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.budgetAmount = try container.decode(Double.self, forKey: .budget_amount)
        self.debitAmounts = try container.decode(DashboardAmounts.self, forKey: .debit_amounts)
        self.creditAmounts = try container.decode(DashboardAmounts.self, forKey: .credit_amounts)
        self.allAmounts = try container.decode(DashboardAmounts.self, forKey: .all_amounts)
        self.monthlyBreakdowns = try container.decode([DashboardDataByMonth].self, forKey: .monthly_breakdowns)
        self.categories = DashboardUtils.summarizeCategories(monthlyBreakdowns.flatMap(\.categories))
        self.categoryGroups = DashboardUtils.summarizeGroups(monthlyBreakdowns.flatMap(\.categoryGroups))
    }
    
    static func == (lhs: DashboardData, rhs: DashboardData) -> Bool {
        lhs.beginDate == rhs.beginDate &&
        lhs.endDate == rhs.endDate &&
        lhs.budgetAmount == rhs.budgetAmount &&
        lhs.debitAmounts == rhs.debitAmounts &&
        lhs.creditAmounts == rhs.creditAmounts &&
        lhs.allAmounts == rhs.allAmounts &&
        lhs.categories == rhs.categories &&
        lhs.categoryGroups == rhs.categoryGroups &&
        lhs.monthlyBreakdowns == rhs.monthlyBreakdowns
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(beginDate)
        hasher.combine(endDate)
        hasher.combine(budgetAmount)
        hasher.combine(debitAmounts)
        hasher.combine(creditAmounts)
        hasher.combine(allAmounts)
        hasher.combine(categories)
        hasher.combine(categoryGroups)
        hasher.combine(monthlyBreakdowns)
    }
}


@Observable
class DashboardModel {
    //var shouldUseTotalSpending: Bool = false
    
    @ObservationIgnored private let store: AppStore
    init(store: AppStore) {
        self.store = store
    }        
    
    public var shouldUseTotalSpending: Bool {
        get { appStorageGetter(\.shouldUseTotalSpending, key: "dashboardShouldUseTotalSpending", default: false) }
        set { appStorageSetter(\.shouldUseTotalSpending, key: "dashboardShouldUseTotalSpending", new: newValue) }
    }
    
    public var shouldUseTotalIncome: Bool {
        get { appStorageGetter(\.shouldUseTotalIncome, key: "dashboardShouldUseTotalIncome", default: false) }
        set { appStorageSetter(\.shouldUseTotalIncome, key: "dashboardShouldUseTotalIncome", new: newValue) }
    }
    
    
    var beginDate: Date = Date().startDateOfMonth
    var endDate: Date = Date().endDateOfMonth
    var categories: [CBCategory] = []
    var groups: [CBCategoryGroup] = []
    
    var data = DashboardData()
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
        data.budgetAmount >= (shouldUseTotalSpending ? data.allAmounts.totalSpend : data.allAmounts.actualSpend)
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
        
        let startDay = calendar.component(.day, from: start)
        let startMonth = calendar.component(.month, from: start)
        let startYear = calendar.component(.year, from: start)
        
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
        
        /// Fallback
        return "\(start.string(to: .datePickerDateOnlyDefault)) - \(end.string(to: .datePickerDateOnlyDefault))"
    }
    
    
    @MainActor
    var isAnalyzingAtLeastOneCreditCategory: Bool {
        self.categories
            .filter { $0.type.enumID == XrefModel.getItem(from: .categoryTypes, byEnumID: .payment).enumID }
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
    
    
    @MainActor
    func initialFetchIfApplicable(calModel: CalendarModel, catModel: CategoryModel) async {
        if !calModel.sMonth.isPlaceholder {
            for group in catModel.categoryGroups {
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
                                                
            await fetchDashboard()
        }
//        else {
//            AppState.shared.showAlert("Could not fetch dashboard. (Broke cal ref)")
//        }
        
    }
    
    
    func fetchIfChange() {
        if !categories.isEmpty || !groups.isEmpty {
            if changeHash != oldChangeHash {
                oldChangeHash = changeHash
                Task {
                    await self.fetchDashboard()
                }
            }
        }
    }
    
    
    @MainActor
    func fetchDashboard() async {
        if categories.isEmpty && groups.isEmpty {
            //AppState.shared.showAlert("Please select some categories first.")
            return
        }
        print("Loading \(beginDate) to \(endDate)")
        isLoading = true
        let requestModel = DashboardRequestModel(
            beginDate: beginDate,
            endDate: endDate,
            categories: self.categories,
            categoryGroups: self.groups
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










struct Dashboard: View {
    //private enum WhichView: String { case overview, categories }
    //@AppStorage("categoryInsightSheetViewMode") private var whichView: WhichView = .overview
    //@AppStorage("CategoryInsightsOnlyUntilToday") private var onlyUpUntilToday = false
    
    
    @Environment(\.colorScheme) var colorScheme
    #if os(macOS)
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appearsActive) var appearsActive
    #endif
    
    //@Local(\.colorTheme) var colorTheme
    @Environment(CalendarProps.self) private var calProps
    @Environment(CalendarModel.self) private var calModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(PayMethodModel.self) private var payModel
    
    #if os(iOS)
    @Binding var navPath: [CalendarNavDest]
    #else
    @State private var navPath: [CalendarNavDest] = []
    #endif
    @Binding var showAnalysisSheet: Bool
    @Bindable var model: DashboardModel
    var isForSelectedMonth: Bool
    
    @State private var showCategorySheet = false
    @State private var showOptionsSheet = false
    
    
    var body: some View {
        @Bindable var calModel = calModel
        content
            .navigationTitle("Dashboard\(AppState.shared.devMode ? " (Dev)" : "")")
            .if(!isForSelectedMonth) {
                $0.navigationSubtitle("\(model.formattedDateRange)")
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(isForSelectedMonth ? .inline : .large)
            //.navigationBarTitleDisplayMode(.inline)
            #endif
            .task {
                model.oldChangeHash = model.changeHash
            }
            .toolbar {
                DashboardToolbar(
                    model: model,
                    showCategorySheet: $showCategorySheet,
                    showAnalysisSheet: $showAnalysisSheet,
                    navPath: $navPath,
                    isForSelectedMonth: isForSelectedMonth
                )
            }
            .sheet(isPresented: $model.showOptionsSheet, onDismiss: model.fetchIfChange) {
                DashboardOptionsSheet(model: model, isForSelectedMonth: isForSelectedMonth)
                    .interactiveDismissDisabled(true)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showCategorySheet, onDismiss: model.fetchIfChange) {
                MultiCategorySheet(
                    categories: $model.categories,
                    categoryGroups: $model.groups
                )
                #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
                #endif
            }
    }
    
    
    @ViewBuilder
    var content: some View {
        if model.categories.isEmpty && model.groups.isEmpty {
            contentUnavailableView
        } else {
            ScrollView {
                VStack(spacing: 24) {
                    if isForSelectedMonth {
                        DashboardWidget(title: "Net Worth") {
                            DashboardNetWorthChange()
                        }
                    }
                    
                    if AppState.shared.isIphone {
                        DashboardDetailSection(model: model, data: model.data)
                    } else {
                        NavigationStack(path: $navPath) {
                            DashboardDetailSection(model: model, data: model.data)
                        }
                    }
                    
                    DashboardWidget(title: "Activity By Category") {
                        DashboardActivityByCategoryChart(model: model, data: model.data, isForSelectedMonth: isForSelectedMonth)
                    }
                                                                            
                    if model.data.monthlyBreakdowns.count > 1 {
                        DashboardActivityByMonthChart(model: model, data: model.data)
                    }
                    
                    DashboardWidget(title: "Breakdown") {
                        DashboardExpenseByCategoryTable(model: model, navPath: $navPath)
                    }
                }
                .scenePadding()
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
        }
    }
    

    var contentUnavailableView: some View {
        ContentUnavailableView {
            Label {
                Text("No Categories Selected")
            } icon: {
                Image(systemName: "books.vertical")
            }
        } description: {
            Text("Select some categories to view insights.")
        } actions: {
            Button {
                showCategorySheet = true
            } label: {
                Text("Select Categories")
                    .padding(4)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}


fileprivate struct DashboardToolbar: ToolbarContent {
    @Environment(CalendarModel.self) private var calModel
    
    @Bindable var model: DashboardModel
    @Binding var showCategorySheet: Bool
    @Binding var showAnalysisSheet: Bool
    @Binding var navPath: [CalendarNavDest]
    var isForSelectedMonth: Bool
    
    //@ToolbarContentBuilder
    var body: some ToolbarContent {
        #if os(iOS)
                
        if AppState.shared.isIpad {
            ToolbarItem(placement: .topBarLeading) { showCategorySheetButton }
            ToolbarSpacer(.fixed, placement: .topBarLeading)
        }
        
//        if !isForSelectedMonth {
//            ToolbarItem(placement: .topBarLeading) { showOptionsSheetButton }
//        }
        
        
        if AppState.shared.isIpad {
            ToolbarItem(placement: .topBarTrailing) { closeButton }
        } else {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await model.fetchDashboard()
                    }
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .symbolEffect(.rotate, options: SymbolEffectOptions.repeat(.continuous).speed(3), isActive: model.isLoading)
                }
                .tint(.none)
                .disabled(model.isLoading)
            }
            ToolbarItem(placement: .topBarTrailing) { showCategorySheetButton }
            
            //if !isForSelectedMonth {
                ToolbarItem(placement: .topBarTrailing) { showOptionsSheetButton }
            //}
        }

        if isForSelectedMonth {
            //ToolbarSpacer(.fixed, placement: .topBarLeading)
            if !model.categories.isEmpty || !model.groups.isEmpty {
                ToolbarItem(placement: .bottomBar) { showCalendarButton }
                //ToolbarSpacer(.fixed, placement: .topBarLeading)
            }
        }
        
        
        #else
        ToolbarItemGroup(placement: .destructiveAction) {
            HStack {
                showCategorySheetButton
                showMonthsButton
            }
        }
        
        ToolbarItemGroup(placement: .confirmationAction) {
            HStack {
                closeButton
            }
        }
        
        #endif
    }
    
    
    var showCategorySheetButton: some View {
        Button {
            showCategorySheet = true
        } label: {
            Label {
                Text("Select Categories")
            } icon: {
                Image(systemName: "books.vertical")
            }
        }
        .tint(.none)
        #if os(macOS)
        .buttonStyle(.roundMacButton)
        #endif
    }
    
    
    var showOptionsSheetButton: some View {
        Button {
            model.showOptionsSheet = true
        } label: {
            Image(systemName: "ellipsis")
            //Text("\(model.formattedDateRange)")
        }
        .tint(.none)
        #if os(macOS)
        .buttonStyle(.roundMacButton)
        #endif
    }
    
    
    var showCalendarButton: some View {
        Button {
            withAnimation {
                calModel.sCategories = (model.categories + model.groups.flatMap { $0.categories }).uniqued(on: { $0.id })
                calModel.sPayMethod = nil
            }
                                    
            #if os(iOS)
            if AppState.shared.isIphone {
                navPath.removeLast()
            }
            #else
            //dismiss()
            #endif
            
        } label: {
            Text("View Filtered Calendar")
//            Label {
//                Text("View Filtered Calendar")
//            } icon: {
//                Image(systemName: "calendar")
//            }
        }
        .tint(.none)
    }
    
    
    var closeButton: some View {
        Button {
            #if os(iOS)
            withAnimation {
                calModel.isInMultiSelectMode = false
                showAnalysisSheet = false
            }
            #else
            dismiss()
            #endif
        } label: {
            Image(systemName: "xmark")
        }
        .tint(.none)
        #if os(macOS)
        .buttonStyle(.roundMacButton)
        #endif
    }
}


fileprivate struct DashboardOptionsSheet: View {
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: DashboardModel
    var isForSelectedMonth: Bool
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Spending Display Type", selection: $model.shouldUseTotalSpending.animation()) {
                        Text("Actual").tag(false)
                        Text("Total").tag(true)
                    }
                } footer: {
                    Text("Choose whether to show the actual spending or the total spending. Actual Spending is your spending, offset by any money that came in.")
                }
                
                if !isForSelectedMonth {
                    Section("Date Range") {
                        DatePicker("Begin Date", selection: $model.beginDate, displayedComponents: [.date])
                        DatePicker("End Date", selection: $model.endDate, in: model.beginDate..., displayedComponents: [.date])
                        
                        ScrollView(.horizontal) {
                            HStack {
                                //                        Button("Selected Month") {
                                //                            model.beginDate = calModel.sMonth.days.first(where: { !$0.isPlaceholder })?.date ?? Date()
                                //                            model.endDate = calModel.sMonth.days.last?.date ?? Date()
                                //                        }
                                
                                let currentMonthName = NavDestination.getMonthFromInt(AppState.shared.todayMonth)?.displayName
                                Button("\(currentMonthName ?? "N/A") \(String(AppState.shared.todayYear))") {
                                    let now = Date()
                                    model.beginDate = now.startDateOfMonth
                                    model.endDate = now.endDateOfMonth
                                }
                                
                                Button("YTD") {
                                    let now = Date()
                                    model.beginDate = now.startDateOfYear
                                    model.endDate = now
                                }
                                
                                Button("This Quarter") {
                                    let now = Date()
                                    model.beginDate = now.startDateOfQuarter
                                    model.endDate = now.endDateOfQuarter
                                }
                                
                                Button(String(AppState.shared.todayYear)) {
                                    let now = Date()
                                    model.beginDate = now.startDateOfYear
                                    model.endDate = now.endDateOfYear
                                }
                                
                                ForEach(1...4, id: \.self) { q in
                                    Button("Q\(q)") {
                                        let now = Date()
                                        let range = now.datesForQuarter(q)
                                        model.beginDate = range.start
                                        model.endDate = range.end
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .contentMargins(.bottom, -10, for: .scrollIndicators)
                    }
                }
                
                
            }
            //.listStyle(.)
            //.padding()
            .navigationTitle("Dashboard Options")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        #if os(iOS)
                        withAnimation {
                            model.showOptionsSheet = false
                        }
                        #else
                        dismiss()
                        #endif
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .tint(.none)
                    #if os(macOS)
                    .buttonStyle(.roundMacButton)
                    #endif
                }
            }
        }
    }
}


fileprivate struct DashboardDetailSection: View {
    @Bindable var model: DashboardModel
    @Bindable var data: DashboardData
        
    var body: some View {
        DashboardWidget {
            NavigationLink(value: CalendarNavDest.dashboardNumericBreakdown) {
                HStack {
                    Grid(alignment: .leading) {
                        GridRow {
                            Text("Spending")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)
                            
                            Text("Income")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)
                            
                            Text("Credit Payments")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)
                        }
                        .bold()
                        
                        Divider()
                        
                        GridRow {
                            Text((model.shouldUseTotalSpending ? data.allAmounts.totalSpend : data.allAmounts.actualSpend).currencyWithDecimals())
                                .contentTransition(.numericText())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)
                                .bold()
                            
                            Text((data.debitAmounts.regularIncome + data.debitAmounts.irregularIncome).currencyWithDecimals())
                                .contentTransition(.numericText())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)
                            
                            Text((data.creditAmounts.creditPayment ?? 0.0).currencyWithDecimals())
                                .contentTransition(.numericText())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)
                        }
                    }
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                }
                
            }
            .schemeBasedForegroundStyle()
        }
    }
}


fileprivate struct DashboardChartLegend: View {
    @Environment(CalendarModel.self) private var calModel
    @Bindable var data: DashboardData
    
    var categories: [CBCategory] {
        return (data.categories + data.categoryGroups.flatMap { $0.categories })
            .sorted(by: Helpers.categorySorter())
            .uniqued(on: { $0.id })
    }
    
    var body: some View {
        ScrollView(.horizontal) {
            ZStack {
                Spacer()
                    .containerRelativeFrame([.horizontal])
                    .frame(height: 1)
                                            
                HStack(spacing: 0) {
                    ForEach(categories) { cat in
                        HStack(alignment: .circleAndTitle, spacing: 5) {
                            //Text("\(item.category.active)")
                            Circle()
                                .fill(cat.color)
                                .frame(maxWidth: 8, maxHeight: 8) // 8 seems to be the default from charts
                                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(cat.title)
                                    .foregroundStyle(Color.secondary)
                                    .font(.caption2)
                                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                            }
                        }
                        .padding(.horizontal, 4)
                        .contentShape(Rectangle())
                    }
                    Spacer()
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .contentMargins(.vertical, 10, for: .scrollContent)
    }
    
//    var body: some View {
//        ScrollView {
//            ZStack {
////                Spacer()
////                    .containerRelativeFrame([.horizontal])
////                    .frame(height: 1)
//                                            
//                VStack(alignment: .leading, spacing: 5) {
//                    ForEach(categories) { cat in
//                        HStack(alignment: .circleAndTitle, spacing: 5) {
//                            //Text("\(item.category.active)")
//                            Circle()
//                                .fill(cat.color)
//                                .frame(maxWidth: 8, maxHeight: 8) // 8 seems to be the default from charts
//                                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                            
//                            VStack(alignment: .leading, spacing: 2) {
//                                Text(cat.title)
//                                    .foregroundStyle(Color.secondary)
//                                    .font(.caption2)
//                                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                            }
//                        }
//                        .padding(.horizontal, 4)
//                        .contentShape(Rectangle())
//                    }
//                    Spacer()
//                }
//            }
//        }
//        .scrollBounceBehavior(.basedOnSize)
//        //.contentMargins(.vertical, 10, for: .scrollContent)
//        .frame(height: 150)
//    }
}


fileprivate struct DashboardActivityByCategoryChart: View {
    enum Tabs: String { case bar, pie, guage }
    @AppStorage("dashboardSelectedChartPageTabThing") var selectedTab: Tabs = .bar
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: DashboardModel
    @Bindable var data: DashboardData
    var isForSelectedMonth: Bool
    
    @State private var selectedCategory: CBCategory?
    
    let columnGrid = Array(repeating: GridItem(.flexible(), spacing: 0, alignment: .top), count: 6)
    
    enum ChartRow: String {
        case budget = "Budget"
        case spending = "Spending"
        case income = "Money In"
    }
    
    var amount: Double {
        data.budgetAmount - (model.shouldUseTotalSpending ? data.allAmounts.totalSpend : data.allAmounts.actualSpend)
    }
    
    var isOver: Bool { amount < 0 }
    var overUnder: String { abs(amount).currencyWithDecimals() }
    
    var message: AttributedString {
        let leftovers = calculateLeftovers()
        let spendingAmount = model.shouldUseTotalSpending ? data.allAmounts.totalSpend : data.allAmounts.actualSpend
        
        return AttributedString.build {
            if isForSelectedMonth {
                "Your net worth grew by "
                
                "\(leftovers.0)"
                    .foreground(leftovers.1 ? .green : .red)
                
                ", and you are currently "
            } else {
                "You are currently "
            }
            
            overUnder
                .foreground(isOver ? .red : .green)

            " \(isOver ? "over" : "under") your budget of "
            "\(data.budgetAmount.currencyWithDecimals()), having spent "

            spendingAmount
                .currencyWithDecimals()
                .bold()

            "."
        }
    }
    
    
    func calculateLeftovers() -> (String, Bool) {
        var amount: Double = 0.0
        if let start = calModel.sMonth.startingAmounts.filter({ $0.payMethod.isUnifiedDebit }).first {
            let eom = calModel.calculateTotal(for: calModel.sMonth, using: start.payMethod, and: .giveMeLastDayEod)
            let change = abs(eom - start.amount)
            amount = change
                        
            if start.payMethod.isCreditOrLoan || start.payMethod.isUnifiedCredit {
                return (amount.currencyWithDecimals(), change < 0)
            } else {
                return (amount.currencyWithDecimals(), change > 0)
            }
        } else {
            return ((0.0).currencyWithDecimals(), false)
        }
    }
    
    
    var body: some View {
        VStack {
            Text(message)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)
            
            Divider()
            
            TabView(selection: $selectedTab) {
                Tab(value: Tabs.bar) {
                    VStack {
                        DashboardActivityByCategoryBarChart(model: model, data: data, selectedCategory: $selectedCategory)
                        Spacer()
                    }
                } label: {
                    Image(systemName: "chart.bar.yaxis")
                }
                
                Tab(value: Tabs.pie) {
                    VStack {
                        DashboardActivityByCategoryPieChart(model: model, data: data, selectedCategory: $selectedCategory)
                        Spacer()
                    }
                } label: {
                    Image(systemName: "chart.pie")
                }
            }
            .frame(height: 200)
            .tabViewStyle(.page)
            .padding(.bottom, -20) /// Remove the padding under the page indicators
            .overlay(alignment: .top) {
                if let category = selectedCategory {
                    DashboardActivityByCategoryAnnotation(category: category)
                }
            }
        }
    }
}



//
//fileprivate struct DashboardCompareChartOG: View {
//    @Environment(CalendarModel.self) private var calModel
//    @Bindable var model: DashboardModel
//    @Bindable var data: DashboardData
//    
//    @State private var rawSelectedAngle: Double?
//    @State private var rawSelectedBar: Double?
//    private var selectedCategory: CBCategory? {
//        //print("\(rawSelectedBar) - \(rawSelectedAngle)")
//        var theValue: Double = 0.0
//        if rawSelectedBar == nil && rawSelectedAngle == nil { return nil }
//        if let raw = rawSelectedBar { theValue = raw }
//        if let raw = rawSelectedAngle { theValue = raw }
//        //guard let rawSelectedAngle else { return nil }
//        
//        var total = 0.0
//        for cat in categories {
//            let value = max(0, (cat.allAmounts?.totalSpend ?? 0.0))
//            let nextTotal = total + value
//            
//            if theValue >= total && theValue < nextTotal {
//                return cat
//            }
//            
//            total = nextTotal
//        }
//        
//        return nil
//    }
//    
//    var isUnderBudget: Bool {
//        return data.budgetAmount >= data.allAmounts.actualSpend
//    }
//   
//    var categories: [CBCategory] {
//        return (data.categories + data.categoryGroups.flatMap(\.categories))
//            //.filter { $0.type != XrefModel.getItem(from: .categoryTypes, byEnumID: .income) }
//            .uniqued(on: { $0.id })
//            .sorted(by: Helpers.categorySorter())
//    }
//    
//    var expenseCategories: [CBCategory] { categories.filter { !$0.isIncome } }
//    var incomeCategories: [CBCategory] { categories.filter { $0.isIncome } }
//    
//    
//    @State private var annotationHeight: CGFloat = 0
//    
//    var body: some View {
////        VStack(spacing: 10) {
////            barChart
////            HStack {
////                //barChart
////                pieChart
////                Spacer()
////                DashboardChartLegend(data: data)
////            }
////        }
//        VStack(spacing: 10) {
//            HStack {
//                barChart
//                pieChart
//            }
//            DashboardChartLegend(data: data)
//        }
//        .sensoryFeedback(.selection, trigger: selectedCategory)
//        .overlay(alignment: .top) {
//            if selectedCategory != nil {
//                categoryAnnotation
//                    .frame(maxWidth: .infinity)
//                    .padding(.horizontal)
//                    .background {
//                        GeometryReader { geo in
//                            Color.clear
//                                .onAppear {
//                                    annotationHeight = geo.size.height
//                                }
//                                .onChange(of: geo.size.height) { _, newValue in
//                                    annotationHeight = newValue
//                                }
//                        }
//                    }
//                    .offset(y: -annotationHeight - 8)
//                    .zIndex(10)
//            }
//        }
//    }
//    
//    
//    var pieChart: some View {
//        Chart(expenseCategories) { cat in
//            SectorMark(
//                angle: .value("Amount", (cat.allAmounts?.totalSpend ?? 0.0)),
//                innerRadius: .ratio(0.4),
//                angularInset: 1.0
//            )
//            .cornerRadius(5)
//            .foregroundStyle(cat.color)
//            .opacity(selectedCategory == nil ? 1 : (cat.id == selectedCategory!.id ? 1 : 0.3))
//        }
//        .chartAngleSelection(value: $rawSelectedAngle)
//        .frame(height: 150)
//    }
//            
//    
//    var barChart: some View {
//        Chart {
//            if model.groups.isEmpty {
//                ForEach(expenseCategories) { cat in
//                    BarMark(
//                        x: .value("Budget", cat.budgetAmount),
//                        y: .value("Key", "Budget")
//                    )
//                    .foregroundStyle(cat.color)
//                }
//            } else {
//                RuleMark(
//                    x: .value("Budget", data.budgetAmount),
//                    yStart: .value("Start", "Actual Spending"),
//                    yEnd: .value("End", "Actual Spending")
//                )
//                .foregroundStyle(isUnderBudget ? Color.green.gradient : Color.red.gradient)
//                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
//                .zIndex(1)
//            }
//                                    
//            ForEach(expenseCategories) { cat in
//                BarMark(
//                    x: .value("Amount", cat.allAmounts?.actualSpend ?? 0.0),
//                    y: .value("Key", "Actual Spending")
//                )
//                .foregroundStyle(cat.color)
//                .opacity(selectedCategory == nil ? 1 : (cat.id == selectedCategory!.id ? 1 : 0.3))
//                .zIndex(0)
//            }
//            
//            ForEach(incomeCategories) { cat in
//                let amount = cat.isRegularIncome ? cat.allAmounts?.regularIncome : cat.allAmounts?.irregularIncome
//                BarMark(
//                    x: .value("Amount", amount ?? 0.0),
//                    y: .value("Key", "Income")
//                )
//                .foregroundStyle(cat.color)
//                //.opacity(selectedCategory == nil ? 1 : (cat.id == selectedCategory!.id ? 1 : 0.3))
//                .zIndex(0)
//            }
//        }
//        .frame(height: 150)
//        .chartXSelection(value: $rawSelectedBar)
//        .chartXAxis {
//            AxisMarks {
//                let value = $0.as(Int.self)!
//                AxisGridLine()
//                //AxisTick()
//                //AxisValueLabel(format: .currency(code: "USD"))
//                AxisValueLabel { Text("$\(value)") }
//            }
//        }
//        .if(!model.groups.isEmpty) {
//            $0.chartYAxis {
//                AxisMarks { value in
//                    AxisGridLine()
//                    AxisTick()
//                    AxisValueLabel()
//                }
//            }
//        }
//        .chartLegend(.hidden)
//    }
//    
//    
//    var categoryAnnotation: some View {
//        VStack {
//            VStack(alignment: .leading) {
//                HStack {
//                    Text(selectedCategory!.title.capitalized)
//                        .lineLimit(1)
//                    Spacer()
//                    
//                    ChartCircleDot(
//                        budget: selectedCategory!.budgetAmount,
//                        expenses: abs(selectedCategory!.allAmounts?.totalSpend ?? 0.0),
//                        color: .white,
//                        size: 20
//                    )
//                    
//                    Image(systemName: selectedCategory!.emoji ?? "circle")
//                }
//                .font(.headline)
//                
//                Divider()
//                
//                Grid(alignment: .leading) {
//                    GridRow {
//                        Text("Budget").bold()
//                        Text(selectedCategory!.budgetAmount.currencyWithDecimals())
//                    }
//                    GridRow {
//                        Text("Income").bold()
//                        Text((selectedCategory!.allAmounts?.irregularIncome ?? 0.0).currencyWithDecimals())
//                    }
//                    GridRow {
//                        Text("Expenses").bold()
//                        Text((selectedCategory!.allAmounts?.totalSpend ?? 0.0).currencyWithDecimals())
//                    }
//                    
//                    Divider()
//                    
//                    GridRow {
//                        Text("Actual Spend").bold()
//                        Text(((selectedCategory!.allAmounts?.actualSpend ?? 0.0)).currencyWithDecimals())
//                    }
//                }
//                .font(.subheadline)
//            }
//            .if(selectedCategory!.isNil) {
//                $0.schemeBasedReversedForegroundStyle()
//            }
//            .if(!selectedCategory!.isNil) {
//                $0.schemeBasedForegroundStyle()
//            }
//            //.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
//            .padding(12)
//            .background(
//                RoundedRectangle(cornerRadius: 10)
//                    .fill(selectedCategory!.color)
//            )
//            .accessibilityHidden(true)
//        }
//        .frame(maxWidth: .infinity)
//    }
//}


fileprivate struct DashboardActivityByCategoryBarChart: View {
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: DashboardModel
    @Bindable var data: DashboardData
    @Binding var selectedCategory: CBCategory?
    
    @State private var selectedRow: String?
    @State private var selectedXAmount: Double?
    
    enum ChartRow: String {
        case budget = "Budget"
        case spending = "Spending"
        case income = "Income"
    }
    
    var totalExpenseAmount: String {
        max(0, (model.shouldUseTotalSpending ? data.allAmounts.totalSpend : data.allAmounts.actualSpend)).currencyWithDecimals()
    }
    
    var totalIncomeAmount: String {
        max(0, (data.debitAmounts.regularIncome + data.debitAmounts.irregularIncome)).currencyWithDecimals()
    }
    
    var body: some View {
        Chart {
            if model.groups.isEmpty {
                budgetBars
            } else {
                RuleMark(
                    x: .value("Budget ", data.budgetAmount),
                    yStart: .value("Start", "\(ChartRow.spending.rawValue) - \(totalExpenseAmount)"),
                    yEnd: .value("End", "\(ChartRow.spending.rawValue) - \(totalExpenseAmount)")
                )
                .foregroundStyle(model.isUnderBudget ? Color.green.gradient : Color.red.gradient)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                .zIndex(1)
            }
                                    
            expenseBars
            incomeBars
        }
        .frame(height: 150)
        .chartYSelection(value: $selectedRow)
        .chartXSelection(value: $selectedXAmount)
        .chartXAxis {
            AxisMarks { axisValue in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let value = axisValue.as(Double.self) {
                        Text(value.axisCurrencyLabel)
                        //Text("$\(value.kVersion)")
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .onChange(of: selectedRow) {
            updateSelectedCategoryFromBar()
        }
        .onChange(of: selectedXAmount) {
            updateSelectedCategoryFromBar()
        }
        .sensoryFeedback(.selection, trigger: selectedCategory)
        .overlay(alignment: .top) {
            if let category = selectedCategory {
                DashboardActivityByCategoryAnnotation(category: category)
            }
        }
    }
    
    @ChartContentBuilder
    var budgetBars: some ChartContent {
        ForEach(model.expenseCategories) { cat in
            BarMark(
                x: .value("Budget", max(0, cat.budgetAmount)),
                y: .value("Key", ChartRow.budget.rawValue),
                stacking: .standard
            )
            .foregroundStyle(cat.color.gradient)
            .opacity(selectedCategory == nil ? 1 : (cat.id == selectedCategory?.id ? 1 : 0.3))
            .cornerRadius(5)
        }
    }
    
        
    @ChartContentBuilder
    var expenseBars: some ChartContent {
        ForEach(model.expenseCategories) { cat in
            BarMark(
                //x: .value("Amount", max(0, cat.allAmounts?.totalSpend ?? 0.0)),
                x: .value("Amount", max(0, (model.shouldUseTotalSpending ? cat.allAmounts?.totalSpend ?? 0 : cat.allAmounts?.actualSpend ?? 0))),
                y: .value("Key", "\(ChartRow.spending.rawValue) - \(totalExpenseAmount)"),
                stacking: .standard
            )
            .foregroundStyle(cat.color.gradient)
            .opacity(selectedCategory == nil ? 1 : (cat.id == selectedCategory?.id ? 1 : 0.3))
            .zIndex(0)
            .cornerRadius(5)
        }
    }
    
    
    @ChartContentBuilder
    var incomeBars: some ChartContent {
        ForEach(model.incomeCategories) { cat in
            BarMark(
                x: .value("Amount", max(0, DashboardUtils.incomeAmount(for: cat))),
                y: .value("Key", "\(ChartRow.income.rawValue) - \(totalIncomeAmount)"),
                stacking: .standard
            )
            .foregroundStyle(cat.color.gradient)
            .opacity(selectedCategory == nil ? 1 : (cat.id == selectedCategory?.id ? 1 : 0.3))
            .zIndex(0)
            .cornerRadius(5)
        }
    }
    
    
    func updateSelectedCategoryFromBar() {
        guard let selectedRow, let selectedXAmount, let row = selectedRow.split(separator: "-").first?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            selectedCategory = nil
            return
        }
        
        switch row {
        case ChartRow.budget.rawValue:
            selectedCategory = DashboardUtils.categoryOwningXRange(
                selectedXAmount: selectedXAmount,
                categories: model.expenseCategories
            ) { cat in
                max(0, cat.budgetAmount)
            }
            
        case ChartRow.spending.rawValue:
            selectedCategory = DashboardUtils.categoryOwningXRange(
                selectedXAmount: selectedXAmount,
                categories: model.expenseCategories
            ) { cat in
                max(0, (model.shouldUseTotalSpending ? cat.allAmounts?.totalSpend ?? 0 : cat.allAmounts?.actualSpend ?? 0))
            }
            
        case ChartRow.income.rawValue:
            selectedCategory = DashboardUtils.categoryOwningXRange(
                selectedXAmount: selectedXAmount,
                categories: model.incomeCategories
            ) { cat in
                max(0, DashboardUtils.incomeAmount(for: cat))
            }
            
        default:
            selectedCategory = nil
        }
    }
}


fileprivate struct DashboardActivityByCategoryPieChart: View {
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: DashboardModel
    @Bindable var data: DashboardData
    @Binding var selectedCategory: CBCategory?
    
    @State private var rawSelectedExpenseAngle: Double?
    @State private var rawSelectedIncomeAngle: Double?
    
    var body: some View {
        HStack {
            expensePieChart
            Spacer()
            incomePieChart
        }
        .sensoryFeedback(.selection, trigger: selectedCategory)
    }
    
    var expensePieChart: some View {
        Chart {
            if model.expenseCategories.isEmpty {
                dummySectorMark
            } else {
                ForEach(model.expenseCategories) { cat in
                    SectorMark(
                        angle: .value("Amount", max(0, (model.shouldUseTotalSpending ? cat.allAmounts?.totalSpend ?? 0 : cat.allAmounts?.actualSpend ?? 0))),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.0
                    )
                    .cornerRadius(5)
                    .foregroundStyle(cat.color)
                    .opacity(selectedCategory == nil ? 1 : (cat.id == selectedCategory?.id ? 1 : 0.3))
                }
            }
        }
        //.chartBackground { donutLabel($0, "Spending") }
        .chartBackground {
            let text1 = model.expenseCategories.isEmpty ? "No Spending" : "Spending"
            let text2 = model.expenseCategories.isEmpty
            ? nil
            : (model.shouldUseTotalSpending ? data.allAmounts.totalSpend : data.allAmounts.actualSpend).currencyWithDecimals()
            
            donutLabel($0, text1, text2)
        }
        .chartAngleSelection(value: $rawSelectedExpenseAngle)
        .frame(width: 150, height: 150)
        .onChange(of: rawSelectedExpenseAngle) {
            updateSelectedCategoryFromExpensePie()
        }
    }
            
    
    @ViewBuilder
    var incomePieChart: some View {
        Chart {
            if model.incomeCategories.isEmpty {
                dummySectorMark
            } else {
                ForEach(model.incomeCategories) { cat in
                    SectorMark(
                        angle: .value("Amount", max(0, DashboardUtils.incomeAmount(for: cat))),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.0
                    )
                    .cornerRadius(5)
                    .foregroundStyle(cat.color)
                    .opacity(selectedCategory == nil ? 1 : (cat.id == selectedCategory?.id ? 1 : 0.3))
                }
            }
            
        }
        .chartBackground {
            let text1 = model.incomeCategories.isEmpty ? "No Income" : "Income"
            let text2 = model.incomeCategories.isEmpty
            ? nil
            : (data.debitAmounts.regularIncome + data.debitAmounts.irregularIncome).currencyWithDecimals()
            donutLabel($0, text1, text2)
        }
        .chartAngleSelection(value: $rawSelectedIncomeAngle)
        .frame(width: 150, height: 150)
        .onChange(of: rawSelectedIncomeAngle) {
            updateSelectedCategoryFromIncomePie()
        }
    }

    
    @ChartContentBuilder
    var dummySectorMark: some ChartContent {
        SectorMark(
            angle: .value("Amount", 100),
            innerRadius: .ratio(0.6),
            angularInset: 1.0
        )
        .cornerRadius(5)
        .foregroundStyle(Color.secondary.opacity(0.1))
    }
    
    
    @ViewBuilder
    func donutLabel(_ chartProxy: ChartProxy, _ text1: String, _ text2: String? = nil) -> some View {
        GeometryReader { geometry in
            if let anchor = chartProxy.plotFrame {
                let frame = geometry[anchor]
                VStack {
                    Text(text1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    if let text2 = text2 {
                        Text(text2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
                .contentTransition(.numericText())
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .position(x: frame.midX, y: frame.midY)
            }
        }
    }
    
    
    func updateSelectedCategoryFromExpensePie() {
        guard let rawSelectedExpenseAngle else {
            selectedCategory = nil
            return
        }
        
        selectedCategory = DashboardUtils.categoryOwningXRange(
            selectedXAmount: rawSelectedExpenseAngle,
            categories: model.expenseCategories
        ) { cat in
            max(0, (model.shouldUseTotalSpending ? cat.allAmounts?.totalSpend ?? 0 : cat.allAmounts?.actualSpend ?? 0))
        }
    }
    
    
    func updateSelectedCategoryFromIncomePie() {
        guard let rawSelectedIncomeAngle else {
            selectedCategory = nil
            return
        }
        
        selectedCategory = DashboardUtils.categoryOwningXRange(
            selectedXAmount: rawSelectedIncomeAngle,
            categories: model.incomeCategories
        ) { cat in
            max(0, DashboardUtils.incomeAmount(for: cat))
        }
    }
}


struct DashboardActivityByCategoryAnnotation: View {
    var category: CBCategory
    
    @State private var annotationHeight: CGFloat = 0
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                HStack {
                    
                    Text(category.title.capitalized)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    ChartCircleDot(
                        budget: category.budgetAmount,
                        expenses: abs(category.allAmounts?.totalSpend ?? 0.0),
                        color: .white,
                        size: 20
                    )
                    
                    Image(systemName: category.emoji ?? "circle")
                }
                .font(.headline)
                
                Divider()
                
                if category.isIncome {
                    let amount = category.isRegularIncome
                    ? (category.allAmounts?.regularIncome ?? 0.0)
                    : (category.allAmounts?.irregularIncome ?? 0.0)
                    Grid(alignment: .leading) {
                        GridRow {
                            Text("Income").bold()
                            Text(amount.currencyWithDecimals())
                        }
                    }
                    .font(.subheadline)
                } else {
                    Grid(alignment: .leading) {
                        GridRow {
                            Text("Budget").bold()
                            Text(category.budgetAmount.currencyWithDecimals())
                        }
                        
                        GridRow {
                            Text("Income").bold()
                            Text((category.allAmounts?.irregularIncome ?? 0.0).currencyWithDecimals())
                        }
                        
                        GridRow {
                            Text("Expenses").bold()
                            Text((category.allAmounts?.totalSpend ?? 0.0).currencyWithDecimals())
                        }
                        
                        Divider()
                        
                        GridRow {
                            Text("Actual Spend").bold()
                            Text((category.allAmounts?.actualSpend ?? 0.0).currencyWithDecimals())
                        }
                    }
                    .font(.subheadline)
                }
                
                
            }
            .if(category.isNil) {
                $0.schemeBasedReversedForegroundStyle()
            }
            .if(!category.isNil) {
                $0.schemeBasedForegroundStyle()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(category.color.gradient)
            )
            .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .background {
            GeometryReader { geo in
                Color.clear
                    .onAppear { annotationHeight = geo.size.height }
                    .onChange(of: geo.size.height) { annotationHeight = $1 }
            }
        }
        .offset(y: -annotationHeight - 8)
        .zIndex(10)
    }
}




fileprivate struct DashboardActivityByMonthChart: View {
    enum Tabs: String { case expense, income }
    @AppStorage("dashboardSelectedMonthChartPageTabThing") var selectedTab: Tabs = .expense
    
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: DashboardModel
    @Bindable var data: DashboardData
    
    @State private var annotationHeight: CGFloat = 0
    @State private var chartScroll: Date?

    private let visibleSeconds: TimeInterval = 3600 * 24 * 365 * 2



    @State private var rawSelectedDate: Date?
//    var selectedMonth: DashboardDataByMonth? {
//        guard let rawSelectedDate else { return nil }
//        return data.monthlyBreakdowns.filter {
//            Calendar.current.isDate(rawSelectedDate, equalTo: $0.date, toGranularity: .month)
//        }.first
//    }
//
    
    enum SelectedBreakdown {
        case month(DashboardDataByMonth)
        case quarter(DashboardDataByQuarter)
    }
    
    var selectedQuarter: DashboardDataByQuarter? {
        guard let rawSelectedDate else { return nil }

        return data.quarterlyBreakdowns.first { quarter in
            rawSelectedDate >= quarter.date &&
            rawSelectedDate < quarter.endDate
        }
    }

    var selectedMonth: DashboardDataByMonth? {
        guard let rawSelectedDate else { return nil }

        return data.monthlyBreakdowns.first {
            Calendar.current.isDate(
                rawSelectedDate,
                equalTo: $0.date,
                toGranularity: .month
            )
        }
    }

    var selectedSummary: (any DashboardBreakdownSummary)? {
        switch data.breakdownType {
        case .monthly:
            selectedMonth
        case .quarterly:
            selectedQuarter
        }
    }
    
    var selectedID: String? {
        switch data.breakdownType {
        case .monthly:
            selectedMonth?.id
        case .quarterly:
            selectedQuarter?.id
        }
    }
    
    
    var widgetTitle: String {
        switch selectedTab {
        case .expense:
            "Spending By "
        case .income:
            "Income By "
        }
    }
    
    var annotationColor: Color {
        switch selectedTab {
        case .expense: .green
        case .income: .blue
        }
    }
    
//    private var lastChartDate: Date? {
//        data.monthlyBreakdowns.map(\.date).max()
//    }
//
//    private var chartStartDateForEnd: Date? {
//        lastChartDate?.addingTimeInterval(-visibleSeconds)
//    }
//    
//    private var visibleStartDate: Date? {
//        chartScroll
//    }
//    
//    private var visibleEndDate: Date? {
//        guard let chartScroll else { return nil }
//        return Calendar.current.date(byAdding: .year, value: 2, to: chartScroll)
//    }
//
//    private var visibleMonths: [DashboardDataByMonth] {
//        guard let start = chartScroll,
//              let end = visibleEndDate else { return [] }
//
//        return data.monthlyBreakdowns.filter {
//            $0.date >= start && $0.date < end
//        }
//    }
//
//    private var visibleSpendTotal: Double {
//        visibleMonths.reduce(0) { partial, month in
//            partial + (model.shouldUseTotalSpending ? month.allAmounts?.totalSpend ?? 0 : month.allAmounts?.actualSpend ?? 0)
//        }
//    }
//    
//    private var visibleIncomeTotal: Double {
//        visibleMonths.reduce(0) { partial, month in
//            partial + (month.allAmounts?.irregularIncome ?? 0) + (month.allAmounts?.regularIncome ?? 0)
//        }
//    }
//    
//    private var rangeText: String {
//        guard let start = visibleStartDate, let end = visibleEndDate else { return "" }
//
//        let formatter = DateFormatter()
//        formatter.dateFormat = "MMM yyyy"
//
//        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
//    }
    
    
    var body: some View {
        
        DashboardWidget {
            HStack(spacing: 0) {
                Text(widgetTitle)
                    .padding(.leading, 12)
                    .foregroundStyle(.secondary)
                    .font(.headline)
                
                Menu {
                    ForEach(DashboardMontlyOrQuarterlyBreakdowns.allCases, id: \.self) { opt in
                        Button {
                            withAnimation {
                                data.breakdownType = opt
                            }
                        } label: {
                            Text(opt.rawValue)
                        }
                    }
                } label: {
                    Text(data.breakdownType.rawValue)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                
//                Picker("", selection: $data.breakdownType) {
//                    ForEach(DashboardMontlyOrQuarterlyBreakdowns.allCases, id: \.self) {
//                        Text($0.rawValue)
//                            .tag($0)
//                    }
//                }
//                .labelsHidden()
//                .pickerStyle(.menu)
            }
        } content: {
            VStack {
                TabView(selection: $selectedTab) {
                    Tab("Expenses", systemImage: "tray.and.arrow.up", value: Tabs.expense) {
                        VStack {
    //                        VStack(alignment: .leading) {
    //                            Text(visibleSpendTotal.currencyWithDecimals())
    //                                .font(.callout)
    //                            Text(rangeText)
    //                                .font(.caption2)
    //                                .foregroundStyle(.secondary)
    //                        }
    //
    //                        .frame(maxWidth: .infinity, alignment: .leading)
                            
                            //expenseChart
                            expenseChart2
                            Spacer()
                        }
                        .padding(.top, 10)
                    }
                    
                    Tab("Income", systemImage: "tray.and.arrow.down", value: Tabs.income) {
                        VStack {
    //                        VStack(alignment: .leading) {
    //                            Text(visibleIncomeTotal.currencyWithDecimals())
    //                                .font(.callout)
    //                            Text(rangeText)
    //                                .font(.caption2)
    //                                .foregroundStyle(.secondary)
    //                        }
    //                        .font(.caption2)
    //                        .frame(maxWidth: .infinity, alignment: .leading)
                            
                            incomeChart2
                            Spacer()
                        }
                        .padding(.top, 10)
                    }
                }
                .frame(height: 200)
                .tabViewStyle(.page)
                .padding(.bottom, -20) /// Remove the padding under the page indicators
            }
            .overlay(alignment: .top) {
                if let selectedMonth = selectedMonth {
                    selectedDataView
                }
            }
//            .onChange(of: lastChartDate) { _, _ in
//                chartScroll = chartStartDateForEnd
//            }
//            .onAppear {
//                chartScroll = chartStartDateForEnd
//            }
        }

        
//        DashboardWidget(title: widgetTitle) {
//            
//        }
    }
    
    
    var expenseChart2: some View {
        Chart {
            if let selectedSummary = selectedSummary {
                let date = switch data.breakdownType {
                case .monthly:
                    selectedSummary.date
                case .quarterly:
                    selectedSummary.date.middleDateOfQuarter
                }
                RuleMark(x: .value("Start Date", date, unit: .month))
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
            
            switch data.breakdownType {
            case .monthly:
                ForEach(data.monthlyBreakdowns) { month in
                    BarMark(
                        x: .value("Date", month.date, unit: .month),
                        y: .value("Amount", model.shouldUseTotalSpending ? month.allAmounts?.totalSpend ?? 0 : month.allAmounts?.actualSpend ?? 0)
                    )
                    .foregroundStyle(.green.gradient)
                    //.opacity(month.date == selectedMonth?.date ? 1 : (selectedMonth == nil ? 1 : 0.3))
                }
            case .quarterly:
                ForEach(data.quarterlyBreakdowns) { quarter in
                    RectangleMark(
                        xStart: .value("Start Date", quarter.date.startDateOfQuarter, unit: .day),
                        xEnd: .value("End Date", quarter.date.endDateOfQuarter.addingTimeInterval(-60 * 60 * 24 * 14), unit: .day),
                        yStart: .value("Start", 0),
                        yEnd: .value("End", model.shouldUseTotalSpending ? quarter.allAmounts?.totalSpend ?? 0 : quarter.allAmounts?.actualSpend ?? 0)
                    )
                    .foregroundStyle(.green.gradient)
                }
            }
        }
        .frame(height: 150)
        .sensoryFeedback(.selection, trigger: selectedID)
        .chartXSelection(value: $rawSelectedDate)
        .chartYAxis { yAxis() }
    }
    
    
    
    
    var expenseChart: some View {
        Chart(data.monthlyBreakdowns) { month in
            if let selectedMonth = selectedMonth {
                RuleMark(x: .value("Start Date", selectedMonth.date, unit: .month))
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
            
            BarMark(
                x: .value("Date", month.date, unit: .month),
                y: .value("Amount", model.shouldUseTotalSpending ? month.allAmounts?.totalSpend ?? 0 : month.allAmounts?.actualSpend ?? 0)
            )
            .foregroundStyle(.green.gradient)
            //.opacity(month.date == selectedMonth?.date ? 1 : (selectedMonth == nil ? 1 : 0.3))
        }
        .frame(height: 150)
        .sensoryFeedback(.selection, trigger: selectedMonth)
        .chartXSelection(value: $rawSelectedDate)
        .chartYAxis { yAxis() }
//        .chartXVisibleDomain(length: visibleSeconds)
//        .chartScrollableAxes(.horizontal)
//        .chartScrollTargetBehavior(.valueAligned(matching: DateComponents(day: 1), majorAlignment: .matching(DateComponents(month: 1))))
//        .chartScrollPosition(x: Binding(
//            get: { chartScroll ?? chartStartDateForEnd ?? Date() },
//            set: { chartScroll = $0 }
//        ))
    }
    
    
    var incomeChart2: some View {
        Chart {
            if let selectedSummary = selectedSummary {
                let date = switch data.breakdownType {
                case .monthly:
                    selectedSummary.date
                case .quarterly:
                    selectedSummary.date.middleDateOfQuarter
                }
                RuleMark(x: .value("Start Date", date, unit: .month))
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
               
            switch data.breakdownType {
            case .monthly:
                ForEach(data.monthlyBreakdowns) { month in
                    BarMark(
                        x: .value("Date", month.date, unit: .month),
                        y: .value("Amount", (month.allAmounts?.irregularIncome ?? 0) + (month.allAmounts?.regularIncome ?? 0))
                    )
                    .foregroundStyle(.blue.gradient)
                    //.opacity(month.date == selectedMonth?.date ? 1 : (selectedMonth == nil ? 1 : 0.3))
                }
            case .quarterly:
                ForEach(data.quarterlyBreakdowns) { quarter in
                    RectangleMark(
                        xStart: .value("Start Date", quarter.date.startDateOfQuarter, unit: .day),
                        xEnd: .value("End Date", quarter.date.endDateOfQuarter.addingTimeInterval(-60 * 60 * 24 * 14), unit: .day),
                        yStart: .value("Start", 0),
                        yEnd: .value("End", (quarter.allAmounts?.irregularIncome ?? 0) + (quarter.allAmounts?.regularIncome ?? 0))
                    )
                    .foregroundStyle(.blue.gradient)
                }
            }
        }
        .frame(height: 150)
        .sensoryFeedback(.selection, trigger: selectedID)
        .chartXSelection(value: $rawSelectedDate)
        .chartYAxis { yAxis() }
//        .chartXVisibleDomain(length: visibleSeconds)
//        .chartScrollableAxes(.horizontal)
//        .chartScrollTargetBehavior(.valueAligned(matching: DateComponents(day: 1), majorAlignment: .matching(DateComponents(month: 1))))
//        .chartScrollPosition(x: Binding(
//            get: { chartScroll ?? chartStartDateForEnd ?? Date() },
//            set: { chartScroll = $0 }
//        ))
    }
    
    
    var incomeChart: some View {
        Chart(data.monthlyBreakdowns) { month in
            if let selectedMonth = selectedMonth {
                RuleMark(x: .value("Start Date", selectedMonth.date, unit: .month))
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
            
            BarMark(
                x: .value("Date", month.date, unit: .month),
                y: .value("Amount", (month.allAmounts?.irregularIncome ?? 0) + (month.allAmounts?.regularIncome ?? 0))
            )
            .foregroundStyle(.blue.gradient)
            //.opacity(month.date == selectedMonth?.date ? 1 : (selectedMonth == nil ? 1 : 0.3))
        }
        .frame(height: 150)
        //.sensoryFeedback(.selection, trigger: selectedMonth)
        .chartXSelection(value: $rawSelectedDate)
        .chartYAxis { yAxis() }
//        .chartXVisibleDomain(length: visibleSeconds)
//        .chartScrollableAxes(.horizontal)
//        .chartScrollTargetBehavior(.valueAligned(matching: DateComponents(day: 1), majorAlignment: .matching(DateComponents(month: 1))))
//        .chartScrollPosition(x: Binding(
//            get: { chartScroll ?? chartStartDateForEnd ?? Date() },
//            set: { chartScroll = $0 }
//        ))
    }
    
    
    @AxisContentBuilder
    func yAxis() -> some AxisContent {
        AxisMarks { axisValue in
            AxisGridLine()
            AxisTick()
            AxisValueLabel {
                if let value = axisValue.as(Double.self) {
                    Text("$\(value.kVersion)")
                }
            }
        }
    }
    
    @ViewBuilder
    var selectedDataView: some View {
        if let item = selectedSummary {
            VStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(item.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)

                        Spacer()

//                        Chart(item.flatCats) { cat in
//                            SectorMark(
//                                angle: .value("Amount", max(0, cat.allAmounts?.totalSpend ?? 0.0)),
//                                innerRadius: .ratio(0.2),
//                                angularInset: 0.5
//                            )
//                            .cornerRadius(2)
//                            .foregroundStyle(cat.color)
//                        }
//                        .id(item.date)
//                        .frame(width: 50, height: 50)
                    }
                    .font(.headline)

                    Divider()

                    Grid(alignment: .leading) {
                        GridRow {
                            Text("Budget").bold()
                            Text(item.budgetAmount.currencyWithDecimals())
                        }

                        GridRow {
                            Text("Income").bold()
                            Text(
                                (
                                    (item.allAmounts?.irregularIncome ?? 0.0) +
                                    (item.allAmounts?.regularIncome ?? 0.0)
                                )
                                .currencyWithDecimals()
                            )
                        }

                        GridRow {
                            Text("Expenses").bold()
                            Text((item.allAmounts?.totalSpend ?? 0.0).currencyWithDecimals())
                        }

                        Divider()

                        GridRow {
                            Text("Actual Spend").bold()
                            Text((item.allAmounts?.actualSpend ?? 0.0).currencyWithDecimals())
                        }
                    }
                    .font(.subheadline)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(annotationColor.gradient)
                )
                .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .background {
                GeometryReader { geo in
                    Color.clear
                        .onAppear { annotationHeight = geo.size.height }
                        .onChange(of: geo.size.height) { annotationHeight = $1 }
                }
            }
            .offset(y: -annotationHeight - 8)
            .zIndex(10)
        }
    }
}


//
//
//fileprivate struct DashboardActivityByMonthChartOG: View {
//    @Environment(CalendarModel.self) private var calModel
//    @Bindable var model: DashboardModel
//    @Bindable var data: DashboardData
//    
//    @State private var annotationHeight: CGFloat = 0
//
//    @State private var rawSelectedDate: Date?
//    var selectedMonth: DashboardDataByMonth? {
//        guard let rawSelectedDate else { return nil }
//        return data.monthlyBreakdowns.filter {
//            Calendar.current.isDate(rawSelectedDate, equalTo: $0.date, toGranularity: .month)
//        }.first
//    }
//    
////    var months: Int {
////        data.monthlyBreakdowns.count < 12 ? data.monthlyBreakdowns.count : 12
////    }
//    
////    var xAxisMonths: [Date] {
////        let months = data.monthlyBreakdowns.map(\.date)
////
////        if data.shouldUseQuarterly {
////            return months.enumerated().compactMap { index, date in
////                index % 12 == 0 ? date : nil
////            }
////        }
////
////        let step = data.monthlyBreakdowns.count > 6 ? 3 : 1
////
////        return months.enumerated().compactMap { index, date in
////            index % step == 0 ? date : nil
////        }
////    }
//    
//    var body: some View {
//        Chart {
//            if let selectedMonth = selectedMonth {
//                RuleMark(x: .value("Start Date", selectedMonth.date, unit: .month))
//                    .foregroundStyle(Color.secondary.opacity(0.5))
//            }
//            
//            ForEach(data.monthlyBreakdowns) { month in
//                ForEach(month.expenseCategories) { cat in
//                    BarMark(
//                        x: .value("Date", month.date, unit: .month),
//                        y: .value("Amount", (model.shouldUseTotalSpending ? cat.allAmounts?.totalSpend ?? 0 : cat.allAmounts?.actualSpend ?? 0))
//                    )
//                    .position(by: .value("Type", "Expenses"))
//                    .zIndex(-1)
//                    .foregroundStyle(cat.color)
//                }
//                                
//                ForEach(month.incomeCategories) { cat in
//                    BarMark(
//                        x: .value("Date", month.date, unit: .month),
//                        y: .value("Amount", incomeAmount(for: cat))
//                    )
//                    .position(by: .value("Type", "Income"))
//                    .zIndex(-1)
//                    .foregroundStyle(cat.color)
//                }
//            }
//
////            if data.shouldUseQuarterly {
////                ForEach(data.quarterlyBreakdowns) { quarter in
////                    let cats = quarter.flatCats
////                    let stackedCats = cats.reduce(into: [(cat: CBCategory, start: Double, end: Double)]()) { result, cat in
////                        let start = result.last?.end ?? 0.0
////                        let amount = cat.allAmounts?.actualSpend ?? 0.0
////                        let end = start + amount
////
////                        result.append((cat, start, end))
////                    }
////
////                    ForEach(stackedCats, id: \.cat.id) { item in
////                        RectangleMark(
////                            xStart: .value("Start Date", quarter.date.startDateOfQuarter, unit: .day),
////                            xEnd: .value("End Date", quarter.date.endDateOfQuarter.addingTimeInterval(-60 * 60 * 24 * 14), unit: .day),
////                            yStart: .value("Start", item.start),
////                            yEnd: .value("End", item.end)
////                        )
////                        .foregroundStyle(item.cat.color)
////                    }
////                }
////            } else {
////                ForEach(data.monthlyBreakdowns) { month in
////                    ForEach(month.flatCats) { cat in
////                        BarMark(
////                            x: .value("Date", month.date, unit: .month),
////                            y: .value("Amount", cat.allAmounts?.actualSpend ?? 0.0)
////                        )
////                        .zIndex(-1)
////                        .foregroundStyle(cat.color)
////                    }
////                }
////            }
//        }
//        .sensoryFeedback(.selection, trigger: selectedMonth)
//        .chartXSelection(value: $rawSelectedDate)
//        .if(data.monthlyBreakdowns.count > 12) {
//            $0
//            .chartXVisibleDomain(length: 3600 * 24 * 365 * 1)
//            .chartScrollableAxes(.horizontal)
//        }
//        .chartYAxis {
//            AxisMarks { axisValue in
//                AxisGridLine()
//                AxisTick()
//                AxisValueLabel {
//                    if let value = axisValue.as(Double.self) {
//                        Text("$\(value.kVersion)")
//                    }
//                }
//            }
//        }
//        .overlay(alignment: .top) {
//            selectedDataView
//        }
//        
//        
//        
//        
//        
//        
//        
////        .chartXAxis {
////            AxisMarks(values: xAxisMonths) { value in
////                AxisGridLine()
////                AxisTick()
////                AxisValueLabel {
////                    if let date = value.as(Date.self) {
////                        Text(
////                            date,
////                            format: data.shouldUseQuarterly
////                                ? .dateTime.year()
////                                : .dateTime.month(.abbreviated)
////                        )
////                    }
////                }
////            }
////        }
////        .chartXAxis {
////            AxisMarks(
////                values: .stride(
////                    by: .month,
////                    count: data.shouldUseQuarterly ? 12 : (data.monthlyBreakdowns.count > 6 ? 3 : 1)
////                )
////            ) { _ in
////                AxisGridLine()
////                AxisTick()
////                AxisValueLabel(format: data.shouldUseQuarterly ? .dateTime.year() : .dateTime.month(.abbreviated))
////            }
////        }
//    }
//    
//    @ViewBuilder
//    var selectedDataView: some View {
//        if let month = selectedMonth {
//            VStack {
//                VStack(alignment: .leading) {
//                    HStack {
//                        Text("\(DateFormatter.monthFull.string(from: month.date)) \(String(month.year))")
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                            .lineLimit(1)
//                        
//                        Spacer()
//                        
//                        Chart(month.flatCats) { cat in
//                            SectorMark(
//                                angle: .value("Amount", max(0, cat.allAmounts?.totalSpend ?? 0.0)),
//                                innerRadius: .ratio(0.2),
//                                angularInset: 0.5
//                            )
//                            .cornerRadius(2)
//                            .foregroundStyle(cat.color)
//                        }
//                        .id(month.date)
//                        .frame(width: 50, height: 50)
//                    }
//                    .font(.headline)
//                    
//                    Divider()
//                
//                    Grid(alignment: .leading) {
//                        GridRow {
//                            Text("Budget").bold()
//                            Text(month.budgetAmount.currencyWithDecimals())
//                        }
//                        
//                        GridRow {
//                            Text("Income").bold()
//                            Text((month.allAmounts?.irregularIncome ?? 0.0).currencyWithDecimals())
//                        }
//                        
//                        GridRow {
//                            Text("Expenses").bold()
//                            Text((month.allAmounts?.totalSpend ?? 0.0).currencyWithDecimals())
//                        }
//                        
//                        Divider()
//                        
//                        GridRow {
//                            Text("Actual Spend").bold()
//                            Text((month.allAmounts?.actualSpend ?? 0.0).currencyWithDecimals())
//                        }
//                    }
//                    .font(.subheadline)
//                }
//                .padding(12)
//                .background(
//                    RoundedRectangle(cornerRadius: 10)
//                        .fill(.ultraThinMaterial)
//                )
//                .accessibilityHidden(true)
//            }
//            .frame(maxWidth: .infinity)
//            .padding(.horizontal)
//            .background {
//                GeometryReader { geo in
//                    Color.clear
//                        .onAppear { annotationHeight = geo.size.height }
//                        .onChange(of: geo.size.height) { annotationHeight = $1 }
//                }
//            }
//            .offset(y: -annotationHeight - 8)
//            .zIndex(10)
//        }
//    }
//}


fileprivate struct DashboardExpenseByCategoryTable: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: DashboardModel
    @Binding var navPath: [CalendarNavDest]
    
    var body: some View {
        VStack {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                gridHeader
                
                Divider()
                
                ForEachWithSeparator(model.data.categoryGroups, includeLastSeparator: !model.data.categories.isEmpty) { group in
                    GridRow {
                        HStack {
                            GradientCircleDot(size: 12, colors: group.categories.map(\.color))
                            Text(group.title)
                        }

                        Text(group.budgetAmount.currencyWithDecimals())
                        
                        Text((model.shouldUseTotalSpending ? group.allAmounts?.totalSpend : group.allAmounts?.actualSpend)?.currencyWithDecimals() ?? "N/A")
                        
                        if model.shouldUseTotalSpending {
                            Text(group.allAmounts?.irregularIncome.currencyWithDecimals() ?? "N/A")
                        }

                        Text(abs(group.allAmounts?.variance ?? 0).currencyWithDecimals())
                            .foregroundStyle(group.allAmounts?.variance ?? 0 < 0 ? .red : .green)
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 5)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            group.isExpanded.toggle()
                        }
                    }
                    
                    if group.isExpanded {
                        Divider()
                        ForEachWithSeparator(group.categories.sorted(by: Helpers.categorySorter())) { cat in
                            line(for: cat, isPartOfGroup: true)
                        } separator: {
                            Divider()
                                .padding(.leading, 10)
                        }
                    }
                }
                
                ForEachWithSeparator(
                    model.data.categories
                        .filter { model.shouldUseTotalSpending ? true : !$0.isIncome }
                        .sorted(by: Helpers.categorySorter())
                ) { cat in
                    line(for: cat, isPartOfGroup: false)
                    
                }
            }
            .font(.caption)
            .lineLimit(1)
            .textCase(nil)
        }
    }
    

    var gridHeader: some View {
        GridRow {
            HStack {
                ChartCircleDot(budget: 0, expenses: 0, color: .primary, size: 12)
                Text("Category")
            }

            Text("Budget")
            Text("Spending")
            if model.shouldUseTotalSpending {
                Text("Money In")
            }
            Text("Variance")
            Text("")
        }
        .font(.caption)
    }
    
    
    @ViewBuilder
    func line(for cat: CBCategory, isPartOfGroup: Bool) -> some View {
        GridRow {
            HStack {
                ChartCircleDot(
                    budget: cat.isIncome ? 100 : cat.budgetAmount,
                    expenses: cat.isIncome ? 100 : (model.shouldUseTotalSpending ? cat.allAmounts?.totalSpend ?? 0 : cat.allAmounts?.actualSpend ?? 0),
                    color: cat.color,
                    size: 12
                )

                Text(cat.title)
            }
            .padding(.leading, isPartOfGroup ? 10 : 0)

            let value1 = cat.isIncome || isPartOfGroup ? "N/A" : cat.budgetAmount.currencyWithDecimals()
            Text(value1)
                .foregroundStyle(isPartOfGroup || cat.isIncome ? .gray : .primary)
                .contentTransition(.numericText())
            
            
            //(model.shouldUseTotalSpending ? cat.allAmounts?.totalSpend : cat.allAmounts?.actualSpend)
            
            let value2 = cat.isIncome ? "N/A" : ((model.shouldUseTotalSpending ? cat.allAmounts?.totalSpend : cat.allAmounts?.actualSpend) ?? 0).currencyWithDecimals()
            Text(value2)
                .foregroundStyle(value2 == "N/A" ? .gray : .primary)
                .contentTransition(.numericText())

            if model.shouldUseTotalSpending {
                let value3 = cat.isRegularIncome
                    ? (cat.allAmounts?.regularIncome ?? 0.0).currencyWithDecimals()
                    : (cat.allAmounts?.irregularIncome ?? 0.0).currencyWithDecimals()

                Text(value3)
                    .contentTransition(.numericText())
            }
                    
            let variance = cat.allAmounts?.variance ?? 0.0

            Text(isPartOfGroup || cat.isIncome ? "N/A" : abs(variance).currencyWithDecimals())
                .foregroundStyle(isPartOfGroup || cat.isIncome ? .gray : (variance < 0 ? .red : .green))
                .contentTransition(.numericText())
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                navPath.append(.dashboardTransactionList(model.data, cat))
            }
        }
    }
}


/// Not fileprivate because it is used in the navigation destination in ``CalendarViewPhone``
struct DashboardNumericDetails: View {
    @Bindable var model: DashboardModel
    var isForSelectedMonth: Bool
    //@Binding var showNumericBreakdownSheet
    
    var data: DashboardData {
        model.data
    }
    
    var body: some View {
        //NavigationStack {
            List {
                Section {
                    line(title: "Wages", value: data.debitAmounts.regularIncome)
                    line(title: "Cash Inflow", value: data.debitAmounts.irregularIncome)
//                    line(title: "Credit In", value: data.creditAmounts.irregularIncome)
                    line(title: "Total", value: (data.debitAmounts.regularIncome + data.debitAmounts.irregularIncome))
                        .bold()
                } header: {
                    Text("Income")
                } footer: {
                    Text("Wages + Cash Inflow = Total")
                }
                
                Section {
                    line(title: "Cash Outflow", value: data.debitAmounts.totalSpend)
                    line(title: "Credit Outflow", value: data.creditAmounts.totalSpend)
                    line(title: "Total", value: data.allAmounts.totalSpend)
                        .bold()
                    line(title: "Refunds & Reimbursements", value: (data.creditAmounts.irregularIncome + data.debitAmounts.irregularIncome))
                    line(title: "Total (after refunds)", value: data.allAmounts.actualSpend)
                        .bold()
                } header: {
                    Text("Spending")
                } footer: {
                    VStack(alignment: .leading) {
                        Text("Cash Outflow + Credit Outflow = Total")
                        Text("Total - Refunds & Reimbursement = Total (after refunds)")
                    }
                }
                
                Section {
                    line(title: "Outflow", value: data.creditAmounts.totalSpend)
                    line(title: "Inflow", value: data.creditAmounts.irregularIncome)
                    line(title: "Total", value: data.creditAmounts.actualSpend)
                        .bold()
                    
                    line(title: "Payments", value: data.creditAmounts.creditPayment ?? 0.0)
                    
                    line(title: "Total (after payments)", value: data.creditAmounts.actualSpendMinusPayment)
                        .bold()
                } header: {
                    Text("Credit")
                } footer: {
                    VStack(alignment: .leading) {
                        Text("Outflow - Inflow = Total")
                        Text("Total - Payments = Total (after payments)")
                    }
                    
                }
            }
            .navigationTitle("Details")
            .if(!isForSelectedMonth) {
                $0.navigationSubtitle("\(model.formattedDateRange)")
            }
//            .toolbar {
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button {
//                        #if os(iOS)
//                        withAnimation {
//                            showNumericBreakdownSheet = false
//                        }
//                        #else
//                        dismiss()
//                        #endif
//                    } label: {
//                        Image(systemName: "xmark")
//                    }
//                    .tint(.none)
//                    #if os(macOS)
//                    .buttonStyle(.roundMacButton)
//                    #endif
//                }
//            }
        //}
    }
    
    @ViewBuilder
    func line(title: String, value: Double) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value.currencyWithDecimals())
                .contentTransition(.numericText())
        }
    }
}



struct DashboardTransactionList: View {
    @Environment(CalendarModel.self) private var calModel
    var data: DashboardData
    var category: CBCategory
    
    @State private var transactions: [CBTransaction] = []
    @State private var transEditID: String?
    @State private var editTrans: CBTransaction?
    @State private var transDay: CBDay? = CBDay(date: Date())
    
    @State private var isLoading = true
    
    var expenses: [CBTransaction] {
        calModel.dashboardTransactions.filter { $0.isExpense }
    }
    
    var income: [CBTransaction] {
        calModel.dashboardTransactions.filter { $0.isIncome }
    }
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .tint(.none)
            } else if calModel.dashboardTransactions.isEmpty {
                ContentUnavailableView("No Transactions", systemImage: "square.stack.3d.up.slash.fill")
            } else {
                List {
                    if !expenses.isEmpty {
                        
                        Section {
                            ForEach(expenses) { trans in
                                TransactionListLine(trans: trans, withDate: true, withTags: true, withPhotos: true) {
                                    self.transEditID = trans.id
                                }
                            }
                        } header: {
                            Text("Expenses")
                        } footer: {
                            Text("Total: \((category.allAmounts?.actualSpend ?? 0).currencyWithDecimals())")
                        }
                    }
                    
                    if !income.isEmpty {
                        Section {
                            ForEach(income) { trans in
                                TransactionListLine(trans: trans, withDate: true, withTags: true, withPhotos: true) {
                                    self.transEditID = trans.id
                                }
                            }
                        } header: {
                            Text("Income")
                        } footer: {
                            Text("Total: \(((category.allAmounts?.regularIncome ?? 0) + (category.allAmounts?.irregularIncome ?? 0)).currencyWithDecimals())")
                        }
                    }
                }
            }
        }
        .navigationTitle("Transactions")
        .navigationSubtitle(category.title)
        .transactionEditSheetAndLogic(
            transEditID: $transEditID,
            selectedDay: $transDay,
            findTransactionWhere: .constant(.dashboardList)
        )
        .task {
            await search(calModel: calModel, sortOrder: .reverse)
        }
        .onDisappear {
            calModel.dashboardTransactions.removeAll()
        }
    }
    
    @MainActor
    func search(calModel: CalendarModel, sortOrder: SortOrder) async {
        print("-- \(#function)")
        let searchModel = AdvancedSearchModel()
        searchModel.categories = [category]
        searchModel.beginDate = data.beginDate
        searchModel.endDate = data.endDate
        LogManager.log()
        
        //print(category.id)
        //return
        
        let model = RequestModel(requestType: "new_advanced_search", model: searchModel)
        typealias ResultResponse = Result<Array<CBTransaction>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            if let model {
                for each in model {
                    await each.payMethod?.loadLogoFromCoreDataIfNeeded()
                }
                
                if sortOrder == .forward {
                    calModel.dashboardTransactions = model.sorted { $0.date ?? Date() > $1.date ?? Date() }
                } else {
                    calModel.dashboardTransactions = model.sorted { $0.date ?? Date() < $1.date ?? Date() }
                }
            }
            
        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("calModel fetchFrom Server Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch transactions.")
            }
        }
        
        isLoading = false
    }
}


fileprivate struct DashboardNetWorthChange: View {
    @Environment(CalendarModel.self) private var calModel
    
    @State private var showAllAccounts = false
    
    var allDebitStart: CBStartingAmount? {
        calModel.sMonth.startingAmounts.filter { $0.payMethod.isUnifiedDebit }.first
    }
    
    var allCreditStart: CBStartingAmount? {
        calModel.sMonth.startingAmounts.filter { $0.payMethod.isUnifiedCredit }.first
    }
    
    var starts: Array<CBStartingAmount> {
        calModel.sMonth.startingAmounts
            .filter { $0.payMethod.isPermittedAndNotHidden }
            .filter { !$0.payMethod.isUnified }
            .filter {
                $0.payMethod.matchesFilter()
//                switch AppSettings.shared.paymentMethodFilterMode {
//                case .all:
//                    return true
//                    
//                case .justPrimary:
//                    return $0.payMethod.holderOne?.id == AppState.shared.user?.id
//                    
//                case .primaryAndSecondary:
//                    return $0.payMethod.holderOne?.id == AppState.shared.user?.id
//                    || $0.payMethod.holderTwo?.id == AppState.shared.user?.id
//                    || $0.payMethod.holderThree?.id == AppState.shared.user?.id
//                    || $0.payMethod.holderFour?.id == AppState.shared.user?.id
//                }
            }
            .sorted { Helpers.paymentMethodSorter()($0.payMethod, $1.payMethod) }
    }
    
    var allStart: Double {
        let allDebitAssets = allDebitStart?.amount ?? 0.0
        let allOtherAssets = starts.filter {
            $0.payMethod.accountType == .savings
            || [.investment, .brokerage, .k401, .crypto, .cash].contains($0.payMethod.accountType)
        }
        .map { $0.amount }
        .reduce(0.0, +)
                    
        let allCreditLiabilities = allCreditStart?.amount ?? 0.0
        let allOtherLiabilities = starts.filter {
            $0.payMethod.accountType == .loan
        }
        .map { $0.amount }
        .reduce(0.0, +)
        
        let allAssets = allDebitAssets + allOtherAssets
        let allLiabilities = allCreditLiabilities + allOtherLiabilities
        
        let networth = allAssets - allLiabilities
        return networth
//            let start = CBStartingAmount()
//            start.month = calModel.sMonth.actualNum
//            start.year = calModel.sMonth.year
//            start.amountString = String(networth)
//            start.payMethod.title = "All Accounts"
//            return start
    }
    
    var body: some View {
        Grid(alignment: .leading) {
            GridRow {
                Text("Account")
                Text("Start")
                Text("End")
                Text("Differ")
                Text("Percent")
            }
            .bold()
            
            Divider()
            
            GridRow {
                AllAccountsNetWorthChangeView(startingAmount: allStart)
            }
            //Divider()
            
            Divider()
                
            
            if let allDebitStart {
                GridRow {
                    NetWorthChangeView(startingAmount: allDebitStart)
                }
                //.padding(.top, 20)
                Divider()
            }
            
            if let allCreditStart {
                GridRow {
                    NetWorthChangeView(startingAmount: allCreditStart)
                }
                .padding(.bottom, 20)
                //Divider()
            }
                                    
            if showAllAccounts {
//                Divider()
//                    .padding(.top, 20)
                
                ForEach(starts) { star in
                    GridRow {
                        NetWorthChangeView(startingAmount: star)
                    }
                    Divider()
                }
                
            }
            
            Button(showAllAccounts ? "Hide Individual Accounts" : "Show Individual Accounts") {
                showAllAccounts.toggle()
            }
        }
        .font(.caption)
    }
            
    
    struct NetWorthChangeView: View {
        @Environment(DataChangeTriggers.self) var dataChangeTriggers
        @Environment(CalendarModel.self) private var calModel
        
        var startingAmount: CBStartingAmount
        @State private var eom: Double = 0.0
        @State private var change: Double = 0.0
        @State private var percentage: Double = 0.0
        @State private var isBeneficial: Bool = true
        
        var body: some View {
            Group {
                HStack {
                    BusinessLogo(config: .init(
                        parent: startingAmount.payMethod,
                        fallBackType: startingAmount.payMethod.isUnified ? .gradient : .color,
                        size: 20
                    ))
                    
                    Text(startingAmount.payMethod.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Text(startingAmount.amount.currencyWithDecimals())
                
                Text("\(eom.currencyWithDecimals())")
                
                Text("\(change.currencyWithDecimals())")
                    .foregroundStyle(isBeneficial ? Color.red : Color.green)
                
                Text("\(percentage.decimals(1))%")
                    .foregroundStyle(isBeneficial ? Color.red : Color.green)
            }
            .task {
                calculate()
            }
            .onChange(of: DataChangeTriggers.shared.calendarDidChange) { oldValue, newValue in
                calculate()
            }
        }
        
        func calculate() {
            eom = calModel.calculateTotal(for: calModel.sMonth, using: startingAmount.payMethod, and: .giveMeLastDayEod)
            let change = eom - startingAmount.amount
            self.change = abs(change)
            percentage = abs(Helpers.netWorthPercentageChange(start: startingAmount.amount, end: eom))
            
            if startingAmount.payMethod.isCreditOrLoan || startingAmount.payMethod.isUnifiedCredit {
                isBeneficial = change > 0
            } else {
                isBeneficial = change < 0
            }
        }
    }
    
    
    struct AllAccountsNetWorthChangeView: View {
        @Environment(DataChangeTriggers.self) var dataChangeTriggers
        @Environment(CalendarModel.self) private var calModel
        
        var startingAmount: Double
        @State private var eom: Double = 0.0
        @State private var change: Double = 0.0
        @State private var percentage: Double = 0.0
        @State private var isBeneficial: Bool = true
        
        var body: some View {
            Group {
                HStack {
                    let rainbowGradient = Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red])
                    
                    Image(systemName: "circle.fill")
                        .font(Font.system(size: 20))
                        .imageScale(.medium)
                        .frame(width: 20, height: 20, alignment: .center)
                        .foregroundStyle(AngularGradient(gradient: rainbowGradient, center: .center))
                                        
                    Text("All Accounts")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Text(startingAmount.currencyWithDecimals())
                
                Text("\(eom.currencyWithDecimals())")
                
                Text("\(change.currencyWithDecimals())")
                    .foregroundStyle(isBeneficial ? Color.red : Color.green)
                
                Text("\(percentage.decimals(1))%")
                    .foregroundStyle(isBeneficial ? Color.red : Color.green)
            }
            .task {
                calculate()
            }
            .onChange(of: DataChangeTriggers.shared.calendarDidChange) { oldValue, newValue in
                calculate()
            }
        }
        
        
        func calculate() {
            eom = calculateBalance()
            
            let change = eom - startingAmount
            self.change = abs(change)
            percentage = abs(Helpers.netWorthPercentageChange(start: startingAmount, end: eom))
            
            if startingAmount < 0 && eom < 0 {
                isBeneficial = eom < startingAmount
            } else {
                isBeneficial = eom > startingAmount
            }
        }
        
        
        private func calculateBalance() -> Double {
            var finalEodTotal: Double = 0.0
            var currentAmount = startingAmount
            
            calModel.sMonth.days.forEach { day in
                let amounts = day.transactions
                    .filter { $0.active }
                    .filter { $0.factorInCalculations }
                    .filter { ($0.payMethod?.isPermittedAndNotHidden ?? true) }
                    .map { ($0.payMethod?.isCreditOrLoan ?? false) ? $0.amount * -1 : $0.amount }
                    //.map { $0.amount }
                
                currentAmount += amounts.reduce(0.0, +)
                if day.id == calModel.sMonth.days.last?.id {
                    finalEodTotal = currentAmount
                }
            }
            return finalEodTotal
        }
    }
}


fileprivate struct DashboardWidget<TitleContent: View, Content: View>: View {
    private let title: String?
    private let titleContent: TitleContent
    private let content: Content

    init(
        title: String,
        @ViewBuilder content: () -> Content
    ) where TitleContent == EmptyView {
        self.title = title
        self.titleContent = EmptyView()
        self.content = content()
    }

    init(
        @ViewBuilder title: () -> TitleContent,
        @ViewBuilder content: () -> Content
    ) {
        self.title = nil
        self.titleContent = title()
        self.content = content()
    }

    init(
        @ViewBuilder content: () -> Content
    ) where TitleContent == EmptyView {
        self.title = nil
        self.titleContent = EmptyView()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title)
                    .padding(.leading, 12)
                    .foregroundStyle(.secondary)
                    .font(.headline)

            } else if !(TitleContent.self == EmptyView.self) {
                titleContent
            }

            content
                .frame(maxWidth: .infinity)
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color(.secondarySystemGroupedBackground))
                }
        }
    }
}


struct ForEachWithSeparator<Data: RandomAccessCollection, Content: View, Separator: View>: View where Data.Element: Identifiable {
    let data: Data
    let content: (Data.Element) -> Content
    let separator: () -> Separator
    let includeLastSeparator: Bool
    
    init(
        _ data: Data,
        includeLastSeparator: Bool = false,
        @ViewBuilder content: @escaping (Data.Element) -> Content,
        @ViewBuilder separator: @escaping () -> Separator = { Divider() }
    ) {
        
        self.data = data
        self.content = content
        self.separator = separator
        self.includeLastSeparator = includeLastSeparator
    }
    
    var body: some View {
        let array = Array(data)
        
        ForEach(array.indices, id: \.self) { index in
            content(array[index])
            
            if (index != array.count - 1 || includeLastSeparator) {
                separator()
            }
        }
    }
}
