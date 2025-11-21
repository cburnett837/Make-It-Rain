//
//  BudgetTable.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/6/24.
//

import SwiftUI
import Charts


struct CalendarDashboard: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    //@Local(\.colorTheme) var colorTheme
    @AppStorage("calendarChartMode") var chartMode = CalendarChartModel.verticalBar
    @AppStorage("viewMode") var viewMode = CalendarViewMode.scrollable
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Local(\.categorySortMode) var categorySortMode
    
    
    @Environment(CalendarModel.self) private var calModel
    @Environment(CategoryModel.self) private var catModel
    
    @State private var deleteBudget: CBBudget?
    @State private var editBudget: CBBudget?
    @State private var budgetEditID: CBBudget.ID?
        
    @State private var selectedAngle: Double?
    @State private var whichView: WhichView = .chart
    
    enum WhichView { case chart, list }
    
    @State private var breakdownOrChart = "chart"
    
    
    @State private var rawSelectedData: String?
    var selectedData: ChartData? {
        guard let rawSelectedData else { return nil }
        return data.filter { $0.category.title == rawSelectedData }.first
        
    }
    @State private var data: [ChartData] = []
    var relevantData: [ChartData] {
        data.filter { $0.expenses < 0 || $0.income > 0 }
    }
            
    var budgetCount: Int { calModel.sMonth.budgets.count }
    var title: String { "Dashboard \(calModel.sMonth.name) \(String(calModel.sMonth.year))" }
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        //let _ = Self._printChanges()
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                Section("Net Worth Change") {
                    networthChange
                }
                
                Section {
                    if breakdownOrChart == "chart" {
                        verticalBarChart
                    } else {
                        BudgetBreakdownView(chartData: data, calculateDataFunction: prepareData)
                    }
                } header: {
                    expenseByCategoryHeaderMenu
                }
                .textCase(nil)
                
                Section("Spending Overview") {
                    pieChart
                }
            }
            #if os(iOS)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            #endif
        }
        .onChange(of: budgetEditID) { oldValue, newValue in
            if let newValue {
                editBudget = calModel.sMonth.budgets.filter { $0.id == newValue }.first!
            } else if newValue == nil && oldValue != nil {
                let budget = calModel.sMonth.budgets.filter { $0.id == oldValue! }.first!
                Task {
                    if budget.hasChanges() {
                        print("HAS CHANGES")
                        await calModel.submit(budget)
                    } else {
                        print("NO CHANGES")
                    }
                }
            }
        }
        .sheet(item: $editBudget, onDismiss: {
            budgetEditID = nil
        }, content: { budget in
            BudgetEditView(budget: budget, calModel: calModel)
                .presentationSizing(.page)
                //#if os(iOS)
                //.presentationDetents([.medium, .large])
                //#endif
                //#if os(macOS)
                //.frame(minWidth: 700)
                //#endif
                //.frame(maxWidth: 300)
        })
        .task { prepareData() }
        /// Recalculate the analysis data when the month or year changes.
        .onChange(of: DataChangeTriggers.shared.calendarDidChange) {
            print("🤞🏻 CalendarDashboard.body: Received recalc trigger")
            prepareData()
//            Task {
//                try? await Task.sleep(nanoseconds: UInt64(0.3 * Double(NSEC_PER_SEC)))
//                prepareData()
//            }
        }
    }
    
    @ViewBuilder
    var networthChange: some View {
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
                .sorted { $0.payMethod.title < $1.payMethod.title }
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
            Divider()
            
            Divider()
                .padding(.top, 20)
            
            
            if let allDebitStart {
                GridRow {
                    NetWorthChangeView(startingAmount: allDebitStart)
                }
                Divider()
            }
            
            if let allCreditStart {
                GridRow {
                    NetWorthChangeView(startingAmount: allCreditStart)
                }
                Divider()
            }
            
            
            Divider()
                .padding(.top, 20)
            
            ForEach(starts) { star in
                GridRow {
                    NetWorthChangeView(startingAmount: star)
                }
                Divider()
            }
        }
        .font(.caption)
    }
    
    struct NetWorthChangeView: View {
        @Local(\.useWholeNumbers) var useWholeNumbers
        @Environment(DataChangeTriggers.self) var dataChangeTriggers
        @Environment(CalendarModel.self) private var calModel
        
        var startingAmount: CBStartingAmount
        @State private var eom: Double = 0.0
        @State private var change: Double = 0.0
        @State private var percentage: Double = 0.0
        @State private var isBeneficial: Bool = true
        
        var body: some View {
            Group {
                Text(startingAmount.payMethod.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(startingAmount.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                
                Text("\(eom.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                
                Text("\(change.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
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
        @Local(\.useWholeNumbers) var useWholeNumbers
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
                
                Text(startingAmount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                
                Text("\(eom.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                
                Text("\(change.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
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
        
        
//        private func calculateSumForDay(for month: CBMonth, and doWhat: DoWhatWhenCalculating) -> Double {
//            var finalEodTotal: Double = 0.0
//            
//            month.days.forEach { day in
//                let amount = day.transactions
//                    .filter { $0.active }
//                    .filter { $0.factorInCalculations }
//                    .filter { ($0.payMethod?.isPermitted ?? true) }
//                    .filter { !($0.payMethod?.isHidden ?? true) }
//                    .map { ($0.payMethod?.isCreditOrLoan ?? false) ? $0.amount * -1 : $0.amount }
//                    .reduce(0.0, +)
//                            
//                switch doWhat {
//                case .updateEod:
//                    day.eodTotal = amount
//                    
//                case .giveMeLastDayEod:
//                    if day.id == month.days.last?.id {
//                        finalEodTotal = amount
//                    }
//                }
//            }
//            /// This isn't used anywhere
//            return finalEodTotal
//        }
    }
    
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
        //.padding(5)
        //.glassEffect(.regular.interactive(), in: .circle)
        //.glassEffect(.regular.interactive())
    }
    
    var expenseByCategoryHeaderMenu: some View {
        Menu {
            Section {
                Button {
                    breakdownOrChart = "chart"
                } label: {
                    Label("Chart", systemImage: "chart.bar.doc.horizontal")
                }
                
                Button {
                    breakdownOrChart = "breakdown"
                } label: {
                    Label("Breakdown", systemImage: "list.bullet")
                }
            }
            
            Section {
                exportCsvButton
            }
        } label: {
            HStack(spacing: 4) {
                Text("Budget By Category")
                    .foregroundStyle(.gray)
                    .bold()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.gray)
                    .font(.subheadline)
            }
        }
    }
    
    
    
//    var widgetList: some View {
//        Group {
//            VStack(alignment: .leading) {
//                WidgetLabel(title: "Expenses By Category")
//                verticalBarChart
//                    .padding()
//                    .widgetShape()
//            }
//            .swipeActions(allowsFullSwipe: false) {
//                Button("Delete") {
//                    
//                }
//                .tint(.red)
//            }
//            .listRowSeparator(.hidden)
//        
//
//            VStack(alignment: .leading) {
//                WidgetLabel(title: "Expense Overview")
//                pieChart
//                    .padding()
//                    .widgetShape()
//            }
//            .swipeActions(allowsFullSwipe: false) {
//                Button("Delete") {
//                    
//                }
//                .tint(.red)
//            }
//            .listRowSeparator(.hidden)
//        
//
//            VStack(alignment: .leading) {
//                WidgetLabelMenu(
//                    title: "Breakdown",
//                    sections: [
//                        WidgetLabelOptionSection(title: nil, options: [
//                            WidgetLabelOption(content: AnyView(exportCsvButton))
//                        ])
//                    ]
//                )
//                BudgetBreakdownView(wrappedInSection: false, chartData: data, calculateDataFunction: prepareData)
//                    .padding()
//                    .widgetShape()
//            }
//            .swipeActions(allowsFullSwipe: false) {
//                Button("Delete") {
//                    
//                }
//                .tint(.red)
//            }
//            .listRowSeparator(.hidden)
//        }
//        //.onMove(perform: move)
//        
//        
////        @MainActor func move(from source: IndexSet, to destination: Int) {
////            model.selectedWidgets.move(fromOffsets: source, toOffset: destination)
////            for (i, widget) in model.selectedWidgets.enumerated() {
////                model.updateListOrder(key: widget.key!, listOrder: i)
////            }
////        }
//    }
    
    
    
    var widgetGrid: some View {
        Text("Grid")
    }
    
    
    var exportCsvButton: some View {
        // file rows
        let rows = data.map {
            let budget = $0.budget
            let expense = ($0.expenses == 0 ? 0 : $0.expenses * -1)
            let income = ($0.income)
            let overUnder1 = $0.budget + ($0.expenses + $0.income)
            let overUnder2 = abs(overUnder1)
            
            return [$0.category.title, String(budget), String(expense), String(income), String(overUnder2)]
        }
        return ExportCsvButton(fileName: "Breakdown-\(calModel.sMonth.name)-\(calModel.sYear).csv", headers: ["Category", "Budget", "Expenses", "Income", "Variance"], rows: rows)
    }
            
    
    
    var barSection: some View {
        VStack {
            ForEach(relevantData) { item in
                //let expenses = String(item.expensesMinusIncome.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                //let budget = String(item.budget.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                VStack(spacing: 0) {
                    Label {
                        Text(item.category.title)
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: item.category.emoji ?? "circle")
                            .foregroundStyle(item.category.color)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                                                                                    
                    Rectangle()
                        .foregroundStyle(item.category.color)
                        .scaleEffect(x: item.chartPercentage > 100 ? 100 : item.chartPercentage, anchor: .leading)
                        .frame(height: 10)
                }
            }
        }
    }
    
    
    
    var theChart: some View {
        VStack {
            if chartMode == .verticalBar {
                verticalBarChart
                    //.frame(height: 800)
            } else {
                pieChart
            }
        }
    }
    
    
    
    var verticalBarChart: some View {
        VStack {
            Chart {
                ForEach(relevantData) { item in
                    if item.expensesMinusIncome > 0 {
                        BarMark(
                            x: .value("Amount", item.chartPercentage),
                            y: .value("Budget", item.category.title)
                        )
                        .foregroundStyle(getColor(for: item.category, withOpacity: false))
                    }
                    
                    BarMark(
                        x: .value("Amount", 100 - item.chartPercentage),
                        y: .value("Budget", item.category.title)
                    )
                    //.foregroundStyle(getColor(for: item.category, withOpacity: true))
                    .foregroundStyle(.clear)
                    .annotation(position: .top, alignment: .trailing, spacing: 0) {
                        percentageAnnotation(for: item)
                    }
                }
                
                if let selectedData {
                    BarMark(
                        x: .value("Amount", 0),
                        y: .value("Budget", selectedData.category.title)
                    )
                    .foregroundStyle(.clear)
                    .annotation(
                        position: .automatic,
                        alignment: .trailing,
                        spacing: 0,
                        overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
                    ) {
                        barChartAnnotation
                    }
                }
            }
            .chartXAxis {
                AxisMarks(
                    format: Decimal.FormatStyle.Percent.percent.scale(1),
                    values: [0, 25, 50, 75, 100]
                )
            }
            .chartYSelection(value: $rawSelectedData.animation())
            .chartScrollTargetBehavior(.valueAligned(unit: 1))
            .frame(height: CGFloat(relevantData.count) * 30)
        }
    }
    
    
    var barChartAnnotation: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(selectedData!.category.title.capitalized)
                Spacer()
                
                ChartCircleDot(
                    budget: selectedData!.budget,
                    expenses: abs(selectedData!.expenses),
                    color: colorScheme == .dark ? .white : .black,
                    size: 20
                )
                
                Image(systemName: selectedData!.category.emoji ?? "circle")
            }
            .font(.headline)
            
            Divider()
            Text("Budget: \(selectedData!.budget.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                .bold()
            Text("Income: \(selectedData!.income.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                .bold()
            Text("Expenses: \((selectedData!.expenses * -1).currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                .bold()
        }
        .foregroundStyle(.white)
        .padding(12)
        .frame(minWidth: 180)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(selectedData!.category.color)
        )
        .accessibilityHidden(true)
    }
    
    
    
    var pieChart: some View {
        HStack(spacing: 8) {
            Chart {
                ForEach(relevantData) { item in
                    SectorMark(angle: .value("Expenses", abs(item.expenses)), innerRadius: .ratio(0.4), angularInset: 1.0)
                        .cornerRadius(2)
                        .foregroundStyle(item.category.color)
                        .opacity(selectedData == nil ? 1 : (item.category.id == selectedData!.category.id ? 1 : 0.3))
                }
            }
            .frame(width: 150, height: 150)
            
            
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(relevantData) { item in
                        VStack(spacing: 0) {
                            HStack(spacing: 5) {
                                ChartCircleDot(
                                    budget: item.budget,
                                    expenses: item.expenses,
                                    color: item.category.color,
                                    size: 22
                                )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.category.title)
                                        .foregroundStyle(Color.secondary)
                                        .font(.subheadline)
                                    
                                    if item.expenses != 0 {
                                        Text("\(item.expensesMinusIncome.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                                            .foregroundStyle(Color.secondary)
                                            .font(.caption2)
                                    } else {
                                        Text("-")
                                            .foregroundStyle(Color.secondary)
                                            .font(.caption2)
                                    }
                                
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .contentMargins(.bottom, 10, for: .scrollContent)
            .frame(height: 150)
        }
    }
    
    
    @ViewBuilder func percentageAnnotation(for item: ChartData) -> some View {
        Text("\(Int(item.actualPercentage))%")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    
    
    func getColor(for category: CBCategory, withOpacity: Bool) -> Color {
        selectedData == nil
        ? category.color.opacity(withOpacity ? 0.2 : 1)
        : selectedData!.category.id == category.id
        ? category.color.opacity(withOpacity ? 0.2 : 1)
        : .gray.opacity(0.5)
    }
    
    
//    var pieChartOG: some View {
//        VStack(spacing: 8) {
//            Chart {
//                ForEach(data) { item in
//                    SectorMark(angle: .value("Expenses", abs(item.expenses)), innerRadius: .ratio(0.7), angularInset: 2.0)
//                        .foregroundStyle(item.category.color)
//                        .cornerRadius(8)
//                        .opacity(selectedData == nil ? 1 : (item.category.title == selectedData ? 1 : 0.3))
//                }
//            }
//            .chartAngleSelection(value: $selectedAngle.animation())
//            .onChange(of: selectedAngle) { old, new in
//                if let new {
//                    var cum: Double = 0
//                    let _ = data.first {
//                        cum += abs($0.expenses)
//                        if new <= cum {
//                            selectedData = $0.category.title
//                            return true
//                        }
//                        return false
//                    }
//                } else {
//                    selectedData = nil
//                }
//            }
//            .chartBackground { chartProxy in
//                GeometryReader { geometry in
//                    if let anchor = chartProxy.plotFrame {
//                        let frame = geometry[anchor]
//                        
//                        if let selectedData {
//                            let budget = data.filter { $0.category.title == selectedData }.first?.budget
//                            let expenses = data.filter { $0.category.title == selectedData }.first?.expenses
//                            let category = data.filter { $0.category.title == selectedData }.first?.category
//                            
//                            if let budget, let expenses, let category {
//                                Chart {
//                                    if abs(expenses) < abs(budget) {
//                                        SectorMark(
//                                            angle: .value("Budget", abs(budget - abs(expenses))),
//                                            innerRadius: .ratio(0.6),
//                                            outerRadius: .ratio(0.6),
//                                            angularInset: 2.0
//                                        )
//                                        .foregroundStyle(category.color)
//                                        .cornerRadius(8)
//                                        .opacity(0.3)
//                                    }
//                                                                                                            
//                                    
//                                        SectorMark(
//                                            angle: .value("Expenses", abs(expenses)),
//                                            innerRadius: .ratio(0.6),
//                                            outerRadius: .ratio(0.6),
//                                            angularInset: 2.0
//                                        )
//                                        .foregroundStyle(category.color.gradient)
//                                        .cornerRadius(8)
//                                        .opacity(1)
//                                       
//                                    
//                                }
//                                //.frame(width: 200, height: 200)
//                                .position(x: frame.midX, y: frame.midY)
//                                
//                                
//                                
//                                
//                                VStack(alignment: .leading) {
//                                    Text(selectedData.capitalized)
//                                        .font(.headline)
//                                    //Divider()
//                                    Text("Budget: \(budget.currencyWithDecimals(2))")
//                                        .foregroundStyle(Color.secondary)
//                                        .font(.subheadline)
//                                    Text("Expenses: \(abs(expenses).currencyWithDecimals(2))")
//                                        .foregroundStyle(Color.secondary)
//                                        .font(.subheadline)
//                                }
//                                .position(x: frame.midX, y: frame.midY)
//                            }
//                        } else {
//                            let expenses = data.map { abs($0.expenses) }.reduce(0.0, +)
//                            
//                            VStack(alignment: .leading) {
//                                Text("Total Expenses")
//                                    .font(.headline)
//                                
//                                Text("\(abs(expenses).currencyWithDecimals(2))")
//                            }
//                            .position(x: frame.midX, y: frame.midY)
//                        }
//                    }
//                }
//                //.background(Color.red)
//            }
//            
//            ScrollView(.horizontal) {
//                ZStack {
//                    Spacer()
//                        .containerRelativeFrame([.horizontal])
//                        .frame(height: 1)
//                                                
//                    HStack(spacing: 0) {
//                        ForEach(data.filter { $0.expenses < 0 || $0.income > 0 }) { item in
//                            
//                            VStack(spacing: 0) {
//                                
//                                
//                                
//                                HStack(spacing: 5) {
//                                    ChartCircleDot(
//                                        budget: item.budget,
//                                        expenses: item.expenses,
//                                        color: item.category.color,
//                                        size: 22
//                                    )
//                                    
//                                    
////                                    Circle()
////                                        .fill(item.category.color)
////                                        .frame(maxWidth: 12, maxHeight: 12) // 8 seems to be the default from charts
////                                        .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                                    
//                                    VStack(alignment: .leading, spacing: 2) {
//                                        Text(item.category.title)
//                                            .foregroundStyle(Color.secondary)
//                                            .font(.subheadline)
//                                            //.alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                                        
//                                        let expenses = data.filter { $0.category.title == item.category.title }.first?.expenses
//                                        if let expenses {
//                                            if expenses != 0 {
//                                                Text("\(abs(expenses).currencyWithDecimals(2))")
//                                                    .foregroundStyle(Color.secondary)
//                                                    .font(.caption2)
//                                            } else {
//                                                Text("-")
//                                                    .foregroundStyle(Color.secondary)
//                                                    .font(.caption2)
//                                            }
//                                        }
//                                    }
//                                }
//                                .padding(.horizontal, 4)
//                                .contentShape(Rectangle())
//    //                            #if os(macOS)
//    //                            .onContinuousHover { phase in
//    //                                switch phase {
//    //                                case .active:
//    //                                    selectedData = item.category.title
//    //                                case .ended:
//    //                                    selectedData = nil
//    //                                }
//    //                            }
//    //                            #endif
//                                
//                            }
//                            .frame(maxWidth: .infinity)
//                        }
//                    }
//                }
//            }
//            .scrollBounceBehavior(.basedOnSize)
//            .contentMargins(.bottom, 10, for: .scrollContent)
//        }
//    }
//    
//    
//    
    func prepareData() {
        data = calModel.sMonth.budgets
            /// Category is not nil.
            .filter { $0.category != nil }
            /// Category is not income.
            .filter { !$0.category!.isIncome }
            /// Standard category sort.
            .sorted(by: Helpers.budgetSorter())
            .enumerated()
            .compactMap { (index, budget) in
                if let cat = budget.category {
                    let transactions = calModel.getTransactions(cats: [cat])
                    return calModel.createChartData(
                        transactions: transactions,
                        cat: cat,
                        budgets: [budget]
                    )
                } else {
                    return nil
                }
        }
    }
}

struct ChartPercentage {
    var actual: Double
    var chart: Double
    var expensesMinusIncome: Double
}
