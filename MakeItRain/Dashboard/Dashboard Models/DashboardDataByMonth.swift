//
//  DashboardDataByMonth.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

struct DashboardDataByMonth: Hashable, Identifiable, Codable, Equatable, DashboardBreakdownSummary {
    var id: String { "\(month)-\(year)" }
    var categories: [CBCategory] = []
    var categoryGroups: [CBCategoryGroup] = []
    //var startingAmountObj: CBStartingAmount?
    var startingAmount: Decimal?
    var paymentAmount: Decimal?
    var budget: Double = 0.0
    var categoryAndGroupBudget: Double = 0.0
    var debitAmounts: DashboardAmounts?
    var creditAmounts: DashboardAmounts?
    var allAmounts: DashboardAmounts?
    var month: Int
    var year: Int
    var date: Date {
        Helpers.createDate(month: month, year: year)!
    }
    
    var title: String {

        "\(DateFormatter.monthFull.string(from: date)) \(year)"

    }
//    var expenseCategories: [CBCategory] { flatCats.filter { !$0.isIncome && $0.allAmounts?.actualSpend ?? 0 > 0 } }
//    var incomeCategories: [CBCategory] {
//        //categories.filter { $0.isIncome || ($0.allAmounts?.actualSpend ?? 0.0) < 0 }
//        flatCats.filter { $0.isIncome || ($0.debitAmounts?.regularIncome ?? 0.0) > 0 || ($0.debitAmounts?.irregularIncome ?? 0.0) > 0 }
//    }
//    
//    var flatCats: [CBCategory] {
//        return (categories + categoryGroups.flatMap(\.categories))
//            //.filter { $0.type != XrefModel.getItem(from: .categoryTypes, byEnumID: .income) }
//            .uniqued(on: { $0.id })
//            .sorted(by: Helpers.categorySorter())
//    }
    
    var flatCats: [CBCategory]
    var expenseCategories: [CBCategory]
    var incomeCategories: [CBCategory]
    
    
    enum CodingKeys: CodingKey { case categories, category_groups, month, year, budget_amount, debit_amounts, credit_amounts, all_amounts, category_and_group_budget, budget, starting_amount, payment_amount }
    
    
    /// For ``NavDest``
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(month, forKey: .month)
        try container.encode(year, forKey: .year)
        try container.encode(categories, forKey: .categories)
        try container.encode(categoryGroups, forKey: .category_groups)
        try container.encode(budget, forKey: .budget)
        try container.encode(categoryAndGroupBudget, forKey: .budget_amount)
        try container.encode(debitAmounts, forKey: .debit_amounts)
        try container.encode(creditAmounts, forKey: .credit_amounts)
        try container.encode(allAmounts, forKey: .all_amounts)
        //try container.encode(startingAmountObj, forKey: .starting_amount)
        try container.encode(startingAmount, forKey: .starting_amount)
        try container.encode(paymentAmount, forKey: .payment_amount)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.month = try container.decode(Int.self, forKey: .month)
        self.year = try container.decode(Int.self, forKey: .year)
        self.categories = try container.decode([CBCategory].self, forKey: .categories)
        self.categoryGroups = try container.decode([CBCategoryGroup].self, forKey: .category_groups)
        self.budget = try container.decodeIfPresent(Double.self, forKey: .budget) ?? 0.0
        self.categoryAndGroupBudget = try container.decodeIfPresent(Double.self, forKey: .budget_amount) ?? 0.0
        self.debitAmounts = try container.decodeIfPresent(DashboardAmounts.self, forKey: .debit_amounts)
        self.creditAmounts = try container.decodeIfPresent(DashboardAmounts.self, forKey: .credit_amounts)
        self.allAmounts = try container.decodeIfPresent(DashboardAmounts.self, forKey: .all_amounts)
        //self.startingAmountObj = try container.decodeIfPresent(CBStartingAmount.self, forKey: .starting_amount)
        self.startingAmount = try container.decodeIfPresent(Decimal.self, forKey: .starting_amount)
        self.paymentAmount = try container.decodeIfPresent(Decimal.self, forKey: .payment_amount)
        
        let flatCats = (categories + categoryGroups.flatMap(\.categories))
            .uniqued(on: { $0.id })
            .sorted(by: Helpers.categorySorter())
        self.flatCats = flatCats
        
        self.expenseCategories = flatCats.filter { !$0.isIncome && $0.allAmounts?.actualSpend ?? 0 > 0 }
        self.incomeCategories = flatCats.filter { $0.isIncome || ($0.debitAmounts?.regularIncome ?? 0.0) > 0 || ($0.debitAmounts?.irregularIncome ?? 0.0) > 0 }
    }
    
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(month)
//        hasher.combine(year)
//        hasher.combine(categories)
//        hasher.combine(categoryGroups)
//        hasher.combine(budgetAmount)
//        hasher.combine(debitAmounts)
//        hasher.combine(creditAmounts)
//        hasher.combine(allAmounts)
//    }
    
    var quarter: Int {
        ((month - 1) / 3) + 1
    }
}
