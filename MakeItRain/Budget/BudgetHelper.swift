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

        for day in days {
            guard let date = day.date else { continue }

            let trans = transactions.filter { $0.dateComponents?.day == date.day }

            if !trans.isEmpty {
                var amount: Decimal = 0.0
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

            cumTotals.append(
                BudgetCumTotal(date: date, total: total, budgetAmount: budgetAmount)
            )
        }
        
        return cumTotals
    }
    
//    static func pointsWithBudgetCrossings(from points: [BudgetCumTotal], budget: Double) -> [BudgetCumTotalChartPoint] {
//        var result: [BudgetCumTotalChartPoint] = []
//        
//        for index in points.indices {
//            let current = points[index]
//            let currentAmount = current.total * -1
//            
//            if index > 0 {
//                let previous = points[index - 1]
//                let previousAmount = previous.total * -1
//                
//                let crossesBudget =
//                    (previousAmount < budget && currentAmount > budget) ||
//                    (previousAmount > budget && currentAmount < budget)
//                
//                if crossesBudget {
//                    let progress = (budget - previousAmount) / (currentAmount - previousAmount)
//                    let timeInterval = current.date.timeIntervalSince(previous.date)
//                    let crossingDate = previous.date.addingTimeInterval(timeInterval * progress)
//                    
//                    let crossingIsFromUnderToOver = previousAmount < budget && currentAmount > budget
//
//                    result.append(
//                        BudgetCumTotalChartPoint(
//                            date: crossingDate,
//                            amount: budget,
//                            isOverBudget: crossingIsFromUnderToOver ? false : true,
//                            isCrossingPoint: true
//                        )
//                    )
//
//                    result.append(
//                        BudgetCumTotalChartPoint(
//                            date: crossingDate,
//                            amount: budget,
//                            isOverBudget: crossingIsFromUnderToOver ? true : false,
//                            isCrossingPoint: true
//                        )
//                    )
//                }
//            }
//            
//            result.append(
//                BudgetCumTotalChartPoint(
//                    date: current.date,
//                    amount: currentAmount,
//                    isOverBudget: currentAmount > budget,
//                    isCrossingPoint: false
//                )
//            )
//        }
//        
//        return result
//    }
    
    
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
    
 
    static func getBudgetGradientPosition(from points: [BudgetCumTotal], budget: Decimal) -> Decimal? {
        
        let amounts = points.map { $0.total * -1 }
        
        guard let minAmount = amounts.min(),
              let maxAmount = amounts.max(),
              minAmount != maxAmount
        else {
            return nil
        }
        
        let result = (budget - minAmount) / (maxAmount - minAmount)
        
        guard !result.isInfinite, !result.isNaN else { return nil }
        
        return min(max(result, 0), 1)
    }
    
}

