//
//  CategoryAnalysisSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/26/24.
//

import SwiftUI
import Charts


enum CivNavDestination {
    case monthList, transactionList
}

#if os(iOS)
struct CategoryInsightsViewWrapperIpad: View {
    @State private var navPath = NavigationPath()
    @Binding var showAnalysisSheet: Bool
    @Bindable var model: CivViewModel
    
    var body: some View {
        NavigationStack(path: $navPath) {
            CategoryInsightsView(navPath: $navPath, showAnalysisSheet: $showAnalysisSheet, model: model)
        }
    }
}
#endif

struct CategoryInsightsView: View {
    @Environment(\.colorScheme) var colorScheme
    #if os(macOS)
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appearsActive) var appearsActive
    #endif
    
    //@Local(\.colorTheme) var colorTheme
    @Environment(CalendarProps.self) private var calProps
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    
    #if os(iOS)
    @Binding var navPath: NavigationPath
    #else
    @State private var navPath = NavigationPath()
    #endif
    @Binding var showAnalysisSheet: Bool
    @Bindable var model: CivViewModel
    
    @State private var showCategoryLiteSheet = false
    @State private var showCategorySheet = false
    @State private var showMonthSheet = false
    //@State private var isPreparingData = false
    @State private var recalc = false
    @State private var showInfo = false
    //@State private var navPath: Array<CivNavDestination> = []
    @State private var refreshTask: Task<Void, Never>?
    
    //private enum MonthlyData { case income, cashOut, totalSpending, spendingMinusPayments }
    
    //@State private var selectedDataPoint: CivDataPoint? = nil
    //@State private var selectedMonthGroup: Array<CivMonthlyData> = []
    //@State private var selectedMonth: CivMonthlyData?

    
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
        if AppState.shared.isIphone {
            content
        } else {
            NavigationStack(path: $navPath) {
                content
            }
        }
    }
    
    
    @ViewBuilder
    var content: some View {
        @Bindable var calModel = calModel
        
        VStack(spacing: 0) {
            if calModel.sCategoriesForAnalysis.isEmpty {
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
            } else {
                StandardContainerWithToolbar(.list) {
                    detailSection
                    Section {
                        VStack {
                            CivBudgetCompareChart(model: model)
                            CivChartLegend(model: model)
                        }
                    }
                    
                    if calModel.sCategoriesForAnalysis.count > 1 {
                        Section {
                            HStack {
                                CivActualSpendingByCategoryPieChart(model: model)
                                CivActualSpendingByCategoryBarChart(model: model)
                            }
                        } header: {
                            VStack(alignment: .leading) {
                                Text("Actual Spending")
                                Text("(Summary)")
                                    .font(.footnote)
                            }
                        }
                    }
                                                   
                    breakdownSection
                    
                    if model.monthsForAnalysis.count > 1 {
                        Section {
                            CivSpendingBreakdownChart(model: model)
                        } header: {
                            VStack(alignment: .leading) {
                                Text("Actual Spending Over Time")
                                Text("(Summary)")
                                    .font(.footnote)
                            }
                        }
                        
                        Section {
                            CivActualSpendingByCategoryByMonthLineChart(model: model)
                        } header: {
                            VStack(alignment: .leading) {
                                Text("Actual Spending Over Time")
                                Text("(By category)")
                                    .font(.footnote)
                            }
                        }
                        
                        Section("Transaction Count") {
                            CivTransactionCountChart(model: model)
                        }
                    }
                    
                    transactionSection
                }
            }
        }
        #if os(iOS)
        .safeAreaBar(edge: .top) {
            CivCalculatingProgressView(model: model)
        }
        #endif
        .navigationTitle("Insights")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar { toolbar }
        .navigationDestination(for: CivNavDestination.self) { dest in
            switch dest {
            case .monthList:
                CivMonthMiddleMan(monthlyData: model.selectedMonthGroup, selectedMonth: $model.selectedMonth, model: model, navPath: $navPath)
                
            case .transactionList:
                if let _ = model.selectedMonth {
                    CivTransactionList(model: model)
                } else {
                    ContentUnavailableView("Uh Oh!", systemImage: "exclamationmark.triangle.text.page", description: Text("The page you are looking for could not be found."))
                }
            }
        }
        #if os(iOS)
        .background(Color(.systemBackground)) // force matching
        #endif
        .task { prepareView() }
        /// Needed for the inspector on iPad.
        .onChange(of: showAnalysisSheet) {
            if $1 && !showCategorySheet { showCategorySheet = true }
        }
        .sheet(isPresented: $showCategorySheet, onDismiss: {
            prepareData()
        }, content: {
            MultiCategorySheet(
                categories: $calModel.sCategoriesForAnalysis,
                categoryGroup: $calModel.sCategoryGroupsForAnalysis,
                showAnalyticSpecificOptions: true
            )
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
            CivMultiMonthSheet(model: model, recalc: $recalc)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        }
        .onChange(of: DataChangeTriggers.shared.calendarDidChange) {
            /// Put a slight delay so the app has time to switch all the transactions to the new month.
            Task {
                try await Task.sleep(for: .seconds(0.3))
                //try? await Task.sleep(nanoseconds: UInt64(0.3 * Double(NSEC_PER_SEC)))
                prepareData()
            }
        }
        /// Clear the seleted data when coming back from the list.
        .onChange(of: navPath) {
            if $1.isEmpty {
                model.selectedDataPoint = nil
                model.selectedMonth = nil
                model.selectedMonthGroup.removeAll()
            }
        }
        #if os(macOS)
        .onChange(of: appearsActive) {
            if $1 { Task { prepareData() } }
        }
        #endif
    }
    
    @AppStorage("CategoryInsightsOnlyUntilToday") private var onlyUpUntilToday = false
    
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
            #if os(iOS)
            .listSectionSpacing(5)
            #endif
            
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
            
            Section {
                Toggle(isOn: $onlyUpUntilToday) {
                    Text("Up until today only")
                }
                .onChange(of: onlyUpUntilToday) {
                    prepareData()
                }
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
            Text(model.budget.currencyWithDecimals())
                .contentTransition(.numericText())
        }
    }
    
    
    @ViewBuilder
    var incomeRow: some View {
        CivFakeNavLink {
            HStack {
                infoButtonLabel("Money in…")
                Spacer()
                Text((model.income).currencyWithDecimals())
                    .contentTransition(.numericText())
            }
        } action: {
            setMoneyIn(shouldNavigate: true)
        }
    }
    
    
    @ViewBuilder
    var cashOutRow: some View {
        CivFakeNavLink {
            HStack {
                infoButtonLabel("Cash out…")
                Spacer()
                Text((model.cashOut * -1).currencyWithDecimals())
                    .contentTransition(.numericText())
            }
        } action: {
            setCashOut(shouldNavigate: true)
        }
    }
    
    
    @ViewBuilder
    var totalSpendingRow: some View {
        CivFakeNavLink {
            HStack {
                infoButtonLabel("Total spending…")
                Spacer()
                Text((model.totalSpent * -1).currencyWithDecimals())
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
            Text((model.spendMinusIncome * -1).currencyWithDecimals())
                .contentTransition(.numericText())
                .bold()
        }
    }
    
    
    var spendMinusPaymentsRow: some View {
        HStack {
            infoButtonLabel("Spending minus payments…")
            Spacer()
            Text((model.spendMinusPayments * -1).currencyWithDecimals())
                .contentTransition(.numericText())
        }
    }
    
    
    var overUnderRow: some View {
        HStack {
            let amount = model.budget - (model.spendMinusIncome * -1)
            let isOver = amount < 0
            infoButtonLabel(isOver ? "You're over-budget by…" : "You're under-budget by…")
            Spacer()
            Text(abs(amount).currencyWithDecimals())
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
    
    
    @ViewBuilder
    var transactionSection: some View {
        let months = model.monthsForAnalysis.sorted(by: { $0.num < $1.num })
        Section {
            ForEach(months) { month in
                let trans = model.transactions.filter { $0.dateComponents?.month == month.actualNum && $0.dateComponents?.year == month.year }
                
                if trans.count > 0 {
                    let cost = calModel.getSpendMinusIncome(from: trans)
                    CivFakeNavLink {
                        VStack(alignment: .leading) {
                            Text("\(month.name) \(String(month.year))")
                            Text("\(abs(cost).currencyWithDecimals())")
                                .foregroundStyle(.gray)
                                .contentTransition(.numericText())
                        }
                        Spacer()
                        TextWithCircleBackground(text: "\(trans.count)")
                    } action: {
                        setAll(for: month, shouldNavigate: true)
                    }
                }
            }
        } header: {
            sectionHeader("Transactions")
        }
    }
     
    
    
    // MARK: - Toolbar Views
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        #if os(iOS)
        if AppState.shared.isIpad {
            ToolbarItem(placement: .topBarLeading) { showCategorySheetButton }
            ToolbarSpacer(.fixed, placement: .topBarLeading)
            ToolbarItem(placement: .topBarLeading) { showMonthsButton }
        }
        
//        if model.showLoadingSpinner {
//            ToolbarItem(placement: .topBarTrailing) { ProgressView().tint(.none) }
//                .sharedBackgroundVisibility(.hidden)
//        }
//        ToolbarSpacer(.fixed, placement: .topBarTrailing)
        if AppState.shared.isIpad {
            ToolbarItem(placement: .topBarTrailing) { closeButton }
        } else {
            ToolbarItem(placement: .topBarTrailing) { showCategorySheetButton }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            ToolbarItem(placement: .topBarTrailing) { showMonthsButton }
        }
        
                        
        if !calModel.sCategoriesForAnalysis.isEmpty {
            ToolbarItem(placement: .bottomBar) { showCalendarButton }
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
            Image(systemName: "books.vertical")
        }
        .tint(.none)
        #if os(macOS)
        .buttonStyle(.roundMacButton)
        #endif
    }
    
    
    var showMonthsButton: some View {
        Button {
            showMonthSheet = true
        } label: {
            Image(systemName: "calendar")
        }
        .tint(.none)
        #if os(macOS)
        .buttonStyle(.roundMacButton)
        #endif
    }
    
    
    var showCalendarButton: some View {
        Button {
            withAnimation {
                calModel.sCategories = calModel.sCategoriesForAnalysis
                calModel.sPayMethod = nil
            }
                                    
            #if os(iOS)
            if AppState.shared.isIphone {
                withAnimation {
                    navPath.removeLast()
                    //showAnalysisSheet = false
                }
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
        if calModel.isInMultiSelectMode {
            model.monthsForAnalysis.removeAll()
            let monthYears = calModel.multiSelectTransactions.compactMap { ($0.dateComponents?.month, $0.dateComponents?.year) }
            for month in monthYears {
                if model.monthsForAnalysis.filter ({ $0.actualNum == month.0 && $0.year == month.1 }).isEmpty {
                    if let targetMonth = calModel
                        .months
                        .filter ({ $0.actualNum == month.0 && $0.year == month.1 })
                        .first {
                            model.monthsForAnalysis.append(targetMonth)
                        }
                }
            }
        } else {
            /// If there are no months set, add the current month
            if model.monthsForAnalysis.isEmpty {
                let viewingMonth = calModel
                    .months
                    .filter { $0.num == calModel.sMonth.num }
                    //.filter { $0.actualNum == AppState.shared.todayMonth && $0.year == AppState.shared.todayYear }
                    .first
                
                if let viewingMonth {
                    model.monthsForAnalysis.append(viewingMonth)
                }
            }
        }
        
        
        
                                
        if calModel.sCategoriesForAnalysis.isEmpty && showAnalysisSheet {
            //showCategorySheet = true
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
        var spendingBreakdownChartdata: [CivSpendingBreakdownChartData]
        var transactionCountChartData: [CivTransactionCountChartData]
        var actualSpendingBreakdownByCategoryChartData: [CivActualSpendingBreakdownByCategoryOuterChartData]
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
        //model.selectedMonthGroup.removeAll()
        model.progress = 0
        withAnimation {
            model.showLoadingSpinner = true
        }

        //model.startDelayedLoadingSpinnerTimer()

        self.refreshTask = Task {
            for await update in prepareDataForRealStream(onlyUpUntilToday: onlyUpUntilToday) {
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
                    }
                    
                    withAnimation {
                        model.spendingBreakdownChartdata = data.spendingBreakdownChartdata
                        model.transactionCountChartData = data.transactionCountChartData
                        model.actualSpendingBreakdownByCategoryChartData = data.actualSpendingBreakdownByCategoryChartData
                    }
                    
                    withAnimation {
                        model.progress = 1
                        model.showLoadingSpinner = false
                    }
                    
                    //model.stopDelayedLoadingSpinnerTimer()
                }
            }
            
            //#error("FIX THIS TO HANDLE ALL DATAPOINTS. ALSO MIGHT NOT NEED STATE PROPERTY")
            
            model.selectedMonthGroup.removeAll()
            
            switch model.selectedDataPoint {
            case .moneyIn:
                setMoneyIn(shouldNavigate: false)
                
            case .cashOut:
                setCashOut(shouldNavigate: false)
                
            case .totalSpending:
                setTotalSpending(shouldNavigate: false)
                
            case .all:
                if let selectedMonth = model.selectedMonth {
                    setAll(for: selectedMonth.month, shouldNavigate: false)
                }
                
            case .actualSpending:
                setActualSpending(shouldNavigate: false)
                
            case nil:
                break
            }
            
            
//            let months = model.monthsForAnalysis.sorted(by: { $0.num < $1.num })
//            
//            
//            withAnimation {
//                model.spendingBreakdownChartdata = months.map { month in
//                    let date = Calendar.current.date(from: DateComponents(year: month.year, month: month.actualNum, day: 1))!
//                    let trans = model.transactions.filter { $0.dateComponents?.month == month.actualNum && $0.dateComponents?.year == month.year }
//                    let cost = calModel.getSpendMinusIncome(from: trans)
//                    
//                    return CivSpendingBreakdownChartData(month: month, date: date, cost: cost)
//                }
//                
//                model.transactionCountChartData = months.map { month in
//                    let date = Calendar.current.date(from: DateComponents(year: month.year, month: month.actualNum, day: 1))!
//                    let trans = model.transactions.filter { $0.dateComponents?.month == month.actualNum && $0.dateComponents?.year == month.year }
//                    
//                    return CivTransactionCountChartData(month: month, date: date, count: trans.count)
//                }
//                
//                model.actualSpendingBreakdownByCategoryChartData = calModel.sCategoriesForAnalysis.map { cat in
//                    let data = months.map { month in
//                        let date = Calendar.current.date(from: DateComponents(year: month.year, month: month.actualNum, day: 1))!
//                        let trans = model.transactions.filter {
//                            $0.dateComponents?.month == month.actualNum
//                            && $0.dateComponents?.year == month.year
//                            && $0.category?.id == cat.id
//                        }
//                        let cost = calModel.getSpendMinusIncome(from: trans)
//                        
//                        return CivActualSpendingBreakdownByCategoryChartData(month: month, date: date, cost: cost)
//                    }
//                    
//                    return CivActualSpendingBreakdownByCategoryOuterChartData(category: cat, data: data)
//                }
//            }
        }
    }
    
    
    /// This is called by both the user and the long poll. User action will cause navigation. Long poll will not.
    func setMoneyIn(shouldNavigate: Bool) {
        model.selectedDataPoint = .moneyIn
        model.monthsForAnalysis.forEach { month in
            let monthlyTrans = model.transactions.filter {
                $0.dateComponents?.month == month.actualNum
                && $0.dateComponents?.year == month.year
                && (onlyUpUntilToday ?
                    (
                        ($0.dateComponents?.month == AppState.shared.todayMonth && $0.dateComponents?.year == AppState.shared.todayYear)
                        ? ($0.dateComponents?.day ?? 0) <= AppState.shared.todayDay
                        : true
                    )
                    : true
                )
            }
            let transactions = calModel.getIncomeTransactions(from: monthlyTrans)
            let moneyIn = calModel.getIncome(from: monthlyTrans)
            let cashOut = calModel.getDebitSpend(from: monthlyTrans)
            let totalSpend = calModel.getSpend(from: monthlyTrans)
            let actualSpend = calModel.getSpendMinusIncome(from: monthlyTrans)
            
            //let overallTotalSpend = calModel.getSpend(from: model.transactions)
            let breakdown = CivBreakdownData(moneyIn: moneyIn, cashOut: cashOut, spending: totalSpend, actualSpending: actualSpend)
            
            let catData = calModel.sCategoriesForAnalysis.map { cat in
                let monthlyTrans = model.transactions.filter {
                    $0.dateComponents?.month == month.actualNum
                    && $0.dateComponents?.year == month.year
                    && (onlyUpUntilToday ?
                        (
                            ($0.dateComponents?.month == AppState.shared.todayMonth && $0.dateComponents?.year == AppState.shared.todayYear)
                            ? ($0.dateComponents?.day ?? 0) <= AppState.shared.todayDay
                            : true
                        )
                        : true
                    )
                    && $0.category?.id == cat.id
                }
                //let transactions = calModel.getIncomeTransactions(from: monthlyTrans)
                let moneyIn = calModel.getIncome(from: monthlyTrans)
                let cashOut = calModel.getDebitSpend(from: monthlyTrans)
                let totalSpend = calModel.getSpend(from: monthlyTrans)
                let actualSpend = calModel.getSpendMinusIncome(from: monthlyTrans)
                
                return CivBreakdownData(category: cat, moneyIn: moneyIn, cashOut: cashOut, spending: totalSpend, actualSpending: actualSpend)
            }
            
            let data = CivMonthlyData(dataPoint: .moneyIn, month: month, trans: transactions, breakdown: breakdown, dataByCategory: catData)
            process(data: data)
        }
        if shouldNavigate {
            navigate()
        }
    }
    
    
    /// This is called by both the user and the long poll. User action will cause navigation. Long poll will not.
    func setCashOut(shouldNavigate: Bool) {
        model.selectedDataPoint = .cashOut
        model.monthsForAnalysis.forEach { month in
            let monthlyTrans = model.transactions.filter {
                $0.dateComponents?.month == month.actualNum
                && $0.dateComponents?.year == month.year
                && (onlyUpUntilToday ?
                    (
                        ($0.dateComponents?.month == AppState.shared.todayMonth && $0.dateComponents?.year == AppState.shared.todayYear)
                        ? ($0.dateComponents?.day ?? 0) <= AppState.shared.todayDay
                        : true
                    )
                    : true
                )
            }
            let trans = calModel.getDebitSpendTransactions(from: monthlyTrans)
            let moneyIn = calModel.getIncome(from: monthlyTrans)
            let cashOut = calModel.getDebitSpend(from: monthlyTrans)
            let totalSpend = calModel.getSpend(from: monthlyTrans)
            let actualSpend = calModel.getSpendMinusIncome(from: monthlyTrans)
            
            //let overallTotalSpend = calModel.getSpend(from: model.transactions)
            let breakdown = CivBreakdownData(moneyIn: moneyIn, cashOut: cashOut, spending: totalSpend, actualSpending: actualSpend)
            
            let catData = calModel.sCategoriesForAnalysis.map { cat in
                let monthlyTrans = model.transactions.filter {
                    $0.dateComponents?.month == month.actualNum
                    && $0.dateComponents?.year == month.year
                    && (onlyUpUntilToday ?
                        (
                            ($0.dateComponents?.month == AppState.shared.todayMonth && $0.dateComponents?.year == AppState.shared.todayYear)
                            ? ($0.dateComponents?.day ?? 0) <= AppState.shared.todayDay
                            : true
                        )
                        : true
                    )
                    && $0.category?.id == cat.id
                }
                //let trans = calModel.getDebitSpendTransactions(from: monthlyTrans)
                let moneyIn = calModel.getIncome(from: monthlyTrans)
                let cashOut = calModel.getDebitSpend(from: monthlyTrans)
                let totalSpend = calModel.getSpend(from: monthlyTrans)
                let actualSpend = calModel.getSpendMinusIncome(from: monthlyTrans)
                
                return CivBreakdownData(category: cat, moneyIn: moneyIn, cashOut: cashOut, spending: totalSpend, actualSpending: actualSpend)
            }
            
            let data = CivMonthlyData(dataPoint: .cashOut, month: month, trans: trans, breakdown: breakdown, dataByCategory: catData)
            process(data: data)
        }
        if shouldNavigate {
            navigate()
        }
    }
    
    
    /// This is called by both the user and the long poll. User action will cause navigation. Long poll will not.
    func setTotalSpending(shouldNavigate: Bool) {
        model.selectedDataPoint = .totalSpending
        model.monthsForAnalysis.forEach { month in
            let monthlyTrans = model.transactions.filter {
                $0.dateComponents?.month == month.actualNum
                && $0.dateComponents?.year == month.year
                && (onlyUpUntilToday ?
                    (
                        ($0.dateComponents?.month == AppState.shared.todayMonth && $0.dateComponents?.year == AppState.shared.todayYear)
                        ? ($0.dateComponents?.day ?? 0) <= AppState.shared.todayDay
                        : true
                    )
                    : true
                )
            }
            let trans = calModel.getSpendTransactions(from: monthlyTrans)
            let moneyIn = calModel.getIncome(from: monthlyTrans)
            let cashOut = calModel.getDebitSpend(from: monthlyTrans)
            let totalSpend = calModel.getSpend(from: monthlyTrans)
            let actualSpend = calModel.getSpendMinusIncome(from: monthlyTrans)
            
            //let overallTotalSpend = calModel.getSpend(from: model.transactions)
            let breakdown = CivBreakdownData(moneyIn: moneyIn, cashOut: cashOut, spending: totalSpend, actualSpending: actualSpend)
            
            let catData = calModel.sCategoriesForAnalysis.map { cat in
                let monthlyTrans = model.transactions.filter {
                    $0.dateComponents?.month == month.actualNum
                    && $0.dateComponents?.year == month.year
                    && (onlyUpUntilToday ?
                        (
                            ($0.dateComponents?.month == AppState.shared.todayMonth && $0.dateComponents?.year == AppState.shared.todayYear)
                            ? ($0.dateComponents?.day ?? 0) <= AppState.shared.todayDay
                            : true
                        )
                        : true
                    )
                    && $0.category?.id == cat.id
                }
                //let trans = calModel.getSpendTransactions(from: monthlyTrans)
                let moneyIn = calModel.getIncome(from: monthlyTrans)
                let cashOut = calModel.getDebitSpend(from: monthlyTrans)
                let totalSpend = calModel.getSpend(from: monthlyTrans)
                let actualSpend = calModel.getSpendMinusIncome(from: monthlyTrans)
                
                return CivBreakdownData(category: cat, moneyIn: moneyIn, cashOut: cashOut, spending: totalSpend, actualSpending: actualSpend)
            }
            
            let data = CivMonthlyData(dataPoint: .totalSpending, month: month, trans: trans, breakdown: breakdown, dataByCategory: catData)
            process(data: data)
        }
        if shouldNavigate {
            navigate()
        }
    }
    
    /// This is called by both the user and the long poll. User action will cause navigation. Long poll will not.
    func setActualSpending(shouldNavigate: Bool) {
        model.selectedDataPoint = .actualSpending
        model.monthsForAnalysis.forEach { month in
            let monthlyTrans = model.transactions.filter {
                $0.dateComponents?.month == month.actualNum
                && $0.dateComponents?.year == month.year
                && (onlyUpUntilToday ?
                    (
                        ($0.dateComponents?.month == AppState.shared.todayMonth && $0.dateComponents?.year == AppState.shared.todayYear)
                        ? ($0.dateComponents?.day ?? 0) <= AppState.shared.todayDay
                        : true
                    )
                    : true
                )
            }
            let trans = calModel.getSpendTransactions(from: monthlyTrans)
            let moneyIn = calModel.getIncome(from: monthlyTrans)
            let cashOut = calModel.getDebitSpend(from: monthlyTrans)
            let totalSpend = calModel.getSpend(from: monthlyTrans)
            let actualSpend = calModel.getSpendMinusIncome(from: monthlyTrans)
            
            //let overallTotalSpend = calModel.getSpend(from: model.transactions)
            let breakdown = CivBreakdownData(moneyIn: moneyIn, cashOut: cashOut, spending: totalSpend, actualSpending: actualSpend)
            
            let catData = calModel.sCategoriesForAnalysis.map { cat in
                let monthlyTrans = model.transactions.filter {
                    $0.dateComponents?.month == month.actualNum
                    && $0.dateComponents?.year == month.year
                    && (onlyUpUntilToday ?
                        (
                            ($0.dateComponents?.month == AppState.shared.todayMonth && $0.dateComponents?.year == AppState.shared.todayYear)
                            ? ($0.dateComponents?.day ?? 0) <= AppState.shared.todayDay
                            : true
                        )
                        : true
                    )
                    && $0.category?.id == cat.id
                }
                //let trans = calModel.getSpendTransactions(from: monthlyTrans)
                let moneyIn = calModel.getIncome(from: monthlyTrans)
                let cashOut = calModel.getDebitSpend(from: monthlyTrans)
                let totalSpend = calModel.getSpend(from: monthlyTrans)
                let actualSpend = calModel.getSpendMinusIncome(from: monthlyTrans)
                
                return CivBreakdownData(category: cat, moneyIn: moneyIn, cashOut: cashOut, spending: totalSpend, actualSpending: actualSpend)
            }
            
            let data = CivMonthlyData(dataPoint: .actualSpending, month: month, trans: trans, breakdown: breakdown, dataByCategory: catData)
            process(data: data)
        }
        if shouldNavigate {
            navigate()
        }
    }
    
    
    /// This is called by both the user and the long poll. User action will cause navigation. Long poll will not.
    func setAll(for month: CBMonth, shouldNavigate: Bool) {
        model.selectedDataPoint = .all
        let monthlyTrans = model.transactions.filter {
            $0.dateComponents?.month == month.actualNum
            && $0.dateComponents?.year == month.year
            && (onlyUpUntilToday ?
                (
                    ($0.dateComponents?.month == AppState.shared.todayMonth && $0.dateComponents?.year == AppState.shared.todayYear)
                    ? ($0.dateComponents?.day ?? 0) <= AppState.shared.todayDay
                    : true
                )
                : true
            )
        }
        let moneyIn = calModel.getIncome(from: monthlyTrans)
        let cashOut = calModel.getDebitSpend(from: monthlyTrans)
        let totalSpend = calModel.getSpend(from: monthlyTrans)
        let actualSpend = calModel.getSpendMinusIncome(from: monthlyTrans)
        
        //let overallTotalSpend = calModel.getSpend(from: model.transactions)
        let breakdown = CivBreakdownData(moneyIn: moneyIn, cashOut: cashOut, spending: totalSpend, actualSpending: actualSpend)
        
        let catData = calModel.sCategoriesForAnalysis.map { cat in
            let monthlyTrans = model.transactions.filter {
                $0.dateComponents?.month == month.actualNum
                && $0.dateComponents?.year == month.year
                && (onlyUpUntilToday ?
                    (
                        ($0.dateComponents?.month == AppState.shared.todayMonth && $0.dateComponents?.year == AppState.shared.todayYear)
                        ? ($0.dateComponents?.day ?? 0) <= AppState.shared.todayDay
                        : true
                    )
                    : true
                )
                && $0.category?.id == cat.id
            }
            let moneyIn = calModel.getIncome(from: monthlyTrans)
            let cashOut = calModel.getDebitSpend(from: monthlyTrans)
            let totalSpend = calModel.getSpend(from: monthlyTrans)
            let actualSpend = calModel.getSpendMinusIncome(from: monthlyTrans)
            
            print("\(cat.title): \(actualSpend)")
            
            return CivBreakdownData(category: cat, moneyIn: moneyIn, cashOut: cashOut, spending: totalSpend, actualSpending: actualSpend)
        }
        
        let data = CivMonthlyData(dataPoint: .all, month: month, trans: model.transactions, breakdown: breakdown, dataByCategory: catData)
        print("Process!!")
        process(data: data, forceToTransactionList: true)
        
        if shouldNavigate {
            navigate(forceToTransactionList: true)
        }
    }
    
    
    fileprivate func navigate(forceToTransactionList: Bool = false) {
        if model.monthsForAnalysis.count == 1 || forceToTransactionList {
            print("Navigating to transaction list")
            navPath.append(CivNavDestination.transactionList)
        } else {
            navPath.append(CivNavDestination.monthList)
        }
    }
    
    
    fileprivate func process(data: CivMonthlyData, forceToTransactionList: Bool = false) {
        Task.detached(priority: .userInitiated) { [model] in
            print("-- \(#function)")
            var target: CivMonthlyData?
            if model.monthsForAnalysis.count == 1 || forceToTransactionList {
                target = model.selectedMonth
            } else {
                target = model.selectedMonthGroup.filter({ $0.month.num == data.month.num }).first
            }
            
            
            //        if !model.selectedMonthGroup.map({ $0.month.num }).contains(data.month.num) {
            //            model.selectedMonthGroup.removeAll(where: { $0.month.num == data.month.num })
            //            return
            //        }
            
            
            if let target {
                withAnimation {
                    target.month = data.month
                    target.dataPoint = data.dataPoint
                    target.breakdown = data.breakdown
                    target.dataByCategory = data.dataByCategory
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
                }
            } else {
                if model.monthsForAnalysis.count == 1 || forceToTransactionList {
                    model.selectedMonth = data
                } else {
                    model.selectedMonthGroup.append(data)
                }
            }
            
            print("-- \(#function) - DONE")
        }
    }
    
    
    func prepareDataForRealStream(onlyUpUntilToday: Bool) -> AsyncStream<DataPreparationProgress> {
        AsyncStream { continuation in
            Task.detached(priority: .userInitiated) { [calModel, model] in
                continuation.yield(.started)
                
                let transactions = await calModel
                    .getTransactions(months: model.monthsForAnalysis, cats: calModel.sCategoriesForAnalysis)
                    .filter { trans in
                        if onlyUpUntilToday {
                            return (trans.date ?? Date()) <= Date()
                        } else {
                            return true
                        }
                    }
                
                let income = await calModel.getIncome(from: transactions)
                let totalSpent = await calModel.getSpend(from: transactions)
                let debitSpend = await calModel.getDebitSpend(from: transactions)
                let spendMinusPayments = await calModel.getSpendMinusPayments(from: transactions)
                let spendMinusIncome = await calModel.getSpendMinusIncome(from: transactions)
                
                
                print("income: \(income)")
                print("totalSpent: \(totalSpent)")
                
                /// Get budgets from other apps in the Cody Suite.
                let appSuiteBudgets = await calModel.appSuiteBudgets
                
                /// Get all individual category budgets for the selected months.
                let categoricalBudgets = model.monthsForAnalysis.flatMap {
                    $0.budgets.filter { $0.type == XrefModel.getItem(from: .budgetTypes, byEnumID: .category) }
                }
                
                /// Get all group budgets for the selected months.
                let groupBudgets = model.monthsForAnalysis.flatMap {
                    $0.budgets.filter { $0.type == XrefModel.getItem(from: .budgetTypes, byEnumID: .categoryGroup) }
                }
                
                /// Filter the budgets from the selected months by the selected categories.
                let categoryIds: [String] = await calModel.sCategoriesForAnalysis.map(\.id)
                let relevantCategoricalBudgets = (categoricalBudgets + appSuiteBudgets)
                    .filter { budget in
                        if let id = budget.category?.id {
                            return categoryIds.contains(id)
                        } else {
                            return false
                        }
                    }
                
                /// Filter the budgets from the selected months by the selected groups.
                let groupIds: [String] = await calModel.sCategoryGroupsForAnalysis.map(\.id)
                let relevantGroupBudgets = groupBudgets
                    .filter { budget in
                        if let id = budget.categoryGroup?.id {
                            return groupIds.contains(id)
                        } else {
                            return false
                        }
                    }
                
                let overallCategoricalBudgetAmount = relevantCategoricalBudgets.map(\.amount).reduce(0.0, +)
                let overallGroupBudgetAmount = relevantGroupBudgets.map(\.amount).reduce(0.0, +)
                let overallBudget = overallCategoricalBudgetAmount + overallGroupBudgetAmount
                
                var chartData: [ChartData]
                if await calModel.sCategoryGroupsForAnalysis.isEmpty {
                    chartData = await calModel.sCategoriesForAnalysis
                        .sorted(by: Helpers.categorySorter())
                        /// Map over each selected category and create the chart data.
                        .asyncMap { cat in
                            /// Get transactions from the total list only for this category.
                            let trans = transactions.filter { $0.category?.id == cat.id }
                            /// Get budgets for just this category.
                            let budgets = relevantCategoricalBudgets.filter { $0.category?.id == cat.id }
                            let budgetAmount = budgets.map { $0.amount }.reduce(0.0, +)
                                                        
                            return await calModel.createChartData(
                                transactions: trans,
                                category: cat,
                                categoricalBudgetAmount: budgetAmount,
                                categoryGroup: nil,
                                groupBudgetAmount: nil,
                                budgets: budgets
                            )
                        }                                        
                } else {
                    chartData = await calModel.sCategoryGroupsForAnalysis.asyncFlatMap { group in
                        let result = await group.categories.filter({$0.active}).asyncMap { cat in
                            /// Get transactions from the total list only for this category.
                            let trans = transactions.filter { $0.category?.id == cat.id }
                            /// Get budgets for just this category.
                            let budgets = relevantCategoricalBudgets.filter { $0.category?.id == cat.id }
                            let budgetAmount = budgets.map { $0.amount }.reduce(0.0, +)
                            
                            return await calModel.createChartData(
                                transactions: trans,
                                category: cat,
                                categoricalBudgetAmount: budgetAmount,
                                categoryGroup: group,
                                groupBudgetAmount: overallBudget,
                                budgets: budgets
                            )
                        }
                        return result
                    }
                }
                
                
                let months = model.monthsForAnalysis.sorted(by: { $0.num < $1.num })
                
                let spendingBreakdownChartdata = await months.asyncMap { month in
                    let date = Calendar.current.date(from: DateComponents(year: month.year, month: month.actualNum, day: 1))!
                    let trans = transactions.filter { $0.dateComponents?.month == month.actualNum && $0.dateComponents?.year == month.year }
                    let cost = await calModel.getSpendMinusIncome(from: trans)
                    
                    return CivSpendingBreakdownChartData(month: month, date: date, cost: cost)
                }
                
                let transactionCountChartData = await months.asyncMap { month in
                    let date = Calendar.current.date(from: DateComponents(year: month.year, month: month.actualNum, day: 1))!
                    let trans = transactions.filter { $0.dateComponents?.month == month.actualNum && $0.dateComponents?.year == month.year }
                    print("\(month.num): \(trans.count)")
                    
                    return CivTransactionCountChartData(month: month, date: date, count: trans.count)
                }
                
                let actualSpendingBreakdownByCategoryChartData = await calModel.sCategoriesForAnalysis.asyncMap { cat in
                    let data = await months.asyncMap { month in
                        let date = Calendar.current.date(from: DateComponents(year: month.year, month: month.actualNum, day: 1))!
                        let trans = transactions.filter {
                            $0.dateComponents?.month == month.actualNum
                            && $0.dateComponents?.year == month.year
                            && $0.category?.id == cat.id
                        }
                        let cost = await calModel.getSpendMinusIncome(from: trans)
                        
                        return CivActualSpendingBreakdownByCategoryChartData(month: month, date: date, cost: cost)
                    }
                    
                    return CivActualSpendingBreakdownByCategoryOuterChartData(category: cat, data: data)
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
                    budget: overallBudget,
                    chartData: chartData,
                    /*
                     `ChartData` = Array of...
                     struct ChartData: Identifiable {
                         var id: String { return category.id }
                         
                         let category: CBCategory
                         var budgetForCategory: Double
                         
                         let categoryGroup: CBCategoryGroup?
                         var budgetForCategoryGroup: Double?
                         
                         var income: Double
                         var incomeMinusPayments: Double
                         var expenses: Double
                         var expensesMinusIncome: Double
                         var chartPercentage: Double
                         var actualPercentage: Double
                         var budgetObjects: Array<CBBudget>?
                     }
                     */
                    cumTotals: cumTotals,
                    spendingBreakdownChartdata: spendingBreakdownChartdata,
                    transactionCountChartData: transactionCountChartData,
                    actualSpendingBreakdownByCategoryChartData: actualSpendingBreakdownByCategoryChartData
                )

                continuation.yield(.finished(data))
                continuation.finish()
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
    
    func asyncForEach(_ transform: (Element) async throws -> Void) async rethrows {
        for element in self {
            try await transform(element)
        }
    }
}
