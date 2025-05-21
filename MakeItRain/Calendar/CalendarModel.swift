//
//  Model.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/18/24.
//

import Foundation
import SwiftUI
import PhotosUI
import CoreTransferable
#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif


@MainActor
@Observable
class CalendarModel: PhotoUploadCompletedDelegate {
    static let shared = CalendarModel()
    
    // MARK: - State Variables
    //var trans: CBTransaction?
    var isThinking = false // **EXTRACT**
    var showMonth = false // **EXTRACT**
    
    #if os(iOS)
    var isShowingFullScreenCoverOnIpad = false // **EXTRACT**
    #endif
    var categoryFilterWasSetByCategoryPage = false // **EXTRACT**
    var sCategoriesForAnalysis: [CBCategory] = [] // **EXTRACT**
    //var selectedDay: CBDay?

    var windowMonth: NavDestination?    
    
    var sMonth: CBMonth = CBMonth(num: 1) // **EXTRACT**
    var sYear: Int = AppState.shared.todayYear // **EXTRACT**
    var sPayMethod: CBPaymentMethod? { // **EXTRACT**
        didSet {
            //prepareStartingAmount(for: self.sPayMethod) /// Needed for the mac to prepare the unified starting amount
            let _ = calculateTotal(for: self.sMonth)
        }
    }
    var sCategory: CBCategory? // **EXTRACT**
    var sCategories: [CBCategory] = [] // **EXTRACT**
   
    
    /// This gets set to prevent that currently edited transaction from being updates by the long poll or scene change.
    var editLock = false
    var transEditID: String? // **EXTRACT**
    var searchText = "" // **EXTRACT**
    var searchWhat = CalendarSearchWhat.titles // **EXTRACT**
    
    // MARK: - Visual things
    var transactionToCopy: CBTransaction?
    var dragTarget: CBDay?
    var hilightTrans: CBTransaction?
    
    var isInMultiSelectMode = false
    var multiSelectTransactions: Array<CBTransaction> = []
    //var refreshTask: Task<Void, Error>?
    
    
    var weekdaysNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    // MARK: - Data Container Variables
    var months: [CBMonth] = [
        CBMonth(num: 0),
        CBMonth(num: 1),
        CBMonth(num: 2),
        CBMonth(num: 3),
        CBMonth(num: 4),
        CBMonth(num: 5),
        CBMonth(num: 6),
        CBMonth(num: 7),
        CBMonth(num: 8),
        CBMonth(num: 9),
        CBMonth(num: 10),
        CBMonth(num: 11),
        CBMonth(num: 12),
        CBMonth(num: 13)
    ]
    var tempTransactions: [CBTransaction] = []
    var searchedTransactions: [CBTransaction] = []
    //var smartTransactionsWithIssues: [CBTransaction] = []
    var tags: Array<CBTag> = []
    var fitTrans: Array<CBFitTransaction> = []
    
    var justTransactions: Array<CBTransaction> {
        months.flatMap { $0.days }.flatMap { $0.transactions }
    }
    
    var justBudgets: Array<CBBudget> {
        months.flatMap { $0.budgets }
    }
    
    var isUnifiedPayMethod: Bool {
        self.sPayMethod?.accountType == .unifiedChecking || self.sPayMethod?.accountType == .unifiedCredit
    }
   
    
    
    // MARK: - Fetch From Server
    
    @MainActor
    func fetchFitTransactionsFromServer() async {
        //print("-- \(#function)")
        LogManager.log()
        
        let start = CFAbsoluteTimeGetCurrent()
        
        //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        //print("DONE FETCHING")
                            
        //let month = months.filter { $0.num == monthNum }.first!
        let model = RequestModel(requestType: "fetch_fit_transactions", model: CodablePlaceHolder())
        typealias ResultResponse = Result<Array<CBFitTransaction>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            if let model {
                self.fitTrans = model
            }
            
            let currentElapsed = CFAbsoluteTimeGetCurrent() - start
            print("🔴It took \(currentElapsed) seconds to fetch the fit transaction")
            
        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("calModel fetchFitTransactionsFromServer Server Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch fit transactions.")
            }
        }
    }
    
    
    @MainActor
    func fetchFromServer(month: CBMonth, createNewStructs: Bool, refreshTechnique: RefreshTechnique) async {
        //print("-- \(#function)")
        LogManager.log()
        
        let start = CFAbsoluteTimeGetCurrent()
        
        //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        //print("DONE FETCHING")
                            
        //let month = months.filter { $0.num == monthNum }.first!
        let model = RequestModel(requestType: "fetch_transactions_for_month", model: month)
        typealias ResultResponse = Result<TransactionAndStartingAmountModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            
            #warning("need snapshot code")
            if let model {
                month.hasBeenPopulated = model.hasPopulated
                
                if !createNewStructs {
                    self.handleTransactions(model.transactions, for: month, refreshTechnique: refreshTechnique)
                } else {
                    for trans in model.transactions {
                        
                        /// Handle smart transactions that may have been added
                        if let isSmartTransaction = trans.isSmartTransaction {
                            if isSmartTransaction && !(trans.smartTransactionIsAcknowledged ?? true) {
                                if trans.smartTransactionIssue != nil {
                                    if tempTransactions.filter({ $0.id == trans.id }).isEmpty {
                                        tempTransactions.append(trans)
                                    }
                                    continue
                                }
                            }
                        }
                        
                        let day = month.days.filter { $0.date == trans.date }.first
                        day?.transactions.append(trans)
                    }
                    
                    
//                    let pendingSmartCount = self.tempTransactions.filter {$0.isSmartTransaction ?? false}.count
//                    
//                    if pendingSmartCount > 0 {
//                        AppState.shared.showToast(title: "Smart Transaction Issues", subtitle: "\(pendingSmartCount) require attention", body: "", symbol: "exclamationmark.triangle", symbolColor: .orange)
//                    }
                    
                }
                
                for startingAmount in model.startingAmounts {
                    /// When navigation changes, a new `CBStartingAmount` that corresponds to `self.sPayMethod` gets added to the newly selected month. (for when we navigate to a month that does not yet have one on the server.)
                    if month.startingAmounts.contains(where: { $0.payMethod.id == startingAmount.payMethod.id }) {
                        let index = month.startingAmounts.firstIndex(where: { $0.payMethod.id == startingAmount.payMethod.id })!
                        month.startingAmounts[index] = startingAmount
                    } else {
                        month.startingAmounts.append(startingAmount)
                    }
                }
                
                
                if let budgets = model.budgets {
                    for budget in budgets {
                        if month.budgets.contains(where: { $0.id == budget.id }) {
                            let index = month.budgets.firstIndex(where: { $0.id == budget.id })!
                            month.budgets[index] = budget
                        } else {
                            month.budgets.append(budget)
                        }
                    }
                }
                
                
//                
//                if createNewStructs {
//                    for trans in model.transactions {
//                        let day = month.days.filter { $0.date == trans.date }.first
//                        day?.transactions.append(trans)
//                    }
//                }
                
                let _ = calculateTotal(for: month)
            }
            if createNewStructs {
                withAnimation {
                    LoadingManager.shared.downloadAmount += 10
                }
                AppState.shared.downloadedData.append(month.enumID)
            }
            
            
            let currentElapsed = CFAbsoluteTimeGetCurrent() - start
            print("🔴It took \(currentElapsed) seconds to fetch \(month.actualNum) \(month.year)")
            
        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("calModel fetchFrom Server Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch transactions.")
            }
        }
    }
    
    
    
    @MainActor
    func advancedSearch(model: AdvancedSearchModel) async {
        print("-- \(#function)")
        LogManager.log()
        
        let model = RequestModel(requestType: "new_advanced_search", model: model)
        typealias ResultResponse = Result<Array<CBTransaction>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            if let model {
                searchedTransactions = model.sorted { $0.date ?? Date() > $1.date ?? Date() }
            }
            
        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("calModel fetchFrom Server Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch transactions.")
            }
        }
    }
    
    
    
    // MARK: - Transaction Stuff
    
    func filteredTrans(day: CBDay) -> Array<CBTransaction> {
        let transactionSortMode = TransactionSortMode.fromString(UserDefaults.standard.string(forKey: "transactionSortMode") ?? "")
        let categorySortMode = CategorySortMode.fromString(UserDefaults.standard.string(forKey: "categorySortMode") ?? "")
        
        /// This will look at both the transaction, and its deepCopy.
        /// The reason being - in case we change a transction category or payment method from what is currently being viewed. This will allow the transaction sheet to remain on screen until we close it, at which point the save function will clear the deepCopy.
        return day.transactions
            /// FIlter by active transactions.
            .filter { trans in trans.active }
            /// Filter by search term & category.
            .filter { trans in
                if searchText.isEmpty {
                    if !sCategories.isEmpty {
                        return sCategories.map{ $0.id }.contains { trans.categoryIdsInCurrentAndDeepCopy.contains($0) }
                    } else {
                        return true
                    }
                } else {
                    if !sCategories.isEmpty {
                        if searchWhat == .titles {
                            return
                                trans.title.localizedStandardContains(searchText)
                                && sCategories.map{ $0.id }.contains { trans.categoryIdsInCurrentAndDeepCopy.contains($0) }
                        } else {
                            return
                                !trans.tags.filter { $0.tag.localizedStandardContains(searchText) }.isEmpty
                                && sCategories.map{ $0.id }.contains { trans.categoryIdsInCurrentAndDeepCopy.contains($0) }
                        }
                    } else {
                        if searchWhat == .titles {
                            return trans.title.localizedStandardContains(searchText)
                        } else {
                            return !trans.tags.filter { $0.tag.localizedStandardContains(searchText) }.isEmpty
                        }
                    }
                }
            }
            /// Filter by payment method
            .filter { trans in
                if sPayMethod?.accountType == .unifiedChecking {
                    return [AccountType.checking, AccountType.cash].contains { trans.payMethodTypesInCurrentAndDeepCopy.contains($0) } || (trans.action == .add && trans.payMethod == nil)
                    
                } else if sPayMethod?.accountType == .unifiedCredit {
                    return [AccountType.credit].contains { trans.payMethodTypesInCurrentAndDeepCopy.contains($0) } || (trans.action == .add && trans.payMethod == nil)
                    
                } else {
                    return sPayMethod?.id == trans.payMethod?.id || sPayMethod?.id == trans.deepCopy?.payMethod?.id
                }
            }
            /// Sort by either enteredDate or title - user preference.
            .sorted {
                if transactionSortMode == .title {
                    return $0.title < $1.title
                    
                } else if transactionSortMode == .enteredDate {
                    return $0.enteredDate < $1.enteredDate
                    
                } else {
                    if categorySortMode == .title {
                        return ($0.category?.title ?? "").lowercased() < ($1.category?.title ?? "").lowercased()
                    } else {
                        return $0.category?.listOrder ?? 10000000000 < $1.category?.listOrder ?? 10000000000
                    }
                }
            }
    }
         
    
    func getTransCount(for meth: CBPaymentMethod, and cbMonth: CBMonth) -> Int {
        return justTransactions
            .filter { $0.active }
            .filter { $0.dateComponents?.month == cbMonth.actualNum && $0.dateComponents?.year == cbMonth.year }
            //.filter { $0.payMethod?.id == meth.id }
            .filter { trans in
                if searchText.isEmpty {
                    if !sCategories.isEmpty {
                        return sCategories.map{ $0.id }.contains { trans.categoryIdsInCurrentAndDeepCopy.contains($0) }
                    } else {
                        return true
                    }
                } else {
                    if !sCategories.isEmpty {
                        if searchWhat == .titles {
                            return
                                trans.title.localizedStandardContains(searchText)
                                && sCategories.map{ $0.id }.contains { trans.categoryIdsInCurrentAndDeepCopy.contains($0) }
                        } else {
                            return
                                !trans.tags.filter { $0.tag.localizedStandardContains(searchText) }.isEmpty
                                && sCategories.map{ $0.id }.contains { trans.categoryIdsInCurrentAndDeepCopy.contains($0) }
                        }
                    } else {
                        if searchWhat == .titles {
                            return trans.title.localizedStandardContains(searchText)
                        } else {
                            return !trans.tags.filter { $0.tag.localizedStandardContains(searchText) }.isEmpty
                        }
                    }
                }
            }
            .filter { trans in
                if meth.accountType == .unifiedChecking {
                    return [AccountType.checking, AccountType.cash].contains(trans.payMethod?.accountType)
                    
                } else if meth.accountType == .unifiedCredit {
                    return [AccountType.credit].contains(trans.payMethod?.accountType)
                    
                } else {
                    return trans.payMethod?.id == meth.id
                }
            }
            .count
    }
    
    
    func handleTransactions(_ transactions: Array<CBTransaction>, for month: CBMonth? = nil, refreshTechnique: RefreshTechnique?) {
        let pendingSmartTransactionCount = tempTransactions.filter({ $0.isSmartTransaction ?? false }).count
        
        for transaction in transactions {
            let id = transaction.id
            let date = transaction.date
            let month = transaction.dateComponents?.month
            let dayNum = transaction.dateComponents?.day
            let year = transaction.dateComponents?.year
            
            var ogObject: CBTransaction?
            
            /// Handle smart transactions.
            if let isSmartTransaction = transaction.isSmartTransaction {
                if isSmartTransaction && !(transaction.smartTransactionIsAcknowledged ?? true) {
                    if transaction.smartTransactionIssue != nil {
                        if tempTransactions.filter({ $0.id == transaction.id }).isEmpty {
                            tempTransactions.append(transaction)
                        }
                        continue
                    }
//                    else {
//                        if transaction.active {
//                            AppState.shared.showToast(title: "Smart Transaction Added", subtitle: transaction.title, body: "\(transaction.prettyDate ?? "N/A")", symbol: "checkmark", symbolColor: .green)
//                        }
//                    }
                } else {
                    if isSmartTransaction {
                        /// Is acknowledged (do this to remove from other devices via long poll)
                        tempTransactions.removeAll { $0.id == transaction.id }
                                                        
                        /// Show an alert when a smart transaction first completes.
                        if justTransactions.filter ({ $0.id == transaction.id }).isEmpty {
                            AppState.shared.showToast(title: "Smart Transaction Added", subtitle: transaction.title, body: "\(transaction.prettyDate ?? "N/A")", symbol: "checkmark", symbolColor: .green)
                        }
                    }
                }
            }
            
            /// Check if the transaction exists locally.
            var dateChanged = false
            var exists = false
            months.forEach { month in
                month.days.forEach { day in
                    day.transactions.forEach { trans in
                        if trans.id == id {
                            /// Ignore the currently viewed transaction if coming back to the app from another app (ie if bouncing back and forth between this app and a banking app)
                            if id == transEditID {
                                if refreshTechnique == .viaSceneChange || refreshTechnique == .viaTempListSceneChange {
                                    return
                                }
                            }
                            
                            exists = true
                            
                            /// Delete the transaction if applicable.
                            if !transaction.active {
                                day.remove(transaction)
                            } else {
                                /// Find the transaction in the appropriate day and update if applicable.
                                if let index = day.getIndex(for: transaction) {
                                    ogObject = day.transactions[index]
                                    ogObject!.setFromAnotherInstance(transaction: transaction)
                                    ogObject!.deepCopy?.setFromAnotherInstance(transaction: transaction)
                                }
                                
                                /// Set a flag that the date changed if applicable.
                                if date != day.date {
                                    dateChanged = true
                                }
                            }
                            return
                        }
                    }
                    if exists { return }
                }
                if exists { return }
            }
            
            if !exists {
                ogObject = transaction
            }
                          
            /// If the transaction was not found locally, or the date changed, add it to the applicable day if the month and year match the local scope.
            if !exists || dateChanged {
//                var proceed: Bool
//                var targetMonthNum = month
//                if month == 1 && year == sYear + 1 {
//                    targetMonthNum = 13
//                    proceed = true
//                } else if month == 12 && year == sYear - 1 {
//                    targetMonthNum = 0
//                    proceed = true
//                } else if year != sYear {
//                    proceed = false
//                } else {
//                    proceed = true
//                }
//                
//                if proceed {
                if transaction.active {
                    if let targetMonth = months.filter({ $0.actualNum == month && $0.year == year }).first {
                        if let targetDay = targetMonth.days.filter({ $0.dateComponents?.day == dayNum }).first {
                            withAnimation {
                                targetDay.upsert(ogObject!)
                            }
                        }
                    }
                }
                    
//                }
            }
            
            /// Remove the transaction from the former day if the transaction date changed.
            if dateChanged {
                withAnimation {
                    months
                        .flatMap { $0.days }
                        .filter { day in day.transactions.contains { $0.id == id && $0.date != day.date } }
                        .forEach { $0.transactions.removeAll { $0.id == id } }
                }
            }
        }
        
                
        /// Handle transactions that got deleted, but didn't get checked by the long poll. (When the mac calls downloadEverything() in response to a lifecycle change, a transaction that was deleted on another device would not be in the model, and thus get skipped and left lingering behind)
        if month != nil {
            justTransactions
                .filter { $0.dateComponents?.month == month?.actualNum && $0.dateComponents?.year == month?.year }
                .filter { $0.action != .add }
                .forEach { trans in
                let exists = !transactions.filter { $0.id == trans.id }.isEmpty
                if !exists {
                    months
                    .flatMap { $0.days }
                    .filter { $0.transactions.contains { $0.id == trans.id } }
                    .forEach { $0.remove(trans) }
                }
            }
        }
        
        /// Throw up the toolbar button for smart transactions that need attention.
        let newPendingSmartTransactionCount = tempTransactions.filter({ $0.isSmartTransaction ?? false }).count
        if newPendingSmartTransactionCount > pendingSmartTransactionCount {
            AppState.shared.showToast(title: "Smart Transaction Issues", subtitle: "\(newPendingSmartTransactionCount) require attention", body: "", symbol: "exclamationmark.triangle", symbolColor: .orange)
        }
    }
    
    
    /// Used by the event model to see if the real transaction associated with the event transaction already exists
    func doesTransactionExist(with id: String, from transactionLocation: WhereToLookForTransaction = .normalList) -> Bool {
        let theList = switch transactionLocation {
            case .normalList:           justTransactions
            case .tempList, .smartList: tempTransactions
            case .searchResultList:     searchedTransactions
            //case .eventList:            eventTransactions
        }
        
        return !theList.filter { $0.id == id }.isEmpty
    }
            
    
    func getTransaction(by id: String, from transactionLocation: WhereToLookForTransaction = .normalList) -> CBTransaction {
        let theList = switch transactionLocation {
            case .normalList:           justTransactions
            case .tempList, .smartList: tempTransactions
            case .searchResultList:     searchedTransactions
            //case .eventList:            eventTransactions
        }
        
        return theList.first(where: { $0.id == id }) ?? CBTransaction(uuid: id)
    }
    
    
    private func changeDate(_ trans: CBTransaction) {
        if let (oldDate, newDate) = trans.getDateChanges() {
            if let targetMonth = months.filter({ $0.actualNum == oldDate?.month && $0.year == oldDate?.year }).first {
                if let targetDay = targetMonth.days.filter({ $0.date == oldDate }).first {
                    if targetDay.isExisting(trans) {
                        targetDay.remove(trans)
                                                
                        if newDate?.year == oldDate?.year {
                            if let targetMonth = months.filter({ $0.actualNum == newDate?.month && $0.year == newDate?.year }).first {
                                if let targetDay = targetMonth.days.filter({ $0.date == newDate }).first {
                                    targetDay.upsert(trans)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    func transactionIsValid(trans: CBTransaction, day: CBDay? = nil) -> Bool {
        if trans.action == .delete {
            print("-- \(#function) -- Trans is in delete mode")
            day?.remove(trans)
            return true
        }
        
        /// Check for blank title or missing payment method
        if trans.title.isEmpty || trans.payMethod == nil /*&& day.date == nil*/ {
            print("-- \(#function) -- Title or payment method missing 1")
            /// If a transaction is already existing, and you wipe out the title, put the title back and alert the user.
            if trans.action != .add && trans.title.isEmpty {
                trans.title = trans.deepCopy?.title ?? ""
                                
                AppState.shared.showAlert("Removing a title from a transaction is not allowed. If you want to delete \"\(trans.title)\", please use the delete button instead.")
            } else {
                day?.remove(trans)
            }
            
            if !trans.title.isEmpty && trans.payMethod == nil {
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(0.5 * Double(NSEC_PER_SEC)))
                    AppState.shared.showToast(title: "Failed To Save", subtitle: "Account was missing", body: "", symbol: "exclamationmark.triangle", symbolColor: .orange)
                }
            }
            return false
        }
        
        
        if trans.date == nil && (trans.isSmartTransaction ?? false) {
            print("-- \(#function) -- Trans date is nil and isSmartTransaction")
            Task {
                try? await Task.sleep(nanoseconds: UInt64(0.5 * Double(NSEC_PER_SEC)))
                AppState.shared.showToast(title: "Failed To Save", subtitle: "Date was missing", body: "", symbol: "exclamationmark.triangle", symbolColor: .orange)
            }
            return false
        }
        
        
        /// If there is no changes
        if !trans.hasChanges() && trans.action != .delete {
            print("-- \(#function) -- No changed detected")
            LogManager.log("No changed detected")
            return false
            
        /// nothing, assumed mistake
        } else if trans.title.isEmpty || trans.payMethod == nil {
            print("-- \(#function) -- Title or payment method missing 2")
            return false
        }
        
        return true
    }
  
    
    func saveTransactionFromEvent(eventTrans: CBEventTransaction, relatedID: String) {
        print("-- \(#function) -- \(eventTrans.title) - \(eventTrans.id)")
        
        /// Create a placeholder(maybe) realTrans.
        /// This will be replaced with an actual realTrans if it already exists in the current model.
        var trans: CBTransaction = CBTransaction(eventTrans: eventTrans, relatedID: relatedID)
        
        /// Check if the realTrans exists in the current model.
        let doesExist = doesTransactionExist(with: relatedID)
        
        /// If the realTrans exists in the current model.
        if doesExist {
            /// Replace the realTrans placeholder with the found trans.
            trans = getTransaction(by: relatedID)
            trans.action = eventTrans.actionForRealTransaction!
            
            /// Make the realTrans action the same as the eventTrans and do logic.
            switch trans.action {
            case .add:
                print("ADD1")
                /// This won't do anything else because if you're adding, the realTrans will not exist, so this entire code block won't run.
                break
                
            case .edit:
                print("EDIT1")
                /// Create deepCopy so we can check for date changes.
                trans.deepCopy(.create)
                /// Update the realTrans with the properties from the eventTrans.
                trans.setFromEventInstance(eventTrans: eventTrans)
                /// Change the date if applicable.
                if trans.dateChanged() {
                    print("Date changed")
                    changeDate(trans)
                    
                } else {
                    print("date did not change")
                }
                
            case .delete:
                print("DELETE1")
                /// Remove the realTrans from the day.
                
                if let targetMonth = months.filter({ $0.actualNum == trans.dateComponents?.month && $0.year == trans.dateComponents?.year }).first {
                    /// Find the day of the eventTrans.
                    if let targetDay = targetMonth.days.filter({ $0.dateComponents?.day == trans.date?.day }).first {
                        targetDay.remove(trans)
                        let _ = calculateTotal(for: sMonth)
                        eventTrans.relatedTransactionID = nil
                    }
                }
            }
                                    
        } else /*The realTrans does not exist locally.*/ {
            /// Find the month of the eventTrans.
            if let targetMonth = months.filter({ $0.actualNum == eventTrans.dateComponents?.month && $0.year == eventTrans.dateComponents?.year }).first {
                /// Find the day of the eventTrans.
                if let targetDay = targetMonth.days.filter({ $0.dateComponents?.day == eventTrans.date?.day }).first {
                    
                    switch trans.action {
                    case .add:
                        print("ADD2")
                        /// Add the placeholder trans to the target day.
                        targetDay.upsert(trans)
                        
                    case .edit:
                        print("EDIT2")
                        /// Create deepCopy so we can check for date changes.
                        trans.deepCopy(.create)
                        
                        /// Update the realTrans with the properties from the eventTrans.
                        trans.setFromEventInstance(eventTrans: eventTrans)
                        
                        /// When bringing a transaction from a different year into the current year.
                        if !targetDay.isExisting(trans) {
                            targetDay.upsert(trans)
                        }
                        
                        /// Change the date if applicable.
                        if trans.dateChanged() { changeDate(trans) }
                        
                    case .delete:
                        print("DELETE2")
                        /// Remove the realTrans from the day.
                        targetDay.removeTransaction(by: relatedID)
                        eventTrans.relatedTransactionID = nil
                    }
                
                } else {
                    print("cannot find target day")
                }
            } else {
                print("cannot find target month")
            }
        }
        
        /// Run the networking code. I'm using this seperate task instance since `submit(_ trans: CBTransaction)` has a bunch of extra logic that I don't need.
        Task {
            //let _ = await submit(trans)
            print("Trans ID \(trans.id) is headed to the server with an action key of \(trans.action)")
                        
            #if os(iOS)
            var backgroundTaskID: UIBackgroundTaskIdentifier?
            backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "Update Transactions") {
                UIApplication.shared.endBackgroundTask(backgroundTaskID!)
                backgroundTaskID = .invalid
            }
            #endif

            /// Starts the spinner after 2 seconds
            startDelayedLoadingSpinnerTimer()
            print("-- \(#function)")

            isThinking = true

            var isNew = false
            /// If the trans is new, set the flag, but put it in edit mode so the coredata trans gets prooperly updated.
            if trans.action == .add {
                isNew = true
                trans.action = .edit
            }
            
            LogManager.log()
            let model = RequestModel(requestType: isNew ? TransactionAction.add.serverKey : trans.action.serverKey, model: trans)
                            
            /// Do Networking.
            typealias ResultResponse = Result<ParentChildIdModel?, AppError>
            async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                        
            switch await result {
            case .success(let model):
                LogManager.networkingSuccessful()
                                
                if isNew {
                    trans.id = String(model?.parentID.id ?? "0")
                    trans.uuid = nil
                    trans.action = .edit
                    
                    eventTrans.relatedTransactionID = trans.id
                }
                                                
                isThinking = false
                
                /// At this point, in the future the trans will always be in edit mode unless it was deleted.
                trans.action = .edit
                            
                print("✅Transaction \(trans.id) - \(trans.title) from event successfully saved")
                /// Cancel the loading spinner if it hasn't started, otherwise hide it,
                stopDelayedLoadingSpinnerTimer()
                
                
                /// End the background task.
                #if os(iOS)
                UIApplication.shared.endBackgroundTask(backgroundTaskID!)
                backgroundTaskID = .invalid
                #endif
                
                /// Return successful save result to the caller.
                return true
                
            case .failure(let error):
                print("Transaction failed to save")
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to save the transaction. Will try again at a later time.")
                //trans.deepCopy(.restore)

                isThinking = false
                trans.action = .edit
                
                /// Cancel the loading spinner if it hasn't started, otherwise hide it,
                stopDelayedLoadingSpinnerTimer()
                
                /// End the background task.
                #if os(iOS)
                UIApplication.shared.endBackgroundTask(backgroundTaskID!)
                backgroundTaskID = .invalid
                #endif
                
                /// Return unsuccessful save result to the caller.
                return false
            }
        }
    }
    
    
    func saveTransaction(id: String, day: CBDay? = nil, location: WhereToLookForTransaction = .normalList, eventModel: EventModel? = nil) {
        self.transEditID = nil
        cleanTags()
        //hilightTrans = nil
                
        let trans = getTransaction(by: id, from: location)
        print("-- \(#function) id: \(id) - looking in \(location) - \(trans.title) - \(trans.id)")
        
        
//        if location == .eventList {
//            
//            
//            if let targetMonth = months.filter({ $0.actualNum == trans.dateComponents?.month && $0.year == trans.dateComponents?.year }).first {
//                if let targetDay = targetMonth.days.filter({ $0.dateComponents?.day == trans.date?.day }).first {
//                    let exists = !targetDay.transactions.filter { $0.id == trans.id }.isEmpty
//                    if !exists && trans.action == .add {
//                        targetDay.upsert(trans)
//                        
//                    } else if exists && trans.action == .delete {
//                        targetDay.remove(trans)
//                    }
//                } else {
//                   print("cant find target day \(trans.title)")
//                }
//            } else {
//                print("cant find target month \(trans.title)")
//            }
//            
//            
//            eventTransactions.removeAll(where: { $0.id == id })
//            
//        } else
        
        if location == .smartList || location == .searchResultList {
            /// Go update the normal transaction list if the editing transaction is not already in it.
            self.handleTransactions([trans], refreshTechnique: nil)
        }
        
        if transactionIsValid(trans: trans, day: day) {
            print("✅ Trans is valid to save")
            /// Set the updated by user and date
            trans.updatedBy = AppState.shared.user!
            trans.updatedDate = Date()
            
            /// Move the transaction if applicable
            if trans.dateChanged() { changeDate(trans) }
                        
            if trans.action == .delete {
                /// Check if the transaction has a related ID (like from a transfer or payment)
                if trans.relatedTransactionID != nil && trans.relatedTransactionType == XrefModel.getItem(from: .relatedTransactionType, byEnumID: .transaction) {
                    let trans2 = getTransaction(by: trans.relatedTransactionID!, from: .normalList)
                    
                    print("HERE2")
                    
                    self.delete(trans)
                    self.delete(trans2)
                } else {
                    print("HERE1")
                    self.delete(trans, eventModel: eventModel)
                }
                
            } else {
                /// Recalculate totals for each day
                Task { let _ = calculateTotal(for: sMonth) }
                
                let toastLingo = "Successfully \(trans.action == .add ? "Added" : "Updated")"
                
                /// Check if the transaction has a related ID (like from a transfer or payment)
                /// This will not handle event transactions!
                if trans.relatedTransactionID != nil
                && trans.action != .add
                && trans.relatedTransactionType == XrefModel.getItem(from: .relatedTransactionType, byEnumID: .transaction) {
                                        
                    let trans2 = getTransaction(by: trans.relatedTransactionID!, from: .normalList)
                    trans2.deepCopy(.create)
                    trans2.updatedBy = AppState.shared.user!
                    trans2.updatedDate = Date()
                    
                    /// Update the linked date
                    if trans.dateChanged() {
                        trans2.date = trans.date
                        changeDate(trans2)
                    }
                    
                    /// Update the dollar amounts accordingly
                    let useWholeNumbers = LocalStorage.shared.useWholeNumbers
                    if trans.payMethod?.accountType != .credit {
                        if trans2.payMethod?.accountType == .credit {
                            trans2.amountString = (trans.amount * 1).currencyWithDecimals(useWholeNumbers ? 0 : 2)
                        } else {
                            trans2.amountString = (trans.amount * -1).currencyWithDecimals(useWholeNumbers ? 0 : 2)
                        }
                        
                    } else {
                        if trans2.payMethod?.accountType == .credit {
                            trans2.amountString = (trans.amount * -1).currencyWithDecimals(useWholeNumbers ? 0 : 2)
                        } else {
                            trans2.amountString = (trans.amount * 1).currencyWithDecimals(useWholeNumbers ? 0 : 2)
                        }
                    }
                    
                    /// Submit to the server
                    Task {
                        await withTaskGroup(of: Void.self) { group in
                            group.addTask { let _ = await self.submit(trans) }
                            group.addTask { let _ = await self.submit(trans2) }
                        }
                        
                        if sPayMethod?.accountType == .checking || sPayMethod?.accountType == .cash {
                            if trans.payMethod?.accountType != .checking && trans.payMethod?.accountType != .cash {
                                NotificationManager.shared.sendNotification(title: toastLingo, subtitle: trans.title, body: trans.amountString)
                            }
                        } else {
                            if trans.payMethod?.accountType == .checking && trans.payMethod?.accountType == .cash {
                                NotificationManager.shared.sendNotification(title: toastLingo, subtitle: trans.title, body: trans.amountString)
                            }
                        }
                    }
                    
                    
                    
                } else {
                    Task { @MainActor in
                        trans.actionBeforeSave = trans.action
                        /// If we filter transactions by category or by payment method, and change it on the transaction, we need the line below to cause the transaction to disapear when closing it.
                        /// The transaction filter function that provides the views with the transactions looks for both the transaction and it's deep copy. When chaning a category for example, the trans will remain due to the deep copy still having the old reference.
                        trans.deepCopy(.clear)
                        
                        let _ = await submit(trans)
                        showToastsForTransactionSave(showSmartTransAlert: location == .smartList, trans: trans)
                        self.handleSavingOfEventTransaction(trans: trans, eventModel: eventModel)
                    }
                }
                
                
                if location == .smartList {
                    tempTransactions.removeAll(where: {$0.id == trans.id})
                }
                
            }
        } else {
            print("❌ Trans is not valid to save")
        }
    }
    
    
    private func handleSavingOfEventTransaction(trans: CBTransaction, eventModel: EventModel? = nil) {
        
        
//        if trans.relatedTransactionID != nil {
//            print("🌧️trans related ID is not nil")
//        }
//        
//        if trans.actionBeforeSave != .add {
//            print("🌧️action is right - currently \(trans.actionBeforeSave)")
//        } else {
//            print("🌧️action is NOT right - currently \(trans.actionBeforeSave)")
//        }
//        
//        
//        if trans.relatedTransactionType == XrefModel.getItem(from: .relatedTransactionType, byEnumID: .eventTransaction) {
//            print("🌧️related type is right")
//        }
//        if eventModel != nil {
//            print("🌧️event model is not nil")
//        }
//            
        
        
        /// See if there is an event that needs to be updated.
        if trans.relatedTransactionID != nil
        && trans.actionBeforeSave != .add
        && trans.relatedTransactionType == XrefModel.getItem(from: .relatedTransactionType, byEnumID: .eventTransaction)
        && eventModel != nil
        {
            print("Processing event transaction update...")
            if let eventModel, let relatedID = trans.relatedTransactionID {
                /// Go find eventTrans.
                if eventModel.doesTransactionExist(with: relatedID) {
                    if let index = eventModel.getTransactionIndex(for: relatedID) {
                        /// Update the eventTrans.
                        let eventTrans = eventModel.justTransactions[index]
                        eventTrans.setFromTransactionInstance(transaction: trans)
                        
                        switch trans.actionBeforeSave {
                        case .add:
                            eventTrans.action = .add
                        case .edit:
                            eventTrans.action = .edit
                        case .delete:
                            eventTrans.action = .delete
                        }
                        
                        /// Save the event to the server.
                        if let event = eventModel.getEventThatContainsTransaction(transactionID: eventTrans.id) {
                            Task {
                                
                                if eventTrans.action == .delete {
                                    event.deleteTransaction(id: eventTrans.id)
                                }
                                
                                let _ = await eventModel.submit(event)
                            }
                        }
                    }
                }
            }
        } else {
            print("NOT Processing event transaction update...")
        }
    }
    
    
    private func showToastsForTransactionSave(showSmartTransAlert: Bool, trans: CBTransaction) {
        let toastLingo = "Successfully \(trans.action == .add ? "Added" : "Updated")"
        
        if showSmartTransAlert {
            AppState.shared.showToast(
                title: "Successfully Added \(trans.title)",
                subtitle: "\(trans.date?.string(to: .monthDayShortYear) ?? "Date: N/A")",
                body: "\(trans.payMethod?.title ?? "N/A")\n\(trans.amountString)",
                symbol: "creditcard"
            )
        } else {
            if sPayMethod?.accountType == .unifiedChecking {
                if trans.payMethod?.accountType != .checking && trans.payMethod?.accountType != .cash {
                    //NotificationManager.shared.sendNotification(title: "Successfully Added", subtitle: trans.title, body: trans.amountString)
                    AppState.shared.showToast(title: toastLingo, subtitle: trans.title, body: trans.amountString, symbol: "creditcard")
                }
            } else if sPayMethod?.accountType == .unifiedCredit {
                if trans.payMethod?.accountType == .checking && trans.payMethod?.accountType == .cash {
                    //NotificationManager.shared.sendNotification(title: "Successfully Added", subtitle: trans.title, body: trans.amountString)
                    AppState.shared.showToast(title: toastLingo, subtitle: trans.title, body: trans.amountString, symbol: "creditcard")
                }
            } else {
                if sPayMethod?.accountType != trans.payMethod?.accountType {
                    //NotificationManager.shared.sendNotification(title: "Successfully Added", subtitle: trans.title, body: trans.amountString)
                    AppState.shared.showToast(title: toastLingo, subtitle: trans.title, body: trans.amountString, symbol: "creditcard")
                }
            }
        }
    }
    
    

    var showLoadingSpinner = false
    var loadingSpinnerTimer: Timer?
    @objc func showLoadingSpinnerViaTimer() {
        showLoadingSpinner = true
    }
    
    func startDelayedLoadingSpinnerTimer() {
        //print("-- \(#function)")
        if loadingSpinnerTimer != nil {
            loadingSpinnerTimer = Timer(fireAt: Date.now.addingTimeInterval(2), interval: 0, target: self, selector: #selector(showLoadingSpinnerViaTimer), userInfo: nil, repeats: false)
            RunLoop.main.add(loadingSpinnerTimer!, forMode: .common)
        }        
    }
    
    func stopDelayedLoadingSpinnerTimer() {
        //print("-- \(#function)")
        if let loadingSpinnerTimer = self.loadingSpinnerTimer {
            loadingSpinnerTimer.invalidate()
        }
        if showLoadingSpinner {
            showLoadingSpinner = false
        }
        
    }
    
    /// Only called from `funcModel.downloadEverything()`.
    /// Only here to allow `self.submit()` to be private.
    func saveTemp(trans: CBTransaction) async {
        let _ = await submit(trans)
    }
    
    /// Only called via `saveTransaction(id: day:)` or `saveTemp(trans:)`.
    @MainActor
    private func submit(_ trans: CBTransaction) async -> Bool {
        print("-- \(#function)")
        print("Submitting Trans \(trans.id)")
        /// Allow the transaction more time to save if the user enters the background.
        #if os(iOS)
        var backgroundTaskID: UIBackgroundTaskIdentifier?
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "Update Transactions") {
            UIApplication.shared.endBackgroundTask(backgroundTaskID!)
            backgroundTaskID = .invalid
        }
        #endif
        
        /// Starts the spinner after 2 seconds
        startDelayedLoadingSpinnerTimer()
        LoadingManager.shared.startLongNetworkTimer()
        
        isThinking = true
        
//        var isNew = false
//        /// If the trans is new, set the flag, but put it in edit mode so the coredata trans gets properly updated.
//        if trans.action == .add {
//            isNew = true
//            trans.action = .edit
//        }
        
        /// Add a temporary transaction to coredata (For when the app was already loaded, but you went back to it after entering an area of bad network connection)
        /// This way, if you add a transaction in an area of bad connection, the trans won't be lost when you try and save it.
        guard let entity = await DataManager.shared.getOne(type: TempTransaction.self, predicate: .byId(.string(trans.id)), createIfNotFound: true) else { return false }
        entity.id = trans.id
        entity.title = trans.title
        entity.amount = trans.amount
        entity.payMethodID = trans.payMethod?.id ?? "0"
        entity.categoryID = trans.category?.id ?? "0"
        entity.date = trans.date
        entity.notes = trans.notes
        entity.hexCode = trans.color.toHex()
        //entity.hexCode = trans.color.description
        //entity.tags = trans.tags
        entity.enteredDate = trans.enteredDate
        entity.updatedDate = trans.updatedDate
        //entity.pictures = trans.pictures
        entity.factorInCalculations = trans.factorInCalculations
        entity.notificationOffset = Int64(trans.notificationOffset ?? 0)
        entity.notifyOnDueDate = trans.notifyOnDueDate
        //entity.action = isNew ? "add" : trans.action.rawValue
        entity.action = trans.action.rawValue
        entity.tempAction = trans.action == .add ? "edit" : trans.action.rawValue
        entity.isPending = true
        let _ = await DataManager.shared.save()
        
        //self.tempTransactions.append(trans)
        
        LogManager.log()
        let model = RequestModel(requestType: trans.action.serverKey, model: trans)
            
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        /// Do Networking.
        typealias ResultResponse = Result<ParentChildIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager(timeout: 10).singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            
            //tempTransactions.removeAll(where: {$0.id == trans.id})
            let _ = await DataManager.shared.delete(type: TempTransaction.self, predicate: .byId(.string(trans.id)))
            //print("Deleting transaction from coredata \(deleteResult)")
            
//            if isNew {
//                /// If a new transaction, update it with its new DBID.
//                if trans.isFromCoreData {
//                    let actualTrans = justTransactions.first(where: { $0.id == trans.id })
//                    if let actualTrans {
//                        actualTrans.id = String(model?.parentID ?? "0")
//                        actualTrans.uuid = nil
//                        actualTrans.action = .edit
//                    }
//                } else {
//                    trans.id = String(model?.parentID ?? "0")
//                    trans.uuid = nil
//                    trans.action = .edit
//                }
//            }
            
            if trans.isFromCoreData {
                let actualTrans = justTransactions.first(where: { $0.id == trans.id })
                if let actualTrans {
                    actualTrans.id = String(model?.parentID.id ?? "0")
                    actualTrans.uuid = nil
                    actualTrans.action = .edit
                }
            } else {
                trans.id = String(model?.parentID.id ?? "0")
                trans.uuid = nil
                trans.action = .edit
            }
            
            
            
            
            /// Updated any tags / locations that were added for the first time via this transaction with their new DBID.
            for each in model?.childIDs ?? [] {
                if each.type == "tag" {
                    let index = tags.firstIndex(where: { $0.uuid == each.uuid })
                    if let index {
                        tags[index].id = String(each.id)
                    }
                } else if each.type == "transaction_location" {
                    let index = trans.locations.firstIndex(where: { $0.uuid == each.uuid })
                    if let index {
                        trans.locations[index].id = String(each.id)
                    }
                }
                
            }
            
            isThinking = false
            
            /// At this point, in the future the trans will always be in edit mode unless it was deleted.
            trans.action = .edit
            
            /// Clear the logs since they will be refetched live when trying to view the transaction again. (Prevents dupes).
            trans.logs.removeAll()
                        
            print("✅Transaction successfully saved")
            /// Cancel the loading spinner if it hasn't started, otherwise hide it,
            stopDelayedLoadingSpinnerTimer()
            
            
            /// End the background task.
            #if os(iOS)
            UIApplication.shared.endBackgroundTask(backgroundTaskID!)
            backgroundTaskID = .invalid
            #endif
            
            
            
            if LoadingManager.shared.showLongNetworkTaskToast {
                AppState.shared.showToast(title: "Transaction Successfully Saved", subtitle: "Maybe the network doesn't suck", body: nil, symbol: "checkmark", symbolColor: .green)
            }
            
            LoadingManager.shared.stopLongNetworkTimer()
            
            NotificationCenter.default.post(name: .updateCategoryAnalytics, object: nil, userInfo: nil)
            
            /// Return successful save result to the caller.
            return true
            
        case .failure(let error):
            print("❌Transaction failed to save")
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to save the transaction. Will try again at a later time.")
            //trans.deepCopy(.restore)

            isThinking = false
            trans.action = .edit
            
            /// Cancel the loading spinner if it hasn't started, otherwise hide it,
            stopDelayedLoadingSpinnerTimer()
            LoadingManager.shared.stopLongNetworkTimer()
            
            /// End the background task.
            #if os(iOS)
            UIApplication.shared.endBackgroundTask(backgroundTaskID!)
            backgroundTaskID = .invalid
            #endif
            
            /// Return unsuccessful save result to the caller.
            return false
        }
    }
    
    
    /// Only called via `saveTransaction(id: day:)`.
    private func delete(_ trans: CBTransaction, eventModel: EventModel? = nil) {
        print("-- \(#function)")
        trans.action = .delete
        trans.actionBeforeSave = trans.action
        withAnimation {
            let day = sMonth.days.filter { $0.dateComponents?.day == trans.dateComponents?.day }.first
            if let day {
                day.remove(trans)
                let _ = calculateTotal(for: sMonth)
            }
                        
            tempTransactions.removeAll {$0.id == trans.id}
        }
           
        Task { @MainActor in
            let _ = await submit(trans)
            self.handleSavingOfEventTransaction(trans: trans, eventModel: eventModel)
        }
    }
    
    
    
    @MainActor
    func addMultiple(trans: Array<CBTransaction>, budgets: Array<CBBudget>, isTransfer: Bool) async {
        
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        
        let repModel = RepeatingAndBudgetSubmissionModel(month: sMonth.actualNum, year: sMonth.year, transactions: trans, budgets: budgets, isTransfer: isTransfer)
        let model = RequestModel(requestType: "add_populated_transactions_and_budgets", model: repModel)
        
        typealias ResultResponse = Result<Array<ReturnIdModel>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            if let model {
                
                //var transferTransactions: Array<CBTransaction> = []
                for idModel in model {
                    let type = idModel.type
                    
                    let targetMonth = months.filter { $0.enumID == sMonth.enumID }.first!
                    
                    if type == "transaction" {
                        //print("TYPE IS TRANSACTION - isTransfer \(isTransfer)")
                        let targetDays = targetMonth.days
                        let transactions = targetDays.flatMap({ $0.transactions })
                                                                        
                        let index = transactions.firstIndex(where: { $0.id == idModel.uuid ?? "" })
                        if let index {
                            transactions[index].id = String(idModel.id)
                            if let relatedID = idModel.relatedID {
                                transactions[index].relatedTransactionID = String(relatedID)
                            }
                            
                            //transactions[index].id = String(model?.transactionID ?? "0")
                            transactions[index].uuid = nil
                            transactions[index].action = .edit
                            
//                            if isTransfer {
//                                transferTransactions.append(transactions[index])
//                            }
                            
                        }
                    } else {
                        let index = targetMonth.budgets.firstIndex(where: { $0.id == idModel.uuid })
                        if let index {
                            targetMonth.budgets[index].id = idModel.id
                        }
                    }
                }
                
                
//                if isTransfer {
//                    transferTransactions[0].relatedTransactionID = transferTransactions[1].id
//                    transferTransactions[1].relatedTransactionID = transferTransactions[0].id
//                }
                
                
            }
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to save the starting amount.")
            //showSaveAlert = true
            #warning("Undo behavior")
            //let listActivity = activities.filter { $0.id == activity.id }.first ?? DailyActivity.emptyActivity
            //listActivity.deepCopy(.restore)
        }
        //LoadingManager.shared.stopDelayedSpinner()
        //self.refreshTask = nil
        
    }
    
    
    @MainActor
    func editMultiple(trans: Array<CBTransaction>) async {
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        
        let multiModel = MultiTransactionSubmissionModel(transactions: trans)
        let model = RequestModel(requestType: "alter_multiple_transactions", model: multiModel)
        
        typealias ResultResponse = Result<Array<ParentChildIdModel>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            if let model {
                print("Multi-update successful")
            }
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to save the starting amount.")
            #warning("Undo behavior")
        }
    }
    
    
    
    
    
    
    @MainActor
    func denyFitTransaction(_ trans: CBFitTransaction) async {
        print("-- \(#function)")
        
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        let model = RequestModel(requestType: "deny_fit_transaction", model: trans)
            
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to deny the fit transaction.")
            #warning("Undo behavior")
        }
        //LoadingManager.shared.stopDelayedSpinner()
    }
    
    
    @MainActor
    func denySmartTransaction(_ trans: CBTransaction) async {
        print("-- \(#function)")
        
        tempTransactions.removeAll(where: {$0.id == trans.id})
        
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        let model = RequestModel(requestType: "deny_smart_transaction", model: trans)
            
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to deny the smart transaction.")
            #warning("Undo behavior")
        }
        //LoadingManager.shared.stopDelayedSpinner()
    }
    
    
    
    
    
    func createCopy(of transaction: CBTransaction) {
        print("-- \(#function)")
        #warning("Update when adding new properties to CBTransaction")
        let trans = CBTransaction(uuid: UUID().uuidString)
        
        trans.title = transaction.title
        trans.amountString = transaction.amountString
        trans.date = transaction.date
        trans.payMethod = transaction.payMethod
        trans.category = transaction.category
        trans.notes = transaction.notes
        trans.factorInCalculations = transaction.factorInCalculations
        trans.color = transaction.color
        trans.tags = transaction.tags
        trans.notificationOffset = transaction.notificationOffset
        trans.notifyOnDueDate = transaction.notifyOnDueDate
        //trans.pictures = transaction.pictures
        self.transactionToCopy = trans
    }
    
    
    func getCopyOfTransaction() -> CBTransaction? {
        #warning("Update when adding new properties to CBTransaction")
        if let transactionToCopy {
            let trans = CBTransaction(uuid: UUID().uuidString)
            trans.title = transactionToCopy.title
            trans.amountString = transactionToCopy.amountString
            trans.date = transactionToCopy.date
            trans.payMethod = transactionToCopy.payMethod
            trans.category = transactionToCopy.category
            trans.notes = transactionToCopy.notes
            trans.factorInCalculations = transactionToCopy.factorInCalculations
            trans.action = .add
            trans.color = transactionToCopy.color
            trans.tags = transactionToCopy.tags
            trans.notifyOnDueDate = transactionToCopy.notifyOnDueDate
            return trans
        }
        return nil
    }
        
    // MARK: - Fit Trans
    func doesExist(_ trans: CBFitTransaction) -> Bool {
        return !fitTrans.filter { $0.id == trans.id }.isEmpty
    }        
    
    func upsert(_ trans: CBFitTransaction) {
        if !doesExist(trans) {
            fitTrans.append(trans)
        }
    }
    
    func getIndex(for trans: CBFitTransaction) -> Int? {
        return fitTrans.firstIndex { $0.id == trans.id }
    }
    
    func delete(_ trans: CBFitTransaction) {
        fitTrans.removeAll { $0.id == trans.id }
    }
    
    
    // MARK: - Budget Stuff
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
    
    
    @MainActor
    func submit(_ budget: CBBudget) async {
        print("-- \(#function)")
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        let model = RequestModel(requestType: budget.action.serverKey, model: budget)
            
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        typealias ResultResponse = Result<ReturnIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
                        
            if budget.action == .add {                
                budget.id = model?.id ?? "0"
                budget.uuid = nil
                budget.action = .edit
            }
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to save the repeating transaction.")
            #warning("Undo behavior")
        }
        //LoadingManager.shared.stopDelayedSpinner()
    }
    
    
//    func delete(_ budget: CBBudget) async {
//        budget.action = .delete
//        budgets.removeAll { $0 == budget }
//        
//        await submit(budget)
//    }
    
    
    
    
    
    // MARK: - Starting Amount Stuff
    
    /// Handle the submission of new starting amounts with this timer..
    /// Called via ``CalendarToolbarLeading`` `.onChange(of: calendarModel.sMonth.startingAmounts.filter { $0.payMethod.id == calendarModel.sPayMethod?.id }.first?.amountString)`
//    var startingAmountSubmitTimer: Timer?
//    
//    @objc func submitStartingAmountViaTimer() {
//        Task {
//            let start = sMonth.startingAmounts.filter { $0.payMethod.id == sPayMethod?.id && ($0.payMethod.accountType != .unifiedChecking && $0.payMethod.accountType != .unifiedCredit) }.first
//            if let start {
//                await submit(start)
//            }
//        }
//    }
//    
//    func startDelayedStartingAmountTimer() {
//        startingAmountSubmitTimer = Timer(fireAt: Date.now.addingTimeInterval(2), interval: 0, target: self, selector: #selector(submitStartingAmountViaTimer), userInfo: nil, repeats: false)
//        if let startingAmountSubmitTimer {
//            RunLoop.main.add(startingAmountSubmitTimer, forMode: .common)
//        }
//    }
//    
//    func stopDelayedStartingAmountTimer() {
//        if let startingAmountSubmitTimer = self.startingAmountSubmitTimer {
//            startingAmountSubmitTimer.invalidate()
//        }
//    }
    
    /// For Mac.
//    func prepareStartingAmount() {
//        /// Called via  ``setSelectedMonthFromNavigation(navID:prepareStartAmount:)`` which is called via `.onChange(of: navManager.selection)` in ``RootView``
//        /// Called via `self.sPayMethod.didSet{}`
//        
//        print("-- \(#function)")
//        //print(sPayMethod?.title ?? "No Method selected")
//        if !sMonth.startingAmounts.contains(where: { $0.payMethod.id == sPayMethod?.id }) {
//            print("Creating Starting Amount Model for \(sPayMethod?.title ?? "No Method selected") for Month \(self.sMonth.num) \(self.sYear)")
//            //print("🔴IT DOES NOT CONTAINS")
//            let starting = CBStartingAmount()
//            
//            if let sPayMethod = self.sPayMethod {
//                //print("🔴PAY METH GOOD")
//                starting.payMethod = sPayMethod
//                starting.action = .add
//                starting.month = self.sMonth.num
//                starting.year = self.sYear
//                starting.amountString = "$0.00"
//                sMonth.startingAmounts.append(starting)
//                
//            } else {
//                //print("🔴PAY METH BAD")
//            }
//        } else {
//            //print("🔴IT CONTAINS")
//        }
//    }
//    
//    func prepareStartingAmount(for payMethod: CBPaymentMethod?) {
//        /// Called via  ``setSelectedMonthFromNavigation(navID:prepareStartAmount:)`` which is called via `.onChange(of: navManager.selection)` in ``RootView``
//        /// Called via `self.sPayMethod.didSet{}`
//        /// Called via  the button that activates the starting amount sheet in ``CalendarViewPhone``.
//        
//        //print("-- \(#function)")
//        if !sMonth.startingAmounts.contains(where: { $0.payMethod.id == payMethod?.id }) {
//            //print("\(#function) - Creating Starting Amount Model for \(String(describing: payMethod?.title)) for Month \(self.sMonth.num) \(self.sYear)")
//            let starting = CBStartingAmount()
//                        
//            if let payMethod = payMethod {
//                starting.payMethod = payMethod
//                starting.action = .add
//                starting.month = self.sMonth.num
//                starting.year = self.sYear
//                starting.amountString = ""
//                sMonth.startingAmounts.append(starting)
//            }
//        }
//    }
    
    
    
    
    @MainActor
    func submit(_ startingAmount: CBStartingAmount) async {
        print("-- \(#function)")
        print("\(startingAmount.payMethod.title) -- \(startingAmount.amountString) -- \(startingAmount.month) -- \(startingAmount.year) -- \(startingAmount.action.serverKey)")
        //LoadingManager.shared.startDelayedSpinner()
        
        
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
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            /// Get the new ID from the server after adding a new activity.
            if startingAmount.action == .add {
                startingAmount.id = model?.id ?? "0"
                startingAmount.uuid = nil
                startingAmount.action = .edit
            }
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to save the starting amount.")
            //showSaveAlert = true
            #warning("Undo behavior")
            //let listActivity = activities.filter { $0.id == activity.id }.first ?? DailyActivity.emptyActivity
            //listActivity.deepCopy(.restore)
        }
        //LoadingManager.shared.stopDelayedSpinner()
        //self.refreshTask = nil
    }
    
    
    
    
    
    
    // MARK: - Tags
    
    @MainActor
    func fetchTags() async {
        tags.removeAll()
        LogManager.log()

        /// Do networking.
        let model = RequestModel(requestType: "fetch_tags", model: AppState.shared.user)
        typealias ResultResponse = Result<Array<CBTag>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)

        switch await result {
        case .success(let model):

            /// For testing bad network connection.
            //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))

            LogManager.networkingSuccessful()
            
            if let model {
                if !model.isEmpty {
                    for tag in model {
                        let index = tags.firstIndex(where: { $0.id == tag.id })
                        if let index {
                            tags[index].setFromAnotherInstance(tag: tag)
                        } else {
                            tags.append(tag)
                        }
                    }
                }
            }

            /// Update the progress indicator.
            //AppState.shared.downloadedData.append(.tags)

        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("fetchTags Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch the tags.")
            }
        }
    }
    
    
    func cleanTags() {
        tags.forEach { tag in
            let count = justTransactions.filter { $0.tags.contains(tag) }.count
            if count == 0 {
                tags.removeAll(where: { $0 == tag })
            }
        }
    }
    
    
    
    // MARK: - Helpers
    
    func prepareForRefresh() {
        months.forEach { month in
            month.days.removeAll()
            month.budgets.removeAll()
            tempTransactions.removeAll()
        }
        prepareMonths()
    }
    
    
    func prepareMonths() {
        months.forEach { month in
            if month.days.count == 0 {
                if month.firstWeekdayOfMonth != 1 {
                    for i in 0 ..< month.firstWeekdayOfMonth - 1 {
                        month.days.append(CBDay(id: i-50))
                    }
                }
                
                for i in 1 ..< month.dayCount + 1 {
                    
                    if month.enumID == .lastDecember {
                        let components = DateComponents(year: sYear-1, month: 12, day: i)
                        let theDate = Calendar.current.date(from: components)!
                        month.days.append(CBDay(date: theDate))
                        
                    } else if month.enumID == .nextJanuary {
                        let components = DateComponents(year: sYear+1, month: 1, day: i)
                        let theDate = Calendar.current.date(from: components)!
                        month.days.append(CBDay(date: theDate))
                        
                    } else {
                        let components = DateComponents(year: sYear, month: month.num, day: i)
                        let theDate = Calendar.current.date(from: components)!
                        //print(theDate)
                        month.days.append(CBDay(date: theDate))
                    }                    
                }
            }
        }
    }
    
    
    func updateUnifiedStartingAmount(month: CBMonth, for unifiedAccountType: AccountType) -> Double {
        /// This is called via `calculateTotal()` and via `PayMethodSheet.task{}`
        var targetAccountTypes: [AccountType]
        if unifiedAccountType == .unifiedCredit {
            targetAccountTypes = [.credit]
        } else {
            targetAccountTypes = [.checking, .cash]
        }
        
        let startingBalance = month.startingAmounts
            .filter { targetAccountTypes.contains($0.payMethod.accountType) }
            .map { $0.amount }
            .reduce(0.0, +)
                                
        let index = month.startingAmounts.firstIndex(where: { $0.payMethod.accountType == unifiedAccountType })
        if let index {
            let useWholeNumbers = LocalStorage.shared.useWholeNumbers
            month.startingAmounts[index].amountString = startingBalance.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        }
        
        return startingBalance
    }
    
    
    enum DoWhatWhenCalculating { case updateEod, giveMeLastDayEod }
    
    func calculateTotal(for month: CBMonth, using paymentMethod: CBPaymentMethod? = nil, and doWhat: DoWhatWhenCalculating = .updateEod) -> Double {
        var theMethod: CBPaymentMethod?
        if paymentMethod == nil {
            theMethod = sPayMethod
        } else {
            theMethod = paymentMethod
        }

        if theMethod?.accountType == .unifiedChecking {
            return calculateUnifiedChecking(for: month, and: doWhat)
            
        } else if theMethod?.accountType == .unifiedCredit {            
            return calculateUnifiedCredit(for: month, and: doWhat)
                                                
        } else if theMethod?.accountType == .credit {
            return calculateCredit(for: month, using: theMethod, and: doWhat)
            
        } else {
            return calculateChecking(for: month, using: theMethod, and: doWhat)
        }
    }
    
    
    private func calculateUnifiedChecking(for month: CBMonth, and doWhat: DoWhatWhenCalculating) -> Double {
        var finalEodTotal: Double = 0.0
        let startingBalance = updateUnifiedStartingAmount(month: month, for: .unifiedChecking)
        var currentAmount = startingBalance
        
        month.days.forEach { day in
            let amounts = day.transactions
                .filter { $0.payMethod?.accountType == .checking || $0.payMethod?.accountType == .cash }
                .filter { $0.active }
                .filter { $0.factorInCalculations == true }
                .map { $0.amount }
            
            currentAmount += amounts.reduce(0.0, +)
            switch doWhat {
            case .updateEod:
                day.eodTotal = currentAmount
                
            case .giveMeLastDayEod:
                if day.id == month.days.last?.id {
                    finalEodTotal = currentAmount
                }
            }
        }
        return finalEodTotal
    }
    
    
    private func calculateUnifiedCredit(for month: CBMonth, and doWhat: DoWhatWhenCalculating) -> Double {
        let creditEodView = CreditEodView.fromString(UserDefaults.standard.string(forKey: "creditEodView") ?? "")
        
        var finalEodTotal: Double = 0.0
        let startingBalance = updateUnifiedStartingAmount(month: month, for: .unifiedCredit)
        var currentAmount = 0.0
        
        switch creditEodView {
        case .availableCredit:
            /// To show available credit.
            let cumulativeLimits = PayMethodModel.shared
                .paymentMethods
                .filter { $0.accountType == .credit }
                .map { $0.limit ?? 0.0 }
                .reduce(0.0, +)
            
            currentAmount = cumulativeLimits - startingBalance
            
        case .remainingBalance:
            currentAmount = startingBalance
        }
                            
        month.days.forEach { day in
            let amounts = day.transactions
                .filter { $0.payMethod?.accountType == .credit }
                .filter { $0.active }
                .filter { $0.factorInCalculations == true }
                .map { $0.amount }
            
            switch creditEodView {
            case .availableCredit: currentAmount -= amounts.reduce(0.0, +)
            case .remainingBalance: currentAmount += amounts.reduce(0.0, +)
            }
                        
            switch doWhat {
            case .updateEod:
                day.eodTotal = currentAmount
                
            case .giveMeLastDayEod:
                if day.id == month.days.last?.id {
                    finalEodTotal = currentAmount
                }
            }
        }
        return finalEodTotal
    }
    
    
    private func calculateCredit(for month: CBMonth, using paymentMethod: CBPaymentMethod?, and doWhat: DoWhatWhenCalculating) -> Double {
        let creditEodView = CreditEodView.fromString(UserDefaults.standard.string(forKey: "creditEodView") ?? "")
        
        var finalEodTotal: Double = 0.0
        let startingBalance = month.startingAmounts.filter { $0.payMethod.id == paymentMethod?.id }.first
        var currentAmount = 0.0
        
        if let startingBalance {
            switch creditEodView {
            case .availableCredit: currentAmount = (paymentMethod?.limit ?? 0.0) - startingBalance.amount
            case .remainingBalance: currentAmount = startingBalance.amount
            }
            
            month.days.forEach { day in
                let amounts = day.transactions
                    .filter { $0.payMethod?.id == paymentMethod?.id }
                    .filter { $0.active }
                    .filter { $0.factorInCalculations == true }
                    .map { $0.amount }
                
                switch creditEodView {
                case .availableCredit: currentAmount -= amounts.reduce(0.0, +)
                case .remainingBalance: currentAmount += amounts.reduce(0.0, +)
                }
                                    
                switch doWhat {
                case .updateEod:
                    day.eodTotal = currentAmount
                    
                case .giveMeLastDayEod:
                    if day.id == month.days.last?.id {
                        finalEodTotal = currentAmount
                    }
                }
            }
        } else {
            print("COULDNT DETERMINE CURRENT BALANCE")
        }
        return finalEodTotal
    }
    
    
    private func calculateChecking(for month: CBMonth, using paymentMethod: CBPaymentMethod?, and doWhat: DoWhatWhenCalculating) -> Double {
        var finalEodTotal: Double = 0.0
        let startingAmount = month.startingAmounts.filter { $0.payMethod.id == paymentMethod?.id }.first ?? CBStartingAmount()
        var currentAmount = startingAmount.amount
        
        month.days.forEach { day in
            let amounts = day.transactions
                .filter { $0.payMethod?.id == paymentMethod?.id }
                .filter { $0.active }
                .filter { $0.factorInCalculations == true }
                .map { $0.amount }
            
            currentAmount += amounts.reduce(0.0, +)
            switch doWhat {
            case .updateEod:
                day.eodTotal = currentAmount
                
            case .giveMeLastDayEod:
                if day.id == month.days.last?.id {
                    finalEodTotal = currentAmount
                }
            }
        }
        return finalEodTotal
    }
    
    
    
    func setSelectedMonthFromNavigation(navID: NavDestination, prepareStartAmount: Bool) {
        //print("-- \(#function)")
        if let month = months.filter({ $0.enumID == navID }).first {
            sMonth = month
            if prepareStartAmount {
                //prepareStartingAmount(for: self.sPayMethod) /// Needed for the mac to show the unified starting amount
                let _ = calculateTotal(for: sMonth) /// Call this to calculate the unified starting amounts
            }
        } else {
            fatalError("Could not determine month")
        }
    }
    
    
    func populate(options: PopulateOptions, repTransactions: Array<CBRepeatingTransaction>, categories: Array<CBCategory>) {
        print("-- \(#function)")
        //let dateFormatter = DateFormatter()
        
        var repTransToServer: Array<CBTransaction> = []
        var budgetsToServer: Array<CBBudget> = []
        
        
        for meth in options.paymentMethods {
            if meth.doIt {
                for repTrans in repTransactions.filter({ $0.payMethod?.id == meth.id }) {
                    let repID = repTrans.id
                    
//                    var monthID = 0
//                    if sMonth.enumID == .nextJanuary {
//                        monthID = 1
//                    } else if sMonth.enumID == .lastDecember {
//                        monthID = 12
//                    } else {
//                        monthID = sMonth.num
//                    }
                                        
                    let isRelevantToSelectedMonth = !repTrans.when.filter({ $0.active && $0.whenType == .month && $0.monthNum == sMonth.actualNum}).isEmpty
                    
                    /// Only if the month checkbox in the repeating is checked.
                    if isRelevantToSelectedMonth {
                        
                        /// Target the currently viewed month.
                        let targetMonth = months.filter { $0.enumID == sMonth.enumID }.first!
                    
                        for when in repTrans.when.filter({ $0.active }) {
                            
                            /// Transactions that have a day of month specifiied.
                            if when.whenType == .dayOfMonth {
                                /// Find the day from the when record.
                                if let targetDay = targetMonth.days.filter({ $0.dateComponents?.day == Int(when.when.replacingOccurrences(of: "day", with: "")) ?? 0 }).first {
                                    /// Make sure transaction was not already added.
                                    let addedTrans = targetDay.transactions.filter { $0.repID == repID }.first
                                    if addedTrans == nil {
                                        if repTrans.repeatingTransactionType.enumID != XrefEnum.regular {
                                            let fromTrans = CBTransaction(
                                                repTrans: repTrans,
                                                date: targetDay.date!,
                                                payMethod: repTrans.payMethod,
                                                amountString: repTrans.amountString
                                            )
                                            
                                            let toTrans = CBTransaction(
                                                repTrans: repTrans,
                                                date: targetDay.date!,
                                                payMethod: repTrans.payMethodPayTo,
                                                amountString: repTrans.amountString
                                            )
                                            
                                            
                                            fromTrans.relatedTransactionID = toTrans.id
                                            fromTrans.relatedTransactionType = XrefModel.getItem(from: .relatedTransactionType, byEnumID: .transaction)
                                            
                                            
                                            
                                            if repTrans.repeatingTransactionType.enumID == XrefEnum.payment {
                                                fromTrans.title = "Payment to \(repTrans.payMethodPayTo?.title ?? "")"
                                            } else {
                                                fromTrans.title = "Transfer to \(repTrans.payMethodPayTo?.title ?? "")"
                                            }
                                            
                                            toTrans.relatedTransactionID = fromTrans.id
                                            toTrans.relatedTransactionType = XrefModel.getItem(from: .relatedTransactionType, byEnumID: .transaction)
                                            
                                            
                                            if repTrans.repeatingTransactionType.enumID == XrefEnum.payment {
                                                toTrans.title = "Payment from \(repTrans.payMethod?.title ?? "")"
                                            } else {
                                                toTrans.title = "Transfer from \(repTrans.payMethod?.title ?? "")"
                                            }
                                            toTrans.isPayment = true
                                            
                                            if fromTrans.isExpense && repTrans.repeatingTransactionType.enumID != XrefEnum.payment {
                                                toTrans.amountString = toTrans.amountString.replacingOccurrences(of: "-", with: "")
                                            }
                                            
                                            
                                            targetDay.transactions.append(fromTrans)
                                            repTransToServer.append(fromTrans)
                                            
                                            targetDay.transactions.append(toTrans)
                                            repTransToServer.append(toTrans)
                                            
                                            
                                        } else {
                                            let newTrans = CBTransaction(
                                                repTrans: repTrans,
                                                date: targetDay.date!,
                                                payMethod: repTrans.payMethod,
                                                amountString: repTrans.amountString
                                            )
                                            targetDay.transactions.append(newTrans)
                                            repTransToServer.append(newTrans)
                                        }
                                        
                                        
                                    }
                                } else {
                                    /// If the day can't be found above, the transaction exists on a day that this month doesn't have (like having a date of the 31st in February).
                                    /// Add to the last day of the month.
                                    if Int(when.when.replacingOccurrences(of: "day", with: "")) ?? 0 > targetMonth.dayCount {
                                        if let targetDay = targetMonth.days.last {
                                            let newTrans = CBTransaction(
                                                repTrans: repTrans,
                                                date: targetDay.date!,
                                                payMethod: repTrans.payMethod,
                                                amountString: repTrans.amountString
                                            )
                                            targetDay.transactions.append(newTrans)
                                            repTransToServer.append(newTrans)
                                        }
                                    }
                                }
                                
                            /// For specific weekdays.
                            } else if when.whenType == .weekday {
                                let weekdays = targetMonth.days
                                    .filter { $0.date != nil }
                                    .filter { AppState.shared.dateFormatter.weekdaySymbols[Calendar.current.component(.weekday, from: $0.date!) - 1].lowercased() == when.when.lowercased() }
                                
                                for weekday in weekdays {
                                    /// Make sure transaction was not already added via the day of the month trigger.
                                    let addedTrans = weekday.transactions.filter { $0.repID == repID }.first
                                    if addedTrans == nil {
                                        let newTrans = CBTransaction(
                                            repTrans: repTrans,
                                            date: weekday.date!,
                                            payMethod: repTrans.payMethod,
                                            amountString: repTrans.amountString
                                        )
                                        weekday.transactions.append(newTrans)
                                        repTransToServer.append(newTrans)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if options.budget {
            for cat in categories {
                let budgetExists = !sMonth.budgets.filter { $0.category?.id == cat.id }.isEmpty
                if !budgetExists {
                    let budget = CBBudget()
                    budget.month = sMonth.actualNum
                    budget.year = sMonth.year
                    budget.amountString = cat.amountString ?? ""
                    budget.category = cat
                    
                    budgetsToServer.append(budget)
                    sMonth.budgets.append(budget)
                }
            }
        }
        
        
        
        if repTransToServer.isEmpty && budgetsToServer.isEmpty {
            return
        }
        
        let _ = calculateTotal(for: sMonth)
        sMonth.hasBeenPopulated = true
        
        Task {
            await addMultiple(trans: repTransToServer, budgets: budgetsToServer, isTransfer: false)
        }
    }
    
    
    func resetMonth(_ resetModel: ResetOptions) {
        resetModel.paymentMethods.forEach { meth in
            if meth.transactions {
                sMonth.days.forEach { $0.transactions.removeAll { $0.payMethod?.id == meth.id } }
            }
            
            if meth.startingAmount {
                sMonth.startingAmounts.removeAll { $0.payMethod.id == meth.id }
            }
        }
                                
        if resetModel.budget { sMonth.budgets.removeAll() }
        if resetModel.hasBeenPopulated { sMonth.hasBeenPopulated = false }
                
        let _ = calculateTotal(for: sMonth)
        
        resetModel.month = sMonth.actualNum
        resetModel.year = sMonth.year
        
        Task {
            LogManager.log()
            
            //let resetModel = ResetMonthModel(month: sMonth.num, year: sYear)
            let model = RequestModel(requestType: "reset_month", model: resetModel)
            
            typealias ResultResponse = Result<ResultCompleteModel?, AppError>
            async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                        
            switch await result {
            case .success:
                LogManager.networkingSuccessful()
                
            case .failure(let error):
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to save the starting amount.")
                //showSaveAlert = true
                #warning("Undo behavior")
                //let listActivity = activities.filter { $0.id == activity.id }.first ?? DailyActivity.emptyActivity
                //listActivity.deepCopy(.restore)
            }
            //LoadingManager.shared.stopDelayedSpinner()
            //self.refreshTask = nil
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    // MARK: - PHOTO STUFF
    /// There's only 3 things that need to be changed to add photo abilities to another project - indicated by a **
    
    /// This is here instead of a flag indicating a smart trans because if I opt to upload a receipt directly from a day's context menu, I set the date on this object.
    //var pendingSmartTransaction: CBTransaction?
    //var chatGptIsThinking = false
    //var showSmartTransactionPayMethodSheet: Bool = false
    //var showSmartTransactionDatePickerSheet: Bool = false
    
    /// SmartTrans abandons this variable immediately after it is set and the upload starts.
    //var pictureTransactionID: String?
    var isUploadingSmartTransactionPicture: Bool = false
    var smartTransactionDate: Date?
        
//    /// This is the photo from the photo library.
//    var imagesFromLibrary: Array<PhotosPickerItem> = []
//    func uploadPicturesFromLibrary() {
//        if imagesFromLibrary.isEmpty { return }
//        alertUploadingSmartReceiptIfApplicable()
//        Task {
//            await withTaskGroup(of: Void.self) { group in
//                for each in imagesFromLibrary {
//                    imagesFromLibrary.removeAll(where: { $0 == each })
//                    group.addTask {
//                        if let imageData = await PhotoModel.prepareDataFromPhotoPickerItem(image: each) {
//                            await self.uploadPhoto(with: imageData)
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    
//    #if os(iOS)
//    /// This is the photo from the camera.
//    var imageFromCamera: UIImage?
//    #endif
//    func uploadPictureFromCamera() {
//        if let imageFromCamera = imageFromCamera, let imageData = PhotoModel.prepareDataFromUIImage(image: imageFromCamera) {
//            Task {
//                await uploadPhoto(with: imageData)
//            }
//            
//        } else {
//            isUploadingSmartTransactionPicture = false
//            smartTransactionDate = nil
//        }
//    }
//    
//    
//    
//    func uploadPhoto(with imageData: Data) async {
//        //calModel.uploadPicture(with: imageData)
//        for await status in PhotoModel.uploadPicture(with: imageData, delegate: self) {
//            switch status {
//            case .performCleanup:
//                cleanUpPhotoVariables()
//                
//            case .readyForPlaceholder(let transactionID, let uuid):
//                if let transactionID = transactionID {
//                    addPlaceholderPicture(recordID: transactionID, uuid: uuid)
//                }
//                
//            case .uploaded:
//                break
//                //calModel.markPlaceholderPictureAsReadyForDownload(recordID: transactionID, uuid: uuid)
//                
//            case .displayCompleteAlert(let transactionID, let uuid):
//                var transTitle: String?
//                if let trans = justTransactions.filter({ $0.id == transactionID }).first {
//                    transTitle = trans.title
//                }
//                
//                if !isUploadingSmartTransactionPicture {
//                    AppState.shared.alertBasedOnScenePhase(
//                        title: "Picture Successfully Uploaded",
//                        subtitle: transTitle,
//                        symbol: "photo.badge.checkmark",
//                        symbolColor: .green,
//                        inAppPreference: .toast
//                    )
//                }
//                
//            case .readyForDownload(let transactionID, let uuid):
//                if let transactionID = transactionID {
//                    markPlaceholderPictureAsReadyForDownload(recordID: transactionID, uuid: uuid)
//                }
//                
//            case .failedToUpload(let transactionID, let uuid):
//                if let transactionID = transactionID {
//                    markPictureAsFailedToUpload(recordID: transactionID, uuid: uuid)
//                }
//                
//            case .done:
//                print("done")
//            }
//        }
//    }
//    
//    
//    func uploadPictureOG(with imageData: Data) async {
//        alertUploadingSmartReceiptIfApplicable()
//        
//        /// Capture the set variable because if you start uploading a picture on a trans, and switch to another trans before the upload completes, you will change the pictureTransactionID before the async task completes.
//        let pictureTransactionID = self.pictureTransactionID
//        let smartTransactionDate = self.smartTransactionDate
//        let isUploadingSmartTransactionPicture = self.isUploadingSmartTransactionPicture
//        
//        /// Clean up the variables so other actions can use them.
//        self.isUploadingSmartTransactionPicture = false
//        self.smartTransactionDate = nil
//        
//        let uuid = UUID().uuidString
//        //alertUploadingSmartReceiptIfApplicable()
//        
//        if !isUploadingSmartTransactionPicture, let pictureTransactionID = pictureTransactionID {
//            addPlaceholderPicture(recordID: pictureTransactionID, uuid: uuid)
//        }
//                
//        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
//        if let _ = await PhotoModel.uploadPicture(
//            imageData: imageData,
//            relatedID: pictureTransactionID, //--> will be nil when uploading a smart receipt.
//            uuid: uuid,
//            isSmartTransaction: isUploadingSmartTransactionPicture,
//            smartTransactionDate: smartTransactionDate,
//            responseType: ResultResponse.self
//        ) {
//            if !isUploadingSmartTransactionPicture, let pictureTransactionID = pictureTransactionID {
//                markPlaceholderPictureAsReadyForDownload(recordID: pictureTransactionID, uuid: uuid)
//            }
//            
//            /// Alert if the transaction has changed, or the user left the app.
//            #if os(iOS)
//            let state = UIApplication.shared.applicationState
//            if pictureTransactionID != self.pictureTransactionID || (state == .background || state == .inactive) {
//                var transTitle: String?
//                if let trans = justTransactions.filter({$0.id == pictureTransactionID}).first {
//                    transTitle = trans.title
//                }
//                
//                if !isUploadingSmartTransactionPicture {
//                    AppState.shared.alertBasedOnScenePhase(
//                        title: "Picture Successfully Uploaded",
//                        subtitle: transTitle,
//                        symbol: "photo.badge.checkmark",
//                        symbolColor: .green,
//                        inAppPreference: .toast
//                    )
//                }
//            }
//            #else
//            if pictureTransactionID != self.pictureTransactionID {
//                AppState.shared.showAlert("Picture Successfully Uploaded")
//            }
//            #endif
//            
//        } else {
//            if !isUploadingSmartTransactionPicture, let pictureTransactionID = pictureTransactionID {
//                markPictureAsFailedToUpload(recordID: pictureTransactionID, uuid: uuid)
//            }
//            AppState.shared.alertBasedOnScenePhase(
//                title: "There was a problem uploading the picture",
//                subtitle: "Please try again.",
//                symbol: "photo",
//                symbolColor: .orange,
//                inAppPreference: .alert
//            )
//        }
//    }
//    
    
    
    func displayCompleteAlert(recordID: String, photoType: XrefItem) {
        var transTitle: String?
        if let trans = justTransactions.filter({ $0.id == recordID }).first {
            transTitle = trans.title
        }
        
        if !isUploadingSmartTransactionPicture {
            AppState.shared.alertBasedOnScenePhase(
                title: "Picture Successfully Uploaded",
                subtitle: transTitle,
                symbol: "photo.badge.checkmark",
                symbolColor: .green,
                inAppPreference: .toast
            )
        }
    }
    
    func alertUploadingSmartReceiptIfApplicable() {
        if self.isUploadingSmartTransactionPicture {
            AppState.shared.showToast(
                title: "Analyzing Receipt",
                subtitle: "You will be alerted when analysis is complete",
                body: "(Powered by ChatGPT)",
                symbol: "brain.fill"
            )
        }
    }
    
    func cleanUpPhotoVariables() {
        self.isUploadingSmartTransactionPicture = false
        self.smartTransactionDate = nil
        #if os(iOS)
        PhotoModel.shared.imageFromCamera = nil
        #endif
    }
    
    
    func addPlaceholderPicture(recordID: String, uuid: String, photoType: XrefItem) {
        let picture = CBPicture(relatedID: recordID, uuid: uuid, photoType: photoType.enumID)
        picture.isPlaceholder = true
        
        let targetMonth = months.filter { $0.enumID == sMonth.enumID }.first!
        let targetDays = targetMonth.days
        let transactions = targetDays.flatMap({ $0.transactions })
                                                        
        let index = transactions.firstIndex(where: { $0.id == recordID })
        if let index {
            if let _ = transactions[index].pictures {
                transactions[index].pictures!.append(picture)
            } else {
                transactions[index].pictures = [picture]
            }
        }
    }
            
    
    func markPlaceholderPictureAsReadyForDownload(recordID: String, uuid: String, photoType: XrefItem) {
        let targetMonth = months.filter { $0.enumID == sMonth.enumID }.first!
        let targetDays = targetMonth.days
        let transactions = targetDays.flatMap({ $0.transactions })
        
        if let trans = transactions.filter({$0.id == recordID}).first {
            let index = trans.pictures?.firstIndex(where: { $0.uuid == uuid })
            if let index {
                trans.pictures?[index].isPlaceholder = false
            }
        }
    }
        
    
    func markPictureAsFailedToUpload(recordID: String, uuid: String, photoType: XrefItem) {
        let targetMonth = months.filter { $0.enumID == sMonth.enumID }.first!
        let targetDays = targetMonth.days
        let transactions = targetDays.flatMap({ $0.transactions })
        
        if let trans = transactions.filter({$0.id == recordID}).first {
            let index = trans.pictures?.firstIndex(where: { $0.uuid == uuid })
            if let index {
                trans.pictures?[index].active = false
            }
        }
    }
    
    
    
    func delete(picture: CBPicture, photoType: XrefItem) async {
        if await PhotoModel.shared.delete(picture) {
            let targetMonth = months.filter { $0.enumID == sMonth.enumID }.first!
            let targetDays = targetMonth.days
            let transactions = targetDays.flatMap({ $0.transactions })
                                                            
            let index = transactions.firstIndex(where: { $0.id == picture.relatedID })
            if let index {
                transactions[index].pictures?.removeAll(where: { $0.id == picture.id || $0.uuid == picture.uuid })
            }
        } else {
            AppState.shared.showAlert("There was a problem trying to delete the picture.")
        }
    }
}
