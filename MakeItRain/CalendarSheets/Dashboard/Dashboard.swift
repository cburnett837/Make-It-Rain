//
//  Dashboard.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/21/26.
//

import SwiftUI
import Charts


enum DashboardNavDest {
    case numericBreakdown, transactionList
}

@Observable
class DashboardDataByMonth: Hashable, Identifiable {
    var id = UUID()
    var dataPoint: CivDataPoint
    var month: CBMonth
    var trans: [CBTransaction]
    var breakdown: CivBreakdownData
    var dataByCategory: [CivBreakdownData]
    
    init(id: UUID = UUID(), dataPoint: CivDataPoint, month: CBMonth, trans: [CBTransaction], breakdown: CivBreakdownData, dataByCategory: [CivBreakdownData]) {
        self.id = id
        self.dataPoint = dataPoint
        self.month = month
        self.trans = trans
        self.breakdown = breakdown
        self.dataByCategory = dataByCategory
    }
    
    static func == (lhs: DashboardDataByMonth, rhs: DashboardDataByMonth) -> Bool {
        lhs.month.id == rhs.month.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(month.id)
    }
}


@Observable
class DashboardAmounts: Decodable {
    var regularIncome: Double = 0.0 /// Salary, calculated by any category that is of type "income".
    var irregularIncome: Double = 0.0 /// Reimbursements, refunds, gifts, etc.
    
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
    
    enum CodingKeys: CodingKey { case regular_income, irregular_income, total_spend, actual_spend, actual_spend_minus_regular_income, actual_spend_minus_payment, variance, credit_payment }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
                        
        self.regularIncome = try container.decode(Double.self, forKey: .regular_income)
        self.irregularIncome = try container.decode(Double.self, forKey: .irregular_income)
        
        self.totalSpend = try container.decode(Double.self, forKey: .total_spend)
        self.actualSpend = try container.decode(Double.self, forKey: .actual_spend)
        self.actualSpendMinusRegularIncome = try container.decode(Double.self, forKey: .actual_spend_minus_regular_income)
        self.actualSpendMinusPayment = try container.decode(Double.self, forKey: .actual_spend_minus_payment)
        
        self.variance = try container.decodeIfPresent(Double.self, forKey: .variance)
        self.creditPayment = try container.decodeIfPresent(Double.self, forKey: .credit_payment)
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
class DashboardData: Codable {
    var beginDate: Date = Date().startDateOfMonth
    var endDate: Date = Date().endDateOfMonth
    
    var budgetAmount: Double = 0.0
    var debitAmounts: DashboardAmounts = DashboardAmounts()
    var creditAmounts: DashboardAmounts = DashboardAmounts()
    var allAmounts: DashboardAmounts = DashboardAmounts()
    
    var categories: [CBCategory] = []
    var categoryGroups: [CBCategoryGroup] = []
    //var monthlyBreakdowns: [DashboardDataByMonth] = []
    
            
    init() {}
    
    enum CodingKeys: CodingKey { case categories, category_groups, user_id, account_id, device_uuid, begin_date, end_date, budget_amount, debit_amounts, credit_amounts, all_amounts }
    
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
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.budgetAmount = try container.decode(Double.self, forKey: .budget_amount)
        self.debitAmounts = try container.decode(DashboardAmounts.self, forKey: .debit_amounts)
        self.creditAmounts = try container.decode(DashboardAmounts.self, forKey: .credit_amounts)
        self.allAmounts = try container.decode(DashboardAmounts.self, forKey: .all_amounts)
        self.categories = try container.decode([CBCategory].self, forKey: .categories)
        self.categoryGroups = try container.decode([CBCategoryGroup].self, forKey: .category_groups)
    }
    
//    func setFromAnotherInstance(_ other: DashboardModel) {
//        self.budgetAmount = other.budgetAmount
//        self.debitAmounts.income = other.debitAmounts.income
//        self.debitAmounts.expense = other.debitAmounts.expense
//        self.debitAmounts.expenseMinusIncome = other.debitAmounts.expenseMinusIncome
//        self.debitAmounts.expenseMinusPayment = other.debitAmounts.expenseMinusPayment
//        self.debitAmounts.variance = other.debitAmounts.variance
//        
//        self.creditAmounts.income = other.creditAmounts.income
//        self.creditAmounts.expense = other.creditAmounts.expense
//        self.creditAmounts.expenseMinusIncome = other.creditAmounts.expenseMinusIncome
//        self.creditAmounts.expenseMinusPayment = other.creditAmounts.expenseMinusPayment
//        self.creditAmounts.variance = other.creditAmounts.variance
//        
//        self.allAmounts.income = other.allAmounts.income
//        self.allAmounts.expense = other.allAmounts.expense
//        self.allAmounts.expenseMinusIncome = other.allAmounts.expenseMinusIncome
//        self.allAmounts.expenseMinusPayment = other.allAmounts.expenseMinusPayment
//        self.allAmounts.variance = other.allAmounts.variance
//        
//        let newCatIds = other.categories.map(\.id)
//        let newGroupIds = other.categoryGroups.map(\.id)
//        
//        self.categories.removeAll { !newCatIds.contains($0.id) }
//        self.categoryGroups.removeAll { !newGroupIds.contains($0.id) }
//        
//        
//        for category in other.categories {
//            if let index = self.categories.firstIndex(where: { $0.id == category.id }) {
//                self.categories[index].setFromAnotherInstance(category: category)
//            } else {
//                self.categories.append(category)
//            }
//        }
//        
//        for group in other.categoryGroups {
//            if let index = self.categoryGroups.firstIndex(where: { $0.id == group.id }) {
//                self.categoryGroups[index].setFromAnotherInstance(group: group)
//            } else {
//                self.categoryGroups.append(group)
//            }
//        }
//    }
}


@Observable
class DashboardViewModel {
    var beginDate: Date = Date().startDateOfMonth
    var endDate: Date = Date().endDateOfMonth
    var categories: [CBCategory] = []
    var groups: [CBCategoryGroup] = []
    
    var data = DashboardData()
    var isLoading = false
    var showDateRangeSheet = false
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
    
    weak var calModel: CalendarModel?
    init(calModel: CalendarModel) {
        self.calModel = calModel
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
    func initialFetchIfApplicable(catModel: CategoryModel) async {
        if let calModel = self.calModel {
            for group in catModel.categoryGroups {
                if groups.map({ $0.id }).contains(group.id) { continue }
                
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
        } else {
            AppState.shared.showAlert("Could not fetch dashboard. (Broke cal ref)")
        }
        
    }
    
    
    @MainActor
    func fetchDashboard() async {
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
                //self.data = model
                withAnimation {
                    self.data = model
                    //self.data.setFromAnotherInstance(model)
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
}



struct Dashboard: View {
    private enum WhichView: String { case overview, categories }
    @AppStorage("CategoryInsightsOnlyUntilToday") private var onlyUpUntilToday = false
    @AppStorage("categoryInsightSheetViewMode") private var whichView: WhichView = .overview
    
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
    @Bindable var model: DashboardViewModel
    var isForSelectedMonth: Bool
    
    @State private var showCategorySheet = false
    @State private var showDateRangeSheet = false
    @State private var showNumericBreakdownSheet = false
    
    var categoryFilterTitle: LocalizedStringKey {
        let cats = model.categories
        let baseText = "Data is only for"
        if cats.isEmpty {
            return ""
            
        } else if cats.count == 1 {
            return "(\(baseText) **\(cats[0].title)**)"
            
        } else if cats.count == 2 {
            return "(\(baseText) **\(cats[0].title)** & **\(cats[1].title)**)"
            
        } else {
            return "(\(baseText) **\(cats[0].title)**, **\(cats[1].title)**, and **\(cats.count - 2)** others)"
        }
    }
    
    var isAnalyzingAtLeastOneCreditCategory: Bool {
        !calModel
            .sCategoriesForAnalysis
            .filter { $0.type.enumID == XrefModel.getItem(from: .categoryTypes, byEnumID: .payment).enumID }
            .isEmpty
    }
    
    @State private var oldChangeHash: Int = 0
    var changeHash: Int {
        var hasher = Hasher()
        hasher.combine(model.beginDate)
        hasher.combine(model.endDate)
        hasher.combine(model.categories)
        hasher.combine(model.groups)
        return hasher.finalize()
    }
    
    
    var body: some View {
        @Bindable var calModel = calModel
        content
            .navigationTitle("Dashboard\(AppState.shared.devMode ? " (Dev)" : "")")
            #if os(iOS)
            .navigationBarTitleDisplayMode(isForSelectedMonth ? .inline : .large)
            #endif
            .task {
                oldChangeHash = changeHash
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
            .sheet(isPresented: $model.showDateRangeSheet, onDismiss: fetchFromServer) {
                DashboardDateRangeSheet(model: model)
                    .interactiveDismissDisabled(true)
                    .presentationDetents([.height(300), .medium])
            }
            .sheet(isPresented: $showCategorySheet, onDismiss: fetchFromServer) {
                MultiCategorySheet(
                    categories: $model.categories,
                    categoryGroups: $model.groups,
                    showAnalyticSpecificOptions: true
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
            List {
                if isForSelectedMonth {
                    Section("Net Worth Change \(calModel.sMonth.name) \(String(calModel.sMonth.year))") {
                        DashboardNetWorthChange()
                    }
                }
                
                
                if AppState.shared.isIphone {
                    DashboardDetailSection(data: model.data)
                } else {
                    NavigationStack(path: $navPath) {
                        DashboardDetailSection(data: model.data)
                    }
                }
                
                Section {
                    DashboardCompareChart(model: model, data: model.data)
                } header: {
                    VStack(alignment: .leading) {
                        Text("Actual Spending")
                    }
                }
                
                DashboardBudgetBreakdown(model: model)
            }
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
            
    
    func fetchFromServer() {
        if !model.categories.isEmpty || !model.groups.isEmpty {
            if changeHash != oldChangeHash {
                oldChangeHash = changeHash
                Task {
                    await model.fetchDashboard()
                }
            }
        }
    }
}


fileprivate struct DashboardToolbar: ToolbarContent {
    @Environment(CalendarModel.self) private var calModel
    
    @Bindable var model: DashboardViewModel
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
        } else {
            if isForSelectedMonth {
                ToolbarSpacer(.fixed, placement: .topBarLeading)
                if !model.categories.isEmpty || !model.groups.isEmpty {
                    ToolbarItem(placement: .topBarLeading) { showCalendarButton }
                    ToolbarSpacer(.fixed, placement: .topBarLeading)
                }
            }
        }
        
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
        }
        
        if !isForSelectedMonth {
            ToolbarItem(placement: .topBarLeading) { showDateRangeSheetButton }
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
    
    
    var showDateRangeSheetButton: some View {
        Button {
            model.showDateRangeSheet = true
        } label: {
            Text("\(model.formattedDateRange)")
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
                withAnimation {
                    navPath.removeLast()
                }
            }
            #else
            //dismiss()
            #endif
            
        } label: {
            Label {
                Text("View Filtered Calendar")
            } icon: {
                Image(systemName: "calendar")
            }
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


fileprivate struct DashboardDateRangeSheet: View {
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: DashboardViewModel
    
    var body: some View {
        NavigationStack {
            List {
                DatePicker("Begin Date", selection: $model.beginDate, displayedComponents: [.date])
                DatePicker("End Date", selection: $model.endDate, in: model.beginDate..., displayedComponents: [.date])
                
                ScrollView(.horizontal) {
                    HStack {
                        Button("Selected Month") {
                            model.beginDate = calModel.sMonth.days.first(where: { !$0.isPlaceholder })?.date ?? Date()
                            model.endDate = calModel.sMonth.days.last?.date ?? Date()
                        }
                        
                        let currentMonthName = NavDestination.getMonthFromInt(AppState.shared.todayMonth)?.displayName
                        Button("\(currentMonthName ?? "N/A") \(String(AppState.shared.todayYear))") {
                            let now = Date()
                            model.beginDate = now.startDateOfMonth
                            model.endDate = now.endDateOfMonth
                        }
                        
                        Button("This Quarter") {
                            let now = Date()
                            model.beginDate = now.startDateOfQuarter
                            model.endDate = now.endDateOfQuarter
                        }
                        
                        Button("This Year") {
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
            //.listStyle(.)
            //.padding()
            .navigationTitle("Select Date Range")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        #if os(iOS)
                        withAnimation {
                            model.showDateRangeSheet = false
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
    @Bindable var data: DashboardData
    
    var amount: Double { data.budgetAmount - (data.allAmounts.actualSpend) }
    var isOver: Bool { amount < 0 }
    var overUnder: String { abs(amount).currencyWithDecimals() }
    
    var message: AttributedString {
        var result = AttributedString("With a budget of \(data.budgetAmount.currencyWithDecimals()), you are currently ")

        var amountPart = AttributedString(overUnder)
        amountPart.foregroundColor = isOver ? .red : .green
        result.append(amountPart)
        
        result.append(AttributedString(" \(isOver ? "over-budget" : "under-budget"), having spent "))
        
        var spending = AttributedString(data.allAmounts.actualSpend.currencyWithDecimals())
        spending.font = .body.bold()
        result.append(spending)

        //result.append(AttributedString(" across \(transactionCount) transactions."))
        //result.append(AttributedString(" across N/A transactions."))
        result.append(AttributedString("."))
        return result
    }
            
    var body: some View {
        Section {
            Text(message)
        } header: {
            Text("Details")
        }
        #if os(iOS)
        .listSectionSpacing(5)
        #endif
        
        /*
         total_spending =
             cash_transactions
           + debit_transactions
           + credit_card_purchases
           - refunds
           - reimbursements
         
         cash_outflow =
             debit_transactions
           + cash_transactions
           + credit_card_payments
         
         net_worth_change =
             income
           - true_spending
         
         
         ⚠️ Important nuance (for your charts)
         If you’re showing:
             •    Spending charts → include credit purchases
             •    Cash charts → include payments

         Never mix them.
         
         */
        
        Section {
            NavigationLink(value: CalendarNavDest.dashboardNumericBreakdown) {
                Grid(alignment: .leading) {
                    GridRow {
                        Text("Money In")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                        
                        Text("Spending")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                        
                        Text("Credit Payments")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                    }
                    .bold()
                    
                    Divider()
                    
                    GridRow {
                        Text((data.debitAmounts.regularIncome + data.debitAmounts.irregularIncome).currencyWithDecimals())
                            .contentTransition(.numericText())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                        
                        Text(data.allAmounts.actualSpend.currencyWithDecimals())
                            .contentTransition(.numericText())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                            .bold()
                        
                        Text((data.creditAmounts.creditPayment ?? 0.0).currencyWithDecimals())
                            .contentTransition(.numericText())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                    }
                }
                .font(.caption)
            }
//            Button {
//                showNumericBreakdownSheet = true
//            } label: {
//                
//            }
//            .contentShape(Rectangle())
//            .buttonStyle(.plain)
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
}


fileprivate struct DashboardCompareChart: View {
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: DashboardViewModel
    @Bindable var data: DashboardData
    
    @State private var rawSelectedAngle: Double?
    @State private var rawSelectedBar: Double?
    private var selectedCategory: CBCategory? {
        //print("\(rawSelectedBar) - \(rawSelectedAngle)")
        var theValue: Double = 0.0
        if rawSelectedBar == nil && rawSelectedAngle == nil { return nil }
        if let raw = rawSelectedBar { theValue = raw }
        if let raw = rawSelectedAngle { theValue = raw }
        //guard let rawSelectedAngle else { return nil }
        
        var total = 0.0
        for cat in categories {
            let value = max(0, (cat.allAmounts?.totalSpend ?? 0.0))
            let nextTotal = total + value
            
            if theValue >= total && theValue < nextTotal {
                return cat
            }
            
            total = nextTotal
        }
        
        return nil
    }
    
    var isUnderBudget: Bool {
        return data.budgetAmount >= data.categories.map ({ $0.allAmounts?.actualSpend ?? 0.0 }).reduce(0.0, +)
    }
   
    var categories: [CBCategory] {
        return (data.categories + data.categoryGroups.flatMap(\.categories))
            //.filter { $0.type != XrefModel.getItem(from: .categoryTypes, byEnumID: .income) }
            .uniqued(on: { $0.id })
            .sorted(by: Helpers.categorySorter())
    }
    
    var expenseCategories: [CBCategory] { categories.filter { !$0.isIncome } }
    var incomeCategories: [CBCategory] { categories.filter { $0.isIncome } }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                barChart
                pieChart
            }
            
            DashboardChartLegend(data: data)
        }
        .sensoryFeedback(.selection, trigger: selectedCategory)
    }
    
    
    var pieChart: some View {
        Chart(expenseCategories) { cat in
            SectorMark(
                angle: .value("Amount", (cat.allAmounts?.totalSpend ?? 0.0)),
                innerRadius: .ratio(0.4),
                angularInset: 1.0
            )
            .cornerRadius(5)
            .foregroundStyle(cat.color)
            .opacity(selectedCategory == nil ? 1 : (cat.id == selectedCategory!.id ? 1 : 0.3))
        }
        .chartAngleSelection(value: $rawSelectedAngle)
        .frame(minHeight: 150)
        .overlay {
            if rawSelectedBar != nil, selectedCategory != nil {
                categoryAnnotation
            }
        }
    }
    
    
    var barChart: some View {
        Chart {
            if model.groups.isEmpty {
                ForEach(expenseCategories) { cat in
                    BarMark(
                        x: .value("Budget", cat.budgetAmount),
                        //y: .value("Category", cat.title)
                        y: .value("Key", "Budget")
                    )
                    .foregroundStyle(cat.color)
                }
            } else {
                RuleMark(
                    x: .value("Budget", data.budgetAmount),
                    yStart: .value("Start", "Actual Spending"),
                    yEnd: .value("End", "Actual Spending")
                )
                .foregroundStyle(isUnderBudget ? Color.green.gradient : Color.red.gradient)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                .zIndex(1)
            }
                                    
            ForEach(expenseCategories) { cat in
                BarMark(
                    x: .value("Amount", cat.allAmounts?.actualSpend ?? 0.0),
                    y: .value("Key", "Actual Spending")
                )
                .foregroundStyle(cat.color)
                .opacity(selectedCategory == nil ? 1 : (cat.id == selectedCategory!.id ? 1 : 0.3))
                .zIndex(0)
            }
            
            ForEach(incomeCategories) { cat in
                let amount = cat.isRegularIncome ? cat.allAmounts?.regularIncome : cat.allAmounts?.irregularIncome
                BarMark(
                    x: .value("Amount", amount ?? 0.0),
                    y: .value("Key", "Income")
                )
                .foregroundStyle(cat.color)
                //.opacity(selectedCategory == nil ? 1 : (cat.id == selectedCategory!.id ? 1 : 0.3))
                .zIndex(0)
            }
        }
        .chartXSelection(value: $rawSelectedBar)
        .chartXAxis {
            AxisMarks {
                let value = $0.as(Int.self)!
                AxisGridLine()
                //AxisTick()
                //AxisValueLabel(format: .currency(code: "USD"))
                AxisValueLabel { Text("$\(value)") }
            }
        }
        .if(!model.groups.isEmpty) {
            $0.chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
//                    if incomeCategories.count > 0 {
//                        AxisValueLabel()
//                    }
                    
                    // Do not include AxisValueLabel() here to hide labels
                }
            }
        }
        .chartLegend(.hidden)
        //.opacity(selectedCategory == nil ? 1 : 0)
        .overlay {
            if rawSelectedAngle != nil, selectedCategory != nil {
                categoryAnnotation
            }
        }
    }
    
    
    var categoryAnnotation: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(selectedCategory!.title.capitalized)
                    .lineLimit(1)
                Spacer()
                
                ChartCircleDot(
                    budget: selectedCategory!.budgetAmount,
                    expenses: abs(selectedCategory!.allAmounts?.totalSpend ?? 0.0),
                    color: .white,
                    size: 20
                )
                
                Image(systemName: selectedCategory!.emoji ?? "circle")
            }
            .font(.headline)
            
            Divider()
            
            Grid(alignment: .leading) {
                GridRow {
                    Text("Budget").bold()
                    Text(selectedCategory!.budgetAmount.currencyWithDecimals())
                }
                GridRow {
                    Text("Income").bold()
                    Text((selectedCategory!.allAmounts?.irregularIncome ?? 0.0).currencyWithDecimals())
                }
                GridRow {
                    Text("Expenses").bold()
                    Text((selectedCategory!.allAmounts?.totalSpend ?? 0.0).currencyWithDecimals())
                }
                
                Divider()
                
                GridRow {
                    Text("Actual Spend").bold()
                    Text(((selectedCategory!.allAmounts?.actualSpend ?? 0.0)).currencyWithDecimals())
                }
            }
            .font(.subheadline)
        }
        .if(selectedCategory!.isNil) {
            $0.schemeBasedReversedForegroundStyle()
        }
        .if(!selectedCategory!.isNil) {
            $0.schemeBasedForegroundStyle()
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(selectedCategory!.color)
        )
        .accessibilityHidden(true)
    }
}


fileprivate struct DashboardBudgetBreakdown: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(CalendarModel.self) private var calModel
    
    @Bindable var model: DashboardViewModel
    
    @State private var breakdownOrChart = "breakdown"
    @State private var rawSelectedData: String?
    //@State private var groupData: [GroupChartData] = []
    @State private var rowWidth: CGFloat = 0

    
    var firstColumnWidth: Double {
        rowWidth / 4
    }
    
    var body: some View {
        Section {
            breakdownLines
                .font(.caption)
        } header: {
            Text("Breakdown")
        }
        .lineLimit(1)
        .textCase(nil)
    }
    
    
    @ViewBuilder
    var breakdownLines: some View {
        gridHeader
        
        ForEach(model.data.categoryGroups) { group in
            HStack {
                HStack {
                    GradientCircleDot(size: 12, colors: group.categories.map(\.color))
                    Button(group.title) {
                        withAnimation {
                            group.isExpanded.toggle()
                        }
                    }
                }
                .frame(width: firstColumnWidth, alignment: .leading)
                
                Text(group.budgetAmount.currencyWithDecimals())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentTransition(.numericText())
                    
                Text(group.allAmounts?.totalSpend.currencyWithDecimals() ?? "N/A")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentTransition(.numericText())
                                            
                Text(group.allAmounts?.irregularIncome.currencyWithDecimals() ?? "N/A")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentTransition(.numericText())
                                            
                Text(abs(group.allAmounts?.variance ?? 0).currencyWithDecimals())
                    .foregroundStyle(group.allAmounts?.variance ?? 0 < 0 ? .red : .green)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentTransition(.numericText())
            }
            
            if group.isExpanded {
                ForEach(group.categories.sorted(by: Helpers.categorySorter())) { cat in
                    line(for: cat, isPartOfGroup: true)
                }
            }
        }
        
        ForEach(model.data.categories.sorted(by: Helpers.categorySorter() ), id: \.id) { cat in
            line(for: cat, isPartOfGroup: false)
        }
    }
    
    var gridHeader: some View {
        HStack {
            HStack {
                ChartCircleDot(budget: 0, expenses: 0, color: .primary, size: 12)
                Text("Category")
            }
            .frame(width: firstColumnWidth, alignment: .leading)
            
            Text("Budget")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Expense")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Income")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Variance")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.caption)
        .lineLimit(1)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { self.rowWidth = $0 }
    }
    
    
    @ViewBuilder
    func line(for cat: CBCategory, isPartOfGroup: Bool) -> some View {
        HStack {
            HStack {
                ChartCircleDot(
                    budget: cat.isIncome ? 100 : cat.budgetAmount,
                    expenses: cat.isIncome ? 100 : cat.allAmounts?.totalSpend ?? 0.0,
                    color: cat.color,
                    size: 12
                )
                //.alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                
                Text(cat.title)
                    //.alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
            }
            .padding(.leading, isPartOfGroup ? 10 : 0)
            //.frame(maxWidth: .infinity, alignment: .leading)
            .frame(width: firstColumnWidth, alignment: .leading)
            
            
            
            
            let value1 = cat.isIncome || isPartOfGroup ? "N/A" : cat.budgetAmount.currencyWithDecimals()
            Text(value1)
                //.padding(.leading, inset ? 10 : 0)
                .foregroundStyle(isPartOfGroup || cat.isIncome ? .gray : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentTransition(.numericText())
                
            let value2 = cat.isIncome ? "N/A" : (cat.allAmounts?.actualSpend ?? 0.0).currencyWithDecimals()
            Text(value2)
                //.padding(.leading, inset ? 10 : 0)
                .foregroundStyle(value2 == "N/A" ? .gray : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentTransition(.numericText())
                                        
            let value3 = cat.isRegularIncome
            ? (cat.allAmounts?.regularIncome ?? 0.0).currencyWithDecimals()
            : (cat.allAmounts?.irregularIncome ?? 0.0).currencyWithDecimals()
            Text(value3)
                //.padding(.leading, inset ? 10 : 0)
                .foregroundStyle(value3 == "N/A" ? .gray : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentTransition(.numericText())
                                        
            let overUnder = (cat.budgetAmount) - (cat.allAmounts?.totalSpend ?? 0.0 + (cat.allAmounts?.irregularIncome ?? 0.0))
            Text(isPartOfGroup || cat.isIncome ? "N/A" : abs(overUnder).currencyWithDecimals())
                //.padding(.leading, inset ? 10 : 0)
                .foregroundStyle(isPartOfGroup || cat.isIncome ? Color.gray : (overUnder < 0 ? .red : .green))
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentTransition(.numericText())
                //.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


/// Not fileprivate because it is used in the navigation destination in ``CalendarViewPhone``
struct DashboardNumericDetails: View {
    @Bindable var data: DashboardData
    //@Binding var showNumericBreakdownSheet
    
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
                    line(title: "Refunds & Reimbursements", value: (data.creditAmounts.irregularIncome + data.debitAmounts.irregularIncome))
                    line(title: "Total", value: data.allAmounts.actualSpend)
                        .bold()
                } header: {
                    Text("Spending")
                } footer: {
                    Text("Cash Outflow + Credit Outflow - Refunds - Reimbursements = Total")
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
            .filter { $0.payMethod.isPermittedAndViewable }
            .filter { !$0.payMethod.isUnified }
            .filter {
                switch AppSettings.shared.paymentMethodFilterMode {
                case .all:
                    return true
                    
                case .justPrimary:
                    return $0.payMethod.holderOne?.id == AppState.shared.user?.id
                    
                case .primaryAndSecondary:
                    return $0.payMethod.holderOne?.id == AppState.shared.user?.id
                    || $0.payMethod.holderTwo?.id == AppState.shared.user?.id
                    || $0.payMethod.holderThree?.id == AppState.shared.user?.id
                    || $0.payMethod.holderFour?.id == AppState.shared.user?.id
                }
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
            
            //Divider()
                
            
            if let allDebitStart {
                GridRow {
                    NetWorthChangeView(startingAmount: allDebitStart)
                }
                .padding(.top, 20)
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
                    if !startingAmount.payMethod.isUnified {
                        #if os(iOS)
                        BusinessLogo(config: .init(
                            parent: startingAmount.payMethod,
                            fallBackType: startingAmount.payMethod.isUnified ? .gradient : .color,
                            size: 20
                        ))
                        #else
                        BusinessLogo(config: .init(
                            parent: startingAmount.payMethod,
                            fallBackType: startingAmount.payMethod.isUnified ? .gradient : .color,
                            size: 20
                        ))
                        .padding(.trailing, 10)
                        #endif
                    }
                    
                    
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
                Text("All Accounts")
                    .frame(maxWidth: .infinity, alignment: .leading)
                
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
                    .filter { ($0.payMethod?.isPermittedAndViewable ?? true) }
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

