//
//  ChartData.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/10/25.
//

import Foundation
struct ChartData: Identifiable, Equatable {
    var id: String { return "\(categoryGroup?.id ?? "0")-\(category.id)" }
    
    let category: CBCategory
    var budgetForCategory: Decimal
    
    let categoryGroup: CBCategoryGroup?
    var budgetForCategoryGroup: Decimal?
    
    var income: Decimal
    var incomeMinusPayments: Decimal
    var expenses: Decimal
    var expensesMinusIncome: Decimal
    var chartPercentage: Decimal /// Only used in ``CivBudgetBreakdown``, in a chart that isn't currently used
    var actualPercentage: Decimal /// Only used in ``CivBudgetBreakdown``, in a chart that isn't currently used
    var budgetObjects: Array<CBBudgetItem>?
    
    
    var month: CBMonth?
    var dateForMonth: Date?
    var transactionCount: Int?
    var costPerMonth: [ChartData] = []
}
