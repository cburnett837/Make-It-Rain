//
//  DashboardAmounts.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

@Observable
class DashboardAmounts: Decodable, Hashable, Equatable {
    var regularIncome: Double = 0.0 /// Salary, calculated by any category that is of type "income".
    var irregularIncome: Double = 0.0 /// Reimbursements, refunds, gifts, etc.
    var actualIncome: Double = 0.0
    
    var totalSpend: Double = 0.0 /// Any normal expenses
    var actualSpend: Double = 0.0 /// actual spending (totalSpend - irregularIncome)
    var actualSpendMinusRegularIncome: Double = 0.0 /// left over money between salary and expenses
    var actualSpendMinusPayment: Double = 0.0
    
    var creditPayment: Double?
    
    var variance: Double?
    
    init() {
        self.regularIncome = 0.0
        self.irregularIncome = 0.0
        self.totalSpend = 0.0
        self.actualSpend = 0.0
        self.actualSpendMinusRegularIncome = 0.0
        self.actualSpendMinusPayment = 0.0
        self.variance = nil
    }
    
    enum CodingKeys: CodingKey { case regular_income, irregular_income, actual_income, total_spend, actual_spend, actual_spend_minus_regular_income, actual_spend_minus_payment, variance, credit_payment }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
                        
        self.regularIncome = try container.decode(Double.self, forKey: .regular_income)
        self.irregularIncome = try container.decode(Double.self, forKey: .irregular_income)
        self.actualIncome = try container.decodeIfPresent(Double.self, forKey: .actual_income) ?? 0.0
        
        self.totalSpend = try container.decode(Double.self, forKey: .total_spend)
        self.actualSpend = try container.decode(Double.self, forKey: .actual_spend)
        self.actualSpendMinusRegularIncome = try container.decode(Double.self, forKey: .actual_spend_minus_regular_income)
        self.actualSpendMinusPayment = try container.decode(Double.self, forKey: .actual_spend_minus_payment)
        
        self.variance = try container.decodeIfPresent(Double.self, forKey: .variance)
        self.creditPayment = try container.decodeIfPresent(Double.self, forKey: .credit_payment)
    }
    
    convenience init(copying other: DashboardAmounts?) {
        self.init()
        self.add(other)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(regularIncome)
        hasher.combine(irregularIncome)
        hasher.combine(actualIncome)
        hasher.combine(totalSpend)
        hasher.combine(actualSpend)
        hasher.combine(actualSpendMinusRegularIncome)
        hasher.combine(actualSpendMinusPayment)
        hasher.combine(creditPayment)
        hasher.combine(variance)
    }
    
    static func == (lhs: DashboardAmounts, rhs: DashboardAmounts) -> Bool {
        lhs.regularIncome == rhs.regularIncome &&
        lhs.irregularIncome == rhs.irregularIncome &&
        lhs.actualIncome == rhs.actualIncome &&
        lhs.totalSpend == rhs.totalSpend &&
        lhs.actualSpend == rhs.actualSpend &&
        lhs.actualSpendMinusRegularIncome == rhs.actualSpendMinusRegularIncome &&
        lhs.actualSpendMinusPayment == rhs.actualSpendMinusPayment &&
        lhs.creditPayment == rhs.creditPayment &&
        lhs.variance == rhs.variance
    }
    
    func add(_ other: DashboardAmounts?) {
        guard let other else { return }
        regularIncome += other.regularIncome
        irregularIncome += other.irregularIncome
        actualIncome += other.actualIncome
        totalSpend += other.totalSpend
        actualSpend += other.actualSpend
        actualSpendMinusRegularIncome += other.actualSpendMinusRegularIncome
        actualSpendMinusPayment += other.actualSpendMinusPayment
        creditPayment = (creditPayment ?? 0) + (other.creditPayment ?? 0)
        variance = (variance ?? 0) + (other.variance ?? 0)
    }
}