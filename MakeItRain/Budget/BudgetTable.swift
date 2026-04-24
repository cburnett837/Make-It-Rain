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

struct BudgetTable: View {
    @Environment(\.dismiss) var dismiss
    @Environment(CalendarModel.self) private var calModel
    @Environment(CategoryModel.self) private var catModel
    
    @State private var budgetEditID: CBBudget.ID?
    @State private var editBudget: CBBudget?
    
    //@State private var budgetGroupEditID: CBBudgetGroup.ID?
    //@State private var editBudgetGroup: CBBudgetGroup?
    
    @State private var labelWidth: CGFloat = 20.0
    
    @State private var searchText = ""
    
    var filteredBudgets: Array<CBBudget> {
        if searchText.isEmpty {
            return calModel.sMonth.budgets
                //.filter { $0.category != nil }
                .filter { budget in
                    guard budget.category != nil else { return false }
                    if budget.category!.isHidden { return false }
                    if budget.category!.isNil { return false }
                    return true
                }
                .sorted(by: Helpers.budgetSorter())
        } else {
            return calModel.sMonth.budgets
                //.filter { $0.category != nil }
                .filter { budget in
                    guard budget.category != nil else { return false }
                    if budget.category!.title.localizedCaseInsensitiveContains(searchText) && !budget.category!.isHidden && !budget.category!.isNil {
                        return true
                    }
                    return false
                }
                .sorted(by: Helpers.budgetSorter())
        }
    }
    
    
    var filteredBudgetGroups: Array<CBBudget> {
        if searchText.isEmpty {
            return calModel.sMonth.budgets
                .filter { $0.categoryGroup != nil }
                .filter { budget in
                    guard budget.categoryGroup != nil else { return false }
//                    if budget.category!.isHidden { return false }
//                    if budget.category!.isNil { return false }
                    return true
                }
                .sorted(by: Helpers.budgetSorter())
        } else {
            return calModel.sMonth.budgets
                .filter { $0.categoryGroup != nil }
                .filter { budget in
//                    guard budget.category != nil else { return false }
                    if budget.categoryGroup!.title.localizedCaseInsensitiveContains(searchText) {
                        return true
                    }
                    return false
                }
                .sorted(by: Helpers.budgetSorter())
        }
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
        StandardContainerWithToolbar(.list) {
            bodyPhone
            
            if !calModel.appSuiteBudgets.isEmpty {
                Section("Special Budgets for \(String(calModel.sMonth.year))") {
                    ForEach(calModel.appSuiteBudgets) { budget in
                        if let cat = budget.category {
                            HStack {
                                ChartCircleDot(
                                    budget: budget.amount,
                                    expenses: getExpenseAmount(for: cat),
                                    color: cat.color,
                                    size: 22
                                )
                                Text(cat.title)
                                
                                Spacer()
                                Text(budget.amount.currencyWithDecimals())
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                budgetEditID = budget.id
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: Text("Search"))
        .navigationTitle("Budgets")
        //.navigationSubtitle("\(calModel.sMonth.name) \(String(calModel.sYear))")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            #if os(iOS)
            if AppState.shared.isIpad {
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            DefaultToolbarItem(kind: .search, placement: .bottomBar)
            ToolbarSpacer(.flexible, placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) { CategorySortMenu() }
            #else
            ToolbarItem(placement: .primaryAction) { closeButton }
            #endif
            
            
        }
        .onChange(of: budgetEditID) { oldValue, newValue in
            if let newValue {
                if let editBudget = calModel.sMonth.budgets.first(where: { $0.id == newValue }) {
                    self.editBudget = editBudget
                } else {
                    self.editBudget = calModel.appSuiteBudgets.first(where: { $0.id == newValue })
                }
            } else if newValue == nil && oldValue != nil {
                var budget: CBBudget?
                
                if let editBudget = calModel.sMonth.budgets.first(where: { $0.id == oldValue! }) {
                    budget = editBudget
                } else {
                    budget = calModel.appSuiteBudgets.first(where: { $0.id == oldValue! })
                }
                
                if let budget = budget {
                    Task {
                        if budget.hasChanges() || budget.action == .add {
                            await calModel.submit(budget)
                        }
                    }
                }
            }
        }
        .sheet(item: $editBudget, onDismiss: {
            budgetEditID = nil
            //calculateDataFunction()
        }) { budget in
            BudgetEditView(budget: budget, calModel: calModel)
                .presentationSizing(.page)
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
    }
    
    
    @ViewBuilder
    var bodyPhone: some View {
        Section("Budget Groups for \(calModel.sMonth.name) \(String(calModel.sMonth.year))") {
            ForEach(filteredBudgetGroups) { budget in
                if let group = budget.categoryGroup {
                    Label {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(group.title)
                                Spacer()
                                Text(budget.amount.currencyWithDecimals())
                            }
                        }
                    } icon: {
                        let colors = group.categories.filter({ $0.active }).sorted(by: Helpers.categorySorter()).map { $0.color }
                        GradientCircleDot(colors: colors)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        budgetEditID = budget.id
                    }
                }
            }
        }
        
        Section("Budgets for \(calModel.sMonth.name) \(String(calModel.sMonth.year))") {
            ForEach(filteredBudgets) { budget in
                if let cat = budget.category {
                    
                    Label {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(cat.title)
                                Spacer()
                                Text(budget.amount.currencyWithDecimals())
                            }
                        }
                    } icon: {
                        ChartCircleDot(
                            budget: budget.amount,
                            expenses: getExpenseAmount(for: cat),
                            color: cat.color,
                            size: 20
                        )
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        budgetEditID = budget.id
                    }
                    
//                    Gauge(value: display, in: 0...budget.amount) {
//                            Text("hey")
//                        }
//                        .gaugeStyle(.variableSizeCircular)
//                        .foregroundStyle(cat.color)
//                        .frame(width: 30, height: 30)

//                        .gaugeStyle(.accessoryCircularCapacity)
//                        .tint(cat.color)
//                        .scaleEffect(0.5)
                }
            }
        }
    }
    
    func getExpenseAmount(for category: CBCategory) -> Double {
        calModel.sMonth.justTransactions
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
