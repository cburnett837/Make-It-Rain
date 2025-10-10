//
//  PayMethodChartModels.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/15/25.
//

import Foundation
import SwiftUI

enum PayMethodChartRange: Int {
    case yearToDate = 0
    case year1 = 1
    case year2 = 2
    case year3 = 3
    case year4 = 4
    case year5 = 5
    case year10 = 10
    
    static func fromInt(_ theInt: Int) -> Self {
        switch theInt {
        case 0: return .yearToDate
        case 1: return .year1
        case 2: return .year2
        case 3: return .year3
        case 4: return .year4
        case 5: return .year5
        case 10: return .year10
        default: return .yearToDate
        }
    }
}

enum PayMethodChartDataType {
    case category, creditPaymentMethod, debitPaymentMethod, unifiedCreditPaymentMethod, unifiedDebitPaymentMethod, other
}

struct PayMethodChartConfig {
    var type: PayMethodChartDataType
    var incomeConfig: (title: String, enabled: Bool, color: Color)? = nil
    var incomeAndPositiveAmountsConfig: (title: String, enabled: Bool, color: Color)? = nil
    var positiveAmountsConfig: (title: String, enabled: Bool, color: Color)? = nil
    var expensesConfig: (title: String, enabled: Bool, color: Color)? = nil
    var paymentsConfig: (title: String, enabled: Bool, color: Color)? = nil
    var startingAmountsConfig: (title: String, enabled: Bool, color: Color)? = nil
    var profitLossConfig: (title: String, enabled: Bool, color: Color)? = nil
    var monthEndConfig: (title: String, enabled: Bool, color: Color)? = nil
    var minEodConfig: (title: String, enabled: Bool, color: Color)? = nil
    var maxEodConfig: (title: String, enabled: Bool, color: Color)? = nil
    var color: Color
    var headerLingo: String
}

struct PayMethodChartSelectedDateDetails: Identifiable {
    var id: String { UUID().uuidString }
    var title: String
    var color: Color
    var income: Double
    var incomeAndPositiveAmounts: Double
    var positiveAmounts: Double
    var startingAmountsAndPositiveAmounts: Double
    var expenses: Double
    var payments: Double
    var startingAmounts: Double
    var profitLoss: Double
    var profitLossPercentage: Double
    //var profitLossMinPercentage: Double
    //var profitLossMaxPercentage: Double
    //var profitLossMinAmount: Double
    //var profitLossMaxAmount: Double
    var monthEnd: Double
    var minEod: Double
    var maxEod: Double
    
    
}

public enum IncomeType: String {
    case income, incomeAndPositiveAmounts, positiveAmounts, startingAmountsAndPositiveAmounts
    
    var prettyValue: String {
        switch self {
        case .income: return "Income Only"
        case .incomeAndPositiveAmounts: return "All Money In"
        case .positiveAmounts: return "Money In Only (no income)"
        case .startingAmountsAndPositiveAmounts: return "Starting Amount & All Money In"
        }
    }
    
    static func fromString(_ string: String) -> Self {
        switch string {
        case "income": return .income
        case "incomeAndPositiveAmounts": return .incomeAndPositiveAmounts
        case "positiveAmounts": return .positiveAmounts
        case "startingAmountsAndPositiveAmounts": return .startingAmountsAndPositiveAmounts
        default: return .income
        }
    }
}

public enum MetricByPaymentMethodType: String {
    case expenses, income, startingAmounts, payments
    
    var prettyValue: String {
        switch self {
        case .expenses: return "Expenses"
        case .income: return "Income"
        case .startingAmounts: return "Starting Amounts"
        case .payments: return "Payments"
        }
    }
    
    static func fromString(_ string: String) -> Self {
        switch string {
        case "expenses": return .expenses
        case "income": return .income
        case "startingAmounts": return .startingAmounts
        case "payments": return .payments
        default: return .income
        }
    }
}



public enum ChartCropingStyle: String, CaseIterable {
    case showFullCurrentYear, endAtCurrentMonth
    
    var prettyValue: String {
        switch self {
        case .showFullCurrentYear: return "Show full year"
        case .endAtCurrentMonth: return "Show through current month"
        }
    }
    
    static func fromString(_ string: String) -> Self {
        switch string {
        case "showFullCurrentYear": return .showFullCurrentYear
        case "endAtCurrentMonth": return .endAtCurrentMonth
        default: return .showFullCurrentYear
        }
    }
}



struct Breakdown: Identifiable {
    var id = UUID()
    var date: Date
    var breakdowns: [PayMethodMonthlyBreakdown]
}


// MARK: - PayMethodMonthlyBreakdown
class PayMethodMonthlyBreakdown: Identifiable, Decodable, Equatable {
    var id: String { "\(month)-\(year)-\(payMethodID)" }
    var payMethodID: String
    var title: String = ""
    var color: Color = .primary
    var month: Int
    var year: Int
    var date: Date {
        Helpers.createDate(month: month, year: year)!
    }
    
    var income: Double { Double(incomeString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0 }
    var incomeString: String
    
    var incomeAndPositiveAmounts: Double { Double(incomeAndPositiveAmountsString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0 }
    var incomeAndPositiveAmountsString: String
    
    var positiveAmounts: Double { Double(positiveAmountsString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0 }
    var positiveAmountsString: String
    
    var expenses: Double { Double(expensesString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0 }
    var expensesString: String
    
    var payments: Double { Double(paymentsString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0 }
    var paymentsString: String
    
    var startingAmounts: Double { Double(startingAmountsString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0 }
    var startingAmountsString: String
    
    var profitLoss: Double { Double(profitLossString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0 }
    var profitLossString: String
    
    var profitLossPercentage: Double
    
//    var profitLossMinPercentage: Double { Double(profitLossMinPercentageString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0 }
//    var profitLossMinPercentageString: String
//    
//    var profitLossMaxPercentage: Double { Double(profitLossMaxPercentageString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0 }
//    var profitLossMaxPercentageString: String
//    
//    var profitLossMinAmount: Double { Double(profitLossMinAmountString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0 }
//    var profitLossMinAmountString: String
//    
//    var profitLossMaxAmount: Double { Double(profitLossMaxAmountString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0 }
//    var profitLossMaxAmountString: String
                
    var monthEnd: Double { Double(monthEndString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0 }
    var monthEndString: String
    
    var minEod: Double { Double(minEodString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0 }
    var minEodString: String
    
    var maxEod: Double { Double(maxEodString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0 }
    var maxEodString: String
        
    var startingAmountsAndPositiveAmounts: Double { Double(startingAmountsAndPositiveAmountsString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0 }
    var startingAmountsAndPositiveAmountsString: String
    
    
    
    enum CodingKeys: CodingKey { case payment_method_id, month, year, income, income_and_positive_amounts, positive_amounts, expenses, payments, starting_amounts, profit_loss, starting_amount_and_positive_amounts, month_end, min_eod, max_eod }
    
    init(
        title: String,
        color: Color,
        payMethodID: String,
        month: Int,
        year: Int,
        incomeString: String,
        incomeAndPositiveAmountsString: String,
        positiveAmountsString: String,
        startingAmountsAndPositiveAmountsString: String,
        expensesString: String,
        paymentsString: String,
        startingAmountsString: String,
        profitLossString: String,
        profitLossPercentage: Double,
        //profitLossMinPercentageString: String,
        //profitLossMaxPercentageString: String,
        //profitLossMinAmountString: String,
        //profitLossMaxAmountString: String,
        monthEndString: String,
        minEodString: String,
        maxEodString: String
    ) {
        self.title = title
        self.color = color
        self.payMethodID = payMethodID
        self.month = month
        self.year = year
        self.incomeString = incomeString
        self.incomeAndPositiveAmountsString = incomeAndPositiveAmountsString
        self.positiveAmountsString = positiveAmountsString
        self.startingAmountsAndPositiveAmountsString = startingAmountsAndPositiveAmountsString
        self.expensesString = expensesString
        self.paymentsString = paymentsString
        self.startingAmountsString = startingAmountsString
        self.profitLossString = profitLossString
        self.profitLossPercentage = profitLossPercentage
        //self.profitLossMinPercentageString = profitLossMinPercentageString
        //self.profitLossMaxPercentageString = profitLossMaxPercentageString
        //self.profitLossMinAmountString = profitLossMinAmountString
        //self.profitLossMaxAmountString = profitLossMaxAmountString
        self.monthEndString = monthEndString
        self.minEodString = minEodString
        self.maxEodString = maxEodString
    }
        
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            payMethodID = try String(container.decode(Int.self, forKey: .payment_method_id))
        } catch {
            payMethodID = try container.decode(String.self, forKey: .payment_method_id)
        }
        
        month = try container.decode(Int.self, forKey: .month)
        year = try container.decode(Int.self, forKey: .year)
        incomeString = try String(container.decode(Double.self, forKey: .income))
        incomeAndPositiveAmountsString = try String(container.decode(Double.self, forKey: .income_and_positive_amounts))
        positiveAmountsString = try String(container.decode(Double.self, forKey: .positive_amounts))
        expensesString = try String(container.decode(Double.self, forKey: .expenses))
        paymentsString = try String(container.decode(Double.self, forKey: .payments))
        startingAmountsString = try String(container.decode(Double.self, forKey: .starting_amounts))
        profitLossString = try String(container.decode(Double.self, forKey: .profit_loss))
        monthEndString = try String(container.decode(Double.self, forKey: .month_end))
        minEodString = try String(container.decode(Double.self, forKey: .min_eod))
        maxEodString = try String(container.decode(Double.self, forKey: .max_eod))
        startingAmountsAndPositiveAmountsString = try String(container.decode(Double.self, forKey: .starting_amount_and_positive_amounts))
        
        self.profitLossPercentage = 0.0
        
        //self.profitLossMinPercentageString = ""
        //self.profitLossMaxPercentageString = ""
        //self.profitLossMinAmountString = ""
        //self.profitLossMaxAmountString = ""
        
    }
    
    static func == (lhs: PayMethodMonthlyBreakdown, rhs: PayMethodMonthlyBreakdown) -> Bool {
        if lhs.payMethodID == rhs.payMethodID &&
        lhs.month == rhs.month &&
        lhs.year == rhs.year &&
        lhs.date == rhs.date &&
        lhs.income == rhs.income &&
        lhs.incomeAndPositiveAmounts == rhs.incomeAndPositiveAmounts &&
        lhs.startingAmountsAndPositiveAmounts == rhs.startingAmountsAndPositiveAmounts &&
        lhs.positiveAmounts == rhs.positiveAmounts &&
        lhs.expenses == rhs.expenses &&
        lhs.payments == rhs.payments &&
        lhs.startingAmounts == rhs.startingAmounts &&
        lhs.profitLoss == rhs.profitLoss &&
        lhs.profitLossPercentage == rhs.profitLossPercentage &&
        //lhs.profitLossMinPercentage == rhs.profitLossMinPercentage &&
        //lhs.profitLossMaxPercentage == rhs.profitLossMaxPercentage &&
        //lhs.profitLossMinAmount == rhs.profitLossMinAmount &&
        //lhs.profitLossMaxAmount == rhs.profitLossMaxAmount &&
        lhs.monthEnd == rhs.monthEnd &&
        lhs.minEod == rhs.minEod &&
        lhs.maxEod == rhs.maxEod
        {
            return true
        }
        
        return false
    }
    
    
    func setFromAnotherInstance(_ obj: PayMethodMonthlyBreakdown) {
        self.payMethodID = obj.payMethodID
        self.month = obj.month
        self.year = obj.year
        self.incomeString = obj.incomeString
        self.incomeAndPositiveAmountsString = obj.incomeAndPositiveAmountsString
        self.positiveAmountsString = obj.positiveAmountsString
        self.startingAmountsAndPositiveAmountsString = obj.startingAmountsAndPositiveAmountsString
        self.expensesString = obj.expensesString
        self.paymentsString = obj.paymentsString
        self.startingAmountsString = obj.startingAmountsString
        self.profitLossString = obj.profitLossString
        self.profitLossPercentage = obj.profitLossPercentage
        //self.profitLossMinPercentageString = obj.profitLossMinPercentageString
        //self.profitLossMaxPercentageString = obj.profitLossMaxPercentageString
        //self.profitLossMinAmountString = obj.profitLossMinAmountString
        //self.profitLossMaxAmountString = obj.profitLossMaxAmountString
        self.monthEndString = obj.monthEndString
        self.minEodString = obj.minEodString
        self.maxEodString = obj.maxEodString                
    }
}
