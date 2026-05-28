//
//  BudgetCumSpendingChart.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/11/26.
//


import SwiftUI
import Charts

struct BudgetCumSpendingChart: View {
    @Environment(CalendarModel.self) var calModel
    
    var budgetAmount: Double
    var cumTotals: [BudgetCumTotal]
    let today = Calendar.current.startOfDay(for: Date())
        
    var lineStyle: some ShapeStyle {
        let amounts = cumTotals.map { $0.total * -1 }

        if amounts.allSatisfy({ $0 > budgetAmount }) { return AnyShapeStyle(Color.red) }
        if amounts.allSatisfy({ $0 < budgetAmount }) { return AnyShapeStyle(Color.green) }
        
        let gradientPos = BudgetHelper.getBudgetGradientPosition(from: cumTotals, budget: budgetAmount)
        let transition = min(max(gradientPos ?? 0.5, 0.001), 0.999)
        let epsilon = 0.0001
        
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
        Chart {
            RuleMark(y: .value("Budget", budgetAmount))
                .foregroundStyle(.orange)
                .annotation(position: .top, alignment: .topLeading) {
                    Text("Budget")
                        .foregroundStyle(.secondary)
                        .font(.caption2)
                }
                .zIndex(1)
            
            if calModel.sMonth.isTodayMonth {
                RuleMark(x: .value("Today", today))
                    .foregroundStyle(.gray)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    .zIndex(1)
            }
            
            ForEach(cumTotals) { point in
                LineMark(
                    x: .value("Date", Calendar.current.startOfDay(for: point.date)),
                    y: .value("Amount", point.total * -1)
                )
                .foregroundStyle(lineStyle)
                .symbol {
                    Circle()
                        .fill(point.total * -1 > budgetAmount ? .red : .green)
                        .frame(width: 5, height: 5)
                }
            }
            .zIndex(3)
        }
        .chartYAxis { BudgetHelper.currencyAxisMarks() }
    }
}
