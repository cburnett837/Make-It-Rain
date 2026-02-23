//
//  CategoryAnalyticChartChart.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/10/25.
//


import SwiftUI
import Charts

struct CatChart: View {
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("showAverageOnCategoryAnalyticChart") var showAverage: Bool = true
    @AppStorage("showBudgetOnCategoryAnalyticChart") var showBudget: Bool = true
    @AppStorage("showExpensesOnCategoryAnalyticChart") var showExpenses: Bool = true
    
    @Bindable var model: CatChartViewModel
    
    var body: some View {
        let _ = Self._printChanges()
        VStack {
            //customLegend
            chartLegend
            theChart
        }
        .opacity((model.isLoadingHistory || (model.displayData.isEmpty && !model.isLoadingHistory)) ? 0 : 1)
        .overlay { ProgressView().tint(.none).opacity(model.isLoadingHistory ? 1 : 0) }
        .overlay {
            if model.displayData.isEmpty && !model.isLoadingHistory {
                Text("No data")
                    .foregroundStyle(.gray)
            }
        }
        
        //Text("\(model.isLoadingHistory)")
        //Text("\((model.displayData.isEmpty && !model.isLoadingHistory))")
    }
    
//    @ViewBuilder
//    var customLegend: some View {
//        let averageText = model.average.currencyWithDecimals()
//        
//        HStack {
//            Circle()
//                .frame(width: 8, height: 8)
//                .foregroundStyle(.gray)
//            
//            Text("Average (month): \(averageText)")
//                .contentTransition(.numericText())
//                .foregroundStyle(.gray)
//                .font(.caption2)
//            
//            Spacer()
//        }
//    }
    
    
    @ViewBuilder
    var selectedDataView: some View {
        if let selectedMonth = model.selectedMonth {
            VStack(spacing: 0) {
                Text("\(selectedMonth.first?.date ?? Date(), format: .dateTime.month(.wide)) \(String(selectedMonth.first?.date.year ?? 0))")
                    .bold()
                HStack {
                    let metricText = switch model.displayedMetric {
                    case .income: selectedMonth.map { $0.income }.reduce(0.0, +)
                    case .expenses: selectedMonth.map { $0.expenses }.reduce(0.0, +)
                    case .budget: selectedMonth.map { $0.expenses }.reduce(0.0, +)
                    case .expensesMinusIncome: selectedMonth.map { $0.expensesMinusIncome}.reduce(0.0, +)
                    }
                    
                    Text(metricText.currencyWithDecimals())
                        .bold()
                    Text((selectedMonth.first?.budget ?? 0).currencyWithDecimals())
                        .bold()
                        .foregroundStyle(.secondary)
                    
                    if selectedMonth.first?.type == "category" {
                        ChartCircleDot(
                            budget: selectedMonth.map { $0.budget}.reduce(0.0, +),
                            expenses: selectedMonth.map { $0.expenses}.reduce(0.0, +),
                            color: .white, size: 20
                        )
                    }
                }
            }
            .foregroundStyle(.white)
            .padding(12)
            //.frame(width: 160)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(model.isForGroup ? .gray : model.category!.color)
                    //.fill(category.color)
                //                        .fill(Color.theme)
            )
        }
    }
    
    
    #warning("NOTE! The chart cannot have scrolling because it will cut off the selection overlay.")
    var theChart: some View {
        Chart {
            if let selectedMonth = model.selectedMonth,
            let first = selectedMonth.first {
                RuleMark(x: .value("Start Date", first.date, unit: .month))
                    .foregroundStyle(Color.secondary.opacity(0.5))
                    //.zIndex(-5)
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                        selectedDataView
                    }
            }
                                                
            ForEach(model.displayData) { data in
                let metricToDisplay = switch model.displayedMetric {
                case .income: data.income
                case .expenses: data.expenses
                case .budget: data.budget
                case .expensesMinusIncome: data.expensesMinusIncome
                }
                
                BarMark(
                    x: .value("Date", data.date, unit: .month),
                    y: .value("Amount", metricToDisplay),
                    //stacking: .normalized
                )
                .zIndex(-1)
                //.foregroundStyle(by: .value("Category", data.category.title))
                .foregroundStyle(showBudget ? data.category.color.opacity(0.4) : data.category.color)
                .if(!model.isForGroup) {
                    $0.opacity(data.date == model.selectedMonth?.first?.date ? 1 : (model.selectedMonth == nil ? 1 : 0.3))
                }
            }
            
            if showAverage {
                RuleMark(y: .value("Average", model.average))
                    .foregroundStyle(.gray.opacity(0.7))
                    //.zIndex(-1)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
            }
            
            if showBudget {
                ForEach(model.displayData) { data in
                    RectangleMark(
                        x: .value("Date", data.date, unit: .month),
                        y: .value("Budget", data.budget),
                        height: 2
                    )
                    .foregroundStyle(model.isForGroup ? (colorScheme == .dark ? .white : .black) : model.category!.color)
//                    .foregroundStyle(category.color.darker(by: 30))
                    //.foregroundStyle(Color.theme.lighter(by: 30))
                    //.foregroundStyle(getBudgetColor())
                    
//                    LineMark(
//                        x: .value("Date", data.date, unit: .month),
//                        y: .value("Budget", data.budget),
//                        series: .value("", "Budget")
//                    )
//                    .foregroundStyle(category.color.lighter(by: 20))
                }
            }
        }
//        .animation(.none, value: selectedMonth)
//        .animation(.none, value: rawSelectedDate)
        .sensoryFeedback(.selection, trigger: model.selectedMonth?.first?.id) { $0 != nil && $1 != nil }
        .frame(minHeight: 150)
        //.chartXVisibleDomain(length: visibleChartAreaDomain)
        .chartXSelection(value: $model.rawSelectedDate)
        .chartYAxis {
            AxisMarks {
                AxisGridLine()
                let value = $0.as(Int.self)!
                AxisValueLabel {
                   Text("$\(value)")
                }
            }
        }
//        .chartXAxis {
//            AxisMarks(position: .bottom, values: .automatic) { _ in
//                AxisTick()
//                AxisGridLine()
//                AxisValueLabel(centered: false)
//            }
//        }
        .chartXAxis {
            if (Calendar.current.dateComponents([.month], from: model.minDate, to: model.maxDate).month ?? 0) < 6 {
                AxisMarks(values: .stride(by: .month)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel(centered: true) {
                            Text(date, format: .dateTime.month(.abbreviated)) // Displays abbreviated month name (e.g., "Jan", "Feb")
                        }
                    }
                }
            } else {
                AxisMarks(position: .bottom, values: .automatic) { _ in
                    AxisTick()
                    AxisGridLine()
                    AxisValueLabel(centered: false)
                }
            }            
        }
        .chartLegend(position: .top, alignment: .leading)
        .padding(.bottom, 10)
    }
    
    var chartLegend: some View {
        ScrollView(.horizontal) {
            ZStack {
                Spacer()
                    .containerRelativeFrame([.horizontal])
                    .frame(height: 1)
                                            
                HStack(spacing: 0) {
                    let averageText = model.average.currencyWithDecimals()
                    
                    HStack(spacing: 5) {
                        Circle()
                            .frame(width: 8, height: 8)
                            .foregroundStyle(.gray)
                        
                        Text("Average (month): \(averageText)")
                            .contentTransition(.numericText())
                            .foregroundStyle(.gray)
                            .font(.caption2)
                    }
                    .padding(.trailing, 4)
                    
                    let cats = model.data.map { $0.category }.uniqued(on: \.id).sorted(by: {
                        switch AppSettings.shared.categorySortMode {
                        case .title:
                            return $0.title.lowercased() < $1.title.lowercased()
                        case .listOrder:
                            return $0.listOrder ?? 0 < $1.listOrder ?? 0
                        }
                    })
                    
                    ForEach(cats) { category in
                        HStack(spacing: 5) {
                            Circle()
                                .fill(category.color)
                                .frame(maxWidth: 8, maxHeight: 8) // 8 seems to be the default from charts
                                //.alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.title)
                                    .foregroundStyle(Color.secondary)
                                    .font(.caption2)
                                    //.alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
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
        .contentMargins(.bottom, 10, for: .scrollContent)
    }
}
