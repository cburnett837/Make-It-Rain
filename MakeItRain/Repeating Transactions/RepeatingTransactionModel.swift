//
//  CategoryModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/28/24.
//

import Foundation

@MainActor
@Observable
class RepeatingTransactionModel {
    //static let shared = RepeatingTransactionModel()
    var isThinking = false
    
    //var repTransactionEditID: Int?
    var repTransactions: Array<CBRepeatingTransaction> = []
    //var refreshTask: Task<Void, Error>?
    var fuckYouSwiftuiTableRefreshID: UUID = UUID()
        
    func doesExist(_ repTransaction: CBRepeatingTransaction) -> Bool {
        return !repTransactions.filter { $0.id == repTransaction.id }.isEmpty
    }
    
    func getRepeatingTransaction(by id: String) -> CBRepeatingTransaction {
        return repTransactions.filter { $0.id == id }.first ?? CBRepeatingTransaction(uuid: id)
    }
    
    func upsert(_ repTransaction: CBRepeatingTransaction) {
        if !doesExist(repTransaction) {
            repTransactions.append(repTransaction)
        }
    }
    
    func getIndex(for repTransaction: CBRepeatingTransaction) -> Int? {
        return repTransactions.firstIndex(where: { $0.id == repTransaction.id })
    }
    
    func saveTransaction(id: String) {
        let repTransaction = getRepeatingTransaction(by: id)
        Task {
            if repTransaction.title.isEmpty || repTransaction.payMethod == nil {
                if repTransaction.action != .add && repTransaction.title.isEmpty {
                    repTransaction.title = repTransaction.deepCopy?.title ?? ""
                    AppState.shared.showAlert("Removing a title is not allowed. If you want to delete \(repTransaction.title), please use the delete button instead.")
                } else {
                    repTransactions.removeAll { $0.id == id }
                }
                return
            }
            
            if repTransaction.hasChanges() {
                print("HAS CHANGES")
                repTransaction.updatedBy = AppState.shared.user!
                repTransaction.updatedDate = Date()
                await submit(repTransaction)
            } else {
                print("DOES NOT HAVE CHANGES")
            }
        }
    }
    
    
    @MainActor
    func fetchRepeatingTransactions(file: String = #file, line: Int = #line, function: String = #function) async {
        NSLog("\(file):\(line) : \(function)")
        LogManager.log()
        let start = CFAbsoluteTimeGetCurrent()
        
        /// Do networking.
        let model = RequestModel(requestType: "fetch_repeating_transactions", model: AppState.shared.user)
        typealias ResultResponse = Result<Array<CBRepeatingTransaction>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            
            /// For testing bad network connection.
            //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))

            LogManager.networkingSuccessful()
            if let model {
                if !model.isEmpty {
                    var activeIds: Array<String> = []
                    for repTransaction in model.sorted(by: { $0.title.lowercased() < $1.title.lowercased() }) {
                        activeIds.append(repTransaction.id)
                        let index = repTransactions.firstIndex(where: { $0.id == repTransaction.id })
                        if let index {
                            /// If the transaction is already in the list, update it from the server.
                            repTransactions[index].setFromAnotherInstance(repTransaction: repTransaction)
                        } else {
                            /// Add the transaction to the list (like when the transaction was added on another device).
                            repTransactions.append(repTransaction)
                        }
                    }
                    
                    /// Delete from model.
                    for repTransaction in repTransactions {
                        if !activeIds.contains(repTransaction.id) {
                            repTransactions.removeAll { $0.id == repTransaction.id }
                        }
                    }
                } else {
                    repTransactions.removeAll()
                }
            }
            
            /// Update the progress indicator.
            AppState.shared.downloadedData.append(.repeatingTransactions)
            
            let currentElapsed = CFAbsoluteTimeGetCurrent() - start
            print("⏰It took \(currentElapsed) seconds to fetch the repeating transactions")
            
        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("repModel fetchFrom Server Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch the repTransactions.")
            }
        }
    }
    
    
    @MainActor
    func submit(_ repTransaction: CBRepeatingTransaction) async {
        print("-- \(#function)")
        isThinking = true
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        let model = RequestModel(requestType: repTransaction.action.serverKey, model: repTransaction)
            
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        typealias ResultResponse = Result<ReturnIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            
            if repTransaction.action != .delete {
                if repTransaction.action == .add {
                    repTransaction.id = model?.id ?? "0"
                    repTransaction.action = .edit
                }                
            }
                                    
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to save the repeating transaction.")
            repTransaction.deepCopy(.restore)
            
            switch repTransaction.action {
            case .add: repTransactions.removeAll { $0.id == repTransaction.id }
            case .edit: break
            case .delete: repTransactions.append(repTransaction)
            }
        }
        
        isThinking = false
        repTransaction.action = .edit
        #if os(macOS)
        fuckYouSwiftuiTableRefreshID = UUID()
        #endif
    }
    
    
    func delete(_ repTransaction: CBRepeatingTransaction, andSubmit: Bool) async {
        repTransaction.action = .delete
        repTransactions.removeAll { $0.id == repTransaction.id }
        
        if andSubmit {
            await submit(repTransaction)
        }
    
    }
    
    
    func deleteAll() async {
        for trans in repTransactions {
            trans.action = .delete
            await submit(trans)
        }
        repTransactions.removeAll()
    }
}
