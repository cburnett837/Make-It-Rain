//
//  DashboardDataByQuarter.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

struct DashboardDataByQuarter: Hashable, Identifiable, DashboardBreakdownSummary {
    var id: String { "Q\(quarter)-\(year)" }

    var quarter: Int
    var year: Int
    var months: [DashboardDataByMonth]

    var categoryAndGroupBudget: Double
    var debitAmounts: DashboardAmounts?
    var creditAmounts: DashboardAmounts?
    var allAmounts: DashboardAmounts?
    var categories: [CBCategory]
    var categoryGroups: [CBCategoryGroup]
    var flatCats: [CBCategory]

    init(
        quarter: Int,
        year: Int,
        months: [DashboardDataByMonth]
    ) {
        self.quarter = quarter
        self.year = year
        self.months = months

        self.categoryAndGroupBudget = months.reduce(0) { $0 + $1.categoryAndGroupBudget }
        self.debitAmounts = DashboardDataByQuarter.summarizeAmounts(months.map(\.debitAmounts))
        self.creditAmounts = DashboardDataByQuarter.summarizeAmounts(months.map(\.creditAmounts))
        self.allAmounts = DashboardDataByQuarter.summarizeAmounts(months.map(\.allAmounts))

        self.categories = DashboardUtils.summarizeCategories(months.flatMap(\.categories))
        self.categoryGroups = DashboardUtils.summarizeGroups(months.flatMap(\.categoryGroups))

        self.flatCats = (categories + categoryGroups.flatMap(\.categories))
            .uniqued(on: { $0.id })
            .sorted(by: Helpers.categorySorter())
    }

    private static func summarizeAmounts(_ amounts: [DashboardAmounts?]) -> DashboardAmounts {
        let result = DashboardAmounts()
        amounts.forEach { result.add($0) }
        return result
    }

    var title: String {
        "Q\(quarter) \(year)"
    }

    var date: Date {
        Helpers.createDate(month: startingMonth, year: year)!
    }

    private var startingMonth: Int {
        switch quarter {
        case 1: 1
        case 2: 4
        case 3: 7
        case 4: 10
        default: 1
        }
    }

    var endDate: Date {
        Calendar.current.date(byAdding: .month, value: 3, to: date)!
    }
}