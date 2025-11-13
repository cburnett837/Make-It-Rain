//
//  RootModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/4/24.
//

import Foundation
import SwiftUI
import LocalAuthentication
import GRDB
import CoreData


@Observable
class FuncModel {
    var calModel: CalendarModel
    var payModel: PayMethodModel
    var catModel: CategoryModel
    var keyModel: KeywordModel
    var repModel: RepeatingTransactionModel
    var eventModel: EventModel
    var plaidModel: PlaidModel
    
    var longPollTask: Task<Void, Error>?
    var refreshTask: Task<Void, Error>?
    
    var isLoading = false
    var loadTimes: [(id: UUID, date: Date, load: Double)] = []
    
    init(calModel: CalendarModel, payModel: PayMethodModel, catModel: CategoryModel, keyModel: KeywordModel, repModel: RepeatingTransactionModel, eventModel: EventModel, plaidModel: PlaidModel) {
        self.calModel = calModel
        self.payModel = payModel
        self.catModel = catModel
        self.keyModel = keyModel
        self.repModel = repModel
        self.eventModel = eventModel
        self.plaidModel = plaidModel
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
    
    
    
    
    
    
    
    @MainActor
    func downloadEverything(setDefaultPayMethod: Bool, createNewStructs: Bool, refreshTechnique: RefreshTechnique, file: String = #file, line: Int = #line, function: String = #function) async {
        /// - Parameters:
        ///   - setDefaultPayMethod: Determine if the defaultPaymentMethod should be set.
        ///     I.E. true when launching the app fresh, or false when clicking the refresh buttons.
        ///   - createNewStructs: Determine whether to update the the objects that are in place, or destroy them and make new ones.
        ///     If true, this will tell the calModel to append the `CBTransactions` to the `CBDay`'s, as opposed to updating the existing ones. True will also result in the loading spinners being activated.
        ///   - refreshTechnique: Where this function was initiated from.
        ///     `.viaSceneChange, .viaTempListSceneChange` are used to keep a transaction alive and open if it is already open. (However `.viaTempListSceneChange` will fail at that job if the network status changes)
        ///     `.viaTempListButton, .viaTempListSceneChange` will both remove any existing transactions from the calendar, as to allow a complete refresh when returning to the calendar from the temp list.
        ///     `.viaInitial, .viaButton, .viaLongPoll` are not used, and are only there for clarity.
        
        
        print("-- \(#function) -- Called from: \(file):\(line) : \(function)")
        
        withAnimation {
            isLoading = true
        }
        
        
        AppState.shared.lastNetworkTime = .now
        
        let start = CFAbsoluteTimeGetCurrent()
        
        //NSLog("\(file):\(line) : \(function)")
        
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
        
        
        //eventModel.invitations.removeAll()
        //eventModel.events.removeAll()
        
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
        
        /// Gather any cached transactions and send them to the server.
        
        //var tempTransactions: [(TempTransaction, CBCategory?, CBPaymentMethod?, [CBLog])] = []

        let context = DataManager.shared.createContext()

        let tempTransactions: [(TempTransaction, CBCategory?, CBPaymentMethod?, [CBLog])] = await context.perform {
            var results: [(TempTransaction, CBCategory?, CBPaymentMethod?, [CBLog])] = []

            if let entities = DataManager.shared.getMany(context: context, type: TempTransaction.self) {
                for entity in entities {
                    var category: CBCategory?
                    var payMethod: CBPaymentMethod?
                    var logs: [CBLog] = []

                    if let categoryID = entity.categoryID,
                       let perCategory = DataManager.shared.getOne(
                           context: context,
                           type: PersistentCategory.self,
                           predicate: .byId(.string(categoryID)),
                           createIfNotFound: false
                       ) {
                        category = CBCategory(entity: perCategory)
                    }

                    if let payMethodID = entity.payMethodID,
                       let perPayMethod = DataManager.shared.getOne(
                           context: context,
                           type: PersistentPaymentMethod.self,
                           predicate: .byId(.string(payMethodID)),
                           createIfNotFound: false
                       ) {
                        payMethod = CBPaymentMethod(entity: perPayMethod)
                    }

                    if let logEntities = entity.logs {
                        let groupID = UUID().uuidString
                        for case let logEntity as TempTransactionLog in logEntities {
                            logs.append(CBLog(transEntity: logEntity, groupID: groupID))
                        }
                    }

                    results.append((entity, category, payMethod, logs))
                }
            }

            return results
        }

        // Now safely on the main actor
        await MainActor.run {
            for (entity, category, payMethod, logs) in tempTransactions {
                if let payMethod {
                    Task { await self.calModel.saveTemp(trans: CBTransaction(entity: entity, payMethod: payMethod, category: category, logs: logs)) }
                }
            }
        }

        
        
               
        //Task {
        
            /// Grab anything that got stuffed into temporary storage while the network connection was bad, and send it to the server before trying to download any new data.
        
//        let mainContext = DataManager.shared.container.viewContext
//        await mainContext.perform {
//            let pred = NSPredicate(format: "isPending == %@", NSNumber(value: true))            
//            let cats = DataManager.shared.getMany(context: context, type: PersistentCategory.self, predicate: .single(pred))
//            if let cats {
//                let objectIDs = cats.map { $0.objectID }
//                
//                Task { @MainActor in
//                    let mainObjects = objectIDs.compactMap { mainContext.object(with: $0) as? PersistentCategory }
//                    for entity in mainObjects {
//                        let _ = await self.catModel.submit(CBCategory(entity: entity))
//                    }
//                }
//            }
//                                            
//            let keys = DataManager.shared.getMany(context: context, type: PersistentKeyword.self, predicate: .single(pred))
//            if let keys {
//                let objectIDs = keys.map { $0.objectID }
//                
//                Task { @MainActor in
//                    let mainObjects = objectIDs.compactMap { mainContext.object(with: $0) as? PersistentKeyword }
//                    for entity in mainObjects {
//                        let _ = await self.keyModel.submit(CBKeyword(entity: entity))
//                    }
//                }
//            }
//            
//            let meths = DataManager.shared.getMany(context: context, type: PersistentPaymentMethod.self, predicate: .single(pred))
//            if let meths {
//                let objectIDs = meths.map { $0.objectID }
//                
//                Task { @MainActor in
//                    let mainObjects = objectIDs.compactMap { mainContext.object(with: $0) as? PersistentPaymentMethod }
//                    for entity in mainObjects {
//                        let _ = await self.payModel.submit(CBPaymentMethod(entity: entity))
//                    }
//                }
//            }
//        }
        
        
        
        let mainContext = DataManager.shared.container.viewContext
        // Thread-safe arrays to hold the IDs
        var catIDs: [NSManagedObjectID] = []
        var keyIDs: [NSManagedObjectID] = []
        var methIDs: [NSManagedObjectID] = []

        // Perform the fetches on the context’s queue
        await mainContext.perform {
            let pred = NSPredicate(format: "isPending == %@", NSNumber(value: true))

            if let cats = DataManager.shared.getMany(context: context, type: PersistentCategory.self, predicate: .single(pred)) {
                catIDs = cats.map { $0.objectID }
            }
            if let keys = DataManager.shared.getMany(context: context, type: PersistentKeyword.self, predicate: .single(pred)) {
                keyIDs = keys.map { $0.objectID }
            }
            if let meths = DataManager.shared.getMany(context: context, type: PersistentPaymentMethod.self, predicate: .single(pred)) {
                methIDs = meths.map { $0.objectID }
            }
        }

        // Now that we have the IDs, switch to the main actor
        await MainActor.run {
            let catObjects = catIDs.compactMap { mainContext.object(with: $0) as? PersistentCategory }
            for entity in catObjects {
                Task { await self.catModel.submit(CBCategory(entity: entity)) }
            }
            
            let keyObjects = keyIDs.compactMap { mainContext.object(with: $0) as? PersistentKeyword }
            for entity in keyObjects {
                Task { await self.keyModel.submit(CBKeyword(entity: entity)) }
            }
            
            let methObjects = methIDs.compactMap { mainContext.object(with: $0) as? PersistentPaymentMethod }
            for entity in methObjects {
                Task { await self.payModel.submit(CBPaymentMethod(entity: entity)) }
            }
        }
        
        
        
                                                    
        withAnimation {
            if createNewStructs {
                /// This is the progress bar at the bottom of the navigation stack.
                LoadingManager.shared.showLoadingBar = true
            }
        }
        
        //Task {
            /// Populate items from cache
            await populatePaymentMethodsFromCache(setDefaultPayMethod: setDefaultPayMethod)
            await populateCategoriesFromCache()
            await populateKeywordsFromCache()
            //populateTagsFromCache()
        //}
                
        
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
        
        //print("Current Nav Selection: \(currentNavSelection)")
        
        if let currentNavSelection {
            /// If viewing a month, determine current and adjacent months.
            if NavDestination.justMonths.contains(currentNavSelection) {
                
                /// Grab Payment Methods (only when logging in. We need this to have a payment method in place before the viewing month loads.)
                if AppState.shared.isLoggingInForFirstTime {
                    await payModel.fetchPaymentMethods(calModel: calModel)
                }
                
                let viewingMonth = calModel.months.filter { $0.num == currentNavSelection.monthNum }.first!
                
                //#warning("prepareStartingAmounts()")
                self.prepareStartingAmounts(for: viewingMonth)
                                
                if ![.lastDecember, .nextJanuary].contains(viewingMonth.enumID) {
                    next = calModel.months.filter { $0.num == (currentNavSelection.monthNum ?? 0) + 1 }.first!
                    prev = calModel.months.filter { $0.num == (currentNavSelection.monthNum ?? 0) - 1 }.first!
                }
                
                /// Download viewing month.
                await downloadViewingMonth(viewingMonth, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique)
                
                //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
                
                /// Download fit transactions for Cody.
                //if AppState.shared.user?.id == 1 { await calModel.fetchFitTransactionsFromServer() }
                
                
                await downloadPlaidStuff()
                
                
                //await plaidModel.fetchPlaidTransactionsFromServer()
                //await plaidModel.fetchPlaidBalancesFromServer()
                
                /// Download adjacent months.
                await downloadAdjacentMonths(next: next, prev: prev, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique)
                /// Download other months and accessorials.
                await downloadOtherMonthsAndAccessorials(viewingMonth: viewingMonth, next: next, prev: prev, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique)
                                
            } else {
                /// Run this code if we come back from a sceneChange and are not viewing a month.
                /// If we're not viewing a month, then we must be viewing an accessorial view, so download those first.
                if NavDestination.justAccessorials.contains(currentNavSelection) {
                    await downloadAccessorials(createNewStructs: createNewStructs)
                    await downloadViewingMonth(calModel.sMonth, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique)
                    //if AppState.shared.user?.id == 1 { await calModel.fetchFitTransactionsFromServer() }
                    
//                    await plaidModel.fetchPlaidTransactionsFromServer()
//                    await plaidModel.fetchPlaidBalancesFromServer()
                    
                    await downloadPlaidStuff()
                    
                    await downloadAdjacentMonths(next: next, prev: prev, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique)
                    await downloadOtherMonths(viewingMonth: calModel.sMonth, next: next, prev: prev, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique)
                }
            }
        } else {
            fatalError("Nav Selection is nil")
        }
                
        withAnimation {
            if createNewStructs {
                LoadingManager.shared.showLoadingBar = false
            }
        }
        self.refreshTask = nil
        
        
        let final = CFAbsoluteTimeGetCurrent() - (start)
        print("🔴Everything took \(final) seconds to fetch")
        //AppState.shared.showToast(title: "🔴Everything took \(final) seconds to fetch")
        let metric = (id: UUID(), date: Date(), load: final)
        loadTimes.append(metric)
        withAnimation {
            isLoading = false
        }
        
    }
    
    
    
    // MARK: - Downloading Stuff
    @MainActor private func downloadPlaidStuff() async {
        let plaidStart = CFAbsoluteTimeGetCurrent()
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                print("fetching plaid transactions");
                let fetchModel = PlaidServerModel(rowNumber: 1)
                await self.plaidModel.fetchPlaidTransactionsFromServer(fetchModel, accumulate: false)
            }
        
            group.addTask {
                print("fetching plaid balances");
                await self.plaidModel.fetchPlaidBalancesFromServer()
            }
        }
        let plaidElapsed = CFAbsoluteTimeGetCurrent() - plaidStart
        print("⏰It took \(plaidElapsed) seconds to fetch the plaid data")
    }
    
    
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
        print("⏰It took \(currentElapsed) seconds to fetch the first month")
        
        /// Prepare starting amounts for payment method sheet
//        for payMethod in payModel.paymentMethods {
//            calModel.prepareStartingAmount(for: payMethod)
//            if payMethod.isUnified {
//                let _ = calModel.updateUnifiedStartingAmount(month: calModel.sMonth, for: payMethod.accountType)
//            }
//        }
        
        
            /// This willl flip from the splash screen to `RootView`. `RootView` task will open the calendar sheet.
            AppState.shared.appShouldShowSplashScreen = false
        
    }
        
    
    @MainActor private func downloadAdjacentMonths(next: CBMonth?, prev: CBMonth?, createNewStructs: Bool, refreshTechnique: RefreshTechnique) async {
        /// Grab months adjacent to viewing month.
        let adjacentStart = CFAbsoluteTimeGetCurrent()
        await withTaskGroup(of: Void.self) { group in
            if let next {
                group.addTask {
                    print("fetching \(next.num)");
                    await self.calModel.fetchFromServer(month: next, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique)
                }
            }
            if let prev {
                group.addTask {
                    print("fetching \(prev.num)");
                    await self.calModel.fetchFromServer(month: prev, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique)
                }
            }
        }
        
        let adjacentElapsed = CFAbsoluteTimeGetCurrent() - adjacentStart
        print("⏰It took \(adjacentElapsed) seconds to fetch the Adjacent months")
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
                    group.addTask {
                        print("fetching \(month.num)");
                        await self.calModel.fetchFromServer(month: month, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique)
                    }
                }
            }
        }
        
        let everytingElseElapsed = CFAbsoluteTimeGetCurrent() - everythingElseStart
        print("⏰It took \(everytingElseElapsed) seconds to fetch all other months")
    }
    
    
    @MainActor private func downloadAccessorials(createNewStructs: Bool) async {
        /// Grab all the other months & extra data (payment methods, categories, etc)
        let everythingElseStart = CFAbsoluteTimeGetCurrent()
        await withTaskGroup(of: Void.self) { group in
            
            /// Grab Tags.
            group.addTask { await self.calModel.fetchTags() }
            
            /// Grab Payment Methods (only if not logging in. If logging in, they are fetched before the viewing month is fetched)/.
            if !AppState.shared.isLoggingInForFirstTime {
                group.addTask {
                    await self.payModel.fetchPaymentMethods(calModel: self.calModel)
                    await self.prepareStartingAmounts(for: self.calModel.sMonth)
                }
            }
            /// Grab Transaction Title Suggestions.
            group.addTask { await self.calModel.fetchSuggestedTitles() }
            /// Grab Logos.
            group.addTask { await self.fetchLogos() }
            /// Grab Categories.
            group.addTask { await self.catModel.fetchCategories() }
            /// Grab Category Groups.
            group.addTask { await self.catModel.fetchCategoryGroups() }
            /// Grab Keywords.
            group.addTask { await self.keyModel.fetchKeywords() }
            /// Grab Repeating Transactions.
            group.addTask { await self.repModel.fetchRepeatingTransactions() }
            /// Grab Events.
            group.addTask { await self.eventModel.fetchEvents() }
            /// Grab Invitations.
            group.addTask { await self.eventModel.fetchInvitations() }
            /// Grab plaid things.
            group.addTask { await self.plaidModel.fetchBanks() }
            /// Grab Open Records.
            group.addTask { await OpenRecordManager.shared.fetchOpenOrClosed() }
        }
        
        let everytingElseElapsed = CFAbsoluteTimeGetCurrent() - everythingElseStart
        print("⏰It took \(everytingElseElapsed) seconds to fetch all accessorials")
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
            
            /// Grab Payment Methods and their logos.
            group.addTask {
                await self.payModel.fetchPaymentMethods(calModel: self.calModel)
                await self.fetchLogos()
            }
            /// Grab Transaction Title Suggestions.
            group.addTask { await self.calModel.fetchSuggestedTitles() }
            /// Grab Categories.
            group.addTask { await self.catModel.fetchCategories() }
            /// Grab Category Groups.
            group.addTask { await self.catModel.fetchCategoryGroups() }
            /// Grab Keywords.
            group.addTask { await self.keyModel.fetchKeywords() }
            /// Grab Repeating Transactions.
            group.addTask { await self.repModel.fetchRepeatingTransactions() }
            /// Grab Events.
            group.addTask { await self.eventModel.fetchEvents() }
            /// Grab Event Invitations
            group.addTask { await self.eventModel.fetchInvitations() }
            /// Grab plaid things.
            group.addTask { await self.plaidModel.fetchBanks() }
            /// Grab Open Records.
            group.addTask { await OpenRecordManager.shared.fetchOpenOrClosed() }
            
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
        print("⏰It took \(everytingElseElapsed) seconds to fetch all other months")
    }
    
    
    
    
    
    // MARK: - Cache Stuff
    /// Not private because it is called directly from the RootView
    func populatePaymentMethodsFromCache(setDefaultPayMethod: Bool) async {
        print("-- \(#function)")
        let context = DataManager.shared.createContext()
        
        var objectIDs: Array<NSManagedObjectID>?
        await context.perform {
            let meths = DataManager.shared.getMany(context: context, type: PersistentPaymentMethod.self)
            if let meths {
                /// Get object IDs from the core data entities
                objectIDs = meths.map { $0.objectID }
            }
        }
        
        guard let objectIDs else { print("❌ No Object IDs found for pay methods"); return }
                
        await MainActor.run {
            let mainContext = DataManager.shared.container.viewContext
            let mainObjects: [PersistentPaymentMethod] = objectIDs.compactMap {
                mainContext.object(with: $0) as? PersistentPaymentMethod
            }
            
            mainObjects.forEach { meth in
                if setDefaultPayMethod && meth.isViewingDefault {
                    calModel.sPayMethod = CBPaymentMethod(entity: meth)
                }
                
                if let id = meth.id, !payModel.paymentMethods.contains(where: { $0.id == id }) {
                    payModel.paymentMethods.append(CBPaymentMethod(entity: meth))
                }
            }
            
            /// Sort the payment methods in place.
            payModel.paymentMethods.sort(by: Helpers.paymentMethodSorter())
            
            /// Prepopulate the payment method sections to avoid flash on first viewing.
            payModel.sections = payModel.getApplicablePayMethods(
                type: .all,
                calModel: calModel,
                plaidModel: plaidModel,
                searchText: .constant("")
            )
                                                                    
//            let sortedMeths = mainObjects
//                .sorted { ($0.title ?? "").lowercased() < ($1.title ?? "").lowercased() }
//
//            for meth in sortedMeths {
//                if setDefaultPayMethod && meth.isViewingDefault {
//                    calModel.sPayMethod = CBPaymentMethod(entity: meth)
//                }
//                
//                if let id = meth.id, !payModel.paymentMethods.contains(where: { $0.id == id }) {
//                    payModel.paymentMethods.append(CBPaymentMethod(entity: meth))
//                }
//            }
        }
    }
        
    /// Not private because it is called directly from the RootView, and from the temp transaction list
    func populateCategoriesFromCache() async {
        print("-- \(#function)")
        let context = DataManager.shared.createContext()
                        
        var objectIDs: Array<NSManagedObjectID>?
        await context.perform {
            let meths = DataManager.shared.getMany(context: context, type: PersistentCategory.self)
            if let meths {
                /// Get object IDs from the core data entities
                objectIDs = meths.map { $0.objectID }
            }
        }
        
        guard let objectIDs else { print("❌ No Object IDs found for categories"); return }
                
        await MainActor.run {
            let mainContext = DataManager.shared.container.viewContext
            let mainObjects: [PersistentCategory] = objectIDs.compactMap {
                mainContext.object(with: $0) as? PersistentCategory
            }
            
            mainObjects
                .forEach { cat in
                if let id = cat.id, !catModel.categories.contains(where: { $0.id == id }) {
                    catModel.categories.append(CBCategory(entity: cat))
                }
            }
            
            catModel.categories.sort(by: Helpers.categorySorter())
        }
    }
    
    
    private func populateKeywordsFromCache() async {
        print("-- \(#function)")
        let context = DataManager.shared.createContext()
                
        var objectIDs: Array<NSManagedObjectID>?
        await context.perform {
            let meths = DataManager.shared.getMany(context: context, type: PersistentKeyword.self)
            if let meths {
                /// Get object IDs from the core data entities
                objectIDs = meths.map { $0.objectID }
            }
        }
        
        guard let objectIDs else { print("❌ No Object IDs found for keywords"); return }
    
        await MainActor.run {
            let mainContext = DataManager.shared.container.viewContext
            let mainObjects: [PersistentKeyword] = objectIDs.compactMap {
                mainContext.object(with: $0) as? PersistentKeyword
            }
            
            mainObjects
                .sorted { ($0.keyword ?? "").lowercased() < ($1.keyword ?? "").lowercased() }
                .forEach { key in
                    if let id = key.id, !keyModel.keywords.contains(where: { $0.id == id }) {
                        keyModel.keywords.append(CBKeyword(entity: key))
                    }
                }
        }
    
        
        
//        do {
//            let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("cache_directory.sqlite")
//            let dbQueue = try DatabaseQueue(path: url.path)
//            try await dbQueue.write { db in
//                let keys = try CBKeyword.fetchAll(db)
//                Task { @MainActor in
//                    keys
//                        .sorted { ($0.keyword).lowercased() < ($1.keyword).lowercased() }
//                        .forEach { key in
//                            
//                            if let index = self.keyModel.keywords.firstIndex(where: { $0.id == key.id }) {
//                                self.keyModel.keywords[index].setFromAnotherInstance(keyword: key)
//                            } else {
//                                self.keyModel.keywords.append(key)
//                            }
//                        }
//                }
//            }
//        } catch {
//            print(error.localizedDescription)
//        }
        
//        let man = CacheManager<CBKeyword>(file: .keywords)
//        if let keys = man.loadMany() {
//            Task { @MainActor in
//                keys
//                    .sorted { ($0.keyword).lowercased() < ($1.keyword).lowercased() }
//                    .forEach { key in
//
//                        if let index = keyModel.keywords.firstIndex(where: { $0.id == key.id }) {
//                            keyModel.keywords[index].setFromAnotherInstance(keyword: key)
//                        } else {
//                            keyModel.keywords.append(key)
//                        }
//                    }
//            }
//        }
        
//        let keys = DataManager.shared.getMany(context: context, type: PersistentKeyword.self)
//        if let keys {
//            let objectIDs = keys.map { $0.objectID }
//            
//            Task { @MainActor in
//                let mainContext = DataManager.shared.container.viewContext
//                let mainObjects: [PersistentKeyword] = objectIDs.compactMap {
//                    mainContext.object(with: $0) as? PersistentKeyword
//                }
//                
//                mainObjects
//                    .sorted { ($0.keyword ?? "").lowercased() < ($1.keyword ?? "").lowercased() }
//                //.filter { $0.id != nil } /// Have a weird bug that added blank in CoreData.
//                    .forEach { key in
//                        //print(key.keyword)
//                        if keyModel.keywords.filter({ $0.id == key.id! }).isEmpty {
//                            keyModel.keywords.append(CBKeyword(entity: key))
//                        }
//                    }
//            }
//        }
       
    }
    
    
    
    
    
    // MARK: - Long Poll Stuff
    @MainActor func longPollServerForChanges() {
        print("-- \(#function)")
        
        if longPollTask == nil {
            print("Longpoll task does not exist. Creating.")
            longPollTask = Task {
                await longPollServer(lastReturnTime: nil)
            }
        } else {
            print("Longpoll task exists")
            if longPollTask!.isCancelled {
                print("Long poll task has been cancelled. Restarting")
                longPollTask = Task {
                    await longPollServer(lastReturnTime: nil)
                }
            } else {
                print("Long poll task has not been cancelled and is running. Ignoring.")
            }
        }
        
        @MainActor
        func longPollServer(lastReturnTime: Int?) async {
            //return
            print("-- \(#function) -- starting with lastReturnTime: \(String(describing: lastReturnTime))")
            LogManager.log()
                                
            let model = RequestModel(requestType: "longpoll_server", model: LongPollSubscribeModel(lastReturnTime: lastReturnTime))
            typealias ResultResponse = Result<LongPollModel?, AppError>
            async let result: ResultResponse = await NetworkManager().longPollServer(requestModel: model)
            
            switch await result {
            case .success(let model):
                LogManager.networkingSuccessful()
                
                AppState.shared.lastNetworkTime = .now
                
                var lastReturnTimeFromServer: Int?
                
                if let model {
                    //print("GOT SUccessful long poll model with return time \(String(describing: model.returnTime))")
                    lastReturnTimeFromServer = model.returnTime
                    
                    if model.transactions != nil
                    || model.fitTransactions != nil
                    || model.startingAmounts != nil
                    || model.repeatingTransactions != nil
                    || model.payMethods != nil
                    || model.categories != nil
                    || model.categoryGroups != nil
                    || model.keywords != nil
                    || model.budgets != nil
                    || model.events != nil
                    || model.eventTransactions != nil
                    || model.eventTransactionOptions != nil
                    || model.eventCategories != nil
                    || model.eventItems != nil
                    || model.eventParticipants != nil
                    || model.invitations != nil
                    || model.openRecords != nil
                    || model.plaidBanks != nil
                    || model.plaidAccounts != nil
                    || model.plaidTransactionsWithCount != nil
                    || model.plaidBalances != nil
                    || model.logos != nil
                    {
                        
                        #warning("This all needs to be fixed in regards to coredata. Right now, each update of the cache or delete ferom the cache uses its own context, and saves after each operation. If I used a single background context, when deleting a payment method via the long poll, the save operation will fail. It is recommended to perform all operations, and then call save at the end. But this will require some work to implement. 11/6/25")
                        //try? await Task.sleep(nanoseconds: UInt64(5 * Double(NSEC_PER_SEC)))
                        
                        if let transactions = model.transactions { self.handleLongPollTransactions(transactions) }
                        
//                        if AppState.shared.user?.id == 1 {
//                            if let fitTransactions = model.fitTransactions { self.handleLongPollFitTransactions(fitTransactions) }
//                        }
                        
                        if let startingAmounts = model.startingAmounts { self.handleLongPollStartingAmounts(startingAmounts) }
                        if let repeatingTransactions = model.repeatingTransactions { await self.handleLongPollRepeatingTransactions(repeatingTransactions) }
                        if let payMethods = model.payMethods { await self.handleLongPollPaymentMethods(payMethods) }
                        if let categories = model.categories { await self.handleLongPollCategories(categories) }
                        if let categoryGroups = model.categoryGroups { await self.handleLongPollCategoryGroups(categoryGroups) }
                        if let keywords = model.keywords { await self.handleLongPollKeywords(keywords) }
                        if let budgets = model.budgets { self.handleLongPollBudgets(budgets) }
                        
                        if let events = model.events { await self.handleLongPollEvents(events) }
                        if let eventTransactions = model.eventTransactions { await self.handleLongPollEventTransactions(eventTransactions) }
                        if let eventTransactionOptions = model.eventTransactionOptions { await self.handleLongPollEventTransactionOptions(eventTransactionOptions) }
                        if let eventCategories = model.eventCategories { await self.handleLongPollEventCategories(eventCategories) }
                        if let eventItems = model.eventItems { await self.handleLongPollEventItems(eventItems) }
                        if let eventParticipants = model.eventParticipants { await self.handleLongPollEventParticipants(eventParticipants) }
                        
                        if let invitations = model.invitations { await self.handleLongPollInvitations(invitations) }
                        if let openRecords = model.openRecords { await self.handleLongPollOpenRecords(openRecords) }
                        
                        if let plaidBanks = model.plaidBanks { await self.handleLongPollPlaidBanks(plaidBanks) }
                        if let plaidAccounts = model.plaidAccounts { await self.handleLongPollPlaidAccounts(plaidAccounts) }
                        if let plaidTransactionsWithCount = model.plaidTransactionsWithCount { self.handleLongPollPlaidTransactions(plaidTransactionsWithCount) }
                        if let plaidBalances = model.plaidBalances { self.handleLongPollPlaidBalances(plaidBalances) }
                        
                        if let logos = model.logos { self.handleLongPollLogos(logos) }
                    }
                } else {
                    //print("GOT UNNNNSUccessful long poll model with return time \(String(describing: model?.returnTime))")
                    lastReturnTimeFromServer = lastReturnTime
                }
                
                
                //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
                
                print("restarting longpoll - \(Date())")
                await longPollServer(lastReturnTime: lastReturnTimeFromServer)
                
            case .failure (let error):
                switch error {
                case .taskCancelled:
                    /// Task gets cancelled when logging out. So only show the alert if the error is not related to the task being cancelled.
                    print("Task Cancelled")
                case .incorrectCredentials:
                    print("NO LONG POLL PERMISSION")
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
        print("-- \(#function)")
        calModel.handleTransactions(transactions, refreshTechnique: .viaLongPoll)
        
        let months = transactions.filter { $0.date != nil }.map { $0.dateComponents?.month }.uniqued()
        months.forEach { month in
            let montObj = calModel.months.filter{ $0.num == month }.first!
            let _ = calModel.calculateTotal(for: montObj)
        }
        
        DataChangeTriggers.shared.viewDidChange(.calendar)
    }
    
    
//    @MainActor private func handleLongPollFitTransactions(_ transactions: Array<CBFitTransaction>) {
//        print("-- \(#function)")
//        for trans in transactions {
//            if calModel.doesExist(trans) {
//                if trans.isAcknowledged {
//                    calModel.delete(trans)
//                    continue
//                } else {
//                    if let index = calModel.getIndex(for: trans) {
//                        calModel.fitTrans[index].setFromAnotherInstance(trans: trans)
//                    }
//                }
//            } else {
//                if !trans.isAcknowledged {
//                    calModel.upsert(trans)
//                }
//            }
//        }
//    }
    
    
    @MainActor private func handleLongPollStartingAmounts(_ startingAmounts: Array<CBStartingAmount>) {
        print("-- \(#function)")
        for startingAmount in startingAmounts {
            //let year = startingAmount.year
            
//            if startingAmount.month == 1 && startingAmount.year == AppState.shared.todayYear + 1 {
//                startingAmount.month = 13
//            } else if startingAmount.month == 12 && startingAmount.year == AppState.shared.todayYear - 1 {
//                startingAmount.month = 0
//            }
            
            let month = startingAmount.month
            let year = startingAmount.year
            
            
            let targetMonth = calModel.months.filter{ $0.actualNum == month && $0.year == year }.first
            if let targetMonth {
                let targetAmount = targetMonth.startingAmounts.filter{ $0.payMethod.id == startingAmount.payMethod.id }.first
                if let targetAmount {
                    
                    if !startingAmount.active {
                        targetAmount.amountString = ""
                    } else {
                        targetAmount.setFromAnotherInstance(startingAmount: startingAmount)
                    }
                } else {
                    self.prepareStartingAmounts(for: targetMonth)
                    //calModel.prepareStartingAmount(for: startingAmount.payMethod)
                    let targetAmount = targetMonth.startingAmounts.filter{ $0.payMethod.id == startingAmount.payMethod.id }.first
                    if let targetAmount {
                        targetAmount.setFromAnotherInstance(startingAmount: startingAmount)
                    }
                    
                }
            }
            
            let montObj = calModel.months.filter{ $0.num == month }.first!
            let _ = calModel.calculateTotal(for: montObj)
        }
    }
    
    
    @MainActor private func handleLongPollRepeatingTransactions(_ repeatingTransactions: Array<CBRepeatingTransaction>) async {
        print("-- \(#function)")
        for transaction in repeatingTransactions {
            if repModel.doesExist(transaction) {
                if !transaction.active {
                    repModel.delete(transaction, andSubmit: false)
                } else {
                    if let index = repModel.getIndex(for: transaction) {
                        repModel.repTransactions[index].setFromAnotherInstance(repTransaction: transaction)
                        repModel.repTransactions[index].deepCopy?.setFromAnotherInstance(repTransaction: transaction)
                    }
                }
            } else {
                if transaction.active {
                    withAnimation { repModel.upsert(transaction) }
                }
            }
        }
    }
    
    
    @MainActor private func handleLongPollPaymentMethods(_ payMethods: Array<CBPaymentMethod>) async {
        print("-- \(#function)")
        
        //let ogListOrders = payModel.paymentMethods.map { $0.listOrder ?? 0 }.sorted()
        //var newListOrders: [Int] = []
        
        let context = DataManager.shared.createContext()
        for payMethod in payMethods {
            //newListOrders.append(payMethod.listOrder ?? 0)
            if payModel.doesExist(payMethod) {
                if !payMethod.active {
                    payModel.delete(payMethod, andSubmit: false, calModel: calModel)
                    continue
                } else {
                    if let index = payModel.getIndex(for: payMethod) {
                        payModel.paymentMethods[index].setFromAnotherInstance(payMethod: payMethod)
                        payModel.paymentMethods[index].deepCopy?.setFromAnotherInstance(payMethod: payMethod)
                    }
                }
            } else {
                if payMethod.active {
                    withAnimation { payModel.upsert(payMethod) }
                }
            }
            if payMethod.isPermitted {
                let _ = await payModel.updateCache(for: payMethod)
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
        
        payModel.determineIfUserIsRequiredToAddPaymentMethod()
        
        self.prepareStartingAmounts(for: calModel.sMonth)
        
//        if newListOrders != ogListOrders {
//            DataChangeTriggers.shared.viewDidChange(.paymentMethodListOrders)
//        }
        
    }
    
    
    @MainActor private func handleLongPollCategories(_ categories: Array<CBCategory>) async {
        print("-- \(#function)")
        for category in categories {
            if catModel.doesExist(category) {
                if !category.active {
                    catModel.delete(category, andSubmit: false, calModel: calModel, keyModel: keyModel)
                    continue
                } else {
                    if let index = catModel.getIndex(for: category) {
                        catModel.categories[index].setFromAnotherInstance(category: category)
                        catModel.categories[index].deepCopy?.setFromAnotherInstance(category: category)
                    }
                }
            } else {
                if category.active {
                    withAnimation { catModel.upsert(category) }
                }
            }
            let _ = await catModel.updateCache(for: category)
            //print("SaveResult: \(saveResult)")
            
            calModel.justTransactions.filter { $0.category?.id == category.id }.forEach { $0.category = category }
            repModel.repTransactions.filter { $0.category?.id == category.id }.forEach { $0.category = category }
        }
        
        //let categorySortMode = SortMode.fromString(UserDefaults.standard.string(forKey: "categorySortMode") ?? "")
                           
        withAnimation {
            catModel.categories.sort(by: Helpers.categorySorter())
        }
    }
    
    
    @MainActor private func handleLongPollCategoryGroups(_ groups: Array<CBCategoryGroup>) async {
        print("-- \(#function)")
        for group in groups {
            if catModel.doesExist(group) {
                if !group.active {
                    catModel.delete(group, andSubmit: false)
                    continue
                } else {
                    if let index = catModel.getIndex(for: group) {
                        catModel.categoryGroups[index].setFromAnotherInstance(group: group)
                        catModel.categoryGroups[index].deepCopy?.setFromAnotherInstance(group: group)
                    }
                }
            } else {
                if group.active {
                    withAnimation { catModel.upsert(group) }
                }
            }
        }
    }
    
    
    @MainActor private func handleLongPollKeywords(_ keywords: Array<CBKeyword>) async {
        print("-- \(#function)")
        for keyword in keywords {
            if keyModel.doesExist(keyword) {
                if !keyword.active {
                    keyModel.delete(keyword, andSubmit: false)
                    continue
                } else {
                    if let index = keyModel.getIndex(for: keyword){
                        keyModel.keywords[index].setFromAnotherInstance(keyword: keyword)
                        keyModel.keywords[index].deepCopy?.setFromAnotherInstance(keyword: keyword)
                    }
                }
            } else {
                if keyword.active {
                    withAnimation { keyModel.upsert(keyword) }
                }
            }
            let _ = await keyModel.updateCache(for: keyword)
            //print("SaveResult: \(saveResult)")
        }
    }
    
    
    @MainActor private func handleLongPollBudgets(_ budgets: Array<CBBudget>) {
        print("-- \(#function)")
        for budget in budgets {
            if let targetMonth = calModel.months.filter({ $0.actualNum == budget.month && budget.year == $0.year }).first {
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
    
    
    @MainActor private func handleLongPollLogos(_ logos: Array<CBLogo>) {
        print("-- \(#function)")
        let context = DataManager.shared.createContext()
        
        for logo in logos {
            guard
                let baseString = logo.baseString,
                let logoData = Data(base64Encoded: baseString),
                let perLogo = DataManager.shared.getOne(context: context, type: PersistentLogo.self, predicate: .byId(.string(logo.id)), createIfNotFound: false)
            else {
                continue
            }
                        
            perLogo.photoData = logoData
            perLogo.serverUpdatedDate = logo.updatedDate
            perLogo.localUpdatedDate = logo.updatedDate
            
            if logo.relatedRecordType.enumID == .paymentMethod {
                let meth = payModel.getPaymentMethod(by: logo.relatedID)
                meth.logo = logoData
                
                calModel.justTransactions
                    .filter { $0.payMethod?.id == meth.id }
                    .forEach { $0.payMethod?.logo = meth.logo }
            }        
        }
        
        let _ = DataManager.shared.save(context: context)
    }
    
    
    @MainActor private func handleLongPollEvents(_ events: Array<CBEvent>) async {
        print("-- \(#function)")
        print("-- \(#function)")
        
        for event in events {
            let doesUserHavePermission = event.activeParticipantUserIds.contains(AppState.shared.user!.id)
            
            if eventModel.doesExist(event) {
                
                /// If the event has been deleted, remove it.
                if !event.active {
                    withAnimation {
                        eventModel.revoke(event)
                    }
                    
                    if !event.amIAdmin() {
                        AppState.shared.showToast(title: "Event Removed", subtitle: event.title, body: "The event has been removed by the host.", symbol: "calendar.badge.minus")
                    }
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
//                                                            
                    /// Find the event in the users data.
                    if let index = eventModel.getIndex(for: event) {
                        eventModel.events[index].setFromAnotherInstanceForLongPoll(event: event)
                        eventModel.events[index].deepCopy?.setFromAnotherInstanceForLongPoll(event: event)
                    }
                }
            } else {
                /// If the event is active, check to make sure the user is allowed to see it.
                /// If they are, upsert the event.
                if event.active {
                    /// See if the user has an active participant record.
                    
                    if doesUserHavePermission {
                        eventModel.upsert(event)
                        eventModel.invitations.removeAll(where: {$0.eventID == event.id})
                    }
                }
            }
        }
    }
    
    
    @MainActor private func handleLongPollEventTransactions(_ transactions: Array<CBEventTransaction>) async {
        print("-- \(#function)")
        for trans in transactions {
            //print(trans.title)
            if let index = eventModel.events.firstIndex(where: {$0.id == trans.eventID}) {
                let event = eventModel.events[index]
                
                if event.doesExist(trans) {
                    if !trans.active {
                        event.deleteTransaction(id: trans.id)
                        await eventModel.delete(trans, andSubmit: false)
                        continue
                    } else {
                        if let index = event.getIndex(for: trans) {                            
                            if event.transactions[index].updatedDate < trans.updatedDate {
                                event.transactions[index].setFromAnotherInstance(transaction: trans)
                                event.transactions[index].deepCopy?.setFromAnotherInstance(transaction: trans)
                            }
                        }
                    }
                } else {
                    if trans.active {
                        event.upsert(trans)
                    }
                }
            }
        }
    }
    
    
    @MainActor private func handleLongPollEventTransactionOptions(_ options: Array<CBEventTransactionOption>) async {
        print("-- \(#function)")
        for option in options {
            if let index = eventModel.justTransactions.firstIndex(where: {$0.id == option.transactionID}) {
                let trans = eventModel.justTransactions[index]
                
                
                //print("found trans id \(trans.id) for item id \(item.id)")
                
                if trans.doesExist(option) {
                    if !option.active {
                        trans.deleteOption(id: option.id)
                        continue
                    } else {
                        if let index = trans.getIndex(for: option) {
                            trans.options?[index].setFromAnotherInstance(option: option)
                            trans.options?[index].deepCopy?.setFromAnotherInstance(option: option)
                        }
                    }
                } else {
                    //print("item does not exist")
                    if option.active {
                        //print("upserting")
                        trans.upsert(option)
                    }
                }
            }
        }
    }
    
    
    @MainActor private func handleLongPollEventCategories(_ categories: Array<CBEventCategory>) async {
        print("-- \(#function)")
        var eventIdsThatGotChanged: Array<String> = []
        
        for cat in categories {
            if let index = eventModel.events.firstIndex(where: {$0.id == cat.eventID}) {
                let event = eventModel.events[index]
                
                eventIdsThatGotChanged.append(event.id)
                
                if event.doesExist(cat) {
                    if !cat.active {
                        event.deleteCategory(id: cat.id)
                        await eventModel.delete(cat, andSubmit: false)
                        continue
                    } else {
                        if let index = event.getIndex(for: cat) {
                            event.categories[index].setFromAnotherInstance(category: cat)
                            event.categories[index].deepCopy?.setFromAnotherInstance(category: cat)
                        }
                    }
                } else {
                    if cat.active {
                        event.upsert(cat)
                    }
                }
            }
        }
        
        for id in eventIdsThatGotChanged {
            if let index = eventModel.events.firstIndex(where: {$0.id == id}) {
                withAnimation {
                    eventModel.events[index].categories.sort { $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000 }
                }
            }
        }
    }
    
    
    @MainActor private func handleLongPollEventItems(_ items: Array<CBEventItem>) async {
        print("-- \(#function)")
        var eventIdsThatGotChanged: Array<String> = []
        for item in items {
            if let index = eventModel.events.firstIndex(where: {$0.id == item.eventID}) {
                let event = eventModel.events[index]
                
                eventIdsThatGotChanged.append(event.id)
                
                if event.doesExist(item) {
                    if !item.active {
                        event.deleteItem(id: item.id)
                        await eventModel.delete(item, andSubmit: false)
                        continue
                    } else {
                        if let index = event.getIndex(for: item) {
                            event.items[index].setFromAnotherInstance(item: item)
                            event.items[index].deepCopy?.setFromAnotherInstance(item: item)
                        }
                    }
                } else {
                    if item.active {
                        event.upsert(item)
                    }
                }
            }
        }
        
        for id in eventIdsThatGotChanged {
            if let index = eventModel.events.firstIndex(where: {$0.id == id}) {
                withAnimation {
                    eventModel.events[index].items.sort { $0.listOrder ?? 1000000000 < $1.listOrder ?? 1000000000 }
                }
            }
        }
    }
    
    
    @MainActor private func handleLongPollEventParticipants(_ parts: Array<CBEventParticipant>) async {
        print("-- \(#function)")
        for part in parts {
            if let index = eventModel.events.firstIndex(where: {$0.id == part.eventID}) {
                let event = eventModel.events[index]
                
                if event.doesExist(part) {
                    if !part.active {
                        event.deleteParticipant(id: part.id)
                        await eventModel.delete(part, andSubmit: false)
                        
                        /// Revoke the event from the user if applicable
                        if part.user.id == AppState.shared.user!.id {
                            withAnimation {
                                eventModel.revoke(event)
                            }
                            AppState.shared.showToast(title: "Event Revoked", subtitle: event.title, body: "You have been removed by the host.", symbol: "person.slash.fill")
                        }
                        
                        continue
                    } else {
                        if let index = event.getIndex(for: part) {
                            event.participants[index].setFromAnotherInstance(part: part)
                            event.participants[index].deepCopy?.setFromAnotherInstance(part: part)
                        }
                    }
                } else {
                    if part.active {
                        event.upsert(part)
                    }
                }
            }
        }
    }
    
    
    @MainActor private func handleLongPollInvitations(_ participants: Array<CBEventParticipant>) async {
        print("-- \(#function)")
        //print(participants.map {$0.email})
        //print(participants.map {$0.active})
        //print(participants.map {$0.id})
        //print(participants.map {$0.status?.description})
        
        for part in participants {
            if eventModel.doesExist(part) {
                /// If the invite is inactive, that means the invitee rejected it.
                if !part.active {
                    /// Remove the invitation from the invitation list.
                    eventModel.removeInvitation(by: part.id)
                    
                    /// Remove the pending invitation from the associated event.
//                    if let targetEvent = eventModel.events.filter({ $0.id == part.eventID }).first {
//                        targetEvent.deleteParticipant(id: part.id)
//                    }
//                    
                    let event = eventModel.getEvent(by: part.eventID)
                    event.deleteParticipant(id: part.id)
                    
                    continue
                } else {
                    /// The event is active, so update the invitation in the model.
                    if let index = eventModel.getIndex(for: part) {
                        if part.status?.enumID == .rejected {
                            eventModel.removeInvitation(by: part.id)
                        } else {
                            eventModel.invitations[index].setFromAnotherInstance(part: part)
                        }
                    }
                }
            } else {
                /// Upsert the invite if it doesn't exist.
                if part.active {
                    if part.status?.enumID == .rejected {
                        /// Remove the invitation from the invitation list.
                        eventModel.removeInvitation(by: part.id)
                        /// Remove the pending invitation from the associated event.
//                        if let targetEvent = eventModel.events.filter({ $0.id == part.eventID }).first {
//                            targetEvent.deleteParticipant(id: part.id)
//                        }
                        let event = eventModel.getEvent(by: part.eventID)
                        event.deleteParticipant(id: part.id)
                    } else {
                        AppState.shared.showToast(title: "Invitation Received", subtitle: part.eventName, body: "Invited by \(part.inviteFrom?.name ?? "N/A")", symbol: "calendar.badge.plus")
                        withAnimation {
                            eventModel.upsert(part)
                        }
                        
                    }
                } else {
                    eventModel.removeInvitation(by: part.id)
                }
            }
        }
    }
    
    
//    @MainActor private func handleLongPollOpenEvents(_ openEvents: Array<CBEventViewMode>) async {
//        print("-- \(#function)")
//        
//        print(eventModel.openEvents.map {"\($0.user.id) - \($0.id)"})
//        
//        withAnimation {
//            for openEvent in openEvents {
//                if eventModel.doesExist(openEvent, what: .event) {
//                    if !openEvent.active {
//                        eventModel.deleteOpen(id: openEvent.id, what: .event)
//                        continue
//                    } else {
//                        if let index = eventModel.getIndex(for: openEvent, what: .event) {
//                            eventModel.openEvents[index].setFromAnotherInstance(openEvent: openEvent)
//                        }
//                    }
//                } else {
//                    if openEvent.active {
//                        eventModel.upsert(openEvent, what: .event)
//                    }
//                }
//            }
//        }
//    }
//    
//    @MainActor private func handleLongPollOpenEventTransactions(_ openEventTransactions: Array<CBEventViewMode>) async {
//        print("-- \(#function)")
//        withAnimation {
//            for openEventTrans in openEventTransactions {
//                if eventModel.doesExist(openEventTrans, what: .transaction) {
//                    if !openEventTrans.active {
//                        eventModel.deleteOpen(id: openEventTrans.id, what: .transaction)
//                        continue
//                    } else {
//                        if let index = eventModel.getIndex(for: openEventTrans, what: .transaction) {
//                            eventModel.openEvents[index].setFromAnotherInstance(openEvent: openEventTrans)
//                        }
//                    }
//                } else {
//                    if openEventTrans.active {
//                        eventModel.upsert(openEventTrans, what: .transaction)
//                    }
//                }
//            }
//        }
//    }
    
    
    @MainActor private func handleLongPollOpenRecords(_ openRecords: Array<CBOpenOrClosedRecord>) async {
        print("-- \(#function)")
        
        for openRecord in openRecords {
            let recordType = openRecord.recordType.enumID
            
            if OpenRecordManager.shared.doesExist(openRecord, what: recordType) {
                if !openRecord.active {
                    OpenRecordManager.shared.deleteOpen(id: openRecord.id, what: recordType)
                    continue
                } else {
                    if let index = OpenRecordManager.shared.getIndex(for: openRecord, what: recordType) {
                        OpenRecordManager.shared.openOrClosedRecords[index].setFromAnotherInstance(openEvent: openRecord)
                    }
                }
            } else {
                if openRecord.active {
                    OpenRecordManager.shared.upsert(openRecord, what: recordType)
                }
            }
        }
    }
    
    
    @MainActor private func handleLongPollPlaidBanks(_ banks: Array<CBPlaidBank>) async {
        print("-- \(#function)")
        for bank in banks {
            if plaidModel.doesExist(bank) {
                if !bank.active {
                    await plaidModel.delete(bank, andSubmit: false)
                    continue
                } else {
                    if let index = plaidModel.getIndex(for: bank) {
                        plaidModel.banks[index].setFromAnotherInstance(bank: bank)
                        plaidModel.banks[index].deepCopy?.setFromAnotherInstance(bank: bank)
                    }
                }
            } else {
                if bank.active {
                    plaidModel.upsert(bank)
                }
            }
        }
    }
    
    
    @MainActor private func handleLongPollPlaidAccounts(_ accounts: Array<CBPlaidAccount>) async {
        print("-- \(#function)")
        var eventIdsThatGotChanged: Array<String> = []
        
        for act in accounts {
            if let index = plaidModel.banks.firstIndex(where: { $0.id == act.bankID }) {
                let bank = plaidModel.banks[index]
                
                eventIdsThatGotChanged.append(bank.id)
                
                if bank.doesExist(act) {
                    if !act.active {
                        bank.deleteAccount(id: act.id)
                        continue
                    } else {
                        if let index = bank.getIndex(for: act) {
                            bank.accounts[index].setFromAnotherInstance(account: act)
                            bank.accounts[index].deepCopy?.setFromAnotherInstance(account: act)
                        }
                    }
                } else {
                    if act.active {
                        bank.upsert(act)
                    }
                }
            }
        }
        
//        for id in eventIdsThatGotChanged {
//            if let index = plaidModel.banks.firstIndex(where: { $0.id == id }) {
//                withAnimation {
//                    plaidModel.banks[index].accounts
//                }
//            }
//        }
    }
    
        
    @MainActor private func handleLongPollPlaidTransactions(_ transactionsWithCount: CBPlaidTransactionListWithCount) {
        print("-- \(#function)")
        plaidModel.totalTransCount = transactionsWithCount.count
        if let safeTrans = transactionsWithCount.trans {
            for trans in safeTrans {
                if plaidModel.doesExist(trans) {
                    if !trans.active {
                        plaidModel.delete(trans)
                        continue
                    } else {
                        if trans.isAcknowledged {
                            plaidModel.delete(trans)
                            continue
                        } else {
                            if let index = plaidModel.getIndex(for: trans) {
                                plaidModel.trans[index].setFromAnotherInstance(trans: trans)
                            }
                        }
                    }
                } else {
                    if !trans.isAcknowledged {
                        plaidModel.upsert(trans)
                    }
                }
            }
        }
    }
    
    
    @MainActor private func handleLongPollPlaidBalances(_ balances: Array<CBPlaidBalance>) {
        print("-- \(#function)")
        for bal in balances {
            if plaidModel.doesExist(bal) {
                if !bal.active {
                    plaidModel.delete(bal)
                    continue
                } else {
                    if let index = plaidModel.getIndex(for: bal) {
                        plaidModel.balances[index].setFromAnotherInstance(bal: bal)
                    }
                }
            } else {
                plaidModel.upsert(bal)
            }
        }
    }
    
    
    
    
    // MARK: - Misc
    @MainActor func prepareStartingAmounts(for month: CBMonth) {
        print("-- \(#function)")
        for payMethod in payModel.paymentMethods.filter({ !$0.isHidden || !$0.isPrivate }) {
            //print("preparing starting amounts for \(payMethod.title) - \(month.actualNum) - \(month.year)")
            //calModel.prepareStartingAmount(for: payMethod)
            
            /// Create a starting amount if it doesn't exist in the current month.
            if !month.startingAmounts.contains(where: { $0.payMethod.id == payMethod.id }) {
                //print("\(payMethod.title) does not exist - creating")
                let starting = CBStartingAmount()
                starting.payMethod = payMethod
                starting.action = .add
                //starting.month = calModel.sMonth.num
                //starting.year = calModel.sYear
                
                starting.month = month.actualNum
                starting.year = month.year
                
                starting.amountString = ""
                month.startingAmounts.append(starting)
            } else {
                //print("\(payMethod.title) does exist - not creating")
            }
                                                
            if payMethod.isUnified {
                let _ = calModel.updateUnifiedStartingAmount(month: month, for: payMethod.accountType)
            }
        }
    }
    
    
    
    @MainActor func getPlaidDebitSums() -> Double {
        let debitIDs = payModel.paymentMethods
            .filter { $0.isDebit }
            .filter { $0.isPermitted }
            .filter { !$0.isHidden }
            .map { $0.id }
        
        return plaidModel.balances
            .filter { debitIDs.contains($0.payMethodID) }
            .map { $0.amount }
            .reduce(0.0, +)
    }
    
    
    @MainActor func getPlaidCreditSums() -> Double {
        let creditIDs = payModel.paymentMethods
            .filter { $0.isCredit }
            .filter { $0.isPermitted }
            .filter { !$0.isHidden }
            .map { $0.id }
        
        return plaidModel.balances
            .filter { creditIDs.contains($0.payMethodID) }
            .map { $0.amount }
            .reduce(0.0, +)
    }
    
    
    @MainActor func getPlaidBalance() -> CBPlaidBalance? {
        plaidModel.balances
        .filter({ $0.payMethodID == calModel.sPayMethod?.id })
        .filter ({ bal in
            if let meth = payModel.paymentMethods.filter({ $0.id == bal.payMethodID }).first {
                return meth.isPermitted
            } else {
                return false
            }
        })
        .filter ({ bal in
            if let meth = payModel.paymentMethods.filter({ $0.id == bal.payMethodID }).first {
                return !meth.isHidden
            } else {
                return false
            }
        })
        .first
    }
    
    
//    @MainActor
//    func updateLogo(_ logoModel: UpdateLogoModel) async {
//        print("-- \(#function)")
//        //LoadingManager.shared.startDelayedSpinner()
//        LogManager.log()
//      
//        /// Networking
//        let model = RequestModel(requestType: "update_logo", model: logoModel)
//        
//        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
//        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
//                    
//        switch await result {
//        case .success(let model):
//            LogManager.networkingSuccessful()
//
//        case .failure(let error):
//            LogManager.error(error.localizedDescription)
//            AppState.shared.showAlert("There was a problem trying to fetch analytics.")
//            //showSaveAlert = true
//            #warning("Undo behavior")
//        }
//        //LoadingManager.shared.stopDelayedSpinner()
//    }
    
    
    @MainActor
    func fetchLogos(file: String = #file, line: Int = #line, function: String = #function) async {
        NSLog("\(file):\(line) : \(function)")
        LogManager.log()
        let start = CFAbsoluteTimeGetCurrent()
        
        var logos: Array<CBLogo> = []
        let context = DataManager.shared.createContext()
        if let perLogos = DataManager.shared.getMany(context: context, type: PersistentLogo.self) {
            for each in perLogos {
                if each.id == nil || each.relatedID == nil {
                    continue
                }
                logos.append(CBLogo(entity: each))
                
            }
        }
        
        let submitModel = LogoMaybeShouldUpdateModel(logos: logos)
        
        
        /// Do networking.
        let model = RequestModel(requestType: "fetch_logos", model: submitModel)
        typealias ResultResponse = Result<Array<CBLogo>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            
            /// For testing bad network connection.
            //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))

            LogManager.networkingSuccessful()
            if let model {
                if !model.isEmpty {
                    let context = DataManager.shared.createContext()
                    for logo in model {
                        print("Logo \(logo.id) changed")
                        /// Make sure the logo is legit data
                        guard
                            let baseString = logo.baseString,
                            let logoData = Data(base64Encoded: baseString)
                        else {
                            continue
                        }
                        
                        /// Find the persistent logo, create if not found
                        let pred1 = NSPredicate(format: "relatedID == %@", logo.relatedID)
                        let pred2 = NSPredicate(format: "relatedTypeID == %@", NSNumber(value: logo.relatedRecordType.id))
                        let comp = NSCompoundPredicate(andPredicateWithSubpredicates: [pred1, pred2])
                        
                        if let perLogo = DataManager.shared.getOne(
                            context: context,
                            type: PersistentLogo.self,
                            predicate: .compound(comp),
                            createIfNotFound: true
                        ) {
                            /// Update the persistent record
                            perLogo.photoData = logoData
                            perLogo.id = logo.id
                            perLogo.relatedID = logo.relatedID
                            perLogo.relatedTypeID = Int64(logo.relatedRecordType.id)
                            //perLogo.serverEnteredDate = logo.enteredDate
                            perLogo.localUpdatedDate = logo.updatedDate
                            perLogo.serverUpdatedDate = logo.updatedDate
                            
                            /// If the server logo is for a payment method
                            if logo.relatedRecordType.enumID == .paymentMethod {
                                /// Find the method and update it.
                                let meth = payModel.getPaymentMethod(by: logo.relatedID)
                                meth.logo = logoData
                                
                                /// Find all the transactions using the method and update their logo
                                calModel.justTransactions
                                    .filter { $0.payMethod?.id == meth.id }
                                    .forEach { $0.payMethod?.logo = logoData }
                                
                                repModel.repTransactions
                                    .filter { $0.payMethod?.id == meth.id || $0.payMethodPayTo?.id == meth.id}
                                    .forEach { $0.payMethod?.logo = logoData }
                            }
                        }
                    }
                    
                    let _ = DataManager.shared.save(context: context)
                    
                } else {
                    print("looks like no logos have changed")
                }
            }
            
            let currentElapsed = CFAbsoluteTimeGetCurrent() - start
            print("⏰It took \(currentElapsed) seconds to fetch payment method logos")
            
        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("repModel fetchFrom Server Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch payment method logos.")
            }
        }
    }
    
        
    
    
    // MARK: - Initial Download
    func downloadInitial() {
        @Bindable var navManager = NavigationManager.shared
        /// Set navigation destination to current month
        //navManager.selection = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
        #if os(iOS)
        navManager.selectedMonth = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
        #else
        navManager.selection = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
        #endif
        //navManager.monthSelection = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
        //navManager.navPath.append(NavDestination.getMonthFromInt(AppState.shared.todayMonth)!)
        
        LoadingManager.shared.showInitiallyLoadingSpinner = true
                    
        refreshTask = Task {
            /// populate all months with their days.
            await calModel.prepareMonths()
            #if os(iOS)
            if let selectedMonth = navManager.selectedMonth {
                /// set the calendar model to use the current month (ignore starting amounts and calculations)
                await calModel.setSelectedMonthFromNavigation(navID: selectedMonth, prepareStartAmount: false)
                /// download everything, and populate the days in the respective months with transactions.
                await downloadEverything(setDefaultPayMethod: true, createNewStructs: true, refreshTechnique: .viaInitial)
            } else {
                print("Selected Month Not Set")
            }
            #else
            if let selectedMonth = navManager.selection {
                /// set the calendar model to use the current month (ignore starting amounts and calculations)
                await calModel.setSelectedMonthFromNavigation(navID: selectedMonth, prepareStartAmount: false)
                /// download everything, and populate the days in the respective months with transactions.
                await downloadEverything(setDefaultPayMethod: true, createNewStructs: true, refreshTechnique: .viaInitial)
            }
            #endif
        }
    }
    
    
    
    
    @MainActor
    func submitListOrders(items: Array<ListOrderUpdate>, for updateType: ListOrderUpdateType) async -> Bool {
        print("-- \(#function)")
        LogManager.log()
        let model = RequestModel(requestType: "alter_list_orders", model: ListOrderUpdateModel(items: items, updateType: updateType))
        
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success:
            LogManager.networkingSuccessful()
            return true
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem syncing the category. Will try again at a later time.")
            return false
        }
        
        
    }
    
    
    
    
    // MARK: - Logout
    @MainActor func logout() {
        print("-- \(#function)")
        /// Clearing all session data related to login and loading indicators.
        AuthState.shared.clearLoginState()
        AppState.shared.downloadedData.removeAll()
        LoadingManager.shared.showInitiallyLoadingSpinner = true
        LoadingManager.shared.downloadAmount = 0
        LoadingManager.shared.showLoadingBar = true
        
        /// Cancel the long polling task.
        if let _ = longPollTask {
            longPollTask!.cancel()
            longPollTask = nil
        }
        
        /// Cancel the long polling task.
        if let _ = refreshTask {
            refreshTask!.cancel()
            refreshTask = nil
        }
        
        /// Remove all transactions and starting amounts for all months.
        calModel.months.forEach { month in
            month.startingAmounts.removeAll()
            month.days.forEach { $0.transactions.removeAll() }
            month.budgets.removeAll()
        }
        
        /// Remove all extra downloaded data.
        repModel.repTransactions.removeAll()
        payModel.paymentMethods.removeAll()
        catModel.categories.removeAll()
        catModel.categoryGroups.removeAll()
        keyModel.keywords.removeAll()
        eventModel.events.removeAll()
        eventModel.invitations.removeAll()
        
        NavigationManager.shared.selectedMonth = nil
        NavigationManager.shared.selection = nil
        NavigationManager.shared.navPath.removeAll()
                        
        let context = DataManager.shared.createContext()
        context.perform {
            let _ = DataManager.shared.deleteAll(context: context, for: PersistentPaymentMethod.self)
            let _ = DataManager.shared.deleteAll(context: context, for: PersistentCategory.self)
            let _ = DataManager.shared.deleteAll(context: context, for: PersistentKeyword.self)
            let _ = DataManager.shared.deleteAll(context: context, for: PersistentToast.self)
            let _ = DataManager.shared.deleteAll(context: context, for: PersistentLogo.self)
            
            // Save once after all deletions
            let _ = DataManager.shared.save(context: context)
        }
        
    }
    
    
//    func clearCoreDataCache() {
//        let context = DataManager.shared.createContext()
//
//        let _ = DataManager.shared.deleteAll(context: context, for: PersistentPaymentMethod.self)
//        let _ = DataManager.shared.deleteAll(context: context, for: PersistentCategory.self)
//        let _ = DataManager.shared.deleteAll(context: context, for: PersistentKeyword.self)
//        
//        // Save once after all deletions
//        let _ = DataManager.shared.save(context: context)
//        
//    }
    
}
