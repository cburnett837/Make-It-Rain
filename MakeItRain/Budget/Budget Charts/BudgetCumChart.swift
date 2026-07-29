//
//  BudgetCumSpendingChart.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/11/26.
//


import SwiftUI
import Charts

struct BudgetCumChart: View {
    @Environment(CalendarModel.self) var calModel
    
    var budgetAmount: Decimal
    var cumTotals: [BudgetCumTotal]
    var type: BudgetHelperCalcType
    let today = Calendar.current.startOfDay(for: Date())
    
    var factor: Decimal {
        (type == .spend ? -1 : 1)
    }
    
    func circleColor(for point: BudgetCumTotal) -> Color {
        switch type {
        case .spend: return point.total * factor > budgetAmount ? .red : .green
        case .income: return point.total * factor < budgetAmount ? .red : .green
        }
    }
        
    var lineStyle: some ShapeStyle {
        let amounts = cumTotals.map { $0.total * factor }

        if amounts.allSatisfy({
            switch type {
            case .spend: return $0 > budgetAmount
            case .income: return $0 < budgetAmount
            }
        }) {
            return AnyShapeStyle(Color.red)
        }
        
        if amounts.allSatisfy({
            switch type {
            case .spend: return $0 < budgetAmount
            case .income: return $0 > budgetAmount
            }
        }) {
            return AnyShapeStyle(Color.green)
        }
        
        let gradientPos = BudgetHelper.getBudgetGradientPosition(from: cumTotals, budget: budgetAmount)
        let epsilon = 0.0001
        
        let transition = CGFloat(
            NSDecimalNumber(decimal: min(max(gradientPos ?? 0.5, 0.001), 0.999)).doubleValue
        )

        return AnyShapeStyle(
            LinearGradient(
                stops: [
                    .init(color: .green, location: max(0, transition - epsilon)),
                    .init(color: .red, location: min(1, transition + epsilon))
                ],
                startPoint: .bottom,
                endPoint: .top
            )
        )
    }

    
    var body: some View {
        if cumTotals.allSatisfy({ $0.total == 0 }) {
            noContentView
        } else {
            theChart
        }
    }
    
    
    var theChart: some View {
        Chart {
            if type == .spend {
                RuleMark(y: .value("Budget", budgetAmount))
                    .foregroundStyle(.orange)
                    .annotation(position: .top, alignment: .topLeading) {
                        Text("Budget")
                            .foregroundStyle(.secondary)
                            .font(.caption2)
                    }
                    .zIndex(1)
            }
            
            
            if calModel.sMonth.isNow {
                RuleMark(x: .value("Today", today))
                    .foregroundStyle(.gray)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    .zIndex(1)
            }
            
            ForEach(cumTotals) { point in
                LineMark(
                    x: .value("Date", Calendar.current.startOfDay(for: point.date)),
                    y: .value("Amount", point.total * factor)
                )
                .foregroundStyle(lineStyle)
                .symbol {
                    Circle()
                        .fill(circleColor(for: point))
                        .frame(width: 5, height: 5)
                }
            }
            .zIndex(3)
        }
        .chartYAxis { BudgetHelper.currencyAxisMarks() }
    }
    
    var noContentView: some View {
        ContentUnavailableView("No Data", systemImage: "rectangle.stack.slash", description: Text("No data to display."))
    }
}
