//
//  BudgetSpendingByDayChart.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/11/26.
//


import SwiftUI
import Charts

struct BudgetSpendingByDayChart: View {
    @Environment(CalendarModel.self) var calModel
    
    var data: [BudgetDailySpendTotal]
    
    let today = Calendar.current.startOfDay(for: Date())

    
    var body: some View {
        Chart {
            if calModel.sMonth.isTodayMonth {
                RuleMark(x: .value("Today", today))
                    .foregroundStyle(.gray)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    .zIndex(1)
            }
            
            ForEach(data) { data in
                BarMark(
                    x: .value("Date", Calendar.current.startOfDay(for: data.date)),
                    y: .value("Amount", data.total * -1)
                )
                .foregroundStyle(.blue)
            }
        }
        .chartYAxis { BudgetHelper.currencyAxisMarks() }
    }
}
