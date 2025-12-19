//
//  CategoryAnalyticChartRawDataListForGroup.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/11/25.
//


import SwiftUI
import Charts

struct CatChartRawDataListForGroup: View {
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Environment(CalendarModel.self) private var calModel
    @Environment(CategoryModel.self) private var catModel
    
    @Bindable var model: CatChartViewModel
        
    @State private var yearlyData: Array<YearlyData> = []
    
    var displayRange: ClosedRange<Int> {
        let years = model.data.map { $0.year }
        return min((years.min() ?? 0), model.fetchYearStart)...max((years.max() ?? 0), model.fetchYearEnd)
    }
    
    var body: some View {
        /// Don't use `displayData` here since when viewing YTD, it will ommit the rest of the data and will look like it's missing.
        List {
            ForEach(Array(displayRange.reversed()), id: \.self) { year in
                let data = model.data.filter { $0.year == year }.sorted(by: { $0.date > $1.date })
                yearlySections(for: year, with: data)
            }
            
            Section {
                fetchMoreButton
            }
        }
        .tint(Color.theme)
        .navigationTitle("\(model.categoryGroup!.title) Data")
        .navigationSubtitle("\(String(model.fetchYearStart)) - \(String(AppState.shared.todayYear))")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                CatChartRefreshButton(model: model)
            }
        }
        #endif
        .onChange(of: calModel.showMonth) {
            if !$1 && $0 {
                Task { await model.fetchHistory(setChartAsNew: false) }
            }
        }
        .onChange(of: model.isLoadingHistory, initial: true) {
            if !$1 {
                yearlyData = buildYearlyData(from: model.data)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .updateCategoryAnalytics, object: nil)) { _ in
            Task { await model.fetchHistory(setChartAsNew: false) }
        }
    }
    
    @ViewBuilder
    func yearlySections(for year: Int, with data: Array<CategoryAnalyticData>) -> some View {
        ForEach(yearlyData) { yearly in
            Section(String(yearly.year)) {
                ForEach(yearly.months) { monthly in
                    NavigationLink {
                        monthlyCategories(monthlyData: monthly, year: year)
                    } label: {
                        HStack {
                            Text("\(monthly.monthName) \(String(year))")
                            Spacer()
                            //Text("\(monthly.expenses.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                            
                            let metricText = switch model.displayedMetric {
                            case .income: monthly.income
                            case .expenses: monthly.expenses
                            case .budget: monthly.budget
                            case .expensesMinusIncome: monthly.expensesMinusIncome
                            }
                            
                            Text(metricText.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func monthlyCategories(monthlyData: MonthlyData, year: Int) -> some View {
        List {
            Section {
                HStack {
                    monthlyCategoriesPieChart(monthlyData: monthlyData)
                    monthlyCategoriesBarChart(monthlyData: monthlyData)
                }
                
            }
            
//            Section {
//                monthlyCategoriesPieChart(monthlyData: monthlyData)
//            }
        
            Section("Data") {
                ForEach(monthlyData.data) { data in
                    CatChartRawDataListLine(category: data.category, data: data, labelType: .category, model: model)
                }
            }                        
        }
        .navigationTitle("\(monthlyData.monthName) Data")
        .navigationSubtitle(String(year))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                CatChartRefreshButton(model: model)
            }
        }
        #endif
    }
    
    
    @ViewBuilder
    func monthlyCategoriesBarChart(monthlyData: MonthlyData) -> some View {
        Chart {
            ForEach(monthlyData.data) { data in
                let metricToDisplay = switch model.displayedMetric {
                case .income: data.income
                case .expenses: data.expenses
                case .budget: data.budget
                case .expensesMinusIncome: data.expensesMinusIncome
                }
                
                BarMark(
                    x: .value("Category", data.category.title),
                    y: .value("Amount", metricToDisplay),
                )
                .foregroundStyle(data.category.color)
            }
        }
        .frame(minHeight: 150)
    }
    
    
    @ViewBuilder
    func monthlyCategoriesPieChart(monthlyData: MonthlyData) -> some View {
        HStack {
            Chart {
                ForEach(monthlyData.data) { data in
                    let metricToDisplay = switch model.displayedMetric {
                    case .income: data.income
                    case .expenses: data.expenses
                    case .budget: data.budget
                    case .expensesMinusIncome: data.expensesMinusIncome
                    }
                    
                    SectorMark(angle: .value("Amount", metricToDisplay), innerRadius: .ratio(0.4), angularInset: 1.0)
                        .cornerRadius(2)
                        .foregroundStyle(data.category.color)
                }
            }
            .frame(minHeight: 150)
            
            //chartLegend(monthlyData: monthlyData)
        }
    }
    
    
    @ViewBuilder
    func chartLegend(monthlyData: MonthlyData) -> some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(monthlyData.data) { data in
                    let metricToDisplay = switch model.displayedMetric {
                    case .income: data.income
                    case .expenses: data.expenses
                    case .budget: data.budget
                    case .expensesMinusIncome: data.expensesMinusIncome
                    }
                    
                    VStack(spacing: 0) {
                        HStack(spacing: 5) {
                            ChartCircleDot(
                                budget: data.budget,
                                expenses: metricToDisplay,
                                color: data.category.color,
                                size: 22
                            )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(data.category.title)
                                    .foregroundStyle(Color.secondary)
                                    .font(.subheadline)
                                
                                if metricToDisplay != 0 {
                                    Text("\(metricToDisplay.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                                        .foregroundStyle(Color.secondary)
                                        .font(.caption2)
                                } else {
                                    Text("-")
                                        .foregroundStyle(Color.secondary)
                                        .font(.caption2)
                                }
                            
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .contentMargins(.bottom, 10, for: .scrollContent)
        .frame(height: 150)
    }
    
 
    var fetchMoreButton: some View {
        Button("Fetch \(String(model.fetchYearStart - 10)) - \(String(model.fetchYearEnd - 10))", action: model.fetchMoreHistory)
            .tint(.gray)
    }
    
    
    func buildYearlyData(from data: [CategoryAnalyticData]) -> [YearlyData] {
        let groupedByYear = Dictionary(grouping: data, by: { $0.year })
        var yearlyResult: [YearlyData] = []

        for (year, yearItems) in groupedByYear {
            let groupedByMonth = Dictionary(grouping: yearItems, by: { $0.month })
            var monthlyResult: [MonthlyData] = []

            for (month, monthItems) in groupedByMonth {
                let monthName = NavDestination.getMonthFromInt(month)?.displayName ?? "N/A"
                let income = monthItems.reduce(0.0) { $0 + $1.income }
                let expenses = monthItems.reduce(0.0) { $0 + $1.expenses }
                let budget = monthItems.reduce(0.0) { $0 + $1.budget }
                let expensesMinusIncome = monthItems.reduce(0.0) { $0 + $1.expensesMinusIncome }
                
                let data = data
                    .filter { $0.year == year && $0.date.month == month }
                    .sorted(by: {
                        switch LocalStorage.shared.categorySortMode {
                        case .title:
                            return $0.category.title.lowercased() < $1.category.title.lowercased()
                        case .listOrder:
                            return $0.category.listOrder ?? 0 < $1.category.listOrder ?? 0
                        }
                    })
                    //.sorted(by: { $0.category.title < $1.category.title })
                
                //let cats = monthItems.compactMap { catModel.getCategory(by: $0.record.id) }

                let monthly = MonthlyData(
                    month: month,
                    monthName: monthName,
                    income: income,
                    expenses: expenses,
                    budget: budget,
                    expensesMinusIncome: expensesMinusIncome,
                    data: data
                )

                monthlyResult.append(monthly)
            }

            monthlyResult.sort { $0.month > $1.month }

            let yearly = YearlyData(year: year, months: monthlyResult)
            yearlyResult.append(yearly)
        }

        yearlyResult.sort { $0.year > $1.year }

        return yearlyResult
    }
    
    
    struct YearlyData: Identifiable {
        var id: Int { return year }
        var year: Int
        var months: [MonthlyData]
    }
    
    
    struct MonthlyData: Identifiable {
        var id: Int { return month }
        var month: Int
        var monthName: String
        var income: Double
        var expenses: Double
        var budget: Double
        var expensesMinusIncome: Double
        var data: [CategoryAnalyticData]
    }
    
}
