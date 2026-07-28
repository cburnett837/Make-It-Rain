//
//  DashboardAmounts.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

@Observable
class DashboardAmounts: Codable, Hashable, Equatable {
    var regularIncome: Decimal = 0.0 /// Salary, calculated by any category that is of type "income".
    var irregularIncome: Decimal = 0.0 /// Reimbursements, refunds, gifts, etc.
    var actualIncome: Decimal = 0.0
    
    var totalSpend: Decimal = 0.0 /// Any normal expenses
    var actualSpend: Decimal = 0.0 /// actual spending (totalSpend - irregularIncome)
    var actualSpendMinusRegularIncome: Decimal = 0.0 /// left over money between salary and expenses
    var actualSpendMinusPayment: Decimal = 0.0
    
    var creditPayment: Decimal?
    
    var variance: Decimal?
    
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
    
    /// For ``NavDest``
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(regularIncome, forKey: .regular_income)
        try container.encode(irregularIncome, forKey: .irregular_income)
        try container.encode(actualIncome, forKey: .actual_income)
        
        try container.encode(totalSpend, forKey: .total_spend)
        try container.encode(actualSpend, forKey: .actual_spend)
        try container.encode(actualSpendMinusRegularIncome, forKey: .actual_spend_minus_regular_income)
        try container.encode(actualSpendMinusPayment, forKey: .actual_spend_minus_payment)
        
        try container.encode(variance, forKey: .variance)
        try container.encode(creditPayment, forKey: .credit_payment)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
                        
        self.regularIncome = try container.decode(Decimal.self, forKey: .regular_income)
        self.irregularIncome = try container.decode(Decimal.self, forKey: .irregular_income)
        self.actualIncome = try container.decodeIfPresent(Decimal.self, forKey: .actual_income) ?? 0.0
        
        self.totalSpend = try container.decode(Decimal.self, forKey: .total_spend)
        self.actualSpend = try container.decode(Decimal.self, forKey: .actual_spend)
        self.actualSpendMinusRegularIncome = try container.decode(Decimal.self, forKey: .actual_spend_minus_regular_income)
        self.actualSpendMinusPayment = try container.decode(Decimal.self, forKey: .actual_spend_minus_payment)
        
        self.variance = try container.decodeIfPresent(Decimal.self, forKey: .variance)
        self.creditPayment = try container.decodeIfPresent(Decimal.self, forKey: .credit_payment)
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
