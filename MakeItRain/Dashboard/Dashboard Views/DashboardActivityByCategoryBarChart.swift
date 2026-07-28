//
//  DashboardActivityByCategoryBarChart.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

struct DashboardActivityByCategoryBarChart: View {
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: DashboardModel
    @Bindable var data: DashboardData
    @Binding var selectedCategory: CBCategory?
    
    @State private var selectedRow: String?
    @State private var selectedXAmount: Decimal?
    
    enum ChartRow: String {
        case budget = "Budget"
        case spending = "Spending"
        case income = "Income"
    }
    
    var totalExpenseAmount: String {
        max(0, (model.shouldUseTotalSpending ? data.allAmounts.totalSpend : data.allAmounts.actualSpend)).currencyWithDecimals()
    }
    
    var totalIncomeAmount: String {
        max(0, (data.debitAmounts.regularIncome + data.debitAmounts.irregularIncome)).currencyWithDecimals()
    }
    
    var body: some View {
        Chart {
            if model.groups.isEmpty {
                budgetBars
            } else {
                RuleMark(
                    x: .value("Budget ", data.categoryAndGroupBudget),
                    yStart: .value("Start", "\(ChartRow.spending.rawValue) - \(totalExpenseAmount)"),
                    yEnd: .value("End", "\(ChartRow.spending.rawValue) - \(totalExpenseAmount)")
                )
                .foregroundStyle(model.isUnderBudget ? Color.green.gradient : Color.red.gradient)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                .zIndex(1)
            }
                                    
            expenseBars
            incomeBars
        }
        .frame(height: 150)
        .chartYSelection(value: $selectedRow)
        .chartXSelection(value: $selectedXAmount)
        .chartXAxis {
            AxisMarks { axisValue in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let value = axisValue.as(Double.self) {
                        Text(value.axisCurrencyLabel)
                        //Text("$\(value.kVersion)")
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .onChange(of: selectedRow) {
            updateSelectedCategoryFromBar()
        }
        .onChange(of: selectedXAmount) {
            updateSelectedCategoryFromBar()
        }
        .sensoryFeedback(.selection, trigger: selectedCategory)
        .overlay(alignment: .top) {
            if let category = selectedCategory {
                DashboardActivityByCategoryAnnotation(category: category)
            }
        }
    }
    
    @ChartContentBuilder
    var budgetBars: some ChartContent {
        ForEach(model.expenseCategories) { cat in
            BarMark(
                x: .value("Budget", max(0, cat.budgetAmount)),
                y: .value("Key", ChartRow.budget.rawValue),
                stacking: .standard
            )
            .foregroundStyle(cat.color.gradient)
            .opacity(selectedCategory == nil ? 1 : (cat.id == selectedCategory?.id ? 1 : 0.3))
            .cornerRadius(5)
        }
    }
    
        
    @ChartContentBuilder
    var expenseBars: some ChartContent {
        ForEach(model.expenseCategories) { cat in
            BarMark(
                //x: .value("Amount", max(0, cat.allAmounts?.totalSpend ?? 0.0)),
                //x: .value("Amount", max(0, (model.shouldUseTotalSpending ? cat.allAmounts?.totalSpend ?? 0 : cat.allAmounts?.actualSpend ?? 0))),
                x: .value("Amount", max(0, (model.shouldUseTotalSpending ? cat.allAmounts?.totalSpend ?? 0 : cat.allAmounts?.actualSpend ?? 0))),
                y: .value("Key", "\(ChartRow.spending.rawValue) - \(totalExpenseAmount)"),
                stacking: .standard
            )
            .foregroundStyle(cat.color.gradient)
            .opacity(selectedCategory == nil ? 1 : (cat.id == selectedCategory?.id ? 1 : 0.3))
            .zIndex(0)
            .cornerRadius(5)
        }
    }
    
    
    @ChartContentBuilder
    var incomeBars: some ChartContent {
        ForEach(model.incomeCategories) { cat in
            BarMark(
                x: .value("Amount", max(0, DashboardUtils.incomeAmount(for: cat))),
                y: .value("Key", "\(ChartRow.income.rawValue) - \(totalIncomeAmount)"),
                stacking: .standard
            )
            .foregroundStyle(cat.color.gradient)
            .opacity(selectedCategory == nil ? 1 : (cat.id == selectedCategory?.id ? 1 : 0.3))
            .zIndex(0)
            .cornerRadius(5)
        }
    }
    
    
    func updateSelectedCategoryFromBar() {
        guard let selectedRow, let selectedXAmount, let row = selectedRow.split(separator: "-").first?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            selectedCategory = nil
            return
        }
        
        switch row {
        case ChartRow.budget.rawValue:
            selectedCategory = DashboardUtils.categoryOwningXRange(
                selectedXAmount: selectedXAmount,
                categories: model.expenseCategories
            ) { cat in
                max(0, cat.budgetAmount)
            }
            
        case ChartRow.spending.rawValue:
            selectedCategory = DashboardUtils.categoryOwningXRange(
                selectedXAmount: selectedXAmount,
                categories: model.expenseCategories
            ) { cat in
                max(0, (model.shouldUseTotalSpending ? cat.allAmounts?.totalSpend ?? 0 : cat.allAmounts?.actualSpend ?? 0))
            }
            
        case ChartRow.income.rawValue:
            selectedCategory = DashboardUtils.categoryOwningXRange(
                selectedXAmount: selectedXAmount,
                categories: model.incomeCategories
            ) { cat in
                max(0, DashboardUtils.incomeAmount(for: cat))
            }
            
        default:
            selectedCategory = nil
        }
    }
}
