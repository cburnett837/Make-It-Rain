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
    @Bindable var overviewModel: CivViewModel
    
    var body: some View {
        NavigationStack(path: $navPath) {
            CategoryInsightsView(navPath: $navPath, showAnalysisSheet: $showAnalysisSheet, model: model, overviewModel: overviewModel)
        }
    }
}
#endif

struct CategoryInsightsView: View {
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
    @Binding var navPath: NavigationPath
    #else
    @State private var navPath = NavigationPath()
    #endif
    @Binding var showAnalysisSheet: Bool
    @Bindable var model: CivViewModel
    @Bindable var overviewModel: CivViewModel
    
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
            switch whichView {
            case .overview:
                monthlyOverview
            case .categories:
                categoryBreakdown
            }
        }
        #if os(iOS)
        .safeAreaBar(edge: .top) {
            CivCalculatingProgressView(model: model)
        }
        #endif
        //.navigationTitle("Dashboard")
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
                categoryGroups: $calModel.sCategoryGroupsForAnalysis,
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
        .onChange(of: onlyUpUntilToday) {
            prepareData()
        }
        #if os(macOS)
        .onChange(of: appearsActive) {
            if $1 { Task { prepareData() } }
        }
        #endif
    }
    
    
    @ViewBuilder
    var monthlyOverview: some View {
        StandardContainerWithToolbar(.list) {
            Section("Net Worth Change \(calModel.sMonth.name) \(String(calModel.sMonth.year))") {
                CivNetWorthChange()
            }
            
            
            let amount = overviewModel.budget - (overviewModel.spendMinusIncome * -1)
            let isOver = amount < 0
            let overUnder = abs(amount).currencyWithDecimals()

            let budget = overviewModel.budget.currencyWithDecimals()
            let transactionCount = overviewModel.transactions.count

            let income = overviewModel.income.currencyWithDecimals()
            let cashOut = (overviewModel.cashOut * -1).currencyWithDecimals()
            let expenses = (overviewModel.totalSpent * -1).currencyWithDecimals()
            let spendingMinusPayments = (overviewModel.spendMinusPayments * -1).currencyWithDecimals()
            let actualSpending = (overviewModel.spendMinusIncome * -1).currencyWithDecimals()
            
            DetailSection(
                amount: amount,
                budget: budget,
                transactionCount: transactionCount,
                income: income,
                cashOut: cashOut,
                expenses: expenses,
                spendingMinusPayments: spendingMinusPayments,
                actualSpending: actualSpending,
                setMoneyIn: setMoneyIn,
                setCashOut: setCashOut,
                setTotalSpending: setTotalSpending
            )
            
            CivBudgetBreakdown(model: overviewModel, prepareData: prepareData)
            
        }
    }
    
    
    @ViewBuilder
    var categoryBreakdown: some View {
        if calModel.sCategoriesForAnalysis.isEmpty && calModel.sCategoryGroupsForAnalysis.isEmpty {
            contentUnavailableView
        } else {
            List {
//                detailSection
                
                let amount = model.budget - (model.spendMinusIncome * -1)
                let isOver = amount < 0
                let overUnder = abs(amount).currencyWithDecimals()
    
                let budget = model.budget.currencyWithDecimals()
                let transactionCount = model.transactions.count
    
                let income = model.income.currencyWithDecimals()
                let cashOut = (model.cashOut * -1).currencyWithDecimals()
                let expenses = (model.totalSpent * -1).currencyWithDecimals()
                let spendingMinusPayments = (model.spendMinusPayments * -1).currencyWithDecimals()
                let actualSpending = (model.spendMinusIncome * -1).currencyWithDecimals()
                
                DetailSection(
                    amount: amount,
                    budget: budget,
                    transactionCount: transactionCount,
                    income: income,
                    cashOut: cashOut,
                    expenses: expenses,
                    spendingMinusPayments: spendingMinusPayments,
                    actualSpending: actualSpending,
                    setMoneyIn: setMoneyIn,
                    setCashOut: setCashOut,
                    setTotalSpending: setTotalSpending
                )
                
                CivBudgetBreakdown(model: model, prepareData: prepareData)
                
                Section {
                    CivBudgetCompareChart(model: model)
//                    VStack(spacing: 10) {
//                        //CivBudgetCompareChart(model: model)
//                        
//                        HStack {
//                            CivBudgetCompareChart(model: model)
//                            //CivActualSpendingByCategoryBarChart(model: model)
//                            CivActualSpendingByCategoryPieChart(model: model)
//                            
//                        }
//                        
//                        CivChartLegend(model: model)
//                    }
                } header: {
                    VStack(alignment: .leading) {
                        Text("Actual Spending")
//                        Text("(Summary)")
//                            .font(.footnote)
                    }
                }
                
//                if calModel.sCategoriesForAnalysis.count > 1 {
//                    Section {
//                        HStack {
//                            CivActualSpendingByCategoryPieChart(model: model)
//                            CivActualSpendingByCategoryBarChart(model: model)
//                        }
//                    } header: {
//                        VStack(alignment: .leading) {
//                            Text("Actual Spending")
//                            Text("(Summary)")
//                                .font(.footnote)
//                        }
//                    }
//                }
                
                
//                Section {
//                    HStack {
//                        CivActualSpendingByCategoryPieChart(model: model)
//                        CivActualSpendingByCategoryBarChart(model: model)
//                    }
//                } header: {
//                    VStack(alignment: .leading) {
//                        Text("Actual Spending")
//                        Text("(Summary)")
//                            .font(.footnote)
//                    }
//                }
                                                                   
                
                
                if model.monthsForAnalysis.count > 1 {
                    Section {
                        
                        VStack(spacing: 10) {
                            VStack(alignment: .leading) {
                                Text("Spending By Category")
                                    .foregroundStyle(.gray)
                                    .font(.caption)
                                CivActualSpendingByCategoryByMonthLineChart(model: model)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Actual Spending")
                                    .foregroundStyle(.gray)
                                    .font(.caption)
                                CivSpendingBreakdownChart(model: model)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Transactions")
                                    .foregroundStyle(.gray)
                                    .font(.caption)
                                CivTransactionCountChart(model: model)
                            }
                        }
                    } header: {
                        VStack(alignment: .leading) {
                            Text("Changes Over Time")
                            
                        }
                    }
                    
//                    Section {
//                        CivActualSpendingByCategoryByMonthLineChart(model: model)
//                    } header: {
//                        VStack(alignment: .leading) {
//                            Text("Actual Spending Over Time")
//                            Text("(By category)")
//                                .font(.footnote)
//                        }
//                    }
                    
//                    Section("Transaction Count") {
//                        CivTransactionCountChart(model: model)
//                    }
                }
                
                transactionSection
            }
            .environment(\.defaultMinListRowHeight, 5)
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
            
    
    // MARK: - Detail Section
//    @ViewBuilder
//    var detailSection: some View {
//        if showInfo {
//            explanationSections
//            
//        } else {
//            let amount = model.budget - (model.spendMinusIncome * -1)
//            let isOver = amount < 0
//            let overUnder = abs(amount).currencyWithDecimals()
//            
//            let budget = model.budget.currencyWithDecimals()
//            let transactionCount = model.transactions.count
//            
//            let income = model.income.currencyWithDecimals()
//            let cashOut = (model.cashOut * -1).currencyWithDecimals()
//            let expenses = (model.totalSpent * -1).currencyWithDecimals()
//            let spendingMinusPayments = (model.spendMinusPayments * -1).currencyWithDecimals()
//            let actualSpending = (model.spendMinusIncome * -1).currencyWithDecimals()
//            
//            var message: AttributedString {
//                var result = AttributedString("With a budget of \(budget), you are currently ")
//
//                var amountPart = AttributedString(overUnder)
//                amountPart.foregroundColor = isOver ? .red : .green
//                result.append(amountPart)
//                
//                result.append(AttributedString(" \(isOver ? "over-budget" : "under-budget"), having spent "))
//                
//                var spending = AttributedString(actualSpending)
//                spending.font = .body.bold()
//                result.append(spending)
//
//                result.append(AttributedString(" across \(transactionCount) transactions."))
//                return result
//            }
//            
//            Section {
//                Text(message)
//            } header: {
//                HStack {
//                    Text("Details")
//                    Spacer()
//                    showInfoButton
//                }
//            }
//            #if os(iOS)
//            .listSectionSpacing(5)
//            #endif
//                                    
////            Section {
//////                numberOfTransactionsRow
//////                cumBudgetsRow
//////                overUnderRow
////                
////                Grid(alignment: .leading) {
////                    GridRow {
////                        Text("Transactions")
////                            .frame(maxWidth: .infinity, alignment: .leading)
////                        
////                        Text("Budget")
////                            .frame(maxWidth: .infinity, alignment: .leading)
////                        
////                        Text(isOver ? "Over-budget By" : "Under-budget By")
////                            .frame(maxWidth: .infinity, alignment: .leading)
////                            .gridCellColumns(2)
////                    }
////                    .bold()
////                    
////                    Divider()
////                    
////                    GridRow {
////                        Text("\(transactionCount)")
////                            .contentTransition(.numericText())
////                            .frame(maxWidth: .infinity, alignment: .leading)
////                        
////                        Text(budget)
////                            .contentTransition(.numericText())
////                            .frame(maxWidth: .infinity, alignment: .leading)
////                        
////                        Text(overUnder)
////                            .contentTransition(.numericText())
////                            .foregroundStyle(isOver ? .red : .green)
////                            .gridCellColumns(2)
////                            .frame(maxWidth: .infinity, alignment: .leading)
////                    }
////                }
////                .font(.caption)
////            } header: {
////               HStack {
////                   Text("Details")
////                   Spacer()
////                   showInfoButton
////               }
////           }
////           #if os(iOS)
////           .listSectionSpacing(5)
////           #endif
//                        
//            Section {
//                Grid(alignment: .leading) {
//                    GridRow {
//                        Text("Income")
//                            .onTapGesture { setMoneyIn(shouldNavigate: true) }
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                        
//                        Text("Cash Out")
//                            .onTapGesture { setCashOut(shouldNavigate: true) }
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                        
//                        Text("Expenses")
//                            .onTapGesture { setTotalSpending(shouldNavigate: true) }
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                        
//                        if isAnalyzingAtLeastOneCreditCategory {
//                            Text("Spending Minus Payments")
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                        }
//                        
//                        Text("Spending")
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                    }
//                    .bold()
//                    
//                    
//                    Divider()
//                    
//                    GridRow {
//                        Text(income)
//                            .contentTransition(.numericText())
//                            .onTapGesture { setMoneyIn(shouldNavigate: true) }
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                        
//                        Text(cashOut)
//                            .contentTransition(.numericText())
//                            .onTapGesture { setCashOut(shouldNavigate: true) }
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                        
//                        Text(expenses)
//                            .contentTransition(.numericText())
//                            .onTapGesture { setTotalSpending(shouldNavigate: true) }
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                        
//                        if isAnalyzingAtLeastOneCreditCategory {
//                            Text(spendingMinusPayments)
//                                .contentTransition(.numericText())
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                        }
//                        
//                        Text(actualSpending)
//                            .contentTransition(.numericText())
//                            .bold()
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                    }
//                }
//                .font(.caption)
//            } footer: {
//                Text(categoryFilterTitle)
//            }
//        }
//    }
    
    
    private struct DetailSection: View {
        let amount: Double
        var isOver: Bool { amount < 0 }
        var overUnder: String { abs(amount).currencyWithDecimals() }
        
        let budget: String
        let transactionCount: Int
        
        let income: String
        let cashOut: String
        let expenses: String
        let spendingMinusPayments: String
        let actualSpending: String
        
        let setMoneyIn: (Bool) -> Void
        let setCashOut: (Bool) -> Void
        let setTotalSpending: (Bool) -> Void
        
        var message: AttributedString {
            var result = AttributedString("With a budget of \(budget), you are currently ")

            var amountPart = AttributedString(overUnder)
            amountPart.foregroundColor = isOver ? .red : .green
            result.append(amountPart)
            
            result.append(AttributedString(" \(isOver ? "over-budget" : "under-budget"), having spent "))
            
            var spending = AttributedString(actualSpending)
            spending.font = .body.bold()
            result.append(spending)

            result.append(AttributedString(" across \(transactionCount) transactions."))
            return result
        }
                
        var body: some View {
            if false {
                //Text("FIX ME")
                //explanationSections
                
            } else {
                Section {
                    Text(message)
                } header: {
                    HStack {
                        Text("Details")
                        Spacer()
                        //showInfoButton
                    }
                }
                #if os(iOS)
                .listSectionSpacing(5)
                #endif
                            
                Section {
                    Grid(alignment: .leading) {
                        GridRow {
                            Text("Income")
                                .onTapGesture { setMoneyIn(true) }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("Cash Out")
                                .onTapGesture { setCashOut(true) }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("Expenses")
                                .onTapGesture { setTotalSpending(true) }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
//                            if isAnalyzingAtLeastOneCreditCategory {
//                                Text("Spending Minus Payments")
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                            }
                            
                            Text("Spending")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .bold()
                        
                        
                        Divider()
                        
                        GridRow {
                            Text(income)
                                .contentTransition(.numericText())
                                //.onTapGesture { setMoneyIn(shouldNavigate: true) }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text(cashOut)
                                .contentTransition(.numericText())
                                //.onTapGesture { setCashOut(shouldNavigate: true) }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text(expenses)
                                .contentTransition(.numericText())
                                //.onTapGesture { setTotalSpending(shouldNavigate: true) }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
//                            if isAnalyzingAtLeastOneCreditCategory {
//                                Text(spendingMinusPayments)
//                                    .contentTransition(.numericText())
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                            }
                            
                            Text(actualSpending)
                                .contentTransition(.numericText())
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .font(.caption)
                }
//                footer: {
//                    Text("FIX ME")
//                    //Text(categoryFilterTitle)
//                }
            }
        }
    }
    
    
    @ViewBuilder
    var explanationSections: some View {
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
//    @State private var breakdownOrChart = "chart"
//    @State private var rawSelectedData: String?
//    var selectedData: ChartData? {
//        guard let rawSelectedData else { return nil }
//        return model.chartData.filter { $0.category.title == rawSelectedData }.first
//        
//    }
//    var relevantData: [ChartData] {
//        model.chartData.filter { $0.expenses < 0 || $0.income > 0 }
//    }
    
//    var breakdownSection: some View {
////        Section {
////            BudgetBreakdownView(chartData: model.chartData, calculateDataFunction: prepareData)
////        } header: {
////            sectionHeader("Breakdown")
////        } footer: {
////            BreakdownExportCsvButton(chartData: model.chartData)
////        }
//        
//        Section {
//            if breakdownOrChart == "chart" {
//                verticalBarChart
//            } else {
//                BudgetBreakdownView(chartData: model.chartData, calculateDataFunction: prepareData)
//            }
//        } header: {
//            expenseByCategoryHeaderMenu
//        }
//        .textCase(nil)
//    }
//    
//    var expenseByCategoryHeaderMenu: some View {
//        Menu {
//            Section {
//                Button {
//                    breakdownOrChart = "chart"
//                } label: {
//                    Label("Chart", systemImage: "chart.bar.doc.horizontal")
//                }
//                
//                Button {
//                    breakdownOrChart = "breakdown"
//                } label: {
//                    Label("Breakdown", systemImage: "list.bullet")
//                }
//            }
//            
//            Section {
//                exportCsvButton
//            }
//        } label: {
//            HStack(spacing: 4) {
//                Text("Budget By Category")
//                    .foregroundStyle(.gray)
//                    .bold()
//                
//                Image(systemName: "chevron.right")
//                    .foregroundStyle(.gray)
//                    .font(.subheadline)
//            }
//        }
//    }
//    
//    
//    var exportCsvButton: some View {
//        // file rows
//        let rows = model.chartData.map {
//            let budget = $0.budgetForCategory
//            let expense = ($0.expenses == 0 ? 0 : $0.expenses * -1)
//            let income = ($0.income)
//            let overUnder1 = $0.budgetForCategory + ($0.expenses + $0.income)
//            let overUnder2 = abs(overUnder1)
//            
//            return [$0.category.title, String(budget), String(expense), String(income), String(overUnder2)]
//        }
//        return ExportCsvButton(fileName: "Breakdown-\(calModel.sMonth.name)-\(calModel.sYear).csv", headers: ["Category", "Budget", "Expenses", "Income", "Variance"], rows: rows) {
//            Label("Export CSV", systemImage: "tablecells")
//        }
//    }
//    
//    
//    var verticalBarChart: some View {
//        VStack {
//            Chart {
//                ForEach(relevantData) { item in
//                    if item.expensesMinusIncome > 0 {
//                        BarMark(
//                            x: .value("Amount", item.chartPercentage),
//                            y: .value("Budget", item.category.title)
//                        )
//                        .foregroundStyle(getColor(for: item.category, withOpacity: false))
//                    }
//                    
//                    BarMark(
//                        x: .value("Amount", 100 - item.chartPercentage),
//                        y: .value("Budget", item.category.title)
//                    )
//                    //.foregroundStyle(getColor(for: item.category, withOpacity: true))
//                    .foregroundStyle(.clear)
//                    .annotation(position: .top, alignment: .trailing, spacing: 0) {
//                        percentageAnnotation(for: item)
//                    }
//                }
//                
//                if let selectedData {
//                    BarMark(
//                        x: .value("Amount", 0),
//                        y: .value("Budget", selectedData.category.title)
//                    )
//                    .foregroundStyle(.clear)
//                    .annotation(
//                        position: .automatic,
//                        alignment: .trailing,
//                        spacing: 0,
//                        overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
//                    ) {
//                        barChartAnnotation
//                    }
//                }
//            }
//            .chartXAxis {
//                AxisMarks(
//                    format: Decimal.FormatStyle.Percent.percent.scale(1),
//                    values: [0, 25, 50, 75, 100]
//                )
//            }
//            .chartYSelection(value: $rawSelectedData.animation())
//            .chartScrollTargetBehavior(.valueAligned(unit: 1))
//            .frame(height: CGFloat(relevantData.count) * 30)
//        }
//    }
//    
//    var barChartAnnotation: some View {
//        VStack(alignment: .leading) {
//            HStack {
//                Text(selectedData!.category.title.capitalized)
//                Spacer()
//                
//                ChartCircleDot(
//                    budget: selectedData!.budgetForCategory,
//                    expenses: abs(selectedData!.expenses),
//                    color: colorScheme == .dark ? .white : .black,
//                    size: 20
//                )
//                
//                Image(systemName: selectedData!.category.emoji ?? "circle")
//            }
//            .font(.headline)
//            
//            Divider()
//            Text("Budget: \(selectedData!.budgetForCategory.currencyWithDecimals())")
//                .bold()
//            Text("Income: \(selectedData!.income.currencyWithDecimals())")
//                .bold()
//            Text("Expenses: \((selectedData!.expenses * -1).currencyWithDecimals())")
//                .bold()
//        }
//        .foregroundStyle(.white)
//        .padding(12)
//        .frame(minWidth: 180)
//        .background(
//            RoundedRectangle(cornerRadius: 10)
//                .fill(selectedData!.category.color)
//        )
//        .accessibilityHidden(true)
//    }
//    
//    
//    @ViewBuilder func percentageAnnotation(for item: ChartData) -> some View {
//        Text("\(Int(item.actualPercentage))%")
//            .font(.caption)
//            .foregroundStyle(.secondary)
//    }
//    
//    
//    func getColor(for category: CBCategory, withOpacity: Bool) -> Color {
//        selectedData == nil
//        ? category.color.opacity(withOpacity ? 0.2 : 1)
//        : selectedData!.category.id == category.id
//        ? category.color.opacity(withOpacity ? 0.2 : 1)
//        : .gray.opacity(0.5)
//    }
    
    
    
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
        
        ToolbarItem(placement: .title) {
            Picker("", selection: $whichView) {
                Text("Overview")
                    .tag(WhichView.overview)
                Text("Categories")
                    .tag(WhichView.categories)
            }
            .labelsHidden()
            .pickerStyle(.segmented)
        }
                
        if AppState.shared.isIpad {
            ToolbarItem(placement: .topBarLeading) { showCategorySheetButton }
            ToolbarSpacer(.fixed, placement: .topBarLeading)
            ToolbarItem(placement: .topBarLeading) { showMonthsButton }
        }
        
        if AppState.shared.isIpad {
            ToolbarItem(placement: .topBarTrailing) { closeButton }
        } else {
            //ToolbarItem(placement: .topBarTrailing) { showCategorySheetButton }
            //ToolbarSpacer(.fixed, placement: .topBarTrailing)
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    showCategorySheetButton
                    showMonthsButton
                    Divider()
                    Toggle(isOn: $onlyUpUntilToday) {
                        Text("Up until today only")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .schemeBasedForegroundStyle()
                }
                
            }
        }
        
                        
        if !calModel.sCategoriesForAnalysis.isEmpty || !calModel.sCategoryGroupsForAnalysis.isEmpty {
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
    
    
    var showMonthsButton: some View {
        Button {
            showMonthSheet = true
        } label: {
            Label {
                Text("Select Months")
            } icon: {
                Image(systemName: "calendar")
            }
        }
        .tint(.none)
        #if os(macOS)
        .buttonStyle(.roundMacButton)
        #endif
    }
    
    
    var showCalendarButton: some View {
        Button {
            withAnimation {
                calModel.sCategories = (calModel.sCategoriesForAnalysis + calModel.sCategoryGroupsForAnalysis.flatMap { $0.categories }).uniqued(on: { $0.id })
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
        var budgetVsSpendChartData: [ChartData]
        var groupBudgetVsSpendChartData: [GroupChartData]
        var cumTotals: [CumTotal]
        var spendingBreakdownChartdata: [CivSpendingBreakdownChartData]
        var transactionCountChartData: [CivTransactionCountChartData]
        var actualSpendingBreakdownByCategoryChartData: [CivActualSpendingBreakdownByCategoryOuterChartData]
    }
    
    
    enum DataPreparationProgress {
        case started
        case step(String, Double)  // description + percent
        case finished(TheData)
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
        
        /// For each selected month.
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
            
            //print("\(cat.title): \(actualSpend)")
            
            return CivBreakdownData(category: cat, moneyIn: moneyIn, cashOut: cashOut, spending: totalSpend, actualSpending: actualSpend)
        }
        
        let data = CivMonthlyData(dataPoint: .all, month: month, trans: model.transactions, breakdown: breakdown, dataByCategory: catData)
        //print("Process!!")
        process(data: data, forceToTransactionList: true)
        
        if shouldNavigate {
            navigate(forceToTransactionList: true)
        }
    }
    
    
    fileprivate func navigate(forceToTransactionList: Bool = false) {
        if model.monthsForAnalysis.count == 1 || forceToTransactionList {
            //print("Navigating to transaction list")
            navPath.append(CivNavDestination.transactionList)
        } else {
            navPath.append(CivNavDestination.monthList)
        }
    }
    
    
    fileprivate func process(data: CivMonthlyData, forceToTransactionList: Bool = false) {
        print("-- \(#function)")
        Task.detached(priority: .userInitiated) { [model] in
            print("-- \(#function)")
            var target: CivMonthlyData?
            if model.monthsForAnalysis.count == 1 || forceToTransactionList {
                target = model.selectedMonth
            } else {
                target = model.selectedMonthGroup.filter({ $0.month.num == data.month.num }).first
            }
            
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
            
            //print("-- \(#function) - DONE")
        }
    }
    
    
    @MainActor
    func prepareData() {
        //model.selectedMonthGroup.removeAll()
        model.progress = 0
        overviewModel.progress = 0
        withAnimation {
            model.showLoadingSpinner = true
        }

        //model.startDelayedLoadingSpinnerTimer()

        self.refreshTask = Task {
            for await update in prepareCategoricalDataForRealStream(onlyUpUntilToday: onlyUpUntilToday) {
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
                        model.budgetVsSpendChartData = data.budgetVsSpendChartData
                        model.groupBudgetVsSpendChartData = data.groupBudgetVsSpendChartData
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
            
            
//            for await update in prepareOverviewDataForRealStream(onlyUpUntilToday: onlyUpUntilToday) {
//                switch update {
//                case .started:
//                    overviewModel.progress = 0
//                case .step(let message, let percent):
//                    withAnimation {
//                        overviewModel.progress = percent
//                        overviewModel.statusMessage = message
//                    }
//                case .finished(let data):
//                    withAnimation {
//                        overviewModel.transactions = data.transactions
//                        overviewModel.income = data.income
//                        overviewModel.totalSpent = data.totalSpent
//                        overviewModel.cashOut = data.cashOut
//                        overviewModel.spendMinusIncome = data.spendMinusIncome
//                        overviewModel.spendMinusPayments = data.spendMinusPayments
//                        overviewModel.budget = data.budget
//                        overviewModel.budgetVsSpendChartData = data.budgetVsSpendChartData
//                        overviewModel.cumTotals = data.cumTotals
//                    }
//                    
//                    withAnimation {
//                        overviewModel.spendingBreakdownChartdata = data.spendingBreakdownChartdata
//                        overviewModel.transactionCountChartData = data.transactionCountChartData
//                        overviewModel.actualSpendingBreakdownByCategoryChartData = data.actualSpendingBreakdownByCategoryChartData
//                    }
//                    
//                    withAnimation {
//                        overviewModel.progress = 1
//                        overviewModel.showLoadingSpinner = false
//                    }
//                    
//                    //model.stopDelayedLoadingSpinnerTimer()
//                }
//            }
            
            
            
            
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
        }
    }
    
    
    
    func prepareCategoricalDataForRealStream(onlyUpUntilToday: Bool) -> AsyncStream<DataPreparationProgress> {
        AsyncStream { continuation in
            Task.detached(priority: .userInitiated) { [calModel, model] in
                continuation.yield(.started)
                
                let fetchCats = await calModel.sCategoriesForAnalysis + calModel.sCategoryGroupsForAnalysis.flatMap(\.categories)
                
                let transactions = await calModel
                    .getTransactions(months: model.monthsForAnalysis, cats: fetchCats)
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
                
                
                //print("income: \(income)")
                //print("totalSpent: \(totalSpent)")
                
                
                
                /// Get budgets from other apps in the Cody Suite.
                let appSuiteBudgets = await calModel.appSuiteBudgets
                
                /// Get all individual category budgets for the selected months.
                let categoricalBudgets = model.monthsForAnalysis.flatMap {
                    $0.budgets.filter { $0.type == XrefModel.getItem(from: .budgetTypes, byEnumID: .category) }
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
                
                
                
                /// Get all group budgets for the selected months.
                let groupBudgets = model.monthsForAnalysis.flatMap {
                    $0.budgets.filter { $0.type == XrefModel.getItem(from: .budgetTypes, byEnumID: .categoryGroup) }
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
                let overallBudget = overallCategoricalBudgetAmount + overallGroupBudgetAmount // -> Goes to model.budget
                
                //var budgetVsSpendChartData: [ChartData] = []
                //var groupBudgetVsSpendChartData: [GroupChartData] = []
                let budgetVsSpendChartData = await calModel.sCategoriesForAnalysis.filter({ $0.active }).sorted(by: Helpers.categorySorter()).asyncMap { cat in
                    /// Get transactions from the total list only for this category.
                    let trans = transactions.filter { $0.category?.id == cat.id }
                    /// Get budgets for just this category.
                    let budgets = relevantCategoricalBudgets.filter { $0.category?.id == cat.id }
                    let budgetAmount = budgets.map { $0.amount }.reduce(0.0, +)
                    
                    
//                    ChartData(
//                        category: category,
//                        budgetForCategory: categoricalBudgetAmount,
//                        categoryGroup: categoryGroup,
//                        budgetForCategoryGroup: groupBudgetAmount,
//                        income: income,
//                        incomeMinusPayments: incomeMinusPayments,
//                        expenses: expenses,
//                        expensesMinusIncome: expensesMinusIncome,
//                        chartPercentage: chartPer,
//                        actualPercentage: actualPer,
//                        budgetObjects: budgets
//                    )
                    
                    return await calModel.createChartData(
                        transactions: trans,
                        category: cat,
                        categoricalBudgetAmount: budgetAmount,
                        categoryGroup: nil,
                        groupBudgetAmount: nil,
                        budgets: budgets
                    )
                }
                
                let groupBudgetVsSpendChartData = await calModel.sCategoryGroupsForAnalysis.asyncMap { group in
                    let budgetAmount = relevantGroupBudgets.filter { $0.categoryGroup?.id == group.id }.first?.amount ?? 0.0
                    print("\(group.title) \(budgetAmount)")
                    //let budgetAmount = budgets.amount
                    
                    let chartData = await group.categories.filter({ $0.active }).asyncMap { cat in
                        /// Get transactions from the total list only for this category.
                        let trans = transactions.filter { $0.category?.id == cat.id }
                        
                        return await calModel.createChartData(
                            transactions: trans,
                            category: cat,
                            categoricalBudgetAmount: 0,
                            categoryGroup: nil,
                            groupBudgetAmount: nil,
                            budgets: []
                        )
                    }
                    
                    return GroupChartData(group: group, budget: budgetAmount, data: chartData)
                }
                
                //budgetVsSpendChartData.append(contentsOf: catChartData)
                //budgetVsSpendChartData.append(contentsOf: groupChartData)
                
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
                    //print("\(month.num): \(trans.count)")
                    
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
                        
                        let budgets = month.budgets.filter { $0.type == XrefModel.getItem(from: .budgetTypes, byEnumID: .category) && $0.category?.id == cat.id }
                        
                        
                        var chartData = await calModel.createChartData(
                            transactions: trans,
                            category: cat,
                            categoricalBudgetAmount: budgets.map { $0.amount }.reduce(0, +),
                            categoryGroup: nil,
                            groupBudgetAmount: nil,
                            budgets: budgets
                        )
                        chartData.month = month
                        chartData.dateForMonth = date
                        
                        return chartData
//                        return CivActualSpendingBreakdownByCategoryChartData(
//                            month: month,
//                            date: date,
//                            cost: cost
//                        )
                    }
                    
                    return CivActualSpendingBreakdownByCategoryOuterChartData(category: cat, costPerMonth: data)
                }
                
                
                let actualSpendingBreakdownByCategoryGroupChartData = await calModel.sCategoryGroupsForAnalysis.asyncMap { group in
                    let groupData = await group.categories.filter({ $0.active }).asyncFlatMap { cat in
                        return await months.asyncMap { month in
                            let date = Calendar.current.date(from: DateComponents(year: month.year, month: month.actualNum, day: 1))!
                            let trans = transactions.filter {
                                $0.dateComponents?.month == month.actualNum
                                && $0.dateComponents?.year == month.year
                                && $0.category?.id == cat.id
                            }
                            let cost = await calModel.getSpendMinusIncome(from: trans)
                            let budgets = month.budgets.filter { $0.type == XrefModel.getItem(from: .budgetTypes, byEnumID: .categoryGroup) && $0.categoryGroup?.id == group.id }
                            
                            //return CivActualSpendingBreakdownByCategoryChartData(month: month, category: cat, date: date, cost: cost)
                            
                            var chartData = await calModel.createChartData(
                                transactions: trans,
                                category: cat,
                                categoricalBudgetAmount: budgets.map { $0.amount }.reduce(0, +),
                                categoryGroup: nil,
                                groupBudgetAmount: nil,
                                budgets: budgets
                            )
                            chartData.month = month
                            chartData.dateForMonth = date
                            
                            return chartData
                            
                            
                        }
                        
                    }
                    
                    return CivActualSpendingBreakdownByCategoryOuterChartData(group: group, costPerMonth: groupData)
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
                    budgetVsSpendChartData: budgetVsSpendChartData,
                    groupBudgetVsSpendChartData: groupBudgetVsSpendChartData,
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
                    actualSpendingBreakdownByCategoryChartData: actualSpendingBreakdownByCategoryChartData + actualSpendingBreakdownByCategoryGroupChartData
                )

                continuation.yield(.finished(data))
                continuation.finish()
            }
        }
    }
    
//    
//    
//    func prepareOverviewDataForRealStream(onlyUpUntilToday: Bool) -> AsyncStream<DataPreparationProgress> {
//        AsyncStream { continuation in
//            Task.detached(priority: .userInitiated) { [calModel] in
//                continuation.yield(.started)
//                
//                let transactions = await calModel
//                    .getTransactions() /// Defaults to sMonth.
//                    .filter { trans in
//                        if onlyUpUntilToday {
//                            return (trans.date ?? Date()) <= Date()
//                        } else {
//                            return true
//                        }
//                    }
//                
//                let sMonth = await calModel.sMonth
//                let income = await calModel.getIncome(from: transactions)
//                let totalSpent = await calModel.getSpend(from: transactions)
//                let debitSpend = await calModel.getDebitSpend(from: transactions)
//                let spendMinusPayments = await calModel.getSpendMinusPayments(from: transactions)
//                let spendMinusIncome = await calModel.getSpendMinusIncome(from: transactions)
//                let activeCats = await catModel.categories.filter { $0.active && !$0.isHidden }
//                let activeCatGroups = await catModel.categoryGroups.filter { $0.active }
//                //let activeTrans = sMonth.justTransactions.filter { $0.active }
//                
//                
//                //print("income: \(income)")
//                //print("totalSpent: \(totalSpent)")
//                
//                /// Get budgets from other apps in the Cody Suite.
//                let appSuiteBudgets = await calModel.appSuiteBudgets
//                
//                /// Get all individual category budgets for the selected months.
//                let categoricalBudgets = sMonth.budgets.filter { $0.type == XrefModel.getItem(from: .budgetTypes, byEnumID: .category) }
//                
//                
//                /// Get all group budgets for the selected months.
//                let groupBudgets = sMonth.budgets.filter { $0.type == XrefModel.getItem(from: .budgetTypes, byEnumID: .categoryGroup) }
//                
//                /// Filter the budgets from the selected months by the selected categories.
//                let categoryIds: [String] = activeCats.map(\.id)
//                let relevantCategoricalBudgets = (categoricalBudgets + appSuiteBudgets)
//                    .filter { budget in
//                        if let id = budget.category?.id {
//                            return categoryIds.contains(id)
//                        } else {
//                            return false
//                        }
//                    }
//                
//                /// Filter the budgets from the selected months by the selected groups.
//                let groupIds: [String] = activeCatGroups.map(\.id)
//                let relevantGroupBudgets = groupBudgets
//                    .filter { budget in
//                        if let id = budget.categoryGroup?.id {
//                            return groupIds.contains(id)
//                        } else {
//                            return false
//                        }
//                    }
//                
//                let overallCategoricalBudgetAmount = relevantCategoricalBudgets.map(\.amount).reduce(0.0, +)
//                let overallGroupBudgetAmount = relevantGroupBudgets.map(\.amount).reduce(0.0, +)
//                let overallBudget = overallCategoricalBudgetAmount + overallGroupBudgetAmount
//                
//                var chartData: [ChartData]
//                if activeCatGroups.isEmpty {
//                    chartData = await activeCats
//                        .sorted(by: Helpers.categorySorter())
//                        /// Map over each selected category and create the chart data.
//                        .asyncMap { cat in
//                            /// Get transactions from the total list only for this category.
//                            let trans = transactions.filter { $0.category?.id == cat.id }
//                            /// Get budgets for just this category.
//                            let budgets = relevantCategoricalBudgets.filter { $0.category?.id == cat.id }
//                            let budgetAmount = budgets.map { $0.amount }.reduce(0.0, +)
//                                                        
//                            return await calModel.createChartData(
//                                transactions: trans,
//                                category: cat,
//                                categoricalBudgetAmount: budgetAmount,
//                                categoryGroup: nil,
//                                groupBudgetAmount: nil,
//                                budgets: budgets
//                            )
//                        }
//                } else {
//                    chartData = await activeCatGroups.asyncFlatMap { group in
//                        let result = await group.categories.filter({ $0.active }).asyncMap { cat in
//                            /// Get transactions from the total list only for this category.
//                            let trans = transactions.filter { $0.category?.id == cat.id }
//                            /// Get budgets for just this category.
//                            let budgets = relevantCategoricalBudgets.filter { $0.category?.id == cat.id }
//                            let budgetAmount = budgets.map { $0.amount }.reduce(0.0, +)
//                            
//                            return await calModel.createChartData(
//                                transactions: trans,
//                                category: cat,
//                                categoricalBudgetAmount: budgetAmount,
//                                categoryGroup: group,
//                                groupBudgetAmount: overallBudget,
//                                budgets: budgets
//                            )
//                        }
//                        return result
//                    }
//                }
//                
//                //print(chartData.map {$0.category.title})
//                
//                //print(activeCats.map {$0.title})
//                
//                let date = Calendar.current.date(from: DateComponents(year: sMonth.year, month: sMonth.actualNum, day: 1))!
//                let cost = await calModel.getSpendMinusIncome(from: transactions)
//                let spendingBreakdownChartdata = [CivSpendingBreakdownChartData(month: sMonth, date: date, cost: cost)]
//                let transactionCountChartData = [CivTransactionCountChartData(month: sMonth, date: date, count: transactions.count)]
//
//                let actualSpendingBreakdownByCategoryChartData = await activeCats.asyncMap { cat in
//                    let catTrans = sMonth.justTransactions.filter { $0.category?.id == cat.id }
//                    let cost = await calModel.getSpendMinusIncome(from: catTrans)
//                    let data = CivActualSpendingBreakdownByCategoryChartData(month: sMonth, date: date, cost: cost)
//                    return CivActualSpendingBreakdownByCategoryOuterChartData(category: cat, costPerMonth: [data])
//                }
//
//                //continuation.yield(.step("Summarizing days", 0.1))
//                var cumTotals: [CumTotal] = []
//                var total: Double = 0.0
//                
//                let totalDays = sMonth.days.count
//                
//                let progressAtThisPoint = 0.0
//                for (index, day) in sMonth.days.enumerated() {
//                    let daysTrans = transactions.filter { $0.dateComponents?.day == day.id }
//                    if !daysTrans.isEmpty {
//                        let debitSpend = await calModel.getDebitSpend(from: daysTrans)
//                        let creditSpend = await calModel.getCreditSpend(from: daysTrans)
//                        
//                        let dailyTotal = debitSpend + creditSpend
//                        total += dailyTotal
//                        cumTotals.append(
//                            CumTotal(day: day.date!.day, total: total)
//                        )
//                    }
//                    
//                    let fraction = Double(index + 1) / Double(totalDays)    // 1/totalSteps → 1.0
//                    let progress = progressAtThisPoint + (1 - progressAtThisPoint) * fraction
//                    //print(progress)
//                    continuation.yield(.step("Analyzing days", progress))
//                }
//
//                let data = TheData(
//                    transactions: transactions,
//                    income: income,
//                    totalSpent: totalSpent,
//                    cashOut: debitSpend,
//                    spendMinusIncome: spendMinusIncome,
//                    spendMinusPayments: spendMinusPayments,
//                    budget: overallBudget,
//                    budgetVsSpendChartData: chartData,
//                    groupBudgetVsSpendChartData: [],
//                    /*
//                     `ChartData` = Array of...
//                     struct ChartData: Identifiable {
//                         var id: String { return category.id }
//                         
//                         let category: CBCategory
//                         var budgetForCategory: Double
//                         
//                         let categoryGroup: CBCategoryGroup?
//                         var budgetForCategoryGroup: Double?
//                         
//                         var income: Double
//                         var incomeMinusPayments: Double
//                         var expenses: Double
//                         var expensesMinusIncome: Double
//                         var chartPercentage: Double
//                         var actualPercentage: Double
//                         var budgetObjects: Array<CBBudget>?
//                     }
//                     */
//                    cumTotals: cumTotals,
//                    spendingBreakdownChartdata: spendingBreakdownChartdata,
//                    transactionCountChartData: transactionCountChartData,
//                    actualSpendingBreakdownByCategoryChartData: actualSpendingBreakdownByCategoryChartData
//                )
//
//                continuation.yield(.finished(data))
//                continuation.finish()
//            }
//        }
//    }
}
