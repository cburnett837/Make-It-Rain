//
//  BudgetHelper.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/11/26.
//

import Foundation
import Charts
import SwiftUI

enum BudgetHelperCalcType {
    case spend, income
}
struct BudgetHelper {
    
    @MainActor
    static func calculateDailyAmount(
        days: [CBDay],
        transactions: Array<CBTransaction>,
        type: BudgetHelperCalcType
    ) -> [BudgetDailyTotal] {
        let spendByDateTotals = days.compactMap { day -> BudgetDailyTotal? in
            guard let date = day.date else { return nil }
            
            var val: Decimal = 0.0
            
            switch type {
            case .spend:
                val = transactions
                    .filter { $0.dateComponents?.day == day.date?.day && $0.isExpense }
                    .map { $0.payMethod?.isCreditOrLoan == true ? $0.amount * -1 : $0.amount }
                    .reduce(0, +)
            case .income:
                val = transactions
                    .filter { $0.dateComponents?.day == day.date?.day && $0.isIncome }
                    .map { $0.payMethod?.isCreditOrLoan == true ? $0.amount * -1 : $0.amount }
                    .reduce(0, +)
            }
            
            
            return BudgetDailyTotal(date: date, total: val)
        }
        
        return spendByDateTotals
    }
    
    @MainActor
    static func calculateCumTotals(
        days: [CBDay],
        transactions: Array<CBTransaction>,
        budgetAmount: Decimal,
        type: BudgetHelperCalcType
    ) -> Array<BudgetCumTotal> {
        /// Get how much has been spend up until each day.
        //cumTotals.removeAll()
        
        var cumTotals: [BudgetCumTotal] = []

        var total: Decimal = 0.0
        var amount: Decimal = 0.0
        
        
        let transactionsByDay = Dictionary(grouping: transactions) {
            $0.dateComponents?.day ?? -1
        }

        for day in days {
            guard let date = day.date else { continue }
            let trans = transactionsByDay[day.id] ?? []
            
            amount = 0
            guard let date = day.date else { continue }

            //let trans = transactions.filter { $0.dateComponents?.day == date.day }

            if !trans.isEmpty {
                switch type {
                case .spend:
                    amount = TransactionHelper.All.Amount.actualSpend(from: trans) * -1
                    //print("\(#function) spend - \(amount)")
                case .income:
                    amount = TransactionHelper.All.Amount.actualIncome(from: trans)
                    //print("\(#function) income - \(amount)")
                }
                //let dailySpend = TransactionHelper.All.Amount.actualSpend(from: trans) * -1
                //let dailyIncome = TransactionHelper.All.Amount.actualIncome(from: trans)
                //let new = amount// + dailyIncome
                
                //print("\(day.date) - \(new)")
                
                total += amount
            }

            cumTotals.append(BudgetCumTotal(date: date, dailyTotal: amount, total: total, budgetAmount: budgetAmount))
        }
        
        return cumTotals
    }
   
    @AxisContentBuilder
    static func currencyAxisMarks() -> some AxisContent {
        AxisMarks { value in
            AxisGridLine()
            AxisTick()

            AxisValueLabel {
                if let amount = value.as(Double.self) {
                    Text(
                        amount,
                        format: .currency(code: "USD")
                            .notation(.compactName)
                    )
                }
            }
        }
    }
}

