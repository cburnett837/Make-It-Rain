////
////  CivViewModel.swift
////  MakeItRain
////
////  Created by Cody Burnett on 12/19/25.
////
//
//
//import SwiftUI
//import Charts
//
//@Observable
//class CivViewModel {
//    var monthsForAnalysis: [CBMonth] = []
//    var transactions: [CBTransaction] = []
//    var totalSpent: Double = 0.0
//    var spendMinusIncome: Double = 0.0
//    var spendMinusPayments: Double = 0.0
//    var cashOut: Double = 0.0
//    var income: Double = 0.0
//    var budget: Double = 0.0
//    var budgetVsSpendChartData: [ChartData] = []
//    var groupBudgetVsSpendChartData: [GroupChartData] = []
//    var cumTotals: [CumTotal] = []
//    var progress: Double = 0
//    var statusMessage: String = ""
//    var spendingBreakdownChartdata = [CivSpendingBreakdownChartData]()
//    var transactionCountChartData = [CivTransactionCountChartData]()
//    var actualSpendingBreakdownByCategoryChartData = [CivActualSpendingBreakdownByCategoryOuterChartData]()
//    
//    var selectedDataPoint: CivDataPoint? = nil
//    var selectedMonthGroup: Array<CivMonthlyData> = []
//    var selectedMonth: CivMonthlyData?
//        
//    var showLoadingSpinner = false
//    var loadingSpinnerTimer: Timer?
//    @objc func showLoadingSpinnerViaTimer() {
//        showLoadingSpinner = true
//    }
//    
//    func startDelayedLoadingSpinnerTimer() {
//        loadingSpinnerTimer = Timer(
//            fireAt: Date.now.addingTimeInterval(0.5),
//            interval: 0,
//            target: self,
//            selector: #selector(showLoadingSpinnerViaTimer),
//            userInfo: nil,
//            repeats: false
//        )
//        RunLoop.main.add(loadingSpinnerTimer!, forMode: .common)
//    }
//    
//    func stopDelayedLoadingSpinnerTimer() {
//        if let loadingSpinnerTimer = self.loadingSpinnerTimer {
//            loadingSpinnerTimer.invalidate()
//        }
//        if showLoadingSpinner {
//            showLoadingSpinner = false
//        }
//    }
//    
//    
//    @AxisContentBuilder
//    var chartXAxis: some AxisContent {
//        AxisMarks(values: .stride(by: .month, count: 1)) { value in
//            AxisGridLine()
//            AxisTick()
//            AxisValueLabel {
//                if let date = value.as(Date.self) {
//                    if self.monthsForAnalysis.count > 8 {
//                        Text(date, format: .dateTime.month(.narrow))
//                    } else {
//                        Text(date, format: .dateTime.month(.abbreviated))
//                    }
//                    
//                }
//            }
//        }
//    }
//}
//
//
//
//@Observable
//class CivMonthlyData: Hashable, Identifiable {
//    var id = UUID()
//    var dataPoint: CivDataPoint
//    var month: CBMonth
//    var trans: [CBTransaction]
//    var breakdown: CivBreakdownData
//    var dataByCategory: [CivBreakdownData]
//    
//    init(id: UUID = UUID(), dataPoint: CivDataPoint, month: CBMonth, trans: [CBTransaction], breakdown: CivBreakdownData, dataByCategory: [CivBreakdownData]) {
//        self.id = id
//        self.dataPoint = dataPoint
//        self.month = month
//        self.trans = trans
//        self.breakdown = breakdown
//        self.dataByCategory = dataByCategory
//    }
//    
//    static func == (lhs: CivMonthlyData, rhs: CivMonthlyData) -> Bool {
//        lhs.month.id == rhs.month.id
//    }
//    
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(month.id)
//    }
//}
//
//
//struct CivBreakdownData: Identifiable {
//    var id = UUID()
//    var category: CBCategory?
//    var moneyIn: Double
//    var cashOut: Double
//    var spending: Double
//    var actualSpending: Double
//    //var totalSpending: Double
//}
//
//
//enum CivDataPoint {
//    case moneyIn, cashOut, totalSpending, actualSpending, all
//    
//    var titleString: String {
//        switch self {
//        case .moneyIn:
//            "Money In"
//        case .cashOut:
//            "Cash Out"
//        case .totalSpending:
//            "Total Spending"
//        case .actualSpending:
//            "Actual Spending"
//        case .all:
//            "All Transactions"
//        }
//    }
//}
//
//
//
//struct CivSpendingBreakdownChartData: Identifiable {
//    var id: UUID { return month.id }
//    var month: CBMonth
//    var date: Date
//    var cost: Double
//}
//
//struct CivTransactionCountChartData: Identifiable {
//    var id: UUID { return month.id }
//    var month: CBMonth
//    var date: Date
//    var count: Int
//}
//
//struct CivActualSpendingBreakdownByCategoryOuterChartData: Identifiable {
//    var id: String {
//        //UUID().uuidString
//        //"\(group?.id ?? "0")-\(category?.id ?? "0")"
//        if let category {
//            category.id
//        } else if let group {
//            "\(group.id)-\(costPerMonth.map {$0.category.id})"
//        } else {
//            UUID().uuidString
//        }
//    }
//    var category: CBCategory?
//    var group: CBCategoryGroup?
//    var costPerMonth: [ChartData]
//}
////
////struct CivActualSpendingBreakdownByCategoryChartData: Identifiable {
////    var id: UUID { return month.id }
////    var month: CBMonth
////    var category: CBCategory?
////    var date: Date
////    var cost: Double
////    
////    var budgetForCategory: Double
////    var budgetForCategoryGroup: Double?
////    var income: Double
////    var incomeMinusPayments: Double
////    var expenses: Double
////    var expensesMinusIncome: Double
////}
