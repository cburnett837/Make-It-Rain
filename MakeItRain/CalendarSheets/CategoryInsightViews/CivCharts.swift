//
//  CivCharts.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/19/25.
//

import SwiftUI
import Charts

struct CivSpendingBreakdownChartData: Identifiable {
    var id: UUID { return month.id }
    var month: CBMonth
    var date: Date
    var cost: Double
}

struct CivTransactionCountChartData: Identifiable {
    var id: UUID { return month.id }
    var month: CBMonth
    var date: Date
    var count: Int
}

struct CivActualSpendingBreakdownByCategoryOuterChartData: Identifiable {
    var id: String { return category.id }
    var category: CBCategory
    var data: [CivActualSpendingBreakdownByCategoryChartData]
}

struct CivActualSpendingBreakdownByCategoryChartData: Identifiable {
    var id: UUID { return month.id }
    var month: CBMonth
    var date: Date
    var cost: Double
}


struct CivChartLegend: View {
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: CivViewModel
    
    var body: some View {
        chartLegend
    }
    
    var chartLegend: some View {
        ScrollView(.horizontal) {
            ZStack {
                Spacer()
                    .containerRelativeFrame([.horizontal])
                    .frame(height: 1)
                                            
                HStack(spacing: 0) {
                    ForEach(model.chartData) { item in
                        HStack(alignment: .circleAndTitle, spacing: 5) {
                            //Text("\(item.category.active)")
                            Circle()
                                .fill(item.category.color)
                                .frame(maxWidth: 8, maxHeight: 8) // 8 seems to be the default from charts
                                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.category.title)
                                    .foregroundStyle(Color.secondary)
                                    .font(.caption2)
                                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                            }
                        }
                        .padding(.horizontal, 4)
                        .contentShape(Rectangle())
                    }
                    Spacer()
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        //.contentMargins(.bottom, 10, for: .scrollContent)
    }
}

struct CivBudgetCompareChart: View {
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: CivViewModel
    
    var body: some View {
        Chart {
            if calModel.sCategoryGroupsForAnalysis.isEmpty {
                ForEach(model.chartData) { metric in
                    BarMark(
                        x: .value("Amount", metric.budgetForCategory),
                        y: .value("Key", "Budget")
                    )
                    .foregroundStyle(metric.category.color)
                }
            } else {
                BarMark(
                    x: .value("Amount", model.budget),
                    y: .value("Key", "Budget")
                )
                .foregroundStyle(.gray.gradient)
            }
            
            ForEach(model.chartData) { metric in
                BarMark(
                    x: .value("Amount", (metric.expenses * -1 - metric.income)),
                    y: .value("Key", "Actual Spending")
                )
                .foregroundStyle(metric.category.color)
            }
        }
        .chartLegend(.hidden)
    }        
}


struct CivSpendingBreakdownChart: View {
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: CivViewModel
    
    var body: some View {
        Chart(model.spendingBreakdownChartdata) { data in
            LineMark(
                x: .value("Month", data.date),
                y: .value("Amount", data.cost * -1)
            )
            .interpolationMethod(.cardinal)
            .foregroundStyle(Color.theme)
            .symbol(by: .value("Month", "month"))
        }
        .chartLegend(.hidden)
        .chartXAxis { model.chartXAxis }
    }
}


struct CivTransactionCountChart: View {
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: CivViewModel
       
    var body: some View {
        Chart(model.transactionCountChartData) { data in
            LineMark(
                x: .value("Month", data.date),
                y: .value("Amount", data.count)
            )
            .interpolationMethod(.cardinal)
            .foregroundStyle(Color.theme)
            .symbol(by: .value("Month", "month"))
        }
        .chartLegend(.hidden)
        .chartXAxis { model.chartXAxis }
    }
}


struct CivActualSpendingByCategoryByMonthLineChart: View {
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: CivViewModel
    
    var body: some View {
        //Section("Actual Spending By Category") {
            Chart(model.actualSpendingBreakdownByCategoryChartData) { catData in
                ForEach(catData.data) { data in
                    LineMark(
                        x: .value("Month", data.date),
                        y: .value("Amount", data.cost * -1),
                        series: .value("", catData.id)
                    )
                    .interpolationMethod(.cardinal)
                    .foregroundStyle(catData.category.color)
                }
            }
            .chartLegend(.hidden)
            .chartXAxis { model.chartXAxis }
        //}
    }
}


struct CivActualSpendingByCategoryPieChart: View {
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: CivViewModel
    
    private struct CategorySpendingBar: Identifiable {
        let id: CBCategory.ID   // or UUID
        let category: CBCategory
        let cost: Double
    }
    
    /// The model data needs to be flattened since it is per month. Without it you will end up with an orange food slice for every selected month.
    var body: some View {
        Chart(model.actualSpendingBreakdownByCategoryChartData.map {
            CategorySpendingBar(
                id: $0.category.id,
                category: $0.category,
                cost: $0.data.map(\.cost).reduce(0, +)
            )
        }) { catData in
            SectorMark(
                angle: .value("Amount", (catData.cost * -1 < 0) ? 0 : (catData.cost * -1)),
                innerRadius: .ratio(0.4),
                angularInset: 1.0
            )
            .foregroundStyle(catData.category.color)
        }
        .frame(minHeight: 150)
        
//        Chart(model.actualSpendingBreakdownByCategoryChartData) { catData in
//            ForEach(catData.data) { data in
//                SectorMark(
//                    angle: .value("Amount", (data.cost * -1 < 0) ? 0 : (data.cost * -1)),
//                    innerRadius: .ratio(0.4),
//                    angularInset: 1.0
//                )
//                .cornerRadius(2)
//                .foregroundStyle(catData.category.color)
//            }
//        }
//        .frame(minHeight: 150)
    }
}



struct CivActualSpendingByCategoryBarChart: View {
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: CivViewModel
    
    private struct CategorySpendingBar: Identifiable {
        let id: CBCategory.ID   // or UUID
        let category: CBCategory
        let cost: Double
    }
    
    
    /// The model data needs to be flattened since it is per month. Without it the totals from the selected months will just stack together, instead of being calculated.
    var body: some View {
        Chart(model.actualSpendingBreakdownByCategoryChartData.map {
            CategorySpendingBar(
                id: $0.category.id,
                category: $0.category,
                cost: $0.data.map(\.cost).reduce(0, +)
            )
        }) { catData in
            BarMark(
                x: .value("Amount", catData.cost * -1),
                y: .value("Category", catData.category.title),
            )
            .foregroundStyle(catData.category.color)
        }
        .frame(minHeight: 150)
    }
}
