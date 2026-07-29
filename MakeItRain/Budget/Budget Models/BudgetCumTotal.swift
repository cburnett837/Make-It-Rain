//
//  BudgetCumTotal.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/11/26.
//


import SwiftUI
import Charts

struct BudgetCumTotal: Identifiable {
    var id: Date {return date}
    let date: Date
    var total: Decimal
    var isOverBudget: Bool {
        (total * -1) > budgetAmount
    }
    var budgetAmount: Decimal
}


struct BudgetDailyTotal: Identifiable {
    var id: Date {return date}
    let date: Date
    var total: Decimal
}
