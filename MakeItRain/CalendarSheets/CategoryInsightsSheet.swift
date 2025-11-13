//
//  CategoryAnalysisSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/26/24.
//

import SwiftUI
import Charts


@Observable
class CategoryInsightsModel {
    var monthsForAnalysis: [CBMonth] = []
    var transactions: [CBTransaction] = []
    var totalSpent: Double = 0.0
    var spendMinusIncome: Double = 0.0
    var spendMinusPayments: Double = 0.0
    var cashOut: Double = 0.0
    var income: Double = 0.0
    var budget: Double = 0.0
    var chartData: [ChartData] = []
    var cumTotals: [CumTotal] = []
    var progress: Double = 0
    var statusMessage: String = ""
    
    var showLoadingSpinner = false
    var loadingSpinnerTimer: Timer?
    @objc func showLoadingSpinnerViaTimer() {
        showLoadingSpinner = true
    }
    
    func startDelayedLoadingSpinnerTimer() {
        loadingSpinnerTimer = Timer(
            fireAt: Date.now.addingTimeInterval(0.5),
            interval: 0,
            target: self,
            selector: #selector(showLoadingSpinnerViaTimer),
            userInfo: nil,
            repeats: false
        )
        RunLoop.main.add(loadingSpinnerTimer!, forMode: .common)
    }
    
    func stopDelayedLoadingSpinnerTimer() {
        if let loadingSpinnerTimer = self.loadingSpinnerTimer {
            loadingSpinnerTimer.invalidate()
        }
        if showLoadingSpinner {
            showLoadingSpinner = false
        }
        
    }
}

struct CumTotal {
    var day: Int
    var total: Double
}

fileprivate struct InsightCalculatingProgressView: View {
    @Bindable var model: CategoryInsightsModel

    var body: some View {
        ProgressView(value: model.progress)
            .background(Color(.systemBackground))
            .opacity(model.showLoadingSpinner ? 1 : 0)
            .scenePadding(.horizontal)
    }
}

fileprivate enum DataPoint {
    case moneyIn, cashOut, totalSpending, all
    
    var titleString: String {
        switch self {
        case .moneyIn:
            "Money In"
        case .cashOut:
            "Cash Out"
        case .totalSpending:
            "Total Spending"
        case .all:
            "All Transactions"
        }
    }
}

@Observable
fileprivate class MonthlyData: Hashable, Identifiable {
    var id = UUID()
    var dataPoint: DataPoint
    var month: CBMonth
    var trans: [CBTransaction]
    var cost: Double
    
    init(id: UUID = UUID(), dataPoint: DataPoint, month: CBMonth, trans: [CBTransaction], cost: Double) {
        self.id = id
        self.dataPoint = dataPoint
        self.month = month
        self.trans = trans
        self.cost = cost
    }
    
    static func == (lhs: MonthlyData, rhs: MonthlyData) -> Bool {
        lhs.month.id == rhs.month.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(month.id)
    }
}


fileprivate enum ChildNavDestination {
    case monthList, transactionList
}


struct CategoryInsightsSheet: View {
    @Environment(\.colorScheme) var colorScheme
    #if os(macOS)
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appearsActive) var appearsActive
    #endif
    @AppStorage("transactionSortMode") var transactionSortMode: TransactionSortMode = .title
    @AppStorage("categorySortMode") var categorySortMode: SortMode = .title
    @Local(\.useWholeNumbers) var useWholeNumbers
    //@Local(\.colorTheme) var colorTheme

    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(EventModel.self) private var eventModel
    @Binding var showAnalysisSheet: Bool
    @Bindable var model: CategoryInsightsModel
    
    @State private var showCategorySheet = false
    @State private var showMonthSheet = false
    //@State private var isPreparingData = false
    @State private var recalc = false
    @State private var showInfo = false
    @State private var navPath: Array<ChildNavDestination> = []
    @State private var refreshTask: Task<Void, Never>?
    
    //private enum MonthlyData { case income, cashOut, totalSpending, spendingMinusPayments }
    
    @State private var selectedDataPoint: DataPoint? = nil
    @State private var selectedMonthGroup: Array<MonthlyData> = []
    @State private var selectedMonth: MonthlyData?

    
    let columnGrid = Array(repeating: GridItem(.flexible(), spacing: 0), count: 4)
        
    var categoryFilterTitle: LocalizedStringKey {
        let cats = calModel.sCategoriesForAnalysis
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

    
    var body: some View {
        @Bindable var calModel = calModel
        NavigationStack(path: $navPath) {
            VStack(spacing: 0) {
                InsightCalculatingProgressView(model: model)
                    
                StandardContainerWithToolbar(.list) {
                    detailSection
                    chartSection
                    breakdownSection
                    transactionSection
                }
                .navigationTitle("Insights")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbar }
                #endif
                .navigationDestination(for: ChildNavDestination.self) { dest in
                    switch dest {
                    case .monthList:
                        MonthMiddleMan(data: selectedMonthGroup, selectedMonth: $selectedMonth, model: model, navPath: $navPath)
                        
                    case .transactionList:
                        if let selectedMonth {
                            TransactionList(data: selectedMonth, model: model)
                        } else {
                            ContentUnavailableView("Uh Oh!", systemImage: "exclamationmark.triangle.text.page", description: Text("The page you are looking for could not be found."))
                        }
                    }
                }
            }
            .background(Color(.systemBackground)) // force matching
            
        }
        .task { prepareView() }
        /// Needed for the inspector on iPad.
        .onChange(of: showAnalysisSheet) {
            if $1 && !showCategorySheet { showCategorySheet = true }
        }
        .sheet(isPresented: $showCategorySheet, onDismiss: {
            prepareData()
        }, content: {
            MultiCategorySheet(categories: $calModel.sCategoriesForAnalysis, showAnalyticSpecificOptions: true)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        })
        .sheet(isPresented: $showMonthSheet, onDismiss: {
            if recalc {
                self.refreshTask?.cancel()
                recalc = false
                prepareData()
            }
        }) {
            MultiMonthSheetForCategoryInsights(model: model, recalc: $recalc)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        }
        .onChange(of: DataChangeTriggers.shared.calendarDidChange) {
            /// Put a slight delay so the app has time to switch all the transactions to the new month.
            Task {
                try? await Task.sleep(nanoseconds: UInt64(0.3 * Double(NSEC_PER_SEC)))
                prepareData()
            }
        }
        /// Clear the seleted data when coming back from the list.
        .onChange(of: navPath) {
            if $1.isEmpty {
                selectedDataPoint = nil
                selectedMonth = nil
                selectedMonthGroup.removeAll()
            }
        }
        
        #if os(macOS)
        .onChange(of: appearsActive) {
            if $1 { Task { prepareData() } }
        }
        #endif
    }
    
    // MARK: - Detail Section
    @ViewBuilder
    var detailSection: some View {
        if showInfo {
            Section {
                numberOfTransactionsRow
            } header: {
                HStack {
                    Text("Details")
                    Spacer()
                    showInfoButton
                }
            } footer: {
                Text("The number of transactions that are being used to calculate the metrics.")
            }
            
            Section {
                cumBudgetsRow
            } footer: {
                Text("A summary of the budget amounts from the selected categories.")
            }
            
            Section {
                overUnderRow
            } footer: {
                Text("The amount left after you take the budgets and subtract the amount from the actual spending row.")
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
            
            if isAnalyzingAtLeastOneCreditCategory {
                Section {
                    spendMinusPaymentsRow
                } footer: {
                    Text("The sum of your expenses, offset by credit payments.")
                }
            }
            
            Section {
                actualSpendingRow
            } footer: {
                Text("The sum of your expenses, offset by income/refunds.")
            }
            
        } else {
            Section {
                numberOfTransactionsRow
                cumBudgetsRow
                overUnderRow
            } header: {
                HStack {
                    Text("Details")
                    Spacer()
                    showInfoButton
                }
            }
            .listSectionSpacing(5)
            
            Section {
                incomeRow
                cashOutRow
                totalSpendingRow
                if isAnalyzingAtLeastOneCreditCategory {
                    spendMinusPaymentsRow
                }
                actualSpendingRow
            } footer: {
                Text(categoryFilterTitle)
            }
        }
    }
    
    
    var numberOfTransactionsRow: some View {
        HStack {
            infoButtonLabel("Number of transactions…")
            Spacer()
            Text("\(model.transactions.count)")
                .contentTransition(.numericText())
        }
    }
    
    
    var cumBudgetsRow: some View {
        HStack {
            infoButtonLabel("Cumulative budget…")
            Spacer()
            Text(model.budget.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                .contentTransition(.numericText())
        }
    }
    
    
    @ViewBuilder
    var incomeRow: some View {
        FakeNavLink {
            HStack {
                infoButtonLabel("Money in…")
                Spacer()
                Text((model.income).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                    .contentTransition(.numericText())
            }
        } action: {
            setMoneyIn(shouldNavigate: true)
        }
    }
    
    
    @ViewBuilder
    var cashOutRow: some View {
        FakeNavLink {
            HStack {
                infoButtonLabel("Cash out…")
                Spacer()
                Text((model.cashOut * -1).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                    .contentTransition(.numericText())
            }
        } action: {
            setCashOut(shouldNavigate: true)
        }
    }
    
    
    @ViewBuilder
    var totalSpendingRow: some View {
        FakeNavLink {
            HStack {
                infoButtonLabel("Total spending…")
                Spacer()
                Text((model.totalSpent * -1).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                    .contentTransition(.numericText())
            }
        } action: {
            setTotalSpending(shouldNavigate: true)
        }
    }
    
    
    var actualSpendingRow: some View {
        HStack {
            infoButtonLabel("Actual spending…")
                .bold()
            Spacer()
            Text((model.spendMinusIncome * -1).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                .contentTransition(.numericText())
                .bold()
        }
    }
    
    
    var spendMinusPaymentsRow: some View {
        HStack {
            infoButtonLabel("Spending minus payments…")
            Spacer()
            Text((model.spendMinusPayments * -1).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                .contentTransition(.numericText())
        }
    }
    
    
    var overUnderRow: some View {
        HStack {
            let amount = model.budget - (model.spendMinusIncome * -1)
            let isOver = amount < 0
            infoButtonLabel(isOver ? "You're over-budget by…" : "You're under-budget by…")
            Spacer()
            Text(abs(amount).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                .contentTransition(.numericText())
                .foregroundStyle(isOver ? .red : .green)
        }
    }
    
    
    @ViewBuilder
    func infoButtonLabel(_ text: String) -> some View {
        Text(text)
            .schemeBasedForegroundStyle()
    }
    
    
    var showInfoButton: some View {
        Button {
            withAnimation {
                showInfo.toggle()
            }
        } label: {
            Image(systemName: "info.circle")
        }
        .tint(.none)
    }
        
    
    
    // MARK: - Chart Section
    var chartSection: some View {
        Section {
            VStack {
                Chart(model.chartData) { metric in
                    BarMark(
                        x: .value("Amount", metric.budget),
                        y: .value("Key", "Budget")
                    )
                    .foregroundStyle(metric.category.color)
                    
                    BarMark(
                        x: .value("Amount", (metric.expenses * -1 - metric.income)),
                        y: .value("Key", "Expenses")
                    )
                    .foregroundStyle(metric.category.color)
                }
                .chartLegend(.hidden)
                
                ScrollView(.horizontal) {
                    ZStack {
                        Spacer()
                            .containerRelativeFrame([.horizontal])
                            .frame(height: 1)
                                                    
                        HStack(spacing: 0) {
                            ForEach(model.chartData) { item in
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
                .contentMargins(.bottom, 10, for: .scrollContent)
            }
        } header: {
            sectionHeader("Chart")
        }
    }
    
    
    
    // MARK: - Breakdown Section
    var breakdownSection: some View {
        Section {
            BudgetBreakdownView(chartData: model.chartData, calculateDataFunction: prepareData)
        } header: {
            sectionHeader("Breakdown")
        } footer: {
            BreakdownExportCsvButton(chartData: model.chartData)
        }
    }
    
    
    
    // MARK: - Transaction Section
     var transactionSection: some View {
         Section {
             ForEach(model.monthsForAnalysis.sorted(by: { $0.num < $1.num })) { month in
                 let trans = model.transactions.filter { $0.dateComponents?.month == month.actualNum && $0.dateComponents?.year == month.year }
                 
                 let cost = calModel.getSpend(from: trans)
                 FakeNavLink {
                     VStack(alignment: .leading) {
                         Text("\(month.name) \(String(month.year))")
                         Text("\(cost.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                             .foregroundStyle(.gray)
                             .contentTransition(.numericText())
                     }
                     Spacer()
                     TextWithCircleBackground(text: "\(trans.count)")
                 } action: {
                     setAll(for: month, shouldNavigate: true)
                 }
             }
         } header: {
             sectionHeader("Transactions")
         }
     }
     
    
    
    // MARK: - Toolbar Views
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) { showCategorySheetButton }
        ToolbarSpacer(.fixed, placement: .topBarLeading)
        ToolbarItem(placement: .topBarLeading) { showMonthsButton }
        
//        if model.showLoadingSpinner {
//            ToolbarItem(placement: .topBarTrailing) { ProgressView().tint(.none) }
//                .sharedBackgroundVisibility(.hidden)
//        }
//        ToolbarSpacer(.fixed, placement: .topBarTrailing)
        ToolbarItem(placement: .topBarTrailing) { closeButton }
                        
        ToolbarItem(placement: .bottomBar) { showCalendarButton }
    }
    
    
    var showCategorySheetButton: some View {
        Button {
            showCategorySheet = true
        } label: {
            Image(systemName: "books.vertical")
        }
        .tint(.none)
    }
    
    
    var showMonthsButton: some View {
        Button {
            showMonthSheet = true
        } label: {
            Image(systemName: "calendar")
        }
        .tint(.none)
    }
    
    
    var showCalendarButton: some View {
        Button {
            withAnimation {
                calModel.sCategories = calModel.sCategoriesForAnalysis
            }
                                    
            #if os(iOS)
            if !AppState.shared.isIpad {
                withAnimation { showAnalysisSheet = false }
            }
            
            #else
            //dismiss()
            #endif
            
        } label: {
            Text("View Filtered Calendar")
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
    }
    
   
    @ViewBuilder
    func sectionHeader(_ text: String) -> some View {
        Text(text)
//        HStack {
//            Text(text)
//            Spacer()
//            ProgressView().tint(.none)
//                .opacity(isPreparingData ? 1 : 0)
//        }
    }
    
    
    
    // MARK: - Functions
    func prepareView() {
        /// If there are no months set, add the current month
        if model.monthsForAnalysis.isEmpty {
            let nowMonth = calModel
                .months
                .filter { $0.actualNum == AppState.shared.todayMonth && $0.year == AppState.shared.todayYear }
                .first
            
            if let nowMonth {
                model.monthsForAnalysis.append(nowMonth)
            }
        }
                                
        if calModel.sCategoriesForAnalysis.isEmpty && showAnalysisSheet {
            showCategorySheet = true
        } else {
            prepareData()
        }
    }
    
    
    struct TheData {
        var transactions: Array<CBTransaction>
        var income: Double
        var totalSpent: Double
        var cashOut: Double
        var spendMinusIncome: Double
        var spendMinusPayments: Double
        var budget: Double
        var chartData: [ChartData]
        var cumTotals: [CumTotal]
    }
    
//    func prepareData() {
//        model.startDelayedLoadingSpinnerTimer()
//        self.refreshTask = Task {
//            let data = await prepareDataForReal()
//                    
//            withAnimation {
//                model.transactions = data.transactions
//                model.income = data.income
//                model.totalSpent = data.totalSpent
//                model.cashOut = data.cashOut
//                model.spendMinusPayments = data.spendMinusPayments
//                model.budget = data.budget
//                model.chartData = data.chartData
//                model.cumTotals = data.cumTotals
//            }
//            
//            model.stopDelayedLoadingSpinnerTimer()
//        }
//    }
//    
//    
//    func prepareDataForReal() async -> TheData {
//        print("-- \(#function)")
//        
//        return await Task.detached(priority: .userInitiated) { [calModel] in
//            //isPreparingData = true
//            /// Gather only the relevant transactions.
//            
//            let categoryIds: Array<String> = await calModel.sCategoriesForAnalysis.map { $0.id }
//            let transactions = await calModel.getTransactions(months: model.monthsForAnalysis, cats: calModel.sCategoriesForAnalysis)
//            
//            let income = await calModel.getIncome(months: model.monthsForAnalysis, cats: calModel.sCategoriesForAnalysis)
//            let totalSpent = await calModel.getSpend(months: model.monthsForAnalysis, cats: calModel.sCategoriesForAnalysis)
//            let cashOut = await calModel.getDebitSpend(months: model.monthsForAnalysis, cats: calModel.sCategoriesForAnalysis)
//            let spendMinusPayments = await calModel.getSpendMinusPayments(months: model.monthsForAnalysis, cats: calModel.sCategoriesForAnalysis)
//                        
//            let relevantBudgets = await model.monthsForAnalysis.asyncFlatMap { $0.budgets }.filter { budget in
//                if let id = budget.category?.id {
//                    return categoryIds.contains(id)
//                } else {
//                    return false
//                }
//            }
//            
//            let budget = relevantBudgets.map { $0.amount }.reduce(0.0, +)
//            
//            let chartData = await calModel.sCategoriesForAnalysis
//                .sorted(by: Helpers.categorySorter())
//                .asyncMap { cat in
//                    let budget = relevantBudgets.filter { $0.category?.id == cat.id }.first
//                    return await calModel.createChartData(months: model.monthsForAnalysis, cat: cat, budget: budget)
//                }
//            
//            /// Analyze Data
//            var cumTotals: [CumTotal] = []
//            var total: Double = 0.0
//            
//            for day in await model.monthsForAnalysis.flatMap({ $0.days }) {
//                let doesHaveTransactions = !transactions.filter { $0.dateComponents?.day == day.date?.day }.isEmpty
//                if doesHaveTransactions {
//                    let dailyTotal = await calModel.getSpend(months: model.monthsForAnalysis, day: day.date?.day, cats: calModel.sCategoriesForAnalysis)
//                    
//                    total += dailyTotal
//                    cumTotals.append(CumTotal(day: day.date!.day, total: total))
//                }
//            }
//            
//            return TheData(
//                transactions: transactions,
//                income: income,
//                totalSpent: totalSpent,
//                cashOut: cashOut,
//                spendMinusPayments: spendMinusPayments,
//                budget: budget,
//                chartData: chartData,
//                cumTotals: cumTotals
//            )
//        }.value
//    }
//    
//
    
    enum DataPreparationProgress {
        case started
        case step(String, Double)  // description + percent
        case finished(TheData)
    }
    
    
    @MainActor
    func prepareData() {
        model.progress = 0
        withAnimation {
            model.showLoadingSpinner = true
        }

        //model.startDelayedLoadingSpinnerTimer()

        self.refreshTask = Task {
            for await update in prepareDataForRealStream() {
                switch update {
                case .started:
                    model.progress = 0
                case .step(let message, let percent):
                    withAnimation {
                        model.progress = percent
                        model.statusMessage = message
                    }
                case .finished(let data):
                    withAnimation {
                        model.transactions = data.transactions
                        model.income = data.income
                        model.totalSpent = data.totalSpent
                        model.cashOut = data.cashOut
                        model.spendMinusIncome = data.spendMinusIncome
                        model.spendMinusPayments = data.spendMinusPayments
                        model.budget = data.budget
                        model.chartData = data.chartData
                        model.cumTotals = data.cumTotals
                        model.progress = 1
                        model.showLoadingSpinner = false
                    }
                    //model.stopDelayedLoadingSpinnerTimer()
                }
            }
            
            //#error("FIX THIS TO HANDLE ALL DATAPOINTS. ALSO MIGHT NOT NEED STATE PROPERTY")
            
            switch selectedDataPoint {
            case .moneyIn:
                setMoneyIn(shouldNavigate: false)
                
            case .cashOut:
                setCashOut(shouldNavigate: false)
                
            case .totalSpending:
                setTotalSpending(shouldNavigate: false)
                
            case .all:
                if let selectedMonth {
                    setAll(for: selectedMonth.month, shouldNavigate: false)
                }
            case nil:
                break
            }
        }
    }
    
    
    /// This is called by both the user and the long poll. User action will cause navigation. Long poll will not.
    func setMoneyIn(shouldNavigate: Bool) {
        selectedDataPoint = .moneyIn
        model.monthsForAnalysis.forEach { month in
            let monthlyTrans = model.transactions.filter { $0.dateComponents?.month == month.actualNum && $0.dateComponents?.year == month.year }
            let transactions = calModel.getIncomeTransactions(from: monthlyTrans)
            let cost = calModel.getIncome(from: monthlyTrans)
            let data = MonthlyData(dataPoint: .moneyIn, month: month, trans: transactions, cost: cost)
            process(data: data)
        }
        if shouldNavigate {
            navigate()
        }
    }
    
    
    /// This is called by both the user and the long poll. User action will cause navigation. Long poll will not.
    func setCashOut(shouldNavigate: Bool) {
        selectedDataPoint = .cashOut
        model.monthsForAnalysis.forEach { month in
            let monthlyTrans = model.transactions.filter { $0.dateComponents?.month == month.actualNum && $0.dateComponents?.year == month.year }
            let trans = calModel.getDebitSpendTransactions(from: monthlyTrans)
            let cost = calModel.getDebitSpend(from: monthlyTrans)
            let data = MonthlyData(dataPoint: .cashOut, month: month, trans: trans, cost: cost)
            process(data: data)
        }
        if shouldNavigate {
            navigate()
        }
    }
    
    
    /// This is called by both the user and the long poll. User action will cause navigation. Long poll will not.
    func setTotalSpending(shouldNavigate: Bool) {
        selectedDataPoint = .totalSpending
        model.monthsForAnalysis.forEach { month in
            let monthlyTrans = model.transactions.filter { $0.dateComponents?.month == month.actualNum && $0.dateComponents?.year == month.year }
            let trans = calModel.getSpendTransactions(from: monthlyTrans)
            let cost = calModel.getSpend(from: monthlyTrans)
            let data = MonthlyData(dataPoint: .totalSpending, month: month, trans: trans, cost: cost)
            process(data: data)
        }
        if shouldNavigate {
            navigate()
        }
    }
    
    
    /// This is called by both the user and the long poll. User action will cause navigation. Long poll will not.
    func setAll(for month: CBMonth, shouldNavigate: Bool) {
        selectedDataPoint = .all
        let cost = calModel.getSpend(from: model.transactions)
        let data = MonthlyData(dataPoint: .all, month: month, trans: model.transactions, cost: cost)
        process(data: data, forceToTransactionList: true)
        
        if shouldNavigate {
            navigate(forceToTransactionList: true)
        }
    }
    
    
    fileprivate func navigate(forceToTransactionList: Bool = false) {
        if model.monthsForAnalysis.count == 1 || forceToTransactionList {
            navPath.append(.transactionList)
        } else {
            navPath.append(.monthList)
        }
    }
    
    
    fileprivate func process(data: MonthlyData, forceToTransactionList: Bool = false) {
        var target: MonthlyData?
        if model.monthsForAnalysis.count == 1 || forceToTransactionList {
            target = selectedMonth
        } else {
            target = selectedMonthGroup.filter({ $0.month.num == data.month.num }).first
        }
        
        
        if let target {
            withAnimation {
                target.cost = data.cost
                var activeIds: Array<String> = []
                
                for trans in data.trans {
                    activeIds.append(trans.id)
                    if let targetTrans = target.trans.filter({ $0.id == trans.id }).first {
                        /// Edit.
                        targetTrans.setFromAnotherInstance(transaction: trans)
                    } else {
                        /// Add.
                        target.trans.append(trans)
                    }
                }
                
                /// Delete.
                for trans in target.trans {
                    if !activeIds.contains(trans.id) {
                        target.trans.removeAll(where: { $0.id == trans.id })
                    }
                }
                
                target.month = data.month
            }
        } else {
            if model.monthsForAnalysis.count == 1 || forceToTransactionList {
                selectedMonth = data
            } else {
                selectedMonthGroup.append(data)
            }
        }
    }
    
    
    func prepareDataForRealStream() -> AsyncStream<DataPreparationProgress> {
        AsyncStream { continuation in
            Task.detached(priority: .userInitiated) { [calModel, model] in
                continuation.yield(.started)

                let categoryIds: [String] = await calModel.sCategoriesForAnalysis.map(\.id)
                
                //continuation.yield(.step("Gathering transactions", 0.1))
                let transactions = await calModel.getTransactions(months: model.monthsForAnalysis, cats: calModel.sCategoriesForAnalysis)

                //continuation.yield(.step("Calculating totals", 0.025))
                let income = await calModel.getIncome(from: transactions)
                let totalSpent = await calModel.getSpend(from: transactions)
                let debitSpend = await calModel.getDebitSpend(from: transactions)
                let spendMinusPayments = await calModel.getSpendMinusPayments(from: transactions)
                let spendMinusIncome = await calModel.getSpendMinusIncome(from: transactions)
                
                //continuation.yield(.step("Loading budgets", 0.05))
                let relevantBudgets = await model.monthsForAnalysis.asyncFlatMap { $0.budgets }
                    .filter { budget in
                        if let id = budget.category?.id {
                            return categoryIds.contains(id)
                        } else {
                            return false
                        }
                    }

                let budget = relevantBudgets.map(\.amount).reduce(0.0, +)
                
                //continuation.yield(.step("Building chart data", 0.075))
                let chartData = await calModel.sCategoriesForAnalysis
                    .sorted(by: Helpers.categorySorter())
                    .asyncMap { cat in
                        let trans = transactions.filter { $0.category?.id == cat.id }
                        let budgets = relevantBudgets.filter { $0.category?.id == cat.id }
                        return await calModel.createChartData(transactions: trans, cat: cat, budgets: budgets)
                    }

                //continuation.yield(.step("Summarizing days", 0.1))
                var cumTotals: [CumTotal] = []
                var total: Double = 0.0
                
                let days = model.monthsForAnalysis.flatMap({ $0.days })
                let totalDays = days.count
                
                let progressAtThisPoint = 0.0
                for (index, day) in days.enumerated() {
                    let daysTrans = transactions.filter { $0.dateComponents?.day == day.id }
                    if !daysTrans.isEmpty {
                        let debitSpend = await calModel.getDebitSpend(from: daysTrans)
                        let creditSpend = await calModel.getCreditSpend(from: daysTrans)
                        
                        let dailyTotal = debitSpend + creditSpend
                        total += dailyTotal
                        cumTotals.append(
                            CumTotal(day: day.date!.day, total: total)
                        )
                    }
                    
                    let fraction = Double(index + 1) / Double(totalDays)    // 1/totalSteps → 1.0
                    let progress = progressAtThisPoint + (1 - progressAtThisPoint) * fraction
                    //print(progress)
                    continuation.yield(.step("Analyzing days", progress))
                }

                let data = TheData(
                    transactions: transactions,
                    income: income,
                    totalSpent: totalSpent,
                    cashOut: debitSpend,
                    spendMinusIncome: spendMinusIncome,
                    spendMinusPayments: spendMinusPayments,
                    budget: budget,
                    chartData: chartData,
                    cumTotals: cumTotals
                )

                continuation.yield(.finished(data))
                continuation.finish()
            }
        }
    }
}




fileprivate struct MultiMonthSheetForCategoryInsights: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: CategoryInsightsModel
    @Binding var recalc: Bool
    
    var body: some View {
        @Bindable var calModel = calModel
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                content
            }
            #if os(iOS)
            .navigationTitle("Months")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { selectButton }
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            #endif
        }
        .onChange(of: model.monthsForAnalysis) {
            print("should recalc")
            recalc = true
        }
    }
    
    @ViewBuilder
    var content: some View {
        let lastDecember = calModel.months.filter {$0.enumID == .lastDecember}.first!
        Section(String(lastDecember.year)) {
            label(month: lastDecember)
        }
        
        Section(String(calModel.sYear)) {
            ForEach(calModel.months.filter { ![.lastDecember, .nextJanuary].contains($0.enumID) }, id: \.self) { month in
                label(month: month)
            }
        }
        
        let nextJanuary = calModel.months.filter {$0.enumID == .nextJanuary}.first!
        Section(String(nextJanuary.year)) {
            label(month: nextJanuary)
        }
    }
    
    @ViewBuilder func label(month: CBMonth) -> some View {
        HStack {
            Text(month.name)
            Spacer()
            Image(systemName: "checkmark")
                .opacity(model.monthsForAnalysis.contains(month) ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture { doIt(month) }
    }
    
    
    var selectButton: some View {
        Button {
            model.monthsForAnalysis = model.monthsForAnalysis.isEmpty ? calModel.months : []
        } label: {
            Text(model.monthsForAnalysis.isEmpty  ? "Select All" : "Deselect All")
            //Image(systemName: months.isEmpty ? "checklist.checked" : "checklist.unchecked")
                .schemeBasedForegroundStyle()
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
    
    
    func doIt(_ month: CBMonth) {
        if model.monthsForAnalysis.contains(month) {
            model.monthsForAnalysis.removeAll(where: { $0.num == month.num })
        } else {
            model.monthsForAnalysis.append(month)
        }
    }
}




fileprivate struct MonthMiddleMan: View {
    @Local(\.useWholeNumbers) var useWholeNumbers

    var data: [MonthlyData]
    @Binding var selectedMonth: MonthlyData?
    @Bindable var model: CategoryInsightsModel
    @Binding var navPath: Array<ChildNavDestination>
    
    var body: some View {
        StandardContainerWithToolbar(.list) {
            monthList
        }
        .navigationTitle(data.first?.dataPoint.titleString ?? "Unknown Data Point")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    @ViewBuilder
    var monthList: some View {
        let relevantData = data.filter { !$0.trans.isEmpty }.sorted(by: { $0.month.num < $1.month.num })
        ForEach(relevantData) { data in
            let transCount = data.trans.filter { $0.dateComponents?.month == data.month.actualNum }.count
            FakeNavLink {
                line(data)
            } action: {
                selectedMonth = data
                navPath.append(.transactionList)
            }
        }
    }
    
    @ViewBuilder func line(_ data: MonthlyData) -> some View {
        let transCount = data.trans.filter { $0.dateComponents?.month == data.month.actualNum }.count
        HStack {
            VStack(alignment: .leading) {
                Text("\(data.month.name) \(String(data.month.year))")
                Text("\(data.cost.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                    .foregroundStyle(.gray)
                    .contentTransition(.numericText())
            }
            Spacer()
            TextWithCircleBackground(text: "\(transCount)")
        }
    }
}


fileprivate struct TransactionList: View {
    @AppStorage("transactionSortMode") var transactionSortMode: TransactionSortMode = .title
    @AppStorage("categorySortMode") var categorySortMode: SortMode = .title
    @AppStorage("transactionListDisplayMode") var transactionListDisplayMode: TransactionListDisplayMode = .condensed
    @AppStorage("transactionListDisplayModeShowEmptyDaysInFull") var transactionListDisplayModeShowEmptyDaysInFull: Bool = false
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Environment(CalendarModel.self) private var calModel
    
    @Bindable var data: MonthlyData
    @Bindable var model: CategoryInsightsModel
        
    @State private var transEditID: String?
    @State private var transDay: CBDay?
    @State private var searchText = ""


    var body: some View {
        //Text("\(data.dataPoint.titleString) - \(data.cost.currencyWithDecimals(useWholeNumbers ? 0 : 1))")
        
        StandardContainerWithToolbar(.list) {
            switch transactionListDisplayMode {
            case .full:
                fullView(for: data.month)
            case .condensed:
                condensedView(for: data.month)
            }
//            
//            ForEach(months) { month in
//                ForEach(month.legitDays) { day in
//                    let trans = getTransactions(month: month, day: day)
//                    
//                    let doesHaveTransactions = !trans.isEmpty
//                    
//                    let dailyTotal = trans
//                        .map { ($0.payMethod?.isCreditOrLoan ?? false) ? $0.amount * -1 : $0.amount }
//                        .reduce(0.0, +)
//                    
//                    Section {
//                        if doesHaveTransactions {
//                            ForEach(trans) { trans in
//                                TransactionListLine(trans: trans)
//                                    .onTapGesture {
//                                        self.transDay = day
//                                        self.transEditID = trans.id
//                                    }
//                            }
//                        } else {
//                            Text("No Transactions")
//                                .foregroundStyle(.gray)
//                        }
//                    } header: {
//                        if let date = day.date, date.isToday {
//                            todayIndicatorLine
//                        } else {
//                            Text(day.date?.string(to: .monthDayShortYear) ?? "")
//                        }
//                        
//                    } footer: {
//                        if doesHaveTransactions {
//                            sectionFooter(day: day, dailyCount: trans.count, dailyTotal: dailyTotal)
//                        }
//                    }
//                }
//            }
            
        }
        .searchable(text: $searchText, prompt: Text("Search"))
        .navigationTitle("\(data.dataPoint.titleString)")
        .navigationSubtitle("\(data.month.name) \(String(data.month.year))")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { viewModeMenu }
        }
        .transactionEditSheetAndLogic(transEditID: $transEditID, selectedDay: $transDay)
    }
    
    var viewModeMenu: some View {
        Menu {
            Section("Display Mode") {
                ForEach(TransactionListDisplayMode.allCases, id: \.self) { opt in
                    Button {
                        withAnimation {
                            transactionListDisplayMode = opt
                        }
                        
                    } label: {
                        HStack {
                            Text(opt.prettyValue)
                            Spacer()
                            if opt == transactionListDisplayMode {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    if opt == .full && transactionListDisplayMode == .full {
                        Menu("Show empty days") {
                            emptyDayButton(show: true)
                            emptyDayButton(show: false)
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    @ViewBuilder
    func emptyDayButton(show: Bool) -> some View {
        Button {
            withAnimation {
                transactionListDisplayModeShowEmptyDaysInFull = show
            }
        } label: {
            HStack {
                Text(show ? "Yes" : "No")
                Spacer()
                if transactionListDisplayModeShowEmptyDaysInFull == show {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
    
    
    @ViewBuilder
    func fullView(for month: CBMonth) -> some View {
        ForEach(month.legitDays) { day in
            let trans = getTransactions(month: month, day: day)
            let doesHaveTransactions = !trans.isEmpty
            
            if transactionListDisplayModeShowEmptyDaysInFull {
                theSection(day: day, trans: trans) {
                    if doesHaveTransactions {
                        transLoop(trans: trans)
                    } else {
                        Text("No Transactions")
                            .foregroundStyle(.gray)
                    }
                }
            } else {
                if doesHaveTransactions {
                    theSection(day: day, trans: trans) {
                        transLoop(trans: trans)
                    }
                }
            }
        }
    }
    
    
    @ViewBuilder
    func condensedView(for month: CBMonth) -> some View {
        let trans = getTransactions(month: month)
        transLoop(trans: trans)
    }
    
    
    @ViewBuilder
    func transLoop(trans: Array<CBTransaction>) -> some View {
        ForEach(trans) { trans in
            TransactionListLine(trans: trans, withDate: false)
                .onTapGesture {
                    let day = data.month.days.filter { $0.id == trans.dateComponents?.day }.first
                    self.transDay = day
                    self.transEditID = trans.id
                }
        }
    }
    
    
    @ViewBuilder
    func theSection(day: CBDay, trans: Array<CBTransaction>, @ViewBuilder content: () -> some View) -> some View {
        let doesHaveTransactions = !trans.isEmpty
        let dailyTotal = trans
            .map { ($0.payMethod?.isCreditOrLoan ?? false) ? $0.amount * -1 : $0.amount }
            .reduce(0.0, +)

        Section {
            content()
        } header: {
            if let date = day.date, date.isToday {
                todayIndicatorLine
            } else {
                Text(day.date?.string(to: .monthDayShortYear) ?? "")
            }
            
        } footer: {
            if doesHaveTransactions {
                sectionFooter(day: day, dailyCount: trans.count, dailyTotal: dailyTotal)
            }
        }
    }
    
    
    var todayIndicatorLine: some View {
        HStack {
            Text("TODAY")
                .foregroundStyle(Color.theme)
            VStack {
                Divider()
                    .overlay(Color.theme)
            }
        }
    }
    
    
    @ViewBuilder
    func sectionFooter(day: CBDay, dailyCount: Int, dailyTotal: Double) -> some View {
        HStack {
            Text("Cumulative Total: \((model.cumTotals.filter { $0.day == day.date!.day }.first?.total ?? 0.0).currencyWithDecimals(useWholeNumbers ? 0 : 2))")
            
            Spacer()
            if dailyCount > 1 {
                Text(dailyTotal.currencyWithDecimals(useWholeNumbers ? 0 : 2))
            }
        }
    }
    
    
    func getTransactions(month: CBMonth, day: CBDay? = nil) -> Array<CBTransaction> {
        data.trans
            .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
            .filter { transaction in
                guard
                    let comps = transaction.dateComponents,
                    comps.month == month.actualNum,
                    comps.year == month.year
                else { return false }

                // If a specific day is provided, it must match.
                if let day = day?.id {
                    return comps.day == day
                }

                // Otherwise, ignore the day.
                return true
            }
            .sorted {
                if transactionListDisplayMode == .full {
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
                } else {
                    return $0.date ?? Date() < $1.date ?? Date()
                }
                
            }
    }
}


fileprivate struct FakeNavLink<Content: View>: View {
    @ViewBuilder var label: () -> Content
    var action: () -> Void
    
    var body: some View {
        
        Button {
            action()
        } label: {
            HStack {
                label()
                    .schemeBasedForegroundStyle()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            
        }
    }
}




extension Sequence {
    func asyncMap<T>(_ transform: (Element) async -> T) async -> [T] {
        var results: [T] = []
        results.reserveCapacity(underestimatedCount)
        for element in self {
            results.append(await transform(element))
        }
        return results
    }
    
    func asyncFlatMap<T>(_ transform: (Element) async -> [T]) async -> [T] {
        var results: [T] = []
        for element in self {
            let inner = await transform(element)
            results.append(contentsOf: inner)
        }
        return results
    }
}
