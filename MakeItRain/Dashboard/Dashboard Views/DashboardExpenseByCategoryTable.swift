//
//  DashboardExpenseByCategoryTable.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

struct DashboardExpenseByCategoryTable: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: DashboardModel
    @Binding var navPath: [NavDest]
    var isForSelectedMonth: Bool
    
    var body: some View {
        VStack {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                gridHeader
                
                Divider()
                
                ForEachWithSeparator(model.data.categoryGroups, includeLastSeparator: !model.data.categories.isEmpty) { group in
                    GridRow {
                        HStack {
                            GradientCircleDot(size: 12, colors: group.categories.map(\.color))
                            Text(group.title)
                        }

                        Text(group.budgetAmount.currencyWithDecimals())
                        
                        Text((model.shouldUseTotalSpending ? group.allAmounts?.totalSpend : group.allAmounts?.actualSpend)?.currencyWithDecimals() ?? "N/A")
                        
                        if model.shouldUseTotalSpending {
                            Text(group.allAmounts?.irregularIncome.currencyWithDecimals() ?? "N/A")
                        }

                        Text(abs(group.allAmounts?.variance ?? 0).currencyWithDecimals())
                            .foregroundStyle(group.allAmounts?.variance ?? 0 < 0 ? .red : .green)
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 5)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            if isForSelectedMonth {
                                if let budget = calModel.sMonth.budgets.filter({ $0.type == .categoryGroup && $0.item?.id == group.id }).first {
                                    navPath.append(NavDest.budgetOverview(budget))
                                } else {
                                    print("No category budget found for group with id: \(group.id)")
                                    AppState.shared.showAlert("No budget exists for this category. Please create a new one.")
                                }
                            } else {
                                group.isExpanded.toggle()
                            }
                        }
                    }
                    
                    if group.isExpanded {
                        Divider()
                        ForEachWithSeparator(group.categories.sorted(by: Helpers.categorySorter())) { cat in
                            line(for: cat, isPartOfGroup: true)
                        } separator: {
                            Divider()
                                .padding(.leading, 10)
                        }
                    }
                }
                
                ForEachWithSeparator(
                    model.data.categories
                        .filter { model.shouldUseTotalSpending ? true : !$0.isIncome }
                        .sorted(by: Helpers.categorySorter())
                ) { cat in
                    line(for: cat, isPartOfGroup: false)
                    
                }
            }
            .font(.caption)
            .lineLimit(1)
            .textCase(nil)
        }
        .task {
            model.data.categoryGroups.forEach { print("\($0.title) - \($0.budgetAmount)")}
        }
    }
    

    var gridHeader: some View {
        GridRow {
            HStack {
                ChartCircleDot(budget: 0, expenses: 0, color: .primary, size: 12)
                Text("Category")
            }

            Text("Budget")
            Text("Spending")
            if model.shouldUseTotalSpending {
                Text("Money In")
            }
            Text("Variance")
            Text("")
        }
        .font(.caption)
        .bold()
    }
    
    
    @ViewBuilder
    func line(for cat: CBCategory, isPartOfGroup: Bool) -> some View {
        GridRow {
            HStack {
                ChartCircleDot(
                    budget: cat.isIncome ? 100 : cat.budgetAmount,
                    expenses: cat.isIncome ? 100 : (model.shouldUseTotalSpending ? cat.allAmounts?.totalSpend ?? 0 : cat.allAmounts?.actualSpend ?? 0),
                    color: cat.color,
                    size: 12
                )

                Text(cat.title)
            }
            .padding(.leading, isPartOfGroup ? 10 : 0)

            let value1 = cat.isIncome || isPartOfGroup ? "N/A" : cat.budgetAmount.currencyWithDecimals()
            Text(value1)
                .foregroundStyle(isPartOfGroup || cat.isIncome ? .gray : .primary)
                .contentTransition(.numericText())
            
            
            //(model.shouldUseTotalSpending ? cat.allAmounts?.totalSpend : cat.allAmounts?.actualSpend)
            
            let value2 = cat.isIncome ? "N/A" : ((model.shouldUseTotalSpending ? cat.allAmounts?.totalSpend : cat.allAmounts?.actualSpend) ?? 0).currencyWithDecimals()
            Text(value2)
                .foregroundStyle(value2 == "N/A" ? .gray : .primary)
                .contentTransition(.numericText())

            if model.shouldUseTotalSpending {
                let value3 = cat.isRegularIncome
                    ? (cat.allAmounts?.regularIncome ?? 0.0).currencyWithDecimals()
                    : (cat.allAmounts?.irregularIncome ?? 0.0).currencyWithDecimals()

                Text(value3)
                    .contentTransition(.numericText())
            }
                    
            let variance = cat.allAmounts?.variance ?? 0.0

            Text(isPartOfGroup || cat.isIncome ? "N/A" : abs(variance).currencyWithDecimals())
                .foregroundStyle(isPartOfGroup || cat.isIncome ? .gray : (variance < 0 ? .red : .green))
                .contentTransition(.numericText())
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                if isForSelectedMonth {
                    if let budget = calModel.sMonth.budgets.filter({ $0.type == .category && $0.item?.id == cat.id }).first {
                        //BudgetOverview(budget: budget, location: .monthList)
                        navPath.append(NavDest.budgetOverview(budget))
                    }
                } else {
                    navPath.append(.dashboardTransactionList(model.data, cat))
                }
            }
        }
    }
}
