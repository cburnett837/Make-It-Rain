//
//  BudgetChart.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/11/26.
//


import SwiftUI
import Charts

struct BudgetChart: View {
    var budgetAmount: Decimal
    var expenseAmount: Decimal
    
    var body: some View {
        Chart {
            let yKey = "Budget - \(budgetAmount.currencyWithDecimals())\nExpenses - \(expenseAmount.currencyWithDecimals())"
            RuleMark(
                x: .value("Budget", budgetAmount),
                yStart: .value("Start", yKey),
                yEnd: .value("End", yKey)
            )
            .foregroundStyle(.orange)
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
            .zIndex(1)
        
            BarMark(
                x: .value("Amount", expenseAmount),
                y: .value("Key", yKey)
            )
            .foregroundStyle(expenseAmount > budgetAmount ? .red : .green)
            .cornerRadius(5)
        }
        .chartLegend(.hidden)
        .chartXAxis { BudgetHelper.currencyAxisMarks() }
    }
}



struct BudgetChartForGroup: View {    
    @Environment(CalendarModel.self) var calModel
    
    var categories: [CBCategory]
    var budgetAmount: Decimal
    var expenseAmount: Decimal
    
    var body: some View {
        Chart {
            let yKey = "Budget - \(budgetAmount.currencyWithDecimals())\nExpenses - \(expenseAmount.currencyWithDecimals())"
            
            RuleMark(
                x: .value("Budget", budgetAmount),
                yStart: .value("Start", yKey),
                yEnd: .value("End", yKey)
            )
            .foregroundStyle(.orange)
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
            .zIndex(1)
            
            ForEach(categories) { cat in
                let transactions = calModel.getTransactions(cats: [cat])
                let actualSpend = TransactionHelper.All.Amount.actualSpend(from: transactions)
                BarMark(
                    x: .value("Amount", max(0, actualSpend)),
                    y: .value("Key", yKey),
                    stacking: .standard
                )
                .foregroundStyle(cat.color.gradient)
                .zIndex(0)
                .cornerRadius(5)
            }
            
        
//            BarMark(
//                x: .value("Amount", expenseAmount),
//                y: .value("Key", yKey)
//            )
//            .foregroundStyle(expenseAmount > budgetAmount ? .red : .green)
        }
        .chartLegend(.hidden)
        .chartXAxis { BudgetHelper.currencyAxisMarks() }
    }
}
