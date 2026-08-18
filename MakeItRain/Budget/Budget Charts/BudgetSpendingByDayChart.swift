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
    
    @State private var annotationHeight: CGFloat = 0
    @State private var rawSelectedDate: Date?
    var selectedDay: BudgetDailyTotal? {
        guard let rawSelectedDate else { return nil }
        return data.filter { Calendar.current.isDate(rawSelectedDate, equalTo: $0.date, toGranularity: .day) }.first
    }
    
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
            if let selectedDay = selectedDay {
                RuleMark(x: .value("Date", Calendar.current.startOfDay(for: selectedDay.date)))
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
            
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
        .sensoryFeedback(.selection, trigger: selectedDay)
        .chartXSelection(value: $rawSelectedDate)
        .chartYAxis { BudgetHelper.currencyAxisMarks() }
        .overlay(alignment: .top) {
            if selectedDay != nil {
                selectedDataView
            }
        }
    }
    
    var noContentView: some View {
        ContentUnavailableView("No Data", systemImage: "rectangle.stack.slash", description: Text("No data to display."))
    }
    
    @ViewBuilder
    var selectedDataView: some View {
        if let day = selectedDay {
            VStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(day.date.string(to: .date))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)

                        Spacer()
                    }
                    .font(.headline)

                    Divider()

                    Grid(alignment: .leading) {
                        GridRow {
                            Text("Daily Spend").bold()
                            Text((day.total * factor).currencyWithDecimals())
                        }
                    }
                    .font(.subheadline)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        //.fill(annotationColor)
                        .fill(.blue)
                        //.fill(.secondary)
                )
                .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .background {
                GeometryReader { geo in
                    Color.clear
                        .onAppear { annotationHeight = geo.size.height }
                        .onChange(of: geo.size.height) { annotationHeight = $1 }
                }
            }
            .offset(y: -annotationHeight - 8)
            .zIndex(10)
        }
        
    }
}
