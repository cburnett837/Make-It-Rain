//
//  PaymentMethodModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/20/24.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class PayMethodModel {
    static let shared = PayMethodModel()
    var isThinking = false
    
    //var paymentMethodEditID: Int?
    var paymentMethods: Array<CBPaymentMethod> = []
    //var refreshTask: Task<Void, Error>?
    var fuckYouSwiftuiTableRefreshID: UUID = UUID()
    
    
    var sections: Array<PaySection> = []
    
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
    
    var editingDefaultAccountType: AccountType? {
        paymentMethods.filter({ $0.isEditingDefault }).first?.accountType
    }
    
    func getEditingDefault() -> CBPaymentMethod? {
        paymentMethods.filter({ $0.isEditingDefault }).first
    }
    
    
    @discardableResult
    func savePaymentMethod(id: String, calModel: CalendarModel, plaidModel: PlaidModel) -> Bool {
        let payMethod = getPaymentMethod(by: id)
        payMethod.viewingYear = calModel.sYear
        
        if payMethod.action == .delete {
            payMethod.updatedBy = AppState.shared.user!
            payMethod.updatedDate = Date()
            delete(payMethod, andSubmit: true, calModel: calModel)
            return true
        }
        
        if payMethod.title.isEmpty {
            /// User blanked out the title of an existing payment method.
            if payMethod.action == .edit {
                payMethod.title = payMethod.deepCopy?.title ?? ""
                AppState.shared.showAlert("Removing a title is not allowed. If you want to delete \(payMethod.title), please use the delete button instead.")
            } else {
                /// Remove the dud that is in `.add` mode since it's being upserted into the list on creation.
                withAnimation { paymentMethods.removeAll { $0.id == id } }
            }
            return false
        }
                                                
        if payMethod.hasChanges() {
            payMethod.updatedBy = AppState.shared.user!
            payMethod.updatedDate = Date()
            
            if payMethod.action == .add {
                payMethod.listOrder = paymentMethods.count + 1
            }
            
            /// Update transactions.
            calModel.justTransactions
                .filter { $0.payMethod?.id == payMethod.id }
                .forEach { $0.payMethod?.setFromAnotherInstance(payMethod: payMethod) }
            
            /// Update plaid transactions.
            plaidModel.trans
                .filter { $0.payMethod?.id == payMethod.id }
                .forEach { $0.payMethod?.setFromAnotherInstance(payMethod: payMethod) }
            
            /// Update starting amounts.
            calModel.months
                .flatMap { $0.startingAmounts }
                .filter { $0.payMethod.id == payMethod.id }
                .forEach { $0.payMethod.setFromAnotherInstance(payMethod: payMethod) }
            Task {
                await submit(payMethod)
            }
            return true
        } else {
            print("No Changes")
            return false
        }
    }
    
    
    func updateCache(for payMethod: CBPaymentMethod) async -> Result<Bool, CoreDataError> {
        
        let id = payMethod.id
        let title = payMethod.title
        let dueDate = Int64(payMethod.dueDate ?? 0)
        let limit = payMethod.limit ?? 0.0
        let accountType = Int64(payMethod.accountType.rawValue)
        let hexCode = payMethod.color.toHex()
        let isViewingDefault = payMethod.isViewingDefault
        let notificationOffset = Int64(payMethod.notificationOffset ?? 0)
        let notifyOnDueDate = payMethod.notifyOnDueDate
        let last4 = payMethod.last4
        let interestRate = payMethod.interestRate ?? 0
        let loanDuration = Int64(payMethod.loanDuration ?? 0)
        let isHidden = payMethod.isHidden
        let isPrivate = payMethod.isPrivate
        let logo = payMethod.logo
        //let action = "edit"
        //let isPending = false
        let enteredByID = Int64(payMethod.enteredBy.id)
        let updatedByID = Int64(payMethod.updatedBy.id)
        let enteredDate = payMethod.enteredDate
        let updatedDate = payMethod.updatedDate
        let listOrder = Int64(payMethod.listOrder ?? 0)
        
        let holderOneID = Int64(payMethod.holderOne?.id ?? 0)
        let holderTwoID = Int64(payMethod.holderTwo?.id ?? 0)
        let holderThreeID = Int64(payMethod.holderThree?.id ?? 0)
        let holderFourID = Int64(payMethod.holderFour?.id ?? 0)
        
        let holderOneTypeID = Int64(payMethod.holderOneType?.id ?? 0)
        let holderTwoTypeID = Int64(payMethod.holderTwoType?.id ?? 0)
        let holderThreeTypeID = Int64(payMethod.holderThreeType?.id ?? 0)
        let holderFourTypeID = Int64(payMethod.holderFourType?.id ?? 0)
        
        
        
        let context = DataManager.shared.createContext()
        return await context.perform {
            /// Create this if not found because if a method gets marked as private from another device after this one has already cached it, it will get deleted from the cache by the long poll.
            if let entity = DataManager.shared.getOne(
                context: context,
                type: PersistentPaymentMethod.self,
                predicate: .byId(.string(id)),
                createIfNotFound: true
            ) {
                entity.id = id
                entity.title = title
                entity.dueDate = dueDate
                entity.limit = limit
                entity.accountType = accountType
                entity.hexCode = hexCode
                //entity.hexCode = payMethod.color.description
                entity.isViewingDefault = isViewingDefault
                entity.notificationOffset = notificationOffset
                entity.notifyOnDueDate = notifyOnDueDate
                entity.last4 = last4
                entity.interestRate = interestRate
                entity.loanDuration = loanDuration
                entity.isHidden = isHidden
                entity.isPrivate = isPrivate
                entity.action = "edit"
                entity.isPending = false
//                entity.logo?.photoData = logo
//                entity.logo?.localUpdatedDate = Date()
                entity.enteredByID = enteredByID
                entity.updatedByID = updatedByID
                entity.enteredDate = enteredDate
                entity.updatedDate = updatedDate
                
                entity.listOrder = listOrder
                
                entity.holderOneID = holderOneID
                entity.holderTwoID = holderTwoID
                entity.holderThreeID = holderThreeID
                entity.holderFourID = holderFourID
                entity.holderOneTypeID = holderOneTypeID
                entity.holderTwoTypeID = holderTwoTypeID
                entity.holderThreeTypeID = holderThreeTypeID
                entity.holderFourTypeID = holderFourTypeID
                
                
                let pred1 = NSPredicate(format: "relatedID == %@", id)
                let pred2 = NSPredicate(format: "relatedTypeID == %@", NSNumber(value: XrefModel.getItem(from: .logoTypes, byEnumID: .paymentMethod).id))
                let comp = NSCompoundPredicate(andPredicateWithSubpredicates: [pred1, pred2])
                
                if let perLogo = DataManager.shared.getOne(
                    context: context,
                    type: PersistentLogo.self,
                    predicate: .compound(comp),
                    createIfNotFound: true
                ) {
                    perLogo.photoData = logo
                    perLogo.localUpdatedDate = Date()
                }
                
                
                return DataManager.shared.save(context: context)
            } else {
                return .failure(.notFound)
            }
        }
    }
    
    
    @MainActor
    func fetchPaymentMethods(calModel: CalendarModel) async {
        //print("-- \(#function)")
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
                        
                        let id = payMethod.id
                        let title = payMethod.title
                        let dueDate = Int64(payMethod.dueDate ?? 0)
                        let limit = payMethod.limit ?? 0.0
                        let accountType = Int64(payMethod.accountType.rawValue)
                        let hexCode = payMethod.color.toHex()
                        let isViewingDefault = payMethod.isViewingDefault
                        let isEditingDefault = payMethod.isEditingDefault
                        let notificationOffset = Int64(payMethod.notificationOffset ?? 0)
                        let notifyOnDueDate = payMethod.notifyOnDueDate
                        let last4 = payMethod.last4
                        let interestRate = payMethod.interestRate ?? 0
                        let loanDuration = Int64(payMethod.loanDuration ?? 0)
                        let isHidden = payMethod.isHidden
                        let isPrivate = payMethod.isPrivate
                        //let logo = payMethod.logo
                        //let action = "edit"
                        //let isPending = false
                        let enteredByID = Int64(payMethod.enteredBy.id)
                        let updatedByID = Int64(payMethod.updatedBy.id)
                        let enteredDate = payMethod.enteredDate
                        let updatedDate = payMethod.updatedDate
                        let listOrder = Int64(payMethod.listOrder ?? 0)
                        
                        let holderOneID = Int64(payMethod.holderOne?.id ?? 0)
                        let holderTwoID = Int64(payMethod.holderTwo?.id ?? 0)
                        let holderThreeID = Int64(payMethod.holderThree?.id ?? 0)
                        let holderFourID = Int64(payMethod.holderFour?.id ?? 0)
                        
                        let holderOneTypeID = Int64(payMethod.holderOneType?.id ?? 0)
                        let holderTwoTypeID = Int64(payMethod.holderTwoType?.id ?? 0)
                        let holderThreeTypeID = Int64(payMethod.holderThreeType?.id ?? 0)
                        let holderFourTypeID = Int64(payMethod.holderFourType?.id ?? 0)
                                                                                                
//                        if calModel.sPayMethod == nil && payMethod.isViewingDefault {
//                            calModel.sPayMethod = payMethod
//                        }
                        
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
                            if let entity = DataManager.shared.getOne(
                                context: context,
                                type: PersistentPaymentMethod.self,
                                predicate: .byId(.string(id)),
                                createIfNotFound: true
                            ) {
                                entity.id = id
                                entity.title = title
                                entity.dueDate = dueDate
                                entity.limit = limit
                                entity.accountType = accountType
                                entity.hexCode = hexCode
                                //entity.hexCode = payMethod.color.description
                                entity.isEditingDefault = isEditingDefault
                                entity.isViewingDefault = isViewingDefault
                                entity.notificationOffset = notificationOffset
                                entity.notifyOnDueDate = notifyOnDueDate
                                entity.last4 = last4
                                entity.interestRate = interestRate
                                entity.loanDuration = loanDuration
                                entity.isHidden = isHidden
                                entity.isPrivate = isPrivate
                                entity.action = "edit"
                                entity.isPending = false
                                //entity.logo?.photoData = logo
//                                entity.logo?.localUpdatedDate = Date()
                                entity.enteredByID = enteredByID
                                entity.updatedByID = updatedByID
                                entity.enteredDate = enteredDate
                                entity.updatedDate = updatedDate
                                
                                entity.listOrder = listOrder
                                
                                entity.holderOneID = holderOneID
                                entity.holderTwoID = holderTwoID
                                entity.holderThreeID = holderThreeID
                                entity.holderFourID = holderFourID
                                entity.holderOneTypeID = holderOneTypeID
                                entity.holderTwoTypeID = holderTwoTypeID
                                entity.holderThreeTypeID = holderThreeTypeID
                                entity.holderFourTypeID = holderFourTypeID
                                
                                let _ = DataManager.shared.save(context: context)
                            }
                        }
                    }
                    
                    /// Delete from cache and model.
                    for payMethod in paymentMethods {
                        if !activeIds.contains(payMethod.id) {
                            paymentMethods.removeAll { $0.id == payMethod.id }
                            /// Does so in its own perform block.
                            DataManager.shared.delete(
                                context: context,
                                type: PersistentPaymentMethod.self,
                                predicate: .byId(.string(payMethod.id))
                            )
                        }
                    }
                } else {
                    paymentMethods.removeAll()
                }
            }
            
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
                
        /// Allow more time to save if the user enters the background.
        #if os(iOS)
        var backgroundTaskId = AppState.shared.beginBackgroundTask()
        #endif
        
        isThinking = true
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        
        let id = payMethod.id
        let title = payMethod.title
        let dueDate = Int64(payMethod.dueDate ?? 0)
        let limit = payMethod.limit ?? 0.0
        let accountType = Int64(payMethod.accountType.rawValue)
        let hexCode = payMethod.color.toHex()
        let isViewingDefault = payMethod.isViewingDefault
        let notificationOffset = Int64(payMethod.notificationOffset ?? 0)
        let notifyOnDueDate = payMethod.notifyOnDueDate
        let last4 = payMethod.last4
        let interestRate = payMethod.interestRate ?? 0
        let loanDuration = Int64(payMethod.loanDuration ?? 0)
        let isHidden = payMethod.isHidden
        let isPrivate = payMethod.isPrivate
        let logo = payMethod.logo
        let action = payMethod.action
        //let isPending = false
        let enteredByID = Int64(payMethod.enteredBy.id)
        let updatedByID = Int64(payMethod.updatedBy.id)
        let enteredDate = payMethod.enteredDate
        let updatedDate = payMethod.updatedDate
        
        let listOrder = Int64(payMethod.listOrder ?? 0)
        
        let holderOneID = Int64(payMethod.holderOne?.id ?? 0)
        let holderTwoID = Int64(payMethod.holderTwo?.id ?? 0)
        let holderThreeID = Int64(payMethod.holderThree?.id ?? 0)
        let holderFourID = Int64(payMethod.holderFour?.id ?? 0)
        
        let holderOneTypeID = Int64(payMethod.holderOneType?.id ?? 0)
        let holderTwoTypeID = Int64(payMethod.holderTwoType?.id ?? 0)
        let holderThreeTypeID = Int64(payMethod.holderThreeType?.id ?? 0)
        let holderFourTypeID = Int64(payMethod.holderFourType?.id ?? 0)
        
                
        let context = DataManager.shared.createContext()
        await context.perform {
            if let entity = DataManager.shared.getOne(
                context: context,
                type: PersistentPaymentMethod.self,
                predicate: .byId(.string(id)),
                createIfNotFound: true
            ) {
                entity.id = id
                entity.title = title
                entity.dueDate = dueDate
                entity.limit = limit
                entity.accountType = accountType
                entity.hexCode = hexCode
                //entity.hexCode = payMethod.color.description
                entity.isViewingDefault = isViewingDefault
                entity.notificationOffset = notificationOffset
                entity.notifyOnDueDate = notifyOnDueDate
                entity.last4 = last4
                entity.interestRate = interestRate
                entity.loanDuration = loanDuration
                entity.isHidden = isHidden
                entity.isPrivate = isPrivate
                entity.action = action.rawValue
                entity.isPending = true
                //entity.logo?.photoData = logo
                //entity.logo?.localUpdatedDate = Date()
                entity.enteredByID = enteredByID
                entity.updatedByID = updatedByID
                entity.enteredDate = enteredDate
                entity.updatedDate = updatedDate
                entity.listOrder = listOrder
                
                entity.holderOneID = holderOneID
                entity.holderTwoID = holderTwoID
                entity.holderThreeID = holderThreeID
                entity.holderFourID = holderFourID
                entity.holderOneTypeID = holderOneTypeID
                entity.holderTwoTypeID = holderTwoTypeID
                entity.holderThreeTypeID = holderThreeTypeID
                entity.holderFourTypeID = holderFourTypeID
                
                let pred1 = NSPredicate(format: "relatedID == %@", id)
                let pred2 = NSPredicate(format: "relatedTypeID == %@", NSNumber(value: XrefModel.getItem(from: .logoTypes, byEnumID: .paymentMethod).id))
                let comp = NSCompoundPredicate(andPredicateWithSubpredicates: [pred1, pred2])
                
                if let perLogo = DataManager.shared.getOne(
                    context: context,
                    type: PersistentLogo.self,
                    predicate: .compound(comp),
                    createIfNotFound: true
                ) {
                    perLogo.id = UUID().uuidString
                    perLogo.relatedID = id
                    perLogo.relatedTypeID = Int64(XrefModel.getItem(from: .logoTypes, byEnumID: .paymentMethod).id)
                    perLogo.photoData = logo
                    perLogo.localUpdatedDate = Date()
                }
                
                
                let _ = DataManager.shared.save(context: context)
            }
        }
        
        let model = RequestModel(requestType: payMethod.action.serverKey, model: payMethod)
            
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        
        typealias ResultResponse = Result<ReturnIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
                        
            let modelID = model?.id ?? String(0)
            let updatedDate = model?.updatedDate ?? Date()
            let action = payMethod.action
            
            //print("The server updated date is \(model?.updatedDate)")
            
            if payMethod.action != .delete {
                await context.perform {
                    if let entity = DataManager.shared.getOne(
                        context: context,
                        type: PersistentPaymentMethod.self,
                        predicate: .byId(.string(id)),
                        createIfNotFound: true
                    ) {
                        /// If adding a new pay method, update core data with the server ID by finding it via the UUID.
                        if action == .add {
                            entity.id = modelID
                            entity.action = "edit"
                        }
                        entity.isPending = false
                        
                        /// Update the logo with the updated date from the record.
                        let pred1 = NSPredicate(format: "relatedID == %@", action == .add ? modelID : id)
                        let pred2 = NSPredicate(format: "relatedTypeID == %@", NSNumber(value: XrefModel.getItem(from: .logoTypes, byEnumID: .paymentMethod).id))
                        let comp = NSCompoundPredicate(andPredicateWithSubpredicates: [pred1, pred2])
                        
                        if let perLogo = DataManager.shared.getOne(
                            context: context,
                            type: PersistentLogo.self,
                            predicate: .compound(comp),
                            createIfNotFound: true
                        ) {
                            perLogo.relatedID = modelID
                            perLogo.photoData = logo
                            perLogo.localUpdatedDate = updatedDate
                            perLogo.serverUpdatedDate = updatedDate
                        }
                                                                        
                        let _ = DataManager.shared.save(context: context)
                    }
                }
                
                /// Get the new ID from the server after adding a new activity.
                if action == .add {
                    payMethod.id = modelID
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
            
            /// End the background task.
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
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
            
            /// End the background task.
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
            #endif
            
            return false
        }
        
        
    }
    
    
    func delete(_ payMethod: CBPaymentMethod, andSubmit: Bool, calModel: CalendarModel) {
        payMethod.action = .delete
        withAnimation { paymentMethods.removeAll { $0.id == payMethod.id } }
        
        calModel.months.forEach { month in
            month.days.forEach { day in
                day.transactions.removeAll(where: { $0.payMethod?.id == payMethod.id })
            }
        }
        
        if andSubmit {
            Task { @MainActor in
                let _ = await submit(payMethod)
            }
        } else {
            let context = DataManager.shared.createContext()
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
        
        /// Allow more time to save if the user enters the background.
        #if os(iOS)
        var backgroundTaskId = AppState.shared.beginBackgroundTask()
        #endif
        
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
                                
        paymentMethods = paymentMethods.map({
            let optionItem = $0
            $0.isViewingDefault = $0.id == payMethod.id
            return optionItem
        })
                
        let methInfos = await MainActor.run {
            self.paymentMethods.map { (id: $0.id, isViewingDefault: $0.isViewingDefault) }
        }
        
        let context = DataManager.shared.createContext()
        await context.perform {
            for method in methInfos {
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
            
            /// End the background task.
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
            #endif

        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to set the default payment method.")
            //showSaveAlert = true
            #warning("Undo behavior")
            
            /// End the background task.
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
            #endif
        }
        //LoadingManager.shared.stopDelayedSpinner()
    }
    
    
    @MainActor
    func setDefaultEditing(_ payMethod: CBPaymentMethod) async {
        print("-- \(#function)")
        
        /// Allow more time to save if the user enters the background.
        #if os(iOS)
        var backgroundTaskId = AppState.shared.beginBackgroundTask()
        #endif
        
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
                                
        paymentMethods = paymentMethods.map({
            let optionItem = $0
            $0.isEditingDefault = $0.id == payMethod.id
            return optionItem
        })
        
        let methInfos = await MainActor.run {
            self.paymentMethods.map { (id: $0.id, isEditingDefault: $0.isEditingDefault) }
        }
        
        let context = DataManager.shared.createContext()
        await context.perform {
            for method in methInfos {
                if let entity = DataManager.shared.getOne(context: context, type: PersistentPaymentMethod.self, predicate: .byId(.string(method.id)), createIfNotFound: true) {
                    
                    print("Setting cache result of defaultEdit for \(method.id) to \(method.isEditingDefault)")
                    
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
            
            /// End the background task.
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
            #endif

        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to set the default payment method.")
            //showSaveAlert = true
            #warning("Undo behavior")
            
            /// End the background task.
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
            #endif
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
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("fetchStartingAmountsForDateRange Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch starting amounts for date range.")
            }
            return nil
            #warning("Undo behavior")
        }
    }
    
    
    @MainActor
    func fetchAnalytics(_ analModel: AnalysisRequestModel) async -> Array<CBPaymentMethod>? {
        print("-- \(#function)")
        LogManager.log()
      
        let model = RequestModel(requestType: "fetch_analytics_for_payment_method", model: analModel)
        
        typealias ResultResponse = Result<Array<CBPaymentMethod>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            return model

        case .failure(let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("fetchAnalytics Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch analytics.")
            }
            return nil
        }
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
    
    
    @MainActor
    func setListOrders(sections: Array<PaySection>, calModel: CalendarModel) async -> Array<ListOrderUpdate> {
        var updates: Array<ListOrderUpdate> = []
        var index = 0
        
        for section in sections {
            for payMethod in section.payMethods {
                print("New list order \(payMethod.title) - \(index)")
                                
                payMethod.listOrder = index
                updates.append(ListOrderUpdate(id: payMethod.id, listorder: index))
                index += 1
                
                calModel.months.forEach { month in
                    month.days.forEach { day in
                        day.transactions
                            .filter { $0.payMethod?.id == payMethod.id }
                            .forEach { $0.payMethod?.listOrder = payMethod.listOrder }
                    }
                }
            }
        }
        
        
        await persistListOrders(updates: updates)
        return updates
    }
    
    
    func persistListOrders(updates: [ListOrderUpdate]) async {
        let context = DataManager.shared.createContext()
        await context.perform {
            for update in updates {
                if let entity = DataManager.shared.getOne(context: context, type: PersistentPaymentMethod.self, predicate: .byId(.string(update.id)), createIfNotFound: false) {
                    entity.listOrder = Int64(update.listorder)
                }
            }

            let _ = DataManager.shared.save(context: context)
        }
    }
    
    
    private func getAllPayMethods(includeHidden: Bool, sText: String) -> Array<PaySection> {
        return [
            //PaySection(kind: .combined, payMethods: payModel.paymentMethods.filter { $0.accountType == .unifiedCredit || $0.accountType == .unifiedChecking }),
            PaySection(
                kind: .debit,
                payMethods: self.paymentMethods
                    .filter {
                        $0.isDebit
                        && $0.isPermitted
                        && (includeHidden ? true : !$0.isHidden)
                        && (sText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(sText))
                    }
                    .filter {
                        switch LocalStorage.shared.paymentMethodFilterMode {
                        case .all:
                            return true
                        case .justPrimary:
                            return $0.holderOne?.id == AppState.shared.user?.id
                        case .primaryAndSecondary:
                            return $0.holderOne?.id == AppState.shared.user?.id
                            || $0.holderTwo?.id == AppState.shared.user?.id
                            || $0.holderThree?.id == AppState.shared.user?.id
                            || $0.holderFour?.id == AppState.shared.user?.id
                        }
                    }
                    .sorted(by: Helpers.paymentMethodSorter())
            ),
            PaySection(
                kind: .credit,
                payMethods: self.paymentMethods
                    .filter {
                        $0.isCredit
                        && $0.isPermitted
                        && (includeHidden ? true : !$0.isHidden)
                        && (sText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(sText))
                    }
                    .filter {
                        switch LocalStorage.shared.paymentMethodFilterMode {
                        case .all:
                            return true
                        case .justPrimary:
                            return $0.holderOne?.id == AppState.shared.user?.id
                        case .primaryAndSecondary:
                            return $0.holderOne?.id == AppState.shared.user?.id
                            || $0.holderTwo?.id == AppState.shared.user?.id
                            || $0.holderThree?.id == AppState.shared.user?.id
                            || $0.holderFour?.id == AppState.shared.user?.id
                        }
                    }
                    .sorted(by: Helpers.paymentMethodSorter())
            ),
            PaySection(
                kind: .other,
                payMethods: self.paymentMethods
                    .filter {
                        !$0.isDebit
                        && !$0.isCredit
                        && $0.isPermitted
                        && (includeHidden ? true : !$0.isHidden)
                        && (sText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(sText))
                    }
                    .filter {
                        switch LocalStorage.shared.paymentMethodFilterMode {
                        case .all:
                            return true
                        case .justPrimary:
                            return $0.holderOne?.id == AppState.shared.user?.id
                        case .primaryAndSecondary:
                            return $0.holderOne?.id == AppState.shared.user?.id
                            || $0.holderTwo?.id == AppState.shared.user?.id
                            || $0.holderThree?.id == AppState.shared.user?.id
                            || $0.holderFour?.id == AppState.shared.user?.id
                        }
                    }
                    .sorted(by: Helpers.paymentMethodSorter())
            )
        ]
    }
    
    private func getAllExceptUnifiedPayMethods(includeHidden: Bool, sText: String) -> Array<PaySection> {
        return [
            PaySection(
                kind: .debit,
                payMethods: self.paymentMethods
                    .filter {
                        [.checking, .cash].contains($0.accountType)
                        && $0.isPermitted
                        && (includeHidden ? true : !$0.isHidden)
                        && (sText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(sText))
                    }
                    .filter {
                        switch LocalStorage.shared.paymentMethodFilterMode {
                        case .all:
                            return true
                        case .justPrimary:
                            return $0.holderOne?.id == AppState.shared.user?.id
                        case .primaryAndSecondary:
                            return $0.holderOne?.id == AppState.shared.user?.id
                            || $0.holderTwo?.id == AppState.shared.user?.id
                            || $0.holderThree?.id == AppState.shared.user?.id
                            || $0.holderFour?.id == AppState.shared.user?.id
                        }
                    }
                    .sorted(by: Helpers.paymentMethodSorter())
            ),
            PaySection(
                kind: .credit,
                payMethods: self.paymentMethods
                    .filter {
                        $0.isCreditOrLoan
                        && $0.isPermitted
                        && (includeHidden ? true : !$0.isHidden)
                        && (sText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(sText))
                    }
                    .filter {
                        switch LocalStorage.shared.paymentMethodFilterMode {
                        case .all:
                            return true
                        case .justPrimary:
                            return $0.holderOne?.id == AppState.shared.user?.id
                        case .primaryAndSecondary:
                            return $0.holderOne?.id == AppState.shared.user?.id
                            || $0.holderTwo?.id == AppState.shared.user?.id
                            || $0.holderThree?.id == AppState.shared.user?.id
                            || $0.holderFour?.id == AppState.shared.user?.id
                        }
                    }
                    .sorted(by: Helpers.paymentMethodSorter())
            ),
            PaySection(
                kind: .other,
                payMethods: self.paymentMethods
                    .filter {
                        !$0.isDebit
                        && !$0.isCredit
                        && $0.isPermitted
                        && (includeHidden ? true : !$0.isHidden)
                        && (sText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(sText))
                    }
                    .filter {
                        switch LocalStorage.shared.paymentMethodFilterMode {
                        case .all:
                            return true
                        case .justPrimary:
                            return $0.holderOne?.id == AppState.shared.user?.id
                        case .primaryAndSecondary:
                            return $0.holderOne?.id == AppState.shared.user?.id
                            || $0.holderTwo?.id == AppState.shared.user?.id
                            || $0.holderThree?.id == AppState.shared.user?.id
                            || $0.holderFour?.id == AppState.shared.user?.id
                        }
                    }
                    .sorted(by: Helpers.paymentMethodSorter())
            )
        ]
    }
    
    private func getAllPayMethodsBasedOnSelected(includeHidden: Bool, sText: String, calModel: CalendarModel) -> Array<PaySection> {
        if calModel.sPayMethod?.accountType == .unifiedChecking {
            return [
                PaySection(
                    kind: .debit,
                    payMethods: self.paymentMethods
                        .filter {
                            $0.isDebit
                            && $0.isPermitted
                            && (includeHidden ? true : !$0.isHidden)
                            && (sText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(sText))
                        }
                        .filter {
                            switch LocalStorage.shared.paymentMethodFilterMode {
                            case .all:
                                return true
                            case .justPrimary:
                                return $0.holderOne?.id == AppState.shared.user?.id
                            case .primaryAndSecondary:
                                return $0.holderOne?.id == AppState.shared.user?.id
                                || $0.holderTwo?.id == AppState.shared.user?.id
                                || $0.holderThree?.id == AppState.shared.user?.id
                                || $0.holderFour?.id == AppState.shared.user?.id
                            }
                        }
                        .sorted(by: Helpers.paymentMethodSorter())
                )
            ]
            
        } else if calModel.sPayMethod?.accountType == .unifiedCredit {
            return [
                PaySection(
                    kind: .credit,
                    payMethods: self.paymentMethods
                        .filter {
                            $0.isCreditOrLoan
                            && $0.isPermitted
                            && (includeHidden ? true : !$0.isHidden)
                            && (sText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(sText))
                        }
                        .filter {
                            switch LocalStorage.shared.paymentMethodFilterMode {
                            case .all:
                                return true
                            case .justPrimary:
                                return $0.holderOne?.id == AppState.shared.user?.id
                            case .primaryAndSecondary:
                                return $0.holderOne?.id == AppState.shared.user?.id
                                || $0.holderTwo?.id == AppState.shared.user?.id
                                || $0.holderThree?.id == AppState.shared.user?.id
                                || $0.holderFour?.id == AppState.shared.user?.id
                            }
                        }
                        .sorted(by: Helpers.paymentMethodSorter())
                )
            ]
            
        } else {
            return [
                PaySection(
                    kind: .other,
                    payMethods: self.paymentMethods
                        .filter {
                            !$0.isDebit
                            && !$0.isCredit
                            && $0.isPermitted
                            && (includeHidden ? true : !$0.isHidden)
                            && (sText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(sText))
                        }
                        .filter {
                            switch LocalStorage.shared.paymentMethodFilterMode {
                            case .all:
                                return true
                            case .justPrimary:
                                return $0.holderOne?.id == AppState.shared.user?.id
                            case .primaryAndSecondary:
                                return $0.holderOne?.id == AppState.shared.user?.id
                                || $0.holderTwo?.id == AppState.shared.user?.id
                                || $0.holderThree?.id == AppState.shared.user?.id
                                || $0.holderFour?.id == AppState.shared.user?.id
                            }
                        }
                        .sorted(by: Helpers.paymentMethodSorter())
                )
            ]
        }
    }
    
    private func getAllRemainingAvailbleForPlaidPayMethods(includeHidden: Bool, sText: String, plaidModel: PlaidModel) -> Array<PaySection> {
        let taken: Array<String> = plaidModel.banks.flatMap ({ $0.accounts.compactMap({ $0.paymentMethodID }) })
        return [
            PaySection(
                kind: .debit,
                payMethods: self.paymentMethods
                    /// Intentionally exclude cash
                    .filter {
                        $0.accountType == .checking
                        && !taken.contains($0.id)
                        && $0.isPermitted
                        && (sText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(sText))
                    }
                    .filter {
                        switch LocalStorage.shared.paymentMethodFilterMode {
                        case .all:
                            return true
                        case .justPrimary:
                            return $0.holderOne?.id == AppState.shared.user?.id
                        case .primaryAndSecondary:
                            return $0.holderOne?.id == AppState.shared.user?.id
                            || $0.holderTwo?.id == AppState.shared.user?.id
                            || $0.holderThree?.id == AppState.shared.user?.id
                            || $0.holderFour?.id == AppState.shared.user?.id
                        }
                    }
                    .sorted(by: Helpers.paymentMethodSorter())
            ),
            PaySection(
                kind: .credit,
                payMethods: self.paymentMethods
                    .filter {
                        ($0.accountType == .credit || $0.accountType == .loan)
                        && !taken.contains($0.id)
                        && $0.isPermitted
                        && (sText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(sText))
                    }
                    .filter {
                        switch LocalStorage.shared.paymentMethodFilterMode {
                        case .all:
                            return true
                        case .justPrimary:
                            return $0.holderOne?.id == AppState.shared.user?.id
                        case .primaryAndSecondary:
                            return $0.holderOne?.id == AppState.shared.user?.id
                            || $0.holderTwo?.id == AppState.shared.user?.id
                            || $0.holderThree?.id == AppState.shared.user?.id
                            || $0.holderFour?.id == AppState.shared.user?.id
                        }
                    }
                    .sorted(by: Helpers.paymentMethodSorter())
            ),
            PaySection(
                kind: .other,
                payMethods: self.paymentMethods
                    .filter {
                        !$0.isDebit
                        && !$0.isCredit
                        && $0.isPermitted
                        && (sText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(sText))
                    }
                    .filter {
                        switch LocalStorage.shared.paymentMethodFilterMode {
                        case .all:
                            return true
                        case .justPrimary:
                            return $0.holderOne?.id == AppState.shared.user?.id
                        case .primaryAndSecondary:
                            return $0.holderOne?.id == AppState.shared.user?.id
                            || $0.holderTwo?.id == AppState.shared.user?.id
                            || $0.holderThree?.id == AppState.shared.user?.id
                            || $0.holderFour?.id == AppState.shared.user?.id
                        }
                    }
                    .sorted(by: Helpers.paymentMethodSorter())
            )
        ]
    }
    
    func getApplicablePayMethods(
        type: ApplicablePaymentMethods,
        calModel: CalendarModel,
        plaidModel: PlaidModel,
        searchText: Binding<String>,
        includeHidden: Bool = false
    ) -> Array<PaySection> {
        let sText = searchText.wrappedValue
        
        switch type {
        case .all:
            return getAllPayMethods(includeHidden: includeHidden, sText: sText)
                        
        case .allExceptUnified:
            return getAllExceptUnifiedPayMethods(includeHidden: includeHidden, sText: sText)
            
        case .basedOnSelected:
            return getAllPayMethodsBasedOnSelected(includeHidden: includeHidden, sText: sText, calModel: calModel)
            
        case .remainingAvailbleForPlaid:
            return getAllRemainingAvailbleForPlaidPayMethods(includeHidden: includeHidden, sText: sText, plaidModel: plaidModel)
        }
    }
}
