//
//  CalendarModel+MonthManipulators.swift
//  MakeItRain
//
//  Created by Cody Burnett on 8/31/26.
//

import Foundation

extension CalendarModel {
    func prepareForRefresh() {
        months.forEach { month in
            month.days.removeAll()
            month.budgets.removeAll()
            month.startingAmounts.removeAll()
            tempTransactions.removeAll()
        }
        prepareMonths()
    }
    
    
    func prepareMonths() {
        months.forEach { month in
            if month.days.isEmpty {
                if month.firstWeekdayOfMonth != 1 {
                    for i in 0 ..< month.firstWeekdayOfMonth - 1 {
                        month.days.append(CBDay(id: i-50))
                    }
                }
                
                for i in 1 ..< month.dayCount + 1 {
                    var components: DateComponents
                    
                    if month.enumID == .lastDecember {
                        components = DateComponents(year: sYear - 1, month: 12, day: i)
                        
                    } else if month.enumID == .nextJanuary {
                        components = DateComponents(year: sYear + 1, month: 1, day: i)
                        
                    } else {
                        components = DateComponents(year: sYear, month: month.num, day: i)
                    }
                    
                    let theDate = Calendar.current.date(from: components)!
                    month.days.append(CBDay(date: theDate))
                }
            }
        }
    }
    
    
    func prepare(month: CBMonth) {
        if month.days.isEmpty {
            if month.firstWeekdayOfMonth != 1 {
                for i in 0 ..< month.firstWeekdayOfMonth - 1 {
                    month.days.append(CBDay(id: i-50))
                }
            }
            
            for i in 1 ..< month.dayCount + 1 {
                var components: DateComponents
                
                if month.enumID == .lastDecember {
                    components = DateComponents(year: sYear - 1, month: 12, day: i)
                    
                } else if month.enumID == .nextJanuary {
                    components = DateComponents(year: sYear + 1, month: 1, day: i)
                    
                } else {
                    components = DateComponents(year: sYear, month: month.num, day: i)
                }
                
                let theDate = Calendar.current.date(from: components)!
                month.days.append(CBDay(date: theDate))
            }
        }
    }
    
    
    func resetMonth(_ resetModel: ResetOptions) {
        resetModel.paymentMethods.forEach { meth in
            if meth.transactions {
                sMonth.days.forEach { $0.transactions.removeAll { $0.payMethod?.id == meth.id } }
            }
            
            if meth.startingAmount {
                sMonth.startingAmounts.removeAll { $0.payMethod?.id == meth.id }
            }
        }
                                
        if resetModel.budget { sMonth.budgets.removeAll() }
        if resetModel.hasBeenPopulated { sMonth.hasBeenPopulated = false }
                
        CalcHelper.calculateTotal(for: sMonth, store: store)
        
        resetModel.month = sMonth.actualNum
        resetModel.year = sMonth.year
        
        Task {
            /// Allow more time to save if the user enters the background.
            #if os(iOS)
            var backgroundTaskId = AppState.shared.beginBackgroundTask()
            #endif
            
            LogManager.log()
            
            //let resetModel = ResetMonthModel(month: sMonth.num, year: sYear)
            let model = RequestModel(requestType: "reset_month", model: resetModel)
            
            typealias ResultResponse = Result<ResultCompleteModel?, AppError>
            let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                        
            switch result {
            case .success:
                LogManager.networkingSuccessful()
                
                /// End the background task.
                #if os(iOS)
                AppState.shared.endBackgroundTask(&backgroundTaskId)
                #endif
                
            case .failure(let error):
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to save the starting amount.")
                /// End the background task.
                #if os(iOS)
                AppState.shared.endBackgroundTask(&backgroundTaskId)
                #endif
            }
            //LoadingManager.shared.stopDelayedSpinner()
            //self.refreshTask = nil
        }
    }
}
