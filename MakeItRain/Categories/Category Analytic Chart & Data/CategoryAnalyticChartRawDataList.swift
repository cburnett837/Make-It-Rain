//
//  CategoryAnalyticChartRawDataList.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/10/25.
//

import SwiftUI

struct CatChart<Content: View>: View {
    @Environment(CalendarModel.self) private var calModel
    @Bindable var model: CategoryAnalyticChartViewModel
    var refreshButton: () -> Content
    
    var displayRange: ClosedRange<Int> {
        let years = model.data.map { $0.year }
        return min((years.min() ?? 0), model.fetchYearStart)...max((years.max() ?? 0), model.fetchYearEnd)
    }
        
    var body: some View {
        Section {
            NavigationLink {
                List {
                    /// Don't use `displayData` here since when viewing YTD, it will ommit the rest of the data and will look like it's missing.
                    ForEach(Array(displayRange.reversed()), id: \.self) { year in
                        let data = model.data.filter { $0.year == year }.sorted(by: { $0.date > $1.date })
                        yearlySections(for: year, with: data)
                    }
                    
                    Section {
                        fetchMoreButton
                    }
                }
                .navigationTitle("\(model.category!.title) Data")
                .navigationSubtitle("\(String(model.fetchYearStart)) - \(String(AppState.shared.todayYear))")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        refreshButton()
                    }
                }
                #endif
            } label: {
                Text("Show All")
            }
            .tint(Color.theme)
            .onChange(of: calModel.showMonth) {
                if !$1 && $0 {
                    Task { await model.fetchHistory(setChartAsNew: false) }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .updateCategoryAnalytics, object: nil)) { _ in
                Task { await model.fetchHistory(setChartAsNew: false) }
            }
        } header: {
            Text("Data By Month")
        }
    }
    
    
    @ViewBuilder
    func yearlySections(for year: Int, with data: Array<CategoryAnalyticData>) -> some View {
        Section(String(year)) {
            if data.isEmpty {
                Text("No Transactions")
                    .foregroundStyle(.gray)
            } else {
                ForEach(data) { data in
                    CategoryAnalyticChartRawDataListLineItem(category: model.category!, data: data)
                }
            }
        }
    }
    
    
    var fetchMoreButton: some View {
        Button("Fetch \(String(model.fetchYearStart - 10)) - \(String(model.fetchYearEnd - 10))", action: model.fetchMoreHistory)
            .tint(model.category!.color)
    }
}




struct CategoryAnalyticChartRawDataListForGroup<Content: View>: View {
    @Local(\.useWholeNumbers) var useWholeNumbers
    
    @Environment(CalendarModel.self) private var calModel
    @Environment(CategoryModel.self) private var catModel
    
    @Bindable var model: CategoryAnalyticChartViewModel
    var refreshButton: () -> Content
    
    var displayRange: ClosedRange<Int> {
        let years = model.data.map { $0.year }
        return min((years.min() ?? 0), model.fetchYearStart)...max((years.max() ?? 0), model.fetchYearEnd)
    }
    
    @State private var yearlyData: Array<YearlyData> = []
    
    
    var body: some View {
        NavigationLink {
            List {
                /// Don't use `displayData` here since when viewing YTD, it will ommit the rest of the data and will look like it's missing.
                ForEach(Array(displayRange.reversed()), id: \.self) { year in
                    let data = model.data.filter { $0.year == year }.sorted(by: { $0.date > $1.date })
                    yearlySections(for: year, with: data)
                }
                
                Section {
                    fetchMoreButton
                }
            }
            .navigationTitle("\(model.categoryGroup!.title) Data")
            .navigationSubtitle("\(String(model.fetchYearStart)) - \(String(AppState.shared.todayYear))")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    refreshButton()
                }
            }
            .onChange(of: model.isLoadingHistory, initial: true) {
                if !$1 {
                    yearlyData = buildYearlyData(from: model.data)
                }                
            }
//            .task {
//                yearlyData = buildYearlyData(from: model.data)
//            }
            #endif
        } label: {
            Text("Show All")
        }
        .tint(Color.theme)
        .onChange(of: calModel.showMonth) {
            if !$1 && $0 {
                Task { await model.fetchHistory(setChartAsNew: false) }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .updateCategoryAnalytics, object: nil)) { _ in
            Task { await model.fetchHistory(setChartAsNew: false) }
        }
    }
    
    func buildYearlyData(from data: [CategoryAnalyticData]) -> [YearlyData] {
        let groupedByYear = Dictionary(grouping: data, by: { $0.year })
        var yearlyResult: [YearlyData] = []

        for (year, yearItems) in groupedByYear {
            let groupedByMonth = Dictionary(grouping: yearItems, by: { $0.month })
            var monthlyResult: [MonthlyData] = []

            for (month, monthItems) in groupedByMonth {
                let monthName = NavDestination.getMonthFromInt(month)?.displayName ?? "N/A"
                let totalExpense = monthItems.reduce(0.0) { $0 + $1.expenses }
                
                let data = data.filter { $0.year == year && $0.date.month == month }
                
                //let cats = monthItems.compactMap { catModel.getCategory(by: $0.record.id) }

                let monthly = MonthlyData(
                    month: month,
                    monthName: monthName,
                    expenseAmount: totalExpense,
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
    
//    struct YearlyData: Identifiable {
//        var id: { return year }
//        var year: Int
//        var month: Int
//        var expenseAmount: Double
//        var categories: [CBCategory]
//    }
    
    struct YearlyData: Identifiable {
        var id: Int { return year }
        var year: Int
        var months: [MonthlyData]
    }
    
    struct MonthlyData: Identifiable {
        var id: Int { return month }
        var month: Int
        var monthName: String
        var expenseAmount: Double
        var data: [CategoryAnalyticData]
    }
    
    
    @ViewBuilder
    func yearlySections(for year: Int, with data: Array<CategoryAnalyticData>) -> some View {
        ForEach(yearlyData) { yearly in
            Section(String(yearly.year)) {
                ForEach(yearly.months) { monthly in
                    VStack {
                        HStack {
                            //let monthName = NavDestination.getMonthFromInt(monthly.month)?.displayName ?? "N/A"
                            
                            Text("\(monthly.monthName) \(String(year))")
                            //Text(String(year))
                            Spacer()
                            Text("\(monthly.expenseAmount.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                            //Text("\(items.reduce(0) { $0 + $1.expenses }, format: .number)")
                        }
                        
                        
                        ForEach(monthly.data) { data in
                            let cat = catModel.getCategory(by: data.record.id)
                            HStack {
                                StandardCategoryLabel(cat: cat, labelWidth: 30, showCheckmarkCondition: false)
                                //Text(data.record.title)
                                Text(data.expensesString)
                            }
                        }
                    }
                    
                }
            }
        }
    }
    
//    @ViewBuilder
//    func yearlySectionsOG(for year: Int, with data: Array<CategoryAnalyticData>) -> some View {
//        let groupedByYear = Dictionary(grouping: data, by: { $0.year })
//        let groupedByYearThenMonth =
//            groupedByYear.mapValues { items in
//                Dictionary(grouping: items, by: { $0.month })
//            }
//        
//        //let _ = print(groupedByYearThenMonth)
//        
//        ForEach(groupedByYearThenMonth.keys.sorted(by: >), id: \.self) { year in
//            Section(String(year)) {
//
//                let months = groupedByYearThenMonth[year]!
//                ForEach(months.keys.sorted(by: >), id: \.self) { month in
//                    
//                    let items = months[month]!
//                    HStack {
//                        let monthName = NavDestination.getMonthFromInt(month)?.displayName ?? "N/A"
//                        //let result = "\(monthName) \(String(year))"
//                        let amount = items.map {$0.expenses}.reduce(0.0, +)
//                        Text(monthName)
//                        //Text("\(String(monthName)) \(String(year))")
//                        Text(String(year))
//                        Spacer()
//                        Text("\(amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
//                        //Text("\(items.reduce(0) { $0 + $1.expenses }, format: .number)")
//                    }
//                }
//            }
//        }
//    }
    
    
    var fetchMoreButton: some View {
        Button("Fetch \(String(model.fetchYearStart - 10)) - \(String(model.fetchYearEnd - 10))", action: model.fetchMoreHistory)
            .tint(.gray)
    }
}


