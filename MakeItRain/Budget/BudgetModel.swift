////
////  BudgetModel.swift
////  MakeItRain
////
////  Created by Cody Burnett on 10/30/24.
////
import Foundation
import SwiftUI

struct TagRequestModel: Encodable {
    var tagId: String
    
    enum CodingKeys: CodingKey { case tag_id, user_id, account_id, device_uuid }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tagId, forKey: .tag_id)
        try container.encode(Cody.shared.id, forKey: .user_id)
        try container.encode(Cody.shared.accountID, forKey: .account_id)
        try container.encode(Cody.shared.deviceUUID, forKey: .device_uuid)
    }
}


@MainActor
@Observable
class BudgetModel {
    @ObservationIgnored private let store: AppStore
    init(store: AppStore) {
        self.store = store
    }
    
    var budgets: [CBBudgetItem] {
        get { store.budgets }
        set { store.budgets = newValue }
    }
    
    var globalBudget: CBBudget {
        get { store.globalBudget }
        set { store.globalBudget = newValue }
    }
    
    func getBudgetItem(by id: String, from location: WhereToLookForBudget = .globalList) -> CBBudgetItem? {
        let theList = switch location {
        case .globalList: store.budgets
        case .monthList: store.sMonth.budgets
        }
        
        if let budget = theList.first(where: { $0.id == id }) { return budget }
        return nil
    
    }
    
    
    @MainActor
    func handleIncoming(budgets: [CBBudgetItem], incomingDataType: IncomingDataType) {
        self.budgets = budgets
    }
    
    @MainActor
    func handleIncoming(globalBudget: CBBudget, incomingDataType: IncomingDataType) {
        self.globalBudget = globalBudget
    }
    
    
    func saveBudget(id: String, location: WhereToLookForBudget) {
        print("-- \(#function)")
        guard let budget = getBudgetItem(by: id, from: location) else {
            print("Could not find budget")
            return
        }
                
        
        if budget.action == .delete {
            delete(budget, andSubmit: true)
            return
        }
        
        guard let item = budget.item else {
            print("Budget doesn't have an item. Deleting.")
            delete(budget, andSubmit: budget.action != .add)
            return
        }
        
        if item.title.isEmpty {
            store.budgets.removeAll(where: { $0.id == id })
        }
        
        if budget.hasChanges() {
            Task {
                await submit(budget)
            }
        }
    }
    
    
    @MainActor
    func submit(_ budget: CBBudgetItem) async {
        print("-- \(#function)")
        
        /// Allow more time to save if the user enters the background.
        #if os(iOS)
        var backgroundTaskId = AppState.shared.beginBackgroundTask()
        #endif
        
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        //print("\(budget.action.serverKey.capitalized) BUDGET!")
        let model = RequestModel(requestType: budget.action.serverKey, model: budget)
            
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        typealias ResultResponse = Result<ParentChildIdModel?, AppError>
        let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch result {
        case .success(let model):
            LogManager.networkingSuccessful()
                        
            if budget.action == .add {
                budget.id = model?.parentID.id ?? "0"
                budget.uuid = nil
                budget.action = .edit
                
                budget.tag?.id = model?.childIDs.first?.id ?? "0"
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
                AppState.shared.showAlert("There was a problem trying to save the budget.")
            }
            
            /// End the background task.
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
            #endif
        }
    }
    
    
    func delete(_ budget: CBBudgetItem, andSubmit: Bool) {
        budget.action = .delete
        withAnimation {
            //print(budget.id)
            budgets.removeAll { $0.id == budget.id }
        }
        
        if andSubmit {
            Task { @MainActor in
                let _ = await submit(budget)
            }
        }
    }
    
    
    @MainActor
    func submit(_ budgetForMonth: CBMonth) async {
        print("-- \(#function)")
        
        /// Allow more time to save if the user enters the background.
        #if os(iOS)
        var backgroundTaskId = AppState.shared.beginBackgroundTask()
        #endif
        
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        //print("\(budget.action.serverKey.capitalized) BUDGET!")
        let model = RequestModel(requestType: "edit_cb_month_budget", model: budgetForMonth)
            
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch result {
        case .success(let model):
            LogManager.networkingSuccessful()
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
                AppState.shared.showAlert("There was a problem trying to save the budget.")
            }
            
            /// End the background task.
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
            #endif
        }
    }
    
    
    @MainActor
    func submit(_ globalBudget: CBBudget) async {
        print("-- \(#function)")
        
        /// Allow more time to save if the user enters the background.
        #if os(iOS)
        var backgroundTaskId = AppState.shared.beginBackgroundTask()
        #endif
        
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        //print("\(budget.action.serverKey.capitalized) BUDGET!")
        let model = RequestModel(requestType: "edit_cb_global_budget", model: globalBudget)
            
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch result {
        case .success(let model):
            LogManager.networkingSuccessful()
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
                AppState.shared.showAlert("There was a problem trying to save the budget.")
            }
            
            /// End the background task.
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
            #endif
        }
    }
}




























//    var budgetEditID: Int?
//    var budgets: Array<CBBudgetItem> = []
//    //var refreshTask: Task<Void, Error>?
//    var fuckYouSwiftuiTableRefreshID: UUID = UUID()
//    
//    func getBudget(by id: Int) -> CBBudgetItem {
//        return budgets.filter { $0.id == id }.first ?? CBBudgetItem.empty
//    }
//    
//    func upsert(_ budget: CBBudgetItem) {
//        func isExisting(_ budget: CBBudgetItem) -> Bool {
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
//        var preTaskSnapshot: Array<CBBudgetItem> = []
//        budgets.forEach {
//            $0.deepCopy(.create)
//            preTaskSnapshot.append($0.deepCopy ?? .empty)
//        }
//        
//        /// Do networking.
//        let model = RequestModel(requestType: "fetch_repeating_transactions", model: AppState.shared.user)
//        typealias ResultResponse = Result<Array<CBBudgetItem>?, AppError>
//        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
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
//                    var postTaskSnapshot: Array<CBBudgetItem> = []
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
//    func submit(_ budget: CBBudgetItem) async {
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
//    func delete(_ budget: CBBudgetItem) async {
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
