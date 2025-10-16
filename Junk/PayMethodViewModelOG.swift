////
////  PayMethodViewModel.swift
////  MakeItRain
////
////  Created by Cody Burnett on 5/14/25.
////
//
//import Foundation
//import SwiftUI
//
//@Observable
//class PayMethodViewModelOG {
//    var payMethods: Array<CBPaymentMethod> = []
//    var chartScrolledToDate: Date = Date()
//    var fetchYearStart = AppState.shared.todayYear - 10
//    var fetchYearEnd = AppState.shared.todayYear
//    var isLoadingHistory = true
//    var isLoadingMoreHistory = false
//    
////    var rawData: [PayMethodMonthlyBreakdown] { data.flatMap { $0.data } }
////    var dates: [Date] { Array(Set(rawData.map { $0.date })) }
////    var minDate: Date { dates.min() ?? Date() }
////    var maxDate: Date { dates.max() ?? Date() }
////    var incomes: [Double] { rawData.map { $0.income } }
////    var minIncome: Double { incomes.min() ?? 0 }
////    var maxIncome: Double { incomes.max() ?? 0 }
//    
//    var rawData: [PayMethodMonthlyBreakdown] = []
//    var dates: [Date] = []
//    var minDate: Date = Date()
//    var maxDate: Date = Date()
//    var incomes: [Double] = []
//    var minIncome: Double = 0
//    var maxIncome: Double = 0
//    
//    
//                    
//    // MARK: - Functions
//    
//    /// `@MainActor`  is required to fix the data race that occurs when `for breakdown in summarizedBreakdowns {}` is still updating `CBPaymentMethod.breakdowns`.
//    /// In the chart, the raw data list will try and read `CBPaymentMethod.breakdowns` before `for breakdown in summarizedBreakdowns {}` is finished.
//    @MainActor
//    func fetchHistory(for payMethod: CBPaymentMethod, payModel: PayMethodModel, setChartAsNew: Bool, visibleYearCount: Int) async {
//        if setChartAsNew {
//            payMethod.breakdowns.removeAll()
//            payMethod.breakdownsRegardlessOfPaymentMethod.removeAll()
//            isLoadingHistory = true
//        }
//        
//        /// Accumulate the various payment method ID associated with the unified payment method.
//        var ids: [String] = []
//        if payMethod.isUnified {
//            let accountType = payMethod.accountType
//            if accountType == .unifiedCredit {
//                for each in payModel.paymentMethods.filter({ $0.accountType == .credit }) {
//                    ids.append(each.id)
//                }
//            } else {
//                for each in payModel.paymentMethods.filter({ $0.accountType == .checking || $0.accountType == .cash }) {
//                    ids.append(each.id)
//                }
//            }
//        } else {
//            ids.append(payMethod.id)
//        }
//        
//        
//        let model = AnalysisRequestModel(recordIDs: ids, fetchYearStart: fetchYearStart, fetchYearEnd: fetchYearEnd)
//        
//        if let payMethods = await payModel.fetchStartingAmountsForDateRange2(model) {
//            var thePayMethods: [CBPaymentMethod] = []
//            /// If a unified view, summarize all the data.
//            if payMethod.isUnified {
//                let rawData: [PayMethodMonthlyBreakdown] = payMethods.flatMap { $0.breakdowns }
//                var summarizedBreakdowns: [PayMethodMonthlyBreakdown] = []
//                let dates: [Date] = rawData.map({ $0.date }).uniqued { $0 }
//                
//                for each in dates {
//                    print(each)
//                    let items = rawData.filter({ Calendar.current.isDate($0.date, inSameDayAs: each) })
//                    let incomes = items.map { $0.income }.reduce(0, +)
//                    let incomesAndPositiveAmounts = items.map { $0.incomeAndPositiveAmounts }.reduce(0, +)
//                    let positiveAmounts = items.map { $0.positiveAmounts }.reduce(0, +)
//                    let startingAmountsAndPositiveAmounts = items.map { $0.startingAmountsAndPositiveAmounts }.reduce(0, +)
//                    let expenses = items.map { $0.expenses }.reduce(0, +)
//                    let payments = items.map { $0.payments }.reduce(0, +)
//                    let startingAmounts = items.map { $0.startingAmounts }.reduce(0, +)
//                    let profitLoss = items.map { $0.profitLoss }.reduce(0, +)
//                    let monthEnd = items.map { $0.monthEnd }.reduce(0, +)
//                    let minEod = items.map { $0.minEod }.first ?? 0
//                    let maxEod = items.map { $0.maxEod }.first ?? 0
//                    
//                    print(items.map { $0.maxEod })
//                    
//                    let summarizedBreakdown = PayMethodMonthlyBreakdown(
//                        payMethodID: payMethod.id,
//                        month: each.month,
//                        year: each.year,
//                        incomeString: String(incomes),
//                        incomeAndPositiveAmountsString: String(incomesAndPositiveAmounts),
//                        positiveAmountsString: String(positiveAmounts),
//                        startingAmountsAndPositiveAmountsString: String(startingAmountsAndPositiveAmounts),
//                        expensesString: String(expenses),
//                        paymentsString: String(payments),
//                        startingAmountsString: String(startingAmounts),
//                        profitLossString: String(profitLoss),
//                        monthEndString: String(monthEnd),
//                        minEodString: String(minEod),
//                        maxEodString: String(maxEod)
//                    )
//                    
//                    summarizedBreakdowns.append(summarizedBreakdown)
//                }
//                
//                
//                for breakdown in summarizedBreakdowns {
//                    if setChartAsNew {
//                        payMethod.breakdowns.append(breakdown)
//                    } else {
//                        if let index = payMethod.breakdowns.firstIndex(where: { $0.month == breakdown.month && $0.year == breakdown.year && $0.payMethodID == breakdown.payMethodID }) {
//                            payMethod.breakdowns[index].setFromAnotherInstance(breakdown)
//                        } else {
//                            payMethod.breakdowns.append(breakdown)
//                        }
//                    }
//                }
//                
//                thePayMethods = [payMethod]
//            } else {
//                thePayMethods = payMethods
//            }
//            
//            
//            /// For each payment method that came from the server.
//            for meth in payMethods {
//                for breakdown in meth.breakdowns {
//                    if setChartAsNew {
//                        if payMethod.breakdownsRegardlessOfPaymentMethod.firstIndex(where: { $0.month == breakdown.month && $0.year == breakdown.year && $0.payMethodID == breakdown.payMethodID }) == nil {
//                            payMethod.breakdownsRegardlessOfPaymentMethod.append(breakdown)
//                        }
//                    } else {
//                        if let index = payMethod.breakdownsRegardlessOfPaymentMethod.firstIndex(where: { $0.month == breakdown.month && $0.year == breakdown.year && $0.payMethodID == breakdown.payMethodID }) {
//                            payMethod.breakdownsRegardlessOfPaymentMethod[index].setFromAnotherInstance(breakdown)
//                        } else {
//                            payMethod.breakdownsRegardlessOfPaymentMethod.append(breakdown)
//                        }
//                    }
//                    
//                    
//                }
//            }
//            
//          
//            if setChartAsNew {
//                self.payMethods = thePayMethods
//                
//                /// Sort the data so it plays nice with the chart.
//                for each in self.payMethods {
//                    each.breakdowns.sort(by: { $0.date < $1.date })
//                }
//                
//                /// Set the scrollPosition to which ever is smaller, the idealStartDate, or the maxAvailStartDate.
//                let rawData: [PayMethodMonthlyBreakdown] = self.payMethods.flatMap { $0.breakdowns }
//                let dates: [Date] = rawData.map({ $0.date }).uniqued { $0 }
//                let minDate = dates.min() ?? Date()
//                let maxDate = dates.max() ?? Date()
//                
//                //let maxDate = data.last?.date ?? Date()
//                let idealDate = Calendar.current.date(byAdding: .day, value: -(365 * visibleYearCount), to: maxDate)!
//                                
//                if visibleYearCount == 0 {
//                    let components = Calendar.current.dateComponents([.year], from: .now)
//                    chartScrolledToDate = Calendar.current.date(from: components)!
//                } else {
//                    chartScrolledToDate = minDate < idealDate ? idealDate : minDate
//                }
//            
//                isLoadingHistory = false
//                
//            } else {
//                /// When fetching more data (like at the end of the list), if the data does not already exist, append it.
//                for meth in thePayMethods {
//                    if let index = self.payMethods.firstIndex(where: { $0.id == meth.id }) {
//                        let obj = self.payMethods[index]
//                        for breakdown in meth.breakdowns {
//                            if let index = obj.breakdowns.firstIndex(where: { $0.month == breakdown.month && $0.year == breakdown.year && $0.payMethodID == breakdown.payMethodID }) {
//                                obj.breakdowns[index].setFromAnotherInstance(breakdown)
//                            } else {
//                                obj.breakdowns.append(breakdown)
//                            }
//                        }
//                    }
//                }
//                
//                /// Sort the data so it plays nice with the chart.
//                for each in self.payMethods {
//                    each.breakdowns.sort(by: { $0.date < $1.date })
//                }
//            }
//        }
//        
//        
////        for each in self.payMethods {
////            for each in each.data {
////                print("\(each.month) - \(each.year)")
////            }
////        }
//        
//        prepareData()
//        isLoadingMoreHistory = false
//    }
//    
//    
//    func fetchMoreHistory(for payMethod: CBPaymentMethod, payModel: PayMethodModel, visibleYearCount: Int) {
//        Task {
//            isLoadingMoreHistory = true
//            fetchYearStart -= 10
//            fetchYearEnd -= 10
//            print("fetching more history... \(fetchYearStart) - \(fetchYearEnd)")
//            await fetchHistory(for: payMethod, payModel: payModel, setChartAsNew: false, visibleYearCount: visibleYearCount)
//        }
//    }
//    
//    
//    func numberOfDays(_ num: Int) -> Int { (3600 * 24) * num }
//    
//    
//    
//    func setChartScrolledToDate(_ newValue: CategoryAnalyticChartRange) {
//        /// Set the scrollPosition to which ever is smaller, the targetDate, or the minDate.
//        var targetDate: Date
//        /// If 0, which means it's YTD, start with the maxDate and work backwards to January 1st.
//        if newValue.rawValue == 0 {
//            let components = Calendar.current.dateComponents([.year], from: .now)
//            targetDate = Calendar.current.date(from: components)!
//        } else {
//            ///-365, -730, etc
//            let value = -(365 * newValue.rawValue)
//            /// start with the maxDate and work backwards using the value.
//            targetDate = Calendar.current.date(byAdding: .day, value: value, to: maxDate)!
//        }
//        
//        print("-- \(#function) -- \(targetDate)")
//        
//        /// chartScrolledToDate is the beginning of the chart view.
//        if targetDate < minDate && newValue.rawValue != 0 {
//            chartScrolledToDate = minDate
//        } else {
//            chartScrolledToDate = targetDate
//        }
//    }
//    
//    
//    func prepareData() {
//        print("-- \(#function)")
//        
////        for each in self.payMethods {
////            for each in each.breakdowns {
////                print("\(each.month) - \(each.year)")
////            }
////        }
//        
//        self.rawData = payMethods.flatMap { $0.breakdowns }
//        self.dates = rawData.map { $0.date }
//        self.minDate = dates.min() ?? Date()
//        self.maxDate = dates.max() ?? Date()
//        self.incomes = rawData.map { $0.income }
//        self.minIncome = incomes.min() ?? 0
//        self.maxIncome = incomes.max() ?? 0
//    }
//    
//    
//    func amountPerObject(on selectedDate: Date) -> [PayMethodChartSelectedDateDetails] {
//        var returnMe: [PayMethodChartSelectedDateDetails] = []
//        for pay in payMethods {
//            for each in pay.breakdowns {
//                if Calendar.current.isDate(each.date, equalTo: selectedDate, toGranularity: .month) {
//                    
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
//                        monthEnd: each.monthEnd,
//                        minEod: each.minEod,
//                        maxEod: each.maxEod
//                    )
//                    
//                    returnMe.append(thing)
//                }
//            }
//        }
//        
//        return returnMe
//    }
//}
