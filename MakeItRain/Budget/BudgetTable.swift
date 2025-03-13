//
//  BudgetTable.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/6/24.
//

import SwiftUI
import Charts

struct ChartData: Identifiable {
    let id = UUID().uuidString
    let category: CBCategory
    var budget: Double
    var income: Double
    var expenses: Double
    let overlayPosition: AnnotationPosition
}

//struct ChartDataPoint: Identifiable {
//    let id = UUID().uuidString
//    let title: String
//    let amount: Double
//}

struct BudgetTable: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
    @AppStorage("calendarChartMode") var chartMode = CalendarChartModel.verticalBar
    @AppStorage("viewMode") var viewMode = CalendarViewMode.scrollable
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    @AppStorage("categorySortMode") var categorySortMode: CategorySortMode = .title
    
    @Environment(CalendarModel.self) private var calModel
    @Environment(CategoryModel.self) private var catModel
    
    @State private var deleteBudget: CBBudget?
    @State private var editBudget: CBBudget?
    @State private var budgetEditID: CBBudget.ID?
    
    @State private var selectedBudget: String?
    @State private var selectedAngle: Double?
    
    @Binding var maxHeaderHeight: CGFloat
    
    enum WhichView {
        case chart, list
    }
    
    @State private var whichView: WhichView = .chart
    
    var budgetCount: Int { calModel.sMonth.budgets.count }
    
    @State private var categoryBudget: [ChartData] = []
    
        
    var body: some View {
        #if os(iOS)
        SheetHeader(title: "\(calModel.sMonth.name) \( String(calModel.sMonth.year))", close: { dismiss() })
        #endif
        
        if calModel.sMonth.budgets.isEmpty {
            
            #if os(macOS)
            ContentUnavailableView {
                Label {
                    Text("No Budget")
                } icon: {
                    Image(systemName: "square.stack.3d.up.slash.fill")
                }
            } description: {
                HStack(spacing: 0) {
                    Text("Use the ")
                    Image(systemName: "arrow.triangle.branch")
                        .rotationEffect(Angle(degrees: 180))
                        .font(.title3)
                    Text(" button above to create a budget for this month.")
                }
            }
            .frame(maxWidth: .infinity)
            #else
            ContentUnavailableView {
                Label {
                    Text("No Budget")
                } icon: {
                    Image(systemName: "square.stack.3d.up.slash.fill")
                }
            } description: {
                Text("Click below to create.")
            }
            .frame(maxWidth: .infinity)
            
            Button("Create Budget") {
                let model = PopulateOptions()
                model.budget = true
                calModel.populate(options: model, repTransactions: [], categories: catModel.categories)
            }
            
            .padding(.bottom, 6)
            #if os(macOS)
            .foregroundStyle(Color.fromName(appColorTheme))
            .buttonStyle(.codyStandardWithHover)
            #else
            .tint(Color.fromName(appColorTheme))
            .buttonStyle(.borderedProminent)
            #endif
            
            
            #endif

            
            //ContentUnavailableView("No Budget", systemImage: "square.stack.3d.up.slash.fill", description: Text("Use the populate button above to create a budget for this month."))
        } else {
            GeometryReader { geo in
                if viewMode == CalendarViewMode.split {
                    VStack {
                        #if os(macOS)
                        TheTable(geo: geo, budgetEditID: $budgetEditID, selectedBudget: $selectedBudget, maxHeaderHeight: maxHeaderHeight)
                        #else
                        TheList(geo: geo, budgetEditID: $budgetEditID, selectedBudget: $selectedBudget, maxHeaderHeight: maxHeaderHeight)
                        #endif
                        
                        theChart
                    }
                    //.background{Color.red}
                    
                } else {
                    #if os(iOS)
                    VStack {
                        HStack {
                            Picker("", selection: $whichView) {
                                Text("Chart")
                                    .tag(WhichView.chart)
                                Text("List")
                                    .tag(WhichView.list)
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                            
                            
                            Picker(selection: $chartMode) {
                                Image(systemName: "chart.bar.fill")
                                    .tag(CalendarChartModel.verticalBar)
                                Image(systemName: "chart.pie.fill")
                                    .tag(CalendarChartModel.pie)
                            } label: {
                                EmptyView()
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            .frame(maxWidth: 100)
                            .padding(.leading, 8)
                            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                            .disabled(whichView == .list)
                        }
                        
                        
                        
                        
                        
                        if whichView == .chart {
                            theChart
                        } else {
                            TheList(geo: geo, budgetEditID: $budgetEditID, selectedBudget: $selectedBudget, maxHeaderHeight: maxHeaderHeight)
                        }
                    }
                    
                    
                    #else
                    HStack {
                        theChart
                        TheTable(geo: geo, budgetEditID: $budgetEditID, selectedBudget: $selectedBudget, maxHeaderHeight: maxHeaderHeight)
                    }
                    #endif
                    
                }
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
            .task {
                categoryBudget = calModel.sMonth.budgets
                    .filter{ $0.category != nil }
                    .filter{ !$0.category!.isIncome }
                    .sorted {
                        categorySortMode == .title
                        ? ($0.category!.title).lowercased() < ($1.category!.title).lowercased()
                        : $0.category!.listOrder ?? 1000000000 < $1.category!.listOrder ?? 1000000000
                    }
                    .enumerated()
                    .map { (index, budget) in
                        let expenses = calModel.sMonth.justTransactions
                            .filter { $0.isBudgetable && $0.isExpense && $0.factorInCalculations }
                            .filter { $0.category?.id == budget.category?.id }
                            .map { $0.amount }
                            .reduce(0.0, +)
                                                                                                
                        let income = calModel.sMonth.justTransactions
                            .filter { $0.isBudgetable && $0.isIncome && $0.factorInCalculations }
                            .filter { $0.category?.id == budget.category?.id }
                            .map { $0.amount }
                            .reduce(0.0, +)
                        
                                                
            //            let budge = ChartDataPoint(title: "Budget", amount: budget.amount)
            //            let expenses = ChartDataPoint(title: "Expenses", amount: expenseAmount - reimbursementAmount)
            //
                        return ChartData(
                            category: budget.category!,
                            budget: budget.amount,
                            income: income,
                            expenses: expenses,
                            overlayPosition: index >= budgetCount / 2 ? .leading : .trailing
                        )
                }
            }
        }
    }
    
    
    struct TableHeader: View {
        @AppStorage("threshold") var threshold = "500.0"
        @AppStorage("useWholeNumbers") var useWholeNumbers = false
        @Environment(CalendarModel.self) private var calModel
        
        var maxHeaderHeight: CGFloat
        
        var income: Double {
            calModel.sMonth.startingAmounts
                .filter { $0.payMethod.accountType == .cash || $0.payMethod.accountType == .checking }
                .map { $0.amount }
                .reduce(0.0, +)
            +
            calModel.sMonth.justTransactions
                .filter { $0.isBudgetable && $0.isIncome && $0.factorInCalculations }
                .map { $0.amount }
                .reduce(0.0, +)
        }
        
        var expenses: Double {
            calModel.sMonth.justTransactions
                .filter { $0.isBudgetable && $0.isExpense && $0.factorInCalculations}
                .map { $0.amount }
                .reduce(0.0, +)
        }
                
        var remainingFundsTotal: Color {
            if (income - expenses) > Double(threshold) ?? 500 {
                return .gray
            } else if (income - expenses) < 0 {
                return .red
            } else {
                return .orange
            }
        }
        
        
        
        var body: some View {
            VStack(spacing: 0) {
                #if os(macOS)
                if !AppState.shared.isInFullScreen {
                    Divider()
                }
                #endif
                Spacer()
                    .frame(minHeight: 1)

                HStack(alignment: .center) {
                    Text("Income: \(income.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                        //.padding(.leading, 16)
                                                                                    
                    Text("Expenses: \(abs(expenses).currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                        .padding(.leading, 16)
                    
                    (
                        Text("Available Funds: ")
                        +
                        Text((income - abs(expenses)).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                        .foregroundStyle(remainingFundsTotal)
                    )
                    .padding(.leading, 16)
                    
                    Spacer()
                }
                //.padding(.bottom, 5)
                //.padding(.top, AppState.shared.isInFullScreen ? 10 : 0)
                
                Spacer()
                    .frame(minHeight: 1) /// This has to be here to fix the stupid 1 pixel issue matching with the weekday headers.
                                         /// It seems that this view with spacers is actually bigger than the weekday view, but trying to give it the weekday view height fucks it up.
                Divider()
            }
            .frame(height: maxHeaderHeight)
            //.frame(height: 100)
            //.background { Color.blue.opacity(0.5) }
        }
        
    }
    
    
    struct TheTable: View {
        @AppStorage("viewMode") var viewMode = CalendarViewMode.scrollable
        @AppStorage("useWholeNumbers") var useWholeNumbers = false
        @AppStorage("threshold") var threshold = "500.0"
        @Environment(CalendarModel.self) private var calModel
        
        var geo: GeometryProxy
        @Binding var budgetEditID: CBBudget.ID?
        @Binding var selectedBudget: String?
        
        var maxHeaderHeight: CGFloat
        
        //@State private var sortOrder = [KeyPathComparator(\CBBudget.category?.title)]
        @State private var labelWidth: CGFloat = 20.0
        
                        
        var body: some View {
            VStack(spacing: 0) {
                TableHeader(maxHeaderHeight: maxHeaderHeight)
                    .if(viewMode == .split) {
                        $0.padding(.bottom, 7)
                    }
                Table(of: CBBudget.self, selection: $budgetEditID/*, sortOrder: $sortOrder*/) {
                    TableColumn("Category") { budget in
                        HStack(spacing: 4) {
                            if let emoji = budget.category?.emoji {
                                Image(systemName: emoji)
                                    .foregroundStyle(budget.category?.color ?? .primary)
                                    .frame(minWidth: labelWidth, alignment: .center)
                            } else {
                                Circle()
                                    .fill(budget.category?.color ?? .primary)
                                    .frame(width: 12, height: 12)
                            }
                                                        
                            Text(budget.category?.title ?? "-")
                        }
                    }
                    
                    TableColumn("Budget") { budget in
                        Text(budget.amountString)
                    }
                                
                    TableColumn("Expenses") { budget in
                        let expenses = calModel.sMonth.justTransactions
                            .filter { $0.isBudgetable && $0.isExpense && $0.factorInCalculations }
                            .filter { $0.category?.id == budget.category?.id }
                            .map { $0.amount }
                            .reduce(0.0, +)
                                                                
                        Text(abs(expenses).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                    }
                    
                    TableColumn("Income") { budget in
                        let income = calModel.sMonth.justTransactions
                            .filter { $0.isBudgetable && $0.isIncome && $0.factorInCalculations }
                            .filter { $0.category?.id == budget.category?.id }
                            .map { $0.amount }
                            .reduce(0.0, +)
                                                                
                        Text(abs(income).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                    }
                    
                    
                    TableColumn("Over/Under") { budget in
                        let expenses = calModel.sMonth.justTransactions
                            .filter { $0.isBudgetable && $0.isExpense && $0.factorInCalculations }
                            .filter { $0.category?.id == budget.category?.id }
                            .map { $0.amount }
                            .reduce(0.0, +)
                                                                                                
                        let income = calModel.sMonth.justTransactions
                            .filter { $0.isBudgetable && $0.isIncome && $0.factorInCalculations }
                            .filter { $0.category?.id == budget.category?.id }
                            .map { $0.amount }
                            .reduce(0.0, +)
                                                
                        let overUnder = budget.amount + (expenses + income)
                        
                        Text(abs(overUnder).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                            .foregroundStyle(overUnder < 0 ? .red : (overUnder > budget.amount ? .green : .primary) )
                    }
                } rows: {
                    ForEach(calModel.sMonth.budgets) { budget in
                        TableRow(budget)
                            #if os(macOS)
                            .onHover {
                                selectedBudget = $0 ? budget.category?.title : nil
                            }
                            #endif
                    }
                }
                //.tableStyle(.bordered)
                .clipped()
//                .onChange(of: sortOrder) { _, sortOrder in
//                    calModel.sMonth.budgets.sort(using: sortOrder)
//                }
                /// Do this to align the top of the table with the top of the day views.
//                .if(viewMode == .split) {
//                    $0.padding(.top, 6)
//                }
            }
            .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
            
        }
    }
    
    #if os(iOS)
    struct TheList: View {
        @AppStorage("viewMode") var viewMode = CalendarViewMode.scrollable
        @AppStorage("useWholeNumbers") var useWholeNumbers = false
        @AppStorage("threshold") var threshold = "500.0"
        @Environment(CalendarModel.self) private var calModel
        
        var geo: GeometryProxy
        @Binding var budgetEditID: CBBudget.ID?
        @Binding var selectedBudget: String?
        
        var maxHeaderHeight: CGFloat
        
        @State private var labelWidth: CGFloat = 20.0
        
        var remainingFundsTotal: Color {
            let income = calModel.sMonth.startingAmounts
                .filter { $0.payMethod.accountType != .credit && !$0.payMethod.isUnified }
                .map { $0.amount }
                .reduce(0.0, +)
                +
            
                calModel.sMonth.justTransactions
                    .filter { $0.payMethod?.accountType != .credit && $0.amount > 0 }
                    .map { $0.amount }
                    .reduce(0.0, +)
            
            let expenses = calModel.sMonth.justTransactions
                .filter { $0.payMethod?.accountType != .credit && $0.amount < 0 }
                .map { $0.amount }
                .reduce(0.0, +)
            
            
            if (income - abs(expenses)) > Double(threshold) ?? 500 {
                return .gray
            } else if (income - abs(expenses)) < 0 {
                return .red
            } else {
                return .orange
            }
        }
        
        var income: Double {
            let start = calModel.sMonth.startingAmounts
                .filter { $0.payMethod.accountType != .credit && !$0.payMethod.isUnified }
                .map { $0.amount }
                .reduce(0.0, +)
            
            let trans = calModel.sMonth.justTransactions
                .filter { $0.isBudgetable && ($0.category ?? CBCategory()).isIncome }
                .map { $0.amount }
                .reduce(0.0, +)
            
            
            //print("start: \(start), trans: \(trans), income: \(start + trans)")
            
            return start + trans
        }
        
        var expenses: Double {
            calModel.sMonth.justTransactions
                .filter { $0.payMethod?.accountType != .credit && $0.amount < 0 }
                .compactMap { $0.amount }
                .reduce(0.0, +)
        }
        
        
        let columnGrid = Array(repeating: GridItem(.flexible(), spacing: 0), count: 4)
        
        
        var body: some View {
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Income")
                        Text(income.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Expenses")
                        Text(abs(expenses).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Available Funds")
                        Text((income - abs(expenses)).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                            .foregroundStyle(remainingFundsTotal)
                    }
                    Spacer()
                }
                
                Divider()
                
                LazyVGrid(columns: columnGrid, alignment: .leading, spacing: 10) {
                    Text("Category")
                    Text("Budget")
                    Text("Expenses")
                    Text("Over/Under")
                }
                .font(.caption2)
                
                
                List(calModel.sMonth.budgets, selection: $budgetEditID) { budget in
                    LazyVGrid(columns: columnGrid, alignment: .leading, spacing: 10) {
                        HStack(alignment: .circleAndTitle, spacing: 5) {
                            let expenses = calModel.sMonth.justTransactions
                                .filter { $0.isBudgetable && $0.isExpense && $0.factorInCalculations }
                                .filter { $0.category?.id == budget.category?.id }
                                .map { $0.amount }
                                .reduce(0.0, +)
                            
                            
                            
                            ChartCircleDot(
                                budget: budget.amount,
                                expenses: abs(expenses),
                                color: budget.category?.color ?? .white,
                                size: 12
                            )
                            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                            
                            
//                            Circle()
//                                .fill(budget.category?.color ?? .primary)
//                                .frame(width: 12, height: 12)
//                                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                            
                            
                            Text(budget.category?.title ?? "-")
                                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                        }
                        
                        
                        let expenses = calModel.sMonth.justTransactions
                            .filter { $0.isBudgetable && $0.isExpense && $0.factorInCalculations }
                            .filter { $0.category?.id == budget.category?.id }
                            .map { $0.amount }
                            .reduce(0.0, +)
                        
                        let income = calModel.sMonth.justTransactions
                            .filter { $0.isBudgetable && $0.isIncome && $0.factorInCalculations }
                            .filter { $0.category?.id == budget.category?.id }
                            .map { $0.amount }
                            .reduce(0.0, +)
                        
                        
                        Text(budget.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                        Text(abs(expenses).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                        
                        let overUnder = budget.amount + (expenses + income)
                        
                        Text(abs(overUnder).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                            .foregroundStyle(overUnder < 0 ? .red : (overUnder > budget.amount ? .green : .primary) )
                    }
                    .font(.caption2)
                    .listRowInsets(EdgeInsets())
                    
                    
                    
                    
                    
                    
//                    HStack(alignment: .circleAndTitle, spacing: 4) {
//                        
//                        if let emoji = budget.category?.emoji {
//                            Image(systemName: emoji)
//                                .foregroundStyle(budget.category?.color ?? .primary)
//                                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                                .frame(minWidth: labelWidth, alignment: .center)
//                                .maxViewWidthObserver()
//                        } else {
//                            Circle()
//                                .fill(budget.category?.color ?? .primary)
//                                .frame(width: 12, height: 12)
//                                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                        }
//                        
////                        Circle()
////                            .fill(budget.category?.color ?? .primary)
////                            .frame(width: 12, height: 12)
////                            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                        
//                        VStack(alignment: .leading) {
//                            HStack {
//                                Text(budget.category?.title ?? "-")
//                                Spacer()
//                            }
//                            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                                                    
//                            HStack {
//                                Text("Budget:")
//                                Spacer()
//                                Text(budget.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                            }
//                            .foregroundStyle(.gray)
//                            .font(.caption)
//                        
//                        
//                            HStack {
//                                Text("Expenses:")
//                                Spacer()
//                                let expenses = calModel.sMonth.justTransactions
//                                    .filter { $0.isBudgetable && $0.isExpense && $0.factorInCalculations }
//                                    .filter { $0.category?.id == budget.category?.id }
//                                    .map { $0.amount }
//                                    .reduce(0.0, +)
//                                
//                                Text(abs(expenses).currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                            }
//                            .foregroundStyle(.gray)
//                            .font(.caption)
//                            
//                            
//                            HStack {
//                                Text("Income:")
//                                Spacer()
//                                let income = calModel.sMonth.justTransactions
//                                    .filter { $0.isBudgetable && $0.isIncome && $0.factorInCalculations }
//                                    .filter { $0.category?.id == budget.category?.id }
//                                    .map { $0.amount }
//                                    .reduce(0.0, +)
//                                
//                                Text(abs(income).currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                            }
//                            .foregroundStyle(.gray)
//                            .font(.caption)
//                            
//                            
//                            
//                            HStack {
//                                Text("Over/Under:")
//                                Spacer()
//                                let expenses = calModel.sMonth.justTransactions
//                                    .filter { $0.isBudgetable && $0.isExpense && $0.factorInCalculations }
//                                    .filter { $0.category?.id == budget.category?.id }
//                                    .map { $0.amount }
//                                    .reduce(0.0, +)
//                                                                                                        
//                                let income = calModel.sMonth.justTransactions
//                                    .filter { $0.isBudgetable && $0.isIncome && $0.factorInCalculations }
//                                    .filter { $0.category?.id == budget.category?.id }
//                                    .map { $0.amount }
//                                    .reduce(0.0, +)
//                                
//                                let overUnder = budget.amount + (expenses + income)
//                                
//                                Text(abs(overUnder).currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                                    .foregroundStyle(overUnder < 0 ? .red : (overUnder > budget.amount ? .green : .primary) )
//                            }
//                            .foregroundStyle(.gray)
//                            .font(.caption)
//                        }
//                    }
//                    .rowBackgroundWithSelection(id: budget.id, selectedID: budgetEditID)
                }
                .listStyle(.plain)
                
            }
            //.padding(.horizontal, 20)
            .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        }
    }
    #endif
    
    
    var theChart: some View {
        VStack {
            Divider()
            
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
                ForEach(categoryBudget.filter { $0.expenses < 0 || $0.income > 0 }) { item in
//                    BarMark(
//                        x: .value("Budget", item.category.title),
//                        y: .value("Amount", (item.expenses + item.income) * -1), // Flip the symbols
//                        width: .ratio(0.6)
//                    )
//                    .foregroundStyle(item.category.color)
//                    .clipShape(RoundedRectangle(cornerRadius: 8))
//                    
//                    RectangleMark(
//                        x: .value("Budget", item.category.title),
//                        y: .value("Amount", item.budget),
//                        width: .ratio(0.6),
//                        height: 4
//                    )
//                    .foregroundStyle(.gray)
//                    .clipShape(RoundedRectangle(cornerRadius: 8))
//
                    let budgetBarAmount = item.budget - ((item.expenses + item.income) * -1) < 0 ? 0 : item.budget - ((item.expenses + item.income) * -1)
                    
                    
                    if ((item.expenses + item.income) * -1) > 0 {
                        BarMark(
                            x: .value("Amount", (item.expenses + item.income) * -1),
                            y: .value("Budget", item.category.title)
                            //width: .ratio(0.6)
                        )
                        
                        .foregroundStyle(
                            selectedBudget == nil
                            ? item.category.color
                            : selectedBudget == item.category.title ? item.category.color : .gray.opacity(0.5)
                        )
                        //.cornerRadius(5)
                        //.clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    BarMark(
                        x: .value("Amount", budgetBarAmount),
                        y: .value("Budget", item.category.title)
                        //width: .ratio(0.6)
                    )
                    .foregroundStyle(
                        selectedBudget == nil
                        ? item.category.color.opacity(0.5)
                        : selectedBudget == item.category.title ? item.category.color.opacity(0.5) : .gray.opacity(0.5)
                    )
                 
                }
                
                if let selectedBudget {
                    let position = categoryBudget.filter { $0.category.title == selectedBudget }.first?.overlayPosition
                    let budget = categoryBudget.filter { $0.category.title == selectedBudget }.first?.budget
                    let expenses = categoryBudget.filter { $0.category.title == selectedBudget }.first?.expenses
                    let income = categoryBudget.filter { $0.category.title == selectedBudget }.first?.income
                    let category = categoryBudget.filter { $0.category.title == selectedBudget }.first?.category
                    
                    if let position, let budget, let expenses, let category, let income {
                        
                        //let expenseAmount = (expenses + income) * -1
                        //let budgetBarAmount = budget - ((expenses + income) * -1) < 0 ? 0 : budget - ((expenses + income) * -1)
                        
                        BarMark(
                            x: .value("Amount", 20),
                            y: .value("Budget", selectedBudget), height: .ratio(1)
                        )
                        .foregroundStyle(.clear)
                        .annotation(
                            position: .trailing,
                            alignment: .leading,
                            spacing: 0,
                            overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
                        ) {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(selectedBudget.capitalized)
                                    Spacer()
                                    Image(systemName: category.emoji ?? "circle")
                                    
                                    
//                                    Chart {
//                                        if abs(expenses) < abs(budget) {
//                                            SectorMark(angle: .value("Budget", abs(budget - abs(expenses))))
//                                                .foregroundStyle(category.color)
//                                                .cornerRadius(8)
//                                                .opacity(0.3)
//                                        }
//                                        SectorMark(angle: .value("Expenses", abs(expenses)))
//                                            .foregroundStyle(category.color.gradient)
//                                            .cornerRadius(8)
//                                            .opacity(1)
//                                    }
//                                    .frame(width: 22, height: 22)
                                    
                                    
                                    
                                    
                                }
                                .font(.headline)
                                
                                Divider()
                                Text("Budget: \(budget.currencyWithDecimals(2))")
                                    .bold()
                                Text("Expenses: \((expenses * -1).currencyWithDecimals(2))")
                                    .bold()
                            }
                            //.padding()
                            //.background(Color.annotationBackground)
                            
                            .foregroundStyle(.white)
                            .padding(12)
                            .frame(width: 180)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    //.fill(Color.annotationBackground)
                                    .fill(category.color)
                                    //.fill(category.color.shadow(.drop(color: .black, radius: 10))/*.gradient*/)
                            )
                        }
                        .accessibilityHidden(true)
                    }
                }
            }
//            #if os(macOS)
//            .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 20)) }
//            #else
//            .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 10)) }
//            #endif
            .chartYSelection(value: $selectedBudget.animation())
            //.chartScrollableAxes(.horizontal)
            .chartScrollTargetBehavior(.valueAligned(unit: 1))
            //.chartXVisibleDomain(length: 5)
            
            HStack {
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.6))
                        .frame(maxWidth: 12, maxHeight: 4) // 8 seems to be the default from charts
                    Text("Budget")
                        .foregroundStyle(Color.secondary)
                        .font(.subheadline)
                }
                
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 2)
                        //.fill(Color.gray)
                        .fill(AngularGradient(gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red]), center: .center))
                        .frame(maxWidth: 12, maxHeight: 12) // 8 seems to be the default from charts
                    Text("Expenses")
                        .foregroundStyle(Color.secondary)
                        .font(.subheadline)
                }
                Spacer()
            }
        }
    }
    
//    var verticalBarChart1: some View {
//        Chart {
//            ForEach(categoryBudget) { item in
//                ForEach(item.data) { metric in
//                    BarMark(
//                        x: .value("Budget", item.category.title),
//                        y: .value("Amount", abs(metric.amount)),
//                        width: metric.title == "Budget" ? .ratio(0.7) : .ratio(0.6),
//                        stacking: .unstacked
//                    )
//                    .foregroundStyle(item.category.color.opacity(metric.title == "Budget" ? 0.8 : 1))
//                    
//                    //.foregroundStyle(by: .value("Category", metric.title))
//                    //.position(by: .value("Category", metric.title))
//                }
//            }
//            
//            if let selectedBudget {
//                let position = categoryBudget.filter { $0.category.title == selectedBudget }.first?.overlayPosition
//                let budget = categoryBudget.filter { $0.category.title == selectedBudget }.first?.data[0].amount
//                let expenses = categoryBudget.filter { $0.category.title == selectedBudget }.first?.data[1].amount
//                
//                if let position, let budget, let expenses {
//                    RectangleMark(x: .value("Budget", selectedBudget), width: .ratio(1))
//                        .foregroundStyle(.gray.opacity(0.2))
//                        .annotation(position: position, alignment: .center, spacing: 0) {
//                            VStack(alignment: .leading) {
//                                Text(selectedBudget.capitalized)
//                                    .font(.headline)
//                                Divider()
//                                Text("Budget: \(budget.currencyWithDecimals(2))")
//                                Text("Expenses: \(abs(expenses).currencyWithDecimals(2))")
//                            }
//                            .padding()
//                            .background(Color.annotationBackground)
//                        }
//                        .accessibilityHidden(true)
//                }
//            }
//        }
//        //.chartYScale(domain: [0, 100])
//        #if os(macOS)
//        .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 20)) }
//        #else
//        .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 10)) }
//        #endif
//        .chartXSelection(value: $selectedBudget)
////        #if os(macOS)
////        .chartOverlay { chartProxy in
////            Color.clear
////                .onContinuousHover {
////                    switch $0 {
////                    case .active(let hoverLocation):
////                        selectedBudget = chartProxy.value(atX: hoverLocation.x, as: String.self)
////                    case .ended:
////                        selectedBudget = nil
////                    }
////                }
////        }
////        #endif
//    }
    
    var pieChart: some View {
        VStack(spacing: 8) {
            Chart {
                ForEach(categoryBudget) { item in
                    SectorMark(angle: .value("Expenses", abs(item.expenses)), innerRadius: .ratio(0.7), angularInset: 2.0)
                        .foregroundStyle(item.category.color)
                        .cornerRadius(8)
                        .opacity(selectedBudget == nil ? 1 : (item.category.title == selectedBudget ? 1 : 0.3))
                }
            }
            .chartAngleSelection(value: $selectedAngle.animation())
            .onChange(of: selectedAngle) { old, new in
                if let new {
                    var cum: Double = 0
                    let _ = categoryBudget.first {
                        cum += abs($0.expenses)
                        if new <= cum {
                            selectedBudget = $0.category.title
                            return true
                        }
                        return false
                    }
                } else {
                    selectedBudget = nil
                }
            }
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    if let anchor = chartProxy.plotFrame {
                        let frame = geometry[anchor]
                        
                        if let selectedBudget {
                            let budget = categoryBudget.filter { $0.category.title == selectedBudget }.first?.budget
                            let expenses = categoryBudget.filter { $0.category.title == selectedBudget }.first?.expenses
                            let category = categoryBudget.filter { $0.category.title == selectedBudget }.first?.category
                            
                            if let budget, let expenses, let category {
                                Chart {
                                    if abs(expenses) < abs(budget) {
                                        SectorMark(
                                            angle: .value("Budget", abs(budget - abs(expenses))),
                                            innerRadius: .ratio(0.6),
                                            outerRadius: .ratio(0.6),
                                            angularInset: 2.0
                                        )
                                        .foregroundStyle(category.color)
                                        .cornerRadius(8)
                                        .opacity(0.3)
                                    }
                                                                                                            
                                    
                                        SectorMark(
                                            angle: .value("Expenses", abs(expenses)),
                                            innerRadius: .ratio(0.6),
                                            outerRadius: .ratio(0.6),
                                            angularInset: 2.0
                                        )
                                        .foregroundStyle(category.color.gradient)
                                        .cornerRadius(8)
                                        .opacity(1)
                                       
                                    
                                }
                                //.frame(width: 200, height: 200)
                                .position(x: frame.midX, y: frame.midY)
                                
                                
                                
                                
                                VStack(alignment: .leading) {
                                    Text(selectedBudget.capitalized)
                                        .font(.headline)
                                    //Divider()
                                    Text("Budget: \(budget.currencyWithDecimals(2))")
                                        .foregroundStyle(Color.secondary)
                                        .font(.subheadline)
                                    Text("Expenses: \(abs(expenses).currencyWithDecimals(2))")
                                        .foregroundStyle(Color.secondary)
                                        .font(.subheadline)
                                }
                                .position(x: frame.midX, y: frame.midY)
                            }
                        } else {
                            let expenses = categoryBudget.map { abs($0.expenses) }.reduce(0.0, +)
                            
                            VStack(alignment: .leading) {
                                Text("Total Expenses")
                                    .font(.headline)
                                
                                Text("\(abs(expenses).currencyWithDecimals(2))")
                            }
                            .position(x: frame.midX, y: frame.midY)
                        }
                    }
                }
                //.background(Color.red)
            }
            
            ScrollView(.horizontal) {
                ZStack {
                    Spacer()
                        .containerRelativeFrame([.horizontal])
                        .frame(height: 1)
                                                
                    HStack(spacing: 0) {
                        ForEach(categoryBudget.filter { $0.expenses < 0 || $0.income > 0 }) { item in
                            
                            VStack(spacing: 0) {
                                
                                
                                
                                HStack(spacing: 5) {
                                    ChartCircleDot(
                                        budget: item.budget,
                                        expenses: item.expenses,
                                        color: item.category.color,
                                        size: 22
                                    )
                                    
                                    
//                                    Circle()
//                                        .fill(item.category.color)
//                                        .frame(maxWidth: 12, maxHeight: 12) // 8 seems to be the default from charts
//                                        .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.category.title)
                                            .foregroundStyle(Color.secondary)
                                            .font(.subheadline)
                                            //.alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                                        
                                        let expenses = categoryBudget.filter { $0.category.title == item.category.title }.first?.expenses
                                        if let expenses {
                                            if expenses != 0 {
                                                Text("\(abs(expenses).currencyWithDecimals(2))")
                                                    .foregroundStyle(Color.secondary)
                                                    .font(.caption2)
                                            } else {
                                                Text("-")
                                                    .foregroundStyle(Color.secondary)
                                                    .font(.caption2)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 4)
                                .contentShape(Rectangle())
    //                            #if os(macOS)
    //                            .onContinuousHover { phase in
    //                                switch phase {
    //                                case .active:
    //                                    selectedBudget = item.category.title
    //                                case .ended:
    //                                    selectedBudget = nil
    //                                }
    //                            }
    //                            #endif
                                
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .contentMargins(.bottom, 10, for: .scrollContent)
        }
    }
    
    
}

extension Color {
    static var annotationBackground: Color {
        #if os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color(uiColor: .secondarySystemBackground)
        #endif
    }
}








////
////  BudgetTable.swift
////  MakeItRain
////
////  Created by Cody Burnett on 11/6/24.
////
//
//import SwiftUI
//import Charts
//
//struct ChartData: Identifiable {
//    let id = UUID().uuidString
//    let category: CBCategory
//    let data: Array<ChartDataPoint>
//    let overlayPosition: AnnotationPosition
//}
//
//struct ChartDataPoint: Identifiable {
//    let id = UUID().uuidString
//    let title: String
//    let amount: Double
//}
//
//struct BudgetTable: View {
//    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
//    @AppStorage("calendarChartMode") var chartMode = CalendarChartModel.verticalBar
//    @AppStorage("viewMode") var viewMode = CalendarViewMode.bottomPanel
//    @AppStorage("useWholeNumbers") var useWholeNumbers = false
//    
//    @Environment(CalendarModel.self) private var calModel
//    
//    @State private var deleteBudget: CBBudget?
//    @State private var editBudget: CBBudget?
//    @State private var budgetEditID: CBBudget.ID?
//    
//    @State private var selectedBudget: String?
//    @State private var selectedAngle: Double?
//    
//    @Binding var maxHeaderHeight: CGFloat
//    
//    var budgetCount: Int { calModel.sMonth.budgets.count }
//    
//    var categoryBudget: [ChartData] {
//        calModel.sMonth.budgets.enumerated().map { (index, budget) in
//            let expenseAmount = calModel.sMonth.days
//                .flatMap { $0.transactions
//                    .filter { $0.category?.id == budget.category?.id }
//                    .filter { $0.isBudgetable }
//                    .filter { $0.isExpense }
//                }
//                .compactMap { $0.amount }
//                .reduce(0.0, +)
//            
//            
//            let reimbursementAmount = calModel.sMonth.days
//                .flatMap { $0.transactions
//                    .filter { $0.category?.id == budget.category?.id }
//                    .filter { $0.isBudgetable }
//                    .filter { $0.isIncome }
//                }
//                .compactMap { $0.amount }
//                .reduce(0.0, +)
//                                    
//            let budge = ChartDataPoint(title: "Budget", amount: budget.amount)
//            let expenses = ChartDataPoint(title: "Expenses", amount: expenseAmount - reimbursementAmount)
//            
//            return ChartData(category: budget.category!, data: [budge, expenses], overlayPosition: index >= budgetCount / 2 ? .leading : .trailing)
//        }
//    }
//    
//        
//    var body: some View {
//        if calModel.sMonth.budgets.isEmpty {
//
//            ContentUnavailableView {
//                Label {
//                    Text("No Budget")
//                } icon: {
//                    Image(systemName: "square.stack.3d.up.slash.fill")
//                }
//            } description: {
//                HStack(spacing: 0) {
//                    Text("Use the ")
//                    Image(systemName: "arrow.triangle.branch")
//                        .rotationEffect(Angle(degrees: 180))
//                        .font(.title3)
//                    Text(" button above to create a budget for this month.")
//                }
//            }
//            .frame(maxWidth: .infinity)
//
//            
//            //ContentUnavailableView("No Budget", systemImage: "square.stack.3d.up.slash.fill", description: Text("Use the populate button above to create a budget for this month."))
//        } else {
//            GeometryReader { geo in
//                if viewMode == CalendarViewMode.split {
//                    VStack {
//                        #if os(macOS)
//                        TheTable(geo: geo, budgetEditID: $budgetEditID, selectedBudget: $selectedBudget, maxHeaderHeight: maxHeaderHeight)
//                        #else
//                        TheList(geo: geo, budgetEditID: $budgetEditID, selectedBudget: $selectedBudget, maxHeaderHeight: maxHeaderHeight)
//                        #endif
//                        
//                        theChart
//                    }
//                    
//                } else {
//                    #if os(iOS)
//                    VStack {
//                        theChart
//                        Divider()
//                        TheList(geo: geo, budgetEditID: $budgetEditID, selectedBudget: $selectedBudget, maxHeaderHeight: maxHeaderHeight)
//                    }
//                    #else
//                    HStack {
//                        theChart
//                        TheTable(geo: geo, budgetEditID: $budgetEditID, selectedBudget: $selectedBudget, maxHeaderHeight: maxHeaderHeight)
//                    }
//                    #endif
//                    
//                }
//            }
//            .onChange(of: budgetEditID) { oldValue, newValue in
//                if let newValue {
//                    if newValue != -1 {
//                        editBudget = calModel.sMonth.budgets.filter { $0.id == newValue }.first!
//                    }
//                }
//            }
//            .sheet(item: $editBudget, onDismiss: {
//                budgetEditID = nil
//            }, content: { budget in
//                BudgetEditView(budget: budget, calModel: calModel)
//                    .presentationSizing(.page)
//                    //#if os(iOS)
//                    //.presentationDetents([.medium, .large])
//                    //#endif
//                    //#if os(macOS)
//                    //.frame(minWidth: 700)
//                    //#endif
//                    //.frame(maxWidth: 300)
//            })
//        }
//    }
//    
//    
//    struct TheTable: View {
//        @AppStorage("viewMode") var viewMode = CalendarViewMode.bottomPanel
//        @AppStorage("useWholeNumbers") var useWholeNumbers = false
//        @AppStorage("threshold") var threshold = "500.0"
//        @Environment(CalendarModel.self) private var calModel
//        
//        var geo: GeometryProxy
//        @Binding var budgetEditID: CBBudget.ID?
//        @Binding var selectedBudget: String?
//        
//        var maxHeaderHeight: CGFloat
//        
//        @State private var sortOrder = [KeyPathComparator(\CBBudget.category?.title)]
//        
//        var remainingFundsTotal: Color {
//            let income = calModel.sMonth.startingAmounts
//                .filter { $0.payMethod.accountType != .credit && !$0.payMethod.isUnified }
//                .map { $0.amount }
//                .reduce(0.0, +)
//                +
//            
//                calModel.sMonth.justTransactions
//                    .filter { $0.payMethod?.accountType != .credit }
//                    .filter { $0.amount > 0 }
//                    .map { $0.amount }
//                    .reduce(0.0, +)
//            
//            let expenses = calModel.sMonth.days
//                .flatMap { $0.transactions
//                    .filter { $0.payMethod?.accountType != .credit }
//                    .filter { $0.amount < 0 }
//                }
//                .map { $0.amount }
//                .reduce(0.0, +)
//            
//            
//            if (income - expenses) > Double(threshold) ?? 500 {
//                return .gray
//            } else if (income - expenses) < 0 {
//                return .red
//            } else {
//                return .orange
//            }
//        }
//        
//        var income: Double {
//            calModel.sMonth.startingAmounts
//                .filter { $0.payMethod.accountType != .credit && !$0.payMethod.isUnified }
//                .map { $0.amount }
//                .reduce(0.0, +)
//            +
//            calModel.sMonth.justTransactions
//                .filter { $0.payMethod?.accountType != .credit }
//                .filter { $0.amount > 0 }
//                .map { $0.amount }
//                .reduce(0.0, +)
//        }
//        
//        var expenses: Double {
//            calModel.sMonth.justTransactions
//                .filter { $0.payMethod?.accountType != .credit }
//                .filter { $0.amount < 0 }
//                .compactMap { $0.amount }
//                .reduce(0.0, +)
//        }
//                        
//        var body: some View {
//            VStack {
//                HStack(alignment: .center) {
//                    Text("Income: \(income.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
//                        .padding(.leading, 16)
//                                                                                    
//                    Text("Expenses: \(abs(expenses).currencyWithDecimals(useWholeNumbers ? 0 : 2))")
//                        .padding(.leading, 16)
//                    
//                    (
//                    Text("Available Funds: ")
//                    + Text((income - abs(expenses)).currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                        .foregroundStyle(remainingFundsTotal)
//                    ).padding(.leading, 16)
//                    
//                    Spacer()
//                }
//                .frame(minHeight: maxHeaderHeight)
//                
//                Divider()
//                
//                Table(of: CBBudget.self, selection: $budgetEditID, sortOrder: $sortOrder) {
//                    TableColumn("Category") { budget in
//                        
//                        HStack(spacing: 4) {
//                            Circle()
//                                .fill(budget.category?.color ?? .primary)
//                                .frame(width: 12, height: 12)
//                                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                            Text(budget.category?.title ?? "-")
//                        }
//                    }
//                    
//                    TableColumn("Budget") { budget in
//                        @Bindable var budget = budget
//                        TextField("BudgetAmount", text: $budget.amountString)
//                            .onSubmit {
//                                Task { await calModel.submit(budget) }
//                            }
//                    }
//                                
//                    TableColumn("Expenses") { budget in
//                        let expenseAmount = calModel.sMonth.justTransactions
//                            .filter { $0.payMethod?.accountType != .credit }
//                            .filter { $0.category?.id == budget.category?.id }
//                            .filter { $0.amount < 0 }
//                            .compactMap { $0.amount }
//                            .reduce(0.0, +)
//                                                                
//                        Text(abs(expenseAmount).currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                    }
//                    
//                    
//                    TableColumn("Over/Under") { budget in
//                        let expenseAmount = calModel.sMonth.justTransactions
//                            .filter { $0.payMethod?.accountType != .credit }
//                            .filter { $0.category?.id == budget.category?.id }
//                            .filter { $0.amount < 0 }
//                            .compactMap { $0.amount }
//                            .reduce(0.0, +)
//                        
//                        let reimbursementAmount = calModel.sMonth.days
//                            .flatMap { $0.transactions
//                                .filter { $0.payMethod?.accountType != .credit }
//                                .filter { $0.category?.id == budget.category?.id }
//                                .filter { $0.amount > 0 }
//                            }
//                            .compactMap { $0.amount }
//                            .reduce(0.0, +)
//                                                
//                        let overUnder = (expenseAmount - reimbursementAmount) - budget.amount
//                        
//                        Text(overUnder.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                            .foregroundStyle(overUnder < 0 ? .red : .primary)
//                    }
//                } rows: {
//                    ForEach(calModel.sMonth.budgets) { budget in
//                        TableRow(budget)
//                            #if os(macOS)
//                            .onHover {
//                                selectedBudget = $0 ? budget.category?.title : nil
//                            }
//                            #endif
//                    }
//                }
//                .clipped()
//                .onChange(of: sortOrder) { _, sortOrder in
//                    calModel.sMonth.budgets.sort(using: sortOrder)
//                }
//                /// Do this to align the top of the table with the top of the day views.
//                .if(viewMode == .split) {
//                    $0.padding(.top, 4)
//                }
//            }
//        }
//    }
//    
//    #if os(iOS)
//    struct TheList: View {
//        @AppStorage("viewMode") var viewMode = CalendarViewMode.bottomPanel
//        @AppStorage("useWholeNumbers") var useWholeNumbers = false
//        @AppStorage("threshold") var threshold = "500.0"
//        @Environment(CalendarModel.self) private var calModel
//        
//        var geo: GeometryProxy
//        @Binding var budgetEditID: CBBudget.ID?
//        @Binding var selectedBudget: String?
//        
//        var maxHeaderHeight: CGFloat
//        
//        @State private var sortOrder = [KeyPathComparator(\CBBudget.category?.title)]
//        
//        var remainingFundsTotal: Color {
//            let income = calModel.sMonth.startingAmounts
//                .filter { $0.payMethod.accountType != .credit && !$0.payMethod.isUnified }
//                .map { $0.amount }
//                .reduce(0.0, +)
//                +
//            
//                calModel.sMonth.justTransactions
//                    .filter { $0.payMethod?.accountType != .credit && $0.amount > 0 }
//                    .map { $0.amount }
//                    .reduce(0.0, +)
//            
//            let expenses = calModel.sMonth.justTransactions
//                .filter { $0.payMethod?.accountType != .credit && $0.amount < 0 }
//                .map { $0.amount }
//                .reduce(0.0, +)
//            
//            
//            if (income - abs(expenses)) > Double(threshold) ?? 500 {
//                return .gray
//            } else if (income - abs(expenses)) < 0 {
//                return .red
//            } else {
//                return .orange
//            }
//        }
//        
//        var income: Double {
//            calModel.sMonth.startingAmounts
//                .filter { $0.payMethod.accountType != .credit && !$0.payMethod.isUnified }
//                .map { $0.amount }
//                .reduce(0.0, +)
//            +
//            calModel.sMonth.justTransactions
//                .filter { $0.payMethod?.accountType != .credit && $0.amount > 0 }
//                .map { $0.amount }
//                .reduce(0.0, +)
//        }
//        
//        var expenses: Double {
//            calModel.sMonth.justTransactions
//                .filter { $0.payMethod?.accountType != .credit && $0.amount < 0 }
//                .compactMap { $0.amount }
//                .reduce(0.0, +)
//        }
//        
//        var body: some View {
//            VStack {
//                HStack {
//                    Spacer()
//                        .frame(width: 20)
//                    VStack(alignment: .leading, spacing: 2) {
//                        Text("Income")
//                        Text(income.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                    }
//                    
//                    VStack(alignment: .leading, spacing: 2) {
//                        Text("Expenses")
//                        Text(abs(expenses).currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                    }
//                    
//                    VStack(alignment: .leading, spacing: 2) {
//                        Text("Available Funds")
//                        Text((income - abs(expenses)).currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                            .foregroundStyle(remainingFundsTotal)
//                    }
//                    Spacer()
//                }
//                
//                List(calModel.sMonth.budgets, selection: $budgetEditID) { budget in
//                    HStack(alignment: .circleAndTitle, spacing: 4) {
//                        Circle()
//                            .fill(budget.category?.color ?? .primary)
//                            .frame(width: 12, height: 12)
//                            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                        
//                        VStack(alignment: .leading) {
//                            HStack {
//                                Text(budget.category?.title ?? "-")
//                                Spacer()
//                            }
//                            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                                                    
//                            HStack {
//                                Text("Budget:")
//                                Spacer()
//                                Text(budget.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                            }
//                            .foregroundStyle(.gray)
//                            .font(.caption)
//                        
//                        
//                            HStack {
//                                Text("Expenses:")
//                                Spacer()
//                                let expenseAmount = calModel.sMonth.days
//                                    .flatMap { $0.transactions.filter { /*$0.payMethod?.accountType != .credit &&*/ $0.category?.id == budget.category?.id } }
//                                    .compactMap { $0.amount }
//                                    .reduce(0.0, +)
//                                
//                                Text(abs(expenseAmount).currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                            }
//                            .foregroundStyle(.gray)
//                            .font(.caption)
//                            
//                            HStack {
//                                Text("Over/Under:")
//                                Spacer()
//                                let expenseAmount = calModel.sMonth.days
//                                    .flatMap { $0.transactions.filter { /*$0.payMethod?.accountType != .credit &&*/ $0.category?.id == budget.category?.id } }
//                                    .compactMap { $0.amount }
//                                    .reduce(0.0, +)
//                                
//                                let overUnder = budget.amount - abs(expenseAmount)
//                                
//                                Text(overUnder.currencyWithDecimals(useWholeNumbers ? 0 : 2))
//                                    .foregroundStyle(overUnder < 0 ? .red : .primary)
//                            }
//                            .foregroundStyle(.gray)
//                            .font(.caption)
//                        }
//                    }
//                    .rowBackgroundWithSelection(id: budget.id, selectedID: budgetEditID)
//                }
//                .listStyle(.plain)
//            }
//        }
//    }
//    #endif
//    
//    
//    var theChart: some View {
//        VStack {
//            HStack {
//                Picker(selection: $chartMode) {
//                    Image(systemName: "chart.bar.fill")
//                        .tag(CalendarChartModel.verticalBar)
//                    Image(systemName: "chart.pie.fill")
//                        .tag(CalendarChartModel.pie)
//                } label: {
//                    EmptyView()
//                }
//                .pickerStyle(.segmented)
//                .labelsHidden()
//                .frame(maxWidth: 100)
//                .padding(.leading, 8)
//                Spacer()
//            }
//            .frame(minHeight: maxHeaderHeight)
//            //.maxViewHeightObserver()
//            
//            Divider()
//            
//            if chartMode == .verticalBar {
//                verticalBarChart
//            } else {
//                pieChart
//            }
//        }
//    }
//    
//    
//    
//    var verticalBarChart: some View {
//        VStack {
//            Chart {
//                ForEach(categoryBudget) { item in
//                    BarMark(
//                        x: .value("Budget", item.category.title),
//                        y: .value("Amount", abs(item.data[1].amount)),
//                        width: .ratio(0.6)
//                    )
//                    .foregroundStyle(item.category.color)
//                    .clipShape(RoundedRectangle(cornerRadius: 8))
////                    .annotation(position: .top, alignment: .center, spacing: 0) {
////                        Text(abs(item.data[1].amount).currencyWithDecimals(2))
////                            #if os(iOS)
////                            .font(.footnote)
////                            #endif
////                    }
//                    
//                    RectangleMark(
//                        x: .value("Budget", item.category.title),
//                        y: .value("Amount", abs(item.data[0].amount)),
//                        width: .ratio(0.6),
//                        height: 4
//                    )
//                    //.foregroundStyle(item.category.color.opacity(0.6))
//                    .foregroundStyle(.gray)
//                    .clipShape(RoundedRectangle(cornerRadius: 8))
////                    .annotation(position: .top, alignment: .center, spacing: 0) {
////                        Text(abs(item.data[0].amount).currencyWithDecimals(2))
////                            #if os(iOS)
////                            .font(.footnote)
////                            #endif
////                    }
//                    .accessibilityHidden(true)
//                }
//                
//                if let selectedBudget {
//                    let position = categoryBudget.filter { $0.category.title == selectedBudget }.first?.overlayPosition
//                    let budget = categoryBudget.filter { $0.category.title == selectedBudget }.first?.data[0].amount
//                    let expenses = categoryBudget.filter { $0.category.title == selectedBudget }.first?.data[1].amount
//                    
//                    if let position, let budget, let expenses {
//                        RectangleMark(x: .value("Budget", selectedBudget), width: .ratio(1))
//                            .foregroundStyle(.gray.opacity(0.2))
//                            .annotation(position: position, alignment: .center, spacing: 0) {
//                                VStack(alignment: .leading) {
//                                    Text(selectedBudget.capitalized)
//                                        .font(.headline)
//                                    Divider()
//                                    Text("Budget: \(budget.currencyWithDecimals(2))")
//                                    Text("Expenses: \(abs(expenses).currencyWithDecimals(2))")
//                                }
//                                .padding()
//                                .background(Color.annotationBackground)
//                            }
//                            .accessibilityHidden(true)
//                    }
//                }
//            }
//            #if os(macOS)
//            .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 20)) }
//            #else
//            .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 10)) }
//            #endif
//            .chartXSelection(value: $selectedBudget)
////            .chartForegroundStyleScale([
////                "Budget": Color.fromName(appColorTheme),
////                "Expenses": Color.fromName(appColorTheme).opacity(0.6)
////            ])
//            .chartScrollableAxes(.horizontal)
//            .chartXVisibleDomain(length: 5)
//            .chartScrollTargetBehavior(.valueAligned(unit: 1))
//            
//            HStack {
//                HStack(spacing: 5) {
//                    Rectangle()
//                    //RoundedRectangle(cornerRadius: 8)
//                        //.fill(AngularGradient(gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red]), center: .center))
//                        //.fill(Color.fromName(appColorTheme))
//                        .fill(Color.gray.opacity(0.6))
//                        .frame(maxWidth: 12, maxHeight: 12) // 8 seems to be the default from charts
//                    Text("Budget")
//                        .foregroundStyle(Color.secondary)
//                        .font(.subheadline)
//                }
//                
//                HStack(spacing: 5) {
//                    RoundedRectangle(cornerRadius: 8)
//                        //.fill(AngularGradient(gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red]), center: .center))
//                        //.fill(Color.fromName(appColorTheme))
//                        .fill(Color.gray)
//                        //.frame(maxWidth: 12, maxHeight: 12) // 8 seems to be the default from charts
//                        .frame(maxWidth: 12, maxHeight: 4) // 8 seems to be the default from charts
//                    Text("Expenses")
//                        .foregroundStyle(Color.secondary)
//                        .font(.subheadline)
//                }
//                Spacer()
//            }
//        }
//    }
//    
//    var verticalBarChart1: some View {
//        Chart {
//            ForEach(categoryBudget) { item in
//                ForEach(item.data) { metric in
//                    BarMark(
//                        x: .value("Budget", item.category.title),
//                        y: .value("Amount", abs(metric.amount)),
//                        width: metric.title == "Budget" ? .ratio(0.7) : .ratio(0.6),
//                        stacking: .unstacked
//                    )
//                    .foregroundStyle(item.category.color.opacity(metric.title == "Budget" ? 0.8 : 1))
//                    
//                    //.foregroundStyle(by: .value("Category", metric.title))
//                    //.position(by: .value("Category", metric.title))
//                }
//            }
//            
//            if let selectedBudget {
//                let position = categoryBudget.filter { $0.category.title == selectedBudget }.first?.overlayPosition
//                let budget = categoryBudget.filter { $0.category.title == selectedBudget }.first?.data[0].amount
//                let expenses = categoryBudget.filter { $0.category.title == selectedBudget }.first?.data[1].amount
//                
//                if let position, let budget, let expenses {
//                    RectangleMark(x: .value("Budget", selectedBudget), width: .ratio(1))
//                        .foregroundStyle(.gray.opacity(0.2))
//                        .annotation(position: position, alignment: .center, spacing: 0) {
//                            VStack(alignment: .leading) {
//                                Text(selectedBudget.capitalized)
//                                    .font(.headline)
//                                Divider()
//                                Text("Budget: \(budget.currencyWithDecimals(2))")
//                                Text("Expenses: \(abs(expenses).currencyWithDecimals(2))")
//                            }
//                            .padding()
//                            .background(Color.annotationBackground)
//                        }
//                        .accessibilityHidden(true)
//                }
//            }
//        }
//        //.chartYScale(domain: [0, 100])
//        #if os(macOS)
//        .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 20)) }
//        #else
//        .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 10)) }
//        #endif
//        .chartXSelection(value: $selectedBudget)
////        #if os(macOS)
////        .chartOverlay { chartProxy in
////            Color.clear
////                .onContinuousHover {
////                    switch $0 {
////                    case .active(let hoverLocation):
////                        selectedBudget = chartProxy.value(atX: hoverLocation.x, as: String.self)
////                    case .ended:
////                        selectedBudget = nil
////                    }
////                }
////        }
////        #endif
//    }
//    
//    var pieChart: some View {
//        VStack(spacing: 8) {
//            Chart {
//                ForEach(categoryBudget) { item in
//                    ForEach(item.data.filter { $0.title == "Expenses" }) { metric in
//                        SectorMark(angle: .value("Expenses", abs(metric.amount)), innerRadius: .ratio(0.7), angularInset: 2.0)
//                            .foregroundStyle(item.category.color)
//                            .cornerRadius(8)
//                            .opacity(selectedBudget == nil ? 1 : (item.category.title == selectedBudget ? 1 : 0.3))
////                            .annotation(position: .overlay) {
////                                let expenses = data.filter { $0.category.title == item.category.title }.first?.data[1].amount
////                                if let expenses {
////                                    if expenses != 0 {
////                                        Text("\(abs(expenses).currencyWithDecimals(2))")
////                                    }
////                                }
////                            }
//                    }
//                }
//            }
//            .chartAngleSelection(value: $selectedAngle)
//            .onChange(of: selectedAngle) { old, new in
//                if let new {
//                    var cum: Double = 0
//                    let _ = categoryBudget.first {
//                        cum += abs($0.data[1].amount)
//                        if new <= cum {
//                            selectedBudget = $0.category.title
//                            return true
//                        }
//                        return false
//                    }
//                } else {
//                    selectedBudget = nil
//                }
//            }
//            .chartBackground { chartProxy in
//                GeometryReader { geometry in
//                    if let anchor = chartProxy.plotFrame {
//                        let frame = geometry[anchor]
//                        
//                        if let selectedBudget {
//                            let budget = categoryBudget.filter { $0.category.title == selectedBudget }.first?.data[0].amount
//                            let expenses = categoryBudget.filter { $0.category.title == selectedBudget }.first?.data[1].amount
//                            
//                            if let budget, let expenses {
//                                VStack(alignment: .leading) {
//                                    Text(selectedBudget.capitalized)
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
//                            let expenses = categoryBudget.map { abs($0.data[1].amount) }.reduce(0.0, +)
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
//                    HStack {
//                        ForEach(categoryBudget) { item in
//                            HStack(alignment: .circleAndTitle, spacing: 5) {
//                                Circle()
//                                    .fill(item.category.color)
//                                    .frame(maxWidth: 12, maxHeight: 12) // 8 seems to be the default from charts
//                                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                                
//                                VStack(alignment: .leading, spacing: 2) {
//                                    Text(item.category.title)
//                                        .foregroundStyle(Color.secondary)
//                                        .font(.subheadline)
//                                        .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                                    
//                                    let expenses = categoryBudget.filter { $0.category.title == item.category.title }.first?.data[1].amount
//                                    if let expenses {
//                                        if expenses != 0 {
//                                            Text("\(abs(expenses).currencyWithDecimals(2))")
//                                                .foregroundStyle(Color.secondary)
//                                                .font(.caption2)
//                                        }
//                                    }
//                                }
//                            }
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
//}
//
//extension Color {
//    static var annotationBackground: Color {
//        #if os(macOS)
//        return Color(nsColor: .controlBackgroundColor)
//        #else
//        return Color(uiColor: .secondarySystemBackground)
//        #endif
//    }
//}
