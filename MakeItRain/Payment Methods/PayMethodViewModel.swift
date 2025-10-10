//
//  PayMethodViewModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/14/25.
//

import Foundation
import SwiftUI
import Charts


extension PayMethodViewModel {
    private func appStorageGetter<T: Decodable>(_ keyPath: KeyPath<PayMethodViewModel, T>, key: String, default defaultValue: T) -> T {
        access(keyPath: keyPath)
        if let data = UserDefaults.standard.data(forKey: key) {
            return try! JSONDecoder().decode(T.self, from: data)
        } else {
            return defaultValue
        }
    }
    
    private func appStorageSetter<T: Encodable>(_ keyPath: KeyPath<PayMethodViewModel, T>, key: String, new: T) {
        withMutation(keyPath: keyPath) {
            let data = try? JSONEncoder().encode(new)
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}


@Observable
class PayMethodViewModel {
    var mainPayMethod: CBPaymentMethod = CBPaymentMethod()
    var payMethods: Array<CBPaymentMethod> = []
    var chartLeadingDate: Date = Date()
    var fetchYearStart = AppState.shared.todayYear - 10
    var fetchYearEnd = AppState.shared.todayYear
    var isLoadingHistory = true
    var isLoadingMoreHistory = false
    
    //    var rawData: [PayMethodMonthlyBreakdown] { data.flatMap { $0.data } }
    //    var dates: [Date] { Array(Set(rawData.map { $0.date })) }
    //    var minDate: Date { dates.min() ?? Date() }
    //    var maxDate: Date { dates.max() ?? Date() }
    //    var incomes: [Double] { rawData.map { $0.income } }
    //    var minIncome: Double { incomes.min() ?? 0 }
    //    var maxIncome: Double { incomes.max() ?? 0 }
    
    var rawData: [PayMethodMonthlyBreakdown] = []
    var dates: [Date] = []
    var minDate: Date = Date()
    var maxDate: Date = Date()
    var incomes: [Double] = []
    var minIncome: Double = 0
    var maxIncome: Double = 0
    
    //var chartVisibleYearCount: PayMethodChartRange
//    var incomeType: IncomeType = .income
//    
//    
//    init() {
//        //self.chartVisibleYearCount = PayMethodChartRange.fromInt(UserDefaults.standard.integer(forKey: "monthlyAnalyticChartVisibleYearCount"))
//        self.incomeType = IncomeType.fromString(UserDefaults.standard.string(forKey: "monthlyAnalyticChartVisibleYearCount") ?? "income")
//    }
    
    public var visibleYearCount: PayMethodChartRange {
        get { PayMethodChartRange.fromInt(appStorageGetter(\.visibleYearCount.rawValue, key: "monthlyAnalyticChartVisibleYearCount", default: 1)) }
        set { appStorageSetter(\.visibleYearCount.rawValue, key: "monthlyAnalyticChartVisibleYearCount", new: newValue.rawValue) }
    }
    
    public var chartCropingStyle: ChartCropingStyle {
        get { ChartCropingStyle.fromString(appStorageGetter(\.chartCropingStyle.rawValue, key: "chartCropingStyle", default: ChartCropingStyle.showFullCurrentYear.rawValue)) }
        set { appStorageSetter(\.chartCropingStyle.rawValue, key: "chartCropingStyle", new: newValue.rawValue) }
    }
        
    public var incomeType: IncomeType {
        get { IncomeType.fromString(appStorageGetter(\.incomeType.rawValue, key: "incomeType", default: IncomeType.incomeAndPositiveAmounts.rawValue)) }
        set { appStorageSetter(\.incomeType.rawValue, key: "incomeType", new: newValue.rawValue) }
    }
    
    
    
    var chartXScale: ClosedRange<Date> {
        let data = relevantBreakdowns()
        guard let first = data.first?.date.startDateOfMonth, let last = data.last?.date.endDateOfMonth else { return Date()...Date() }
        return first...last
    }
    
    
    var viewByQuarter: Bool {
        visibleYearCount.rawValue >= 4
    }
        
//    var relevantBreakdowns: [PayMethodMonthlyBreakdown] {
//        viewByQuarter ? quarterlyBreakdowns : monthlyBreakdowns
//    }
//    
//    var monthlyBreakdowns: [PayMethodMonthlyBreakdown] {
//        mainPayMethod.breakdowns.filter { yearIsRelevant(for: $0.date) }
//    }
//    
//    var quarterlyBreakdowns: [PayMethodMonthlyBreakdown] {
//        /// Group by year and quarter.
//        let grouped = Dictionary(grouping: monthlyBreakdowns) {
//            YearQuarter(year: $0.date.year, quarter: $0.date.startOfQuarter.month)
//        }
//
//        /// Summarize each group into one quarterly breakdown.
//        let summaries = grouped.compactMap { summarizeQuarterlyBreakdown(from: $1) }
//
//        /// Sort by year and quarter.
//        return summaries.sorted { $0.date < $1.date }
//    }
    
    func relevantBreakdowns() -> [PayMethodMonthlyBreakdown] {
        viewByQuarter ? quarterlyBreakdowns(for: mainPayMethod) : monthlyBreakdowns(for: mainPayMethod)
    }
    
    func relevantBreakdowns(for payMethod: CBPaymentMethod) -> [PayMethodMonthlyBreakdown] {
        viewByQuarter ? quarterlyBreakdowns(for: payMethod) : monthlyBreakdowns(for: payMethod)
    }
    
    func monthlyBreakdowns(for payMethod: CBPaymentMethod) -> [PayMethodMonthlyBreakdown] {
        payMethod.breakdowns.filter { yearIsRelevant(for: $0.date) }
    }
    
    func quarterlyBreakdowns(for payMethod: CBPaymentMethod) -> [PayMethodMonthlyBreakdown] {
        /// Group by year and quarter.
        let grouped = Dictionary(grouping: monthlyBreakdowns(for: payMethod)) {
            YearQuarter(year: $0.date.year, quarter: $0.date.startOfQuarter.month)
        }

        /// Summarize each group into one quarterly breakdown.
        let summaries = grouped.compactMap { summarizeQuarterlyBreakdown(from: $1, for: payMethod) }

        /// Sort by year and quarter.
        return summaries.sorted { $0.date < $1.date }
    }
    
    
    
    struct YearQuarter: Hashable, Comparable {
        let year: Int
        let quarter: Int
        
        static func < (lhs: YearQuarter, rhs: YearQuarter) -> Bool {
            if lhs.year == rhs.year {
                return lhs.quarter < rhs.quarter
            } else {
                return lhs.year < rhs.year
            }
        }
    }
    
    var visibleDateRangeForHeader: ClosedRange<Date> {
        /// Check if the date range of the data is within the visibleRange. Crop accordingly.
//        var idealEndDate: Date
//        
//        if let firstOfNextYear = Calendar.current.date(from: DateComponents(year: chartLeadingDate.year + visibleYearCount.rawValue, month: 1, day: 1)) {
//            // Get the last day of the current year
//            idealEndDate = Calendar.current.date(byAdding: .day, value: -1, to: firstOfNextYear)!
//        } else {
//            idealEndDate = Calendar.current.date(byAdding: .day, value: (365 * (visibleYearCount.rawValue)), to: chartLeadingDate)!
//        }
        
        let firstOfNextYear = Calendar.current.date(from: DateComponents(year: chartLeadingDate.year + visibleYearCount.rawValue, month: 1, day: 1))!
        let idealEndDate = Calendar.current.date(byAdding: .day, value: -1, to: firstOfNextYear)!
        
        
        guard chartLeadingDate < idealEndDate else {
            //print("returning1 \(idealEndDate)...\(idealEndDate)")
            return idealEndDate...idealEndDate
        }
        //print("returning2 \(chartLeadingDate)...\(idealEndDate)")
        return chartLeadingDate...idealEndDate
    }
    
    
//    var visibleChartAreaDomain: Int {
//        
//        let firstDayOfTheYear = Calendar.current.date(from: DateComponents(year: chartLeadingDate.year, month: 1, day: 1))!
//        let idealEndDate = Calendar.current.date(byAdding: .day, value: -1, to: firstDayOfTheYear)!
//        
//        
//        
//        let calendar = Calendar.current
//        let now = Date()
//
//        // Get the first day of next month
//        var components = Calendar.current.dateComponents([.year, .month], from: now)
//        components.month! += 1
//
//        // Handle year rollover (e.g., December -> January of next year)
//        if components.month! > 12 {
//            components.month = 1
//            components.year! += 1
//        }
//
//        components.day = 1
//
//        guard let startDate = Calendar.current.date(from: components),
//              let endOfYear = Calendar.current.date(from: DateComponents(year: components.year, month: 12, day: 31)) else {
//            fatalError("Failed to create dates")
//        }
//
//        // Calculate number of days between start of next month and end of year
//        let daysLeftThisYear = calendar.dateComponents([.day], from: startDate, to: endOfYear).day! + 1
//        
//        
//        
//        
//        
//        
//       // print(daysLeftThisYear)
//        if chartCropingStyle == .showFullCurrentYear {
//            //print("visibleChartAreaDomain - showFullCurrentYear - \(numberOfDays(365 * visibleYearCount.rawValue))")
//            return numberOfDays(365 * visibleYearCount.rawValue)
//        } else {
//            //print("visibleChartAreaDomain - cropCyurrentYear - \(numberOfDays((365 * visibleYearCount.rawValue) - cut))")
//            return numberOfDays(365 * visibleYearCount.rawValue) - numberOfDays(daysLeftThisYear)
//        }
//        
////        /// Check if the date range of the data is within the visibleChartAreaDomain. Crop accordingly.
////        let daysBetweenMinAndMax = Calendar.current.dateComponents([.day], from: minDate, to: maxDate).day ?? 0
////        let availDays = numberOfDays(daysBetweenMinAndMax)
////        var idealDays: Int
////        
////        idealDays = numberOfDays(365 * visibleYearCount.rawValue)
////        
////        
////        
////        if availDays == 0 {
////            return numberOfDays(30)
////        } else {
////            let isTooManyIdealDays = idealDays > availDays
////            return isTooManyIdealDays ? availDays : idealDays
////        }
//    }
    
    
    var visibleIncome: Double {
        /// Calculate the total of the data currently in the chart visible range.
        mainPayMethod.breakdowns
            .filter { visibleDateRangeForHeader.contains($0.date) }
            .map {
                switch incomeType {
                case .income:
                    $0.income
                case .incomeAndPositiveAmounts:
                    $0.incomeAndPositiveAmounts
                case .positiveAmounts:
                    $0.positiveAmounts
                case .startingAmountsAndPositiveAmounts:
                    $0.startingAmountsAndPositiveAmounts
                }
            }
            .reduce(0, +)
    }
    
    
    var visibleExpenses: Double {
        mainPayMethod.breakdowns
            .filter { visibleDateRangeForHeader.contains($0.date) }
            .map { $0.expenses }
            .reduce(0, +)
    }
    
    
    var visiblePayments: Double {
        /// Calculate the total of the data currently in the chart visible range.
        mainPayMethod.breakdowns
            .filter { visibleDateRangeForHeader.contains($0.date) }
            .map { $0.payments }
            .reduce(0, +)
    }
    
    
    // MARK: - Functions
    
    /// `@MainActor`  is required to fix the data race that occurs when `for breakdown in summarizedBreakdowns {}` is still updating `CBPaymentMethod.breakdowns`.
    /// In the chart, the raw data list will try and read `CBPaymentMethod.breakdowns` before `for breakdown in summarizedBreakdowns {}` is finished.
    @MainActor
    func fetchHistory(for payMethod: CBPaymentMethod, payModel: PayMethodModel, setChartAsNew: Bool) async {
        if setChartAsNew {
            payMethod.breakdowns.removeAll()
            payMethod.breakdownsRegardlessOfPaymentMethod.removeAll()
            isLoadingHistory = true
        }
        
        /// Accumulate the various payment method ID associated with the unified payment method.
        var ids: [String] = []
        if payMethod.isUnified {
            let accountType = payMethod.accountType
            if accountType == .unifiedCredit {
                for each in payModel.paymentMethods.filter({ $0.accountType == .credit || $0.accountType == .loan }) {
                    ids.append(each.id)
                }
            } else {
                for each in payModel.paymentMethods.filter({ $0.accountType == .checking || $0.accountType == .cash }) {
                    ids.append(each.id)
                }
            }
        } else {
            ids.append(payMethod.id)
        }
        
        
        let model = AnalysisRequestModel(recordIDs: ids, fetchYearStart: fetchYearStart, fetchYearEnd: fetchYearEnd)
        
        if let payMethods = await payModel.fetchAnalytics(model) {
            
            var thePayMethods: [CBPaymentMethod] = []
            /// If a unified view, summarize all the data.
            if payMethod.isUnified {
                let rawData: [PayMethodMonthlyBreakdown] = payMethods.flatMap { $0.breakdowns }
                var summarizedBreakdowns: [PayMethodMonthlyBreakdown] = []
                let dates: [Date] = rawData.map({ $0.date }).uniqued { $0 }
                
                for each in dates {
                    //print(each)
                    let breakdowns = rawData.filter({ Calendar.current.isDate($0.date, inSameDayAs: each) })
                    let incomes = breakdowns.map { $0.income }.reduce(0, +)
                    let incomesAndPositiveAmounts = breakdowns.map { $0.incomeAndPositiveAmounts }.reduce(0, +)
                    let positiveAmounts = breakdowns.map { $0.positiveAmounts }.reduce(0, +)
                    let startingAmountsAndPositiveAmounts = breakdowns.map { $0.startingAmountsAndPositiveAmounts }.reduce(0, +)
                    let expenses = breakdowns.map { $0.expenses }.reduce(0, +)
                    let payments = breakdowns.map { $0.payments }.reduce(0, +)
                    let startingAmounts = breakdowns.map { $0.startingAmounts }.reduce(0, +)
                    let profitLoss = breakdowns.map { $0.profitLoss }.reduce(0, +)
                    
                    breakdowns.forEach { $0.profitLossPercentage = Helpers.netWorthPercentageChange(start: $0.startingAmounts, end: $0.monthEnd) }

                    
//                    breakdowns.profitLossPercentage = Helpers.netWorthPercentageChange(
//                        start: startingAmounts,
//                        end: breakdowns.map { $0.monthEnd }.reduce(0, +)
//                    )
                    
                    
                    
                    //let profitLossPercentage = breakdowns.map { $0.profitLossPercentage }.reduce(0, +)
                    
//                    if each.month == 6 && each.year == 2025 {
//                        print("HEREEEEEEE")
//                        
//                        
//                        print(profitLoss)
//                        
//                        print(breakdowns.map { $0.profitLoss })
//                        
//                        print(breakdowns.map { $0.profitLossPercentage })
//                        // [-62.64794935315167, 0.0, 240.0]
//                        
//                        breakdowns.forEach { print($0.payMethodID, $0.startingAmounts, $0.monthEnd) }
//                        //5 3633.0 1357.0
//                        //49 0.0 0.0
//                        //7 500.0 1700.0
//                        print(profitLossPercentage)
//                        //177.35205064684834
//
//                        //(3633 + 500) (1357 + 1700)
//                        //4133 + 3057
//                        print(breakdowns.map { $0.startingAmounts })
//                        print(breakdowns.map { $0.monthEnd })
//                        print(Helpers.netWorthPercentageChange(start: startingAmounts, end: breakdowns.map { $0.monthEnd }.reduce(0, +)))
//                        
//
//                    }
                    
                    
                    let monthEnd = breakdowns.map { $0.monthEnd }.reduce(0, +)
                    let minEod = breakdowns.map { $0.minEod }.reduce(0, +)
                    let maxEod = breakdowns.map { $0.maxEod }.reduce(0, +)
                    
                    //print(breakdowns.map { $0.maxEod })
                    
                    let summarizedBreakdown = PayMethodMonthlyBreakdown(
                        title: payMethod.title,
                        color: payMethod.color,
                        payMethodID: payMethod.id,
                        month: each.month,
                        year: each.year,
                        incomeString: String(incomes),
                        incomeAndPositiveAmountsString: String(incomesAndPositiveAmounts),
                        positiveAmountsString: String(positiveAmounts),
                        startingAmountsAndPositiveAmountsString: String(startingAmountsAndPositiveAmounts),
                        expensesString: String(expenses),
                        paymentsString: String(payments),
                        startingAmountsString: String(startingAmounts),
                        profitLossString: String(profitLoss),
                        profitLossPercentage: Helpers.netWorthPercentageChange(start: startingAmounts, end: breakdowns.map { $0.monthEnd }.reduce(0, +)),
                        //profitLossMinPercentageString: String(profitLossMinPercentage),
                        //profitLossMaxPercentageString: String(profitLossMaxPercentage),
                        //profitLossMinAmountString: String(profitLossMinAmount),
                        //profitLossMaxAmountString: String(profitLossMaxAmount),
                        monthEndString: String(monthEnd),
                        minEodString: String(minEod),
                        maxEodString: String(maxEod)
                    )
                    
                    summarizedBreakdowns.append(summarizedBreakdown)
                }
                
                //let profitLossMinPercentage = percentages.min() ?? 0
                //let profitLossMaxPercentage = percentages.max() ?? 0
                //let profitLossMinAmount = breakdowns.map { $0.profitLoss }.min() ?? 0
                //let profitLossMaxAmount = breakdowns.map { $0.profitLoss }.max() ?? 0
                
                
                
                
                
                let percentages = summarizedBreakdowns.map {$0.profitLossPercentage}
                let profitLossMinPercentage = percentages.min() ?? 0
                let profitLossMaxPercentage = percentages.max() ?? 0
                payMethod.profitLossMinPercentage = profitLossMinPercentage
                payMethod.profitLossMaxPercentage = profitLossMaxPercentage
                
                let profitLosses = summarizedBreakdowns.map {$0.profitLoss}
                let profitLossMinAmount = profitLosses.min() ?? 0
                let profitLossMaxAmount = profitLosses.max() ?? 0
                payMethod.profitLossMinAmountString = String(profitLossMinAmount)
                payMethod.profitLossMaxAmountString = String(profitLossMaxAmount)
                
                let minEod = summarizedBreakdowns.map {$0.minEod}.min() ?? 0
                let maxEod = summarizedBreakdowns.map {$0.maxEod}.min() ?? 0
                payMethod.minEodString = String(minEod)
                payMethod.maxEodString = String(maxEod)
                
                
                
                for breakdown in summarizedBreakdowns {
                    if setChartAsNew {
                        payMethod.breakdowns.append(breakdown)
                    } else {
                        if let index = payMethod.breakdowns.firstIndex(where: { $0.month == breakdown.month && $0.year == breakdown.year && $0.payMethodID == breakdown.payMethodID }) {
                            payMethod.breakdowns[index].setFromAnotherInstance(breakdown)
                        } else {
                            payMethod.breakdowns.append(breakdown)
                        }
                    }
                }
                
                self.mainPayMethod = payMethod
                thePayMethods = payMethods
            } else {
                if let meth = payMethods.first {
                    
                    //let profitLossPercentage = breakdowns.map { Helpers.netWorthPercentageChange(start: $0.startingAmounts, end: $0.monthEnd) }.reduce(0, +)
                    meth.breakdowns.forEach { $0.profitLossPercentage = Helpers.netWorthPercentageChange(start: $0.startingAmounts, end: $0.monthEnd) }
                                                        
                    let percentages = meth.breakdowns.map { $0.profitLossPercentage }
                    let profitLossMinPercentage = percentages.min() ?? 0
                    let profitLossMaxPercentage = percentages.max() ?? 0
                    payMethod.profitLossMinPercentage = profitLossMinPercentage
                    payMethod.profitLossMaxPercentage = profitLossMaxPercentage
                    
                    let profitLosses = payMethods.flatMap { $0.breakdowns.map { $0.profitLoss } }
                    let profitLossMinAmount = profitLosses.min() ?? 0
                    let profitLossMaxAmount = profitLosses.max() ?? 0
                    payMethod.profitLossMinAmountString = String(profitLossMinAmount)
                    payMethod.profitLossMaxAmountString = String(profitLossMaxAmount)
                                        
                    let minEod = payMethods.flatMap { $0.breakdowns.map { $0.minEod } }.min() ?? 0
                    let maxEod = payMethods.flatMap { $0.breakdowns.map { $0.maxEod } }.max() ?? 0
                    payMethod.minEodString = String(minEod)
                    payMethod.maxEodString = String(maxEod)
                    
                    
                    
                    //let rawData: [PayMethodMonthlyBreakdown] = payMethods.flatMap { $0.breakdowns }
                    //let dates: [Date] = rawData.map({ $0.date }).uniqued { $0 }
                    
//                    for each in dates {
//                        let breakdowns = rawData.filter({ Calendar.current.isDate($0.date, inSameDayAs: each) })
//                        
//                        //let profitLoss = breakdowns.map { $0.profitLoss }.reduce(0, +)
//                        
//                        //let percentages = breakdowns.map { Helpers.netWorthPercentageChange(start: $0.startingAmounts, end: $0.monthEnd) }
//                        //let profitLossMinPercentage = percentages.min() ?? 0
//                        //let profitLossMaxPercentage = percentages.max() ?? 0
//                        //let profitLossMinAmount = breakdowns.map { $0.profitLoss }.min() ?? 0
//                        //let profitLossMaxAmount = breakdowns.map { $0.profitLoss }.max() ?? 0
//                        
//                    }
                    
                    
                    
                    self.mainPayMethod = meth
                }
                
                thePayMethods = payMethods
            }
            
            
            
            /// For each payment method that came from the server.
            for meth in payMethods {
                for breakdown in meth.breakdowns {
                    if setChartAsNew {
                        if payMethod.breakdownsRegardlessOfPaymentMethod.firstIndex(where: { $0.month == breakdown.month && $0.year == breakdown.year && $0.payMethodID == breakdown.payMethodID }) == nil {
                            payMethod.breakdownsRegardlessOfPaymentMethod.append(breakdown)
                        }
                    } else {
                        if let index = payMethod.breakdownsRegardlessOfPaymentMethod.firstIndex(where: { $0.month == breakdown.month && $0.year == breakdown.year && $0.payMethodID == breakdown.payMethodID }) {
                            payMethod.breakdownsRegardlessOfPaymentMethod[index].setFromAnotherInstance(breakdown)
                        } else {
                            payMethod.breakdownsRegardlessOfPaymentMethod.append(breakdown)
                        }
                    }
                    
                    
                }
            }
            
            
            if setChartAsNew {
                
                
                
                
                self.payMethods = thePayMethods
                
                /// Sort the data so it plays nice with the chart.
                for each in self.payMethods {
                    each.breakdowns.sort(by: { $0.date < $1.date })
                }
                
                /// Set the scrollPosition to which ever is smaller, the idealStartDate, or the maxAvailStartDate.
                //let rawData: [PayMethodMonthlyBreakdown] = self.payMethods.flatMap { $0.breakdowns }
                //let dates: [Date] = rawData.map({ $0.date }).uniqued { $0 }
                //let minDate = dates.min() ?? Date()
                //let maxDate = dates.max() ?? Date()
                
                //self.minDate = minDate
                //self.maxDate = maxDate
                
                //let maxDate = data.last?.date ?? Date()
                //let idealDate = Calendar.current.date(byAdding: .day, value: -(365 * (visibleYearCount.rawValue)), to: maxDate)!
                
//                if visibleYearCount == .year1 {
//                    let components = Calendar.current.dateComponents([.year], from: .now)
//                    chartLeadingDate = Calendar.current.date(from: components)!
//                } else {
//                    chartLeadingDate = minDate < idealDate ? idealDate : minDate
//                }
                
                //chartLeadingDate = minDate < idealDate ? idealDate : minDate
                prepareData()
                setChartScrolledToDate(visibleYearCount)
                
                isLoadingHistory = false
                
            } else {
                /// When fetching more data (like at the end of the list), if the data does not already exist, append it.
                for meth in thePayMethods {
                    if let index = self.payMethods.firstIndex(where: { $0.id == meth.id }) {
                        let obj = self.payMethods[index]
                        for breakdown in meth.breakdowns {
                            if let index = obj.breakdowns.firstIndex(where: { $0.month == breakdown.month && $0.year == breakdown.year && $0.payMethodID == breakdown.payMethodID }) {
                                obj.breakdowns[index].setFromAnotherInstance(breakdown)
                            } else {
                                obj.breakdowns.append(breakdown)
                            }
                        }
                    }
                }
                
                /// Sort the data so it plays nice with the chart.
                for each in self.payMethods {
                    each.breakdowns.sort(by: { $0.date < $1.date })
                }
            }
        }
        
        
        //        for each in self.payMethods {
        //            for each in each.data {
        //                print("\(each.month) - \(each.year)")
        //            }
        //        }
        
        //prepareData()
        isLoadingMoreHistory = false
    }
    
    
    func fetchMoreHistory(for payMethod: CBPaymentMethod, payModel: PayMethodModel) {
        Task {
            isLoadingMoreHistory = true
            fetchYearStart -= 10
            fetchYearEnd -= 10
            print("fetching more history... \(fetchYearStart) - \(fetchYearEnd)")
            await fetchHistory(for: payMethod, payModel: payModel, setChartAsNew: false)
        }
    }
    
    
    func numberOfDays(_ num: Int) -> Int { (3600 * 24) * num }
    
        
    func setChartScrolledToDate(_ newValue: PayMethodChartRange) {
        let year = Calendar.current.date(byAdding: .year, value: -(newValue.rawValue) + 1, to: maxDate)!
        let components = Calendar.current.dateComponents([.year], from: year)
        let targetDate = Calendar.current.date(from: components)!
        
        /// chartLeadingDate is the beginning of the chart view.
        if targetDate < minDate {
            chartLeadingDate = minDate
        } else {
            chartLeadingDate = targetDate
        }
    }
    
    
    func prepareData() {
        print("-- \(#function)")
        
        //        for each in self.payMethods {
        //            for each in each.breakdowns {
        //                print("\(each.month) - \(each.year)")
        //            }
        //        }
        
        self.rawData = payMethods.flatMap { $0.breakdowns }
        self.dates = rawData.map { $0.date }
        self.minDate = dates.min() ?? Date()
        self.maxDate = dates.max() ?? Date()
        self.incomes = rawData.map { $0.income }
        self.minIncome = incomes.min() ?? 0
        self.maxIncome = incomes.max() ?? 0
    }
    
    
    func breakdownPerMethod(on selectedDate: Date) -> [PayMethodMonthlyBreakdown] {
        var returnMe: [PayMethodMonthlyBreakdown] = []
        for pay in payMethods {
            for each in pay.breakdowns {
                if Calendar.current.isDate(each.date, equalTo: selectedDate, toGranularity: .month) {
                    
                    let thing = breakdownForMethod(method: pay, on: selectedDate)
                    
//                    let thing = PayMethodChartSelectedDateDetails(
//                        title: pay.title,
//                        color: pay.color,
//                        income: each.income,
//                        incomeAndPositiveAmounts: each.incomeAndPositiveAmounts,
//                        positiveAmounts: each.positiveAmounts,
//                        startingAmountsAndPositiveAmounts: each.startingAmountsAndPositiveAmounts,
//                        expenses: each.expenses,
//                        payments: each.payments,
//                        startingAmounts: each.startingAmounts,
//                        profitLoss: each.profitLoss,
//                        profitLossPercentage: each.profitLossPercentage,
//                        //profitLossMinPercentage: each.profitLossMinPercentage,
//                        //profitLossMaxPercentage: each.profitLossMaxPercentage,
//                        //profitLossMinAmount: each.profitLossMinAmount,
//                        //profitLossMaxAmount: each.profitLossMaxAmount,
//                        monthEnd: each.monthEnd,
//                        minEod: each.minEod,
//                        maxEod: each.maxEod
//                    )
                    
                    returnMe.append(thing)
                }
            }
        }
        
        return returnMe
    }
    
    
    func breakdownForMethod(method: CBPaymentMethod, on selectedDate: Date) -> PayMethodMonthlyBreakdown {
        var result: [PayMethodMonthlyBreakdown]
        var startingAmounts: String
        if viewByQuarter {
            result = method.breakdowns.filter { $0.date.year == selectedDate.year && $0.date.startOfQuarter.month == selectedDate.month }
            
            startingAmounts = method.isCredit ? String(avg(\.startingAmounts)) : String(sum(\.startingAmounts))
            
        } else {
            result = method.breakdowns.filter({ Calendar.current.isDate($0.date, equalTo: selectedDate, toGranularity: .month) })
            
            startingAmounts = String(sum(\.startingAmounts))
            
        }
                        
        return PayMethodMonthlyBreakdown(
            title: method.title,
            color:  method.color,
            payMethodID: method.id,
            month: selectedDate.month,
            year: selectedDate.year,
            incomeString: String(sum(\.income)),
            incomeAndPositiveAmountsString: String(sum(\.incomeAndPositiveAmounts)),
            positiveAmountsString: String(sum(\.positiveAmounts)),
            startingAmountsAndPositiveAmountsString: String(sum(\.startingAmountsAndPositiveAmounts)),
            expensesString: String(sum(\.expenses)),
            paymentsString: String(sum(\.payments)),
            startingAmountsString: startingAmounts,
            profitLossString: String(sum(\.profitLoss)),
            profitLossPercentage: sum(\.profitLossPercentage),
            //profitLossMinPercentageString: String,
            //profitLossMaxPercentageString: String,
            //profitLossMinAmountString: String,
            //profitLossMaxAmountString: String,
            monthEndString: String(sum(\.monthEnd)),
            minEodString: String(sum(\.minEod)),
            maxEodString: String(sum(\.maxEod))
            
        )
        
        func sum(_ keyPath: KeyPath<PayMethodMonthlyBreakdown, Double>) -> Double {
            result.reduce(0) { $0 + $1[keyPath: keyPath] }
        }
        
        func avg(_ keyPath: KeyPath<PayMethodMonthlyBreakdown, Double>) -> Double {
            result.map { $0[keyPath: keyPath] }.average()
        }
        
    }
    
    
                
    func moveYears(forward: Bool) {
        if forward {
            let new = Calendar.current.date(byAdding: .year, value: 1, to: chartLeadingDate)!
            print(new)
            guard new.year <= ((maxDate.year - visibleYearCount.rawValue) + 1) else { return }
            chartLeadingDate = new
        } else {
            let new = Calendar.current.date(byAdding: .year, value: -1, to: chartLeadingDate)!
            print(new)
            guard new.year >= fetchYearStart else { return }
            chartLeadingDate = new
        }
    }
    
    
    var moveYearGesture: some Gesture {
        DragGesture(minimumDistance: 50, coordinateSpace: .global).onEnded {
            if $0.translation.width < -50 {
                self.moveYears(forward: true)
            } else if $0.translation.width > 50 {
                self.moveYears(forward: false)
            }
        }
    }
            
    
    func yearIsRelevant(for date: Date) -> Bool {
        //print("-- \(#function) -- \(date.month) -- \(date.year)")
        let isRelevant = date.year >= chartLeadingDate.year && date.year < chartLeadingDate.year + visibleYearCount.rawValue
                
        switch chartCropingStyle {
        case .showFullCurrentYear:
            return isRelevant
            
        case .endAtCurrentMonth:
            if isRelevant {
                return date.year == AppState.shared.todayYear ? Array(1...AppState.shared.todayMonth).contains(date.month) : true
            }
            return false
        }
    }
    
    
    
    func summarizeQuarterlyBreakdown(from monthlyData: [PayMethodMonthlyBreakdown], for payMethod: CBPaymentMethod) -> PayMethodMonthlyBreakdown? {
        guard let first = monthlyData.first else { return nil }

        guard Set(monthlyData.map { $0.payMethodID }).count == 1 else {
            print("Mismatched payMethodIDs — cannot summarize.")
            return nil
        }

        func sum(_ keyPath: KeyPath<PayMethodMonthlyBreakdown, Double>) -> Double {
            monthlyData.reduce(0) { $0 + $1[keyPath: keyPath] }
        }
        
        func avg(_ keyPath: KeyPath<PayMethodMonthlyBreakdown, Double>) -> Double {
            monthlyData.map { $0[keyPath: keyPath] }.average()
        }

        func minValue(_ keyPath: KeyPath<PayMethodMonthlyBreakdown, Double>) -> Double {
            monthlyData.map { $0[keyPath: keyPath] }.min() ?? 0
        }

        func maxValue(_ keyPath: KeyPath<PayMethodMonthlyBreakdown, Double>) -> Double {
            monthlyData.map { $0[keyPath: keyPath] }.max() ?? 0
        }
        
        
        let startingAmounts: String = payMethod.isCredit ? String(avg(\.startingAmounts)) : String(sum(\.startingAmounts))

        let summary = PayMethodMonthlyBreakdown(
            title: first.title,
            color: first.color,
            payMethodID: first.payMethodID,
            month: first.month,
            year: first.year,
            incomeString: String(sum(\.income)),
            incomeAndPositiveAmountsString: String(sum(\.incomeAndPositiveAmounts)),
            positiveAmountsString: String(sum(\.positiveAmounts)),
            startingAmountsAndPositiveAmountsString: String(sum(\.startingAmountsAndPositiveAmounts)),
            expensesString: String(sum(\.expenses)),
            paymentsString: String(sum(\.payments)),
            startingAmountsString: startingAmounts,
            profitLossString: String(sum(\.profitLoss)),
            profitLossPercentage: sum(\.profitLossPercentage) / Double(monthlyData.count),
            monthEndString: String(sum(\.monthEnd)),
            minEodString: String(minValue(\.minEod)),
            maxEodString: String(maxValue(\.maxEod))
        )

        return summary
    }
    
    
    func getIncomeText(for breakdown: PayMethodMonthlyBreakdown) -> Double {
        switch incomeType {
        case .income:
            breakdown.income
        case .incomeAndPositiveAmounts:
            breakdown.incomeAndPositiveAmounts
        case .positiveAmounts:
            breakdown.positiveAmounts
        case .startingAmountsAndPositiveAmounts:
            breakdown.startingAmountsAndPositiveAmounts
        }
    }
    
    
    // MARK: - View Helpers
    
    @AxisContentBuilder
    func xAxis() -> some AxisContent {
        AxisMarks(position: .bottom, values: .automatic) { _ in
            AxisTick()
            AxisGridLine()
            //AxisValueLabel(centered: self.visibleYearCount == .yearToDate)
            AxisValueLabel()
        }
        
        
//        AxisMarks(values: .stride(by: .month)) { date in
//            AxisGridLine()
//            AxisTick()
//            AxisValueLabel(format: .dateTime.month(.abbreviated))
//        }
        
    }
    
    @AxisContentBuilder
    func yAxis(symbol: String = "$") -> some AxisContent {
        AxisMarks(values: .automatic(desiredCount: 6)) {
            AxisGridLine()
            let value = $0.as(Int.self)!
            AxisValueLabel {
                if symbol == "$" {
                    Text("$\(value)")
                } else {
                    Text("\(value)\(symbol)")
                }
            }
        }
    }
    
    func overViewTitle(for date: Date?) -> String {
        if let date = date {
            if viewByQuarter {
                date.quarterString(includeYear: true)
            } else {
                date.string(to: .monthNameYear)
            }
        } else {
            "Select Date"
        }
        
    }
    
    #if os(iOS)
    @ChartContentBuilder
    func selectionRectangle(for date: Date, color: Color = Color(.tertiarySystemBackground)) -> some ChartContent {
        RuleMark(x: .value("Start Date", viewByQuarter ? date.startOfQuarter : date, unit: .month))        
            .foregroundStyle(color.opacity(0.5))
            .zIndex(-1)
    }
    #else
    @ChartContentBuilder
    func selectionRectangle(for date: Date, color: Color = Color(.secondarySystemFill)) -> some ChartContent {
        RuleMark(x: .value("Start Date", viewByQuarter ? date.startOfQuarter : date, unit: .month))        
            .foregroundStyle(color)
            .zIndex(-1)
    }
    #endif
        
        
    #if os(iOS)
    @ChartContentBuilder
    func selectionRectangleOG<Content: View>(for date: Date, color: Color = Color(.tertiarySystemBackground), content: Content) -> some ChartContent {
    //        RectangleMark(
    //            xStart: .value("Start Date", viewByQuarter ? date.startOfQuarter : date, unit: .month),
    //            xEnd: .value("End Date", viewByQuarter ? date.endOfQuarter : date.endDateOfMonth, unit: .day)
    //        )
        
        RuleMark(x: .value("Start Date", viewByQuarter ? date.startOfQuarter : date, unit: .month))
        
        .foregroundStyle(color)
        .zIndex(-1)
        //.offset(yStart: -20)
        .annotation(position: .top, spacing: 0, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
            content
        }
    }
    #else
    @ChartContentBuilder
    func selectionRectangleOG<Content: View>(for date: Date, color: Color = Color(.secondarySystemFill), content: Content) -> some ChartContent {
    //        RectangleMark(
    //            xStart: .value("Start Date", viewByQuarter ? date.startOfQuarter : date, unit: .month),
    //            xEnd: .value("End Date", viewByQuarter ? date.endOfQuarter : date.endDateOfMonth, unit: .day)
    //        )
        
        RuleMark(x: .value("Start Date", viewByQuarter ? date.startOfQuarter : date, unit: .month))
        
        .foregroundStyle(color)
        .zIndex(-1)
        .offset(yStart: -20)
        .annotation(position: .top, spacing: 0, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
            content
        }
    }
    #endif
    
    
    func getGradientPosition(for analyticType: GradientCalculationType, flipAt: Double, min: Double = 0, max: Double = 0) -> Double? {
        var result: Double
        switch analyticType {
        case .amount:
            let profitLosses = relevantBreakdowns().map { $0.profitLoss }
            let minAmount = profitLosses.min() ?? 0
            let maxAmount = profitLosses.max() ?? 0
            result = (flipAt - minAmount) / (maxAmount - minAmount)
            
        case .percentage:
            let percentages = relevantBreakdowns().map { $0.profitLossPercentage }
            let minPer = percentages.min() ?? 0
            let maxPer = percentages.max() ?? 0
            result = (flipAt - minPer) / (maxPer - minPer)
            //print("HEYYYYYY \(result) --- \(minPer) --- \(maxPer)")
            
        case .minMaxEod:
//            let relevant = relevantBreakdowns
//            let minEods = relevant.map { $0.minEod }
//            let maxEods = relevant.map { $0.maxEod }
//            
//            print(minEods)
//            print(maxEods)
//            
//            
//            let minEod = minEods.min() ?? 0
//            let maxEod = maxEods.max() ?? 0
//
            result = (flipAt - min) / (max - min)
        }
       
        //print("(\(flipAt) - \(min)) / (\(max) - \(min)) = \(result)")
        
        
        
        guard !result.isInfinite, !result.isNaN else { return nil }
        if result >= 0 && result <= 1 {
            //print("RETURN \(result)")
            return result
        } else if result < 0 {
            return 0
        } else if result > 1 {
            return 1
        }
        //print("RETURN NIL")
        return nil
    }
}

enum GradientCalculationType {
    case amount, percentage, minMaxEod
}
