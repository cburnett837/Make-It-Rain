//
//  DashboardData.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

@Observable
class DashboardData: Decodable, Hashable {
    var beginDate: Date = Date().startDateOfMonth
    var endDate: Date = Date().endDateOfMonth
    var budget: Double = 0.0
    var categoryAndGroupBudget: Double = 0.0
    var debitAmounts: DashboardAmounts = DashboardAmounts()
    var creditAmounts: DashboardAmounts = DashboardAmounts()
    var allAmounts: DashboardAmounts = DashboardAmounts()
    
    var categories: [CBCategory] = []
    var categoryGroups: [CBCategoryGroup] = []
    var monthlyBreakdowns: [DashboardDataByMonth] = [] {
        didSet {
            quarterlyBreakdowns = Self.makeQuarterlyBreakdowns(from: monthlyBreakdowns)
        }
    }
    
    
    var breakdownType: DashboardMontlyOrQuarterlyBreakdowns = .monthly
    
    
    private(set) var quarterlyBreakdowns: [DashboardDataByQuarter] = []

    static func makeQuarterlyBreakdowns(
        from monthlyBreakdowns: [DashboardDataByMonth]
    ) -> [DashboardDataByQuarter] {
        let grouped = Dictionary(grouping: monthlyBreakdowns) { monthData in
            "\(monthData.year)-\(monthData.quarter)"
        }

        return grouped.values.map { months in
            let months = months.sorted { $0.date < $1.date }
            let first = months[0]
            return DashboardDataByQuarter(
                quarter: first.quarter,
                year: first.year,
                months: months
            )
        }
        .sorted { $0.date < $1.date }
    }
    
    var monthSpan: Int {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.month], from: beginDate, to: endDate)
        return comps.month ?? 0
    }
  
    init() {}
    
    enum CodingKeys: CodingKey { case categories, category_groups, user_id, account_id, device_uuid, begin_date, end_date, budget_amount, debit_amounts, credit_amounts, all_amounts, monthly_breakdowns, category_and_group_budget, budget}
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.budget = try container.decode(Double.self, forKey: .budget)
        self.categoryAndGroupBudget = try container.decode(Double.self, forKey: .category_and_group_budget)
        self.debitAmounts = try container.decode(DashboardAmounts.self, forKey: .debit_amounts)
        self.creditAmounts = try container.decode(DashboardAmounts.self, forKey: .credit_amounts)
        self.allAmounts = try container.decode(DashboardAmounts.self, forKey: .all_amounts)
        self.monthlyBreakdowns = try container.decode([DashboardDataByMonth].self, forKey: .monthly_breakdowns)
        self.categories = DashboardUtils.summarizeCategories(monthlyBreakdowns.flatMap(\.categories))
        self.categoryGroups = DashboardUtils.summarizeGroups(monthlyBreakdowns.flatMap(\.categoryGroups))
    }
    
    static func == (lhs: DashboardData, rhs: DashboardData) -> Bool {
        lhs.beginDate == rhs.beginDate &&
        lhs.endDate == rhs.endDate &&
        lhs.budget == rhs.budget &&
        lhs.categoryAndGroupBudget == rhs.categoryAndGroupBudget &&
        lhs.debitAmounts == rhs.debitAmounts &&
        lhs.creditAmounts == rhs.creditAmounts &&
        lhs.allAmounts == rhs.allAmounts &&
        lhs.categories == rhs.categories &&
        lhs.categoryGroups == rhs.categoryGroups &&
        lhs.monthlyBreakdowns == rhs.monthlyBreakdowns
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(beginDate)
        hasher.combine(endDate)
        hasher.combine(budget)
        hasher.combine(categoryAndGroupBudget)
        hasher.combine(debitAmounts)
        hasher.combine(creditAmounts)
        hasher.combine(allAmounts)
        hasher.combine(categories)
        hasher.combine(categoryGroups)
        hasher.combine(monthlyBreakdowns)
    }
}