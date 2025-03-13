//
//  RootModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/4/24.
//

import Foundation
import SwiftUI
import LocalAuthentication


@Observable
class FuncModel {
    var calModel: CalendarModel
    var payModel: PayMethodModel
    var catModel: CategoryModel
    var keyModel: KeywordModel
    var repModel: RepeatingTransactionModel
    var eventModel: EventModel
    
    var longPollTask: Task<Void, Error>?
    var refreshTask: Task<Void, Error>?
    
    init(calModel: CalendarModel, payModel: PayMethodModel, catModel: CategoryModel, keyModel: KeywordModel, repModel: RepeatingTransactionModel, eventModel: EventModel) {
        self.calModel = calModel
        self.payModel = payModel
        self.catModel = catModel
        self.keyModel = keyModel
        self.repModel = repModel
        self.eventModel = eventModel
    }
    
    
//    /// This will take the stored credentials, and send them to the server for authentication.
//    /// The server will send back a ``CBUser`` object. That object will contain the user information, as well as a flag that indicates if we need to force the user to the payment method screen.
//    @MainActor func checkForCredentials() async {
//        do {
//            let (email, password) = try KeychainManager().getCredentialsFromKeychain()
//            guard (email != nil), (password != nil) else {
//                AuthState.shared.isThinking = false
//                AppState.shared.appShouldShowSplashScreen = false
//                return
//            }
//            await AuthState.shared.attemptLogin(email: email!, password: password!)
//        } catch {
//            print(error.localizedDescription)
//            AuthState.shared.isThinking = false
//            AppState.shared.appShouldShowSplashScreen = false
//        }
//    }
    
    
//    /// This is only for biometrics.
//    @MainActor func authenticate() {
//        let context = LAContext()
//        var error: NSError?
//
//        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
//            let reason = "We need to unlock your data."
//
//            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
//                if success {
//                    AuthState.shared.isBioAuthed = true
//                } else {
//                    //AuthState.shared.isBioAuthed = false
//                }
//            }
//        } else {
//            AuthState.shared.isBioAuthed = true
//        }
//    }
//    
//    
    /// Establish a UUID for each device for the long poll server. The long poll will not respond to the device that makes the change.
    @MainActor func setDeviceUUID() {
        if let uuid = UserDefaults.fetchOneString(requestedKey: "deviceUUID") {
            AppState.shared.deviceUUID = uuid
        } else {
            let uuid = UUID().uuidString
            UserDefaults.updateStringValue(valueToUpdate: uuid, keyToUpdate: "deviceUUID")
            AppState.shared.deviceUUID = uuid
        }
    }
    
    
    
    
    
    
    
    @MainActor func downloadEverything(setDefaultPayMethod: Bool, createNewStructs: Bool, refreshTechnique: RefreshTechnique, file: String = #file, line: Int = #line, function: String = #function) async {
        /// - Parameters:
        ///   - setDefaultPayMethod: Determine if the defaultPaymentMethod should be set.
        ///     I.E. true when launching the app fresh, or false when clicking the refresh buttons.
        ///   - createNewStructs: Determine whether to update the the objects that are in place, or destroy them and make new ones.
        ///     If true, this will tell the calModel to append the `CBTransactions` to the `CBDay`'s, as opposed to updating the existing ones. True will also result in the loading spinners being activated.
        ///   - refreshTechnique: Where this function was initiated from.
        ///     `.viaSceneChange, .viaTempListSceneChange` are used to keep a transaction alive and open if it is already open. (However `.viaTempListSceneChange` will fail at that job if the network status changes)
        ///     `.viaTempListButton, .viaTempListSceneChange` will both remove any existing transactions from the calendar, as to allow a complete refresh when returning to the calendar from the temp list.
        ///     `.viaInitial, .viaButton, .viaLongPoll` are not used, and are only there for clarity.
        
        
        print("-- \(#function)")
        let start = CFAbsoluteTimeGetCurrent()
        
        NSLog("\(file):\(line) : \(function)")
        
        /// Run this in case the user changes notificaiton settings, we will know about it ASAP.
        Task {
            await NotificationManager.shared.registerForPushNotifications()
        }
        
        
        /// If coming from the tempList, remove all the data so it's guaranteed fresh.
        /// createNewStructs will be true here.
        if refreshTechnique == .viaTempListButton || refreshTechnique == .viaTempListSceneChange {
            //AppState.shared.downloadedData.removeAll()
            //LoadingManager.shared.downloadAmount = 0
            let _ = calModel.months.map { $0.days.map { $0.transactions.removeAll() } }
        }
        
        
        eventModel.invitations.removeAll()
        eventModel.events.removeAll()
        
        Task {
            let hasBadConnection = await AppState.shared.hasBadConnection()
            if hasBadConnection {
                self.refreshTask?.cancel()
                self.longPollTask?.cancel()
            }
        }
        
        /// Restart long poll (if applicable).
        longPollServerForChanges()
        
        //payModel.paymentMethods.removeAll()
        
        /// Reset loading visuals (if applicable).
        if createNewStructs {
            /// Removing these will trigger the loading spinners on all views.
            AppState.shared.downloadedData.removeAll()
            LoadingManager.shared.downloadAmount = 0
        }
                
        /// Grab anything that got stuffed into temporary storage while the network connection was bad, and send it to the server before trying to download any new data.
        do {
            if let entities = try DataManager.shared.getMany(type: TempTransaction.self) {
                for entity in entities {
                    var category: CBCategory?
                    var payMethod: CBPaymentMethod?
                    
                    
                    if let categoryID = entity.categoryID {
                        if let perCategory = DataManager.shared.getOne(type: PersistentCategory.self, predicate: .byId(.string(categoryID)), createIfNotFound: false) {
                            category = CBCategory(entity: perCategory)
                        }
                    }
                    
                    if let payMethodID = entity.payMethodID {
                        if let perPayMethod = DataManager.shared.getOne(type: PersistentPaymentMethod.self, predicate: .byId(.string(payMethodID)), createIfNotFound: false) {
                            payMethod = CBPaymentMethod(entity: perPayMethod)
                        }
                    }
                    
                    var logs: Array<CBLog> = []
                    if let logEntities = entity.logs {
                        
                        let groupID = UUID().uuidString
                        
                        logEntities.forEach { entity in
                            let log = CBLog(transEntity: entity as! TempTransactionLog, groupID: groupID)
                            logs.append(log)
                        }
                    }
                    
                    if let payMethod = payMethod {
                        let _ = await calModel.saveTemp(trans: CBTransaction(entity: entity, payMethod: payMethod, category: category, logs: logs))
                    }
                }
            }
            
            
            let pred = NSPredicate(format: "isPending == %@", NSNumber(value: true))
            
            guard let entities = try DataManager.shared.getMany(type: PersistentCategory.self, predicate: .single(pred)) else { return }
            for entity in entities { let _ = await catModel.submit(CBCategory(entity: entity)) }
                        
            guard let entities = try DataManager.shared.getMany(type: PersistentKeyword.self, predicate: .single(pred)) else { return }
            for entity in entities { let _ = await keyModel.submit(CBKeyword(entity: entity)) }
            
            guard let entities = try DataManager.shared.getMany(type: PersistentPaymentMethod.self, predicate: .single(pred)) else { return }
            for entity in entities { let _ = await payModel.submit(CBPaymentMethod(entity: entity)) }
        } catch {
            print(error.localizedDescription)
        }
                
                    
        withAnimation {
            if createNewStructs {
                /// This is the progress bar at the bottom of the navigation stack.
                LoadingManager.shared.showLoadingBar = true
            }
        }
        
        /// Populate items from cache
        populatePaymentMethodsFromCache(setDefaultPayMethod: setDefaultPayMethod)
        populateCategoriesFromCache()
        populateKeywordsFromCache()
        //populateTagsFromCache()
        
        var next: CBMonth?
        var prev: CBMonth?
        //var start: Double?
        
        /// See if the user is looking at a month or an accessorial view.
        
        
        var currentNavSelection = NavigationManager.shared.selection == nil ? NavigationManager.shared.selectedMonth : NavigationManager.shared.selection
        
        
        
        
        /// If the user is not looking at a month or accessorial view, set it to the current month
        /// This is only applicable on iOS - when the user is on the nav menu.
        #if os(iOS)
        if currentNavSelection == nil {
            currentNavSelection = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
        }
        #endif
        
        if let currentNavSelection {
            /// If viewing a month, determine current and adjacent months.
            if NavDestination.justMonths.contains(currentNavSelection) {
                
                /// Grab Payment Methods (only not logging in. We need this to have a payment method in place before the viewing month loads.)
                if AppState.shared.isLoggingInForFirstTime {
                    await payModel.fetchPaymentMethods(calModel: calModel)
                }
                
                let viewingMonth = calModel.months.filter { $0.num == currentNavSelection.monthNum }.first!
                if ![.lastDecember, .nextJanuary].contains(viewingMonth.enumID) {
                    next = calModel.months.filter { $0.num == (currentNavSelection.monthNum ?? 0) + 1 }.first!
                    prev = calModel.months.filter { $0.num == (currentNavSelection.monthNum ?? 0) - 1 }.first!
                }
                
                /// Download viewing month.
                await downloadViewingMonth(viewingMonth, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique)
                
                //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
                
                /// Download fit transactions for Cody.
                if AppState.shared.user?.id == 1 { await calModel.fetchFitTransactionsFromServer() }
                
                /// Download adjacent months.
                await downloadAdjacentMonths(next: next, prev: prev, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique)
                /// Download other months and accessorials.
                await downloadOtherMonthsAndAccessorials(viewingMonth: viewingMonth, next: next, prev: prev, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique)
                
                if AppState.shared.user?.id == 1 {
                    await calModel.fetchFitTransactionsFromServer()
                }
                
                
            } else {
                /// Run this code if we come back from a sceneChange and are not viewing a month.
                /// If we're not viewing a month, then we must be viewing an accessorial view, so download those first.
                if NavDestination.justAccessorials.contains(currentNavSelection) {
                    await downloadAccessorials(createNewStructs: createNewStructs)
                    await downloadViewingMonth(calModel.sMonth, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique)
                    if AppState.shared.user?.id == 1 { await calModel.fetchFitTransactionsFromServer() }
                    await downloadAdjacentMonths(next: next, prev: prev, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique)
                    await downloadOtherMonths(viewingMonth: calModel.sMonth, next: next, prev: prev, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique)
                }
            }
        }
                
        withAnimation {
            if createNewStructs {
                LoadingManager.shared.showLoadingBar = false
            }
        }
        self.refreshTask = nil
        
        
        let final = CFAbsoluteTimeGetCurrent() - (start)
        print("🔴Everything took \(final) seconds to fetch")
    }
    
    
    // MARK: - Downloading Stuff
    @MainActor private func downloadViewingMonth(_ viewingMonth: CBMonth, createNewStructs: Bool, refreshTechnique: RefreshTechnique) async  {
        /// Grab the viewing month first.
        print("fetching \(viewingMonth.num)");
        let start = CFAbsoluteTimeGetCurrent()
        await calModel.fetchFromServer(month: viewingMonth, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique)
        withAnimation {
            if createNewStructs {
                LoadingManager.shared.showInitiallyLoadingSpinner = false
            }
        }
        
        let currentElapsed = CFAbsoluteTimeGetCurrent() - start
        print("🔴It took \(currentElapsed) seconds to fetch the first month")
        
        //withAnimation(.easeOut(duration: 1)) {
            AppState.shared.appShouldShowSplashScreen = false
        //}
    }
        
    
    @MainActor private func downloadAdjacentMonths(next: CBMonth?, prev: CBMonth?, createNewStructs: Bool, refreshTechnique: RefreshTechnique) async {
        /// Grab months adjacent to viewing month.
        let adjacentStart = CFAbsoluteTimeGetCurrent()
        await withTaskGroup(of: Void.self) { group in
            if let next { group.addTask { print("fetching \(next.num)"); await self.calModel.fetchFromServer(month: next, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique) } }
            if let prev { group.addTask { print("fetching \(prev.num)"); await self.calModel.fetchFromServer(month: prev, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique) } }
        }
        
        let adjacentElapsed = CFAbsoluteTimeGetCurrent() - adjacentStart
        print("🔴It took \(adjacentElapsed) seconds to fetch the Adjacent months")
    }
    
    
    @MainActor private func downloadOtherMonths(viewingMonth: CBMonth, next: CBMonth?, prev: CBMonth?, createNewStructs: Bool, refreshTechnique: RefreshTechnique) async {
        /// Grab all the other months & extra data (payment methods, categories, etc)
        let everythingElseStart = CFAbsoluteTimeGetCurrent()
        await withTaskGroup(of: Void.self) { group in
            for month in calModel.months {
                if let next {
                    if month.num == next.num { continue }
                }
                if let prev {
                    if month.num == prev.num { continue }
                }
                if month.num != viewingMonth.num {
                    group.addTask { print("fetching \(month.num)"); await self.calModel.fetchFromServer(month: month, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique) }
                }
            }
        }
        
        let everytingElseElapsed = CFAbsoluteTimeGetCurrent() - everythingElseStart
        print("🔴It took \(everytingElseElapsed) seconds to fetch all other months")
    }
    
    
    @MainActor private func downloadAccessorials(createNewStructs: Bool) async {
        /// Grab all the other months & extra data (payment methods, categories, etc)
        let everythingElseStart = CFAbsoluteTimeGetCurrent()
        await withTaskGroup(of: Void.self) { group in
            
            /// Grab Tags.
            group.addTask { await self.calModel.fetchTags() }
            
            /// Grab Payment Methods (only if not logging in. If logging in, they are fetched before the viewing month is fetched)
            if !AppState.shared.isLoggingInForFirstTime {
                group.addTask { await self.payModel.fetchPaymentMethods(calModel: self.calModel) }
            }
            /// Grab Categories.
            group.addTask { await self.catModel.fetchCategories() }
            /// Grab Keywords.
            group.addTask { await self.keyModel.fetchKeywords() }
            /// Grab Repeating Transactions.
            group.addTask { await self.repModel.fetchRepeatingTransactions() }
            /// Grab Events.
            group.addTask { await self.eventModel.fetchEvents() }
            /// Grab Invitations.
            group.addTask { await self.eventModel.fetchInvitations() }
        }
        
        let everytingElseElapsed = CFAbsoluteTimeGetCurrent() - everythingElseStart
        print("🔴It took \(everytingElseElapsed) seconds to fetch all accessorials")
    }
    
        
    @MainActor private func downloadOtherMonthsAndAccessorials(viewingMonth: CBMonth, next: CBMonth?, prev: CBMonth?, createNewStructs: Bool, refreshTechnique: RefreshTechnique) async {
        /// Grab all the other months & extra data (payment methods, categories, etc)
        let everythingElseStart = CFAbsoluteTimeGetCurrent()
        
        await withTaskGroup(of: Void.self) { group in
            
            /// Grab Tags.
            group.addTask { await self.calModel.fetchTags() }
            
            for month in calModel.months {
                if let next {
                    if month.num == next.num { continue }
                }
                if let prev {
                    if month.num == prev.num { continue }
                }
                if month.num != viewingMonth.num {
                    group.addTask { print("fetching \(month.num)"); await self.calModel.fetchFromServer(month: month, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique) }
                }
            }
            
            /// Grab Payment Methods.
            group.addTask { await self.payModel.fetchPaymentMethods(calModel: self.calModel) }
            /// Grab Categories.
            group.addTask { await self.catModel.fetchCategories() }
            /// Grab Keywords.
            group.addTask { await self.keyModel.fetchKeywords() }
            /// Grab Repeating Transactions.
            group.addTask { await self.repModel.fetchRepeatingTransactions() }
            /// Grab Events.
            group.addTask { await self.eventModel.fetchEvents() }
            /// Grab Event Invitations
            group.addTask { await self.eventModel.fetchInvitations() }
            
//            group.addTask {
//                let model = RequestModel(requestType: "fetch_accessorials", model: CodablePlaceHolder())
//                typealias ResultResponse = Result<AccessorialModel?, AppError>
//                async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
//
//                switch await result {
//                case .success(let model):
//                    if let model {
//                        await MainActor.run {
//                            payModel.paymentMethods = model.payMethods
//                            catModel.categories = model.categories
//                            keyModel.keywords = model.keywords
//                            repModel.repTransactions = model.repeatingTransactions
//
//                            AppState.shared.downloadedData.append(.repeatingTransactions)
//                            AppState.shared.downloadedData.append(.paymentMethods)
//                            AppState.shared.downloadedData.append(.categories)
//                            AppState.shared.downloadedData.append(.keywords)
//                        }
//                    }
//
//                case .failure (let error):
//                    LogManager.error(error.localizedDescription)
//                    AppState.shared.showAlert("There was a problem trying to fetch transactions.")
//                }
//            }
            
            
        }
        withAnimation {
            LoadingManager.shared.downloadAmount += 10
        }
        let everytingElseElapsed = CFAbsoluteTimeGetCurrent() - everythingElseStart
        print("🔴It took \(everytingElseElapsed) seconds to fetch all other months")
    }
    
    /// Not private because it is called directly from the RootView
    @MainActor func populatePaymentMethodsFromCache(setDefaultPayMethod: Bool) {
        /// Populate payment methods from cache.
        do {
            let meths = try DataManager.shared.getMany(type: PersistentPaymentMethod.self)
            if let meths {
                meths
                .sorted { ($0.title ?? "").lowercased() < ($1.title ?? "").lowercased() }
                //.filter { $0.id != nil } /// Have a weird bug that added blank in CoreData.
                .forEach { meth in
                    //print(meth.title)
                    if setDefaultPayMethod && meth.isDefault {
                        calModel.sPayMethod = CBPaymentMethod(entity: meth)
                    }
                    if payModel.paymentMethods.filter({ $0.id == meth.id! }).isEmpty {
                        payModel.paymentMethods.append(CBPaymentMethod(entity: meth))
                    }
                    
//                    #warning("remove this")
//                    let notifications = NotificationManager.shared.scheduledNotifications.filter { $0.payMethodID == meth.id }
//                    if !notifications.isEmpty {
//                        NotificationManager.shared.createReminder2(payMethod: CBPaymentMethod(entity: meth))
//                    }
                }
                                
                //payModel.paymentMethods.sort { $0.title < $1.title }
            }
        } catch {
            fatalError("Could not find paymentMethods from cache")
        }
    }
        
    /// Not private because it is called directly from the RootView, and from the temp transaction list
    @MainActor func populateCategoriesFromCache() {
        print("-- \(#function)")
        /// Populate categories from cache.
        do {
            //let categorySortMode = CategorySortMode.fromString(UserDefaults.standard.string(forKey: "categorySortMode") ?? "")
            
            let cats = try DataManager.shared.getMany(type: PersistentCategory.self)
            if let cats {
                cats
//                .sorted {
//                    categorySortMode == .title
//                    ? ($0.title ?? "").lowercased() < ($1.title ?? "").lowercased()
//                    : Int($0.listOrder) < Int($1.listOrder)
//                }
                .forEach { cat in
                    //print("Category Title \(cat.title) - ID \(cat.id)")
                    if catModel.categories.filter({ $0.id == cat.id! }).isEmpty {
                        catModel.categories.append(CBCategory(entity: cat))
                    }
                }
            }
            
            //catModel.categories.sort { $0.title < $1.title }
            
        } catch {
            fatalError("Could not find categories from cache")
        }
    }
    
    
    @MainActor private func populateKeywordsFromCache() {
        print("-- \(#function)")
        /// Populate keywords from cache.
        do {
            let keys = try DataManager.shared.getMany(type: PersistentKeyword.self)
            if let keys {
                keys
                .sorted { ($0.keyword ?? "").lowercased() < ($1.keyword ?? "").lowercased() }
                //.filter { $0.id != nil } /// Have a weird bug that added blank in CoreData.
                .forEach { key in
                    //print(key.keyword)
                    if keyModel.keywords.filter({ $0.id == key.id! }).isEmpty {
                        keyModel.keywords.append(CBKeyword(entity: key))
                    }
                }
            }
            
            //keyModel.keywords.sort { $0.keyword < $1.keyword }
            
        } catch {
            fatalError("Could not find keywords from cache")
        }
    }
    
//    private func populateTagsFromCache() {
//        /// Populate keywords from cache.
//        do {
//            let tags = try DataManager.shared.getMany(type: PersistentTag.self)
//            if let tags {
//                tags.forEach { tag in
//                    if tagModel.tags.filter({ $0.id == tag.id }).isEmpty {
//                        tagModel.tags.append(CBTag(entity: tag))
//                    }
//                }
//            }
//
//            tagModel.tags.sort { $0.tag < $1.tag }
//
//        } catch {
//            fatalError("Could not find tags from cache")
//        }
//    }
    
    
    // MARK: - Long Poll Stuff
    @MainActor func longPollServerForChanges() {
        print("-- \(#function)")
        
        if longPollTask == nil {
            print("Longpoll task does not exist. Creating.")
            longPollTask = Task {
                await longPollServer()
            }
        } else {
            print("Longpoll task exists")
            if longPollTask!.isCancelled {
                print("Long poll task has been cancelled. Restarting")
                longPollTask = Task {
                    await longPollServer()
                }
            } else {
                print("Long poll task has not been cancelled and is running. Ignoring.")
            }
        }
        
        @MainActor
        func longPollServer() async {
            //return
            print("-- \(#function)")
            LogManager.log()
                                
            let model = RequestModel(requestType: "longpoll_server", model: CodablePlaceHolder())
            typealias ResultResponse = Result<LongPollModel?, AppError>
            async let result: ResultResponse = await NetworkManager().longPollServer(requestModel: model)
            
            switch await result {
            case .success(let model):
                LogManager.networkingSuccessful()
                
                if let model {
                    if let transactions = model.transactions { self.handleLongPollTransactions(transactions) }
                    
                    if AppState.shared.user?.id == 1 {
                        if let fitTransactions = model.fitTransactions { self.handleLongPollFitTransactions(fitTransactions) }
                    }
                    
                    if let startingAmounts = model.startingAmounts { self.handleLongPollStartingAmounts(startingAmounts) }
                    if let repeatingTransactions = model.repeatingTransactions { await self.handleLongPollRepeatingTransactions(repeatingTransactions) }
                    if let payMethods = model.payMethods { await self.handleLongPollPaymentMethods(payMethods) }
                    if let categories = model.categories { await self.handleLongPollCategories(categories) }
                    if let keywords = model.keywords { await self.handleLongPollKeywords(keywords) }
                    if let budgets = model.budgets { self.handleLongPollBudgets(budgets) }
                    if let events = model.events { await self.handleLongPollEvents(events) }
                    if let invitations = model.invitations { await self.handleLongPollInvitations(invitations) }
                }
                
                print("restarting longpoll - \(Date())")
                await longPollServer()
                
            case .failure (let error):
                switch error {
                case .taskCancelled:
                    /// Task gets cancelled when logging out. So only show the alert if the error is not related to the task being cancelled.
                    print("Task Cancelled")
                default:
                    LogManager.error(error.localizedDescription)
                    print(error.localizedDescription)
                    AppState.shared.longPollFailed = true
                    
                    longPollTask?.cancel()
                    longPollTask = nil
                    
                    let alertConfig = AlertConfig(
                        title: "There was a problem subscribing to multi-device updates.",
                        symbol: .init(name: "ipad.and.iphone.slash", color: .red),
                        primaryButton:
                            AlertConfig.AlertButton(config: .init(text: "Retry", role: .primary, function: {
                                Task {
                                    AppState.shared.longPollFailed = false
                                    await self.downloadEverything(setDefaultPayMethod: false, createNewStructs: false, refreshTechnique: .viaLongPoll)
                                }
                            }))
                    )
                    AppState.shared.showAlert(config: alertConfig)
                }
            }
        }
    }
    
    
    @MainActor private func handleLongPollTransactions(_ transactions: Array<CBTransaction>) {
        calModel.handleTransactions(transactions, refreshTechnique: .viaLongPoll)
        
        let months = transactions.map { $0.dateComponents?.month }.uniqued()
        months.forEach { month in
            let montObj = calModel.months.filter{ $0.num == month }.first!
            calModel.calculateTotalForMonth(month: montObj)
        }
    }
    
    @MainActor private func handleLongPollFitTransactions(_ transactions: Array<CBFitTransaction>) {
        calModel.fitTrans = transactions
    }
    
    
    @MainActor private func handleLongPollStartingAmounts(_ startingAmounts: Array<CBStartingAmount>) {
        for startingAmount in startingAmounts {
            //let year = startingAmount.year
            
            if startingAmount.month == 1 && startingAmount.year == AppState.shared.todayYear + 1 {
                startingAmount.month = 13
            } else if startingAmount.month == 12 && startingAmount.year == AppState.shared.todayYear - 1 {
                startingAmount.month = 0
            }
            
            let month = startingAmount.month
            
            
            let targetMonth = calModel.months.filter{ $0.num == month }.first
            if let targetMonth {
                let targetAmount = targetMonth.startingAmounts.filter{ $0.payMethod.id == startingAmount.payMethod.id }.first
                if let targetAmount {
                    
                    if !startingAmount.active {
                        targetAmount.amountString = ""
                    } else {
                        targetAmount.setFromAnotherInstance(startingAmount: startingAmount)
                    }
                } else {
                    calModel.prepareStartingAmount(for: startingAmount.payMethod)
                    let targetAmount = targetMonth.startingAmounts.filter{ $0.payMethod.id == startingAmount.payMethod.id }.first
                    if let targetAmount {
                        targetAmount.setFromAnotherInstance(startingAmount: startingAmount)
                    }
                    
                }
            }
            
            let montObj = calModel.months.filter{ $0.num == month }.first!
            calModel.calculateTotalForMonth(month: montObj)
        }
    }
    
    
    @MainActor private func handleLongPollRepeatingTransactions(_ repeatingTransactions: Array<CBRepeatingTransaction>) async {
        for transaction in repeatingTransactions {
            if repModel.doesExist(transaction) {
                if !transaction.active {
                    await repModel.delete(transaction, andSubmit: false)
                } else {
                    if let index = repModel.getIndex(for: transaction) {
                        repModel.repTransactions[index].setFromAnotherInstance(repTransaction: transaction)
                        repModel.repTransactions[index].deepCopy?.setFromAnotherInstance(repTransaction: transaction)
                    }
                }
            } else {
                if transaction.active {
                    repModel.upsert(transaction)
                }
            }
        }
    }
    
    
    @MainActor private func handleLongPollPaymentMethods(_ payMethods: Array<CBPaymentMethod>) async {
        for payMethod in payMethods {
            if payModel.doesExist(payMethod) {
                if !payMethod.active {
                    await payModel.delete(payMethod, andSubmit: false, calModel: calModel, eventModel: eventModel)
                    continue
                } else {
                    if let index = payModel.getIndex(for: payMethod) {
                        payModel.paymentMethods[index].setFromAnotherInstance(payMethod: payMethod)
                        payModel.paymentMethods[index].deepCopy?.setFromAnotherInstance(payMethod: payMethod)
                    }
                }
            } else {
                if payMethod.active {
                    payModel.upsert(payMethod)
                }
            }
            let _ = payModel.updateCache(for: payMethod)
            //print("SaveResult: \(saveResult)")
            
            calModel.justTransactions.filter { $0.payMethod?.id == payMethod.id }.forEach { $0.payMethod = payMethod }
            repModel.repTransactions.filter { $0.payMethod?.id == payMethod.id }.forEach { $0.payMethod = payMethod }
        }
        
        payModel.determineIfUserIsRequiredToAddPaymentMethod()
        
    }
    
    
    @MainActor private func handleLongPollCategories(_ categories: Array<CBCategory>) async {
        for category in categories {
            if catModel.doesExist(category) {
                if !category.active {
                    await catModel.delete(category, andSubmit: false, calModel: calModel, keyModel: keyModel, eventModel: eventModel)
                    continue
                } else {
                    if let index = catModel.getIndex(for: category) {
                        catModel.categories[index].setFromAnotherInstance(category: category)
                        catModel.categories[index].deepCopy?.setFromAnotherInstance(category: category)
                    }
                }
            } else {
                if category.active {
                    catModel.upsert(category)
                }
            }
            let _ = catModel.updateCache(for: category)
            //print("SaveResult: \(saveResult)")
            
            calModel.justTransactions.filter { $0.category?.id == category.id }.forEach { $0.category = category }
            repModel.repTransactions.filter { $0.category?.id == category.id }.forEach { $0.category = category }
        }
        
        let categorySortMode = CategorySortMode.fromString(UserDefaults.standard.string(forKey: "categorySortMode") ?? "")
                           
        withAnimation {
            catModel.categories.sort {
                categorySortMode == .title
                ? ($0.title).lowercased() < ($1.title).lowercased()
                : $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000
            }
        }

        
    }
    
    
    @MainActor private func handleLongPollKeywords(_ keywords: Array<CBKeyword>) async {
        for keyword in keywords {
            if keyModel.doesExist(keyword) {
                if !keyword.active {
                    await keyModel.delete(keyword, andSubmit: false)
                    continue
                } else {
                    if let index = keyModel.getIndex(for: keyword){
                        keyModel.keywords[index].setFromAnotherInstance(keyword: keyword)
                        keyModel.keywords[index].deepCopy?.setFromAnotherInstance(keyword: keyword)
                    }
                }
            } else {
                if keyword.active {
                    keyModel.upsert(keyword)
                }
            }
            let _ = keyModel.updateCache(for: keyword)
            //print("SaveResult: \(saveResult)")
        }
    }
    
    
    @MainActor private func handleLongPollBudgets(_ budgets: Array<CBBudget>) {
        for budget in budgets {
            if let targetMonth = calModel.months.filter({ $0.num == budget.month }).first {
                if targetMonth.isExisting(budget) {
                    if !budget.active {
                        targetMonth.delete(budget)
                        continue
                    } else {
                        if let index = targetMonth.getIndex(for: budget) {
                            targetMonth.budgets[index].setFromAnotherInstance(budget: budget)
                        }
                    }
                } else {
                    targetMonth.upsert(budget)
                }
            }
        }
    }
    
    
    @MainActor private func handleLongPollEvents(_ events: Array<CBEvent>) async {
        print("-- \(#function)")
        //print(events.map {$0.title})
        
        
        for event in events {
            
            //let participantCount = event.participants.count
            
            
            print("INITIAL PARTS")
            print("userNames: \(event.participants.map {$0.user.name})")
            print("actives: \(event.participants.map {$0.active})")
            print("statuses: \(event.participants.map {$0.status?.description})")
            print("ids: \(event.participants.map {$0.id})")
            
            /// See if the user has an active participant record.
            let doesUserHavePermission = event.participants
                .filter { $0.active }
                .filter { $0.status?.enumID == .accepted }
                .contains(where: { $0.user.id == AppState.shared.user?.id ?? 0 })
            
            if eventModel.doesExist(event) {
                /// If the event has been deleted, remove it.
                if !event.active {
                    AppState.shared.showToast(title: "Event Removed", subtitle: event.title, body: "The event has been removed by the host.", symbol: "calendar.badge.minus")
                    await eventModel.delete(event, andSubmit: false)
                    continue
                } else {
                    /// If they don't have permission, remove the event since they have been kicked out.
                    if !doesUserHavePermission {
                        withAnimation {
                            eventModel.revoke(event)
                        }
                        AppState.shared.showToast(title: "Event Revoked", subtitle: event.title, body: "You have been removed by the host.", symbol: "person.slash.fill")
                        
                        continue
                    }
                                                            
                    /// Find the event in the users data.
                    if let index = eventModel.getIndex(for: event) {
                        let actualEvent = eventModel.events[index]
                        
                        //print(event.items.map{$0.title})
                        //print(event.items.map{$0.active})
                        
                        actualEvent.updateFromLongPoll(event: event)
                        actualEvent.deepCopy?.setFromAnotherInstance(event: event)
                        
                        
                        for item in actualEvent.items {
                            if !item.active {
                                actualEvent.deleteItem(id: item.id)
                            }
                        }
                        
                        for transaction in actualEvent.transactions {
                            if !transaction.active {
                                actualEvent.deleteTransaction(id: transaction.id)
                            }
                        }
                        
                                                
                        /// Check the participant array from the newly updated event, and see if they are part of the list of invitations.
//                        var acceptingUsers: [String] = []
//                        for each in actualEvent.participants {
//                            let participantEmail = each.user.email.lowercased()
//                            
//                            /// If the user is now in participants, and was found in the invite array, that means they have accepted the invitation.
//                            /// Remove the user from the invitation array, and append to the `acceptingUsers` array. (Only used for the toast)
////                            if actualEvent.invitationsToSend.map({ $0.email?.lowercased() }).contains(participantEmail) {
////                                actualEvent.invitationsToSend.removeAll(where: { $0.email?.lowercased() == participantEmail })
////                                acceptingUsers.append(each.user.name)
////                            }
//                        }
                                                                        
                        /// Show the toast for accepted invitations.
                        //if !acceptingUsers.isEmpty {
                            //AppState.shared.showToast(header: "Invite Accepted", title: actualEvent.title, message: "\(acceptingUsers.joined(separator: ", ")) just accepted your invitation", symbol: "calendar.badge.checkmark")
                        
//                        let newParticipantCount = actualEvent.participants.count
//                        
//                        if participantCount > newParticipantCount {
//                            AppState.shared.showToast(header: "Somebody left", title: actualEvent.title, message: "Someone just left the event", symbol: "person.fill.xmark")
//                        } else {
//                            AppState.shared.showToast(header: "Invite Accepted", title: actualEvent.title, message: "Someone just accepted your invitation", symbol: "calendar.badge.checkmark")
//                        }
                        
                        //}
                    }
                }
            } else {
                /// If the event is active, check to make sure the user is allowed to see it.
                /// If they are, upsert the event.
                if event.active {
                    if doesUserHavePermission {
                        eventModel.upsert(event)
                        //eventModel.invitations.removeAll(where: {$0.id == part.id})
                        eventModel.invitations.removeAll(where: {$0.eventID == event.id})
                    }
                }
            }
        }
    }
    
    
    @MainActor private func handleLongPollInvitations(_ participants: Array<CBEventParticipant>) async {
        print("-- \(#function)")
        print(participants.map {$0.email})
        print(participants.map {$0.active})
        print(participants.map {$0.id})
        print(participants.map {$0.status?.description})
        
        for part in participants {
            if eventModel.doesExist(part) {
                /// If the invite is inactive, that means the invitee rejected it.
                if !part.active {
                    /// Remove the invitation from the invitation list.
                    eventModel.invitations.removeAll { $0.id == part.id }
                    /// Remove the pending invitation from the associated event.
                    if let targetEvent = eventModel.events.filter({ $0.id == part.eventID }).first {
                        targetEvent.participants.removeAll(where: { $0.id == part.id })
                    }
                    
                    continue
                } else {
                    /// The event is active, so update the invitation in the model.
                    print("THE PART IS ACTIVE")
                    if let index = eventModel.getIndex(for: part) {
                        //eventModel.invitations[index] = part
                                                                        
                        print("FOUND IT")
                        if part.status?.enumID == .rejected {
                            eventModel.invitations.removeAll(where: { $0.id == part.id })
                        } else {
                            eventModel.invitations[index].setFromAnotherInstance(part: part)
                        }
                        
                    }
                }
            } else {
                /// Upsert the invite if it doesn't exist.
                if part.active {
                    print("Participant is active")
                    if part.status?.enumID == .rejected {
                        /// Remove the invitation from the invitation list.
                        eventModel.invitations.removeAll { $0.id == part.id }
                        /// Remove the pending invitation from the associated event.
                        if let targetEvent = eventModel.events.filter({ $0.id == part.eventID }).first {
                            targetEvent.participants.removeAll(where: { $0.id == part.id })
                        }
                    } else {
                        print("UPSERTING")
                        withAnimation {
                            eventModel.upsert(part)
                        }
                        
                    }
                } else {
                    print("SHOUD REMOVE INVITE")
                    print(eventModel.invitations.map {$0.id})
                    print("\(part.id) - \(String(describing: part.email)) - \(part.eventID)")
                    eventModel.invitations.removeAll(where: {$0.id == part.id})
                }
            }
        }
    }
    
    
    
    
    // MARK: - Misc
    @MainActor func printPersistentMethods() {
        do {
            let meths = try DataManager.shared.getMany(type: PersistentPaymentMethod.self)
            if let meths {
                if meths.count == 0 {
                    print("there are no saved payment methods")
                } else {
                    for meth in meths {
                        print(meth.id ?? "No Meth ID")
                    }
                }
            }
        } catch {
            print("error getting persistent payment methods")
        }
    }
    
    
    // MARK: - Logout
    @MainActor func logout() {
        print("-- \(#function)")
        /// Clearing all ssssion data related to login and loading indicators.
        AuthState.shared.logout()
        AppState.shared.downloadedData.removeAll()
        LoadingManager.shared.showInitiallyLoadingSpinner = true
        LoadingManager.shared.downloadAmount = 0
        LoadingManager.shared.showLoadingBar = true
        
        /// Cancel the long polling task.
        longPollTask?.cancel()
        self.longPollTask = nil
        
        /// Remove all transactions, budgets, and starting amounts for all months.
        calModel.months.forEach { month in
            month.startingAmounts.removeAll()
            month.days.forEach { $0.transactions.removeAll() }
            month.budgets.removeAll()
        }
        
        /// Remove all extra downloaded data.
        repModel.repTransactions.removeAll()
        payModel.paymentMethods.removeAll()
        catModel.categories.removeAll()
        keyModel.keywords.removeAll()
        eventModel.events.removeAll()
        eventModel.invitations.removeAll()
                        
        /// Remove all from cache.
        let _ = DataManager.shared.deleteAll(for: PersistentPaymentMethod.self)
        //print(saveResult1)
        let _ = DataManager.shared.deleteAll(for: PersistentCategory.self)
        //print(saveResult2)
        let _ = DataManager.shared.deleteAll(for: PersistentKeyword.self)
        //print(saveResult3)
    }
}
