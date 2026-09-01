//
//  DashboardActivityByCategoryVerticalBarChart.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/1/26.
//

import SwiftUI
//
//  DashboardActivityByCategoryPieChart.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

struct DashboardActivityByCategoryVerticalBarChart: View {
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: DashboardModel
    @Bindable var data: DashboardData
    @Binding var selectedCategory: CBCategory?
    
//    @State private var selectedCategory: CBCategory?
    
    @State private var selectedTitle: String?
    
    var body: some View {
        Chart {
            if let selectedCategory = selectedCategory {
                RuleMark(x: .value("Category", selectedCategory.title))
                    .foregroundStyle(Color.secondary.opacity(0.5))
//                    .annotation(
//                        position: .top,
//                        alignment: .center,
//                        overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
//                    ) {
//                        DashboardActivityByCategoryAnnotation(category: selectedCategory)
//                        //Rectangle().fill(Color.red).frame(height: 200)
//                        //Text(selectedCategory.title)
//                    }
            }
            
            ForEach(model.expenseCategories) { cat in
                BarMark(
                    x: .value("Category", cat.title),
                    y: .value("Amount", max(0, (model.shouldUseTotalSpending ? cat.allAmounts?.totalSpend ?? 0 : cat.allAmounts?.actualSpend ?? 0)))
                )
                .accessibilityHidden(true)
                .foregroundStyle(cat.color)
                .opacity(selectedCategory == nil ? 1 : (cat.id == selectedCategory?.id ? 1 : 0.3))
            }
        }
        .frame(height: 150)
        .sensoryFeedback(.selection, trigger: selectedCategory)
        .chartXSelection(value: $selectedTitle)
        .chartYAxis { yAxis() }
        .chartXScale(domain: model.expenseCategories.map(\.title))
        .onChange(of: selectedTitle) {
            updateSelectedCategoryFromBar()
        }
    }
    
    
    @AxisContentBuilder
    func yAxis() -> some AxisContent {
        AxisMarks { axisValue in
            AxisGridLine()
            AxisTick()
            AxisValueLabel {
                if let value = axisValue.as(Double.self) {
                    Text("$\(value.kVersion(1))")
                }
            }
        }
    }
    
    
    func updateSelectedCategoryFromBar() {
        let sel = model.expenseCategories.first(where: { $0.title == selectedTitle })
        selectedCategory = sel
    }
}
