//
//  BudgetBreakdownView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/8/25.
//

import SwiftUI

struct BudgetBreakdownView: View {
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Environment(CalendarModel.self) private var calModel
    
    let columnGrid = Array(repeating: GridItem(.flexible(), spacing: 0), count: 5)
    
    var chartData: Array<ChartData>
    var calculateDataFunction: () async -> Void
    
    @State private var budgetEditID: CBBudget.ID?
    @State private var editBudget: CBBudget?
    
    
    var body: some View {
        content
    }
    
    var content: some View {
        Grid(alignment: .leading) {
            GridRow {
                HStack {
                    ChartCircleDot(
                        budget: 0,
                        expenses: 0,
                        color: .primary,
                        size: 12
                    )
                    //.alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                    
                    Text("Category")
                        //.alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                }
                
                Text("Budget")
                Text("Expense")
                Text("Income")
                Text("Variance")
            }
            .font(.caption)
            
            Divider()
                .gridCellUnsizedAxes(.horizontal)
            
            ForEach(chartData, id: \.id) { metric in
                GridRow {
                    Group {
                        HStack {
                            ChartCircleDot(
                                budget: metric.budget,
                                expenses: metric.expenses,
                                color: metric.category.color,
                                size: 12
                            )
                            //.alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                            
                            Text(metric.category.title)
                                //.alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(metric.budget.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                            
                        Text((metric.expenses == 0 ? 0 : metric.expenses * -1 - metric.income).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                                                    
                        Text((metric.income).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                                                    
                        let overUnder = metric.budget + (metric.expenses + metric.income)
                        Text(abs(overUnder).currencyWithDecimals(useWholeNumbers ? 0 : 2))
                            .foregroundStyle(overUnder < 0 ? .red : .green)
                            //.frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
//                    .onTapGesture {
//                        if let objc = metric.budgetObjects?.first {
//                            //print("OnTap for \(objc.month)-\(objc.year)")
//                            budgetEditID = objc.id
//                        } else {
//                            AppState.shared.showAlert("No budget currently exists for \(metric.category.title). Please create via the populate screen.")
//                            
//                            //#warning("Smonth will contains budgets that don't belong to it")
//                            //print("OnTap Budget does not exist for \(metric.category.title)")
//                            //print("budgets in Smonth \(calModel.sMonth.actualNum) \(calModel.sMonth.year) vvvv")
//                            //print(calModel.sMonth.budgets.map {"\(String(describing: $0.category?.id)) \($0.month) \($0.year)"})
//                            
//                            
//                            //createBudget(for: metric.category)
//                        }
//                    }
                }
                .font(.caption)
                
                Divider()
                    .gridCellUnsizedAxes(.horizontal)
            }
        }
        /// NOTE: The sheet HAS to be attached to the grid.
        /// If not, it will cause an "open and immediately dismiss" issue.
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
            Task {
                await calculateDataFunction()
            }
            
        }) { budget in
            BudgetEditView(budget: budget, calModel: calModel)
                //.presentationSizing(.page)
        }
    }
}
