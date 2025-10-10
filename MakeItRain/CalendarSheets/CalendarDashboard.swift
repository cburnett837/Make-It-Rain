//
//  BudgetTable.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/6/24.
//

import SwiftUI
import Charts

struct ChartData: Identifiable {
    var id: String { return category.id }
    let category: CBCategory
    var budget: Double
    var income: Double
    var incomeMinusPayments: Double
    var expenses: Double
    var expensesMinusIncome: Double
    var chartPercentage: Double
    var actualPercentage: Double
    var budgetObject: CBBudget?
}

//struct ChartDataPoint: Identifiable {
//    let id = UUID().uuidString
//    let title: String
//    let amount: Double
//}

struct CalendarDashboard: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Local(\.colorTheme) var colorTheme
    @AppStorage("calendarChartMode") var chartMode = CalendarChartModel.verticalBar
    @AppStorage("viewMode") var viewMode = CalendarViewMode.scrollable
    @Local(\.useWholeNumbers) var useWholeNumbers
    @AppStorage("categorySortMode") var categorySortMode: CategorySortMode = .title
    
    
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
                Section {
                    if breakdownOrChart == "chart" {
                        verticalBarChart
                    } else {
                        BudgetBreakdownView(wrappedInSection: false, chartData: data, calculateDataFunction: createData)
                    }
                } header: {
                    expenseByCategoryHeaderMenu
                }
                .textCase(nil)
                
                Section("Spending Overview") {
                    pieChart
                }
                
                Section("Net Worth Change") {
                    networthChange
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
        .task { createData() }
        /// Recalculate the analysis data when the month or year changes.
        .onChange(of: DataChangeTriggers.shared.calendarDidChange) {
            print("🤞🏻 CalendarDashboard.body: Received recalc trigger")
            createData()
//            Task {
//                try? await Task.sleep(nanoseconds: UInt64(0.3 * Double(NSEC_PER_SEC)))
//                createData()
//            }
        }
    }
    
    @ViewBuilder
    var networthChange: some View {
        
        var starts: Array<CBStartingAmount> {
            calModel.sMonth.startingAmounts
                .filter { $0.payMethod.isAllowedToBeViewedByThisUser && !$0.payMethod.isHidden }
        }
        Grid(alignment: .leading) {
            GridRow {
                Text("Pay Meth")
                Text("Start")
                Text("End")
                Text("Dif")
                Text("Percent")
            }
            Divider()
            ForEach(starts) { star in
                GridRow {
                    NetWorthChangeView(startingAmount: star)
                        //.frame(maxWidth: .infinity, alignment: .leading)
                        //.fixedSize(horizontal: false, vertical: true)
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
        
        var body: some View {
            Group {
                Text(startingAmount.payMethod.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(startingAmount.amountString)
                
                Text("\(eom.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                
                Text("\(change.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                    .foregroundStyle(change < 0 ? Color.red : Color.green)
                
                Text("\(percentage.decimals(1))%")
                    .foregroundStyle(percentage < 0 ? Color.red : Color.green)
            }
            .task {
                calculate()
            }
            /// Recalculate when transaction amounts change.
//            .onChange(of: calModel.sMonth.justTransactions.map{ $0.amount }) {
//                /// Put a slight delay so the app has time to switch all the transactions to the new month.
//                Task {
//                    try? await Task.sleep(nanoseconds: UInt64(0.3 * Double(NSEC_PER_SEC)))
//                    calculate()
//                }
//            }
//            .onChange(of: calModel.sMonth.justTransactions.map{ $0.factorInCalculations }) {
//                /// Put a slight delay so the app has time to switch all the transactions to the new month.
//                Task {
//                    try? await Task.sleep(nanoseconds: UInt64(0.3 * Double(NSEC_PER_SEC)))
//                    calculate()
//                }
//            }
            .onChange(of: DataChangeTriggers.shared.calendarDidChange) { oldValue, newValue in
//                print("🤞🏻 NetWorthChangeView.body: Received recalc trigger newValue: \(newValue), oldValue: \(oldValue)")
//                if newValue != oldValue {
//                    print("NetWorthChangeView.body: will recalc")
//                    calculate()
//                }
                
                calculate()
            }
        }
        
        func calculate() {
            eom = calModel.calculateTotal(for: calModel.sMonth, using: startingAmount.payMethod, and: .giveMeLastDayEod)
            change = eom - startingAmount.amount
            percentage = Helpers.netWorthPercentageChange(start: startingAmount.amount, end: eom)
        }
    }
    
    
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "checkmark")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }
    
    var expenseByCategoryHeaderMenu: some View {
        Menu {
            Section {
                Button {
                    breakdownOrChart = "chart"
                } label: {
                    Label {
                        Text("Chart")
                    } icon: {
                        Image(systemName: "chart.bar.doc.horizontal")
                    }
                }
                
                Button {
                    breakdownOrChart = "breakdown"
                } label: {
                    Label {
                        Text("Breakdown")
                    } icon: {
                        Image(systemName: "list.bullet")
                    }
                }
            }
            
            Section {
                exportCsvButton
            }
        } label: {
            HStack(spacing: 4) {
                Text("Budget By Category")
                    .textCase(.uppercase)
                    
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(.gray)
            .font(.footnote)
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
//                BudgetBreakdownView(wrappedInSection: false, chartData: data, calculateDataFunction: createData)
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
    func createData() {
        data = calModel.sMonth.budgets
            /// Category is not nil.
            .filter{ $0.category != nil }
            /// Category is not income.
            .filter{ !$0.category!.isIncome }
            /// Standard category sort.
            .sorted {
                categorySortMode == .title
                ? ($0.category!.title).lowercased() < ($1.category!.title).lowercased()
                : $0.category!.listOrder ?? 1000000000 < $1.category!.listOrder ?? 1000000000
            }
            .enumerated()
            .map { (index, budget) in
                /// Get the expenses associated with the category from the calModel.
                let expenses = calModel.sMonth.justTransactions
                    .filter { ($0.payMethod?.isAllowedToBeViewedByThisUser ?? true) && ($0.payMethod?.isHidden ?? false) == false }
                    //.filter { $0.isBudgetable && $0.isExpense && $0.factorInCalculations }
                    .filter { $0.isExpense && $0.factorInCalculations }
                    .filter { $0.category?.id == budget.category?.id }
                    //.map { $0.amount }
                    .map { ($0.payMethod?.isCreditOrLoan ?? false) ? $0.amount * -1 : $0.amount }
                    .reduce(0.0, +)
                                                           
                /// Get the income associated with the category from the calModel.
                /// (Like if Laura sends me money for drinks).
                let income = calModel.sMonth.justTransactions
                    .filter { ($0.payMethod?.isAllowedToBeViewedByThisUser ?? true) && ($0.payMethod?.isHidden ?? false) == false }
//                    .filter { $0.isBudgetable && $0.isIncome && $0.factorInCalculations }
                    .filter { $0.isIncome && $0.factorInCalculations }
                    .filter { $0.category?.id == budget.category?.id }
                    //.map { $0.amount }
                    .map { ($0.payMethod?.isCreditOrLoan ?? false) ? $0.amount * -1 : $0.amount }
                    .reduce(0.0, +)
                
                
                let incomeMinusPayments = calModel.sMonth.justTransactions
                    .filter ({
                        ($0.payMethod?.isAllowedToBeViewedByThisUser ?? true)
                        && ($0.payMethod?.isHidden ?? false) == false
                        && $0.isIncome
                        && $0.factorInCalculations
                        && $0.category?.id == budget.category?.id
                    })
//                    .filter { $0.isBudgetable && $0.isIncome && $0.factorInCalculations }
                    //.filter ({ $0.isIncome && $0.factorInCalculations && $0.category?.id == budget.category?.id })
                    /// Ignore transactions that are the beneficiaries of payments.
                    .filter { trans in
                        if trans.relatedTransactionID != nil {
                            if calModel.sMonth.justTransactions.filter ({ $0.id == trans.relatedTransactionID! }).first != nil {
                                if trans.isPaymentOrigin {
                                    return false
                                }
                            }
                        }
                        return true
                    }
                    .map { ($0.payMethod?.isCreditOrLoan ?? false) ? $0.amount * -1 : $0.amount }
                    .reduce(0.0, +)
                
                
                var chartPer = 0.0
                var actualPer = 0.0
                let expensesMinusIncome = (expenses + income) * -1
                
                if budget.amount == 0 {
                    actualPer = expensesMinusIncome
                } else {
                    actualPer = (expensesMinusIncome / budget.amount) * 100
                }
                                                
                if actualPer > 100 {
                    chartPer = 100
                } else if actualPer < 0 {
                    chartPer = 0
                } else {
                    chartPer = actualPer
                }
                
                return ChartData(
                    category: budget.category!,
                    budget: budget.amount,
                    income: income,
                    incomeMinusPayments: incomeMinusPayments,
                    expenses: expenses,
                    expensesMinusIncome: expensesMinusIncome,
                    chartPercentage: chartPer,
                    actualPercentage: actualPer,
                    budgetObject: budget
                )
        }
    }
}
