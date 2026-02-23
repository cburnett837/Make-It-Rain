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
class CalendarModel {
    // MARK: - State Variables
    var isThinking = false
    var showMonth = false
    
    #if os(iOS)
    var isShowingFullScreenCoverOnIpad = false
    #endif
    var categoryFilterWasSetByCategoryPage = false
    var sCategoriesForAnalysis: [CBCategory] = []
    var sCategoryGroupsForAnalysis: [CBCategoryGroup] = []
    var transactionViewHasBeenWarmedUp = false
    var isFirstCalendarLoad = true
    var windowMonth: NavDestination?
    
    var sMonth: CBMonth = CBMonth(num: 1)
    var sYear: Int = AppState.shared.todayYear
    var sPayMethodBeforeFilterWasSetByCategoryPage: CBPaymentMethod?
    var sPayMethod: CBPaymentMethod? {
        didSet {
            let _ = calculateTotal(for: self.sMonth)
        }
    }
    var sCategory: CBCategory?
    var sCategories: [CBCategory] = []
    var isPlayground: Bool { sYear == 1900 }
    var searchText = ""
    var searchWhat = CalendarSearchWhat.titles
    
    var appSuiteBudgets: [CBBudget] = []
    
    
    // MARK: - Visual things
    var transactionToCopy: CBTransaction?
    var transactionIdToCopy: String?
    var dragTarget: CBDay?
    //var hilightTrans: CBTransaction?
    
    var isInMultiSelectMode = false
    var multiSelectTransactions: Array<CBTransaction> = []
    var currentReceiptId: CBTransaction.ID?
    
    
    
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
    var receiptTransactions: [CBTransaction] = []
    var tags: Array<CBTag> = []
    var suggestedTitles: Array<CBSuggestedTitle> = []

    
    
    
    // MARK: - Computed Helper Variables
    var justTransactions: Array<CBTransaction> {
        months.flatMap { $0.days }.flatMap { $0.transactions }
    }
    
    var justBudgets: Array<CBBudget> {
        months.flatMap { $0.budgets }
    }
    
    var isUnifiedPayMethod: Bool {
        self.sPayMethod?.accountType == .unifiedChecking || self.sPayMethod?.accountType == .unifiedCredit
    }
   
    
    
    
    // MARK: - Photo Variables
    var isUploadingSmartTransactionFile: Bool = false
    var smartTransactionDate: Date?
    
    
    
    
    // MARK: - Fetch From Server
    //@MainActor
    nonisolated func fetchFromServer(month: CBMonth, createNewStructs: Bool, refreshTechnique: RefreshTechnique) async {
        print("-- \(#function) \(month.actualNum) \(month.year) -- \(Date())")
        LogManager.log()
        
        let start = CFAbsoluteTimeGetCurrent()
        
        //try? await Task.sleep(for: .seconds(10))
        //print("DONE FETCHING")
                            
        //let month = months.filter { $0.num == monthNum }.first!
        let model = RequestModel(requestType: "fetch_transactions_for_month", model: month)
        typealias ResultResponse = Result<TransactionAndStartingAmountModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            await MainActor.run {
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
                    
//                    if let budgets = model.budgetGroups {
//                        for budget in budgets {
//                            if month.budgetGroups.contains(where: { $0.id == budget.id }) {
//                                let index = month.budgetGroups.firstIndex(where: { $0.id == budget.id })!
//                                month.budgetGroups[index] = budget
//                            } else {
//                                month.budgetGroups.append(budget)
//                            }
//                        }
//                    }
                    
                    let _ = calculateTotal(for: month)
                    
                    /// Run this when switching years.
                    if month.enumID == self.sMonth.enumID {
                        /// If the dashboard is open in the inspector on iPad, it won't be recalculate its data on its own.
                        /// So we use the ``DataChangeTriggers`` class to send a notification to the view to tell it to recalculate.
                        DataChangeTriggers.shared.viewDidChange(.calendar)
                    }
                    
                }
                
                month.changeLoadingSpinners(toShowing: false, includeCalendar: true)
                
                let currentElapsed = CFAbsoluteTimeGetCurrent() - start
                print("⏰It took \(currentElapsed) seconds to fetch \(month.actualNum) \(month.year) -- \(Date())")
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
        //let transactionSortMode = TransactionSortMode.fromString(UserDefaults.standard.string(forKey: "transactionSortMode") ?? "")
        //let categorySortMode = SortMode.fromString(UserDefaults.standard.string(forKey: "categorySortMode") ?? "")
        
        let transactionSortMode = AppSettings.shared.transactionSortMode
        let categorySortMode = AppSettings.shared.categorySortMode
        
        /// This will look at both the transaction, and its deepCopy.
        /// The reason being - in case we change a transction category or payment method from what is currently being viewed. This will allow the transaction sheet to remain on screen until we close it, at which point the save function will clear the deepCopy.
        return day.transactions
            /// FIlter by active transactions.
            .filter { $0.active }
            /// Omit transactions that are being added. (Do this to prevent seeing the blank trans being added to the day before the sheet has finished presenting.
            /// Upin futher review, don't use this so we can animate the removal of transactions. The adding / removing behavior mimcs the iOS calendar app. 11/6/25
            //.filter { $0.action == .edit }
            /// Filter by search term & category.
            .filter { trans in
                if searchText.isEmpty {
                    if !sCategories.isEmpty {
                        return sCategories.map { $0.id }.contains { trans.categoryIdsInCurrentAndDeepCopy.contains($0) }
                    } else {
                        return true
                    }
                } else {
                    if !sCategories.isEmpty {
                        return
                            (trans.title.localizedCaseInsensitiveContains(searchText) || !trans.tags.filter { $0.tag.localizedCaseInsensitiveContains(searchText) }.isEmpty)
                            && sCategories.map{ $0.id }.contains { trans.categoryIdsInCurrentAndDeepCopy.contains($0) }
                        
                        
//                        if searchText.first == "#" {
//                            let actualSearch = searchText.replacing("#", with: "")
//                            return
//                                !trans.tags.filter { $0.tag.localizedCaseInsensitiveContains(actualSearch) }.isEmpty
//                                && sCategories.map{ $0.id }.contains { trans.categoryIdsInCurrentAndDeepCopy.contains($0) }
//                        } else {
//                            return
//                                trans.title.localizedCaseInsensitiveContains(searchText)
//                                && sCategories.map{ $0.id }.contains { trans.categoryIdsInCurrentAndDeepCopy.contains($0) }
//                        }
                        
//                        if searchWhat == .titles {
//                            return
//                                trans.title.localizedCaseInsensitiveContains(searchText)
//                                && sCategories.map{ $0.id }.contains { trans.categoryIdsInCurrentAndDeepCopy.contains($0) }
//                        } else {
//                            return
//                                !trans.tags.filter { $0.tag.localizedCaseInsensitiveContains(searchText) }.isEmpty
//                                && sCategories.map{ $0.id }.contains { trans.categoryIdsInCurrentAndDeepCopy.contains($0) }
//                        }
                    } else {
                        return (trans.title.localizedCaseInsensitiveContains(searchText) || !trans.tags.filter { $0.tag.localizedCaseInsensitiveContains(searchText) }.isEmpty)
//                        if searchText.first == "#" {
//                            let actualSearch = searchText.replacing("#", with: "")
//                            return !trans.tags.filter { $0.tag.localizedCaseInsensitiveContains(actualSearch) }.isEmpty
//                        } else {
//                            return trans.title.localizedCaseInsensitiveContains(searchText)
//                        }
                        
//                        if searchWhat == .titles {
//                            return trans.title.localizedCaseInsensitiveContains(searchText)
//                        } else {
//                            return !trans.tags.filter { $0.tag.localizedCaseInsensitiveContains(searchText) }.isEmpty
//                        }
                    }
                }
            }
            .filter { trans in
                var passesPaymentMethodFilter: Bool {
                    if sPayMethod?.accountType == .unifiedChecking {
                        return ([AccountType.checking, .cash].contains { trans.payMethodTypesInCurrentAndDeepCopy.contains($0) } || (trans.action == .add && trans.payMethod == nil))
                        && !trans.hasHiddenMethodInCurrentOrDeepCopy
                        && trans.isPermitted

                    } else if sPayMethod?.accountType == .unifiedCredit {
                        return ([AccountType.credit, .loan].contains { trans.payMethodTypesInCurrentAndDeepCopy.contains($0) } || (trans.action == .add && trans.payMethod == nil))
                        && !trans.hasHiddenMethodInCurrentOrDeepCopy
                        && trans.isPermitted

                    } else if sPayMethod == nil {
                        return !trans.hasHiddenMethodInCurrentOrDeepCopy && trans.isPermitted

                    } else {
                        return (sPayMethod?.id == trans.payMethod?.id || sPayMethod?.id == trans.deepCopy?.payMethod?.id)
                        && !trans.hasHiddenMethodInCurrentOrDeepCopy
                        && trans.isPermitted
                    }
                }
                
                var passesHolderFilter: Bool {
                    switch AppSettings.shared.paymentMethodFilterMode {
                    case .all:
                        return true

                    case .justPrimary:
                        return trans.payMethod?.holderOne?.id == AppState.shared.user?.id || trans.deepCopy?.payMethod?.holderOne?.id == AppState.shared.user?.id

                    case .primaryAndSecondary:
                        let userId = AppState.shared.user?.id
                        return
                            trans.payMethod?.holderOne?.id == userId
                            || trans.deepCopy?.payMethod?.holderOne?.id == userId
                            || trans.payMethod?.holderTwo?.id == userId
                            || trans.deepCopy?.payMethod?.holderTwo?.id == userId
                            || trans.payMethod?.holderThree?.id == userId
                            || trans.deepCopy?.payMethod?.holderThree?.id == userId
                            || trans.payMethod?.holderFour?.id == userId
                            || trans.deepCopy?.payMethod?.holderFour?.id == userId
                    }
                }

                
                return passesPaymentMethodFilter && passesHolderFilter
            }
        
        
        
//            /// Filter by payment method
//            .filter { trans in
//                if sPayMethod?.accountType == .unifiedChecking {
//                    return ([AccountType.checking, AccountType.cash].contains { trans.payMethodTypesInCurrentAndDeepCopy.contains($0) } || (trans.action == .add && trans.payMethod == nil))
//                    && !trans.hasHiddenMethodInCurrentOrDeepCopy
//                    && trans.isPermitted
//                    
//                } else if sPayMethod?.accountType == .unifiedCredit {
//                    return ([AccountType.credit, AccountType.loan].contains { trans.payMethodTypesInCurrentAndDeepCopy.contains($0) } || (trans.action == .add && trans.payMethod == nil))
//                    && !trans.hasHiddenMethodInCurrentOrDeepCopy
//                    && trans.isPermitted
//                    
//                } else if sPayMethod == nil {
//                    return !trans.hasHiddenMethodInCurrentOrDeepCopy && trans.isPermitted
//                    
//                } else {
//                    return (sPayMethod?.id == trans.payMethod?.id || sPayMethod?.id == trans.deepCopy?.payMethod?.id)
//                    && !trans.hasHiddenMethodInCurrentOrDeepCopy
//                    && trans.isPermitted
//                }
//            }
//            .filter { trans in
//                switch AppSettings.shared.paymentMethodFilterMode {
//                case .all:
//                    return true
//                case .justPrimary:
//                    return trans.payMethod?.holderOne?.id == AppState.shared.user?.id || trans.deepCopy?.payMethod?.holderOne?.id == AppState.shared.user?.id
//                case .primaryAndSecondary:
//                    return trans.payMethod?.holderOne?.id == AppState.shared.user?.id || trans.deepCopy?.payMethod?.holderOne?.id == AppState.shared.user?.id
//                    || trans.payMethod?.holderTwo?.id == AppState.shared.user?.id || trans.deepCopy?.payMethod?.holderTwo?.id == AppState.shared.user?.id
//                    || trans.payMethod?.holderThree?.id == AppState.shared.user?.id || trans.deepCopy?.payMethod?.holderThree?.id == AppState.shared.user?.id
//                    || trans.payMethod?.holderFour?.id == AppState.shared.user?.id || trans.deepCopy?.payMethod?.holderFour?.id == AppState.shared.user?.id
//                }
//            }
            /// Sort by transaction enteredDate or title, or by category (title or list order). User preference.
            .sorted {
                if transactionSortMode == .title {
                    return $0.title < $1.title
                    
                } else if transactionSortMode == .enteredDate {
                    return $0.enteredDate < $1.enteredDate
                    
                } else {
                    if categorySortMode == .title {
                        return ($0.category?.title ?? "").lowercased() < ($1.category?.title ?? "").lowercased()
                    } else {
                        return $0.category?.listOrder ?? -1 < $1.category?.listOrder ?? -1
                    }
                }
            }
            /// Make sure new items are at the bottom of the list.
            .sorted {
                ($0.action == .edit || $0.action == .delete) && ($1.action != .edit && $1.action != .delete)
            }
    }
         
    
    func getTransCount(for meth: CBPaymentMethod, and cbMonth: CBMonth) -> Int {
        return justTransactions
            .filter { $0.active }
            .filter { $0.dateComponents?.month == cbMonth.actualNum && $0.dateComponents?.year == cbMonth.year }
            //.filter { $0.payMethod?.id == meth.id }
        
            /// Filter by search term.
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
                                trans.title.localizedCaseInsensitiveContains(searchText)
                                && sCategories.map{ $0.id }.contains { trans.categoryIdsInCurrentAndDeepCopy.contains($0) }
                        } else {
                            return
                                !trans.tags.filter { $0.tag.localizedCaseInsensitiveContains(searchText) }.isEmpty
                                && sCategories.map{ $0.id }.contains { trans.categoryIdsInCurrentAndDeepCopy.contains($0) }
                        }
                    } else {
                        if searchWhat == .titles {
                            return trans.title.localizedCaseInsensitiveContains(searchText)
                        } else {
                            return !trans.tags.filter { $0.tag.localizedCaseInsensitiveContains(searchText) }.isEmpty
                        }
                    }
                }
            }
            /// Filter by account type and if the method is supposed to be hidden from the list.
            .filter { trans in
                if meth.accountType == .unifiedChecking {
                    return [AccountType.checking, AccountType.cash].contains(trans.payMethod?.accountType)
                    && !trans.hasHiddenMethodInCurrentOrDeepCopy
                    //&& !trans.hasPrivateMethodInCurrentOrDeepCopy
                    //&& (trans.payMethod ?? CBPaymentMethod()).isPermitted ? true : !trans.hasPrivateMethodInCurrentOrDeepCopy
                    
                } else if meth.accountType == .unifiedCredit {
                    return [AccountType.credit, AccountType.loan].contains(trans.payMethod?.accountType)
                    && !trans.hasHiddenMethodInCurrentOrDeepCopy
                    //&& !trans.hasPrivateMethodInCurrentOrDeepCopy
                    
                } else {
                    return trans.payMethod?.id == meth.id
                    && !trans.hasHiddenMethodInCurrentOrDeepCopy
                    //&& !trans.hasPrivateMethodInCurrentOrDeepCopy
                }
            }
            /// Filter the private payment methods.
            .filter { trans in
                if let meth = trans.payMethod {
                    if meth.isPermitted {
                        return true
                    } else {
                        return false
                    }
                } else {
                    return true
                }
            }
        
        
            .count
    }
    
    
    func handleTransactions(_ transactions: Array<CBTransaction>, for month: CBMonth? = nil, refreshTechnique: RefreshTechnique?) {
        let pendingSmartTransactionCount = tempTransactions.filter({ $0.isSmartTransaction ?? false }).count
        
        for incomingTrans in transactions {
            let id = incomingTrans.id
            let date = incomingTrans.date
            let month = incomingTrans.dateComponents?.month
            let dayNum = incomingTrans.dateComponents?.day
            let year = incomingTrans.dateComponents?.year
            
            
            var ogObject: CBTransaction?
            
            /// Handle smart transactions.
            if let isSmartTransaction = incomingTrans.isSmartTransaction {
                if isSmartTransaction && !(incomingTrans.smartTransactionIsAcknowledged ?? true) {
                    if incomingTrans.smartTransactionIssue != nil {
                        if tempTransactions.filter({ $0.id == incomingTrans.id }).isEmpty {
                            tempTransactions.append(incomingTrans)
                        }
                        continue
                    }
//                    else {
//                        if incomingTrans.active {
//                            AppState.shared.showToast(title: "Smart Transaction Added", subtitle: incomingTrans.title, body: "\(incomingTrans.prettyDate ?? "N/A")", symbol: "checkmark", symbolColor: .green)
//                        }
//                    }
                } else {
                    if isSmartTransaction {
                        /// Is acknowledged (do this to remove from other devices via long poll)
                        tempTransactions.removeAll { $0.id == incomingTrans.id }
                                                        
                        /// Show an alert when a smart transaction first completes.
                        if justTransactions.filter ({ $0.id == incomingTrans.id }).isEmpty {
                            if incomingTrans.active {
                                AppState.shared.showToast(title: "Smart Transaction Added", subtitle: incomingTrans.title, body: "\(incomingTrans.prettyDate ?? "N/A")", symbol: "checkmark", symbolColor: .green)
                            }
                        }
                    }
                }
            }
            
            /// Check if transaction is in the search results
            if let index = self.searchedTransactions.firstIndex(where: {$0.id == incomingTrans.id}) {
                searchedTransactions[index].setFromAnotherInstance(transaction: incomingTrans)
                searchedTransactions[index].deepCopy?.setFromAnotherInstance(transaction: incomingTrans)
            }
            
            /// Check if transaction is in the receipts list
            if let index = self.receiptTransactions.firstIndex(where: {$0.id == incomingTrans.id}) {
                receiptTransactions[index].setFromAnotherInstance(transaction: incomingTrans)
                receiptTransactions[index].deepCopy?.setFromAnotherInstance(transaction: incomingTrans)
            } else {
                if let files = incomingTrans.files, !files.isEmpty {
                    receiptTransactions.insert(incomingTrans, at: 0)
                }
            }
            
            /// Check if the transaction exists locally.
            var dateChanged = false
            var exists = false
            months.forEach { month in
                month.days.forEach { day in
                    day.transactions.forEach { trans in
                        /// Find the local transactions that matches the incoming transaction.
                        #warning("serverID Change")
                        if trans.serverID == id {
                            /// If you left this transaction open and it changed from another device while you were away (ie if bouncing back and forth between this app and a banking app), update it and show the user that it has changed.
                            if trans.status == .editing && (refreshTechnique == .viaSceneChange || refreshTechnique == .viaTempListSceneChange) {
                                let message = AppState.shared.user(is: incomingTrans.updatedBy)
                                ? "You left transaction ID \(trans.id), \(trans.title) open and updated it from another device. Those changed have been applied."
                                : "This transaction was updated by \(incomingTrans.updatedBy.name) while you were away. Their changed have been applied."
                                AppState.shared.showAlert(title: "Heads up!", subtitle: message)
                            }
                            
                            /// If a transaction changed from another device while it was in flight, ignore the other devices changes and let the user know the other device will be rolledback.
                            if trans.status == .inFlight {
                                let message = AppState.shared.user(is: incomingTrans.updatedBy)
                                ? "You updated \(trans.title) from another device while it was in the process of saving. The change from the other device will be discarded."
                                : "\(incomingTrans.updatedBy.name) updated \(trans.title) while it was in the process of saving. Their change will be discarded."
                                AppState.shared.showAlert(title: "Heads up!", subtitle: message)
                                return
                            }
                            
                            exists = true
                            
                            /// Delete the transaction if applicable.
                            if !incomingTrans.active {
                                trans.status = .deleteSucceess
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    /// This triggers drawOff (reverse of drawOn)
                                    withAnimation(.easeOut(duration: 0.8)) {
                                        trans.status = .dummy
                                    }
                                    
                                    /// STEP 3 — Wait for drawOff to finish (~0.6s)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                        withAnimation(.easeOut(duration: 0.6)) {
                                            trans.status = nil
                                            day.remove(trans)
                                            let _ = self.calculateTotal(for: month)
                                        }
                                    }
                                }
//                                withAnimation {
//                                    day.remove(incomingTrans)
//                                }
                            } else {
                                /// Find the transaction in the appropriate day and update if applicable.
                                if let index = day.getIndex(for: incomingTrans) {
                                    ogObject = day.transactions[index]
                                    ogObject!.setFromAnotherInstance(transaction: incomingTrans)
                                    ogObject!.deepCopy?.setFromAnotherInstance(transaction: incomingTrans)
                                }
                                
                                /// Set a flag that the date changed if applicable.
                                if date != day.date {
                                    dateChanged = true
                                    //trans.prepareDateChangeFromLongPoll(to: date)
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
                ogObject = incomingTrans
            }
                          
            /// If the transaction was not found locally, or the date changed, add it to the applicable day if the month and year match the local scope.
            if !exists || dateChanged {
                //if !dateChanged {
                    
                
                    if incomingTrans.active {
                        if let targetMonth = months.filter({ $0.actualNum == month && $0.year == year }).first {
                            if let targetDay = targetMonth.days.filter({ $0.dateComponents?.day == dayNum }).first {
                                withAnimation {
                                    withAnimation {
                                        targetDay.upsert(ogObject!)
                                    }
                                }
                            }
                        }
                    }
                //}
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
          
    
    func getTransaction(by id: String, from transactionLocation: WhereToLookForTransaction = .normalList) -> CBTransaction {
        let theList = switch transactionLocation {
            case .normalList:           justTransactions
            case .tempList, .smartList: tempTransactions
            case .searchResultList:     searchedTransactions
            case .receiptsList:         receiptTransactions
        }
        #warning("ServerID")
        
        if let trans = theList.first(where: { ($0.id == id || $0.serverID == id) }) {
            return trans
        }
        return CBTransaction(uuid: id)
    }
    
    
    private func changeDate(_ trans: CBTransaction) {
        print("-- \(#function)")
        guard let (oldDate, newDate) = trans.getDateChanges(), let oldDate, let newDate else {
            //let (oldDate, newDate) = trans.getDateChanges() ?? (Date(), Date())
            //print("-- \(#function) NOPE!!!! - \(trans.id)");
            //print("-- \(#function) oldDate \(oldDate)")
            //print("-- \(#function) newDate \(newDate)")
            return
        }
        
        guard let oldDay = months.getDay(by: oldDate) else {
            print("\(#function) -- Old day is not existing")
            return
        }
        
        guard oldDay.isExisting(trans) else {
            print("\(#function) -- trans does not exist in old day \(String(describing: oldDay.date))")
            return
        }
                
        withAnimation { oldDay.remove(trans) }

//        guard newDate.year == oldDate.year
//        || (newDate.year == self.sYear + 1 && newDate.month == 12)
//        || (newDate.year == self.sYear - 1 && newDate.month == 1) else {
//            return
//        }
        
        //print(newDate, oldDate)
        
        guard let newDay = months.getDay(by: newDate) else {
            print("\(#function) -- could not find new day")
            return
        }
        withAnimation {
            print("\(#function) -- upserting to new day \(String(describing: newDay.date))")
            newDay.upsert(trans)
        }
    }
    
    
//    private func changeDataViaLongPoll(_ trans: CBTransaction) {
//        guard
//            let oldDate = trans.date,
//            let newDate = trans.newDate,
//            let oldDay = months.getDay(by: oldDate),
//            oldDay.isExisting(trans)
//        else { return }
//        
//        withAnimation { oldDay.remove(trans) }
//
//        guard newDate.year == oldDate.year else { return }
//        
//        guard let newDay = months.getDay(by: newDate) else { return }
//        withAnimation { newDay.upsert(trans) }
//        
//        trans.newDate = nil
//        trans.dateChangeViaLongPoll = false
//    }
    
//    private func changeDate(_ trans: CBTransaction) {
//        if let (oldDate, newDate) = trans.getDateChanges() {
//            if let targetMonth = months.filter({ $0.actualNum == oldDate?.month && $0.year == oldDate?.year }).first {
//                if let targetDay = targetMonth.days.filter({ $0.date == oldDate }).first {
//                    if targetDay.isExisting(trans) {
//                        withAnimation {
//                            targetDay.remove(trans)
//                        }
//                                                
//                        if newDate?.year == oldDate?.year {
//                            if let targetMonth = months.filter({ $0.actualNum == newDate?.month && $0.year == newDate?.year }).first {
//                                if let targetDay = targetMonth.days.filter({ $0.date == newDate }).first {
//                                    withAnimation {
//                                        targetDay.upsert(trans)
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
    
    
    private func transactionIsValid(trans: CBTransaction/*, day: CBDay? = nil*/) -> Bool {
        if trans.action == .delete {
            print("-- \(#function) -- Trans is in delete mode")
//            withAnimation {
//                day?.remove(trans)
//            }
            return true
        }
        
        /// Check for blank title or missing payment method
        if trans.title.isEmpty || trans.payMethod == nil /*&& day.date == nil*/ {
            print("-- \(#function) -- Title or payment method missing 1")
            if trans.title.isEmpty {
                print("Title is empty")
            }
            if trans.payMethod == nil {
                print("payMethod is nil")
            }
            /// If a transaction is already existing, and you wipe out the title, put the title back and alert the user.
            if trans.intendedServerAction == .edit && trans.title.isEmpty {
                trans.title = trans.deepCopy?.title ?? ""
                                
                AppState.shared.showAlert(
                    title: "Removing a title from a transaction is not allowed",
                    subtitle: "If you want to delete \"\(trans.title)\", please use the delete button instead."
                )
            }
            else {
                /// Remove the dud that is in `.add` mode since it's being upserted into the list on creation.
                let day = sMonth.days.filter { $0.dateComponents?.day == trans.dateComponents?.day }.first
                if let day {
                    withAnimation {
                        day.remove(trans)
                    }
                }
            }
            
            if !trans.title.isEmpty && trans.payMethod == nil {
                Task {
                    try await Task.sleep(for: .seconds(0.5))
                    //try? await Task.sleep(nanoseconds: UInt64(0.5 * Double(NSEC_PER_SEC)))
                    AppState.shared.showToast(title: "Failed To Save", subtitle: "Account was missing", body: "", symbol: "exclamationmark.triangle", symbolColor: .orange)
                }
            }
            return false
        }
        
        
        if trans.date == nil && (trans.isSmartTransaction ?? false) {
            print("-- \(#function) -- Trans date is nil and isSmartTransaction")
            Task {
                try await Task.sleep(for: .seconds(0.5))
                //try? await Task.sleep(nanoseconds: UInt64(0.5 * Double(NSEC_PER_SEC)))
                AppState.shared.showToast(title: "Failed To Save", subtitle: "Date was missing", body: "", symbol: "exclamationmark.triangle", symbolColor: .orange)
            }
            return false
        }
        
//        if trans.dateChangeViaLongPoll {
//            return true
//        }
        
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
        
        print("-- \(#function) -- default assumption")
        return true
    }
  
    
    @discardableResult
    @MainActor
    func saveTransaction(id: String, /*day: CBDay? = nil,*/ location: WhereToLookForTransaction = .normalList) async -> Bool {
        //cleanTags()
                
        let trans = getTransaction(by: id, from: location)
        print("-- \(#function) id: \(id) - looking in \(location) - \(trans.title) - \(trans.id)")
        
        trans.intendedServerAction = trans.action
        /// Immediately flip the action to edit so 1. the transaction will show on the calendar, and 2. The transaction won't do all its "I'm a new transaction" logic if you open it before it completes its very first round trip from the server.
        if trans.action == .add {
            /// Animate adding the transaction to the day.
            withAnimation {
                trans.action = .edit
            }
        }
        
        if trans.isSmartTransaction ?? false {
            trans.smartTransactionIsAcknowledged = true
        }
                
        
        if transactionIsValid(trans: trans/*, day: day*/) {
            print("✅ Trans is valid to save")
            
            /// Go update the normal transaction list if changing that transaction via the smart list (temp list) or search result list.
            if location == .smartList || location == .searchResultList {
                self.handleTransactions([trans], refreshTechnique: nil)
            }
                                    
            var saveResultToReturn: Bool = false
            /// Set the updated by user and date.
            trans.updatedBy = AppState.shared.user!
            trans.updatedDate = Date()
            trans.status = .inFlight
            
            /// Update the searched transactions if they are in the search list and you update them like normal.
            if let index = searchedTransactions.firstIndex(where: { $0.id == id }) {
                let otherTrans = searchedTransactions[index]
                otherTrans.setFromAnotherInstance(transaction: trans)
            }
            
            /// Update the temp transactions if they are in the search list and you update them like normal. (I don't think this would be very common though).
            if let index = tempTransactions.firstIndex(where: { $0.id == id }) {
                let otherTrans = tempTransactions[index]
                otherTrans.setFromAnotherInstance(transaction: trans)
            }
            
            
            /// Move the transaction if applicable.
            if trans.dateChanged() {
                print("Date check 1")
                changeDate(trans)
            }
            
            /// Move the transaction if applicable.
//            if trans.dateChangeViaLongPoll {
//                changeDataViaLongPoll(trans)
//            }
            
                        
            if trans.action == .delete {
                /// Check if the transaction has a related ID (like from a transfer or payment).
                if trans.relatedTransactionID != nil
                    && trans.relatedTransactionType == XrefModel.getItem(from: .relatedTransactionType, byEnumID: .transaction)
                {
                    let trans2 = getTransaction(by: trans.relatedTransactionID!, from: .normalList)
                    trans2.intendedServerAction = .delete
                                        
                    saveResultToReturn = await self.delete(trans)
                    _ = await self.delete(trans2)
                } else {
                    saveResultToReturn = await self.delete(trans)
                }
                // Only a data change trigger is after this code.
                
            } else {
                /// Recalculate totals for each day.
                Task { let _ = calculateTotal(for: sMonth) }
                
                //let toastLingo = "Successfully \(trans.action == .add ? "Added" : "Updated")"
                
                /// Check if the transaction has a related ID (like from a transfer or payment).
                /// This will not handle event transactions!
                if trans.relatedTransactionID != nil
                && trans.intendedServerAction != .add
                && trans.relatedTransactionType == XrefModel.getItem(from: .relatedTransactionType, byEnumID: .transaction) {
                                        
                    
                    //print("the paymethod is \(trans.payMethod?.title)")
                    //print("the deep paymethod is \(trans.deepCopy?.payMethod?.title)")
                    
                    let trans2 = getTransaction(by: trans.relatedTransactionID!, from: .normalList)
                    trans.status = .inFlight
                    trans2.deepCopy(.create)
                    trans2.updatedBy = AppState.shared.user!
                    trans2.updatedDate = Date()
                    trans2.intendedServerAction = trans.intendedServerAction
                    trans2.factorInCalculations = trans.factorInCalculations
                    //trans2.color = trans.color
                    
                    /// Update the linked date.
                    if trans.dateChanged() {
                        print("Date check 2")
                        trans2.date = trans.date
                        changeDate(trans2)
                    }
                    
                    /// Update the dollar amounts accordingly.
                    if trans.payMethod?.accountType != .credit && trans.payMethod?.accountType != .loan {
                        if trans2.payMethod?.accountType == .credit || trans2.payMethod?.accountType == .loan {
                            trans2.amountString = (trans.amount * 1).currencyWithDecimals()
                        } else {
                            trans2.amountString = (trans.amount * -1).currencyWithDecimals()
                        }
                        
                    } else if trans2.payMethod?.accountType == .credit || trans2.payMethod?.accountType == .loan {
                        trans2.amountString = (trans.amount * -1).currencyWithDecimals()
                    } else {
                        trans2.amountString = (trans.amount * 1).currencyWithDecimals()
                    }
                    
                    /// If we filter transactions by category or by payment method, and change it on the transaction, we need the line below to cause the transaction to disappear when closing it.
                    /// The transaction filter function that provides the views with the transactions looks for both the transaction and it's deep copy. When changing a category for example, the trans will remain due to the deep copy still having the old reference.
                    withAnimation {
                        trans.deepCopy(.clear)
                        trans2.deepCopy(.clear)
                    }
                    
                    /// Submit to the server.
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask { saveResultToReturn = await self.submit(trans) }
                        group.addTask { let _ = await self.submit(trans2) }
                    }
                } else {
                    trans.actionBeforeSave = trans.action
                    /// If we filter transactions by category or by payment method, and change it on the transaction, we need the line below to cause the transaction to disappear when closing it.
                    /// The transaction filter function that provides the views with the transactions looks for both the transaction and it's deep copy. When changing a category for example, the trans will remain due to the deep copy still having the old reference.
                    withAnimation {
                        trans.deepCopy(.clear)
                    }
                    
                    saveResultToReturn = await submit(trans)
                    showToastsForTransactionSave(showSmartTransAlert: location == .smartList, trans: trans)
                }
                
                
                if location == .smartList {
                    tempTransactions.removeAll(where: { $0.id == trans.id })
                }
            }
            
            /// If the dashboard is open in the inspector on iPad, it won't be recalculate its data on its own.
            /// So we use the ``DataChangeTriggers`` class to send a notification to the view to tell it to recalculate.
            DataChangeTriggers.shared.viewDidChange(.calendar)
            return saveResultToReturn
            
        } else {
            print("❌ Trans is not valid to save")
            
            trans.status = nil
            return false
        }
    }
    
    
    /// Only called via `saveTransaction(id: day:)` or `saveTemp(trans:)`.
    @MainActor
    private func submit(_ trans: CBTransaction) async -> Bool {
        /// Allow the transaction more time to save if the user enters the background.
        #if os(iOS)
        var backgroundTaskId = AppState.shared.beginBackgroundTask()
        #endif
        
        print("-- \(#function)")
        print("Submitting Trans \(trans.id)")
        
        let context = DataManager.shared.createContext()
        
        /// Starts the spinner after 2 seconds
        startDelayedLoadingSpinnerTimer()
        LoadingManager.shared.startLongNetworkTimer()
        
        isThinking = true
       
        /// Add a temporary transaction to coredata (For when the app was already loaded, but you went back to it after entering an area of bad network connection).
        /// This way, if you add a transaction in an area of bad connection, the transaction won't be lost when you try and save it.
        context.performAndWait {
            if let entity = DataManager.shared.getOne(context: context, type: TempTransaction.self, predicate: .byId(.string(trans.id)), createIfNotFound: true)  {
                entity.id = trans.id
                entity.title = trans.title
                entity.amount = trans.amount
                entity.payMethodID = trans.payMethod?.id ?? "0"
                entity.categoryID = trans.category?.id ?? "0"
                entity.date = trans.date
                entity.notes = String(trans.notes.characters)
                entity.hexCode = trans.color.toHex()
                //entity.hexCode = trans.color.description
                //entity.tags = trans.tags
                entity.enteredDate = trans.enteredDate
                entity.updatedDate = trans.updatedDate
                //entity.files = trans.files
                entity.factorInCalculations = trans.factorInCalculations
                entity.notificationOffset = Int64(trans.notificationOffset)
                entity.notifyOnDueDate = trans.notifyOnDueDate
                //entity.action = isNew ? "add" : trans.action.rawValue
                entity.action = trans.action.rawValue
                entity.tempAction = trans.action == .add ? "edit" : trans.action.rawValue
                entity.isPending = true
                let _ = DataManager.shared.save(context: context)
            }
        }
        
        LogManager.log()
        let model = RequestModel(requestType: trans.intendedServerAction.serverKey, model: trans)
            
        /// Used to test the snapshot data race
        //try? await Task.sleep(for: .seconds(10))
        
        /// Do Networking.
        typealias ResultResponse = Result<ParentChildIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager(timeout: 10).singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            
            /// Performs in its own context
            DataManager.shared.delete(context: context, type: TempTransaction.self, predicate: .byId(.string(trans.id)))
            
            if trans.isFromCoreData {
                let actualTrans = justTransactions.first(where: { $0.id == trans.id })
                if let actualTrans {
                    #warning("serverID Change")
                    actualTrans.serverID = String(model?.parentID.id ?? "0")
                    #warning("put back if abaodon serverID")
                    //actualTrans.uuid = nil
                    actualTrans.intendedServerAction = .edit
                }
            } else {
                #warning("serverID Change")
                trans.serverID = String(model?.parentID.id ?? "0")
                #warning("put back if abaodon serverID")
                //trans.uuid = nil
                trans.intendedServerAction = .edit
            }
                                                
            /// Update any tags / locations that were added for the first time via this transaction with their new DBID.
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
            if trans.action == .delete {
                //trans.status = nil
                trans.status = .deleteSucceess
            } else {
                trans.status = .saveSuccess
            }
            performLineItemAnimations(for: trans)
            
            
            /// At this point, in the future the trans will always be in edit mode unless it was deleted.
            trans.intendedServerAction = .edit
            
            /// Clear the logs since they will be refetched live when trying to view the transaction again. (Prevents dupes).
            trans.logs.removeAll()
                        
            print("✅Transaction successfully saved")
            /// Cancel the loading spinner if it hasn't started, otherwise hide it.
            stopDelayedLoadingSpinnerTimer()
            
            /// End the background task.
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
            #endif
            
            if LoadingManager.shared.showLongNetworkTaskToast {
                AppState.shared.showToast(title: "Transaction Successfully Saved", subtitle: "Network connection seems stable.", body: nil, symbol: "checkmark", symbolColor: .green)
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
            trans.status = .saveFail
            performLineItemAnimations(for: trans)
            
            /// Cancel the loading spinner if it hasn't started, otherwise hide it,
            stopDelayedLoadingSpinnerTimer()
            LoadingManager.shared.stopLongNetworkTimer()
            
            /// End the background task.
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
            #endif
            
            /// Return unsuccessful save result to the caller.
            return false
        }
    }
    
    
    /// Only called via `saveTransaction(id: day:)`.
    @discardableResult
    private func delete(_ trans: CBTransaction) async -> Bool {
        print("-- \(#function)")
        trans.action = .delete
        trans.actionBeforeSave = trans.action
        trans.intendedServerAction = .delete
        withAnimation {
//            if let targetMonth = months.filter({ $0.actualNum == trans.dateComponents?.month && $0.year == trans.dateComponents?.year }).first {
//                if let day = targetMonth.days.filter({ $0.dateComponents?.day == trans.dateComponents?.day }).first {
//                    day.remove(trans)
//                    let _ = calculateTotal(for: sMonth)
//                }
//            }
            
            tempTransactions.removeAll { $0.id == trans.id }
        }
           
        //Task { @MainActor in
        let saveResult = await submit(trans)
        return saveResult
            //self.handleSavingOfEventTransaction(trans: trans, eventModel: eventModel)
        //}
    }
    
    
    /// Only called from `funcModel.downloadEverything()`.
    /// Only here to allow `self.submit()` to be private.
    func saveTemp(trans: CBTransaction) async {
        let _ = await submit(trans)
    }
        
    
    @MainActor
    func addMultiple(trans: Array<CBTransaction>, budgets: Array<CBBudget>, isTransfer: Bool) async {
        #if os(iOS)
        var backgroundTaskId = AppState.shared.beginBackgroundTask()
        #endif
        /// If the dashboard is open in the inspector on iPad, it won't be recalculate its data on its own.
        /// So we use the ``DataChangeTriggers`` class to send a notification to the view to tell it to recalculate.
        DataChangeTriggers.shared.viewDidChange(.calendar)
        
        
        for each in trans {
            each.status = .inFlight
        }
        
        
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        
        let repModel = RepeatingAndBudgetSubmissionModel(
            month: sMonth.actualNum,
            year: sMonth.year,
            transactions: trans,
            budgets: budgets,
            //budgetGroups: budgetGroups,
            isTransfer: isTransfer
        )
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
                            #warning("serverID Change")
                            transactions[index].serverID = String(idModel.id)
                            if let relatedID = idModel.relatedID {
                                transactions[index].relatedTransactionID = String(relatedID)
                            }
                            
                            //transactions[index].id = String(model?.transactionID ?? "0")
                            //transactions[index].uuid = nil
                            transactions[index].action = .edit
                            transactions[index].intendedServerAction = .edit
                            transactions[index].status = .saveSuccess
                            performLineItemAnimations(for: transactions[index])
                            
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
            }
            
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
            #endif
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to add multiple transactions.")
            
            for each in trans {
                each.status = .saveFail
                performLineItemAnimations(for: each)
            }
            
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
            #endif
        }
        //LoadingManager.shared.stopDelayedSpinner()
        //self.refreshTask = nil
        
    }
    
    
    @MainActor
    func editMultiple(trans: Array<CBTransaction>) async {
        #if os(iOS)
        var backgroundTaskId = AppState.shared.beginBackgroundTask()
        #endif
        
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        
        for each in trans {
            /// Due to the way animations are handled when deleting from the multi-select sheet, ignore them.
            if each.status != .deleteSucceess {
                each.status = .inFlight
            }
            
            each.updatedBy = AppState.shared.user!
            each.updatedDate = Date()
        }
        
        //let backgroundTaskId = AppState.shared.beginBackgroundTask()
        
//        #if os(iOS)
//        var backgroundTaskID: UIBackgroundTaskIdentifier?
//        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: UUID().uuidString) {
//            UIApplication.shared.endBackgroundTask(backgroundTaskID!)
//            backgroundTaskID = .invalid
//        }
//        #endif
        
        //try? await Task.sleep(for: .seconds(20))
        
        let multiModel = MultiTransactionSubmissionModel(transactions: trans)
        let model = RequestModel(requestType: "alter_multiple_transactions", model: multiModel)
        
        typealias ResultResponse = Result<Array<ParentChildIdModel>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            if let model {
                for parent in model {
                    if let foundTrans = trans.filter({ $0.uuid == parent.parentID.uuid }).first {
                        if foundTrans.action == .add {
                            #warning("serverID Change")
                            foundTrans.serverID = String(parent.parentID.id)
                            //foundTrans.uuid = nil
                            foundTrans.action = .edit
                            foundTrans.status = .saveSuccess
                            foundTrans.duplicateFileRecordsOnDb = false
                            
                            
                            /// Update any tags / locations / files that were added for the first time via this transaction with their new DBID.
                            for each in parent.childIDs {
                                if each.type == "tag" {
                                    let index = tags.firstIndex(where: { $0.uuid == each.uuid })
                                    if let index {
                                        tags[index].id = String(each.id)
                                    }
                                } else if each.type == "transaction_location" {
                                    let index = foundTrans.locations.firstIndex(where: { $0.uuid == each.uuid })
                                    if let index {
                                        foundTrans.locations[index].id = String(each.id)
                                    }
                                } else if each.type == "transaction_file" {
                                    let index = foundTrans.files?.firstIndex(where: { $0.uuid == each.uuid })
                                    if let index {
                                        foundTrans.files?[index].id = String(each.id)
                                    }
                                }
                            }
                            
                            
                        } else if foundTrans.action == .edit {
                            foundTrans.status = .saveSuccess
                            
                        } else if foundTrans.action == .delete {
                            foundTrans.status = .deleteSucceess
                            tempTransactions.removeAll { $0.id == foundTrans.id }
                            //foundTrans.status = .deleteSucceess
//                            withAnimation {
//                                let day = sMonth.days.filter { $0.dateComponents?.day == foundTrans.dateComponents?.day }.first
//                                if let day {
//                                    day.remove(foundTrans)
//                                    let _ = calculateTotal(for: sMonth)
//                                }
//
//                                tempTransactions.removeAll {$0.id == foundTrans.id}
//                            }
                        }
                        
                        performLineItemAnimations(for: foundTrans)
                        
                    }
                }
                
                #if os(iOS)
                AppState.shared.endBackgroundTask(&backgroundTaskId)
                #endif
                                
                print("Multi-update successful")
            }
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to update multiple transactions.")
            #warning("Undo behavior")
            
            for each in trans {
                each.status = .saveFail
                performLineItemAnimations(for: each)
            }
                                    
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
            #endif
        }
    }
        
    
    private func showToastsForTransactionSave(showSmartTransAlert: Bool, trans: CBTransaction) {
        let toastLingo = "Successfully \(trans.action == .add ? "Added" : "Updated")"
        
        if showSmartTransAlert {
            AppState.shared.showToast(
                title: "Successfully Added \(trans.title)",
                subtitle: "\(trans.date?.string(to: .monthDayShortYear) ?? "Date: N/A")",
                body: "\(trans.payMethod?.title ?? "N/A")\n\(trans.amountString)",
                //symbol: "creditcard",
                logo: .init(
                    parent: trans.payMethod,
                    fallBackType: .customImage(.init(name: "creditcard", color: .green))
                )
            )
        } else {
            if sPayMethod?.accountType == .unifiedChecking {
                if trans.payMethod?.accountType != .checking && trans.payMethod?.accountType != .cash {
                    //NotificationManager.shared.sendNotification(title: "Successfully Added", subtitle: trans.title, body: trans.amountString)
                    AppState.shared.showToast(
                        title: toastLingo,
                        subtitle: trans.title,
                        body: trans.amountString,
                        //symbol: "creditcard",
                        logo: .init(
                            parent: trans.payMethod,
                            fallBackType: .customImage(.init(name: "creditcard", color: .green))
                        )
                    )
                }
                
            } else if sPayMethod?.accountType == .unifiedCredit {
                if trans.payMethod?.accountType == .checking && trans.payMethod?.accountType == .cash {
                    //NotificationManager.shared.sendNotification(title: "Successfully Added", subtitle: trans.title, body: trans.amountString)
                    AppState.shared.showToast(
                        title: toastLingo,
                        subtitle: trans.title,
                        body: trans.amountString,
                        symbol: "creditcard",
                        logo: .init(
                            parent: trans.payMethod,
                            fallBackType: .customImage(.init(name: "creditcard", color: .green))
                        )
                    )
                }
                
            } else if sPayMethod == nil {
                /// Nothing

            } else if sPayMethod?.accountType != trans.payMethod?.accountType {
                //NotificationManager.shared.sendNotification(title: "Successfully Added", subtitle: trans.title, body: trans.amountString)
                AppState.shared.showToast(
                    title: toastLingo,
                    subtitle: trans.title,
                    body: trans.amountString,
                    //symbol: "creditcard",
                    logo: .init(
                        parent: trans.payMethod,
                        fallBackType: .customImage(.init(name: "creditcard", color: .green))
                    )
                )
            }
        }
    }
        
    
    func performLineItemAnimations(for trans: CBTransaction) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            /// This triggers drawOff (reverse of drawOn)
            withAnimation(.easeOut(duration: 0.8)) {
                trans.status = .dummy
            }
            
            /// STEP 3 — Wait for drawOff to finish (~0.6s)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.6)) {
                    trans.status = nil
                    
                    if trans.action == .delete {
                        if let targetMonth = self.months.filter({ $0.actualNum == trans.dateComponents?.month && $0.year == trans.dateComponents?.year }).first {
                            if let day = targetMonth.days.filter({ $0.dateComponents?.day == trans.dateComponents?.day }).first {
                                day.remove(trans)
                                let _ = self.calculateTotal(for: self.sMonth)
                            }
                        }
                    }
                }
            }
        }
    }
                
    
    @MainActor
    func fetchSuggestedTitles() async {
        //print("-- \(#function)")
        LogManager.log()
        let model = RequestModel(requestType: "fetch_suggested_transaction_titles", model: AppState.shared.user!)
            
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        typealias ResultResponse = Result<Array<CBSuggestedTitle>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            if let model {
                suggestedTitles = model
                //print(suggestedTitles)
            }
            
        case .failure(let error):
            switch error {
            case .taskCancelled:
                print("\(#function) Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch suggested titles.")
            }
        }
    }
    
    
    @MainActor
    func transactionsUpdatesExistAfter(_ date: Date) -> Bool {
        print("-- \(#function)")
        let allDates = justTransactions.map(\.updatedDate)
        guard let latest = allDates.max() else { return false }
        print("\(latest) \(date) \(date < latest)")
        return date < latest
    }
            
    
    @MainActor
    func denySmartTransaction(_ trans: CBTransaction) async {
        print("-- \(#function)")
        
        /// Allow more time to save if the user enters the background.
        #if os(iOS)
        var backgroundTaskId = AppState.shared.beginBackgroundTask()
        #endif
        
        tempTransactions.removeAll(where: {$0.id == trans.id})
        
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        let model = RequestModel(requestType: "deny_smart_transaction", model: trans)
            
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
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
            switch error {
            case .taskCancelled:
                print("\(#function) Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to deny the smart transaction.")
            }
            /// End the background task.
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
            #endif
        }
        //LoadingManager.shared.stopDelayedSpinner()
    }
    
    
    func pasteTransaction(to day: CBDay) {
        withAnimation {
            if let trans = self.getCopyOfTransaction() {
                trans.date = day.date!
                                                
                if !isUnifiedPayMethod, let method = self.sPayMethod {
                    trans.payMethod = method
                } else {
                    #warning("Prompt the user to select a payment method if pasting on a unified view.")
                }
                
                day.upsert(trans)
                
                if let relatedId = trans.relatedTransactionID {
                    let relatedTrans = self.getTransaction(by: relatedId)
                    
                    let trans2 = CBTransaction(uuid: UUID().uuidString)
                    trans2.title = relatedTrans.title
                    trans2.amountString = relatedTrans.amountString
                    trans2.date = day.date!
                    trans2.payMethod = relatedTrans.payMethod
                    trans2.category = relatedTrans.category
                    trans2.notes = relatedTrans.notes
                    trans2.factorInCalculations = relatedTrans.factorInCalculations
                    trans2.action = .add
                    trans2.color = relatedTrans.color
                    trans2.tags = relatedTrans.tags
                    trans2.notifyOnDueDate = relatedTrans.notifyOnDueDate
                    trans2.relatedTransactionID = trans.id
                    trans2.relatedTransactionType = relatedTrans.relatedTransactionType
                    trans2.christmasListStatus = relatedTrans.christmasListStatus
                    trans2.christmasListGiftID = relatedTrans.christmasListGiftID
                    trans2.status = .editing
                    
                    trans.relatedTransactionID = trans2.id
                    
                    day.upsert(trans2)
                    
                    
                    Task {
                        await self.addMultiple(trans: [trans, trans2], budgets: [], isTransfer: false)
                    }
                    
                } else {
                    Task {
                        await self.saveTransaction(id: trans.id/*, day: day*/)
                    }
                    
                }
                                
                self.dragTarget = nil
                self.transactionToCopy = nil
            }
        }
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
        //trans.files = transaction.files
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
            trans.relatedTransactionID = transactionToCopy.relatedTransactionID
            trans.relatedTransactionType = transactionToCopy.relatedTransactionType
            trans.christmasListStatus = transactionToCopy.christmasListStatus
            trans.christmasListGiftID = transactionToCopy.christmasListGiftID
            return trans
        }
        return nil
    }
        
    
    
    
    @MainActor
    func fetchReceiptsFromServer(funcModel: FuncModel) async {
        let fetchModel = GenericUserInfoModel()
        
        let model = RequestModel(requestType: "fetch_receipts", model: fetchModel)
        typealias ResultResponse = Result<Array<CBTransaction>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            if let model {
                if self.receiptTransactions.isEmpty {
                    for trans in model {
                        self.receiptTransactions.append(trans)
                    }
                    
                    await withTaskGroup(of: Void.self) { group in
                        for trans in self.receiptTransactions.prefix(3) {
                            if let files = trans.files?.filter({ $0.active }), !files.isEmpty, let firstFile = files.first {
                                group.addTask {
                                    await funcModel.downloadFile(file: firstFile)
                                }
                            }
                        }
                    }
                } else {
                    for trans in model {
                        if let index = self.receiptTransactions.firstIndex(where: { $0.id == trans.id }) {
                            self.receiptTransactions[index].setFromAnotherInstance(transaction: trans)
                        } else {
                            self.receiptTransactions.insert(trans, at: 0)
                        }
                    }
                }
                
                currentReceiptId = model.first?.id
            }
                
        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("receiptView fetchFromServer Server Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch fit transactions.")
            }
        }
    }
    
    
    
    // MARK: - Loading Spinner
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
    
    
    
    
    // MARK: - Summary Functions
    func getTransactions(
        months: Array<CBMonth>? = nil,
        day: Int? = nil,
        meth: CBPaymentMethod? = nil,
        cats: Array<CBCategory>? = nil,
    ) -> Array<CBTransaction> {
        
        let theMonths: Array<CBMonth> = months ?? [self.sMonth]
        
        //var trans: Array<CBTransaction> = []
        
        var trans = theMonths.flatMap { $0.justTransactions }
            .filter {
                $0.active
                /// If the app is in multi-select mode, pay attention to only those transactions.
                && self.isInMultiSelectMode ? self.multiSelectTransactions.map({ $0.id }).contains($0.id) : true
                /// Only payment methods that are allowed to be viewed by the current user.
                && $0.isPermitted
                /// This will look at both the transaction, and its deepCopy.
                /// The reason being - in case we change a transaction category or payment method from what is currently being viewed. This will allow the transaction sheet to remain on screen until we close it, at which point the save function will clear the deepCopy.
                && !$0.hasHiddenMethodInCurrentOrDeepCopy
                /// Only transactions that are not excluded from calculations.
                && $0.factorInCalculations
                
                /// Only transactions related to the passed in payment method. (If applicable).
                //&& meth == nil ? true : ($0.payMethod?.id == meth?.id)
                
                /// Only transactions related to the passed in categories. (If applicable).
                //&& self.sCategoriesForAnalysis.map{ $0.id }.contains($0.category?.id)
                //&& cats == nil ? true : cats?.map{ $0.id }.contains($0.category?.id)
                /// Only transactions from the selected month.
                //&& $0.dateComponents?.month == calModel.sMonth.actualNum
                /// Only transactions from the selected year.
                //&& $0.dateComponents?.year == calModel.sMonth.year
            }
        
        /// Only transactions related to the passed in payment method. (If applicable).
        if let meth = meth {
            
            if meth.isUnifiedDebit {
                trans = trans.filter { guard let meth = $0.payMethod else { return false }; return meth.isDebitOrCash }
            } else if meth.isUnifiedCredit {
                trans = trans.filter { guard let meth = $0.payMethod else { return false }; return meth.isCreditOrLoan }
            } else {
                trans = trans.filter { $0.payMethod?.id == meth.id }
            }
            
            
        }
        
        /// Only transactions related to the passed in categories. (If applicable).
        if let cats = cats {
            let catIds = cats.map { $0.id }
            
            trans = trans.filter {
                catIds.contains($0.categoryIdsInCurrentAndDeepCopy[0] ?? "") || catIds.contains($0.categoryIdsInCurrentAndDeepCopy[1] ?? "")
            }
        }
        
        /// Only transactions from a certain day. (If applicable).
        if let day = day {
            trans = trans.filter { $0.dateComponents?.day == day }
        }
        
        /// Sort based on day.
        return trans.sorted { $0.dateComponents?.day ?? 0 < $1.dateComponents?.day ?? 0 }
    }
    
    
    
    
    // MARK: - Debit Summary Helpers
    func getDebitTransactions(from transactions: Array<CBTransaction>) -> Array<CBTransaction> {
        return transactions
            /// Only debit or cash accounts.
            .filter { ($0.payMethod?.isDebitOrCash ?? false) }
            /// Is not the origination transaction from the transfer utility.
            .filter { !$0.isTransferOrigin }
            /// Is not the destination transaction from the transfer utility.
            .filter { !$0.isTransferDest }
    }
    
    func getDebitIncomeTransactions(from transactions: Array<CBTransaction>) -> Array<CBTransaction> {
        return getDebitTransactions(from: transactions)
            /// Anything that has a negative dollar amount (expenses).
            .filter { $0.isIncome }
    }
    
    func getDebitSpendTransactions(from transactions: Array<CBTransaction>) -> Array<CBTransaction> {
        return getDebitTransactions(from: transactions)
            /// Anything that has a positive dollar amount (income).
            .filter { $0.isExpense }
    }
    
    func getDebitSpend(from transactions: Array<CBTransaction>) -> Double {
        return getDebitTransactions(from: transactions)
            /// Anything that has a negative dollar amount (expenses).
            .filter { $0.isExpense }
            .map { $0.amount }
            .reduce(0.0, +)
    }
    
    func getDebitIncome(from transactions: Array<CBTransaction>) -> Double {
        return getDebitTransactions(from: transactions)
            /// Anything that has a positive dollar amount (income).
            .filter { $0.isIncome }
            .map { $0.amount }
            .reduce(0.0, +)
    }
    
    
    
    
    // MARK: - Credit Summary Helpers
    func getCreditTransactions(from transactions: Array<CBTransaction>) -> Array<CBTransaction> {
        return transactions
        /// Only credit or loans.
            .filter { $0.payMethod?.isCreditOrLoan ?? false }
    }
    
    func getCreditSpendTransactions(from transactions: Array<CBTransaction>) -> Array<CBTransaction> {
        return getCreditTransactions(from: transactions)
            /// Anything that has a positive dollar amount (expenses).
            .filter { $0.isExpense }
            /// Exclude cash advances
            .filter { !$0.isTransferOrigin }
    }
    
    func getCreditPaymentTransactions(from transactions: Array<CBTransaction>) -> Array<CBTransaction> {
        return getCreditTransactions(from: transactions)
            /// Anything that has a negative dollar amount (payments).
            .filter { $0.isIncome }
            /// Is the destination transaction from the transfer utility.
            .filter { $0.isPaymentDest }
    }
    
    func getCreditRefundsOrPerkTransactions(from transactions: Array<CBTransaction>) -> Array<CBTransaction> {
        return getCreditTransactions(from: transactions)
            /// Anything that has a negative dollar amount (refunds, rewards, etc.).
            .filter { $0.isIncome }
            /// Is not the destination transaction from the transfer utility.
            .filter { !$0.isPaymentDest }
    }
    
    func getCreditSpend(from transactions: Array<CBTransaction>) -> Double {
        return getCreditSpendTransactions(from: transactions)
            .map { $0.amount * -1 }
            .reduce(0.0, +)
    }
    
    func getCreditPayments(from transactions: Array<CBTransaction>) -> Double {
        return getCreditPaymentTransactions(from: transactions)
            .map { $0.amount }
            .reduce(0.0, +)
    }
    
    func getCreditRefundsOrPerks(from transactions: Array<CBTransaction>) -> Double {
        return getCreditRefundsOrPerkTransactions(from: transactions)
            .map { $0.amount * -1 }
            .reduce(0.0, +)
    }

    
    
    
    // MARK: - All Transactions Helpers
    func getIncomeTransactions(from transactions: Array<CBTransaction>) -> Array<CBTransaction> {
        return getCreditRefundsOrPerkTransactions(from: transactions) + getDebitIncomeTransactions(from: transactions)
    }
    
    func getSpendTransactions(from transactions: Array<CBTransaction>) -> Array<CBTransaction> {
        return getDebitSpendTransactions(from: transactions) + getCreditSpendTransactions(from: transactions)
    }
        
//    func getSpendMinusPaymentTransactions(from transactions: Array<CBTransaction>) -> Array<CBTransaction> {
//        return getSpendTransactions(from: transactions) - getCreditPaymentTransactions(from: transactions)
//    }
//    
//    func getIncomeMinusPaymentTransactions(from transactions: Array<CBTransaction>) -> Array<CBTransaction> {
//        let debitIncome = getDebitIncomeTransactions(from: transactions)
//        let creditIncome = getCreditRefundsOrPerkTransactions(from: transactions)
//        let payments = getCreditPaymentTransactions(from: transactions)
//        return (debitIncome + creditIncome) - payments
//    }
                            
    func getIncome(from transactions: Array<CBTransaction>) -> Double {
        let refunds = getCreditRefundsOrPerks(from: transactions)
        let debitIncome = getDebitIncome(from: transactions)
        
        print(refunds, debitIncome)
        return refunds + debitIncome
        
        
        //return getCreditRefundsOrPerks(from: transactions) + getDebitIncome(from: transactions)
    }
    
    func getSpend(from transactions: Array<CBTransaction>) -> Double {
        return getDebitSpend(from: transactions) + getCreditSpend(from: transactions)
    }
        
    func getSpendMinusPayments(from transactions: Array<CBTransaction>) -> Double {
        return getSpend(from: transactions) - getCreditPayments(from: transactions)
    }
    
    func getIncomeMinusPayments(from transactions: Array<CBTransaction>) -> Double {
        let debitIncome = getDebitIncome(from: transactions)
        let creditIncome = getCreditRefundsOrPerks(from: transactions)
        let payments = getCreditPayments(from: transactions)
        return (debitIncome + creditIncome) - payments
    }
    
    func getSpendMinusIncome(from transactions: Array<CBTransaction>) -> Double {
        let expenses = getSpend(from: transactions)
        let income = getIncome(from: transactions)
        return (expenses + income)
    }
    
//    func getChartPercentage(expenses: Double, income: Double, budget: Double) -> ChartPercentage {
//        var chartPer = 0.0
//        var actualPer = 0.0
//        let expensesMinusIncome = (expenses + income) * -1
//        
//        if budget == 0 {
//            actualPer = expensesMinusIncome
//        } else {
//            actualPer = (expensesMinusIncome / budget) * 100
//        }
//                                        
//        if actualPer > 100 {
//            chartPer = 100
//        } else if actualPer < 0 {
//            chartPer = 0
//        } else {
//            chartPer = actualPer
//        }
//        
//        return ChartPercentage(actual: actualPer, chart: chartPer, expensesMinusIncome: expensesMinusIncome)
//    }
    
    func createChartData(
        transactions: Array<CBTransaction>,
        category: CBCategory,
        categoricalBudgetAmount: Double,
        categoryGroup: CBCategoryGroup?,
        groupBudgetAmount: Double?,
        budgets: Array<CBBudget>?
    ) -> ChartData {
        //let categoricalBudgetAmount = budgets?.map { $0.amount }.reduce(0.0, +) ?? 0.0
        let expenses = getSpend(from: transactions)
        let income = getIncome(from: transactions)
        let incomeMinusPayments = getIncomeMinusPayments(from: transactions)
        
        var chartPer = 0.0
        var actualPer = 0.0
        let expensesMinusIncome = (expenses + income) * -1
        
        if categoricalBudgetAmount == 0 {
            actualPer = expensesMinusIncome
        } else {
            actualPer = (expensesMinusIncome / categoricalBudgetAmount) * 100
        }
                                        
        if actualPer > 100 {
            chartPer = 100
        } else if actualPer < 0 {
            chartPer = 0
        } else {
            chartPer = actualPer
        }
        
        
        return ChartData(
            category: category,
            budgetForCategory: categoricalBudgetAmount,
            categoryGroup: categoryGroup,
            budgetForCategoryGroup: groupBudgetAmount,
            income: income,
            incomeMinusPayments: incomeMinusPayments,
            expenses: expenses,
            expensesMinusIncome: expensesMinusIncome,
            chartPercentage: chartPer,
            actualPercentage: actualPer,
            budgetObjects: budgets
        )
    }
    
    
    
    
    // MARK: - Budget Stuff
    @MainActor
    func submit(_ budget: CBBudget) async {
        print("-- \(#function)")
        
        /// Allow more time to save if the user enters the background.
        #if os(iOS)
        var backgroundTaskId = AppState.shared.beginBackgroundTask()
        #endif
        
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
//        /// Called via  ``setSelectedMonthFromNavigation(navID:calculateStartingAndEod:)`` which is called via `.onChange(of: navManager.selection)` in ``RootView``
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
//        /// Called via  ``setSelectedMonthFromNavigation(navID:calculateStartingAndEod:)`` which is called via `.onChange(of: navManager.selection)` in ``RootView``
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

        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("\(#function) Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch the tags.")
            }
        }
    }
    
    
    /// Only used to hide a tag.
    @MainActor
    func submit(_ tag: CBTag) async {
        LogManager.log()
        
        /// Allow more time to save if the user enters the background.
        #if os(iOS)
        var backgroundTaskId = AppState.shared.beginBackgroundTask()
        #endif

        /// Do networking.
        let model = RequestModel(requestType: "edit_cb_tag", model: tag)
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)

        switch await result {
        case .success:
            LogManager.networkingSuccessful()
            
            /// End the background task.
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
            #endif
            
        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("\(#function) Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to hide the tag.")
            }
            
            /// End the background task.
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
            #endif
        }
    }
    
    
//    func cleanTags() {
//        tags.forEach { tag in
//            let count = justTransactions.filter { $0.tags.contains(tag) }.count
//            if count == 0 {
//                tags.removeAll(where: { $0 == tag })
//            }
//        }
//    }
    
    
    
    
    // MARK: - Calculate Total Functions
    enum DoWhatWhenCalculating { case updateEod, giveMeLastDayEod, giveMeEodAsOfToday }
    
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
            .filter { $0.payMethod.isPermitted }
            .filter { !$0.payMethod.isHidden }
            .filter {
                switch AppSettings.shared.paymentMethodFilterMode {
                case .all:
                    return true
                case .justPrimary:
                    return $0.payMethod.holderOne?.id == AppState.shared.user?.id
                case .primaryAndSecondary:
                    return $0.payMethod.holderOne?.id == AppState.shared.user?.id
                    || $0.payMethod.holderTwo?.id == AppState.shared.user?.id
                    || $0.payMethod.holderThree?.id == AppState.shared.user?.id
                    || $0.payMethod.holderFour?.id == AppState.shared.user?.id
                }
            }
            .map { $0.amount }
            .reduce(0.0, +)
        
        //print("\(#function) -- \(startingBalance)")
                                
        let index = month.startingAmounts.firstIndex(where: { $0.payMethod.accountType == unifiedAccountType })
        if let index {
            month.startingAmounts[index].amountString = startingBalance.currencyWithDecimals()
        }
        
        return startingBalance
    }
                
    
    @discardableResult
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
                                                
        } else if [.credit, .loan].contains(theMethod?.accountType) {
            return calculateCredit(for: month, using: theMethod, and: doWhat)
            
        } else if [.checking, .cash, .savings, .investment, .k401].contains(theMethod?.accountType) {
            return calculateChecking(for: month, using: theMethod, and: doWhat)
            
        } else {
            return calculateSumForDay(for: month, and: doWhat)
        }
    }
    
    
    private func calculateUnifiedChecking(for month: CBMonth, and doWhat: DoWhatWhenCalculating) -> Double {
        var finalEodTotal: Double = 0.0
        let startingBalance = updateUnifiedStartingAmount(month: month, for: .unifiedChecking)
        var currentAmount = startingBalance
        
        month.days.forEach { day in
            let amounts = day.transactions
                .filter {
                    ($0.payMethod?.isDebitOrCash ?? true)
                    && $0.active
                    && $0.factorInCalculations
                    && ($0.payMethod?.isPermitted ?? true)
                    && !($0.payMethod?.isHidden ?? true)
                }
                .filter {
                    switch AppSettings.shared.paymentMethodFilterMode {
                    case .all:
                        return true
                    case .justPrimary:
                        return $0.payMethod?.holderOne?.id == AppState.shared.user?.id
                    case .primaryAndSecondary:
                        return $0.payMethod?.holderOne?.id == AppState.shared.user?.id
                        || $0.payMethod?.holderTwo?.id == AppState.shared.user?.id
                        || $0.payMethod?.holderThree?.id == AppState.shared.user?.id
                        || $0.payMethod?.holderFour?.id == AppState.shared.user?.id
                    }
                }
                .map { $0.amount }
            
            currentAmount += amounts.reduce(0.0, +)
            switch doWhat {
            case .updateEod:
                day.eodTotal = currentAmount
                
            case .giveMeLastDayEod:
                if day.id == month.days.last?.id {
                    finalEodTotal = currentAmount
                }
            case .giveMeEodAsOfToday:
                if day.id == AppState.shared.todayDay && day.dateComponents?.month == AppState.shared.todayMonth && day.dateComponents?.year == AppState.shared.todayYear {
                    finalEodTotal = currentAmount
                }
            }
        }
        return finalEodTotal
    }
    
    
    private func calculateUnifiedCredit(for month: CBMonth, and doWhat: DoWhatWhenCalculating) -> Double {
        //let creditEodView = CreditEodView.fromString(UserDefaults.standard.string(forKey: "creditEodView") ?? "")
        let creditEodView = LocalStorage.shared.creditEodView
        
        var finalEodTotal: Double = 0.0
        let startingBalance = updateUnifiedStartingAmount(month: month, for: .unifiedCredit)
        var currentAmount = 0.0
        
        switch creditEodView {
        case .availableCredit:
            /// To show available credit.
            let cumulativeLimits = PayMethodModel.shared
                .paymentMethods
                .filter { $0.isCreditOrLoan }
                .filter { $0.isPermitted }
                .filter { !$0.isHidden }
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
                .map { $0.limit ?? 0.0 }
                .reduce(0.0, +)
            
            currentAmount = cumulativeLimits - startingBalance
            
        case .remainingBalance:
            currentAmount = startingBalance
        }
                            
        month.days.forEach { day in
            let amounts = day.transactions
                .filter {
                    ($0.payMethod?.isCreditOrLoan ?? false)
                    && $0.active
                    && $0.factorInCalculations
                    && ($0.payMethod?.isPermitted ?? true)
                    && !($0.payMethod?.isHidden ?? true)
                }
                .filter {
                    switch AppSettings.shared.paymentMethodFilterMode {
                    case .all:
                        return true
                    case .justPrimary:
                        return $0.payMethod?.holderOne?.id == AppState.shared.user?.id
                    case .primaryAndSecondary:
                        return $0.payMethod?.holderOne?.id == AppState.shared.user?.id
                        || $0.payMethod?.holderTwo?.id == AppState.shared.user?.id
                        || $0.payMethod?.holderThree?.id == AppState.shared.user?.id
                        || $0.payMethod?.holderFour?.id == AppState.shared.user?.id
                    }
                }
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
            case .giveMeEodAsOfToday:
                if day.id == AppState.shared.todayDay && day.dateComponents?.month == AppState.shared.todayMonth && day.dateComponents?.year == AppState.shared.todayYear {
                    finalEodTotal = currentAmount
                }
            }
            
        }
        return finalEodTotal
    }
    
    
    private func calculateCredit(for month: CBMonth, using paymentMethod: CBPaymentMethod?, and doWhat: DoWhatWhenCalculating) -> Double {
        //let creditEodView = CreditEodView.fromString(UserDefaults.standard.string(forKey: "creditEodView") ?? "")
        let creditEodView = LocalStorage.shared.creditEodView
        
        var finalEodTotal: Double = 0.0
        let startingBalance = month.startingAmounts.filter { $0.payMethod.id == paymentMethod?.id }.filter { !$0.payMethod.isHidden }.first
        var currentAmount = 0.0
        
        if let startingBalance {
            switch creditEodView {
            case .availableCredit: currentAmount = (paymentMethod?.limit ?? 0.0) - startingBalance.amount
            case .remainingBalance: currentAmount = startingBalance.amount
            }
            
            month.days.forEach { day in
                let amounts = day.transactions
                    .filter {
                        $0.payMethod?.id == paymentMethod?.id
                        && $0.active
                        && $0.factorInCalculations
                        && ($0.payMethod?.isPermitted ?? true)
                        && !($0.payMethod?.isHidden ?? true)
                    }
                    .filter {
                        switch AppSettings.shared.paymentMethodFilterMode {
                        case .all:
                            return true
                        case .justPrimary:
                            return $0.payMethod?.holderOne?.id == AppState.shared.user?.id
                        case .primaryAndSecondary:
                            return $0.payMethod?.holderOne?.id == AppState.shared.user?.id
                            || $0.payMethod?.holderTwo?.id == AppState.shared.user?.id
                            || $0.payMethod?.holderThree?.id == AppState.shared.user?.id
                            || $0.payMethod?.holderFour?.id == AppState.shared.user?.id
                        }
                    }
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
                    
                case .giveMeEodAsOfToday:
                    if day.id == AppState.shared.todayDay && day.dateComponents?.month == AppState.shared.todayMonth && day.dateComponents?.year == AppState.shared.todayYear {
                        finalEodTotal = currentAmount
                    }
                }
            }
        } else {
            print("COULDNT DETERMINE CURRENT BALANCE")
        }
        return finalEodTotal
    }
    
    /// Not private so it can get the daily cash to show in the overall debit total at the top of the calendar.
    /*private*/ func calculateChecking(for month: CBMonth, using paymentMethod: CBPaymentMethod?, and doWhat: DoWhatWhenCalculating) -> Double {
        var finalEodTotal: Double = 0.0
        let startingAmount = month.startingAmounts.filter { $0.payMethod.id == paymentMethod?.id }.filter { !$0.payMethod.isHidden }.first ?? CBStartingAmount()
        var currentAmount = startingAmount.amount
        
        month.days.forEach { day in
            let amounts = day.transactions
                .filter {
                    $0.payMethod?.id == paymentMethod?.id
                    && $0.active
                    && $0.factorInCalculations
                    && ($0.payMethod?.isPermitted ?? true)
                    && !($0.payMethod?.isHidden ?? true)
                }
                .filter {
                    switch AppSettings.shared.paymentMethodFilterMode {
                    case .all:
                        return true
                    case .justPrimary:
                        return $0.payMethod?.holderOne?.id == AppState.shared.user?.id
                    case .primaryAndSecondary:
                        return $0.payMethod?.holderOne?.id == AppState.shared.user?.id
                        || $0.payMethod?.holderTwo?.id == AppState.shared.user?.id
                        || $0.payMethod?.holderThree?.id == AppState.shared.user?.id
                        || $0.payMethod?.holderFour?.id == AppState.shared.user?.id
                    }
                }
                .map { $0.amount }
            
            currentAmount += amounts.reduce(0.0, +)
            switch doWhat {
            case .updateEod:
                day.eodTotal = currentAmount
                
            case .giveMeLastDayEod:
                if day.id == month.days.last?.id {
                    finalEodTotal = currentAmount
                }
                
            case .giveMeEodAsOfToday:
                if day.id == AppState.shared.todayDay && day.dateComponents?.month == AppState.shared.todayMonth && day.dateComponents?.year == AppState.shared.todayYear {
                    finalEodTotal = currentAmount
                }
            }
        }
        return finalEodTotal
    }
    
    
    func calculateSumForDay(for month: CBMonth, and doWhat: DoWhatWhenCalculating) -> Double {
        var finalEodTotal: Double = 0.0
        
        month.days.forEach { day in
            let amount = day.transactions
                .filter {
                    $0.active
                    && $0.factorInCalculations
                    && $0.payMethod?.isPermittedAndViewable ?? true
                    && (self.categoryFilterWasSetByCategoryPage ? self.sCategories.map({ $0.id }).contains($0.category?.id) : true)
                }
                .filter {
                    switch AppSettings.shared.paymentMethodFilterMode {
                    case .all:
                        return true
                    case .justPrimary:
                        return $0.payMethod?.holderOne?.id == AppState.shared.user?.id
                    case .primaryAndSecondary:
                        return $0.payMethod?.holderOne?.id == AppState.shared.user?.id
                        || $0.payMethod?.holderTwo?.id == AppState.shared.user?.id
                        || $0.payMethod?.holderThree?.id == AppState.shared.user?.id
                        || $0.payMethod?.holderFour?.id == AppState.shared.user?.id
                    }
                }
                //.filter { ($0.payMethod?.isPermitted ?? true) }
                //.filter { !($0.payMethod?.isHidden ?? true) }
                .map { ($0.payMethod?.isCreditOrLoan ?? false) ? $0.amount * -1 : $0.amount }
                .reduce(0.0, +)
            
            //print("\(#function) - \(day.date?.day) - \(amount)")
                        
            switch doWhat {
            case .updateEod:
                day.eodTotal = amount
                
            case .giveMeLastDayEod:
                if day.id == month.days.last?.id {
                    finalEodTotal = amount
                }
                
            case .giveMeEodAsOfToday:
                if day.id == AppState.shared.todayDay && day.dateComponents?.month == AppState.shared.todayMonth && day.dateComponents?.year == AppState.shared.todayYear {
                    finalEodTotal = amount
                }
            }
        }
        /// This isn't used anywhere
        return finalEodTotal
    }
    
    
    
    // MARK: - Helpers
    
    func startingAmountSheetDismissed() {
        self.calculateTotal(for: self.sMonth)
        
        /// If the dashboard is open in the inspector on iPad, it won't be recalculate its data on its own.
        /// So we use the ``DataChangeTriggers`` class to send a notification to the view to tell it to recalculate.
        DataChangeTriggers.shared.viewDidChange(.calendar)
        
        Task {
            await withTaskGroup(of: Void.self) { group in
                let starts = self.sMonth.startingAmounts.filter { !$0.payMethod.isUnified }
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
    
    
    
    func prepareForRefresh() {
        months.forEach { month in
            month.days.removeAll()
            month.budgets.removeAll()
            month.startingAmounts.removeAll()
            tempTransactions.removeAll()
        }
        prepareMonths()
    }
    
    
    func prepareMonths() {
        months.forEach { month in
            if month.days.isEmpty {
                if month.firstWeekdayOfMonth != 1 {
                    for i in 0 ..< month.firstWeekdayOfMonth - 1 {
                        month.days.append(CBDay(id: i-50))
                    }
                }
                
                for i in 1 ..< month.dayCount + 1 {
                    var components: DateComponents
                    
                    if month.enumID == .lastDecember {
                        components = DateComponents(year: sYear - 1, month: 12, day: i)
                        
                    } else if month.enumID == .nextJanuary {
                        components = DateComponents(year: sYear + 1, month: 1, day: i)
                        
                    } else {
                        components = DateComponents(year: sYear, month: month.num, day: i)
                    }
                    
                    let theDate = Calendar.current.date(from: components)!
                    month.days.append(CBDay(date: theDate))
                }
            }
        }
    }
                    
    
    func setSelectedMonthFromNavigation(navID: NavDestination, calculateStartingAndEod: Bool) {
        //print("-- \(#function)")
        if let month = months.filter({ $0.enumID == navID }).first {
            sMonth = month
                        
            /// When a user performs navigation, this will run.
            /// Likewise, when the ``FuncModel`` does the initial download, this will not run.
            if calculateStartingAndEod {
                /// Needed for the mac to show the unified starting amount
                //prepareStartingAmount(for: self.sPayMethod)
                
                /// Get  starting amounts, and refresh all the EOD totals.
                /// For example, If I go to another month, and fill out a starting amount, and don't run this, the EOD totals would be wrong when going back to the current month.
                let _ = calculateTotal(for: sMonth)
            }
        } else {
            fatalError("Could not determine month")
        }
    }
    
    
    func populate(options: PopulateOptions, repTransactions: Array<CBRepeatingTransaction>, categories: Array<CBCategory>, categoryGroups: Array<CBCategoryGroup>) {
        print("-- \(#function)")
        //let dateFormatter = DateFormatter()
        
        var repTransToServer: Array<CBTransaction> = []
        var budgetsToServer: Array<CBBudget> = []
        //var budgetGroupsToServer: Array<CBBudgetGroup> = []
        
        
        for meth in options.paymentMethods {
            if meth.doIt {
                for repTrans in repTransactions.filter({ $0.payMethod?.id == meth.id && $0.include }) {
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
                                if let targetDay = targetMonth.days.filter({ $0.dateComponents?.day == Int(when.when.replacing("day", with: "")) ?? 0 }).first {
                                    /// Make sure transaction was not already added.
                                    let addedTrans = targetDay.transactions.filter { $0.repID == repID }.first
                                    if addedTrans == nil {
                                        if repTrans.repeatingTransactionType.enumID != XrefEnum.regular {
                                            processThing(repTrans: repTrans, targetDay: targetDay, repTransToServer: &repTransToServer)
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
                                    if Int(when.when.replacing("day", with: "")) ?? 0 > targetMonth.dayCount {
                                        if repTrans.repeatingTransactionType.enumID == XrefEnum.regular {
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
                                        } else {
                                            if let targetDay = targetMonth.days.last {
                                                processThing(repTrans: repTrans, targetDay: targetDay, repTransToServer: &repTransToServer)
                                            }
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
            
            for group in categoryGroups {
                let budgetExists = !sMonth.budgetGroups.filter { $0.id == group.id }.isEmpty
                if !budgetExists {
                    let budget = CBBudget()
                    budget.month = sMonth.actualNum
                    budget.year = sMonth.year
                    budget.amountString = group.amountString ?? ""
                    budget.categoryGroup = group
                    
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
        
        
        
        func processThing(repTrans: CBRepeatingTransaction, targetDay: CBDay, repTransToServer: inout [CBTransaction]) {
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
                fromTrans.isPaymentOrigin = true
            } else {
                fromTrans.title = "Transfer to \(repTrans.payMethodPayTo?.title ?? "")"
                fromTrans.isTransferOrigin = true
            }
            
            toTrans.relatedTransactionID = fromTrans.id
            toTrans.relatedTransactionType = XrefModel.getItem(from: .relatedTransactionType, byEnumID: .transaction)
            
            
            if repTrans.repeatingTransactionType.enumID == XrefEnum.payment {
                toTrans.title = "Payment from \(repTrans.payMethod?.title ?? "")"
                toTrans.isPaymentDest = true
            } else {
                toTrans.title = "Transfer from \(repTrans.payMethod?.title ?? "")"
                toTrans.isTransferDest = true
            }
                                                        
            if fromTrans.isExpense && repTrans.repeatingTransactionType.enumID != XrefEnum.payment {
                toTrans.amountString = toTrans.amountString.replacing("-", with: "")
            }
            
            
            targetDay.transactions.append(fromTrans)
            repTransToServer.append(fromTrans)
            
            targetDay.transactions.append(toTrans)
            repTransToServer.append(toTrans)
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
            /// Allow more time to save if the user enters the background.
            #if os(iOS)
            var backgroundTaskId = AppState.shared.beginBackgroundTask()
            #endif
            
            LogManager.log()
            
            //let resetModel = ResetMonthModel(month: sMonth.num, year: sYear)
            let model = RequestModel(requestType: "reset_month", model: resetModel)
            
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
                AppState.shared.showAlert("There was a problem trying to save the starting amount.")
                /// End the background task.
                #if os(iOS)
                AppState.shared.endBackgroundTask(&backgroundTaskId)
                #endif
            }
            //LoadingManager.shared.stopDelayedSpinner()
            //self.refreshTask = nil
        }
    }
}




extension CalendarModel: FileUploadCompletedDelegate {
    func displayCompleteAlert(recordID: String, parentType: XrefItem, fileType: FileType) {
        var transTitle: String?
        if let trans = justTransactions.filter({ $0.id == recordID }).first {
            transTitle = trans.title
        }
        
        if !isUploadingSmartTransactionFile {
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
        if self.isUploadingSmartTransactionFile {
            AppState.shared.showToast(
                title: "Analyzing Receipt",
                subtitle: "You will be alerted when analysis is complete",
                body: "(Powered by ChatGPT)",
                symbol: "brain.fill"
            )
        }
    }
    
    
    func cleanUpPhotoVariables() {
        self.isUploadingSmartTransactionFile = false
        self.smartTransactionDate = nil
        #if os(iOS)
        FileModel.shared.imageFromCamera = nil
        #endif
    }
    
    
    func addPlaceholderFile(recordID: String, uuid: String, parentType: XrefItem, fileType: FileType) {
        let picture = CBFile(relatedID: recordID, uuid: uuid, parentType: parentType.enumID, fileType: fileType)
        picture.isPlaceholder = true
        
        if let index = justTransactions.firstIndex(where: { $0.id == recordID }) {
            let trans = justTransactions[index]
            
            if let _ = trans.files {
                trans.files!.append(picture)
            } else {
                trans.files = [picture]
            }
        }
        
        /// Update the searched transactions if they are in the search list and you update them like normal.
        if let index = searchedTransactions.firstIndex(where: { $0.id == recordID }) {
            let trans = searchedTransactions[index]
            
            if let _ = trans.files {
                trans.files!.append(picture)
            } else {
                trans.files = [picture]
            }
        }
        
        /// Update the temp transactions if they are in the search list and you update them like normal. (I don't think this would be very common though).
        if let index = tempTransactions.firstIndex(where: { $0.id == recordID }) {
            let trans = tempTransactions[index]
            
            if let _ = trans.files {
                trans.files!.append(picture)
            } else {
                trans.files = [picture]
            }
        }
        
        /// Update the temp transactions if they are in the search list and you update them like normal. (I don't think this would be very common though).
        if let index = receiptTransactions.firstIndex(where: { $0.id == recordID }) {
            let trans = receiptTransactions[index]
            
            if let _ = trans.files {
                trans.files!.append(picture)
            } else {
                trans.files = [picture]
            }
        }
        
        
        
//        if let targetMonth = months.filter { $0.actualNum == date.month && $0.year == date.year }.first {
//            let targetDays = targetMonth.days
//            let transactions = targetDays.flatMap({ $0.transactions })
//
//            let index = transactions.firstIndex(where: { $0.id == recordID })
//            if let index {
//                if let _ = transactions[index].files {
//                    transactions[index].files!.append(picture)
//                } else {
//                    transactions[index].files = [picture]
//                }
//            }
//        }
    }
            
    
    func markPlaceholderFileAsReadyForDownload(recordID: String, uuid: String, parentType: XrefItem, fileType: FileType) {
//        let targetMonth = months.filter { $0.enumID == sMonth.enumID }.first!
//        let targetDays = targetMonth.days
//        let transactions = targetDays.flatMap({ $0.transactions })
//
//        if let trans = transactions.filter({$0.id == recordID}).first {
//            let index = trans.files?.firstIndex(where: { $0.uuid == uuid })
//            if let index {
//                trans.files?[index].isPlaceholder = false
//            }
//        }
        
        
        if let trans = justTransactions.filter({ $0.id == recordID }).first {
            if let index = trans.files?.firstIndex(where: { $0.uuid == uuid }) {
                trans.files?[index].isPlaceholder = false
            }
        }
        
        /// Update the searched transactions if they are in the search list and you update them like normal.
        if let trans = searchedTransactions.filter({ $0.id == recordID }).first {
            if let index = trans.files?.firstIndex(where: { $0.uuid == uuid }) {
                trans.files?[index].isPlaceholder = false
            }
        }
        
        /// Update the temp transactions if they are in the search list and you update them like normal. (I don't think this would be very common though).
        if let trans = tempTransactions.filter({ $0.id == recordID }).first {
            if let index = trans.files?.firstIndex(where: { $0.uuid == uuid }) {
                trans.files?[index].isPlaceholder = false
            }
        }
        
        /// Update the receipt transactions if they are in the search list and you update them like normal. (I don't think this would be very common though).
        if let trans = receiptTransactions.filter({ $0.id == recordID }).first {
            if let index = trans.files?.firstIndex(where: { $0.uuid == uuid }) {
                trans.files?[index].isPlaceholder = false
            }
        }
    }
        
    
    func markFileAsFailedToUpload(recordID: String, uuid: String, parentType: XrefItem, fileType: FileType) {
//        let targetMonth = months.filter { $0.enumID == sMonth.enumID }.first!
//        let targetDays = targetMonth.days
//        let transactions = targetDays.flatMap({ $0.transactions })
//
//        if let trans = transactions.filter({$0.id == recordID}).first {
//            let index = trans.files?.firstIndex(where: { $0.uuid == uuid })
//            if let index {
//                trans.files?[index].active = false
//            }
//        }
        
        if let trans = justTransactions.filter({ $0.id == recordID }).first {
            if let index = trans.files?.firstIndex(where: { $0.uuid == uuid }) {
                trans.files?[index].active = false
            }
        }
        
        /// Update the searched transactions if they are in the search list and you update them like normal.
        if let trans = searchedTransactions.filter({ $0.id == recordID }).first {
            if let index = trans.files?.firstIndex(where: { $0.uuid == uuid }) {
                trans.files?[index].active = false
            }
        }
        
        /// Update the temp transactions if they are in the search list and you update them like normal. (I don't think this would be very common though).
        if let trans = tempTransactions.filter({ $0.id == recordID }).first {
            if let index = trans.files?.firstIndex(where: { $0.uuid == uuid }) {
                trans.files?[index].active = false
            }
        }
        
        /// Update the receipt transactions if they are in the search list and you update them like normal. (I don't think this would be very common though).
        if let trans = receiptTransactions.filter({ $0.id == recordID }).first {
            if let index = trans.files?.firstIndex(where: { $0.uuid == uuid }) {
                trans.files?[index].active = false
            }
        }
    }
    
        
    func delete(file: CBFile, parentType: XrefItem, fileType: FileType) async {
//        if await FileModel.shared.delete(picture) {
//            let targetMonth = months.filter { $0.enumID == sMonth.enumID }.first!
//            let targetDays = targetMonth.days
//            let transactions = targetDays.flatMap({ $0.transactions })
//
//            let index = transactions.firstIndex(where: { $0.id == picture.relatedID })
//            if let index {
//                transactions[index].files?.removeAll(where: { $0.id == picture.id || $0.uuid == picture.uuid })
//            }
//        } else {
//            AppState.shared.showAlert("There was a problem trying to delete the picture.")
//        }
        
        
        
        if await FileModel.shared.delete(file) {
            if let trans = justTransactions.filter({ $0.id == file.relatedID }).first {
                //if let _ = trans.files?.firstIndex(where: { $0.id == file.id }) {
                    trans.files?.removeAll { $0.id == file.id || $0.uuid == file.uuid }
                //}
            }
            
            /// Update the searched transactions if they are in the search list and you update them like normal.
            if let trans = searchedTransactions.filter({ $0.id == file.relatedID }).first {
                //if let _ = trans.files?.firstIndex(where: { $0.id == file.id }) {
                    trans.files?.removeAll { $0.id == file.id || $0.uuid == file.uuid }
                //}
            }
            
            /// Update the temp transactions if they are in the search list and you update them like normal. (I don't think this would be very common though).
            if let trans = tempTransactions.filter({ $0.id == file.relatedID }).first {
                //if let _ = trans.files?.firstIndex(where: { $0.id == file.id }) {
                    trans.files?.removeAll { $0.id == file.id || $0.uuid == file.uuid }
                //}
            }
                        
            /// Update the receipt transactions if they are in the search list and you update them like normal. (I don't think this would be very common though).
            if let trans = receiptTransactions.filter({ $0.id == file.relatedID }).first {
                //if let _ = trans.files?.firstIndex(where: { $0.id == file.id }) {
                    trans.files?.removeAll { $0.id == file.id || $0.uuid == file.uuid }
                //}
            }
            
        } else {
            AppState.shared.showAlert("There was a problem trying to delete the picture.")
        }
    }
}
