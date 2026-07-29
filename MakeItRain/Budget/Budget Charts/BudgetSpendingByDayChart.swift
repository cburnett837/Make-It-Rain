//
//  BudgetByDayChart.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/11/26.
//


import SwiftUI
import Charts

struct BudgetByDayChart: View {
    @Environment(CalendarModel.self) var calModel
    
    var data: [BudgetDailyTotal]
    var type: BudgetHelperCalcType
    
    let today = Calendar.current.startOfDay(for: Date())
    
    var factor: Decimal {
        (type == .spend ? -1 : 1)
    }

    
    var body: some View {
        if data.allSatisfy({ $0.total == 0 }) {
            noContentView
        } else {
            theChart
        }
    }
    
    var theChart: some View {
        Chart {
            if calModel.sMonth.isNow {
                RuleMark(x: .value("Today", today))
                    .foregroundStyle(.gray)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    .zIndex(1)
            }
            
            ForEach(data) { d in
                BarMark(
                    x: .value("Date", Calendar.current.startOfDay(for: d.date)),
                    y: .value("Amount", d.total * factor)
                )
                .foregroundStyle(.blue)
            }
        }
        .chartYAxis { BudgetHelper.currencyAxisMarks() }
    }
    
    var noContentView: some View {
        ContentUnavailableView("No Data", systemImage: "rectangle.stack.slash", description: Text("No data to display."))
    }
}
