//
//  PaymentMethodModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/20/24.
//

import Foundation

@MainActor
@Observable
class PayMethodModel {
    var isThinking = false
    
    var paymentMethodEditID: Int?
    var paymentMethods: Array<CBPaymentMethod> = []
    //var refreshTask: Task<Void, Error>?
    var fuckYouSwiftuiTableRefreshID: UUID = UUID()
    
    func doesExist(_ payMethod: CBPaymentMethod) -> Bool {
        return !paymentMethods.filter { $0.id == payMethod.id }.isEmpty
    }
    
    func getPaymentMethod(by id: String) -> CBPaymentMethod {
        return paymentMethods.filter { $0.id == id }.first ?? CBPaymentMethod(uuid: id)
    }
    
    func upsert(_ payMethod: CBPaymentMethod) {
        if !doesExist(payMethod) {
            paymentMethods.append(payMethod)
        }
    }
    
    func getIndex(for payMethod: CBPaymentMethod) -> Int? {
        return paymentMethods.firstIndex(where: { $0.id == payMethod.id })
    }
    
    func savePaymentMethod(id: String, calModel: CalendarModel) {
        let payMethod = getPaymentMethod(by: id)
        if payMethod.title.isEmpty {
            if payMethod.action != .add && payMethod.title.isEmpty {
                payMethod.title = payMethod.deepCopy?.title ?? ""
                AppState.shared.showAlert("Removing a title is not allowed. If you want to delete \(payMethod.title), please use the delete button instead.")
            } else {
                paymentMethods.removeAll { $0.id == id }
            }
            return
        }
                                                
//                    payModel.upsert(payMethod)
        if payMethod.hasChanges() {
            
            calModel.justTransactions.filter { $0.payMethod?.id == payMethod.id }.forEach {
                $0.payMethod?.color = payMethod.color
            }
            
//            
//            calModel.months.forEach { month in
//                month.days.forEach { day in
//                    day.transactions.forEach { trans in
//                        if trans.payMethod?.id == payMethod.id {
//                            trans.payMethod?.color = payMethod.color
//                        }
//                    }
//                }
//            }
        }
        Task {
            await submit(payMethod)
        }
    }
    
    func updateCache(for payMethod: CBPaymentMethod) -> Result<Bool, CoreDataError> {
        guard let entity = DataManager.shared.getOne(type: PersistentPaymentMethod.self, predicate: .byId(.string(payMethod.id)), createIfNotFound: false) else { return .failure(.reason("notFound")) }
        
        entity.id = payMethod.id
        entity.title = payMethod.title
        entity.dueDate = Int64(payMethod.dueDate ?? 0)
        entity.limit = payMethod.limit ?? 0.0
        entity.accountType = payMethod.accountType.rawValue
        entity.hexCode = payMethod.color.toHex()
        //entity.hexCode = payMethod.color.description
        entity.isDefault = payMethod.isDefault
        entity.notificationOffset = Int64(payMethod.notificationOffset ?? 0)
        entity.notifyOnDueDate = payMethod.notifyOnDueDate
        entity.last4 = payMethod.last4
        entity.action = "edit"
        entity.isPending = false
                                                        
        let saveResult = DataManager.shared.save()
        return saveResult
    }
    
    
    @MainActor
    func fetchPaymentMethods(calModel: CalendarModel) async {
        print("-- \(#function)")
        LogManager.log()
        
        /// Do networking.
        let model = RequestModel(requestType: "fetch_payment_methods", model: AppState.shared.user)
        typealias ResultResponse = Result<Array<CBPaymentMethod>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            
            /// For testing bad network connection.
            //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))

            LogManager.networkingSuccessful()
            if let model {
                if !model.isEmpty {
                    var activeIds: Array<String> = []
                    for payMethod in model {
                        activeIds.append(payMethod.id)
                        
                        if calModel.sPayMethod == nil && payMethod.isDefault {
                            calModel.sPayMethod = payMethod
                        }
                        
                        /// Find the payment method in cache.
                        let entity = DataManager.shared.getOne(type: PersistentPaymentMethod.self, predicate: .byId(.string(payMethod.id)), createIfNotFound: true)
                        
                        /// Update the cache and add to model (if appolicable).
                        /// This should always be true because the line above creates the entity if it's not found.
                        if let entity {
                            entity.id = payMethod.id
                            entity.title = payMethod.title
                            entity.dueDate = Int64(payMethod.dueDate ?? 0)
                            entity.limit = payMethod.limit ?? 0.0
                            entity.accountType = payMethod.accountType.rawValue
                            entity.hexCode = payMethod.color.toHex()
                            //entity.hexCode = payMethod.color.description
                            entity.isDefault = payMethod.isDefault
                            entity.notificationOffset = Int64(payMethod.notificationOffset ?? 0)
                            entity.notifyOnDueDate = payMethod.notifyOnDueDate
                            entity.last4 = payMethod.last4
                            entity.action = "edit"
                            entity.isPending = false
                            
                            let index = paymentMethods.firstIndex(where: { $0.id == payMethod.id })
                            if let index {
                                /// If the payment method is already in the list, update it from the server.
                                paymentMethods[index].setFromAnotherInstance(payMethod: payMethod)
                            } else {
                                /// Add the payment method to the list (like when the payment method was added on another device).
                                paymentMethods.append(payMethod)
                            }
                        }
                    }
                    
                    /// Delete from cache and model.
                    for payMethod in paymentMethods {
                        if !activeIds.contains(payMethod.id) {
                            paymentMethods.removeAll { $0.id == payMethod.id }
                            let _ = DataManager.shared.delete(type: PersistentPaymentMethod.self, predicate: .byId(.string(payMethod.id)))
                        }
                    }
            
                    /// Save the cache.
                    let _ = DataManager.shared.save()
                }
            }
            
            /// Update the progress indicator.
            AppState.shared.downloadedData.append(.paymentMethods)
            
        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("payModel fetchFrom Server Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch the payment methods.")
            }
        }
    }
    
    
    @MainActor
    func submit(_ payMethod: CBPaymentMethod) async -> Bool {
        isThinking = true
        //LoadingManager.shared.startDelayedSpinner()
                
        guard let entity = DataManager.shared.getOne(type: PersistentPaymentMethod.self, predicate: .byId(.string(payMethod.id)), createIfNotFound: true) else { return false }
        entity.id = payMethod.id
        entity.title = payMethod.title
        entity.dueDate = Int64(payMethod.dueDate ?? 0)
        entity.limit = payMethod.limit ?? 0.0
        entity.accountType = payMethod.accountType.rawValue
        entity.hexCode = payMethod.color.toHex()
        //entity.hexCode = payMethod.color.description
        entity.isDefault = payMethod.isDefault
        entity.notificationOffset = Int64(payMethod.notificationOffset ?? 0)
        entity.notifyOnDueDate = payMethod.notifyOnDueDate
        entity.last4 = payMethod.last4
        entity.action = payMethod.action.rawValue
        entity.isPending = true
                                                        
        let _ = DataManager.shared.save()
        
        
        print(payMethod.action)
        print(entity.id)
        
        
        LogManager.log()
        let model = RequestModel(requestType: payMethod.action.serverKey, model: payMethod)
            
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        typealias ResultResponse = Result<ReturnIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            /// Get the new ID from the server after adding a new activity.
            if payMethod.action != .delete {
                guard let entity = DataManager.shared.getOne(type: PersistentPaymentMethod.self, predicate: .byId(.string(payMethod.id)), createIfNotFound: true) else { return false }
                
                if payMethod.action == .add {
                    
                    payMethod.id = model?.id ?? "0"
                    payMethod.uuid = nil
                    payMethod.action = .edit
                    entity.id = model?.id ?? "0"
                    entity.action = "edit"
                }
                            
                entity.isPending = false
                let _ = DataManager.shared.save()
            } else {
                let saveResult = DataManager.shared.delete(type: PersistentPaymentMethod.self, predicate: .byId(.string(payMethod.id)))
            }
            
            isThinking = false
            payMethod.action = .edit
            #if os(macOS)
            fuckYouSwiftuiTableRefreshID = UUID()
            #endif
            return true
                                                
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem syncing the payment method. Will try again at a later time.")
//            payMethod.deepCopy(.restore)
//            
//            switch payMethod.action {
//            case .add: paymentMethods.removeAll { $0.id == payMethod.id }
//            case .edit: break
//            case .delete: paymentMethods.append(payMethod)
//            }
            
            isThinking = false
            payMethod.action = .edit
            #if os(macOS)
            fuckYouSwiftuiTableRefreshID = UUID()
            #endif
            return false
        }
        
        
    }
    
    
    func delete(_ payMethod: CBPaymentMethod, andSubmit: Bool, calModel: CalendarModel) async {
        print("-- \(#function)")
        print(payMethod.id)
        print(paymentMethods.map {$0.id})
        
        payMethod.action = .delete
        paymentMethods.removeAll { $0.id == payMethod.id }
        
        calModel.months.forEach { month in
            month.days.forEach { day in
                day.transactions.removeAll(where: { $0.payMethod?.id == payMethod.id })
            }
        }
        
        if andSubmit {
            let _ = await submit(payMethod)
        } else {
            let _ = DataManager.shared.delete(type: PersistentPaymentMethod.self, predicate: .byId(.string(payMethod.id)))
        }
    }
    
    
    func deleteAll() async {
        for meth in paymentMethods {
            meth.action = .delete
            let _ = await submit(meth)
        }
        
        let saveResult = DataManager.shared.deleteAll(for: PersistentPaymentMethod.self)
        //print("SaveResult: \(saveResult)")
        paymentMethods.removeAll()
    }
    
    
    
    
    @MainActor
    func setDefault(_ payMethod: CBPaymentMethod) async {
        print("-- \(#function)")
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
                                
        paymentMethods = paymentMethods.map({
            let optionItem = $0
            $0.isDefault = $0.id == payMethod.id
            return optionItem
        })
        
        paymentMethods.forEach {
            if let entity = DataManager.shared.getOne(type: PersistentPaymentMethod.self, predicate: .byId(.string($0.id)), createIfNotFound: true) {
                entity.isDefault = $0.isDefault
            }
        }
        
        let _ = DataManager.shared.save()
      
        /// Networking
        let model = RequestModel(requestType: "set_default_payment_method", model: payMethod)
        
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()

        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to set the default payment method.")
            //showSaveAlert = true
            #warning("Undo behavior")
        }
        //LoadingManager.shared.stopDelayedSpinner()
    }
    
    
    func determineIfUserIsRequiredToAddPaymentMethod() {
        print("-- \(#function)")
        /// If you close the payment method edit page, and the data is not valid, hide all the other views.
        if AppState.shared.methsExist
        && paymentMethods.filter({ !$0.isUnified }).isEmpty {
            AppState.shared.methsExist = false
            AppState.shared.showPaymentMethodNeededSheet = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                #if os(iOS)
                NavigationManager.shared.navPath = []
                #else
                NavigationManager.shared.selection = nil
                #endif
            })
            
        } else {
            /// If you close the payment method edit page, and the data was valid, show all the other views.
            if !AppState.shared.methsExist
            && !paymentMethods.filter({ !$0.isUnified }).isEmpty {
                AppState.shared.methsExist = true
            }
        }
    }
}
