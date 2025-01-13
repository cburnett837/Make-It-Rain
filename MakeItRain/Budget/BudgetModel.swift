////
////  BudgetModel.swift
////  MakeItRain
////
////  Created by Cody Burnett on 10/30/24.
////
//import Foundation
//import SwiftUI
//
//@MainActor
//@Observable
//class BudgetModel {
//    var budgetEditID: Int?
//    var budgets: Array<CBBudget> = []
//    //var refreshTask: Task<Void, Error>?
//    var fuckYouSwiftuiTableRefreshID: UUID = UUID()
//    
//    func getBudget(by id: Int) -> CBBudget {
//        return budgets.filter { $0.id == id }.first ?? CBBudget.empty
//    }
//    
//    func upsert(_ budget: CBBudget) {
//        func isExisting(_ budget: CBBudget) -> Bool {
//            return !budgets.filter { $0.id == budget.id }.isEmpty
//        }
//        
//        if !isExisting(budget) {
//            budgets.append(budget)
//        }
//    }
//    
//    
//    @MainActor
//    func fetchBudgets() async {
//        LogManager.log()
//        
//        /// Take a snapshot of the data before the server data is fetched.
//        var preTaskSnapshot: Array<CBBudget> = []
//        budgets.forEach {
//            $0.deepCopy(.create)
//            preTaskSnapshot.append($0.deepCopy ?? .empty)
//        }
//        
//        /// Do networking.
//        let model = RequestModel(requestType: "fetch_repeating_transactions", model: AppState.shared.user)
//        typealias ResultResponse = Result<Array<CBBudget>?, AppError>
//        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
//        
//        switch await result {
//        case .success(let model):
//            
//            /// For testing bad network connection.
//            //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
//
//            LogManager.networkingSuccessful()
//            if let model {
//                if !model.isEmpty {
//                    
//                    /// Take a snapshot of the data after the server data has been fetched.
//                    var postTaskSnapshot: Array<CBBudget> = []
//                    budgets.forEach {
//                        $0.deepCopy(.create)
//                        postTaskSnapshot.append($0.deepCopy ?? .empty)
//                    }
//                    
//                    /// See if any payment methods have been changed while the app was talking to the server.
//                    if preTaskSnapshot != postTaskSnapshot {
//                        print("⚠️ SOMETHING CHANGED WHEN THE NETWORK CALL WAS HAPPENING. DATA OUT OF SYNC!")
//                        for budget in model {
//                            if let postSnapshotCategory = postTaskSnapshot.filter({ $0.id == budget.id }).first {
//                                /// If the payment method found locally, merge the local changes into the server model.
//                                budget.setFromAnotherInstance(budget: postSnapshotCategory)
//                            } else {
//                                /// If not found, the payment method was deleted locally. So remove it from the server model.
//                                budgets.removeAll { $0.id == budget.id }
//                            }
//                        }
//                    }
//                    
//                    for budget in model {
//                        let index = budgets.firstIndex(where: { $0.id == budget.id })
//                        if let index {
//                            /// If the transaction is already in the list, update it from the server.
//                            budgets[index] = budget
//                        } else {
//                            /// Add the transaction to the list (like when the transaction was added on another device).
//                            budgets.append(budget)
//                        }
//                    }
//                }
//            }
//            
//            /// Update the progress indicator.
//            AppState.shared.downloadedData.append(.budgets)
//            
//        case .failure (let error):
//            switch error {
//            case .taskCancelled:
//                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
//                print("budgetModel fetchFrom Server Task Cancelled")
//            default:
//                LogManager.error(error.localizedDescription)
//                AppState.shared.showAlert("There was a problem trying to fetch the budgets.")
//            }
//        }
//    }
//    
//    
//    @MainActor
//    func submit(_ budget: CBBudget) async {
//        print("-- \(#function)")
//        //LoadingManager.shared.startDelayedSpinner()
//        LogManager.log()
//        let model = RequestModel(requestType: budget.action.serverKey, model: budget)
//            
//        /// Used to test the snapshot data race
//        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
//        
//        typealias ResultResponse = Result<ParentReturnIdModel?, AppError>
//        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
//                    
//        switch await result {
//        case .success(let model):
//            LogManager.networkingSuccessful()
//            
//            if let model {
//                budget.id = model.parentID
//                budget.action = .edit
//            }
//            
//            fuckYouSwiftuiTableRefreshID = UUID()
//            
//        case .failure(let error):
//            LogManager.error(error.localizedDescription)
//            AppState.shared.showAlert("There was a problem trying to save the repeating transaction.")
//            #warning("Undo behavior")
//        }
//        //LoadingManager.shared.stopDelayedSpinner()
//    }
//    
//    
//    func delete(_ budget: CBBudget) async {
//        budget.action = .delete
//        budgets.removeAll { $0 == budget }
//        
//        await submit(budget)
//    }
//    
//    
//    func deleteAll() async {
//        for trans in budgets {
//            trans.action = .delete
//            await submit(trans)
//        }
//        budgets.removeAll()
//    }
//}
