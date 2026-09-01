//
//  CalendarModel+StartingAmounts.swift
//  MakeItRain
//
//  Created by Cody Burnett on 8/31/26.
//

import Foundation

extension CalendarModel {
    @MainActor
    func submit(_ startingAmount: CBStartingAmount) async {
        print("-- \(#function)")
        print("\(startingAmount.payMethod?.title) -- \(startingAmount.amountString) -- \(startingAmount.month) -- \(startingAmount.year) -- \(startingAmount.action.serverKey)")
        //LoadingManager.shared.startDelayedSpinner()
        
        /// Allow more time to save if the user enters the background.
        #if os(iOS)
        var backgroundTaskId = AppState.shared.beginBackgroundTask()
        #endif
        
        
        if startingAmount.month == 13 {
            startingAmount.month = 1
            startingAmount.year = startingAmount.year + 1
        } else if startingAmount.month == 0 {
            startingAmount.month = 12
            startingAmount.year = startingAmount.year - 1
        }
        
        LogManager.log()
        let model = RequestModel(requestType: startingAmount.action.serverKey, model: startingAmount)
            
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        typealias ResultResponse = Result<ReturnIdModel?, AppError>
        let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch result {
        case .success(let model):
            LogManager.networkingSuccessful()
            /// Get the new ID from the server after adding a new activity.
            if startingAmount.action == .add {
                startingAmount.id = model?.id ?? "0"
                startingAmount.uuid = nil
                startingAmount.action = .edit
            }
            
            /// End the background task.
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
            #endif
            
        case .failure(let error):
            switch error {
            case .taskCancelled:
                print("\(#function) Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to save the starting amount.")
            }
            
            /// End the background task.
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
            #endif
        }
    }
    
    
    func startingAmountSheetDismissed() {
        CalcHelper.updateUnifiedStartingAmount(month: self.sMonth, for: .unifiedChecking, store: store)
        CalcHelper.updateUnifiedStartingAmount(month: self.sMonth, for: .unifiedCredit, store: store)
        CalcHelper.calculateTotal(for: self.sMonth, store: store)
        
        /// If the dashboard is open in the inspector on iPad, it won't be recalculate its data on its own.
        /// So we use the ``DataChangeTriggers`` class to send a notification to the view to tell it to recalculate.
        DataChangeTriggers.shared.viewDidChange(.calendar)
        
        Task {
            await withTaskGroup(of: Void.self) { group in
                let starts = self.sMonth.startingAmounts.filter { $0.payMethod?.isUnified == false }
                for start in starts {
                    if start.hasChanges() {
                        group.addTask {
                            await self.submit(start)
                        }
                    } else {
                        //print("No Starting amount Changes for \(start.payMethod.title)")
                    }
                }
            }
        }
    }
}
