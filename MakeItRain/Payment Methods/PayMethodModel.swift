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
    static let shared = PayMethodModel()
    var isThinking = false
    
    //var paymentMethodEditID: Int?
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
        print("-- \(#function)")
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
                                                
        if payMethod.hasChanges() {
            print("Account has changes")
            payMethod.updatedBy = AppState.shared.user!
            payMethod.updatedDate = Date()
            
            /// Update transactions.
            calModel.justTransactions
                .filter { $0.payMethod?.id == payMethod.id }
                .forEach { $0.payMethod?.setFromAnotherInstance(payMethod: payMethod) }
            
            /// Update Starting amounts.
            calModel.months
                .flatMap { $0.startingAmounts }
                .filter { $0.payMethod.id == payMethod.id }
                .forEach { $0.payMethod.setFromAnotherInstance(payMethod: payMethod) }
            Task {
                await submit(payMethod)
            }
        } else {
            print("No Changes")
        }
    }
    
    func updateCache(for payMethod: CBPaymentMethod) async -> Result<Bool, CoreDataError> {
        let context = DataManager.shared.createContext()
        return await context.perform {
            /// Create this if not found because if a method gets marked as private from another device after this one has already cached it, it will get deleted from the cache by the long poll.
            if let entity = DataManager.shared.getOne(context: context, type: PersistentPaymentMethod.self, predicate: .byId(.string(payMethod.id)), createIfNotFound: true) {
                entity.id = payMethod.id
                entity.title = payMethod.title
                entity.dueDate = Int64(payMethod.dueDate ?? 0)
                entity.limit = payMethod.limit ?? 0.0
                entity.accountType = Int64(payMethod.accountType.rawValue)
                entity.hexCode = payMethod.color.toHex()
                //entity.hexCode = payMethod.color.description
                entity.isViewingDefault = payMethod.isViewingDefault
                entity.notificationOffset = Int64(payMethod.notificationOffset ?? 0)
                entity.notifyOnDueDate = payMethod.notifyOnDueDate
                entity.last4 = payMethod.last4
                entity.interestRate = payMethod.interestRate ?? 0
                entity.loanDuration = Int64(payMethod.loanDuration ?? 0)
                entity.isHidden = payMethod.isHidden
                entity.isPrivate = payMethod.isPrivate
                entity.action = "edit"
                entity.isPending = false
                return DataManager.shared.save(context: context)
            } else {
                return .failure(.notFound)
            }
        }
    }
    
    
    @MainActor
    func fetchPaymentMethods(calModel: CalendarModel) async {
        print("-- \(#function)")
        LogManager.log()
        
        let start = CFAbsoluteTimeGetCurrent()
        
        /// Do networking.
        let model = RequestModel(requestType: "fetch_payment_methods", model: AppState.shared.user)
        typealias ResultResponse = Result<Array<CBPaymentMethod>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            
            /// For testing bad network connection.
            //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
            
            let context = DataManager.shared.createContext()
            
            LogManager.networkingSuccessful()
            if let model {
                if !model.isEmpty {
                    var activeIds: Array<String> = []
                    for payMethod in model {
                        activeIds.append(payMethod.id)
                        
                        if calModel.sPayMethod == nil && payMethod.isViewingDefault {
                            calModel.sPayMethod = payMethod
                        }
                        
                        let index = paymentMethods.firstIndex(where: { $0.id == payMethod.id })
                        if let index {
                            /// If the payment method is already in the list, update it from the server.
                            paymentMethods[index].setFromAnotherInstance(payMethod: payMethod)
                        } else {
                            /// Add the payment method to the list (like when the payment method was added on another device).
                            paymentMethods.append(payMethod)
                        }
                        
                        /// Find the payment method in cache.
                        await context.perform {
                            /// Update the cache and add to model (if appolicable).
                            /// This should always be true because the line above creates the entity if it's not found.
                            if let entity = DataManager.shared.getOne(context: context, type: PersistentPaymentMethod.self, predicate: .byId(.string(payMethod.id)), createIfNotFound: true) {
                                entity.id = payMethod.id
                                entity.title = payMethod.title
                                entity.dueDate = Int64(payMethod.dueDate ?? 0)
                                entity.limit = payMethod.limit ?? 0.0
                                entity.accountType = Int64(payMethod.accountType.rawValue)
                                entity.hexCode = payMethod.color.toHex()
                                //entity.hexCode = payMethod.color.description
                                entity.isViewingDefault = payMethod.isViewingDefault
                                entity.notificationOffset = Int64(payMethod.notificationOffset ?? 0)
                                entity.notifyOnDueDate = payMethod.notifyOnDueDate
                                entity.last4 = payMethod.last4
                                entity.interestRate = payMethod.interestRate ?? 0
                                entity.loanDuration = Int64(payMethod.loanDuration ?? 0)
                                entity.isHidden = payMethod.isHidden
                                entity.isPrivate = payMethod.isPrivate
                                entity.action = "edit"
                                entity.isPending = false
                                
                                let _ = DataManager.shared.save(context: context)
                            }
                        }
                    }
                    
                    /// Delete from cache and model.
                    for payMethod in paymentMethods {
                        if !activeIds.contains(payMethod.id) {
                            paymentMethods.removeAll { $0.id == payMethod.id }
                            /// Does so in its own perform block.
                            DataManager.shared.delete(context: context, type: PersistentPaymentMethod.self, predicate: .byId(.string(payMethod.id)))
                        }
                    }
                } else {
                    paymentMethods.removeAll()
                }
            }
            
            /// Update the progress indicator.
            AppState.shared.downloadedData.append(.paymentMethods)
            
            let currentElapsed = CFAbsoluteTimeGetCurrent() - start
            print("⏰It took \(currentElapsed) seconds to fetch the payment methods")
            
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
        print("-- \(#function)")
        isThinking = true
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
                
        let context = DataManager.shared.createContext()
        await context.perform {
            if let entity = DataManager.shared.getOne(context: context, type: PersistentPaymentMethod.self, predicate: .byId(.string(payMethod.id)), createIfNotFound: true) {
                entity.id = payMethod.id
                entity.title = payMethod.title
                entity.dueDate = Int64(payMethod.dueDate ?? 0)
                entity.limit = payMethod.limit ?? 0.0
                entity.accountType = Int64(payMethod.accountType.rawValue)
                entity.hexCode = payMethod.color.toHex()
                //entity.hexCode = payMethod.color.description
                entity.isViewingDefault = payMethod.isViewingDefault
                entity.notificationOffset = Int64(payMethod.notificationOffset ?? 0)
                entity.notifyOnDueDate = payMethod.notifyOnDueDate
                entity.last4 = payMethod.last4
                entity.interestRate = payMethod.interestRate ?? 0
                entity.loanDuration = Int64(payMethod.loanDuration ?? 0)
                entity.action = payMethod.action.rawValue
                entity.isHidden = payMethod.isHidden
                entity.isPrivate = payMethod.isPrivate
                entity.isPending = true
                let _ = DataManager.shared.save(context: context)
            }
        }
        
        let model = RequestModel(requestType: payMethod.action.serverKey, model: payMethod)
            
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        typealias ResultResponse = Result<ReturnIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
                        
            if payMethod.action != .delete {
                await context.perform {
                    if let entity = DataManager.shared.getOne(context: context, type: PersistentPaymentMethod.self, predicate: .byId(.string(payMethod.id)), createIfNotFound: true) {
                        /// If adding a new pay method, update core data with the server ID by finding it via the UUID.
                        if payMethod.action == .add {
                            entity.id = model?.id ?? String(0)
                            entity.action = "edit"
                        }
                        entity.isPending = false
                        let _ = DataManager.shared.save(context: context)
                    }
                }
                
                /// Get the new ID from the server after adding a new activity.
                if payMethod.action == .add {
                    payMethod.id = model?.id ?? String(0)
                    payMethod.uuid = nil
                    payMethod.action = .edit
                }
                
            } else {
                /// Does so in its own perform block.
                DataManager.shared.delete(context: context, type: PersistentPaymentMethod.self, predicate: .byId(.string(payMethod.id)))
            }
            
            print("✅Payment method successfully saved")
            
            isThinking = false
            payMethod.action = .edit
            #if os(macOS)
            fuckYouSwiftuiTableRefreshID = UUID()
            #endif
            return true
                                                
        case .failure(let error):
            print("❌Payment method failed to save")
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
    
    
    func delete(_ payMethod: CBPaymentMethod, andSubmit: Bool, calModel: CalendarModel, eventModel: EventModel) async {
        print("-- \(#function)")
        print(payMethod.id)
        print(paymentMethods.map {$0.id})
        
        let context = DataManager.shared.createContext()
        
        payMethod.action = .delete
        paymentMethods.removeAll { $0.id == payMethod.id }
        
        calModel.months.forEach { month in
            month.days.forEach { day in
                day.transactions.removeAll(where: { $0.payMethod?.id == payMethod.id })
            }
        }
        
        eventModel.events.forEach { event in
            event.transactions.removeAll(where: { $0.payMethod?.id == payMethod.id })
        }
        
        if andSubmit {
            let _ = await submit(payMethod)
        } else {
            DataManager.shared.delete(context: context, type: PersistentPaymentMethod.self, predicate: .byId(.string(payMethod.id)))
        }
    }
    
    
    func deleteAll() async {
        let context = DataManager.shared.createContext()
        for meth in paymentMethods {
            meth.action = .delete
            let _ = await submit(meth)
        }
        
        let _ = DataManager.shared.deleteAll(context: context, for: PersistentPaymentMethod.self)
        let _ = DataManager.shared.save(context: context)
        //print("SaveResult: \(saveResult)")
        paymentMethods.removeAll()
    }
    
    
    
    
    @MainActor
    func setDefaultViewing(_ payMethod: CBPaymentMethod) async {
        print("-- \(#function)")
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
                                
        paymentMethods = paymentMethods.map({
            let optionItem = $0
            $0.isViewingDefault = $0.id == payMethod.id
            return optionItem
        })
        
        let context = DataManager.shared.createContext()
        await context.perform {
            for method in self.paymentMethods {
                if let entity = DataManager.shared.getOne(context: context, type: PersistentPaymentMethod.self, predicate: .byId(.string(method.id)), createIfNotFound: true) {
                    entity.isViewingDefault = method.isViewingDefault
                }
            }
            
            let _ = DataManager.shared.save(context: context)
        }
      
        /// Networking
        let model = RequestModel(requestType: "set_default_viewing_payment_method", model: payMethod)
        
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success:
            LogManager.networkingSuccessful()

        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to set the default payment method.")
            //showSaveAlert = true
            #warning("Undo behavior")
        }
        //LoadingManager.shared.stopDelayedSpinner()
    }
    
    
    @MainActor
    func setDefaultEditing(_ payMethod: CBPaymentMethod) async {
        print("-- \(#function)")
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
                                
        paymentMethods = paymentMethods.map({
            let optionItem = $0
            $0.isEditingDefault = $0.id == payMethod.id
            return optionItem
        })
        
        
        let context = DataManager.shared.createContext()
        await context.perform {
            for method in self.paymentMethods {
                if let entity = DataManager.shared.getOne(context: context, type: PersistentPaymentMethod.self, predicate: .byId(.string(method.id)), createIfNotFound: true) {
                    entity.isEditingDefault = method.isEditingDefault
                }
            }
            
            let _ = DataManager.shared.save(context: context)
        }
        
        
        
      
        /// Networking
        let model = RequestModel(requestType: "set_default_editing_payment_method", model: payMethod)
        
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success:
            LogManager.networkingSuccessful()

        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to set the default payment method.")
            //showSaveAlert = true
            #warning("Undo behavior")
        }
        //LoadingManager.shared.stopDelayedSpinner()
    }
    
    
    
    
    @MainActor
    func fetchStartingAmountsForDateRange(_ analModel: AnalysisRequestModel) async -> Array<CBStartingAmount>? {
        print("-- \(#function)")
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
      
        /// Networking
        let model = RequestModel(requestType: "fetch_starting_amounts_for_date_range", model: analModel)
        
        typealias ResultResponse = Result<Array<CBStartingAmount>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            return model

        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to fetch analytics.")
            return nil
            //showSaveAlert = true
            #warning("Undo behavior")
        }
        //LoadingManager.shared.stopDelayedSpinner()
    }
    
    
    @MainActor
    func fetchStartingAmountsForDateRange2(_ analModel: AnalysisRequestModel) async -> Array<CBPaymentMethod>? {
        print("-- \(#function)")
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
      
        /// Networking
        let model = RequestModel(requestType: "fetch_starting_amounts_for_date_range2", model: analModel)
        
        typealias ResultResponse = Result<Array<CBPaymentMethod>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            return model

        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to fetch analytics.")
            return nil
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
                //NavigationManager.shared.navPath = []
                NavigationManager.shared.selection = nil
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
