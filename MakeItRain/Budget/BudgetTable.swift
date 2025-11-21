//
//  BudgetTable.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/18/25.
//

import SwiftUI

struct BudgetTable: View {
    @Local(\.categorySortMode) var categorySortMode
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Environment(\.dismiss) var dismiss
    @Environment(CalendarModel.self) private var calModel
    @Environment(CategoryModel.self) private var catModel

    
    @State private var budgetEditID: CBBudget.ID?
    @State private var editBudget: CBBudget?
    @State private var labelWidth: CGFloat = 20.0
    
    @State private var searchText = ""
    
    var filteredBudgets: Array<CBBudget> {
        if searchText.isEmpty {
            return calModel.sMonth.budgets
                .filter { budget in
                    guard budget.category != nil else { return false }
                    if budget.category!.isHidden { return false }
                    if budget.category!.isNil { return false }
                    return true
                }
                .sorted(by: Helpers.budgetSorter())
        } else {
            return calModel.sMonth.budgets
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

    
    var body: some View {
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                Section("Budgets for \(calModel.sMonth.name) \(String(calModel.sMonth.year))") {
                    bodyPhone
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
                ToolbarItem(placement: .topBarTrailing) { closeButton }
                #else
                ToolbarItem(placement: .primaryAction) { closeButton }
                #endif
                
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                ToolbarSpacer(.flexible, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) { CategorySortMenu() }
            }
            .onChange(of: budgetEditID) { oldValue, newValue in
                if let newValue {
                    editBudget = calModel.sMonth.budgets.filter { $0.id == newValue }.first!
                } else if newValue == nil && oldValue != nil {
                    let budget = calModel.sMonth.budgets.filter { $0.id == oldValue! }.first!
                    Task {
                        if budget.hasChanges() || budget.action == .add {
                            await calModel.submit(budget)
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
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
    }
    
    var bodyPhone: some View {
        ForEach(filteredBudgets) { budget in
            if let cat = budget.category {
                HStack {
                    //StandardCategoryLabel(cat: cat, labelWidth: labelWidth, showCheckmarkCondition: false)
                    
                    ChartCircleDot(
                        budget: budget.amount,
                        expenses: getExpenseAmount(for: cat),
                        color: cat.color,
                        size: 22
                    )
                    Text(cat.title)
                    
                    Spacer()
                    Text(budget.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    budgetEditID = budget.id
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
}
