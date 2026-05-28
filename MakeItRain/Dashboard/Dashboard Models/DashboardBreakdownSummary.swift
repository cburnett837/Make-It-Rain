//
//  DashboardBreakdownSummary.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

protocol DashboardBreakdownSummary {
    var title: String { get }
    var date: Date { get }
    var categoryAndGroupBudget: Double { get }
    var allAmounts: DashboardAmounts? { get }
    var flatCats: [CBCategory] { get }
}