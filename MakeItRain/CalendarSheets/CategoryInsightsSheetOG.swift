////
////  CategoryAnalysisSheet.swift
////  MakeItRain
////
////  Created by Cody Burnett on 12/26/24.
////
//
//import SwiftUI
//import Charts
//
//
//@Observable
//class CategoryInsightsModel {
//    var monthsForAnalysis: [CBMonth] = []
//    var transactions: [CBTransaction] = []
//    var totalSpent: Double = 0.0
//    var spendMinusPayments: Double = 0.0
//    var cashOut: Double = 0.0
//    var income: Double = 0.0
//    var budget: Double = 0.0
//    var chartData: [ChartData] = []
//    var cumTotals: [CumTotal] = []
//}
//
//struct CumTotal {
//    var day: Int
//    var total: Double
//}
//
//fileprivate struct MultiMonthSheetForCategoryInsights: View {
//    @Environment(\.dismiss) var dismiss
//    @Environment(\.colorScheme) var colorScheme
//    @Environment(CalendarModel.self) private var calModel
//    @Bindable var model: CategoryInsightsModel
//    @Binding var recalc: Bool
//    
//    var body: some View {
//        @Bindable var calModel = calModel
//        NavigationStack {
//            StandardContainerWithToolbar(.list) {
//                content
//            }
//            #if os(iOS)
//            .navigationTitle("Months")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .topBarLeading) { selectButton }
//                ToolbarItem(placement: .topBarTrailing) { closeButton }
//            }
//            #endif
//        }
//        .onChange(of: model.monthsForAnalysis) {
//            print("should recalc")
//            recalc = true
//        }
//    }
//    
//    
//    var content: some View {
//        ForEach(calModel.months) { month in
//            HStack {
//                Text(month.name)
//                Spacer()
//                Image(systemName: "checkmark")
//                    .opacity(model.monthsForAnalysis.contains(month) ? 1 : 0)
//            }
//            .contentShape(Rectangle())
//            .onTapGesture { doIt(month) }
//        }
//    }
//    
//    
//    var selectButton: some View {
//        Button {
//            model.monthsForAnalysis = model.monthsForAnalysis.isEmpty ? calModel.months : []
//        } label: {
//            Text(model.monthsForAnalysis.isEmpty  ? "Select All" : "Deselect All")
//            //Image(systemName: months.isEmpty ? "checklist.checked" : "checklist.unchecked")
//                .schemeBasedForegroundStyle()
//        }
//    }
//    
//    
//    var closeButton: some View {
//        Button {
//            dismiss()
//        } label: {
//            Image(systemName: "xmark")
//                .schemeBasedForegroundStyle()
//        }
//    }
//    
//    
//    func doIt(_ month: CBMonth) {
//        if model.monthsForAnalysis.contains(month) {
//            model.monthsForAnalysis.removeAll(where: { $0.num == month.num })
//        } else {
//            model.monthsForAnalysis.append(month)
//        }
//    }
//}
//
//
//
//struct CategoryInsightsSheet: View {
//    @Environment(\.colorScheme) var colorScheme
//    #if os(macOS)
//    @Environment(\.dismiss) private var dismiss
//    @Environment(\.appearsActive) var appearsActive
//    #endif
//    @AppStorage("transactionSortMode") var transactionSortMode: TransactionSortMode = .title
//    @AppStorage("categorySortMode") var categorySortMode: SortMode = .title
//    @Local(\.useWholeNumbers) var useWholeNumbers
//    //@Local(\.colorTheme) var colorTheme
//
//    @Environment(CalendarModel.self) private var calModel
//    @Environment(PayMethodModel.self) private var payModel
//    @Environment(EventModel.self) private var eventModel
//    @Binding var showAnalysisSheet: Bool
//    @Bindable var model: CategoryInsightsModel
//    
////    struct ChartData: Identifiable {
////        var id: String { return category.id }
////        let category: CBCategory
////        var budget: Double
////        var expenses: Double
////        var budgetObject: CBBudget?
////    }
//    
//
//    //@State private var transactions: [CBTransaction] = []
//    //@State private var totalSpent: Double = 0.0
//    //@State private var spendMinusPayments: Double = 0.0
//    //@State private var cashOut: Double = 0.0
//    //@State private var income: Double = 0.0
//    //@State private var budget: Double = 0.0
//    //@State private var chartData: [ChartData] = []
//   // @State private var cumTotals: [CumTotal] = []
//    
//    @State private var transEditID: String?
//    @State private var editTrans: CBTransaction?
//    
//    @State private var transDay: CBDay?
//    @State private var showCategorySheet = false
//    
//    @State private var showInfo = false
//    
//    let columnGrid = Array(repeating: GridItem(.flexible(), spacing: 0), count: 4)
//    
//    
//    var categoryFilterTitle: LocalizedStringKey {
//        let cats = calModel.sCategoriesForAnalysis
//        let baseText = "Data is only for"
//        if cats.isEmpty {
//            return ""
//            
//        } else if cats.count == 1 {
//            return "(\(baseText) **\(cats[0].title)**.)"
//            
//        } else if cats.count == 2 {
//            return "(\(baseText) **\(cats[0].title)** & **\(cats[1].title)**.)"
//            
//        } else {
//            return "(\(baseText) **\(cats[0].title)**, **\(cats[1].title)**, and **\(cats.count - 2)** others.)"
//        }
//    }
//    
//    @State private var showMonthSheet = false
//    @State private var isPreparingData = false
//    @State private var recalc = false
//    
//    var body: some View {
//        @Bindable var calModel = calModel
//        NavigationStack {
//            StandardContainerWithToolbar(.list) {
//                detailSection
//                                
//                Section {
//                    chartSection
//                } header: {
//                    Text("Chart")
//                }
//                
//                BudgetBreakdownView(wrappedInSection: true, chartData: model.chartData, calculateDataFunction: prepareData)
//                //transactionList
//            }
//            .navigationTitle("Category Insights")
//            #if os(iOS)
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                
//                ToolbarItem(placement: .topBarLeading) { showCategorySheetButton }
//                ToolbarSpacer(.fixed, placement: .topBarLeading)
//                ToolbarItem(placement: .topBarLeading) { showMonthsButton }
//                
//                if isPreparingData {
//                    ToolbarItem(placement: .topBarTrailing) { ProgressView().tint(.none) }
//                        .sharedBackgroundVisibility(.hidden)
//                }
//                ToolbarSpacer(.fixed, placement: .topBarTrailing)
//                ToolbarItem(placement: .topBarTrailing) { closeButton }
//                                
//                ToolbarItem(placement: .bottomBar) { showCalendarButton }
//            }
//            #endif
//        }
//        .task {
//            /// If there are no months set, add the current month
//            if model.monthsForAnalysis.isEmpty {
//                let nowMonth = calModel
//                    .months
//                    .filter { $0.actualNum == AppState.shared.todayMonth && $0.year == AppState.shared.todayYear }
//                    .first
//                
//                if let nowMonth {
//                    model.monthsForAnalysis.append(nowMonth)
//                }
//            }
//                                    
//            if calModel.sCategoriesForAnalysis.isEmpty && showAnalysisSheet {
//                showCategorySheet = true
//            } else {
//                await prepareData()
//            }
//            
//        }
//        /// Needed for the inspector on iPad.
//        .onChange(of: showAnalysisSheet) {
//            if $1 && !showCategorySheet { showCategorySheet = true }
//        }
//        .sheet(isPresented: $showCategorySheet, onDismiss: {
//            //analyzeTransactions()
//        }, content: {
//            MultiCategorySheet(categories: $calModel.sCategoriesForAnalysis, showAnalyticSpecificOptions: true)
//            #if os(macOS)
//                .frame(minWidth: 300, minHeight: 500)
//                .presentationSizing(.fitted)
//            #endif
//            //CategorySheet(category: $calModel.sCategory)
//        })
//        .sheet(isPresented: $showMonthSheet, onDismiss: {
//            if recalc {
//                recalc = false
//                print("It says we should recalc")
//                Task {
//                    await prepareData()
//                }
//            }
//        }) {
//            MultiMonthSheetForCategoryInsights(model: model, recalc: $recalc)
//            #if os(macOS)
//                .frame(minWidth: 300, minHeight: 500)
//                .presentationSizing(.fitted)
//            #endif
//        }
//        .onChange(of: showCategorySheet) {
//            if !$1 {
//                Task {
//                    await prepareData()
//                }
//                
//            }
//        }
//        /// Recalculate the analysis data when the month changes.
////        .onChange(of: NavigationManager.shared.selectedMonth) {
////            /// Put a slight delay so the app has time to switch all the transactions to the new month.
////            Task {
////                try? await Task.sleep(nanoseconds: UInt64(0.3 * Double(NSEC_PER_SEC)))
////                prepareData()
////            }
////        }
//        /// Recalculate the analysis data when the month or year changes.
////        .onChange(of: calModel.sMonth.justTransactions) {
////            /// Put a slight delay so the app has time to switch all the transactions to the new month.
////            Task {
////                try? await Task.sleep(nanoseconds: UInt64(0.3 * Double(NSEC_PER_SEC)))
////                prepareData()
////            }
////        }
////        /// Recalculate when transaction amounts change.
////        .onChange(of: calModel.sMonth.justTransactions.map{ $0.amount }) {
////            /// Put a slight delay so the app has time to switch all the transactions to the new month.
////            Task {
////                try? await Task.sleep(nanoseconds: UInt64(0.3 * Double(NSEC_PER_SEC)))
////                prepareData()
////            }
////        }
//        
//        .onChange(of: DataChangeTriggers.shared.calendarDidChange) {
//            /// Put a slight delay so the app has time to switch all the transactions to the new month.
//            Task {
//                try? await Task.sleep(nanoseconds: UInt64(0.3 * Double(NSEC_PER_SEC)))
//                await prepareData()
//            }
//        }
//        
//        #if os(macOS)
//        .onChange(of: appearsActive) {
//            if $1 { Task { prepareData() } }
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
//        .transactionEditSheetAndLogic(transEditID: $transEditID, selectedDay: $transDay)
//    }
//    
////
////    var bodyOG: some View {
////        @Bindable var calModel = calModel
////        StandardContainer(AppState.shared.isIpad ? .sidebarList : .list) {
////            detailSection
////            BudgetBreakdownView(wrappedInSection: true, chartData: chartData, calculateDataFunction: prepareData)
////            transactionList
////        } header: {
////            if AppState.shared.isIpad {
////                SidebarHeader(
////                    title: "Analyze Categories",
////                    close: {
////                        #if os(iOS)
////                        withAnimation { showAnalysisSheet = false }
////                        #else
////                        dismiss()
////                        #endif
////                    },
////                    view1: { showCategorySheetButton },
////                    view2: { showCalendarButton }
////                )
////            } else {
////                SheetHeader(
////                    title: "Analyze Categories",
////                    close: {
////                        #if os(iOS)
////                        withAnimation { showAnalysisSheet = false }
////                        #else
////                        dismiss()
////                        #endif
////                    },
////                    view1: { showCategorySheetButton },
////                    view2: { showCalendarButton }
////                )
////            }
////        }
////        .task {
////            if calModel.sCategoriesForAnalysis.isEmpty {
////                showCategorySheet = true
////            } else {
////                prepareData()
////                //analyzeTransactions()
////            }
////        }
////        .sheet(isPresented: $showCategorySheet, onDismiss: {
////            //analyzeTransactions()
////        }, content: {
////            MultiCategorySheet(categories: $calModel.sCategoriesForAnalysis)
////            #if os(macOS)
////                .frame(minWidth: 300, minHeight: 500)
////                .presentationSizing(.fitted)
////            #endif
////            //CategorySheet(category: $calModel.sCategory)
////        })
////        .onChange(of: showCategorySheet) {
////            if !$1 { prepareData() }
////        }
////
////        #if os(macOS)
////        .onChange(of: appearsActive) {
////            if $1 { prepareData() }
////        }
////        #endif
////
//////        .sheet(item: $editTrans) { trans in
//////            TransactionEditView(trans: trans, transEditID: $transEditID, day: transDay!, isTemp: false)
//////                /// This is needed for the drag to dismiss.
//////                .onDisappear { transEditID = nil }
//////            #warning("produces a race condition when swiping to close and opening another trans too quickly. Causes transDays to be nil and crashes the app.")
//////        }
//////        .onChange(of: transEditID) { transEditIdChanged(oldValue: $0, newValue: $1) }
//////        .sensoryFeedback(.selection, trigger: transEditID) { $1 != nil }
////
////        .transactionEditSheetAndLogic(
////            calModel: calModel,
////            transEditID: $transEditID,
////            editTrans: $editTrans,
////            selectedDay: $transDay
////        )
////    }
////
////
//    @ViewBuilder var detailSection: some View {
//        if showInfo {
//            Section {
//                numberOfTransactionsRow
//            } header: {
//                HStack {
//                    Text("Details")
//                    Spacer()
//                    showInfoButton
//                }
//            } footer: {
//                Text("The number of transactions that are being used to calculate the metrics.")
//            }
//            
//            Section {
//                cumBudgetsRow
//            } footer: {
//                Text("A summary of the budget amounts from the selected categories.")
//            }
//            
//            Section {
//                incomeRow
//            } footer: {
//                Text("The sum of positive dollar amounts.\n(Income, Deposits, Refunds, Etc.)")
//            }
//            
//            Section {
//                cashOutRow
//            } footer: {
//                Text("The sum of all money that left your debit accounts. (Including credit/loan payments)")
//            }
//            
//            Section {
//                totalSpendingRow
//            } footer: {
//                Text("The sum of actual consumption. AKA expenses that are not offset by a credit/loan payment.")
//            }
//            
//            Section {
//                spendMinusPaymentsRow
//            } footer: {
//                Text("The sum of your expenses, offset by credit payments.")
//            }
//            
//            Section {
//                overUnderRow
//            } footer: {
//                Text("The amount left after you take the budgets and subtract the amount from the total spending row.")
//            }
//            
//        } else {
//            Section {
//                numberOfTransactionsRow
//                cumBudgetsRow
//                incomeRow
//                cashOutRow
//            } header: {
//                HStack {
//                    Text("Details")
//                    Spacer()
//                    showInfoButton
//                }
//            }
//            .listSectionSpacing(5)
//            
//            Section {
//                totalSpendingRow
//                spendMinusPaymentsRow
//                overUnderRow
//            } footer: {
//                Text(categoryFilterTitle)
//            }
//        }
//        
//    }
//    
//    var numberOfTransactionsRow: some View {
//        HStack {
//            infoButtonLabel("Number of transactions…")
//            Spacer()
//            Text("\(model.transactions.count)")
//                .contentTransition(.numericText())
//        }
//    }
//    
//    var cumBudgetsRow: some View {
//        HStack {
//            infoButtonLabel("Cumulative budget…")
//            Spacer()
//            Text(model.budget.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                .contentTransition(.numericText())
//        }
//    }
//    
//    var incomeRow: some View {
//        HStack {
//            infoButtonLabel("Income…")
//            Spacer()
//            Text((model.income).currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                .contentTransition(.numericText())
//        }
//    }
//    
//    var cashOutRow: some View {
//        HStack {
//            infoButtonLabel("Cash out…")
//            Spacer()
//            Text((model.cashOut * -1).currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                .contentTransition(.numericText())
//        }
//    }
//    
//    var totalSpendingRow: some View {
//        HStack {
//            infoButtonLabel("Total spending…")
//                .bold()
//            Spacer()
//            Text((model.totalSpent * -1).currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                .contentTransition(.numericText())
//        }
//    }
//    
//    var spendMinusPaymentsRow: some View {
//        HStack {
//            infoButtonLabel("Spending minus payments…")
//            Spacer()
//            Text((model.spendMinusPayments * -1).currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                .contentTransition(.numericText())
//        }
//    }
//    
//    var overUnderRow: some View {
//        HStack {
//            let amount = model.budget - (model.totalSpent * -1)
//            let isOver = amount < 0
//            infoButtonLabel(isOver ? "You're over-budget by…" : "You're under-budget by…")
//            Spacer()
//            Text(abs(amount).currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                .contentTransition(.numericText())
//                .foregroundStyle(isOver ? .red : .green)
//        }
//    }
//    
//    @ViewBuilder func infoButtonLabel(_ text: String) -> some View {
//        Text(text)
//            .schemeBasedForegroundStyle()
//    }
//    
//    
//    var showInfoButton: some View {
//        Button {
//            withAnimation {
//                showInfo.toggle()
//            }
//        } label: {
//            Image(systemName: "info.circle")
//        }
//        .tint(.none)
//    }
//    
//    
//    var transactionList: some View {
//        ForEach(calModel.sMonth.days.filter { $0.date != nil }) { day in
//            let doesHaveTransactions = model.transactions
//                .filter { $0.dateComponents?.day == day.date?.day }
//                .count > 0
//            
//            let dailyTotal = model.transactions
//                .filter { $0.dateComponents?.day == day.date?.day }
//                .map { ($0.payMethod?.isCreditOrLoan ?? false) ? $0.amount * -1 : $0.amount }
//                .reduce(0.0, +)
//            
//            let dailyCount = model.transactions
//                .filter { $0.dateComponents?.day == day.date?.day }
//                .count
//            
//            Section {
//                if doesHaveTransactions {
//                    ForEach(getTransactions(for: day)) { trans in
//                        TransactionListLine(trans: trans)
//                            .onTapGesture {
//                                self.transDay = day
//                                self.transEditID = trans.id
//                            }
//                    }
//                } else {
//                    Text("No Transactions")
//                        .foregroundStyle(.gray)
//                }
//            } header: {
//                if let date = day.date, date.isToday {
//                    HStack {
//                        Text("TODAY")
//                            .foregroundStyle(Color.theme)
//                        VStack {
//                            Divider()
//                                .overlay(Color.theme)
//                        }
//                    }
//                } else {
//                    Text(day.date?.string(to: .monthDayShortYear) ?? "")
//                }
//                
//            } footer: {
//                if doesHaveTransactions {
//                    sectionFooter(day: day, dailyCount: dailyCount, dailyTotal: dailyTotal)
//                }
//            }
//            
////            if let date = day.date, date.isToday {
////                Section {
////                    if doesHaveTransactions {
////                        ForEach(getTransactions(for: day)) { trans in
////                            TransactionListLine(trans: trans)
////                                .onTapGesture {
////                                    self.transDay = day
////                                    self.transEditID = trans.id
////                                }
////                        }
////                    } else {
////                        Text("No Transactions Today")
////                            .foregroundStyle(.gray)
////                    }
////                } header: {
////                    HStack {
////                        Text("TODAY")
////                            .foregroundStyle(Color.theme)
////                        VStack {
////                            Divider()
////                                .overlay(Color.theme)
////                        }
////                    }
////                } footer: {
////                    if doesHaveTransactions {
////                        SectionFooter(day: day, dailyCount: dailyCount, dailyTotal: dailyTotal, cumTotals: cumTotals)
////                    }
////                }
////            } else {
////                if doesHaveTransactions {
////                    Section {
////                        ForEach(getTransactions(for: day)) { trans in
////                            TransactionListLine(trans: trans)
////                                .onTapGesture {
////                                    self.transDay = day
////                                    self.transEditID = trans.id
////                                }
////                        }
////                    } header: {
////                        Text(day.date?.string(to: .monthDayShortYear) ?? "")
////                    } footer: {
////                        SectionFooter(day: day, dailyCount: dailyCount, dailyTotal: dailyTotal, cumTotals: cumTotals)
////                    }
////                }
////            }
//        }
//    }
//    
//    
//    func getTransactions(for day: CBDay) -> Array<CBTransaction> {
//        model.transactions
//            .filter { $0.dateComponents?.day == day.date?.day }
//            .filter { ($0.payMethod?.isPermitted ?? true) }
//            .filter { !($0.payMethod?.isHidden ?? false) }
//            .sorted {
//                if transactionSortMode == .title {
//                    return $0.title < $1.title
//                    
//                } else if transactionSortMode == .enteredDate {
//                    return $0.enteredDate < $1.enteredDate
//                    
//                } else {
//                    if categorySortMode == .title {
//                        return ($0.category?.title ?? "").lowercased() < ($1.category?.title ?? "").lowercased()
//                    } else {
//                        return $0.category?.listOrder ?? 10000000000 < $1.category?.listOrder ?? 10000000000
//                    }
//                }
//            }
//    }
//    
//    
//    
//    
//    @ViewBuilder func sectionFooter(day: CBDay, dailyCount: Int, dailyTotal: Double) -> some View {
//        HStack {
//            Text("Cumulative Total: \((model.cumTotals.filter { $0.day == day.date!.day }.first?.total ?? 0.0).currencyWithDecimals(useWholeNumbers ? 0 : 2))")
//            
//            Spacer()
//            if dailyCount > 1 {
//                Text(dailyTotal.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//            }
//        }
//    }
//        
//    
//    
//    
//    var chartSection: some View {
//        Group {
//            VStack {
//                Chart(model.chartData) { metric in
//                    BarMark(
//                        x: .value("Amount", metric.budget),
//                        y: .value("Key", "Budget")
//                    )
//                    .foregroundStyle(metric.category.color)
////                    .annotation(position: .overlay, alignment: .center) {
////                        HStack {
////                            Text(metric.budget.currencyWithDecimals(useWholeNumbers ? 0 : 2))
////                                .font(.caption2)
////                            Spacer()
////                        }
////                    }
//                    
//                    BarMark(
//                        x: .value("Amount", (metric.expenses * -1 - metric.income)),
//                        y: .value("Key", "Expenses")
//                    )
//                    .foregroundStyle(metric.category.color)
////                    .annotation(position: .overlay, alignment: .center) {
////                        HStack {
////                            Text(metric.expenses.currencyWithDecimals(useWholeNumbers ? 0 : 2))
////                                .font(.caption2)
////
////                            Spacer()
////                        }
////                    }
//                }
//                .chartLegend(.hidden)
//                
//                
//                
//                
//                ScrollView(.horizontal) {
//                    ZStack {
//                        Spacer()
//                            .containerRelativeFrame([.horizontal])
//                            .frame(height: 1)
//                                                    
//                        HStack(spacing: 0) {
//                            ForEach(model.chartData) { item in
//                                HStack(alignment: .circleAndTitle, spacing: 5) {
//                                    Circle()
//                                        .fill(item.category.color)
//                                        .frame(maxWidth: 8, maxHeight: 8) // 8 seems to be the default from charts
//                                        .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                                    
//                                    VStack(alignment: .leading, spacing: 2) {
//                                        Text(item.category.title)
//                                            .foregroundStyle(Color.secondary)
//                                            .font(.caption2)
//                                            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
////
////                                        Text(item.expenses.currencyWithDecimals(2))
////                                            .foregroundStyle(Color.secondary)
////                                            .font(.caption2)
//                                    }
//                                }
//                                .padding(.horizontal, 4)
//                                .contentShape(Rectangle())
//    //                            #if os(macOS)
//    //                            .onContinuousHover { phase in
//    //                                switch phase {
//    //                                case .active:
//    //                                    selectedBudget = item.category.title
//    //                                case .ended:
//    //                                    selectedBudget = nil
//    //                                }
//    //                            }
//    //                            #endif
//                            }
//                            Spacer()
//                        }
//                    }
//                }
//                .scrollBounceBehavior(.basedOnSize)
//                .contentMargins(.bottom, 10, for: .scrollContent)
//            }
//        }
//    }
//    
//    
//    var showCategorySheetButton: some View {
//        Button {
//            showCategorySheet = true
//        } label: {
//            Image(systemName: "books.vertical")
//        }
//        .tint(.none)
//        //.buttonStyle(.borderedProminent)
//        //.buttonStyle(.sheetHeader)
//    }
//    
//    
//    var showMonthsButton: some View {
//        Button {
//            showMonthSheet = true
//        } label: {
//            Image(systemName: "calendar")
//        }
//        .tint(.none)
//        //.buttonStyle(.borderedProminent)
//        //.buttonStyle(.sheetHeader)
//    }
//    
//    var showCalendarButton: some View {
//        Button {
//            withAnimation {
//                calModel.sCategories = calModel.sCategoriesForAnalysis
//            }
//            
//                        
//            #if os(iOS)
//            if !AppState.shared.isIpad {
//                withAnimation { showAnalysisSheet = false }
//            }
//            
//            #else
//            //dismiss()
//            #endif
//            
//        } label: {
//            Text("View Filtered Calendar")
////            Image(systemName: "calendar")
////                .contentShape(Rectangle())
//        }
//        .tint(.none)
//    }
//    
//    
//    var closeButton: some View {
//        Button {
//            #if os(iOS)
//            withAnimation { showAnalysisSheet = false }
//            #else
//            dismiss()
//            #endif
//        } label: {
//            Image(systemName: "xmark")
//        }
//        .tint(.none)
//        //.buttonStyle(.glassProminent)
//    }
//    
//   
////    func transEditIdChanged(oldValue: String?, newValue: String?) {
////        /// When `newValue` is false, save to the server. We have to use this because `.popover(isPresented:)` has no onDismiss option.
////        if oldValue != nil && newValue == nil {
////            let theDay = transDay
////            transDay = nil
////            calModel.saveTransaction(id: oldValue!, day: theDay, eventModel: eventModel)
////            //calModel.pictureTransactionID = nil
////            FileModel.shared.fileParent = nil
////
////            calModel.editLock = false
////
////        } else if newValue != nil {
////            if !calModel.editLock {
////                /// Prevent a transaction from being opened while another one is trying to save.
////                calModel.editLock = true
////                editTrans = calModel.getTransaction(by: newValue!, from: .normalList)
////            }
////        }
////    }
//    
//    
//    func prepareData() async {
//        isPreparingData = true
//        let data = await prepareDataForReal()
//                
//        withAnimation {
//            model.transactions = data.transactions
//            model.income = data.income
//            model.totalSpent = data.totalSpent
//            model.cashOut = data.cashOut
//            model.spendMinusPayments = data.spendMinusPayments
//            model.budget = data.budget
//            model.chartData = data.chartData
//            model.cumTotals = data.cumTotals
//        }
//        
//        isPreparingData = false
//    }
//    
//    
//    struct TheData {
//        var transactions: Array<CBTransaction>
//        var income: Double
//        var totalSpent: Double
//        var cashOut: Double
//        var spendMinusPayments: Double
//        var budget: Double
//        var chartData: [ChartData]
//        var cumTotals: [CumTotal]
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
//            //let relevantBudgets = calModel.sMonth.budgets.filter { calModel.sCategoriesForAnalysis.map { $0.id }.contains($0.category?.id) }
//            
//            let relevantBudgets = await model.monthsForAnalysis.asyncFlatMap { $0.budgets }.filter { budget in
//                
//                if let id = budget.category?.id {
//                    return categoryIds.contains(id)
//                } else {
//                    return false
//                }
//                //categoryIds.contains($0.category?.id)
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
//            
//            //isPreparingData = false
//        }.value
//    }
//    
//    
////    func prepareDataOG() {
////        print("-- \(#function)")
////        /// Gather only the relevant transactions.
////        model.transactions = calModel.getTransactions(cats: calModel.sCategoriesForAnalysis)
////
////        self.income = calModel.getIncome(cats: calModel.sCategoriesForAnalysis)
////        self.model.totalSpent = calModel.getSpend(cats: calModel.sCategoriesForAnalysis)
////        self.cashOut = calModel.getDebitSpend(cats: calModel.sCategoriesForAnalysis)
////        self.spendMinusPayments = calModel.getSpendMinusPayments(cats: calModel.sCategoriesForAnalysis)
////
////        let relevantBudgets = calModel.sMonth.budgets
////            .filter { calModel.sCategoriesForAnalysis.map { $0.id }.contains($0.category?.id) }
////
////        self.budget = relevantBudgets.map { $0.amount }.reduce(0.0, +)
////
////        self.chartData = calModel.sCategoriesForAnalysis
////            .sorted(by: Helpers.categorySorter())
////            .map { cat in
////                let budget = relevantBudgets.filter { $0.category?.id == cat.id }.first
////                return calModel.createChartData(cat: cat, budget: budget)
////            }
////
////        /// Analyze Data
////        self.cumTotals.removeAll()
////        var total: Double = 0.0
////
////        calModel.sMonth.days.forEach { day in
////            let doesHaveTransactions = !model.transactions.filter { $0.dateComponents?.day == day.date?.day }.isEmpty
////            if doesHaveTransactions {
////                let dailyTotal = calModel.getSpend(day: day.date?.day, cats: calModel.sCategoriesForAnalysis)
////
////                total += dailyTotal
////                self.cumTotals.append(CumTotal(day: day.date!.day, total: total))
////            }
////        }
////    }
//}
//
//extension Sequence {
//    func asyncMap<T>(_ transform: (Element) async -> T) async -> [T] {
//        var results: [T] = []
//        results.reserveCapacity(underestimatedCount)
//        for element in self {
//            results.append(await transform(element))
//        }
//        return results
//    }
//    
//    func asyncFlatMap<T>(
//            _ transform: (Element) async -> [T]
//        ) async -> [T] {
//            var results: [T] = []
//            for element in self {
//                let inner = await transform(element)
//                results.append(contentsOf: inner)
//            }
//            return results
//        }
//}
