////
////  BudgetTableOG.swift
////  MakeItRain
////
////  Created by Cody Burnett on 5/7/25.
////
//import SwiftUI
//import Charts
//
//
//struct BudgetTableOG: View {
//    @Environment(\.dismiss) var dismiss
//    @Environment(\.colorScheme) var colorScheme
//    //@Local(\.colorTheme) var colorTheme
//    @AppStorage("calendarChartMode") var chartMode = CalendarChartModel.verticalBar
//    @AppStorage("viewMode") var viewMode = CalendarViewMode.scrollable
//    
//    @Local(\.categorySortMode) var categorySortMode
//    
//    @Environment(CalendarModel.self) private var calModel
//    @Environment(CategoryModel.self) private var catModel
//    
//    @State private var deleteBudget: CBBudget?
//    @State private var editBudget: CBBudget?
//    @State private var budgetEditID: CBBudget.ID?
//    
//    @State private var selectedBudget: String?
//    @State private var selectedAngle: Double?
//    
//    enum WhichView {
//        case chart, list
//    }
//    
//    @State private var whichView: WhichView = .chart
//    
//    var budgetCount: Int { calModel.sMonth.budgets.count }
//    
//    @State private var categoryBudget: [ChartData] = []
//    
//        
//    var body: some View {
//        #if os(iOS)
//        SheetHeader(title: "\(calModel.sMonth.name) \(String(calModel.sMonth.year))", close: { dismiss() })
//        #endif
//        
//        if calModel.sMonth.budgets.isEmpty {
//            noBudgetView
//        } else {
//            Group {
//                #if os(iOS)
//                VStack {
//                    HStack {
//                        Picker("", selection: $whichView) {
//                            Text("Chart")
//                                .tag(WhichView.chart)
//                            Text("List")
//                                .tag(WhichView.list)
//                        }
//                        .labelsHidden()
//                        .pickerStyle(.segmented)
//                                                
//                        Picker(selection: $chartMode) {
//                            Image(systemName: "chart.bar.fill")
//                                .tag(CalendarChartModel.verticalBar)
//                            Image(systemName: "chart.pie.fill")
//                                .tag(CalendarChartModel.pie)
//                        } label: {
//                            EmptyView()
//                        }
//                        .pickerStyle(.segmented)
//                        .labelsHidden()
//                        .frame(maxWidth: 100)
//                        .padding(.leading, 8)
//                        .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                        .disabled(whichView == .list)
//                    }
//                    if whichView == .chart {
//                        theChart
//                    } else {
//                        TheList(budgetEditID: $budgetEditID, selectedBudget: $selectedBudget)
//                    }
//                }
//                #else
//                VStack {
//                    TableHeader()
//                    Divider()
//                    HStack {
//                        TheTable(budgetEditID: $budgetEditID, selectedBudget: $selectedBudget)
//                        theChart
//                    }
//                }
//                #endif
//            }
//            .onChange(of: budgetEditID) { oldValue, newValue in
//                if let newValue {
//                    editBudget = calModel.sMonth.budgets.filter { $0.id == newValue }.first!
//                } else if newValue == nil && oldValue != nil {
//                    let budget = calModel.sMonth.budgets.filter { $0.id == oldValue! }.first!
//                    Task {
//                        if budget.hasChanges() {
//                            print("HAS CHANGES")
//                            await calModel.submit(budget)
//                        } else {
//                            print("NO CHANGES")
//                        }
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
//            .task {
//                categoryBudget = calModel.sMonth.budgets
//                    .filter{ $0.category != nil }
//                    .filter{ !$0.category!.isIncome }
//                    .sorted {
//                        categorySortMode == .title
//                        ? ($0.category!.title).lowercased() < ($1.category!.title).lowercased()
//                        : $0.category!.listOrder ?? 1000000000 < $1.category!.listOrder ?? 1000000000
//                    }
//                    .enumerated()
//                    .map { (index, budget) in
//                        let expenses = calModel.sMonth.justTransactions
//                            .filter { $0.isBudgetable && $0.isExpense && $0.factorInCalculations }
//                            .filter { $0.category?.id == budget.category?.id }
//                            .map { $0.amount }
//                            .reduce(0.0, +)
//                                                                                                
//                        let income = calModel.sMonth.justTransactions
//                            .filter { $0.isBudgetable && $0.isIncome && $0.factorInCalculations }
//                            .filter { $0.category?.id == budget.category?.id }
//                            .map { $0.amount }
//                            .reduce(0.0, +)
//                        
//                                                
//            //            let budge = ChartDataPoint(title: "Budget", amount: budget.amount)
//            //            let expenses = ChartDataPoint(title: "Expenses", amount: expenseAmount - reimbursementAmount)
//            //
//                        return ChartData(
//                            category: budget.category!,
//                            budget: budget.amount,
//                            income: income,
//                            expenses: expenses,
//                            overlayPosition: index >= budgetCount / 2 ? .leading : .trailing
//                        )
//                }
//            }
//        }
//    }
//    
//    
//    var noBudgetView: some View {
//        Group {
//            ContentUnavailableView {
//                Label {
//                    Text("No Budget")
//                } icon: {
//                    Image(systemName: "square.stack.3d.up.slash.fill")
//                }
//            } description: {
//                Text("Click below to create.")
//            }
//            .frame(maxWidth: .infinity)
//            
//            Button("Create Budget") {
//                let model = PopulateOptions()
//                model.budget = true
//                calModel.populate(options: model, repTransactions: [], categories: catModel.categories)
//            }
//            
//            .padding(.bottom, 6)
//            #if os(macOS)
//            .foregroundStyle(Color.theme)
//            .buttonStyle(.codyStandardWithHover)
//            #else
//            .tint(Color.theme)
//            .buttonStyle(.borderedProminent)
//            #endif
//        }
//        
//    }
//    
//    
//    
//    struct TableHeader: View {
//        @AppStorage("threshold") var threshold = "500.0"
//        
//        @Environment(CalendarModel.self) private var calModel
//    
//                
//        var income: Double {
//            calModel.sMonth.startingAmounts
//                .filter { $0.payMethod.accountType == .cash || $0.payMethod.accountType == .checking }
//                .map { $0.amount }
//                .reduce(0.0, +)
//            +
//            calModel.sMonth.justTransactions
//                .filter { $0.isBudgetable && $0.isIncome && $0.factorInCalculations }
//                .map { $0.amount }
//                .reduce(0.0, +)
//        }
//        
//        var expenses: Double {
//            calModel.sMonth.justTransactions
//                .filter { $0.isBudgetable && $0.isExpense && $0.factorInCalculations}
//                .map { $0.amount }
//                .reduce(0.0, +)
//        }
//                
//        var remainingFundsTotal: Color {
//            if (income - expenses) > Double(threshold) ?? 500 {
//                return .gray
//            } else if (income - expenses) < 0 {
//                return .red
//            } else {
//                return .orange
//            }
//        }
//                        
//        var body: some View {
//            HStack(alignment: .center) {
//                Text("Income: \(income.currencyWithDecimals())")
//                    //.padding(.leading, 16)
//                                                                                
//                Text("Expenses: \(abs(expenses).currencyWithDecimals())")
//                    .padding(.leading, 16)
//                
//                (
//                    Text("Available Funds: ")
//                    +
//                    Text((income - abs(expenses)).currencyWithDecimals())
//                    .foregroundStyle(remainingFundsTotal)
//                )
//                .padding(.leading, 16)
//            }
//        }
//    }
//    
//    
//    struct TheTable: View {
//        @AppStorage("viewMode") var viewMode = CalendarViewMode.scrollable
//        
//        @AppStorage("threshold") var threshold = "500.0"
//        @Environment(CalendarModel.self) private var calModel
//        
//        @Binding var budgetEditID: CBBudget.ID?
//        @Binding var selectedBudget: String?
//                
//        //@State private var sortOrder = [KeyPathComparator(\CBBudget.category?.title)]
//        @State private var labelWidth: CGFloat = 20.0
//        
//                        
//        var body: some View {
//            VStack(spacing: 0) {
//                Table(of: CBBudget.self, selection: $budgetEditID/*, sortOrder: $sortOrder*/) {
//                    TableColumn("Category") { budget in
//                        HStack(spacing: 4) {
//                            if let emoji = budget.category?.emoji {
//                                Image(systemName: emoji)
//                                    .foregroundStyle(budget.category?.color ?? .primary)
//                                    .frame(minWidth: labelWidth, alignment: .center)
//                            } else {
//                                Circle()
//                                    .fill(budget.category?.color ?? .primary)
//                                    .frame(width: 12, height: 12)
//                            }
//                                                        
//                            Text(budget.category?.title ?? "-")
//                        }
//                    }
//                    
//                    TableColumn("Budget") { budget in
//                        Text(budget.amountString)
//                    }
//                                
//                    TableColumn("Expenses") { budget in
//                        let expenses = calModel.sMonth.justTransactions
//                            .filter { $0.isBudgetable && $0.isExpense && $0.factorInCalculations }
//                            .filter { $0.category?.id == budget.category?.id }
//                            .map { $0.amount }
//                            .reduce(0.0, +)
//                                                                
//                        Text(abs(expenses).currencyWithDecimals())
//                    }
//                    
//                    TableColumn("Income") { budget in
//                        let income = calModel.sMonth.justTransactions
//                            .filter { $0.isBudgetable && $0.isIncome && $0.factorInCalculations }
//                            .filter { $0.category?.id == budget.category?.id }
//                            .map { $0.amount }
//                            .reduce(0.0, +)
//                                                                
//                        Text(abs(income).currencyWithDecimals())
//                    }
//                    
//                    
//                    TableColumn("Over/Under") { budget in
//                        let expenses = calModel.sMonth.justTransactions
//                            .filter { $0.isBudgetable && $0.isExpense && $0.factorInCalculations }
//                            .filter { $0.category?.id == budget.category?.id }
//                            .map { $0.amount }
//                            .reduce(0.0, +)
//                                                                                                
//                        let income = calModel.sMonth.justTransactions
//                            .filter { $0.isBudgetable && $0.isIncome && $0.factorInCalculations }
//                            .filter { $0.category?.id == budget.category?.id }
//                            .map { $0.amount }
//                            .reduce(0.0, +)
//                                                
//                        let overUnder = budget.amount + (expenses + income)
//                        
//                        Text(abs(overUnder).currencyWithDecimals())
//                            .foregroundStyle(overUnder < 0 ? .red : (overUnder > budget.amount ? .green : .primary) )
//                    }
//                } rows: {
//                    ForEach(calModel.sMonth.budgets.sorted {$0.category?.listOrder ?? 10000000 < $1.category?.listOrder ?? 10000000}) { budget in
//                        TableRow(budget)
//                            #if os(macOS)
//                            .onHover {
//                                selectedBudget = $0 ? budget.category?.title : nil
//                            }
//                            #endif
//                    }
//                }
//                //.tableStyle(.bordered)
//                .clipped()
////                .onChange(of: sortOrder) { _, sortOrder in
////                    calModel.sMonth.budgets.sort(using: sortOrder)
////                }
//                /// Do this to align the top of the table with the top of the day views.
////                .if(viewMode == .split) {
////                    $0.padding(.top, 6)
////                }
//            }
//            .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
//            
//        }
//    }
//    
//    
//    #if os(iOS)
//    struct TheList: View {
//        @AppStorage("viewMode") var viewMode = CalendarViewMode.scrollable
//        
//        @AppStorage("threshold") var threshold = "500.0"
//        @Environment(CalendarModel.self) private var calModel
//    
//        @Binding var budgetEditID: CBBudget.ID?
//        @Binding var selectedBudget: String?
//        
//        @State private var labelWidth: CGFloat = 20.0
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
//            let start = calModel.sMonth.startingAmounts
//                .filter { $0.payMethod.accountType != .credit && !$0.payMethod.isUnified }
//                .map { $0.amount }
//                .reduce(0.0, +)
//            
//            let trans = calModel.sMonth.justTransactions
//                .filter { $0.isBudgetable && ($0.category ?? CBCategory()).isIncome }
//                .map { $0.amount }
//                .reduce(0.0, +)
//            
//            
//            //print("start: \(start), trans: \(trans), income: \(start + trans)")
//            
//            return start + trans
//        }
//        
//        var expenses: Double {
//            calModel.sMonth.justTransactions
//                .filter { $0.payMethod?.accountType != .credit && $0.amount < 0 }
//                .compactMap { $0.amount }
//                .reduce(0.0, +)
//        }
//        
//        
//        let columnGrid = Array(repeating: GridItem(.flexible(), spacing: 0), count: 4)
//        
//        
//        var body: some View {
//            VStack {
//                HStack {
//                    VStack(alignment: .leading, spacing: 2) {
//                        Text("Income")
//                        Text(income.currencyWithDecimals())
//                    }
//                    
//                    VStack(alignment: .leading, spacing: 2) {
//                        Text("Expenses")
//                        Text(abs(expenses).currencyWithDecimals())
//                    }
//                    
//                    VStack(alignment: .leading, spacing: 2) {
//                        Text("Available Funds")
//                        Text((income - abs(expenses)).currencyWithDecimals())
//                            .foregroundStyle(remainingFundsTotal)
//                    }
//                    Spacer()
//                }
//                
//                Divider()
//                
//                LazyVGrid(columns: columnGrid, alignment: .leading, spacing: 10) {
//                    Text("Category")
//                    Text("Budget")
//                    Text("Expenses")
//                    Text("Over/Under")
//                }
//                .font(.caption2)
//                
//                
//                List(calModel.sMonth.budgets.sorted {$0.category?.listOrder ?? 10000000 < $1.category?.listOrder ?? 10000000}, selection: $budgetEditID) { budget in
//                    LazyVGrid(columns: columnGrid, alignment: .leading, spacing: 10) {
//                        HStack(alignment: .circleAndTitle, spacing: 5) {
//                            let expenses = calModel.sMonth.justTransactions
//                                .filter { $0.isBudgetable && $0.isExpense && $0.factorInCalculations }
//                                .filter { $0.category?.id == budget.category?.id }
//                                .map { $0.amount }
//                                .reduce(0.0, +)
//                            
//                            
//                            
//                            ChartCircleDot(
//                                budget: budget.amount,
//                                expenses: abs(expenses),
//                                color: budget.category?.color ?? .white,
//                                size: 12
//                            )
//                            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                            
//                            
////                            Circle()
////                                .fill(budget.category?.color ?? .primary)
////                                .frame(width: 12, height: 12)
////                                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                            
//                            
//                            Text(budget.category?.title ?? "-")
//                                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                        }
//                        
//                        
//                        let expenses = calModel.sMonth.justTransactions
//                            .filter { $0.isBudgetable && $0.isExpense && $0.factorInCalculations }
//                            .filter { $0.category?.id == budget.category?.id }
//                            .map { $0.amount }
//                            .reduce(0.0, +)
//                        
//                        let income = calModel.sMonth.justTransactions
//                            .filter { $0.isBudgetable && $0.isIncome && $0.factorInCalculations }
//                            .filter { $0.category?.id == budget.category?.id }
//                            .map { $0.amount }
//                            .reduce(0.0, +)
//                        
//                        
//                        Text(budget.amount.currencyWithDecimals())
//                        Text(abs(expenses).currencyWithDecimals())
//                        
//                        let overUnder = budget.amount + (expenses + income)
//                        
//                        Text(abs(overUnder).currencyWithDecimals())
//                            .foregroundStyle(overUnder < 0 ? .red : (overUnder > budget.amount ? .green : .primary) )
//                    }
//                    .font(.caption2)
//                    .listRowInsets(EdgeInsets())
//                    
//                    
//                    
//                    
//                    
//                    
////                    HStack(alignment: .circleAndTitle, spacing: 4) {
////
////                        if let emoji = budget.category?.emoji {
////                            Image(systemName: emoji)
////                                .foregroundStyle(budget.category?.color ?? .primary)
////                                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
////                                .frame(minWidth: labelWidth, alignment: .center)
////                                .maxViewWidthObserver()
////                        } else {
////                            Circle()
////                                .fill(budget.category?.color ?? .primary)
////                                .frame(width: 12, height: 12)
////                                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
////                        }
////
//////                        Circle()
//////                            .fill(budget.category?.color ?? .primary)
//////                            .frame(width: 12, height: 12)
//////                            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
////
////                        VStack(alignment: .leading) {
////                            HStack {
////                                Text(budget.category?.title ?? "-")
////                                Spacer()
////                            }
////                            .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
////
////                            HStack {
////                                Text("Budget:")
////                                Spacer()
////                                Text(budget.amount.currencyWithDecimals())
////                            }
////                            .foregroundStyle(.gray)
////                            .font(.caption)
////
////
////                            HStack {
////                                Text("Expenses:")
////                                Spacer()
////                                let expenses = calModel.sMonth.justTransactions
////                                    .filter { $0.isBudgetable && $0.isExpense && $0.factorInCalculations }
////                                    .filter { $0.category?.id == budget.category?.id }
////                                    .map { $0.amount }
////                                    .reduce(0.0, +)
////
////                                Text(abs(expenses).currencyWithDecimals())
////                            }
////                            .foregroundStyle(.gray)
////                            .font(.caption)
////
////
////                            HStack {
////                                Text("Income:")
////                                Spacer()
////                                let income = calModel.sMonth.justTransactions
////                                    .filter { $0.isBudgetable && $0.isIncome && $0.factorInCalculations }
////                                    .filter { $0.category?.id == budget.category?.id }
////                                    .map { $0.amount }
////                                    .reduce(0.0, +)
////
////                                Text(abs(income).currencyWithDecimals())
////                            }
////                            .foregroundStyle(.gray)
////                            .font(.caption)
////
////
////
////                            HStack {
////                                Text("Over/Under:")
////                                Spacer()
////                                let expenses = calModel.sMonth.justTransactions
////                                    .filter { $0.isBudgetable && $0.isExpense && $0.factorInCalculations }
////                                    .filter { $0.category?.id == budget.category?.id }
////                                    .map { $0.amount }
////                                    .reduce(0.0, +)
////
////                                let income = calModel.sMonth.justTransactions
////                                    .filter { $0.isBudgetable && $0.isIncome && $0.factorInCalculations }
////                                    .filter { $0.category?.id == budget.category?.id }
////                                    .map { $0.amount }
////                                    .reduce(0.0, +)
////
////                                let overUnder = budget.amount + (expenses + income)
////
////                                Text(abs(overUnder).currencyWithDecimals())
////                                    .foregroundStyle(overUnder < 0 ? .red : (overUnder > budget.amount ? .green : .primary) )
////                            }
////                            .foregroundStyle(.gray)
////                            .font(.caption)
////                        }
////                    }
////                    .rowBackgroundWithSelection(id: budget.id, selectedID: budgetEditID)
//                }
//                .listStyle(.plain)
//                
//            }
//            //.padding(.horizontal, 20)
//            .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
//        }
//    }
//    #endif
//    
//    
//    var theChart: some View {
//        VStack {
//            if chartMode == .verticalBar {
//                verticalBarChart
//                    //.frame(height: 800)
//            } else {
//                pieChart
//            }
//        }
//    }
//    
//    
//    
//    var verticalBarChart: some View {
//        
//        VStack {
//            Chart {
//                ForEach(categoryBudget.filter { $0.expenses < 0 || $0.income > 0 }) { item in
////                    BarMark(
////                        x: .value("Budget", item.category.title),
////                        y: .value("Amount", (item.expenses + item.income) * -1), // Flip the symbols
////                        width: .ratio(0.6)
////                    )
////                    .foregroundStyle(item.category.color)
////                    .clipShape(RoundedRectangle(cornerRadius: 8))
////
////                    RectangleMark(
////                        x: .value("Budget", item.category.title),
////                        y: .value("Amount", item.budget),
////                        width: .ratio(0.6),
////                        height: 4
////                    )
////                    .foregroundStyle(.gray)
////                    .clipShape(RoundedRectangle(cornerRadius: 8))
////
//                    let budgetBarAmount = item.budget - ((item.expenses + item.income) * -1) < 0 ? 0 : item.budget - ((item.expenses + item.income) * -1)
//                    
//                    
//                    if ((item.expenses + item.income) * -1) > 0 {
//                        BarMark(
//                            x: .value("Amount", (item.expenses + item.income) * -1),
//                            y: .value("Budget", item.category.title)
//                            //width: .ratio(0.6)
//                        )
//                        
//                        .foregroundStyle(
//                            selectedBudget == nil
//                            ? item.category.color
//                            : selectedBudget == item.category.title ? item.category.color : .gray.opacity(0.5)
//                        )
//                        //.cornerRadius(5)
//                        //.clipShape(RoundedRectangle(cornerRadius: 8))
//                    }
//                    
//                    BarMark(
//                        x: .value("Amount", budgetBarAmount),
//                        y: .value("Budget", item.category.title)
//                        //width: .ratio(0.6)
//                    )
//                    .foregroundStyle(
//                        selectedBudget == nil
//                        ? item.category.color.opacity(0.5)
//                        : selectedBudget == item.category.title ? item.category.color.opacity(0.5) : .gray.opacity(0.5)
//                    )
//                 
//                }
//                
//                if let selectedBudget {
//                    let position = categoryBudget.filter { $0.category.title == selectedBudget }.first?.overlayPosition
//                    let budget = categoryBudget.filter { $0.category.title == selectedBudget }.first?.budget
//                    let expenses = categoryBudget.filter { $0.category.title == selectedBudget }.first?.expenses
//                    let income = categoryBudget.filter { $0.category.title == selectedBudget }.first?.income
//                    let category = categoryBudget.filter { $0.category.title == selectedBudget }.first?.category
//                    
//                    if let position, let budget, let expenses, let category, let income {
//                        
//                        //let expenseAmount = (expenses + income) * -1
//                        //let budgetBarAmount = budget - ((expenses + income) * -1) < 0 ? 0 : budget - ((expenses + income) * -1)
//                        
//                        BarMark(
//                            x: .value("Amount", 20),
//                            y: .value("Budget", selectedBudget), height: .ratio(1)
//                        )
//                        .foregroundStyle(.clear)
//                        .annotation(
//                            position: .trailing,
//                            alignment: .leading,
//                            spacing: 0,
//                            overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
//                        ) {
//                            VStack(alignment: .leading) {
//                                HStack {
//                                    Text(selectedBudget.capitalized)
//                                    Spacer()
//                                    
//                                    ChartCircleDot(
//                                        budget: budget,
//                                        expenses: abs(expenses),
//                                        color: colorScheme == .dark ? .white : .black,
//                                        size: 20
//                                    )
//                                    
//                                    Image(systemName: category.emoji ?? "circle")
//                                    
//                                    
////                                    Chart {
////                                        if abs(expenses) < abs(budget) {
////                                            SectorMark(angle: .value("Budget", abs(budget - abs(expenses))))
////                                                .foregroundStyle(category.color)
////                                                .cornerRadius(8)
////                                                .opacity(0.3)
////                                        }
////                                        SectorMark(angle: .value("Expenses", abs(expenses)))
////                                            .foregroundStyle(category.color.gradient)
////                                            .cornerRadius(8)
////                                            .opacity(1)
////                                    }
////                                    .frame(width: 22, height: 22)
//                                    
//                                    
//                                    
//                                    
//                                }
//                                .font(.headline)
//                                
//                                Divider()
//                                Text("Budget: \(budget.currencyWithDecimals(2))")
//                                    .bold()
//                                Text("Expenses: \((expenses * -1).currencyWithDecimals(2))")
//                                    .bold()
//                            }
//                            //.padding()
//                            //.background(Color.annotationBackground)
//                            
//                            .foregroundStyle(.white)
//                            .padding(12)
//                            .frame(width: 180)
//                            .background(
//                                RoundedRectangle(cornerRadius: 10)
//                                    //.fill(Color.annotationBackground)
//                                    .fill(category.color)
//                                    //.fill(category.color.shadow(.drop(color: .black, radius: 10))/*.gradient*/)
//                            )
//                        }
//                        .accessibilityHidden(true)
//                    }
//                }
//            }
////            #if os(macOS)
////            .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 20)) }
////            #else
////            .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 10)) }
////            #endif
//            .chartYSelection(value: $selectedBudget.animation())
//            //.chartScrollableAxes(.horizontal)
//            .chartScrollTargetBehavior(.valueAligned(unit: 1))
//            //.chartXVisibleDomain(length: 5)
//            
//            HStack {
//                HStack(spacing: 5) {
//                    RoundedRectangle(cornerRadius: 8)
//                        .fill(Color.gray.opacity(0.6))
//                        .frame(maxWidth: 12, maxHeight: 4) // 8 seems to be the default from charts
//                    Text("Budget")
//                        .foregroundStyle(Color.secondary)
//                        .font(.subheadline)
//                }
//                
//                HStack(spacing: 5) {
//                    RoundedRectangle(cornerRadius: 2)
//                        //.fill(Color.gray)
//                        .fill(AngularGradient(gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red]), center: .center))
//                        .frame(maxWidth: 12, maxHeight: 12) // 8 seems to be the default from charts
//                    Text("Expenses")
//                        .foregroundStyle(Color.secondary)
//                        .font(.subheadline)
//                }
//                Spacer()
//            }
//        }
//    }
//    
////    var verticalBarChart1: some View {
////        Chart {
////            ForEach(categoryBudget) { item in
////                ForEach(item.data) { metric in
////                    BarMark(
////                        x: .value("Budget", item.category.title),
////                        y: .value("Amount", abs(metric.amount)),
////                        width: metric.title == "Budget" ? .ratio(0.7) : .ratio(0.6),
////                        stacking: .unstacked
////                    )
////                    .foregroundStyle(item.category.color.opacity(metric.title == "Budget" ? 0.8 : 1))
////
////                    //.foregroundStyle(by: .value("Category", metric.title))
////                    //.position(by: .value("Category", metric.title))
////                }
////            }
////
////            if let selectedBudget {
////                let position = categoryBudget.filter { $0.category.title == selectedBudget }.first?.overlayPosition
////                let budget = categoryBudget.filter { $0.category.title == selectedBudget }.first?.data[0].amount
////                let expenses = categoryBudget.filter { $0.category.title == selectedBudget }.first?.data[1].amount
////
////                if let position, let budget, let expenses {
////                    RectangleMark(x: .value("Budget", selectedBudget), width: .ratio(1))
////                        .foregroundStyle(.gray.opacity(0.2))
////                        .annotation(position: position, alignment: .center, spacing: 0) {
////                            VStack(alignment: .leading) {
////                                Text(selectedBudget.capitalized)
////                                    .font(.headline)
////                                Divider()
////                                Text("Budget: \(budget.currencyWithDecimals(2))")
////                                Text("Expenses: \(abs(expenses).currencyWithDecimals(2))")
////                            }
////                            .padding()
////                            .background(Color.annotationBackground)
////                        }
////                        .accessibilityHidden(true)
////                }
////            }
////        }
////        //.chartYScale(domain: [0, 100])
////        #if os(macOS)
////        .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 20)) }
////        #else
////        .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 10)) }
////        #endif
////        .chartXSelection(value: $selectedBudget)
//////        #if os(macOS)
//////        .chartOverlay { chartProxy in
//////            Color.clear
//////                .onContinuousHover {
//////                    switch $0 {
//////                    case .active(let hoverLocation):
//////                        selectedBudget = chartProxy.value(atX: hoverLocation.x, as: String.self)
//////                    case .ended:
//////                        selectedBudget = nil
//////                    }
//////                }
//////        }
//////        #endif
////    }
//    
//    var pieChart: some View {
//        VStack(spacing: 8) {
//            Chart {
//                ForEach(categoryBudget) { item in
//                    SectorMark(angle: .value("Expenses", abs(item.expenses)), innerRadius: .ratio(0.7), angularInset: 2.0)
//                        .foregroundStyle(item.category.color)
//                        .cornerRadius(8)
//                        .opacity(selectedBudget == nil ? 1 : (item.category.title == selectedBudget ? 1 : 0.3))
//                }
//            }
//            .chartAngleSelection(value: $selectedAngle.animation())
//            .onChange(of: selectedAngle) { old, new in
//                if let new {
//                    var cum: Double = 0
//                    let _ = categoryBudget.first {
//                        cum += abs($0.expenses)
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
//                            let budget = categoryBudget.filter { $0.category.title == selectedBudget }.first?.budget
//                            let expenses = categoryBudget.filter { $0.category.title == selectedBudget }.first?.expenses
//                            let category = categoryBudget.filter { $0.category.title == selectedBudget }.first?.category
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
//                            let expenses = categoryBudget.map { abs($0.expenses) }.reduce(0.0, +)
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
//                        ForEach(categoryBudget.filter { $0.expenses < 0 || $0.income > 0 }) { item in
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
//                                        let expenses = categoryBudget.filter { $0.category.title == item.category.title }.first?.expenses
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
//    //                                    selectedBudget = item.category.title
//    //                                case .ended:
//    //                                    selectedBudget = nil
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
//}
