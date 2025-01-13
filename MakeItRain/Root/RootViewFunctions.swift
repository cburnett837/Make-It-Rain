////
////  RootViewFunctions.swift
////  MakeItRain
////
////  Created by Cody Burnett on 10/16/24.
////
//
//import Foundation
//import SwiftUI
//
//extension RootView {
//    func downloadEverything(setDefaultPayMethod: Bool, createNewStructs: Bool, refreshTechnique: RefreshTechnique) async {
//        /// Restart long poll (if applicable).
//        longPollServerForChanges()
//        
//        //payModel.paymentMethods.removeAll()
//        
//        /// Reset loading visuals (if applicable).
//        if createNewStructs {
//            /// Removing these will trigger the loading spinners on all views.
//            AppState.shared.downloadedData.removeAll()
//            LoadingManager.shared.downloadAmount = 0
//        }
//        
//        
//        do {
//            if let entities = try DataManager.shared.getMany(type: TempTransaction.self) {
//                for entity in entities {
//                    var category: CBCategory?
//                    var payMethod: CBPaymentMethod?
//                    
//                    
//                    if let categoryID = entity.categoryID {
//                        if let perCategory = DataManager.shared.getOne(type: PersistentCategory.self, predicate: .byId(.string(categoryID)), createIfNotFound: false) {
//                            category = CBCategory(entity: perCategory)
//                        }
//                    }
//                    
//                    if let payMethodID = entity.payMethodID {
//                        if let perPayMethod = DataManager.shared.getOne(type: PersistentPaymentMethod.self, predicate: .byId(.string(payMethodID)), createIfNotFound: false) {
//                            payMethod = CBPaymentMethod(entity: perPayMethod)
//                        }
//                    }
//                    
//                    if let payMethod = payMethod {
//                        let _ = await calModel.submit(CBTransaction(entity: entity, payMethod: payMethod, category: category))
//                    }
//                    
//                }
//            }
//            
//            
//            let pred = NSPredicate(format: "isPending == %@", NSNumber(value: true))
//            
//            guard let entities = try DataManager.shared.getMany(type: PersistentCategory.self, predicate: .single(pred)) else { return }
//            for entity in entities { let _ = await catModel.submit(CBCategory(entity: entity)) }
//                        
//            guard let entities = try DataManager.shared.getMany(type: PersistentKeyword.self, predicate: .single(pred)) else { return }
//            for entity in entities { let _ = await keyModel.submit(CBKeyword(entity: entity)) }
//            
//            guard let entities = try DataManager.shared.getMany(type: PersistentPaymentMethod.self, predicate: .single(pred)) else { return }
//            for entity in entities { let _ = await payModel.submit(CBPaymentMethod(entity: entity)) }
//        } catch {
//            print(error.localizedDescription)
//        }
//                
//                    
//        withAnimation {
//            if createNewStructs {
//                /// This is the progress bar at the bottom of the navigation stack.
//                LoadingManager.shared.showLoadingBar = true
//            }
//        }
//        
//        /// Populate items from cache
//        populatePaymentMethodsFromCache(setDefaultPayMethod: setDefaultPayMethod)
//        populateCategoriesFromCache()
//        populateKeywordsFromCache()
//        //populateTagsFromCache()
//        
//        var next: CBMonth?
//        var prev: CBMonth?
//        var start: Double?
//        
//        /// See if the user is looking at a month or an accessorial view.
//        let currentView = NavigationManager.shared.selection
//        if let currentView {
//            
//            /// If viewing a month, determine current and adjacent months.
//            if NavDestination.justMonths.contains(currentView) {
//                
//                /// Grab Payment Methods (only not logging in. We need this to have a payment method in place before the viewing month loads.)
//                if AppState.shared.isLoggingInForFirstTime {
//                    await payModel.fetchPaymentMethods(calModel: calModel)
//                }
//                
//                let viewingMonth = calModel.months.filter { $0.num == NavigationManager.shared.selection?.monthNum }.first!
//                if ![.lastDecember, .nextJanuary].contains(viewingMonth.enumID) {
//                    next = calModel.months.filter { $0.num == (NavigationManager.shared.selection?.monthNum ?? 0) + 1 }.first!
//                    prev = calModel.months.filter { $0.num == (NavigationManager.shared.selection?.monthNum ?? 0) - 1 }.first!
//                }
//                
//                /// Download viewing month.
//                start = await downloadViewingMonth(viewingMonth, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique)
//                /// Download adjacent months.
//                await downloadAdjacentMonth(next: next, prev: prev, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique)
//                /// Download other months and accessorials.
//                await downloadOtherMonthsAndAccessorials(viewingMonth: viewingMonth, next: next, prev: prev, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique)
//                
//            } else {
//                /// Run this code if we come back from a sceneChange and are not viewing a month.
//                /// If we're not viewing a month, then we must be viewing an accessorial view, so download those first.
//                if NavDestination.justAccessorials.contains(currentView) {
//                    await downloadAccessorials(createNewStructs: createNewStructs)
//                    start = await downloadViewingMonth(calModel.sMonth, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique)
//                    await downloadAdjacentMonth(next: next, prev: prev, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique)
//                    await downloadOtherMonths(viewingMonth: calModel.sMonth, next: next, prev: prev, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique)
//                }
//            }
//        }
//                
//        withAnimation {
//            if createNewStructs {
//                LoadingManager.shared.showLoadingBar = false
//            }
//        }
//        self.refreshTask = nil
//        
//        let final = CFAbsoluteTimeGetCurrent() - (start ?? 0.0)
//        print("🔴Everything took \(final) seconds to fetch")
//    }
//    
//    
//    // MARK: - Downloading Stuff
//    private func downloadViewingMonth(_ viewingMonth: CBMonth, createNewStructs: Bool, refreshTechnique: RefreshTechnique) async -> CFAbsoluteTime {
//        /// Grab the viewing month first.
//        let start = CFAbsoluteTimeGetCurrent()
//        await calModel.fetchFromServer(month: viewingMonth, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique)
//        withAnimation {
//            if createNewStructs {
//                LoadingManager.shared.showInitiallyLoadingSpinner = false
//            }
//        }
//        
//        let currentElapsed = CFAbsoluteTimeGetCurrent() - start
//        print("🔴It took \(currentElapsed) seconds to fetch the first month")
//        return start
//    }
//        
//    
//    private func downloadAdjacentMonth(next: CBMonth?, prev: CBMonth?, createNewStructs: Bool, refreshTechnique: RefreshTechnique) async {
//        /// Grab months adjacent to viewing month.
//        let adjacentStart = CFAbsoluteTimeGetCurrent()
//        await withTaskGroup(of: Void.self) { group in
//            if let next { group.addTask { print("fetching \(next.num)"); await calModel.fetchFromServer(month: next, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique) } }
//            if let prev { group.addTask { print("fetching \(prev.num)"); await calModel.fetchFromServer(month: prev, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique) } }
//        }
//        
//        let adjacentElapsed = CFAbsoluteTimeGetCurrent() - adjacentStart
//        print("🔴It took \(adjacentElapsed) seconds to fetch the Adjacent months")
//    }
//    
//    
//    private func downloadOtherMonths(viewingMonth: CBMonth, next: CBMonth?, prev: CBMonth?, createNewStructs: Bool, refreshTechnique: RefreshTechnique) async {
//        /// Grab all the other months & extra data (payment methods, categories, etc)
//        let everythingElseStart = CFAbsoluteTimeGetCurrent()
//        await withTaskGroup(of: Void.self) { group in
//            for month in calModel.months {
//                if let next {
//                    if month.num == next.num { continue }
//                }
//                if let prev {
//                    if month.num == prev.num { continue }
//                }
//                if month.num != viewingMonth.num {
//                    group.addTask { print("fetching \(month.num)"); await calModel.fetchFromServer(month: month, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique) }
//                }
//            }
//        }
//        
//        let everytingElseElapsed = CFAbsoluteTimeGetCurrent() - everythingElseStart
//        print("🔴It took \(everytingElseElapsed) seconds to fetch all other months")
//    }
//    
//    
//    private func downloadAccessorials(createNewStructs: Bool) async {
//        /// Grab all the other months & extra data (payment methods, categories, etc)
//        let everythingElseStart = CFAbsoluteTimeGetCurrent()
//        await withTaskGroup(of: Void.self) { group in
//            
//            /// Grab Tags.
//            group.addTask { await calModel.fetchTags() }
//            
//            /// Grab Payment Methods (only if not logging in. If logging in, they are fetched before the viewing month is fetched)
//            if !AppState.shared.isLoggingInForFirstTime {
//                group.addTask { await payModel.fetchPaymentMethods(calModel: calModel) }
//            }
//            /// Grab Categories.
//            group.addTask { await catModel.fetchCategories() }
//            /// Grab Keywords.
//            group.addTask { await keyModel.fetchKeywords() }
//            /// Grab Repeating Transactions.
//            group.addTask { await repModel.fetchRepeatingTransactions() }
//        }
//        
//        let everytingElseElapsed = CFAbsoluteTimeGetCurrent() - everythingElseStart
//        print("🔴It took \(everytingElseElapsed) seconds to fetch all accessorials")
//    }
//    
//        
//    private func downloadOtherMonthsAndAccessorials(viewingMonth: CBMonth, next: CBMonth?, prev: CBMonth?, createNewStructs: Bool, refreshTechnique: RefreshTechnique) async {
//        /// Grab all the other months & extra data (payment methods, categories, etc)
//        let everythingElseStart = CFAbsoluteTimeGetCurrent()
//        
//        await withTaskGroup(of: Void.self) { group in
//            
//            /// Grab Tags.
//            group.addTask { await calModel.fetchTags() }
//            
//            for month in calModel.months {
//                if let next {
//                    if month.num == next.num { continue }
//                }
//                if let prev {
//                    if month.num == prev.num { continue }
//                }
//                if month.num != viewingMonth.num {
//                    group.addTask { print("fetching \(month.num)"); await calModel.fetchFromServer(month: month, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique) }
//                }
//            }
//            
//            /// Grab Payment Methods.
//            group.addTask { await payModel.fetchPaymentMethods(calModel: calModel) }
//            /// Grab Categories.
//            group.addTask { await catModel.fetchCategories() }
//            /// Grab Keywords.
//            group.addTask { await keyModel.fetchKeywords() }
//            /// Grab Repeating Transactions.
//            group.addTask { await repModel.fetchRepeatingTransactions() }
//            
////            group.addTask {
////                let model = RequestModel(requestType: "fetch_accessorials", model: CodablePlaceHolder())
////                typealias ResultResponse = Result<AccessorialModel?, AppError>
////                async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
////
////                switch await result {
////                case .success(let model):
////                    if let model {
////                        await MainActor.run {
////                            payModel.paymentMethods = model.payMethods
////                            catModel.categories = model.categories
////                            keyModel.keywords = model.keywords
////                            repModel.repTransactions = model.repeatingTransactions
////
////                            AppState.shared.downloadedData.append(.repeatingTransactions)
////                            AppState.shared.downloadedData.append(.paymentMethods)
////                            AppState.shared.downloadedData.append(.categories)
////                            AppState.shared.downloadedData.append(.keywords)
////                        }
////                    }
////
////                case .failure (let error):
////                    LogManager.error(error.localizedDescription)
////                    AppState.shared.showAlert("There was a problem trying to fetch transactions.")
////                }
////            }
//            
//            
//        }
//        withAnimation {
//            LoadingManager.shared.downloadAmount += 10
//        }
//        let everytingElseElapsed = CFAbsoluteTimeGetCurrent() - everythingElseStart
//        print("🔴It took \(everytingElseElapsed) seconds to fetch all other months")
//    }
//    
//    /// Not private because it is called directly from the RootView
//    func populatePaymentMethodsFromCache(setDefaultPayMethod: Bool) {
//        /// Populate payment methods from cache.
//        do {
//            let meths = try DataManager.shared.getMany(type: PersistentPaymentMethod.self)
//            if let meths {
//                meths
//                .sorted { ($0.title ?? "").lowercased() < ($1.title ?? "").lowercased() }
//                .forEach { meth in
//                    if setDefaultPayMethod && meth.isDefault {
//                        calModel.sPayMethod = CBPaymentMethod(entity: meth)
//                    }
//                    if payModel.paymentMethods.filter({ $0.id == meth.id! }).isEmpty {
//                        payModel.paymentMethods.append(CBPaymentMethod(entity: meth))
//                    }
//                    
//                    #warning("remove this")
//                    let notifications = NotificationManager.shared.scheduledNotifications.filter { $0.payMethodID == meth.id }
//                    if !notifications.isEmpty {
//                        NotificationManager.shared.createReminder2(payMethod: CBPaymentMethod(entity: meth))
//                    }
//                }
//                                
//                //payModel.paymentMethods.sort { $0.title < $1.title }
//            }
//        } catch {
//            fatalError("Could not find paymentMethods from cache")
//        }
//    }
//        
//    
//    private func populateCategoriesFromCache() {
//        /// Populate categories from cache.
//        do {
//            let cats = try DataManager.shared.getMany(type: PersistentCategory.self)
//            if let cats {
//                cats
//                .sorted { ($0.title ?? "").lowercased() < ($1.title ?? "").lowercased() }
//                .forEach { cat in
//                    print(cat.title)
//                    if catModel.categories.filter({ $0.id == cat.id! }).isEmpty {
//                        catModel.categories.append(CBCategory(entity: cat))
//                    }
//                }
//            }
//            
//            //catModel.categories.sort { $0.title < $1.title }
//            
//        } catch {
//            fatalError("Could not find categories from cache")
//        }
//    }
//    
//    
//    private func populateKeywordsFromCache() {
//        /// Populate keywords from cache.
//        do {
//            let keys = try DataManager.shared.getMany(type: PersistentKeyword.self)
//            if let keys {
//                keys
//                .sorted { ($0.keyword ?? "").lowercased() < ($1.keyword ?? "").lowercased() }
//                .forEach { key in
//                    if keyModel.keywords.filter({ $0.id == key.id! }).isEmpty {
//                        keyModel.keywords.append(CBKeyword(entity: key))
//                    }
//                }
//            }
//            
//            //keyModel.keywords.sort { $0.keyword < $1.keyword }
//            
//        } catch {
//            fatalError("Could not find keywords from cache")
//        }
//    }
//    
////    private func populateTagsFromCache() {
////        /// Populate keywords from cache.
////        do {
////            let tags = try DataManager.shared.getMany(type: PersistentTag.self)
////            if let tags {
////                tags.forEach { tag in
////                    if tagModel.tags.filter({ $0.id == tag.id }).isEmpty {
////                        tagModel.tags.append(CBTag(entity: tag))
////                    }
////                }
////            }
////            
////            tagModel.tags.sort { $0.tag < $1.tag }
////            
////        } catch {
////            fatalError("Could not find tags from cache")
////        }
////    }
//    
//    
//    // MARK: - Long Poll Stuff
//    func longPollServerForChanges() {
//        print("-- \(#function)")
//        
//        if longPollTask == nil {
//            print("Longpoll task does not exist. Creating.")
//            longPollTask = Task {
//                await longPollServer()
//            }
//        } else {
//            print("Longpoll task exists")
//            if longPollTask!.isCancelled {
//                print("Long poll task has been cancelled. Restarting")
//                longPollTask = Task {
//                    await longPollServer()
//                }
//            } else {
//                print("Long poll task has not been cancelled and is running. Ignoring.")
//            }
//        }
//        
//        @MainActor
//        func longPollServer() async {
//            //return
//            print("-- \(#function)")
//            LogManager.log()
//                                
//            let model = RequestModel(requestType: "longpoll_server", model: CodablePlaceHolder())
//            typealias ResultResponse = Result<LongPollModel?, AppError>
//            async let result: ResultResponse = await NetworkManager().longPollServer(requestModel: model)
//            
//            switch await result {
//            case .success(let model):
//                LogManager.networkingSuccessful()
//                
//                if let model {
//                    if let transactions = model.transactions { self.handleLongPollTransactions(transactions) }
//                    if let startingAmounts = model.startingAmounts { self.handleLongPollStartingAmounts(startingAmounts) }
//                    if let repeatingTransactions = model.repeatingTransactions { await self.handleLongPollRepeatingTransactions(repeatingTransactions) }
//                    if let payMethods = model.payMethods { await self.handleLongPollPaymentMethods(payMethods) }
//                    if let categories = model.categories { await self.handleLongPollCategories(categories) }
//                    if let keywords = model.keywords { await self.handleLongPollKeywords(keywords) }
//                    if let budgets = model.budgets { self.handleLongPollBudgets(budgets) }
//                }
//                
//                print("restarting longpoll - \(Date())")
//                await longPollServer()
//                
//            case .failure (let error):
//                switch error {
//                case .taskCancelled:
//                    /// Task gets cancelled when logging out. So only show the alert if the error is not related to the task being cancelled.
//                    print("Task Cancelled")
//                default:
//                    LogManager.error(error.localizedDescription)
//                    print(error.localizedDescription)
//                    AppState.shared.longPollFailed = true
//                    
//                    longPollTask?.cancel()
//                    longPollTask = nil
//                    AppState.shared.showAlert("There was a problem subscribing to multi-device updates.", buttonText: "Retry") {
//                        
//                        Task {
//                            AppState.shared.longPollFailed = false
//                            await downloadEverything(setDefaultPayMethod: false, createNewStructs: false, refreshTechnique: .viaLongPoll)
//                        }
//                        
//                        
//                        //longPollServerForChanges()
//                    }
//                }
//            }
//        }
//    }
//    
//    
//    private func handleLongPollTransactions(_ transactions: Array<CBTransaction>) {
//        calModel.handleTransactions(transactions, refreshTechnique: .viaLongPoll)
//        
//        let months = transactions.map { $0.dateComponents?.month }.uniqued()
//        months.forEach { month in
//            let montObj = calModel.months.filter{ $0.num == month }.first!
//            calModel.calculateTotalForMonth(month: montObj)
//        }
//    }
//    
//    
//    private func handleLongPollStartingAmounts(_ startingAmounts: Array<CBStartingAmount>) {
//        for startingAmount in startingAmounts {
//            let month = startingAmount.month
//            //let year = startingAmount.year
//            
//            let targetMonth = calModel.months.filter{ $0.num == month }.first
//            if let targetMonth {
//                let targetAmount = targetMonth.startingAmounts.filter{ $0.payMethod.id == startingAmount.payMethod.id }.first
//                if let targetAmount {
//                    
//                    if !startingAmount.active {
//                        targetAmount.amountString = ""
//                    } else {
//                        targetAmount.setFromAnotherInstance(startingAmount: startingAmount)
//                    }
//                } else {
//                    calModel.prepareStartingAmount()
//                    let targetAmount = targetMonth.startingAmounts.filter{ $0.payMethod.id == startingAmount.payMethod.id }.first
//                    if let targetAmount {
//                        targetAmount.setFromAnotherInstance(startingAmount: startingAmount)
//                    }
//                    
//                }
//            }
//            
//            let montObj = calModel.months.filter{ $0.num == month }.first!
//            calModel.calculateTotalForMonth(month: montObj)
//        }
//    }
//    
//    
//    private func handleLongPollRepeatingTransactions(_ repeatingTransactions: Array<CBRepeatingTransaction>) async {
//        for transaction in repeatingTransactions {
//            if repModel.doesExist(transaction) {
//                if !transaction.active {
//                    await repModel.delete(transaction, andSubmit: false)
//                } else {
//                    if let index = repModel.getIndex(for: transaction) {
//                        repModel.repTransactions[index].setFromAnotherInstance(repTransaction: transaction)
//                        repModel.repTransactions[index].deepCopy?.setFromAnotherInstance(repTransaction: transaction)
//                    }
//                }
//            } else {
//                if transaction.active {
//                    repModel.upsert(transaction)
//                }
//            }
//        }
//    }
//    
//    
//    private func handleLongPollPaymentMethods(_ payMethods: Array<CBPaymentMethod>) async {
//        for payMethod in payMethods {
//            if payModel.doesExist(payMethod) {
//                if !payMethod.active {
//                    await payModel.delete(payMethod, andSubmit: false, calModel: calModel)
//                    continue
//                } else {
//                    if let index = payModel.getIndex(for: payMethod) {
//                        payModel.paymentMethods[index].setFromAnotherInstance(payMethod: payMethod)
//                        payModel.paymentMethods[index].deepCopy?.setFromAnotherInstance(payMethod: payMethod)
//                    }
//                }
//            } else {
//                if payMethod.active {
//                    payModel.upsert(payMethod)
//                }
//            }
//            let saveResult = payModel.updateCache(for: payMethod)
//            print("SaveResult: \(saveResult)")
//            
//            calModel.justTransactions.filter { $0.payMethod?.id == payMethod.id }.forEach { $0.payMethod = payMethod }
//            repModel.repTransactions.filter { $0.payMethod?.id == payMethod.id }.forEach { $0.payMethod = payMethod }
//        }
//        
//        payModel.determineIfUserIsRequiredToAddPaymentMethod()
//        
//    }
//    
//    
//    private func handleLongPollCategories(_ categories: Array<CBCategory>) async {
//        for category in categories {
//            if catModel.doesExist(category) {
//                if !category.active {
//                    await catModel.delete(category, andSubmit: false, calModel: calModel, keyModel: keyModel)
//                    continue
//                } else {
//                    if let index = catModel.getIndex(for: category) {
//                        catModel.categories[index].setFromAnotherInstance(category: category)
//                        catModel.categories[index].deepCopy?.setFromAnotherInstance(category: category)
//                    }
//                }
//            } else {
//                if category.active {
//                    catModel.upsert(category)
//                }
//            }
//            let saveResult = catModel.updateCache(for: category)
//            print("SaveResult: \(saveResult)")
//            
//            calModel.justTransactions.filter { $0.category?.id == category.id }.forEach { $0.category = category }
//            repModel.repTransactions.filter { $0.category?.id == category.id }.forEach { $0.category = category }
//        }
//    }
//    
//    
//    private func handleLongPollKeywords(_ keywords: Array<CBKeyword>) async {
//        for keyword in keywords {
//            if keyModel.doesExist(keyword) {
//                if !keyword.active {
//                    await keyModel.delete(keyword, andSubmit: false)
//                    continue
//                } else {
//                    if let index = keyModel.getIndex(for: keyword){
//                        keyModel.keywords[index].setFromAnotherInstance(keyword: keyword)
//                        keyModel.keywords[index].deepCopy?.setFromAnotherInstance(keyword: keyword)
//                    }
//                }
//            } else {
//                if keyword.active {
//                    keyModel.upsert(keyword)
//                }
//            }
//            let saveResult = keyModel.updateCache(for: keyword)
//            print("SaveResult: \(saveResult)")
//        }
//    }
//    
//    
//    private func handleLongPollBudgets(_ budgets: Array<CBBudget>) {
//        for budget in budgets {
//            if let targetMonth = calModel.months.filter({ $0.num == budget.month }).first {
//                if targetMonth.isExisting(budget) {
//                    if !budget.active {
//                        targetMonth.delete(budget)
//                        continue
//                    } else {
//                        if let index = targetMonth.getIndex(for: budget) {
//                            targetMonth.budgets[index].setFromAnotherInstance(budget: budget)
//                        }
//                    }
//                } else {
//                    targetMonth.upsert(budget)
//                }
//            }
//        }
//    }
//    
//    
//    // MARK: - Misc
//    func printPersistentMethods() {
//        do {
//            let meths = try DataManager.shared.getMany(type: PersistentPaymentMethod.self)
//            if let meths {
//                if meths.count == 0 {
//                    print("there are no saved payment methods")
//                } else {
//                    for meth in meths {
//                        print(meth.id)
//                    }
//                }
//            }
//        } catch {
//            print("error getting persistent payment methods")
//        }
//    }
//    
//    
//    // MARK: - Logout
//    func logout() {
//        print("-- \(#function)")
//        /// Clearing all ssssion data related to login and loading indicators.
//        AuthState.shared.logout()
//        AppState.shared.downloadedData.removeAll()
//        LoadingManager.shared.showInitiallyLoadingSpinner = true
//        LoadingManager.shared.downloadAmount = 0
//        LoadingManager.shared.showLoadingBar = true
//        
//        /// Cancel the long polling task.
//        longPollTask?.cancel()
//        self.longPollTask = nil
//        
//        /// Remove all transactions, budgets, and starting amounts for all months.
//        calModel.months.forEach { month in
//            month.startingAmounts.removeAll()
//            month.days.forEach { $0.transactions.removeAll() }
//            month.budgets.removeAll()
//        }
//        
//        /// Remove all extra downloaded data.
//        repModel.repTransactions.removeAll()
//        payModel.paymentMethods.removeAll()
//        catModel.categories.removeAll()
//        keyModel.keywords.removeAll()
//                        
//        /// Remove all from cache.
//        let saveResult1 = DataManager.shared.deleteAll(for: PersistentPaymentMethod.self)
//        print(saveResult1)
//        let saveResult2 = DataManager.shared.deleteAll(for: PersistentCategory.self)
//        print(saveResult2)
//        let saveResult3 = DataManager.shared.deleteAll(for: PersistentKeyword.self)
//        print(saveResult3)
//    }
//}
//
