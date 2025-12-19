//
//  CivViewModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/19/25.
//


import SwiftUI
import Charts

@Observable
class CivViewModel {
    var monthsForAnalysis: [CBMonth] = []
    var transactions: [CBTransaction] = []
    var totalSpent: Double = 0.0
    var spendMinusIncome: Double = 0.0
    var spendMinusPayments: Double = 0.0
    var cashOut: Double = 0.0
    var income: Double = 0.0
    var budget: Double = 0.0
    var chartData: [ChartData] = []
    var cumTotals: [CumTotal] = []
    var progress: Double = 0
    var statusMessage: String = ""
    
    
    var selectedDataPoint: CivDataPoint? = nil
    var selectedMonthGroup: Array<CivMonthlyData> = []
    var selectedMonth: CivMonthlyData?
    
    
    var showLoadingSpinner = false
    var loadingSpinnerTimer: Timer?
    @objc func showLoadingSpinnerViaTimer() {
        showLoadingSpinner = true
    }
    
    func startDelayedLoadingSpinnerTimer() {
        loadingSpinnerTimer = Timer(
            fireAt: Date.now.addingTimeInterval(0.5),
            interval: 0,
            target: self,
            selector: #selector(showLoadingSpinnerViaTimer),
            userInfo: nil,
            repeats: false
        )
        RunLoop.main.add(loadingSpinnerTimer!, forMode: .common)
    }
    
    func stopDelayedLoadingSpinnerTimer() {
        if let loadingSpinnerTimer = self.loadingSpinnerTimer {
            loadingSpinnerTimer.invalidate()
        }
        if showLoadingSpinner {
            showLoadingSpinner = false
        }
        
    }
}



@Observable
class CivMonthlyData: Hashable, Identifiable {
    var id = UUID()
    var dataPoint: CivDataPoint
    var month: CBMonth
    var trans: [CBTransaction]
    var breakdown: CivBreakdownData
    
    init(id: UUID = UUID(), dataPoint: CivDataPoint, month: CBMonth, trans: [CBTransaction], breakdown: CivBreakdownData) {
        self.id = id
        self.dataPoint = dataPoint
        self.month = month
        self.trans = trans
        self.breakdown = breakdown
    }
    
    static func == (lhs: CivMonthlyData, rhs: CivMonthlyData) -> Bool {
        lhs.month.id == rhs.month.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(month.id)
    }
}


struct CivBreakdownData: Identifiable {
    var id = UUID()
    var moneyIn: Double
    var cashOut: Double
    var spending: Double
    var actualSpending: Double
    //var totalSpending: Double
}
