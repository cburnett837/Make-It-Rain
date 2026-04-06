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
    var paymentMethods: Array<CBPaymentMethod> = []
    var fuckYouSwiftuiTableRefreshID: UUID = UUID()
    
    let sections: [PaymentMethodSection] = [.debit, .credit, .other]
    
    func doesExist(_ payMethod: CBPaymentMethod) -> Bool {
        return !paymentMethods.filter { $0.id == payMethod.id }.isEmpty
    }
    
    func getPaymentMethod(by id: String) -> CBPaymentMethod {
        return paymentMethods.filter { $0.id == id }.first ?? CBPaymentMethod(uuid: id)
    }
    
    func upsert(_ payMethod: CBPaymentMethod) {
        if doesExist(payMethod), let index = getIndex(for: payMethod) {
            paymentMethods[index].setFromAnotherInstance(payMethod: payMethod)
        } else {
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
    
    
//    func updateCache(for payMethod: CBPaymentMethod) async -> Result<Bool, CoreDataError> {
//        
//        let id = payMethod.id
//        let title = payMethod.title
//        let dueDate = Int64(payMethod.dueDate ?? 0)
//        let limit = payMethod.limit ?? 0.0
//        let accountType = Int64(payMethod.accountType.rawValue)
//        let hexCode = payMethod.color.toHex()
//        let isViewingDefault = payMethod.isViewingDefault
//        let notificationOffset = Int64(payMethod.notificationOffset)
//        let notifyOnDueDate = payMethod.notifyOnDueDate
//        let last4 = payMethod.last4
//        let interestRate = payMethod.interestRate ?? 0
//        let loanDuration = Int64(payMethod.loanDuration ?? 0)
//        let isHidden = payMethod.isHidden
//        let isPrivate = payMethod.isPrivate
//        let logo = payMethod.logo
//        //let action = "edit"
//        //let isPending = false
//        let enteredByID = Int64(payMethod.enteredBy.id)
//        let updatedByID = Int64(payMethod.updatedBy.id)
//        let enteredDate = payMethod.enteredDate
//        let updatedDate = payMethod.updatedDate
//        let listOrder = Int64(payMethod.listOrder ?? 0)
//        
//        let holderOneID = Int64(payMethod.holderOne?.id ?? 0)
//        let holderTwoID = Int64(payMethod.holderTwo?.id ?? 0)
//        let holderThreeID = Int64(payMethod.holderThree?.id ?? 0)
//        let holderFourID = Int64(payMethod.holderFour?.id ?? 0)
//        
//        let holderOneTypeID = Int64(payMethod.holderOneType?.id ?? 0)
//        let holderTwoTypeID = Int64(payMethod.holderTwoType?.id ?? 0)
//        let holderThreeTypeID = Int64(payMethod.holderThreeType?.id ?? 0)
//        let holderFourTypeID = Int64(payMethod.holderFourType?.id ?? 0)
//        let recentTransactionCount = Int64(payMethod.recentTransactionCount)
//        
//        
//        
//        let context = DataManager.shared.createContext()
//        return await context.perform {
//            /// Create this if not found because if a method gets marked as private from another device after this one has already cached it, it will get deleted from the cache by the long poll.
//            if let entity = DataManager.shared.getOne(
//                context: context,
//                type: PersistentPaymentMethod.self,
//                predicate: .byId(.string(id)),
//                createIfNotFound: true
//            ) {
//                entity.id = id
//                entity.title = title
//                entity.dueDate = dueDate
//                entity.limit = limit
//                entity.accountType = accountType
//                entity.hexCode = hexCode
//                //entity.hexCode = payMethod.color.description
//                entity.isViewingDefault = isViewingDefault
//                entity.notificationOffset = notificationOffset
//                entity.notifyOnDueDate = notifyOnDueDate
//                entity.last4 = last4
//                entity.interestRate = interestRate
//                entity.loanDuration = loanDuration
//                entity.isHidden = isHidden
//                entity.isPrivate = isPrivate
//                entity.action = "edit"
//                entity.isPending = false
////                entity.logo?.photoData = logo
////                entity.logo?.localUpdatedDate = Date()
//                entity.enteredByID = enteredByID
//                entity.updatedByID = updatedByID
//                entity.enteredDate = enteredDate
//                entity.updatedDate = updatedDate
//                
//                entity.listOrder = listOrder
//                entity.recentTransactionCount = recentTransactionCount
//                
//                entity.holderOneID = holderOneID
//                entity.holderTwoID = holderTwoID
//                entity.holderThreeID = holderThreeID
//                entity.holderFourID = holderFourID
//                entity.holderOneTypeID = holderOneTypeID
//                entity.holderTwoTypeID = holderTwoTypeID
//                entity.holderThreeTypeID = holderThreeTypeID
//                entity.holderFourTypeID = holderFourTypeID
//                
//                
//                let pred1 = NSPredicate(format: "relatedID == %@", id)
//                let pred2 = NSPredicate(format: "relatedTypeID == %@", NSNumber(value: XrefModel.getItem(from: .logoTypes, byEnumID: .paymentMethod).id))
//                let comp = NSCompoundPredicate(andPredicateWithSubpredicates: [pred1, pred2])
//                
//                if let perLogo = DataManager.shared.getOne(
//                    context: context,
//                    type: PersistentLogo.self,
//                    predicate: .compound(comp),
//                    createIfNotFound: true
//                ) {
//                    perLogo.photoData = logo
//                    perLogo.localUpdatedDate = Date()
//                }
//                
//                
//                return DataManager.shared.save(context: context)
//            } else {
//                return .failure(.notFound)
//            }
//        }
//    }
    
    
    @MainActor
    func fetchPaymentMethods(calModel: CalendarModel) async {
        LogManager.log()
        
        let start = CFAbsoluteTimeGetCurrent()
        
        /// For testing bad network connection.
        //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        
        /// Do networking.
        let model = RequestModel(requestType: "fetch_payment_methods", model: AppState.shared.user)
        typealias ResultResponse = Result<Array<CBPaymentMethod>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            if let model {
                if !model.isEmpty {
                    for meth in model {
                        await meth.loadLogoFromCoreDataIfNeeded()
                        upsert(meth)
                        await meth.updateCoreData(action: .edit, isPending: false, createIfNotFound: true)
                    }
                    
                    /// Delete from cache and local list.
                    for meth in paymentMethods {
                        if model.filter({ $0.id == meth.id }).isEmpty {
                            paymentMethods.removeAll { $0.id == meth.id }
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
    @discardableResult
    func submit(_ payMethod: CBPaymentMethod) async -> Bool {
        print("-- \(#function)")
                
        /// Allow more time to save if the user enters the background.
        #if os(iOS)
        var backgroundTaskId = AppState.shared.beginBackgroundTask()
        #endif
        
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        
        /// Stuff in core data in case something goes wrong in the networking.
        /// If something goes wrong, the isPending flag will cause it to be queued for syncing on next successful connection.
        await payMethod.updateCoreData(action: payMethod.action, isPending: true, createIfNotFound: true)
        
        let model = RequestModel(requestType: payMethod.action.serverKey, model: payMethod)
        typealias ResultResponse = Result<ReturnIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            
            if payMethod.action == .delete {
                print("Delete payment method from core data with id \(payMethod.id)")
                DataManager.shared.delete(context: DataManager.shared.createContext(), type: PersistentPaymentMethod.self, predicate: .byId(.string(payMethod.id)))
                
            } else if let serverID = model?.id {
                /// If adding, the keyword ID will be the UUID, which is what would have been used to save the item to core data initially, so pass it as the lookupID.
                /// Pass the new serverID as the id so it gets set on the keyword.
                await payMethod.updateAfterSubmit(
                    id: payMethod.action == .add ? serverID : payMethod.id,
                    lookupId: payMethod.id,
                    action: payMethod.action,
                    updatedDate: model?.updatedDate ?? Date(),
                    logo: payMethod.logo
                )
            }
                                                
        case .failure(let error):
            print("❌Payment method failed to save")
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem syncing the payment method. Will try again at a later time.")
        }
        
        #if os(macOS)
        fuckYouSwiftuiTableRefreshID = UUID()
        #endif
        
        #if os(iOS)
        AppState.shared.endBackgroundTask(&backgroundTaskId)
        #endif
        
        return (await result).isSuccess
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
    func setDefaultViewing(_ payMethod: CBPaymentMethod?) async {
        print("-- \(#function)")
        
        /// Allow more time to save if the user enters the background.
        #if os(iOS)
        var backgroundTaskId = AppState.shared.beginBackgroundTask()
        #endif
        
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
                                        
        for each in paymentMethods {
            each.isViewingDefault = false
        }
        
        for each in paymentMethods {
            if each.id == payMethod?.id {
                each.isViewingDefault = true
            }
        }
                
        let methInfos = self.paymentMethods.map { (id: $0.id, isViewingDefault: $0.isViewingDefault) }
        
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
        let submitModel = IdSubmitModel(id: payMethod?.id)
        let model = RequestModel(requestType: "set_default_viewing_payment_method", model: submitModel)
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success:
            LogManager.networkingSuccessful()

        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to set the default payment method.")
        }
        
        #if os(iOS)
        AppState.shared.endBackgroundTask(&backgroundTaskId)
        #endif
    }
    
    
    @MainActor
    func setDefaultEditing(_ payMethod: CBPaymentMethod?) async {
        print("-- \(#function)")
        
        /// Allow more time to save if the user enters the background.
        #if os(iOS)
        var backgroundTaskId = AppState.shared.beginBackgroundTask()
        #endif
        
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        
        for each in paymentMethods {
            each.isEditingDefault = false
        }
        
        for each in paymentMethods {
            if each.id == payMethod?.id {
                each.isEditingDefault = true
            }
        }
                                
        let methInfos = self.paymentMethods.map { (id: $0.id, isEditingDefault: $0.isEditingDefault) }
        
        let context = DataManager.shared.createContext()
        await context.perform {
            for method in methInfos {
                if let entity = DataManager.shared.getOne(context: context, type: PersistentPaymentMethod.self, predicate: .byId(.string(method.id)), createIfNotFound: true) {
                    entity.isEditingDefault = method.isEditingDefault
                }
            }
            
            let _ = DataManager.shared.save(context: context)
        }
                                              
        /// Networking
        let submitModel = IdSubmitModel(id: payMethod?.id)
        let model = RequestModel(requestType: "set_default_editing_payment_method", model: submitModel)
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success:
            LogManager.networkingSuccessful()

        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to set the default payment method.")
        }
        
        /// End the background task.
        #if os(iOS)
        AppState.shared.endBackgroundTask(&backgroundTaskId)
        #endif
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
    
    
    @MainActor func prepareStartingAmounts(for month: CBMonth, calModel: CalendarModel) {
        //print("-- \(#function)")
        for payMethod in self.paymentMethods.filter({ $0.isPermittedAndViewable }) {
            /// Create a starting amount if it doesn't exist in the current month.
            if !month.startingAmounts.contains(where: { $0.payMethod.id == payMethod.id }) {
                let starting = CBStartingAmount()
                starting.payMethod = payMethod
                starting.action = .add
                starting.month = month.actualNum
                starting.year = month.year
                
                starting.amountString = ""
                month.startingAmounts.append(starting)
            }
                                                
            if payMethod.isUnified {
                let _ = calModel.updateUnifiedStartingAmount(month: month, for: payMethod.accountType)
            }
        }
    }
    
    
    func determineIfUserIsRequiredToAddPaymentMethod() {
        print("-- \(#function)")
        /// If you close the payment method edit page, and the data is not valid, hide all the other views.
        if AppState.shared.methsExist
        && paymentMethods
            /// User must have at least 1 account that they are listed as the primary holder on
            .filter ({ meth in
                return meth.holderOne?.id == AppState.shared.user?.id
//                switch AppSettings.shared.paymentMethodFilterMode {
//                case .all:
//                    return true
//                case .justPrimary:
//                    return meth.holderOne?.id == AppState.shared.user?.id
//                case .primaryAndSecondary:
//                    return meth.holderOne?.id == AppState.shared.user?.id
//                    || meth.holderTwo?.id == AppState.shared.user?.id
//                    || meth.holderThree?.id == AppState.shared.user?.id
//                    || meth.holderFour?.id == AppState.shared.user?.id
//                }
            })
            .filter({ !$0.isUnified }).isEmpty {
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
    func setListOrders(calModel: CalendarModel) async -> Array<ListOrderUpdate> {
        var updates: Array<ListOrderUpdate> = []
        var index = 0
        
        for section in self.sections {
            for payMethod in getMethodsFor(section: section, type: .all, includeHidden: true) {
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
    
    
    @MainActor
    func handleLongPoll(_ payMethods: Array<CBPaymentMethod>, calModel: CalendarModel, repModel: RepeatingTransactionModel) async {
        print("-- \(#function)")
        
        //let ogListOrders = payModel.paymentMethods.map { $0.listOrder ?? 0 }.sorted()
        //var newListOrders: [Int] = []
        
        let context = DataManager.shared.createContext()
        for payMethod in payMethods {
            await payMethod.loadLogoFromCoreDataIfNeeded()
            
            //newListOrders.append(payMethod.listOrder ?? 0)
            if self.doesExist(payMethod) {
                if !payMethod.active {
                    self.delete(payMethod, andSubmit: false, calModel: calModel)
                    continue
                } else {
                    if let index = self.getIndex(for: payMethod) {
                        self.paymentMethods[index].setFromAnotherInstance(payMethod: payMethod)
                        self.paymentMethods[index].deepCopy?.setFromAnotherInstance(payMethod: payMethod)
                    }
                }
            } else {
                if payMethod.active {
                    withAnimation { self.upsert(payMethod) }
                }
            }
            
            if payMethod.isPermitted {
                await payMethod.updateCoreData(action: .edit, isPending: false, createIfNotFound: false)
            } else {
                DataManager.shared.delete(context: context, type: PersistentPaymentMethod.self, predicate: .byId(.string(payMethod.id)))
            }
            //print("SaveResult: \(saveResult)")
            
            calModel.justTransactions
                .filter { $0.payMethod?.id == payMethod.id }
                .forEach { $0.payMethod?.setFromAnotherInstance(payMethod: payMethod) }
            
            calModel.months
                .flatMap { $0.startingAmounts.compactMap { $0.payMethod } }
                .filter { $0.id == payMethod.id }
                .forEach { $0.setFromAnotherInstance(payMethod: payMethod) }
            
            repModel.repTransactions
                .filter { $0.payMethod?.id == payMethod.id }
                .forEach { $0.payMethod?.setFromAnotherInstance(payMethod: payMethod) }
        }
        
        self.determineIfUserIsRequiredToAddPaymentMethod()
    }
    
    
    @MainActor
    func populateFromCoreData(setDefaultPayMethod: Bool, calModel: CalendarModel) async {
        let context = DataManager.shared.createContext()

        let methodIDs: [String] = await DataManager.shared.perform(context: context) {
            let entities = DataManager.shared.getMany(context: context, type: PersistentPaymentMethod.self) ?? []
            return entities.compactMap(\.id)
        }

        guard !methodIDs.isEmpty else { return }

        var loadedMethods: [CBPaymentMethod] = []
        loadedMethods.reserveCapacity(methodIDs.count)

        for id in methodIDs {
            if let method = await CBPaymentMethod.loadFromCoreData(id: id) {
                loadedMethods.append(method)
            }
        }

        for method in loadedMethods {
            if setDefaultPayMethod && method.isViewingDefault {
                calModel.sPayMethod = method
            }
            
            self.upsert(method)
        }

        self.paymentMethods.sort(by: Helpers.paymentMethodSorter())
    }

    
    
    func getMethodsFor(
        section: PaymentMethodSection,
        type: ApplicablePaymentMethods,
        sText: String = "",
        includeHidden: Bool = false,
        calModel: CalendarModel? = nil,
        plaidModel: PlaidModel? = nil
    ) -> Array<CBPaymentMethod> {
        self.paymentMethods
            .filter { meth in
                switch type {
                case .all:
                    return true
                    
                case .allExceptUnified:
                    return !meth.isUnified
                    
                case .basedOnSelected:
                    if calModel?.sPayMethod?.accountType == .unifiedChecking { return meth.isDebitOrCash }
                    else if calModel?.sPayMethod?.accountType == .unifiedCredit { return meth.isCreditOrLoan }
                    else { return (!meth.isDebitOrUnified && !meth.isCreditOrUnified) }
                    
                case .remainingAvailbleForPlaid:
                    let taken: Array<String> = plaidModel?.banks.flatMap ({ $0.accounts.compactMap({ $0.paymentMethodID }) }) ?? []
                    //return meth.accountType == .checking && !taken.contains(meth.id)
                    return !meth.isUnified && !taken.contains(meth.id)
                }
            }
            .filter {
                $0.sectionType == section
                && $0.isPermitted
                && (includeHidden ? true : !$0.isHidden)
                && (sText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(sText))
            }
            .filter {
                switch AppSettings.shared.paymentMethodFilterMode {
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
    }
    
    
//    private func getAllPayMethods(includeHidden: Bool, sText: String) -> Array<PaySection> {
//        return [
//            //PaySection(kind: .combined, payMethods: payModel.paymentMethods.filter { $0.accountType == .unifiedCredit || $0.accountType == .unifiedChecking }),
//            PaySection(
//                kind: .debit,
//                payMethods: self.paymentMethods
//                    .filter {
//                        $0.isDebitOrUnified
//                        && $0.isPermitted
//                        && (includeHidden ? true : !$0.isHidden)
//                        && (sText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(sText))
//                    }
//                    .filter {
//                        switch AppSettings.shared.paymentMethodFilterMode {
//                        case .all:
//                            return true
//                        case .justPrimary:
//                            return $0.holderOne?.id == AppState.shared.user?.id
//                        case .primaryAndSecondary:
//                            return $0.holderOne?.id == AppState.shared.user?.id
//                            || $0.holderTwo?.id == AppState.shared.user?.id
//                            || $0.holderThree?.id == AppState.shared.user?.id
//                            || $0.holderFour?.id == AppState.shared.user?.id
//                        }
//                    }
//                    .sorted(by: Helpers.paymentMethodSorter())
//            ),
//            PaySection(
//                kind: .credit,
//                payMethods: self.paymentMethods
//                    .filter {
//                        $0.isCreditOrUnified
//                        && $0.isPermitted
//                        && (includeHidden ? true : !$0.isHidden)
//                        && (sText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(sText))
//                    }
//                    .filter {
//                        switch AppSettings.shared.paymentMethodFilterMode {
//                        case .all:
//                            return true
//                        case .justPrimary:
//                            return $0.holderOne?.id == AppState.shared.user?.id
//                        case .primaryAndSecondary:
//                            return $0.holderOne?.id == AppState.shared.user?.id
//                            || $0.holderTwo?.id == AppState.shared.user?.id
//                            || $0.holderThree?.id == AppState.shared.user?.id
//                            || $0.holderFour?.id == AppState.shared.user?.id
//                        }
//                    }
//                    .sorted(by: Helpers.paymentMethodSorter())
//            ),
//            PaySection(
//                kind: .other,
//                payMethods: self.paymentMethods
//                    .filter {
//                        !$0.isDebitOrUnified
//                        && !$0.isCreditOrUnified
//                        && $0.isPermitted
//                        && (includeHidden ? true : !$0.isHidden)
//                        && (sText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(sText))
//                    }
//                    .filter {
//                        switch AppSettings.shared.paymentMethodFilterMode {
//                        case .all:
//                            return true
//                        case .justPrimary:
//                            return $0.holderOne?.id == AppState.shared.user?.id
//                        case .primaryAndSecondary:
//                            return $0.holderOne?.id == AppState.shared.user?.id
//                            || $0.holderTwo?.id == AppState.shared.user?.id
//                            || $0.holderThree?.id == AppState.shared.user?.id
//                            || $0.holderFour?.id == AppState.shared.user?.id
//                        }
//                    }
//                    .sorted(by: Helpers.paymentMethodSorter())
//            )
//        ]
//    }
//    
//    private func getAllExceptUnifiedPayMethods(includeHidden: Bool, sText: String) -> Array<PaySection> {
//        return [
//            PaySection(
//                kind: .debit,
//                payMethods: self.paymentMethods
//                    .filter {
//                        $0.isDebitOrCash
//                        && $0.isPermitted
//                        && (includeHidden ? true : !$0.isHidden)
//                        && (sText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(sText))
//                    }
//                    .filter {
//                        switch AppSettings.shared.paymentMethodFilterMode {
//                        case .all:
//                            return true
//                        case .justPrimary:
//                            return $0.holderOne?.id == AppState.shared.user?.id
//                        case .primaryAndSecondary:
//                            return $0.holderOne?.id == AppState.shared.user?.id
//                            || $0.holderTwo?.id == AppState.shared.user?.id
//                            || $0.holderThree?.id == AppState.shared.user?.id
//                            || $0.holderFour?.id == AppState.shared.user?.id
//                        }
//                    }
//                    .sorted(by: Helpers.paymentMethodSorter())
//            ),
//            PaySection(
//                kind: .credit,
//                payMethods: self.paymentMethods
//                    .filter {
//                        $0.isCreditOrLoan
//                        && $0.isPermitted
//                        && (includeHidden ? true : !$0.isHidden)
//                        && (sText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(sText))
//                    }
//                    .filter {
//                        switch AppSettings.shared.paymentMethodFilterMode {
//                        case .all:
//                            return true
//                        case .justPrimary:
//                            return $0.holderOne?.id == AppState.shared.user?.id
//                        case .primaryAndSecondary:
//                            return $0.holderOne?.id == AppState.shared.user?.id
//                            || $0.holderTwo?.id == AppState.shared.user?.id
//                            || $0.holderThree?.id == AppState.shared.user?.id
//                            || $0.holderFour?.id == AppState.shared.user?.id
//                        }
//                    }
//                    .sorted(by: Helpers.paymentMethodSorter())
//            ),
//            PaySection(
//                kind: .other,
//                payMethods: self.paymentMethods
//                    .filter {
//                        !$0.isDebitOrUnified
//                        && !$0.isCreditOrUnified
//                        && $0.isPermitted
//                        && (includeHidden ? true : !$0.isHidden)
//                        && (sText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(sText))
//                    }
//                    .filter {
//                        switch AppSettings.shared.paymentMethodFilterMode {
//                        case .all:
//                            return true
//                        case .justPrimary:
//                            return $0.holderOne?.id == AppState.shared.user?.id
//                        case .primaryAndSecondary:
//                            return $0.holderOne?.id == AppState.shared.user?.id
//                            || $0.holderTwo?.id == AppState.shared.user?.id
//                            || $0.holderThree?.id == AppState.shared.user?.id
//                            || $0.holderFour?.id == AppState.shared.user?.id
//                        }
//                    }
//                    .sorted(by: Helpers.paymentMethodSorter())
//            )
//        ]
//    }
//    
//    private func getAllPayMethodsBasedOnSelected(includeHidden: Bool, sText: String, calModel: CalendarModel) -> Array<PaySection> {
//        if calModel.sPayMethod?.accountType == .unifiedChecking {
//            return [
//                PaySection(
//                    kind: .debit,
//                    payMethods: self.paymentMethods
//                        .filter {
//                            $0.isDebitOrUnified
//                            && $0.isPermitted
//                            && (includeHidden ? true : !$0.isHidden)
//                            && (sText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(sText))
//                        }
//                        .filter {
//                            switch AppSettings.shared.paymentMethodFilterMode {
//                            case .all:
//                                return true
//                            case .justPrimary:
//                                return $0.holderOne?.id == AppState.shared.user?.id
//                            case .primaryAndSecondary:
//                                return $0.holderOne?.id == AppState.shared.user?.id
//                                || $0.holderTwo?.id == AppState.shared.user?.id
//                                || $0.holderThree?.id == AppState.shared.user?.id
//                                || $0.holderFour?.id == AppState.shared.user?.id
//                            }
//                        }
//                        .sorted(by: Helpers.paymentMethodSorter())
//                )
//            ]
//            
//        } else if calModel.sPayMethod?.accountType == .unifiedCredit {
//            return [
//                PaySection(
//                    kind: .credit,
//                    payMethods: self.paymentMethods
//                        .filter {
//                            $0.isCreditOrLoan
//                            && $0.isPermitted
//                            && (includeHidden ? true : !$0.isHidden)
//                            && (sText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(sText))
//                        }
//                        .filter {
//                            switch AppSettings.shared.paymentMethodFilterMode {
//                            case .all:
//                                return true
//                            case .justPrimary:
//                                return $0.holderOne?.id == AppState.shared.user?.id
//                            case .primaryAndSecondary:
//                                return $0.holderOne?.id == AppState.shared.user?.id
//                                || $0.holderTwo?.id == AppState.shared.user?.id
//                                || $0.holderThree?.id == AppState.shared.user?.id
//                                || $0.holderFour?.id == AppState.shared.user?.id
//                            }
//                        }
//                        .sorted(by: Helpers.paymentMethodSorter())
//                )
//            ]
//            
//        } else {
//            return [
//                PaySection(
//                    kind: .other,
//                    payMethods: self.paymentMethods
//                        .filter {
//                            !$0.isDebitOrUnified
//                            && !$0.isCreditOrUnified
//                            && $0.isPermitted
//                            && (includeHidden ? true : !$0.isHidden)
//                            && (sText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(sText))
//                        }
//                        .filter {
//                            switch AppSettings.shared.paymentMethodFilterMode {
//                            case .all:
//                                return true
//                            case .justPrimary:
//                                return $0.holderOne?.id == AppState.shared.user?.id
//                            case .primaryAndSecondary:
//                                return $0.holderOne?.id == AppState.shared.user?.id
//                                || $0.holderTwo?.id == AppState.shared.user?.id
//                                || $0.holderThree?.id == AppState.shared.user?.id
//                                || $0.holderFour?.id == AppState.shared.user?.id
//                            }
//                        }
//                        .sorted(by: Helpers.paymentMethodSorter())
//                )
//            ]
//        }
//    }
//    
//    private func getAllRemainingAvailbleForPlaidPayMethods(includeHidden: Bool, sText: String, plaidModel: PlaidModel) -> Array<PaySection> {
//        let taken: Array<String> = plaidModel.banks.flatMap ({ $0.accounts.compactMap({ $0.paymentMethodID }) })
//        return [
//            PaySection(
//                kind: .debit,
//                payMethods: self.paymentMethods
//                    /// Intentionally exclude cash
//                    .filter {
//                        $0.accountType == .checking
//                        && !taken.contains($0.id)
//                        && $0.isPermitted
//                        && (sText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(sText))
//                    }
//                    .filter {
//                        switch AppSettings.shared.paymentMethodFilterMode {
//                        case .all:
//                            return true
//                        case .justPrimary:
//                            return $0.holderOne?.id == AppState.shared.user?.id
//                        case .primaryAndSecondary:
//                            return $0.holderOne?.id == AppState.shared.user?.id
//                            || $0.holderTwo?.id == AppState.shared.user?.id
//                            || $0.holderThree?.id == AppState.shared.user?.id
//                            || $0.holderFour?.id == AppState.shared.user?.id
//                        }
//                    }
//                    .sorted(by: Helpers.paymentMethodSorter())
//            ),
//            PaySection(
//                kind: .credit,
//                payMethods: self.paymentMethods
//                    .filter {
//                        ($0.accountType == .credit || $0.accountType == .loan)
//                        && !taken.contains($0.id)
//                        && $0.isPermitted
//                        && (sText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(sText))
//                    }
//                    .filter {
//                        switch AppSettings.shared.paymentMethodFilterMode {
//                        case .all:
//                            return true
//                        case .justPrimary:
//                            return $0.holderOne?.id == AppState.shared.user?.id
//                        case .primaryAndSecondary:
//                            return $0.holderOne?.id == AppState.shared.user?.id
//                            || $0.holderTwo?.id == AppState.shared.user?.id
//                            || $0.holderThree?.id == AppState.shared.user?.id
//                            || $0.holderFour?.id == AppState.shared.user?.id
//                        }
//                    }
//                    .sorted(by: Helpers.paymentMethodSorter())
//            ),
//            PaySection(
//                kind: .other,
//                payMethods: self.paymentMethods
//                    .filter {
//                        !$0.isDebitOrUnified
//                        && !$0.isCreditOrUnified
//                        && $0.isPermitted
//                        && (sText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(sText))
//                    }
//                    .filter {
//                        switch AppSettings.shared.paymentMethodFilterMode {
//                        case .all:
//                            return true
//                        case .justPrimary:
//                            return $0.holderOne?.id == AppState.shared.user?.id
//                        case .primaryAndSecondary:
//                            return $0.holderOne?.id == AppState.shared.user?.id
//                            || $0.holderTwo?.id == AppState.shared.user?.id
//                            || $0.holderThree?.id == AppState.shared.user?.id
//                            || $0.holderFour?.id == AppState.shared.user?.id
//                        }
//                    }
//                    .sorted(by: Helpers.paymentMethodSorter())
//            )
//        ]
//    }
//    
//    func getApplicablePayMethods(
//        type: ApplicablePaymentMethods,
//        calModel: CalendarModel,
//        plaidModel: PlaidModel,
//        searchText: Binding<String>,
//        includeHidden: Bool = false
//    ) -> Array<PaySection> {
//        let sText = searchText.wrappedValue
//        
//        switch type {
//        case .all:
//            return getAllPayMethods(includeHidden: includeHidden, sText: sText)
//                        
//        case .allExceptUnified:
//            return getAllExceptUnifiedPayMethods(includeHidden: includeHidden, sText: sText)
//            
//        case .basedOnSelected:
//            return getAllPayMethodsBasedOnSelected(includeHidden: includeHidden, sText: sText, calModel: calModel)
//            
//        case .remainingAvailbleForPlaid:
//            return getAllRemainingAvailbleForPlaidPayMethods(includeHidden: includeHidden, sText: sText, plaidModel: plaidModel)
//        }
//    }
}
