//
//  CalendarModel+Transactions.swift
//  MakeItRain
//
//  Created by Cody Burnett on 8/31/26.
//

import Foundation
import SwiftUI

extension CalendarModel {
    // MARK: - Fetching
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
                    if !sCategories.isEmpty || !sCategoryGroups.isEmpty {
                        let categoryIds = (sCategories + sCategoryGroups.flatMap(\.categories)).map(\.id)
                        return categoryIds.contains { trans.categoryIdsInCurrentAndDeepCopy.contains($0) }
                    } else {
                        return true
                    }
                } else {
                    if !sCategories.isEmpty || !sCategoryGroups.isEmpty {
                        let categoryIds = (sCategories + sCategoryGroups.flatMap(\.categories)).map(\.id)
                        return
                            (trans.title.localizedStandardContains(searchText) || !trans.tags.filter { $0.title.localizedStandardContains(searchText) }.isEmpty)
                            && categoryIds.contains { trans.categoryIdsInCurrentAndDeepCopy.contains($0) }
                        
                    } else {
                        return (trans.title.localizedStandardContains(searchText) || !trans.tags.filter { $0.title.localizedStandardContains(searchText) }.isEmpty)
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
                                trans.title.localizedStandardContains(searchText)
                                && sCategories.map{ $0.id }.contains { trans.categoryIdsInCurrentAndDeepCopy.contains($0) }
                        } else {
                            return
                                !trans.tags.filter { $0.title.localizedStandardContains(searchText) }.isEmpty
                                && sCategories.map{ $0.id }.contains { trans.categoryIdsInCurrentAndDeepCopy.contains($0) }
                        }
                    } else {
                        if searchWhat == .titles {
                            return trans.title.localizedStandardContains(searchText)
                        } else {
                            return !trans.tags.filter { $0.title.localizedStandardContains(searchText) }.isEmpty
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
    
        
    func getTransactions(
        months: Array<CBMonth>? = nil,
        day: Int? = nil,
        meth: CBPaymentMethod? = nil,
        cats: Array<CBCategory>? = nil,
        includeHiddenPaymentMethods: Bool = false,
        includeExcluded: Bool = false
    ) -> Array<CBTransaction> {
        let theMonths: Array<CBMonth> = months ?? [self.sMonth]
        
        //var trans: Array<CBTransaction> = []
        
        let multiSelectIDs = Set(self.multiSelectTransactions.map(\.id))

        
        var trans = theMonths.flatMap { $0.justTransactions }
            .filter {
                $0.active
                /// When refreshing the budget overview aftering deleting a trans, the trans could get captured because the delete process hasn't completed yet.
                && ($0.action != .delete)
                /// If the app is in multi-select mode, pay attention to only those transactions.
//                && (self.isInMultiSelectMode ? self.multiSelectTransactions.map({ $0.id }).contains($0.id) : true)
                && (!self.isInMultiSelectMode || multiSelectIDs.contains($0.id))
                /// Only payment methods that are allowed to be viewed by the current user.
                && $0.isPermitted
                /// This will look at both the transaction, and its deepCopy.
                /// The reason being - in case we change a transaction category or payment method from what is currently being viewed. This will allow the transaction sheet to remain on screen until we close it, at which point the save function will clear the deepCopy.
                && (includeHiddenPaymentMethods ? true : !$0.hasHiddenMethodInCurrentOrDeepCopy)
                /// Only transactions that are not excluded from calculations.
                && (includeExcluded ? true : $0.factorInCalculations)
                
                && ($0.payMethod?.accountHolderFilter() == true)
                
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
//        if let cats = cats {
//            let catIds = cats.map { $0.id }
//
//            trans = trans.filter {
//                catIds.contains($0.categoryIdsInCurrentAndDeepCopy[0] ?? "") || catIds.contains($0.categoryIdsInCurrentAndDeepCopy[1] ?? "")
//            }
//        }
        
        if let cats {
            let catIDs = Set(cats.map(\.id))

            trans = trans.filter {
                let ids = $0.categoryIdsInCurrentAndDeepCopy
                return catIDs.contains(ids[0] ?? "") || catIDs.contains(ids[1] ?? "")
            }
        }
        
        /// Only transactions from a certain day. (If applicable).
        if let day = day {
            trans = trans.filter { $0.dateComponents?.day == day }
        }
        
        /// Sort based on day.
        return trans.sorted { $0.dateComponents?.day ?? 0 < $1.dateComponents?.day ?? 0 }
    }
    
    
    func getTransaction(by id: String, from transactionLocation: WhereToLookForTransaction = .normalList) -> CBTransaction? {
        let theList = switch transactionLocation {
            case .normalList:           justTransactions
            case .tempList, .smartList: tempTransactions
            case .searchResultList:     searchedTransactions
            case .receiptsList:         receiptTransactions
            case .dashboardList:        dashboardTransactions
            case .tagBudgetList:        store.tagBudgetTransactions
        }
        
        if let trans = theList.first(where: { ($0.id == id || $0.serverID == id) }) { return trans }
        return nil
    }
    
    
    
    
    // MARK: - Handling Incoming
    /// Called from..
    /// 1. the long poll when new transactions arrive
    /// 2. when you save a transaction from a non standard location [.smartList, .searchResultList, .receiptsList, .dashboardList, .tagBudgetList]
    /// 3. from `self.handleIncomingData` when it is not supposed to create new structs.
    func handleTransactions(_ transactions: Array<CBTransaction>, for month: CBMonth? = nil, refreshTechnique: RefreshTechnique?) async {
        print("-- \(#function)")
        let pendingSmartTransactionCount = tempTransactions.filter({ $0.isSmartTransaction ?? false }).count
        
        var shouldReloadDashboard = false
        
        for incomingTrans in transactions {
            let id = incomingTrans.id
            let date = incomingTrans.date
            let month = incomingTrans.dateComponents?.month
            let dayNum = incomingTrans.dateComponents?.day
            let year = incomingTrans.dateComponents?.year
            
            await incomingTrans.payMethod?.loadLogoFromCoreDataIfNeeded()
            
            
            var ogObject: CBTransaction?
            
            print("Incoming trans id \(id)")
            
            /// Handle smart transactions.
            if let isSmartTransaction = incomingTrans.isSmartTransaction {
                print("\(id) - is smart")
                if isSmartTransaction && !(incomingTrans.smartTransactionIsAcknowledged ?? true) {
                    print("\(id) - is not acknowledged")
                    if incomingTrans.smartTransactionIssue != nil {
                        print("\(id) - has an issue")
                        if tempTransactions.filter({ $0.id == incomingTrans.id }).isEmpty {
                            tempTransactions.append(incomingTrans)
                        }
                        continue
                    } else {
                        if incomingTrans.active {
                            AppState.shared.showToast(title: "Smart Transaction Added", subtitle: incomingTrans.title, body: "\(incomingTrans.prettyDate ?? "N/A")", symbol: "checkmark", symbolColor: .green)
                        }
                    }
                } else {
                    print("\(id) - is acknowledged")
                    if isSmartTransaction {
                        print("\(id) - is smart 2")
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
            if let index = self.searchedTransactions.firstIndex(where: { $0.id == incomingTrans.id }) {
                searchedTransactions[index].setFromAnotherInstance(transaction: incomingTrans)
                searchedTransactions[index].deepCopy?.setFromAnotherInstance(transaction: incomingTrans)
            }
            
            /// Check if transaction is in the receipts list
            if let index = self.receiptTransactions.firstIndex(where: { $0.id == incomingTrans.id }) {
                receiptTransactions[index].setFromAnotherInstance(transaction: incomingTrans)
                receiptTransactions[index].deepCopy?.setFromAnotherInstance(transaction: incomingTrans)
            } else {
                if let files = incomingTrans.files, !files.isEmpty {
                    /// You have to make a copy, otherwise you will end up with a referenced object in both the main transaction list, and the receipt transaction list. This will cause additional photos that you add to a new smart transaction to be duplicated.
                    let copy = CBTransaction()
                    copy.setFromAnotherInstance(transaction: incomingTrans)
                    copy.deepCopy?.setFromAnotherInstance(transaction: incomingTrans)
                    receiptTransactions.insert(copy, at: 0)
                }
            }
            
            /// Check if the transaction exists locally.
            var dateChanged = false
            var exists = false
            months.forEach { month in
                month.days.forEach { day in
                    day.transactions.forEach { trans in
                        /// Find the local transactions that matches the incoming transaction.
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
                                trans.status = .deleteSuccess
                                
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
                                            CalcHelper.calculateTotal(for: month, store: self.store)
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
            
            
            //print("PROCESSING LOCAQLLY")
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
            
            
            /// Update the calendar dashboard (if applicable)
            if let incomingDate = incomingTrans.date {
                let range = min(dashboardModel.beginDate, dashboardModel.endDate)...max(dashboardModel.beginDate, dashboardModel.endDate)
                if range.contains(incomingDate) {
                    shouldReloadDashboard = true
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
        
        if shouldReloadDashboard && (refreshTechnique == .viaLongPoll || refreshTechnique == nil) {
            print("SHOULD RELOAD DATA FOR LOCAL DASHBOARD 1")
            Task {
                dashboardModel.localVersionOfServerCode(calModel: self)
                dashboardModel.prepareData(calModel: self)
            }
        }
    }
        
    
    /// Only called from `funcModel.fetchMonthlyData()`
    @MainActor
    func handleIncomingData(for month: CBMonth, using model: TransactionAndStartingAmountModel, createNewStructs: Bool, refreshTechnique: RefreshTechnique) async {
        //print("-- \(#function)")
        month.hasBeenPopulated = model.hasPopulated
        
        var shouldReloadDashboard = false
        
        if !createNewStructs {
            await self.handleTransactions(model.transactions, for: month, refreshTechnique: refreshTechnique)
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
                
                /// Update the calendar dashboard (if applicable)
                if let incomingDate = trans.date {
                    let range = min(dashboardModel.beginDate, dashboardModel.endDate)...max(dashboardModel.beginDate, dashboardModel.endDate)
                    if range.contains(incomingDate) {
                        shouldReloadDashboard = true
                    }
                }
                
                await trans.payMethod?.loadLogoFromCoreDataIfNeeded()
                
                //let day = month.days.filter { $0.date == trans.date }.first
                //day?.transactions.append(trans)
            }
            
            let transactionsByDay = Dictionary(grouping: model.transactions) { transaction in
                transaction.dateComponents?.day ?? -1
            }

            for day in month.legitDays {
                day.transactions = transactionsByDay[day.id] ?? []
            }
        }
        
        for startingAmount in model.startingAmounts {
            /// When navigation changes, a new `CBStartingAmount` that corresponds to `self.sPayMethod` gets added to the newly selected month. (for when we navigate to a month that does not yet have one on the server.)
            await startingAmount.payMethod?.loadLogoFromCoreDataIfNeeded()
            if month.startingAmounts.contains(where: { $0.payMethod?.id == startingAmount.payMethod?.id }) {
                let index = month.startingAmounts.firstIndex(where: { $0.payMethod?.id == startingAmount.payMethod?.id })!
                month.startingAmounts[index] = startingAmount
            } else {
                month.startingAmounts.append(startingAmount)
            }
        }
        
        // Begin Before
//        for day in month.legitDays {
//            if let rates = model.exchangeRates?.filter({ $0.date?.day == day.dateComponents?.day }) {
//                day.exchangeRates = rates
//            }
//        }
        // End Before
        // Begin After
        let exchangeRatesByDay = Dictionary(grouping: model.exchangeRates ?? []) { rate in
            rate.date?.day ?? -1
        }

        for day in month.legitDays {
            day.exchangeRates = exchangeRatesByDay[day.id] ?? []
        }
        // End After
        
        
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
        
        if shouldReloadDashboard && createNewStructs {
            print("SHOULD RELOAD DATA FOR LOCAL DASHBOARD 2")
            Task {
                dashboardModel.localVersionOfServerCode(calModel: self)
                //await dashboardModel.fetchDashboard()
                dashboardModel.prepareData(calModel: self)
            }
        }
        
//        if let budgets = model.budgets {
//            for budget in budgets {
//                if let group = budget.categoryGroup {
//                    if month.budgetGroups.contains(where: { $0.id == budget.id }) {
//                        let index = month.budgetGroups.firstIndex(where: { $0.id == budget.id })!
//                        month.budgetGroups[index] = budget
//                    } else {
//                        month.budgetGroups.append(budget)
//                    }
//                } else {
//                    if month.budgets.contains(where: { $0.id == budget.id }) {
//                        let index = month.budgets.firstIndex(where: { $0.id == budget.id })!
//                        month.budgets[index] = budget
//                    } else {
//                        month.budgets.append(budget)
//                    }
//                }
//
//            }
//        }
        
        
        CalcHelper.calculateTotal(for: month, store: store)
        
        /// Run this when switching years.
        if month.enumID == self.sMonth.enumID {
            /// If the dashboard is open in the inspector on iPad, it won't be recalculate its data on its own.
            /// So we use the ``DataChangeTriggers`` class to send a notification to the view to tell it to recalculate.
            DataChangeTriggers.shared.viewDidChange(.calendar)
        }
        
        month.changeLoadingSpinners(toShowing: false, includeCalendar: true)
    }
        
    
    
    
    // MARK: - Saving
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
            if trans.title.isEmpty { print("Title is empty") }
            if trans.payMethod == nil { print("payMethod is nil") }
            /// If a transaction is already existing, and you wipe out the title, put the title back and alert the user.
            if trans.intendedServerAction == .edit && trans.title.isEmpty {
                trans.title = trans.deepCopy?.title ?? ""
                                
                AppState.shared.showAlert(
                    title: "Removing a title from a transaction is not allowed",
                    subtitle: "If you want to delete \"\(trans.title)\", please use the delete button instead."
                )
            } else {
                /// Remove the dud that is in `.add` mode since it was upserted into the list on creation.
                if let transDay = trans.day,
                   let day = sMonth.getDay(by: transDay) {
                    withAnimation {
                        day.remove(trans)
                    }
                }
                
                withAnimation {
                    tempTransactions.removeAll { $0.id == trans.id }
                    store.tagBudgetTransactions.removeAll { $0.id == trans.id }
                    receiptTransactions.removeAll { $0.id == trans.id }
                    searchedTransactions.removeAll { $0.id == trans.id }
                    dashboardTransactions.removeAll { $0.id == trans.id }
                }
            }
            
            if !trans.title.isEmpty && trans.payMethod == nil {
                Task {
                    try await Task.sleep(for: .seconds(0.5))
                    //try? await Task.sleep(nanoseconds: UInt64(0.5 * Double(NSEC_PER_SEC)))
                    AppState.shared.showToast(
                        title: "Failed To Save",
                        subtitle: "Account was missing",
                        body: "",
                        symbol: "exclamationmark.triangle",
                        symbolColor: .orange
                    )
                }
            }
            return false
        }
        
        
        if trans.date == nil && (trans.isSmartTransaction ?? false) {
            print("-- \(#function) -- Trans date is nil and isSmartTransaction")
            Task {
                try await Task.sleep(for: .seconds(0.5))
                //try? await Task.sleep(nanoseconds: UInt64(0.5 * Double(NSEC_PER_SEC)))
                AppState.shared.showToast(
                    title: "Failed To Save",
                    subtitle: "Date was missing",
                    body: "",
                    symbol: "exclamationmark.triangle",
                    symbolColor: .orange
                )
            }
            return false
        }
        
//        if trans.dateChangeViaLongPoll {
//            return true
//        }
        
        /// If there is no changes.
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
  
        
    @MainActor
    @discardableResult
    func saveTransaction(id: String, /*day: CBDay? = nil,*/ location: WhereToLookForTransaction = .normalList) async -> Bool {
        guard let trans = getTransaction(by: id, from: location) else { return true }
        
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
                
        
        if !transactionIsValid(trans: trans/*, day: day*/) {
            print("❌ Trans is not valid to save")
            trans.status = nil
            return false
        }
        
        trans.amountString = trans.amount.currencyWithDecimals(currencyCode: AppState.shared.country.currencyCode)

        print("✅ Trans is valid to save")
            
        /// Go update the normal transaction list if changing that transaction via one of the various other transaction locations.
        if [.smartList, .searchResultList, .receiptsList, .dashboardList, .tagBudgetList].contains(location) {
            await self.handleTransactions([trans], refreshTechnique: nil)
        }
                                
        var saveResultToReturn: Bool = false
        /// Set the updated by user and date.
        trans.updatedBy = AppState.shared.user!
        trans.updatedDate = Date()
        trans.status = .inFlight
        
        
        func updateTransaction(in transactions: inout [CBTransaction], excluding excludedLocation: WhereToLookForTransaction, appendIfMissing: Bool = false) {
            guard location != excludedLocation else { return }
            
            if let index = transactions.firstIndex(where: { $0.id == id }) {
                transactions[index].setFromAnotherInstance(transaction: trans)
                
            } else if appendIfMissing {
                transactions.append(trans)
            }
        }

        updateTransaction(in: &searchedTransactions, excluding: .searchResultList, appendIfMissing: trans.intendedServerAction == .add)
        updateTransaction(in: &tempTransactions, excluding: .tempList)
        updateTransaction(in: &receiptTransactions, excluding: .receiptsList, appendIfMissing: trans.intendedServerAction == .add && !(trans.files?.isEmpty ?? true))
        updateTransaction(in: &store.tagBudgetTransactions, excluding: .tagBudgetList)
        updateTransaction(in: &dashboardTransactions, excluding: .dashboardList)
        
//        if location != .searchResultList {
//            if let index = searchedTransactions.firstIndex(where: { $0.id == id }) {
//                searchedTransactions[index].setFromAnotherInstance(transaction: trans)
//
//            } else if trans.intendedServerAction == .add {
//                searchedTransactions.append(trans)
//            }
//        }
//
//        if location != .tempList {
//            if let index = tempTransactions.firstIndex(where: { $0.id == id }) {
//                tempTransactions[index].setFromAnotherInstance(transaction: trans)
//            }
//        }
//
//        if location != .receiptsList {
//            if let index = receiptTransactions.firstIndex(where: { $0.id == id }) {
//                receiptTransactions[index].setFromAnotherInstance(transaction: trans)
//
//            } else if trans.intendedServerAction == .add && (trans.files?.count ?? 0) > 0 {
//                receiptTransactions.append(trans)
//            }
//        }
//
//        if location != .tagBudgetList {
//            if let index = store.tagBudgetTransactions.firstIndex(where: { $0.id == id }) {
//                store.tagBudgetTransactions[index].setFromAnotherInstance(transaction: trans)
//            }
//        }
//
//        if location != .dashboardList {
//            if let index = dashboardTransactions.firstIndex(where: { $0.id == id }) {
//                dashboardTransactions[index].setFromAnotherInstance(transaction: trans)
//            }
//        }
        
        
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
                && trans.relatedTransactionType == .transaction// XrefModel.getItem(from: .relatedTransactionType, byEnumID: .transaction)
                //&& trans.relatedTransactionType == XrefModel.getItem(from: .relatedTransactionType, byEnumID: .transaction)
            {
                if let trans2 = getTransaction(by: trans.relatedTransactionID!, from: .normalList) {
                    trans2.intendedServerAction = .delete
                    await self.delete(trans2, andSubmit: true)
                }
                
                saveResultToReturn = await self.delete(trans, andSubmit: true)
                
            } else {
                saveResultToReturn = await self.delete(trans, andSubmit: true)
            }
            // Only a data change trigger is after this code.
            
        } else {
            /// Recalculate totals for each day.
            Task {
                CalcHelper.calculateTotal(for: sMonth, store: store)
            }
            
            //let toastLingo = "Successfully \(trans.action == .add ? "Added" : "Updated")"
            
            /// Check if the transaction has a related ID (like from a transfer or payment).
            /// This will not handle event transactions!
            if trans.relatedTransactionID != nil
            && trans.relatedTransactionType != .split
            && trans.intendedServerAction != .add
            && trans.relatedTransactionType == .transaction, // XrefModel.getItem(from: .relatedTransactionType, byEnumID: .transaction),
            let trans2 = getTransaction(by: trans.relatedTransactionID!, from: .normalList) {
                                    
                
                //print("the paymethod is \(trans.payMethod?.title)")
                //print("the deep paymethod is \(trans.deepCopy?.payMethod?.title)")
                
                
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
        
        if let date = trans.date {
            let range = min(dashboardModel.beginDate, dashboardModel.endDate)...max(dashboardModel.beginDate, dashboardModel.endDate)
            if range.contains(date) {
                Task {
                    dashboardModel.localVersionOfServerCode(calModel: self)
                    dashboardModel.prepareData(calModel: self)
                }
            }
        }
        
        /// Check to see if the transaction was part of the data that powers the dashboard.
        /// If so, tell the dashboard to reload itself from the server.
        if let date = trans.date {
//            let range = min(dashboardModel.beginDate, dashboardModel.endDate)...max(dashboardModel.beginDate, dashboardModel.endDate)
//            let transIsPartOfDashboard = range.contains(date)
//            if transIsPartOfDashboard {
//                self.dashboardModel.isDirty = true
//            }
//
//
//            let range2 = min(calendarDashboardModel.beginDate, calendarDashboardModel.endDate)...max(calendarDashboardModel.beginDate, calendarDashboardModel.endDate)
//            let transIsPartOfDashboard2 = range2.contains(date)
//            if transIsPartOfDashboard2 {
//                self.calendarDashboardModel.isDirty = true
//                await calendarDashboardModel.initialFetchIfApplicable(catModel: catModel)
//            }
        }
        
        
        return saveResultToReturn
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
    
    
    
   
    // MARK: - Networking
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
                entity.amount = trans.amount as NSDecimalNumber
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
                entity.action = trans.intendedServerAction.rawValue
                entity.tempAction = trans.action == .add ? "edit" : trans.intendedServerAction.rawValue
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
        let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model, timeout: 10)
                    
        switch result {
        case .success(let model):
            LogManager.networkingSuccessful()
            
            /// Performs in its own context
            print("Attempting to delete trans from core data with id \(trans.id)")
            DataManager.shared.delete(context: context, type: TempTransaction.self, predicate: .byId(.string(trans.id)))
            
            if trans.isFromCoreData {
                let actualTrans = justTransactions.first(where: { $0.id == trans.id })
                if let actualTrans {
                    actualTrans.serverID = String(model?.parentID.id ?? "0")
                    //actualTrans.uuid = nil
                    actualTrans.intendedServerAction = .edit
                }
            } else {
                trans.serverID = String(model?.parentID.id ?? "0")
                //trans.uuid = nil
                trans.intendedServerAction = .edit
            }
                                                
            /// Update any tags / locations that were added for the first time via this transaction with their new DBID.
            for each in model?.childIDs ?? [] {
                if each.type == "tag" {
                    let index = store.tags.firstIndex(where: { $0.uuid == each.uuid })
                    if let index {
                        store.tags[index].id = String(each.id)
                    }
                } else if each.type == "transaction_location" {
                    let index = trans.locations.firstIndex(where: { $0.uuid == each.uuid })
                    if let index {
                        trans.locations[index].id = String(each.id)
                    }
                }
            }
            
            isThinking = false
//            if trans.action == .delete {
//                //trans.status = nil
//                trans.status = .deleteSuccess
//            } else {
//                trans.status = .saveSuccess
//            }
            performLineItemAnimations(for: trans, wasSuccessful: true)
                        
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
            //return true
            
        case .failure(let error):
            print("❌Transaction failed to save")
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to save the transaction. Will try again at a later time.")
            //trans.deepCopy(.restore)

            isThinking = false
            trans.action = .edit
            //trans.status = .saveFail
            performLineItemAnimations(for: trans, wasSuccessful: false)
            
            /// Cancel the loading spinner if it hasn't started, otherwise hide it,
            stopDelayedLoadingSpinnerTimer()
            LoadingManager.shared.stopLongNetworkTimer()
            
            /// End the background task.
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
            #endif
            
            /// Return unsuccessful save result to the caller.
            //return false
        }
        
        return result.isSuccess
    }
    
    
    /// Only called via `saveTransaction(id: day:)`.
//    @discardableResult
//    private func delete(_ trans: CBTransaction) async -> Bool {
//        print("-- \(#function)")
//        trans.action = .delete
//        trans.actionBeforeSave = trans.action
//        trans.intendedServerAction = .delete
//        withAnimation {
////            if let targetMonth = months.filter({ $0.actualNum == trans.dateComponents?.month && $0.year == trans.dateComponents?.year }).first {
////                if let day = targetMonth.days.filter({ $0.dateComponents?.day == trans.dateComponents?.day }).first {
////                    day.remove(trans)
////                    let _ = calculateTotal(for: sMonth)
////                }
////            }
//
//            tempTransactions.removeAll { $0.id == trans.id }
//        }
//
//        //Task { @MainActor in
//        let saveResult = await submit(trans)
//        return saveResult
//            //self.handleSavingOfEventTransaction(trans: trans, eventModel: eventModel)
//        //}
//    }
    
    
    @discardableResult
    func delete(_ trans: CBTransaction, andSubmit: Bool) async -> Bool {
        print("-- \(#function)")
        trans.action = .delete
        trans.actionBeforeSave = trans.action
        trans.intendedServerAction = .delete
        withAnimation {
            tempTransactions.removeAll { $0.id == trans.id }
            store.tagBudgetTransactions.removeAll { $0.id == trans.id }
            receiptTransactions.removeAll { $0.id == trans.id }
            searchedTransactions.removeAll { $0.id == trans.id }
            dashboardTransactions.removeAll { $0.id == trans.id }
        }
           
        if andSubmit {
            return await submit(trans)
        } else {
            if let transMonth = trans.month,
               let transYear = trans.year,
               let transDay = trans.day,
               let targetMonth = months.get(by: (transMonth, transYear)),
               let targetDay = targetMonth.getDay(by: transDay)
            {
                targetDay.remove(trans)
                CalcHelper.calculateTotal(for: sMonth, store: store)
            }
//            if let targetMonth = months.filter({ $0.actualNum == trans.dateComponents?.month && $0.year == trans.dateComponents?.year }).first {
//                if let day = targetMonth.days.filter({ $0.dateComponents?.day == trans.dateComponents?.day }).first {
//                    day.remove(trans)
//                    CalcHelper.calculateTotal(for: sMonth, store: store)
//                }
//            }
            return false
        }
    }
    
    
    /// Only called from `funcModel.downloadEverything()`.
    /// Only here to allow `self.submit()` to be private.
    func saveTemp(trans: CBTransaction) async {
        let _ = await submit(trans)
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
        let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch result {
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
    
    
        
    
    
    // MARK: - Adding / Editing Multiple
    @MainActor
    func addMultiple(trans: Array<CBTransaction>, budgets: Array<CBBudgetItem>, isTransfer: Bool) async {
        #if os(iOS)
        var backgroundTaskId = AppState.shared.beginBackgroundTask()
        #endif
        /// If the dashboard is open in the inspector on iPad, it won't be recalculate its data on its own.
        /// So we use the ``DataChangeTriggers`` class to send a notification to the view to tell it to recalculate.
        DataChangeTriggers.shared.viewDidChange(.calendar)
                
        for each in trans {
            each.status = .inFlight
            //each.amountUsd = each.amount
            //each.originalUnconvertedAmount = each.amount
        }
                
        LogManager.log()
        
        let repModel = RepeatingAndBudgetSubmissionModel(
            month: sMonth.actualNum,
            year: sMonth.year,
            transactions: trans,
            budgets: budgets,
            isTransfer: isTransfer
        )
        
        let model = RequestModel(requestType: "add_populated_transactions_and_budgets", model: repModel)
        typealias ResultResponse = Result<PopulatedMonthResultModel?, AppError>
        let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch result {
        case .success(let model):
            LogManager.networkingSuccessful()
            if let model {
                for idModel in model.recordInfos {
                    let targetMonth = months.get(byEnumId: sMonth.enumID)
                    
                    if idModel.type == "transaction" {
                        let targetDays = targetMonth.days
                        let transactions = targetDays.flatMap({ $0.transactions })
                                                                        
                        if let index = transactions.firstIndex(where: { $0.id == idModel.uuid ?? "" }) {
                            transactions[index].serverID = String(idModel.id)
                            transactions[index].action = .edit
                            transactions[index].intendedServerAction = .edit
                            //transactions[index].status = .saveSuccess
                            if let relatedID = idModel.relatedID {
                                transactions[index].relatedTransactionID = String(relatedID)
                            }
                            performLineItemAnimations(for: transactions[index], wasSuccessful: true)
                        }
                    } else {
                        if let index = targetMonth.budgets.firstIndex(where: { $0.id == idModel.uuid }) {
                            targetMonth.budgets[index].id = idModel.id
                            targetMonth.budgets[index].action = .edit
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
                //each.status = .saveFail
                performLineItemAnimations(for: each, wasSuccessful: false)
            }
            
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
            #endif
        }
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
            if each.status != .deleteSuccess {
                each.status = .inFlight
            }
            
            each.updatedBy = AppState.shared.user!
            each.updatedDate = Date()
            
            //each.amountUsd = each.amount
            //each.originalUnconvertedAmount = each.amount
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
        let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch result {
        case .success(let model):
            LogManager.networkingSuccessful()
            if let model {
                for parent in model {
                    if let foundTrans = trans.filter({ $0.uuid == parent.parentID.uuid }).first {
                        if foundTrans.action == .add {
                            foundTrans.serverID = String(parent.parentID.id)
                            //foundTrans.uuid = nil
                            foundTrans.action = .edit
                            foundTrans.duplicateFileRecordsOnDb = false
                            
                            
                            /// Update any tags / locations / files that were added for the first time via this transaction with their new DBID.
                            for each in parent.childIDs {
                                if each.type == "tag" {
                                    let index = store.tags.firstIndex(where: { $0.uuid == each.uuid })
                                    if let index {
                                        store.tags[index].id = String(each.id)
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
                            //foundTrans.status = .saveSuccess
                            
                        } else if foundTrans.action == .delete {
                            //foundTrans.status = .deleteSuccess
                            tempTransactions.removeAll { $0.id == foundTrans.id }
                            //foundTrans.status = .deleteSuccess
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
                        
                        performLineItemAnimations(for: foundTrans, wasSuccessful: true)
                        #warning("Fix me")
//                        {
//                            tempTransactions.removeAll { $0.id == foundTrans.id }
//                        }
                        
                    }
                }
                
                #if os(iOS)
                AppState.shared.endBackgroundTask(&backgroundTaskId)
                #endif
                                
                print("Multi-update successful")
                print("SHOULD RELOAD DATA FOR LOCAL DASHBOARD 5")
                dashboardModel.localVersionOfServerCode(calModel: self)
                dashboardModel.prepareData(calModel: self)
            
            }
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to update multiple transactions.")
            #warning("Undo behavior")
            
            for each in trans {
                //each.status = .saveFail
                performLineItemAnimations(for: each, wasSuccessful: false)
            }
                                    
            #if os(iOS)
            AppState.shared.endBackgroundTask(&backgroundTaskId)
            #endif
        }
    }
        
    
    
    
    // MARK: - UI Helpers
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
        
    
    func performLineItemAnimations(for trans: CBTransaction, wasSuccessful: Bool) {
        Task {
            await Helpers.performLineItemAnimations(for: trans, wasSuccessful: wasSuccessful) {
                if let month = self.months.first(where: { $0.isNow }),
                   let day = month.days.first(where: { $0.id == trans.dateComponents?.day }) {
                    day.remove(trans)
                    CalcHelper.calculateTotal(for: self.sMonth, store: self.store)
                }
            }
        }
        
        
        
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            /// This triggers drawOff (reverse of drawOn)
//            withAnimation(.easeOut(duration: 0.8)) {
//                trans.status = .dummy
//            }
//
//            /// STEP 3 — Wait for drawOff to finish (~0.6s)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
//                withAnimation(.easeOut(duration: 0.6)) {
//                    trans.status = nil
//
//                    if trans.action == .delete {
////                        if let targetMonth = self.months.filter({ $0.actualNum == trans.dateComponents?.month && $0.year == trans.dateComponents?.year }).first {
////                            if let day = targetMonth.days.filter({ $0.dateComponents?.day == trans.dateComponents?.day }).first {
////                                day.remove(trans)
////                                CalcHelper.calculateTotal(for: self.sMonth, store: self.store)
////                            }
////                        }
//
//
//                        if let month = self.months.first(where: { $0.isNow }),
//                           let day = month.days.first(where: { $0.id == trans.dateComponents?.day }) {
//                            day.remove(trans)
//                            CalcHelper.calculateTotal(for: self.sMonth, store: self.store)
//                        }
//                    }
//                }
//            }
//        }
    }
                
    
    
    
    // MARK: - Copy & Paste
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
                
                if let relatedId = trans.relatedTransactionID,
                    let relatedTrans = self.getTransaction(by: relatedId) {
                    
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
}
