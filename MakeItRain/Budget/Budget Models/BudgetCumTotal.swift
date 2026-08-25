//
//  BudgetCumTotal.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/11/26.
//


import SwiftUI
import Charts

struct BudgetCumTotal: Identifiable, Equatable {
    var id: Date {return date}
    let date: Date
    var dailyTotal: Decimal
    var total: Decimal
    var isOverBudget: Bool {
        (total * -1) > budgetAmount
    }
    var budgetAmount: Decimal
    
    var properTotal: Decimal {
        total * -1
    }
    
}


struct BudgetDailyTotal: Identifiable, Equatable {
    var id: Date {return date}
    let date: Date
    var total: Decimal
}
