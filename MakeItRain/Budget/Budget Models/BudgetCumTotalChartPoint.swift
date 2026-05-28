//
//  BudgetCumTotalChartPoint.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/11/26.
//


import SwiftUI
import Charts

struct BudgetCumTotalChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
    let isOverBudget: Bool
    let isCrossingPoint: Bool
}
