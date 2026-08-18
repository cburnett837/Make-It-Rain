//
//  BudgetTable.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/18/25.
//

import SwiftUI

struct VariableSizeCircularStyle: GaugeStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .stroke(.primary.opacity(0.5), lineWidth: 4)
            Circle()
                .trim(to: configuration.value)
                .stroke(.primary, style: .init(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            configuration.currentValueLabel
        }
    }
}

extension GaugeStyle where Self == VariableSizeCircularStyle {
    static var variableSizeCircular: VariableSizeCircularStyle { .init() }
}

struct MonthlyBudgetTable: View {
    @Environment(\.dismiss) var dismiss
    @Environment(CalendarModel.self) private var calModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(BudgetModel.self) private var budgetModel
    
    @State private var populateModel = PopulateOptions()
    @State private var budgetItemEditId: CBBudgetItem.ID?
    //@State private var editBudgetItem: CBBudgetItem?
    
    //@State private var budgetEditId: Int?
    @State private var editBudget: CBMonth?
    
    //@State private var budgetGroupEditID: CBBudgetItemGroup.ID?
    //@State private var editBudgetItemGroup: CBBudgetItemGroup?
    
    @State private var labelWidth: CGFloat = 20.0
    
    @State private var searchText = ""
    @State private var cumTotals: [BudgetCumTotal] = []
    @State private var transactions: [CBTransaction] = []

//
//    var filteredBudgets: Array<CBBudgetItem> {
//        if searchText.isEmpty {
//            return calModel.sMonth.budgets
//                //.filter { $0.category != nil }
//                .filter { budget in
//                    guard budget.category != nil else { return false }
//                    if budget.category!.isHidden { return false }
//                    if budget.category!.isNil { return false }
//                    return true
//                }
//                .sorted(by: Helpers.budgetSorter())
//        } else {
//            return calModel.sMonth.budgets
//                //.filter { $0.category != nil }
//                .filter { budget in
//                    guard budget.category != nil else { return false }
//                    if budget.category!.title.localizedCaseInsensitiveContains(searchText) && !budget.category!.isHidden && !budget.category!.isNil {
//                        return true
//                    }
//                    return false
//                }
//                .sorted(by: Helpers.budgetSorter())
//        }
//    }
//    
    
    
    func filteredBudgets(for type: BudgetItemType) -> Array<CBBudgetItem> {
        return calModel.sMonth.budgets
            .filter {
                if let cat = $0.category {
                    return cat.isIncome == false
                } else {
                    return true
                }   
            }
            .filter { $0.type == type }
            .filter {
                if let item = $0.item {
                    return searchText.isEmpty ? true : item.title.localizedCaseInsensitiveContains(searchText)
                } else {
                    return true
                }
                
            }
            .sorted(by: Helpers.budgetSorter())
    }
    
    
//    var filteredBudgetGroups: Array<CBBudgetItem> {
//        if searchText.isEmpty {
//            return calModel.sMonth.budgets
//                .filter { $0.categoryGroup != nil }
//                .filter { budget in
//                    guard budget.categoryGroup != nil else { return false }
////                    if budget.category!.isHidden { return false }
////                    if budget.category!.isNil { return false }
//                    return true
//                }
//                .sorted(by: Helpers.budgetSorter())
//        } else {
//            return calModel.sMonth.budgets
//                .filter { $0.categoryGroup != nil }
//                .filter { budget in
////                    guard budget.category != nil else { return false }
//                    if budget.categoryGroup!.title.localizedCaseInsensitiveContains(searchText) {
//                        return true
//                    }
//                    return false
//                }
//                .sorted(by: Helpers.budgetSorter())
//        }
//    }

    
    //@State private var totalExpenses: Double = 0
    
    var totalExpenses: Decimal {
        let trans = calModel.getTransactions()
            .filter { $0.dateComponents?.month == calModel.sMonth.actualNum }
            .filter { $0.dateComponents?.year == calModel.sMonth.year }
        return TransactionHelper.All.Amount.actualSpend(from: trans)
        //TransactionHelper.getSpend(from: transactions) - TransactionHelper.getSpendMinusIncome(from: transactions)
//        transactions
//            .filter { !$0.isPaymentDest }
//            .map { ($0.payMethod?.isCreditOrLoan ?? false) ? $0.amount : $0.amount * -1 }
//            .reduce(0.0, +)
    }
    
    
    var body: some View {
        if AppState.shared.isIphone {
            content
        } else {
            NavigationStack {
                content
            }
        }
    }
    
    
    @ViewBuilder
    var content: some View {
        @Bindable var calModel = calModel
        Group {
            if filteredBudgets(for: .category).isEmpty && filteredBudgets(for: .categoryGroup).isEmpty {
                ContentUnavailableView {
                    Text("No Budget")
                } description: {
                    Text("A budget has not been created for \(calModel.sMonth.prettyName). Please create one below.")
                } actions: {
                    Button("Create Budget") {
                        populateModel.budget = true
                        calModel.populate(
                            options: populateModel,
                            repTransactions: [],
                            //categories: catModel.categories,
                            //categoryGroups: catModel.categoryGroups
                        )
                    }
                    #if os(iOS)
                    .buttonStyle(.glassProminent)
                    #endif
                }
            } else {
                StandardContainerWithToolbar(.list) {
                    bodyPhone
                }
                .searchable(text: $searchText, prompt: Text("Search"))
                .toolbar {
                    #if os(iOS)
                    if AppState.shared.isIpad {
                        ToolbarItem(placement: .topBarTrailing) { closeButton }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            editBudget = calModel.sMonth
                        } label: {
                            Text("Edit")
                                .schemeBasedForegroundStyle()
                        }
                    }
                    
                    ToolbarSpacer(.flexible, placement: .topBarTrailing)
                                        
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            AppState.shared.showAlert("This feature is not yet available.")
                        } label: {
                            Image(systemName: "plus")
                                .schemeBasedForegroundStyle()
                        }
                    }
                    
                    
                    
                    DefaultToolbarItem(kind: .search, placement: .bottomBar)
                    ToolbarSpacer(.flexible, placement: .bottomBar)
                    ToolbarItem(placement: .bottomBar) { CategorySortMenu() }
                    #else
                    ToolbarItem(placement: .primaryAction) { closeButton }
                    #endif
                }
            }
        }
        .task {
            prepareData(calModel: calModel)
        }
        .navigationTitle("Budget")
        .navigationSubtitle("\(calModel.sMonth.name) \(String(calModel.sYear))")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(item: $editBudget, onDismiss: {
            if calModel.sMonth.hasChanges() {
                Task {
                    await budgetModel.submit(calModel.sMonth)
                }
            }
        }) { budgetId in
            MonthlyBudgetEditView(month: calModel.sMonth)
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
    }
    
    
    @ViewBuilder
    var bodyPhone: some View {
        @Bindable var calModel = calModel
        
        Section {
            Button {
                editBudget = calModel.sMonth
            } label: {
                BudgetChart(budgetAmount: calModel.sMonth.amount, expenseAmount: totalExpenses)
            }
        } header: {
            Text("\(calModel.sMonth.name)'s Budget - \(calModel.sMonth.amount.currencyWithDecimals())")
        } footer: {
            Text("Touch to edit")
        }

        
        
//        Section("Cumulative Spending") {
//            BudgetCumSpendingChart(budgetAmount: calModel.sMonth.amount, cumTotals: cumTotals)
//        }
//        Section("Spending By Day") {
//            BudgetByDayChart(transactions: transactions)
//        }
                                
        ForEach(BudgetItemType.allCases.filter({ $0 != .tag }), id: \.self) { type in
            Section(type.sectionHeaderText) {
                let budgets = filteredBudgets(for: type)
                if budgets.isEmpty {
                    Text("No budgets")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(budgets) { budget in
                        NavigationLink(value: NavDest.budgetOverview(budget)) {
                            Label {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(budget.item?.title ?? "N/A")
                                        Spacer()
                                        Text(budget.amount.currencyWithDecimals())
                                    }
                                }
                            } icon: {
                                switch budget.type {
                                case .category:
                                    if let cat = budget.category {
                                        ChartCircleDot(
                                            budget: budget.amount,
                                            expenses: getExpenseAmount(for: cat),
                                            color: cat.color,
                                            size: 20
                                        )
                                    }
                                    
                                case .categoryGroup:
                                    if let group = budget.categoryGroup {
                                        let colors = group.categories.filter({ $0.active }).sorted(by: Helpers.categorySorter()).map { $0.color }
                                        GradientCircleDot(colors: colors)
                                    }
                                    
                                case .tag:
                                    EmptyView()
                                }
                                
                            }
                        }
    //
    //                    .contentShape(Rectangle())
    //                    .onTapGesture {
    //                        budgetItemEditId = budget.id
    //                    }
                    }
                }
                
            }
        }
        
        
//        Section("Budget Groups") {
//            ForEach(filteredBudgetGroups) { budget in
//                if let group = budget.categoryGroup {
//                    Label {
//                        VStack(alignment: .leading) {
//                            HStack {
//                                Text(group.title)
//                                Spacer()
//                                Text(budget.amount.currencyWithDecimals())
//                            }
//                        }
//                    } icon: {
//                        let colors = group.categories.filter({ $0.active }).sorted(by: Helpers.categorySorter()).map { $0.color }
//                        GradientCircleDot(colors: colors)
//                    }
//                    .contentShape(Rectangle())
//                    .onTapGesture {
//                        budgetItemEditId = budget.id
//                    }
//                }
//            }
//        }
//        
//        Section("Budgets") {
//            ForEach(filteredBudgets) { budget in
//                if let cat = budget.category {
//                    
//                    Label {
//                        VStack(alignment: .leading) {
//                            HStack {
//                                Text(cat.title)
//                                Spacer()
//                                Text(budget.amount.currencyWithDecimals())
//                            }
//                        }
//                    } icon: {
//                        ChartCircleDot(
//                            budget: budget.amount,
//                            expenses: getExpenseAmount(for: cat),
//                            color: cat.color,
//                            size: 20
//                        )
//                    }
//                    .contentShape(Rectangle())
//                    .onTapGesture {
//                        budgetItemEditId = budget.id
//                    }
//                    
////                    Gauge(value: display, in: 0...budget.amount) {
////                            Text("hey")
////                        }
////                        .gaugeStyle(.variableSizeCircular)
////                        .foregroundStyle(cat.color)
////                        .frame(width: 30, height: 30)
//
////                        .gaugeStyle(.accessoryCircularCapacity)
////                        .tint(cat.color)
////                        .scaleEffect(0.5)
//                }
//            }
//        }
    }
    
//    var newBudgetButton: some View {
//        Button {
//            budgetItemEditId = UUID().uuidString
//        } label: {
//            Image(systemName: "plus")
//        }
//        .tint(.none)
//    }
    
    
    
    func getExpenseAmount(for category: CBCategory) -> Decimal {
        calModel.getTransactions()
            .filter { ($0.payMethod?.isPermitted ?? true) }
            .filter { !($0.payMethod?.isHidden ?? false) }
            .filter { $0.category?.id == category.id }
            .map { ($0.payMethod ?? CBPaymentMethod()).isCreditOrLoan ? $0.amount * -1 : $0.amount }
            .reduce(0.0, +)
    }
    
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
        }
        .tint(.none)
        //.buttonStyle(.glassProminent)
    }
    
//    func prepareData() {
//        let trans = calModel.getTransactions()
//        transactions = TransactionHelper.All.Transactions.spend(from: trans)
//            .filter { $0.dateComponents?.month == calModel.sMonth.actualNum }
//            .filter { $0.dateComponents?.year == calModel.sMonth.year }
//                                
//        let newCumTotals = BudgetHelper.calculateCumTotals(
//            calModel: calModel,
//            transactions: transactions,
//            budgetAmount: calModel.sMonth.amount
//        )
//        
//        withAnimation {
//            self.cumTotals = newCumTotals
//        }
//    }
    
    
    @MainActor
    func prepareData(calModel: CalendarModel) {
        let month = calModel.sMonth.actualNum
        let year = calModel.sMonth.year
        let budgetAmount = calModel.sMonth.amount

        let trans = calModel.getTransactions()
        let days = calModel.sMonth.days

        let filteredTransactions = trans//TransactionHelper.All.Transactions.spend(from: trans)
            .filter {
                $0.dateComponents?.month == month &&
                $0.dateComponents?.year == year
            }

        self.transactions = filteredTransactions

        Task {
            let newCumTotals = await Task.detached(priority: .userInitiated) {
                await BudgetHelper.calculateCumTotals(
                    days: days,
                    transactions: filteredTransactions,
                    budgetAmount: budgetAmount,
                    type: .spend
                )
            }.value

            await MainActor.run {
                withAnimation {
                    self.cumTotals = newCumTotals
                }
            }
        }
    }
    
    
    func getReversedColors(_ categories: Array<CBCategory>) -> Array<Gradient.Stop> {
         let colors = categories
            .filter({ $0.active })
            .sorted(by: Helpers.categorySorter())
            .map {$0.color}
        
        
        let count = colors.count
        let step = 1.0 / Double(count)
        let epsilon = 0.00001

        // For sharp edges, we give each color two stops: start and end.
        let stops: [Gradient.Stop] = colors.enumerated().flatMap { index, color in
            let start = Double(index) * step
            let end = start + step - epsilon // Slightly before the next color's start
            return [
                Gradient.Stop(color: color, location: start),
                Gradient.Stop(color: color, location: end)
            ]
        }
        
        return stops
    }
}
