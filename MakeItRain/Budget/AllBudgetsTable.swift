//
//  AllBudgetsTable.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/8/26.
//

import SwiftUI
import Charts


struct AllBudgetsTable: View {
    @Environment(CalendarModel.self) var calModel
    @Environment(BudgetModel.self) var budgetModel
    @Environment(AppStore.self) var store
    
    @Binding var navPath: NavigationPath

    @State private var editBudget: CBBudget?
    
    var body: some View {
        List {
            Section("Your Monthly Budget") {
                Button {
                    editBudget = store.globalBudget
                } label: {
                    HStack {
                        Text(store.globalBudget.amount.currencyWithDecimals())
                            .schemeBasedForegroundStyle()
                        Spacer()
                        Text("Edit")
                            .foregroundStyle(Color.theme)
                    }
                }
            }
            
            
            Section("Tag Budgets") {
                ForEach(budgetModel.budgets.filter {$0.item?.budgetType == .tag}) { budget in
                    //Text("#\(budget.item?.title ?? "N/A")")
                    NavigationLink(value: budget) {
                        Text("#\(budget.item?.title ?? "N/A")")
                    }
                }
            }
        }
        .listStyle(.plain)
        .toolbar {
//            ToolbarItem(placement: .topBarTrailing) {
//                editGlobalBudgetButton
//            }
            #if os(iOS)
            ToolbarSpacer(placement: .topBarTrailing)
            ToolbarItem(placement: .topBarTrailing) { ToolbarRefreshButton() }
            ToolbarItem(placement: .topBarTrailing) { newBudgetButton }
            #endif
        }
        .navigationTitle("Budget\(AppState.shared.devMode ? " (Dev)" : "")")
        .navigationDestination(for: CBBudgetItem.self) { budget in
            BudgetOverview(budget: budget, location: .globalList)
        }
        .sheet(item: $editBudget, onDismiss: {
            if store.globalBudget.hasChanges() {
                Task {
                    await budgetModel.submit(store.globalBudget)
                }
            }
        }) { budget in
            GlobalBudgetEditView(
                title: "Budget Template",
                footer: "Establish a budget that you would like to use on a per-month basis. When preparing a month, this amount will be assigned as that months budget by default. You can change this, or each month individually.",
                obj: budget,
                showCategories: true
            )
        }
    }
    
    var editGlobalBudgetButton: some View {
        Button {
            editBudget = store.globalBudget
        } label: {
            Text("Edit")
        }
        .tint(.none)
    }
    
    var newBudgetButton: some View {
        Button {
            let newId = UUID().uuidString
            navPath.append(CBBudgetItem(uuid: newId))
        } label: {
            Image(systemName: "plus")
        }
        .tint(.none)
    }
}
