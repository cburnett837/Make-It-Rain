////
////  CivCharts.swift
////  MakeItRain
////
////  Created by Cody Burnett on 12/19/25.
////
//
//import SwiftUI
//import Charts
//
//
//struct CivChartLegend: View {
//    @Environment(CalendarModel.self) private var calModel
//    @Bindable var model: CivViewModel
//    
//    var data: [ChartData] {
//        (model.budgetVsSpendChartData + model.groupBudgetVsSpendChartData.flatMap {$0.data})
//            .sorted { Helpers.categorySorter()($0.category, $1.category) }
//            //.sorted(by: Helpers.categorySorter()($0.category, $1.category))
//            .uniqued { $0.category.id }
//    }
//    
//    var body: some View {
//        chartLegend
//    }
//    
//    var chartLegend: some View {
//        ScrollView(.horizontal) {
//            ZStack {
//                Spacer()
//                    .containerRelativeFrame([.horizontal])
//                    .frame(height: 1)
//                                            
//                HStack(spacing: 0) {
//                    ForEach(data) { item in
//                        HStack(alignment: .circleAndTitle, spacing: 5) {
//                            //Text("\(item.category.active)")
//                            Circle()
//                                .fill(item.category.color)
//                                .frame(maxWidth: 8, maxHeight: 8) // 8 seems to be the default from charts
//                                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                            
//                            VStack(alignment: .leading, spacing: 2) {
//                                Text(item.category.title)
//                                    .foregroundStyle(Color.secondary)
//                                    .font(.caption2)
//                                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                            }
//                        }
//                        .padding(.horizontal, 4)
//                        .contentShape(Rectangle())
//                    }
//                    Spacer()
//                }
//            }
//        }
//        .scrollBounceBehavior(.basedOnSize)
//        .contentMargins(.vertical, 10, for: .scrollContent)
//    }
//}
//
//
//struct CivBudgetCompareChart: View {
//    @Environment(CalendarModel.self) private var calModel
//    @Bindable var model: CivViewModel
//    
//    @State private var rawSelectedAngle: Double?
//    @State private var rawSelectedBar: Double?
//    private var selectedData: ChartData? {
//        var theValue: Double = 0.0
//        if rawSelectedBar == nil && rawSelectedAngle == nil { return nil }
//        if let raw = rawSelectedBar { theValue = raw }
//        if let raw = rawSelectedAngle { theValue = raw }
//        //guard let rawSelectedAngle else { return nil }
//        
//        var total = 0.0
//        for item in pieChartData {
//            let value = max(0, item.expenses * -1)
//            let nextTotal = total + value
//            
//            if theValue >= total && theValue < nextTotal {
//                //print("selected angle:", rawSelectedAngle)
//                //print("selected category:", item.category.title)
//                return item
//            }
//            
//            total = nextTotal
//        }
//        
//        return nil
//    }
//    
//    var isUnderBudget: Bool {
//        return model.budget >= barChartData.map ({ ($0.expenses * -1) - $0.income }).reduce(0.0, +)
//    }
//    
////    private struct CategorySpendingBar: Identifiable, Equatable {
////        let id: String
////        let category: CBCategory
////        let group: CBCategoryGroup?
////        let cost: Double
////    }
//    
////    private var pieChartData: [CategorySpendingBar] {
////        let catData = model.actualSpendingBreakdownByCategoryChartData.filter { $0.group == nil }.map { chartData in
////            CategorySpendingBar(
////                id: chartData.category!.id,
////                category: chartData.category!,
////                group: nil,
////                cost: chartData.data.map(\.cost).reduce(0, +)
////            )
////        }
////        
////        let groupCatData = model.actualSpendingBreakdownByCategoryChartData.filter { $0.group != nil }.flatMap { chartData in
////            return chartData.group!.categories.compactMap { cat in
////                CategorySpendingBar(
////                    id: chartData.group!.id,
////                    category: cat,
////                    group: chartData.group!,
////                    cost: chartData.data.filter { $0.category?.id == cat.id }.map(\.cost).reduce(0, +)
////                )
////            }
////        }
////        
////        return (catData + groupCatData)
////            .uniqued(on: { $0.category.id })
////            .sorted { Helpers.categorySorter()($0.category, $1.category) }
////            //.sorted(by: { $0.cost < $1.cost })
////    }
//    
//    
//    private var pieChartData: [ChartData] {
//        /// This gives you a list of category, each containing a list of months and their associated dollar amounts.
//        /// This says "For each category, sum up the totals from the months".
//        /// ``CivActualSpendingBreakdownByCategoryOuterChartData``
//        let catData = model.actualSpendingBreakdownByCategoryChartData.filter { $0.group == nil }.map { chartData in
//            return ChartData(
//                category: chartData.category ?? CBCategory(),
//                budgetForCategory: chartData.costPerMonth.map(\.budgetForCategory).reduce(0, +),
//                categoryGroup: nil,
//                budgetForCategoryGroup: nil,
//                income: chartData.costPerMonth.map(\.income).reduce(0, +),
//                incomeMinusPayments: chartData.costPerMonth.map(\.incomeMinusPayments).reduce(0, +),
//                expenses: chartData.costPerMonth.map(\.expenses).reduce(0, +),
//                expensesMinusIncome: chartData.costPerMonth.map(\.expensesMinusIncome).reduce(0, +),
//                chartPercentage: 0,
//                actualPercentage: 0,
//                budgetObjects: nil
//            )
//        }
//        
//        let groupCatData = model.actualSpendingBreakdownByCategoryChartData.filter { $0.group != nil }.flatMap { chartData in
//            return chartData.group!.categories.compactMap { cat in
//                                
//                let income = chartData.costPerMonth             .filter({ $0.category.id == cat.id }).map(\.income).reduce(0, +)
//                let incomeMinusPayments = chartData.costPerMonth.filter({ $0.category.id == cat.id }).map(\.incomeMinusPayments).reduce(0, +)
//                let expenses = chartData.costPerMonth           .filter({ $0.category.id == cat.id }).map(\.expenses).reduce(0, +)
//                let expensesMinusIncome = chartData.costPerMonth.filter({ $0.category.id == cat.id }).map(\.expensesMinusIncome).reduce(0, +)
//                
//                return ChartData(
//                    category: cat,
//                    budgetForCategory: 0,
//                    categoryGroup: chartData.group!,
//                    budgetForCategoryGroup: 0,
//                    income: income,
//                    incomeMinusPayments: incomeMinusPayments,
//                    expenses: expenses,
//                    expensesMinusIncome: expensesMinusIncome,
//                    chartPercentage: 0,
//                    actualPercentage: 0,
//                    budgetObjects: nil
//                )
//            }
//        }
//        
//        return (catData + groupCatData)
//            .uniqued(on: { $0.category.id })
//            .sorted { Helpers.categorySorter()($0.category, $1.category) }
//            //.sorted(by: { $0.cost < $1.cost })
//    }
//    
//    
//    
//    var barChartData: [ChartData] {
//        let normalData = model.budgetVsSpendChartData
//        let groupData = model.groupBudgetVsSpendChartData.flatMap { $0.data }
//        return (groupData + normalData)
//            .sorted { Helpers.categorySorter()($0.category, $1.category) }
//            .uniqued(on: {$0.category.id})
//    }
//    
//    var body: some View {
//        VStack(spacing: 10) {
//            HStack {
//                barChart
//                pieChart
//            }                        
//            
//            CivChartLegend(model: model)
//        }
//        .sensoryFeedback(.selection, trigger: selectedData)
//    }
//    
//    
//    var pieChart: some View {
//        Chart(pieChartData) { data in
//            SectorMark(
//                angle: .value("Amount", (data.expenses * -1 < 0) ? 0 : (data.expenses * -1)),
//                innerRadius: .ratio(0.4),
//                angularInset: 1.0
//            )
//            .cornerRadius(5)
//            .foregroundStyle(data.category.color)
//            .opacity(selectedData == nil ? 1 : (data.category.id == selectedData!.category.id ? 1 : 0.3))
//        }
//        .chartAngleSelection(value: $rawSelectedAngle)
//        .frame(minHeight: 150)
//        .overlay {
//            if rawSelectedBar != nil, selectedData != nil {
//                barChartAnnotation
//            }
//        }
//    }
//    
//    
//    var barChart: some View {
//        Chart {
//            if calModel.sCategoryGroupsForAnalysis.isEmpty {
//                ForEach(barChartData) { metric in
//                    BarMark(
//                        x: .value("Budget", metric.budgetForCategory),
//                        y: .value("Key", "Budget")
//                    )
//                    .foregroundStyle(metric.category.color)
//                }
//            } else {
//                RuleMark(x: .value("Budget", model.budget))
//                    .foregroundStyle(isUnderBudget ? Color.green.gradient : Color.red.gradient)
//                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
//                    .zIndex(1)
//            }
//                                    
//            ForEach(barChartData) { metric in
//                BarMark(
//                    x: .value("Amount", metric.expensesMinusIncome),
//                    y: .value("Key", "Actual Spending")
//                )
//                .foregroundStyle(metric.category.color)
//                .opacity(selectedData == nil ? 1 : (metric.category.id == selectedData!.category.id ? 1 : 0.3))
//                .zIndex(0)
//            }
//        }
//        .chartXSelection(value: $rawSelectedBar)
//        .chartXAxis {
//            AxisMarks {
//                let value = $0.as(Int.self)!
//                AxisGridLine()
//                //AxisTick()
//                
//                //AxisValueLabel(format: .currency(code: "USD"))
//
//                
//                AxisValueLabel {
//                    Text("$\(value)")
//                }
//            }
//        }
//        .if(!calModel.sCategoryGroupsForAnalysis.isEmpty) {
//            $0.chartYAxis {
//                AxisMarks { value in
//                    AxisGridLine()
//                    AxisTick()
//                    // Do not include AxisValueLabel() here to hide labels
//                }
//            }
//        }
//        .chartLegend(.hidden)
//        //.opacity(selectedData == nil ? 1 : 0)
//        .overlay {
//            if rawSelectedAngle != nil, selectedData != nil {
//                barChartAnnotation
//            }
//        }
//    }
//    
//    
//    
//    var barChartAnnotation: some View {
//        VStack(alignment: .leading) {
//            HStack {
//                Text(selectedData!.category.title.capitalized)
//                    .lineLimit(1)
//                Spacer()
//                
//                ChartCircleDot(
//                    budget: selectedData!.budgetForCategory,
//                    expenses: abs(selectedData!.expenses),
//                    color: .white,
//                    size: 20
//                )
//                
//                Image(systemName: selectedData!.category.emoji ?? "circle")
//            }
//            .font(.headline)
//            
//            Divider()
//            
//            Grid(alignment: .leading) {
//                if selectedData!.categoryGroup == nil {
//                    GridRow {
//                        Text("Budget")
//                            .bold()
//                        Text(selectedData!.budgetForCategory.currencyWithDecimals())
//                    }
//                }
//                GridRow {
//                    Text("Income")
//                        .bold()
//                    Text(selectedData!.income.currencyWithDecimals())
//                }
//                GridRow {
//                    Text("Expenses")
//                        .bold()
//                    Text((selectedData!.expenses * -1).currencyWithDecimals())
//                }
//                
//                Divider()
//                
//                GridRow {
//                    Text("Actual Spend")
//                        .bold()
//                    Text((selectedData!.expensesMinusIncome).currencyWithDecimals())
//                }
//            }
//            .font(.subheadline)
//            
////            if selectedData!.categoryGroup == nil {
////                Text("Budget: \(selectedData!.budgetForCategory.currencyWithDecimals())")
////                    .bold()
////            }
//////            else {
//////                Text("Budget: (Part of group)")
//////                    .bold()
//////                    .foregroundStyle(.gray)
//////            }
////            
////            Text("Income: \(selectedData!.income.currencyWithDecimals())")
////                .bold()
////            
////            Text("Expenses: \((selectedData!.expenses * -1).currencyWithDecimals())")
////                .bold()
//        }
//        .foregroundStyle(.white)
//        .padding(12)
//        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
//        //.frame(minWidth: 180)
//        .background(
//            RoundedRectangle(cornerRadius: 10)
//                .fill(selectedData!.category.color)
//        )
//        .accessibilityHidden(true)
//    }
//}
//
//
//struct CivSpendingBreakdownChart: View {
//    @Environment(CalendarModel.self) private var calModel
//    @Bindable var model: CivViewModel
//    
//    var body: some View {
//        Chart(model.spendingBreakdownChartdata) { data in
//            LineMark(
//                x: .value("Month", data.date),
//                y: .value("Amount", data.cost * -1)
//            )
//            .interpolationMethod(.cardinal)
//            .foregroundStyle(Color.theme)
//            .symbol(by: .value("Month", "month"))
//        }
//        .chartLegend(.hidden)
//        .chartXAxis { model.chartXAxis }
//    }
//}
//
//
//struct CivTransactionCountChart: View {
//    @Environment(CalendarModel.self) private var calModel
//    @Bindable var model: CivViewModel
//       
//    var body: some View {
//        Chart(model.transactionCountChartData) { data in
//            LineMark(
//                x: .value("Month", data.date),
//                y: .value("Amount", data.count)
//            )
//            .interpolationMethod(.cardinal)
//            .foregroundStyle(Color.theme)
//            .symbol(by: .value("Month", "month"))
//        }
//        .chartLegend(.hidden)
//        .chartXAxis { model.chartXAxis }
//    }
//}
//
//
//struct CivActualSpendingByCategoryByMonthLineChart: View {
//    /* TITLE
//    Actual Spending Over Time
//    (By category)
//    */
//        
//    @Environment(CalendarModel.self) private var calModel
//    @Bindable var model: CivViewModel
//    
//    var body: some View {
//        Chart {
//            ForEach(model.actualSpendingBreakdownByCategoryChartData) { item in
//                ForEach(item.costPerMonth) { data in
//                    let category = item.group == nil ? item.category! : data.category
//                    
//                    LineMark(
//                        x: .value("Month", data.dateForMonth ?? Date()),
//                        y: .value("Amount", data.expenses * -1),
//                        series: .value("", category.id)
//                    )
//                    .interpolationMethod(.cardinal)
//                    .foregroundStyle(category.color)
//                }
//            }
//        }
//        .chartLegend(.hidden)
//        .chartXAxis { model.chartXAxis }
//    }
//}
//
////
////struct CivActualSpendingByCategoryPieChart: View {
////    /* TITLE
////     Actual Spending
////     //(Summary)
////     */
////    @Environment(CalendarModel.self) private var calModel
////    @Bindable var model: CivViewModel
////    
////    @State private var rawSelectedAngle: Double?
////    private var selectedData: CategorySpendingBar? {
////        guard let rawSelectedAngle else { return nil }
////        
////        var total = 0.0
////        for item in chartData {
////            let value = max(0, item.cost * -1)
////            let nextTotal = total + value
////            
////            if rawSelectedAngle >= total && rawSelectedAngle < nextTotal {
////                print("selected angle:", rawSelectedAngle)
////                print("selected category:", item.category.title)
////                return item
////            }
////            
////            total = nextTotal
////        }
////        
////        return nil
////    }
////    
////    private struct CategorySpendingBar: Identifiable {
////        let id: String
////        let category: CBCategory
////        let group: CBCategoryGroup?
////        let cost: Double
////    }
////    
////    private var chartData: [CategorySpendingBar] {
////        let catData = model.actualSpendingBreakdownByCategoryChartData.filter { $0.group == nil }.map { chartData in
////            CategorySpendingBar(
////                id: chartData.category!.id,
////                category: chartData.category!,
////                group: nil,
////                cost: chartData.data.map(\.cost).reduce(0, +)
////            )
////        }
////        
////        let groupCatData = model.actualSpendingBreakdownByCategoryChartData.filter { $0.group != nil }.flatMap { chartData in
////            return chartData.group!.categories.compactMap { cat in
////                CategorySpendingBar(
////                    id: chartData.group!.id,
////                    category: cat,
////                    group: chartData.group!,
////                    cost: chartData.data.filter { $0.category?.id == cat.id }.map(\.cost).reduce(0, +)
////                )
////            }
////        }
////        
////        return (catData + groupCatData)
////            .uniqued(on: { $0.category.id })
////            .sorted { Helpers.categorySorter()($0.category, $1.category) }
////            //.sorted(by: { $0.cost < $1.cost })
////    }
////    
////    /// The model data needs to be flattened since it is per month. Without it you will end up with an orange food slice for every selected month.
////    var body: some View {
////        VStack {
////            Chart(chartData) { data in
////                SectorMark(
////                    angle: .value("Amount", (data.cost * -1 < 0) ? 0 : (data.cost * -1)),
////                    innerRadius: .ratio(0.4),
////                    angularInset: 1.0
////                )
////                .cornerRadius(5)
////                .foregroundStyle(data.category.color)
////                .opacity(selectedData == nil ? 1 : (data.category.id == selectedData!.category.id ? 1 : 0.3))
////            }
////            .chartAngleSelection(value: $rawSelectedAngle)
////            .frame(minHeight: 150)
////            
////            if let selectedData = selectedData {
////                barChartAnnotation
////            }
////        }
////    }
////}
//
//
//
//struct CivActualSpendingByCategoryBarChart: View {
//    /* TITLE
//    Actual Spending
//    //(Summary)
//    */
//    @Environment(CalendarModel.self) private var calModel
//    @Bindable var model: CivViewModel
//    
//    private struct CategorySpendingBar: Identifiable {
//        let id: String
//        let category: CBCategory?
//        let group: CBCategoryGroup?
//        let cost: Double
//    }
//    
//    private var chartData: [CategorySpendingBar] {
//        let catData = model.actualSpendingBreakdownByCategoryChartData.filter { $0.group == nil }.map { chartData in
//            CategorySpendingBar(
//                id: "0-\(chartData.category!.id)",
//                category: chartData.category!,
//                group: nil,
//                cost: chartData.costPerMonth.map(\.expenses).reduce(0, +)
//            )
//        }
//        
//        let groupCatData = model.actualSpendingBreakdownByCategoryChartData.filter { $0.group != nil }.flatMap { chartData in
//            return chartData.group!.categories.compactMap { cat in
//                CategorySpendingBar(
//                    id: "\(chartData.group!.id)-\(cat.id)",
//                    category: cat,
//                    group: chartData.group!,
//                    cost: chartData.costPerMonth.filter { $0.category.id == cat.id }.map(\.expenses).reduce(0, +)
//                )
//            }
//        }
//        
//        return catData + groupCatData
//    }
//    
//    
//    /// The model data needs to be flattened since it is per month. Without it the totals from the selected months will just stack together, instead of being calculated.
//    var body: some View {
//        Chart(chartData) { data in
//            BarMark(
//                x: .value("Amount", data.cost * -1),
//                y: .value("Category", data.group != nil ? data.group!.title : data.category!.title),
//            )
//            .foregroundStyle(data.category?.color ?? .secondary)
//        }
//        .frame(minHeight: 150)
//        .if(model.actualSpendingBreakdownByCategoryChartData.count >= 5) {
//            $0
//            .chartScrollableAxes(.vertical)
//            .chartYVisibleDomain(length: 5)
//        }
//        
//    }
//}
