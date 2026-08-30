//
//  CategoryModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/28/24.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class RepeatingTransactionModel {
    @ObservationIgnored private let store: AppStore
    init(store: AppStore) {
        self.store = store
    }
    
    var isThinking = false
    
    var repTransactions: [CBRepeatingTransaction] {
        get { store.repTransactions }
        set { store.repTransactions = newValue }
    }
    
    
    //var repTransactions: Array<CBRepeatingTransaction> = []
    
    var fuckYouSwiftuiTableRefreshID: UUID = UUID()
        
    func doesExist(_ repTransaction: CBRepeatingTransaction) -> Bool {
        return !repTransactions.filter { $0.id == repTransaction.id }.isEmpty
    }
    
    func getRepeatingTransaction(by id: String) -> CBRepeatingTransaction? {
        return repTransactions.first(where: { $0.id == id })
    }
    
    func upsert(_ repTransaction: CBRepeatingTransaction) {
        if !doesExist(repTransaction) {
            repTransactions.append(repTransaction)
        }
    }
    
    func getIndex(for repTransaction: CBRepeatingTransaction) -> Int? {
        return repTransactions.firstIndex(where: { $0.id == repTransaction.id })
    }
    
        
    @MainActor
    func handleIncoming(reps: Array<CBRepeatingTransaction>, incomingDataType: IncomingDataType) async {
        if reps.isEmpty {
            self.repTransactions.removeAll()
            return
        }
                
        for repTransaction in reps.sorted(by: { $0.title.lowercased() < $1.title.lowercased() }) {
            await repTransaction.payMethod?.loadLogoFromCoreDataIfNeeded()
            await repTransaction.payMethodPayTo?.loadLogoFromCoreDataIfNeeded()
            
            if self.doesExist(repTransaction) {
                if !repTransaction.active {
                    await self.delete(repTransaction, andSubmit: false)
                    continue
                } else if let index = self.getIndex(for: repTransaction) {
                    self.repTransactions[index].setFromAnotherInstance(repTransaction: repTransaction)
                    self.repTransactions[index].deepCopy?.setFromAnotherInstance(repTransaction: repTransaction)
                }
            } else if repTransaction.active {
                withAnimation { self.upsert(repTransaction) }
            }
        }
        
        /// When downloading everything from the server, if we find a local object that is not in the server payload, it means it is no longer valid and must be deleted from the local copies.
        if incomingDataType == .viaStandardRefresh {
            for rep in self.repTransactions {
                if reps.filter({ $0.id == rep.id }).isEmpty {
                    await delete(rep, andSubmit: false)
                }
            }
        }
    }
    
    
    @discardableResult
    func saveTransaction(id: String) async -> Bool {
        guard let repTransaction = getRepeatingTransaction(by: id) else { return true }
                
        if repTransaction.action == .delete {
            repTransaction.updatedBy = AppState.shared.user!
            repTransaction.updatedDate = Date()
            return await delete(repTransaction, andSubmit: true)
        }
        
        /// User blanked out the title of an existing transaction.
        if repTransaction.action == .edit && repTransaction.title.isEmpty {
            repTransaction.title = repTransaction.deepCopy?.title ?? ""
            AppState.shared.showAlert("Removing a title is not allowed. If you want to delete \(repTransaction.title), please use the delete button instead.")
            return false
        }
        
        /// User is entering a new transaction but forgot the payment method.
        /// Remove the dud that is in `.add` mode since it's being upserted into the list on creation.
        if repTransaction.title.isEmpty && repTransaction.payMethod == nil {
            //AppState.shared.showAlert(title: "Not Saved", subtitle: "An account is required.")
            withAnimation { repTransactions.removeAll { $0.id == id } }
            return false
        }
        
        if repTransaction.hasChanges() {
            repTransaction.updatedBy = AppState.shared.user!
            repTransaction.updatedDate = Date()
            return await submit(repTransaction)
        }
        
        return false
    }
        

    @MainActor
    @discardableResult
    func submit(_ repTransaction: CBRepeatingTransaction) async -> Bool {
        print("-- \(#function)")
        
        /// Allow more time to save if the user enters the background.
        #if os(iOS)
        var backgroundTaskId = AppState.shared.beginBackgroundTask()
        #endif
        
        isThinking = true
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        let model = RequestModel(requestType: repTransaction.action.serverKey, model: repTransaction)
            
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        typealias ResultResponse = Result<ReturnIdModel?, AppError>
        let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch result {
        case .success(let model):
            LogManager.networkingSuccessful()
            
            isThinking = false
            if repTransaction.action != .delete {
                if repTransaction.action == .add {
                    repTransaction.id = model?.id ?? "0"
                    repTransaction.action = .edit
                }                
            }
                                    
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to save the recurring transaction.")
            
            isThinking = false
            repTransaction.action = .edit
            
            switch repTransaction.action {
            case .add: repTransactions.removeAll { $0.id == repTransaction.id }
            case .edit: repTransaction.deepCopy(.restore)
            case .delete: repTransactions.append(repTransaction)
            }
        }
        
        /// End the background task.
        #if os(iOS)
        AppState.shared.endBackgroundTask(&backgroundTaskId)
        #endif
                        
        #if os(macOS)
        fuckYouSwiftuiTableRefreshID = UUID()
        #endif
                        
        return (await result).isSuccess
    }
    
    
    @discardableResult
    func delete(_ repTransaction: CBRepeatingTransaction, andSubmit: Bool) async -> Bool {
        repTransaction.action = .delete
        withAnimation { repTransactions.removeAll { $0.id == repTransaction.id } }
        return andSubmit ? await submit(repTransaction) : false
    }
    
    
    func deleteAll() async {
        for trans in repTransactions {
            trans.action = .delete
            await submit(trans)
        }
        repTransactions.removeAll()
    }
}
