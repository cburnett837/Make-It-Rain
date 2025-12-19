//
//  ChartData.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/10/25.
//

import Foundation
struct ChartData: Identifiable {
    var id: String { return category.id }
    
    let category: CBCategory
    var budgetForCategory: Double
    
    let categoryGroup: CBCategoryGroup?
    var budgetForCategoryGroup: Double?
    
    var income: Double
    var incomeMinusPayments: Double
    var expenses: Double
    var expensesMinusIncome: Double
    var chartPercentage: Double
    var actualPercentage: Double
    var budgetObjects: Array<CBBudget>?
}
