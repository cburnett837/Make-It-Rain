//
//  CategoryAnalyticChartViewModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/10/25.
//


import SwiftUI
import Charts

@Observable
class CatChartViewModel {
    var fetchYearStart = AppState.shared.todayYear - 10
    var fetchYearEnd = AppState.shared.todayYear
    var isLoadingHistory = true
    var isLoadingMoreHistory = false
    var data: Array<CategoryAnalyticData> = []
    var chartScrolledToDate: Date = Date()
    var fetchHistoryTime = Date()
    var refreshTask: Task<Void, Never>?
    
    var isForGroup: Bool = false
    var category: CBCategory?
    var categoryGroup: CBCategoryGroup?
    
    var calModel: CalendarModel
    var catModel: CategoryModel
    
    init(
        isForGroup: Bool,
        category: CBCategory? = nil,
        categoryGroup: CBCategoryGroup? = nil,
        calModel: CalendarModel,
        catModel: CategoryModel
    ) {
        print("initing view model")
        self.isForGroup = isForGroup
        self.category = category
        self.categoryGroup = categoryGroup
        self.calModel = calModel
        self.catModel = catModel
    }
    
    public var chartVisibleYearCount: CategoryAnalyticChartRange {
        get { CategoryAnalyticChartRange.fromInt(appStorageGetter(\.chartVisibleYearCount.rawValue, key: "monthlyCategoryAnalyticChartVisibleYearCount", default: 1)) }
        set {
            withAnimation {
                appStorageSetter(\.chartVisibleYearCount.rawValue, key: "monthlyCategoryAnalyticChartVisibleYearCount", new: newValue.rawValue)
            }
        }
    }
    
    public var displayedMetric: CategoryAnalyticChartDisplayedMetric {
        get { CategoryAnalyticChartDisplayedMetric.fromString(appStorageGetter(\.displayedMetric.rawValue, key: LocalKeys.Charts.CategoryAnalytics.displayedMetric, default: CategoryAnalyticChartDisplayedMetric.expenses.rawValue)) }
        set {
            withAnimation {
                appStorageSetter(\.displayedMetric.rawValue, key: LocalKeys.Charts.CategoryAnalytics.displayedMetric, new: newValue.rawValue)
            }
            
        }
    }
        
    var displayData: Array<CategoryAnalyticData> {
        let currentYear = Calendar.current.component(.year, from: .now)
        let years = (0..<chartVisibleYearCount.rawValue).map { currentYear - $0 }
        return data
            .filter { years.contains($0.year) }
            .sorted(by: {
                switch LocalStorage.shared.categorySortMode {
                case .title:
                    return $0.category.title.lowercased() > $1.category.title.lowercased()
                case .listOrder:
                    return $0.category.listOrder ?? 0 > $1.category.listOrder ?? 0
                }
            })
    }
    
    var rawSelectedDate: Date?
    var selectedMonth: Array<CategoryAnalyticData>? {
        guard let rawSelectedDate else { return nil }
        return data.filter {
            Calendar.current.isDate(rawSelectedDate, equalTo: $0.date, toGranularity: .month)
        }
    }
    
    var visibleTotal: Double {
        /// Calculate the total of the data currently in the chart visible range.
        displayData
            .map {
                switch displayedMetric {
                case .income: $0.income
                case .expenses: $0.expenses
                case .budget: $0.budget
                case .expensesMinusIncome: $0.expensesMinusIncome
                }
            }
            .reduce(0, +)
    }
    
    
    var visibleYearCount: Int {
        chartVisibleYearCount.rawValue == 0 ? 1 : chartVisibleYearCount.rawValue
    }
    
    var minDate: Date {
        displayData.first?.date.startDateOfMonth ?? Date()
    }
    
    var maxDate: Date {
        displayData.last?.date.endDateOfMonth ?? Date()
    }
    
//    var daysBetweenMinAndMax: Int {
//        /// Check if the date range of the data is within the visibleChartAreaDomain. Crop accordingly.
//        //let minDate = displayData.first?.date.startDateOfMonth ?? Date()
//        //let maxDate = displayData.last?.date.endDateOfMonth ?? Date()
//        //print("The minDate is \(minDate) and the maxDate is \(maxDate)")
//        let between = Calendar.current.dateComponents([.day], from: minDate, to: maxDate).day ?? 0
//        print("The days between are \(between)")
//
//        return between
//    }
    
//    var monthsBetweenMinAndMax: Int {
//        /// Check if the date range of the data is within the visibleChartAreaDomain. Crop accordingly.
//        //let minDate = displayData.first?.date.startDateOfMonth ?? Date()
//        //let maxDate = displayData.last?.date.endDateOfMonth ?? Date()
//        //print("The minDate is \(minDate) and the maxDate is \(maxDate)")
//        let between = Calendar.current.dateComponents([.month], from: minDate, to: maxDate).month ?? 0
//        print("The months between are \(between)")
//
//        return between
//    }
        
//    var visibleChartAreaDomain: Int {
//        let availDays = numberOfDays(daysBetweenMinAndMax)
//        let idealDays = numberOfDays(365 * visibleYearCount)
//
//        if availDays == 0 {
//            return numberOfDays(30)
//        } else {
//            let isTooManyIdealDays = idealDays > availDays
//            return isTooManyIdealDays ? availDays : idealDays
//
//        }
//    }
    
//    var visibleDateRange: ClosedRange<Date> {
//        /// Check if the date range of the data is within the visibleRange. Crop accordingly.
//        let maxAvailEndDate = data.last?.date.endDateOfMonth ?? Date().endDateOfMonth
//        let idealEndDate: Date = Calendar.current.date(byAdding: .day, value: 365, to: chartScrolledToDate)!
//
//        let endRange: Date = idealEndDate > maxAvailEndDate ? maxAvailEndDate : idealEndDate
//
//        guard chartScrolledToDate < endRange else { return endRange...endRange }
//        return chartScrolledToDate...endRange
//    }
    
    var average: Double {
        displayData
            .map {
                switch displayedMetric {
                case .income: $0.income
                case .expenses: $0.expenses
                case .budget: $0.budget
                case .expensesMinusIncome: $0.expensesMinusIncome
                }
            }
            .average()
    }
    
    
    
    func setChartScrolledToDate(_ newValue: CategoryAnalyticChartRange) {
        /// Set the scrollPosition to which ever is smaller, the targetDate, or the minDate.
        let minDate = data.first?.date ?? Date()
        let maxDate = data.last?.date ?? Date()
        var targetDate: Date
        /// If 0, which means it's YTD, start with the maxDate and work backwards to January 1st.
        if newValue.rawValue == 0 {
            let components = Calendar.current.dateComponents([.year], from: .now)
            targetDate = Calendar.current.date(from: components)!
        } else {
            ///-365, -730, etc
            let value = -(365 * newValue.rawValue)
            /// start with the maxDate and work backwards using the value.
            targetDate = Calendar.current.date(byAdding: .day, value: value, to: maxDate)!
        }
        
        /// chartScrolledToDate is the beginning of the chart view.
        if targetDate < minDate && newValue.rawValue != 0 {
            chartScrolledToDate = minDate
        } else {
            chartScrolledToDate = targetDate
        }
    }
    
    
    func prepareView() async {
        /// iPhone: only fetch the new historical if it has been wiped out (by returning to the account list), or if a transaction has been updated since the history was fetched from the server.
        /// Due to the navigation stack, we can leave the chart open and go elsewhere in the app. Thus, no need to refresh the data unless a transaction changed in the meantime.
        /// Likewise, when returning to the account list, the viewmodel would be destroyed, and the history would need to be refetched.
        ///
        /// iPad: Always fetch the data since everything is inside a sheet, which must be closed before returning to the rest of the app. Thus the viewmodel would be destroyed, and the history would need to be refetched.
        let needsUpdates = await calModel.transactionsUpdatesExistAfter(fetchHistoryTime)
        if data.isEmpty || needsUpdates || AppState.shared.isIpad {
            fetchHistoryTime = Date()
            fetchHistory(setChartAsNew: true)
        }
    }
    
    
    var localData: Array<CategoryAnalyticData> = []
    
    
    func fetchHistory(setChartAsNew: Bool) {
        self.refreshTask = Task {
            if setChartAsNew {
                isLoadingHistory = true
            }
            
            let requestModel = AnalysisRequestModel(
                recordIDs: isForGroup ? [] : [category!.id],
                groupID: isForGroup ? categoryGroup!.id : nil,
                fetchYearStart: fetchYearStart,
                fetchYearEnd: fetchYearEnd,
                isUnifiedRequest: false
            )
            
            if let data = await catModel.fetchExpensesByCategory(requestModel) {
                //withAnimation {
                //var localData: Array<CategoryAnalyticData> = []
                for each in data {
                    //let category = each.category
                    //print("Processing category: \(category?.title ?? "Unknown") on \(each.date) - expenses \(each.expenses) - budget \(each.budget)")
                    //print(each.date)
                    if let index = self.localData.firstIndex(where: { $0.month == each.month && $0.year == each.year && $0.category.id == each.category?.id }) {
                        self.localData[index].budgetString = each.budgetString
                        self.localData[index].expensesString = each.expensesString
                        self.localData[index].incomeString = each.incomeString
                    } else {
                        if let cat = each.category {
                            let anal = CategoryAnalyticData(
                                category: cat,
                                type: "category",
                                month: each.month,
                                year: each.year,
                                budgetString: each.budgetString,
                                expensesString: each.expensesString,
                                incomeString: each.incomeString
                            )
                            self.localData.append(anal)
                        }
                        
                    }
                }
                
                self.localData.sort(by: { $0.date < $1.date })
                //}
                
                withAnimation {
                    self.data = localData
                }
                
                if setChartAsNew {
                    var visibleYearCount: Int {
                        self.chartVisibleYearCount.rawValue == 0 ? 1 : self.chartVisibleYearCount.rawValue
                    }
                    
                    /// Set the scrollPosition to which ever is smaller, the idealStartDate, or the maxAvailStartDate.
                    let minDate = data.first?.date ?? Date()
                    let maxDate = data.last?.date ?? Date()
                    let idealDate = Calendar.current.date(byAdding: .day, value: -(365 * visibleYearCount), to: maxDate)!
                    
                    //                if chartVisibleYearCount == .yearToDate {
                    //                    let components = Calendar.current.dateComponents([.year], from: .now)
                    //                    chartScrolledToDate = Calendar.current.date(from: components)!
                    //                } else {
                    self.chartScrolledToDate = minDate < idealDate ? idealDate : minDate
                    //                }
                    
                    print("Setting to false")
                    await MainActor.run {
                        self.isLoadingHistory = false
                    }
                    
                }
            }
            
            self.isLoadingMoreHistory = false
        }
    }
    
    
//    func fetchHistoryNew(setChartAsNew: Bool) async {
//        if setChartAsNew { isLoadingHistory = true }
//
//        let requestModel = AnalysisRequestModel(
//            recordIDs: isForGroup ? [] : [category!.id],
//            groupID: isForGroup ? categoryGroup!.id : nil,
//            fetchYearStart: fetchYearStart,
//            fetchYearEnd: fetchYearEnd,
//            isUnifiedRequest: false
//        )
//        
//        // 1. Fetch + compute off-main
//        let newData: [CategoryAnalyticData] = await withTaskGroup(of: CategoryAnalyticData?.self) { group in
//            var results: [CategoryAnalyticData] = []
//            
//            if let response = await catModel.fetchExpensesByCategory(requestModel) {
//                for each in response {
//                    group.addTask {
//                        if let cat = each.category {
//                            let anal = CategoryAnalyticData(
//                                category: cat,
//                                type: "category",
//                                month: each.month,
//                                year: each.year,
//                                budgetString: each.budgetString,
//                                expensesString: each.expensesString,
//                                incomeString: each.incomeString
//                            )
//                            return anal
//                        }
//                        
//                    }
//                }
//                
//                for await item in group {
//                    if let item { results.append(item) }
//                }
//            }
//            
//            return results.sorted { $0.date < $1.date }
//        }
//
//        // 2. Update UI state ONCE on main actor
//        await MainActor.run {
//            withAnimation(.easeOut(duration: 0.25)) {
//                self.data = newData
//            }
//            if setChartAsNew {
//                //self.chartScrolledToDate = minDate < idealDate ? idealDate : minDate
//                isLoadingHistory = false
//            }
//        }
//    }
    
    
    func fetchMoreHistory() {
        self.isLoadingMoreHistory = true
        self.fetchYearStart -= 10
        self.fetchYearEnd -= 10
        print("fetching more history... \(self.fetchYearStart) - \(self.fetchYearEnd)")
        fetchHistory(setChartAsNew: false)
    }
}



extension CatChartViewModel {
    private func appStorageGetter<T: Decodable>(_ keyPath: KeyPath<CatChartViewModel, T>, key: String, default defaultValue: T) -> T {
        access(keyPath: keyPath)
        if let data = UserDefaults.standard.data(forKey: key) {
            return try! JSONDecoder().decode(T.self, from: data)
        } else {
            return defaultValue
        }
    }
    
    private func appStorageSetter<T: Encodable>(_ keyPath: KeyPath<CatChartViewModel, T>, key: String, new: T) {
        withMutation(keyPath: keyPath) {
            let data = try? JSONEncoder().encode(new)
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
