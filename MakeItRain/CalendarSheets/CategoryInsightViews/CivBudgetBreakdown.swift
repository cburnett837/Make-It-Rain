//
//  CivBudgetBreakdown.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/16/26.
//

import SwiftUI
import Charts

struct CategoryChartData: Identifiable {
    var id: String {category.id}
    var category: CBCategory
    var data: [ChartData]
}

@Observable
class GroupChartData: Identifiable {
    var id: String {group.id}
    var group: CBCategoryGroup
    var data: [ChartData] // This is data for each category
    
    var budgetAmount: Double// { data.map { $0.budgetForCategoryGroup ?? 0.0 }.reduce(0.0, +) }
    var expenseAmount: Double { data.map { ($0.expenses == 0 ? 0 : $0.expenses * -1 - $0.income) }.reduce(0.0, +) }
    var incomeAmount: Double { data.map { $0.income }.reduce(0.0, +) }
    var varianceAmount: Double {
        let overUnder = (budgetAmount) - (expenseAmount + incomeAmount)
        return overUnder
    }
    
    var isExpanded: Bool = false
    
    init(group: CBCategoryGroup, budget: Double, data: [ChartData]) {
        self.group = group
        self.budgetAmount = budget
        self.data = data
        self.isExpanded = false
    }
}


struct CivBudgetBreakdown: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(CalendarModel.self) private var calModel
    
    @Bindable var model: CivViewModel
    var prepareData: () -> ()
    
    @State private var breakdownOrChart = "breakdown"
    @State private var rawSelectedData: String?
    //@State private var groupData: [GroupChartData] = []
    @State private var rowWidth: CGFloat = 0


    var selectedData: ChartData? {
        guard let rawSelectedData else { return nil }
        return model.budgetVsSpendChartData.filter { $0.category.title == rawSelectedData }.first
    }
    var relevantData: [ChartData] {
        model.budgetVsSpendChartData.filter { $0.expenses < 0 || $0.income > 0 }
    }
    
    
    var body: some View {
        Section {
            if breakdownOrChart == "chart" {
                verticalBarChart
            } else {
                breakdownLines
                    .font(.caption)
//                BudgetBreakdownView(
//                    chartData: model.budgetVsSpendChartData,
//                    groupData: groupData,
//                    calculateDataFunction: prepareData
//                )
            }
        } header: {
            expenseByCategoryHeaderMenu
        }
//        footer: {
//            BreakdownExportCsvButton(chartData: model.budgetVsSpendChartData)
//        }
        .lineLimit(1)
        .textCase(nil)
//        .task {
//            buildGroupData()
//        }
//        .onChange(of: model.budgetVsSpendChartData) {
//            buildGroupData()
//        }
    }
    
    
    @ViewBuilder
    var breakdownLines: some View {
        gridHeader
        
        ForEach(model.groupBudgetVsSpendChartData) { group in
            HStack {
                HStack {
                    GradientCircleDot(size: 12, colors: group.group.categories.map(\.color))
                    Button(group.group.title) {
                        withAnimation {
                            group.isExpanded.toggle()
                        }
                    }
                }
                .frame(width: rowWidth / 3, alignment: .leading)
                
                Text(group.budgetAmount.currencyWithDecimals())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                Text(group.expenseAmount.currencyWithDecimals())
                    .frame(maxWidth: .infinity, alignment: .leading)
                                            
                Text(group.incomeAmount.currencyWithDecimals())
                    .frame(maxWidth: .infinity, alignment: .leading)
                                            
                Text(abs(group.varianceAmount).currencyWithDecimals())
                    .foregroundStyle(group.varianceAmount < 0 ? .red : .green)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if group.isExpanded {
                ForEach(group
                    .data
                    .sorted { Helpers.categorySorter()($0.category, $1.category) }
                ) { data in
                    line(for: data, inset: true)
                }
            }
        }
        
        ForEach(model.budgetVsSpendChartData
            .filter { $0.categoryGroup == nil }
            .sorted { Helpers.categorySorter()($0.category, $1.category) }, id: \.id
        ) { catData in
            line(for: catData, inset: false)
        }
    }
    
    
    var expenseByCategoryHeaderMenu: some View {
        Menu {
            Section {
                Button {
                    breakdownOrChart = "chart"
                } label: {
                    Label("Chart", systemImage: "chart.bar.doc.horizontal")
                }
                
                Button {
                    breakdownOrChart = "breakdown"
                } label: {
                    Label("Breakdown", systemImage: "list.bullet")
                }
            }
            
//            Section {
//                exportCsvButton
//            }
        } label: {
            HStack(spacing: 4) {
                Text("Budget By Category")
                    .foregroundStyle(.gray)
                    .bold()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.gray)
                    .font(.subheadline)
            }
        }
    }
    
    
    var gridHeader: some View {
        HStack {
            HStack {
                ChartCircleDot(budget: 0, expenses: 0, color: .primary, size: 12)
                Text("Category")
            }
            .frame(width: rowWidth / 3, alignment: .leading)
            
            Text("Budget")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Expense")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Income")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Variance")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.caption)
        .lineLimit(1)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { self.rowWidth = $0 }
    }
    
    
    @ViewBuilder
    func line(for metric: ChartData, inset: Bool) -> some View {
        HStack {
            HStack {
                ChartCircleDot(
                    budget: metric.budgetForCategory,
                    expenses: metric.expenses,
                    color: metric.category.color,
                    size: 12
                )
                //.alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                
                Text(metric.category.title)
                    //.alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
            }
            //.frame(maxWidth: .infinity, alignment: .leading)
            .frame(width: rowWidth / 3, alignment: .leading)
            .padding(.leading, inset ? 10 : 0)
            
            Text(inset ? "N/A" : metric.budgetForCategory.currencyWithDecimals())
                .padding(.leading, inset ? 10 : 0)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(inset ? .gray : .primary)
                
            Text((metric.expenses == 0 ? 0 : metric.expensesMinusIncome).currencyWithDecimals())
                .padding(.leading, inset ? 10 : 0)
                .frame(maxWidth: .infinity, alignment: .leading)
                                        
            Text(metric.income.currencyWithDecimals())
                .padding(.leading, inset ? 10 : 0)
                .frame(maxWidth: .infinity, alignment: .leading)
                                        
            let overUnder = (metric.budgetForCategory) + (metric.expenses + metric.income)
            Text(inset ? "N/A" : abs(overUnder).currencyWithDecimals())
                .foregroundStyle(inset ? Color.gray : (overUnder < 0 ? .red : .green))
                .padding(.leading, inset ? 10 : 0)
                .frame(maxWidth: .infinity, alignment: .leading)
                //.frame(maxWidth: .infinity, alignment: .leading)
        }
        //.padding(.vertical, 4)
        //.contentShape(Rectangle())
    }
    
    
    var exportCsvButton: some View {
        // file rows
        let rows = model.budgetVsSpendChartData.map {
            let budget = $0.budgetForCategory
            let expense = ($0.expenses == 0 ? 0 : $0.expenses * -1)
            let income = ($0.income)
            let overUnder1 = $0.budgetForCategory + ($0.expenses + $0.income)
            let overUnder2 = abs(overUnder1)
            
            return [$0.category.title, String(budget), String(expense), String(income), String(overUnder2)]
        }
        return ExportCsvButton(fileName: "Breakdown-\(calModel.sMonth.name)-\(calModel.sYear).csv", headers: ["Category", "Budget", "Expenses", "Income", "Variance"], rows: rows) {
            Label("Export CSV", systemImage: "tablecells")
        }
    }
    
    
    var verticalBarChart: some View {
        VStack {
            Chart {
                ForEach(relevantData) { item in
                    if item.expensesMinusIncome > 0 {
                        BarMark(
                            x: .value("Amount", item.chartPercentage),
                            y: .value("Budget", item.category.title)
                        )
                        .foregroundStyle(getColor(for: item.category, withOpacity: false))
                    }
                    
                    BarMark(
                        x: .value("Amount", 100 - item.chartPercentage),
                        y: .value("Budget", item.category.title)
                    )
                    //.foregroundStyle(getColor(for: item.category, withOpacity: true))
                    .foregroundStyle(.clear)
                    .annotation(position: .top, alignment: .trailing, spacing: 0) {
                        percentageAnnotation(for: item)
                    }
                }
                
                if let selectedData {
                    BarMark(
                        x: .value("Amount", 0),
                        y: .value("Budget", selectedData.category.title)
                    )
                    .foregroundStyle(.clear)
                    .annotation(
                        position: .automatic,
                        alignment: .trailing,
                        spacing: 0,
                        overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
                    ) {
                        barChartAnnotation
                    }
                }
            }
            .chartXAxis {
                AxisMarks(
                    format: Decimal.FormatStyle.Percent.percent.scale(1),
                    values: [0, 25, 50, 75, 100]
                )
            }
            .chartYSelection(value: $rawSelectedData.animation())
            .chartScrollTargetBehavior(.valueAligned(unit: 1))
            .frame(height: CGFloat(relevantData.count) * 30)
        }
    }
    
    
    var barChartAnnotation: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(selectedData!.category.title.capitalized)
                Spacer()
                
                ChartCircleDot(
                    budget: selectedData!.budgetForCategory,
                    expenses: abs(selectedData!.expenses),
                    color: colorScheme == .dark ? .white : .black,
                    size: 20
                )
                
                Image(systemName: selectedData!.category.emoji ?? "circle")
            }
            .font(.headline)
            
            Divider()
            Text("Budget: \(selectedData!.budgetForCategory.currencyWithDecimals())")
                .bold()
            Text("Income: \(selectedData!.income.currencyWithDecimals())")
                .bold()
            Text("Expenses: \((selectedData!.expenses * -1).currencyWithDecimals())")
                .bold()
        }
        .foregroundStyle(.white)
        .padding(12)
        .frame(minWidth: 180)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(selectedData!.category.color)
        )
        .accessibilityHidden(true)
    }
    
    
    @ViewBuilder
    func percentageAnnotation(for item: ChartData) -> some View {
        Text("\(Int(item.actualPercentage))%")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    
    
    func getColor(for category: CBCategory, withOpacity: Bool) -> Color {
        selectedData == nil
        ? category.color.opacity(withOpacity ? 0.2 : 1)
        : selectedData!.category.id == category.id
        ? category.color.opacity(withOpacity ? 0.2 : 1)
        : .gray.opacity(0.5)
    }
    
    
//    func buildGroupData() {
//        print("-- \(#function)")
//        var groups: [GroupChartData] = []
//        
//        for each in model.budgetVsSpendChartData {
//            guard let group = each.categoryGroup else { continue }
//            
//            if let index = groups.firstIndex(where: { $0.group.id == group.id }) {
//                groups[index].data.append(each)
//            } else {
//                groups.append(GroupChartData(group: group, budget: each.budgetForCategoryGroup ?? 0, data: [each]))
//            }
//        }
//        
//        groupData = groups
//    }
}
