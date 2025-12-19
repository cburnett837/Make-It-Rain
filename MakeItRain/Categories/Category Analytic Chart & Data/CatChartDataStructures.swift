//
//  CategoryAnalyticChartData.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/10/25.
//

import Foundation
import SwiftUI
//
//struct CategoryAnalyticRecord {
//    var id: String
//    var title: String
//    var color: Color
//}
//

struct CategoryAnalyticData: Identifiable {
    var id = UUID()
    //var category: CBCategory?
    var category: CBCategory
    var type: String
    var month: Int
    var year: Int
    var date: Date {
        Helpers.createDate(month: month, year: year)!
    }
    
    var budgetString: String
    var budget: Double {
        Double(budgetString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
    }
    
    var expensesString: String
    var expenses: Double {
        Double(expensesString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
    }
    
    var incomeString: String
    var income: Double {
        Double(incomeString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
    }
    
    var incomeMinusExpenses: Double {
        income - expenses
    }
    
    var expensesMinusIncome: Double {
        expenses - income
    }
}


enum CategoryAnalyticChartRange: Int {
    //case yearToDate = 0
    case year1 = 1
    case year2 = 2
    case year3 = 3
    case year4 = 4
    case year5 = 5
    case year10 = 10
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        //case "yearToDate": return .yearToDate
        case "year1": return .year1
        case "year2": return .year2
        case "year3": return .year3
        case "year4": return .year4
        case "year5": return .year5
        case "year10": return .year10
        default: return .year1
        }
    }
    
    static func fromInt(_ theInt: Int) -> Self {
        switch theInt {
        //case 0: return .yearToDate
        case 1: return .year1
        case 2: return .year2
        case 3: return .year3
        case 4: return .year4
        case 5: return .year5
        case 10: return .year10
        default: return .year1
        }
    }
}



enum CategoryAnalyticChartDisplayedMetric: String, CaseIterable, Identifiable {
    var id: CategoryAnalyticChartDisplayedMetric { return self }
    case income, expenses, budget, expensesMinusIncome
    
    var prettyValue: String {
        switch self {
        case .income:
            "Income"
        case .expenses:
            "Expenses"
        case .budget:
            "Budget"
        case .expensesMinusIncome:
            "Expenses minus income"
        }
    }
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "income": return .income
        case "expenses": return .expenses
        case "budget": return .budget
        case "expensesMinusIncome": return .expensesMinusIncome
        default: return .expenses
        }
    }
}



enum CatChartRawDataListLineDisplayLabel {
    case date, category
}
