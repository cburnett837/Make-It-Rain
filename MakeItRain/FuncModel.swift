//
//  RootModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/4/24.
//

import Foundation
import SwiftUI
//import LocalAuthentication
//import GRDB
import CoreData
import WidgetKit


@Observable
class FuncModel {
    @ObservationIgnored private let store: AppStore
    var calModel: CalendarModel
    var payModel: PayMethodModel
    var catModel: CategoryModel
    var keyModel: KeywordModel
    var repModel: RepeatingTransactionModel
    var plaidModel: PlaidModel
    var webSocketManager: WebSocketManager
    var dashboardModel: DashboardModel
    var budgetModel: BudgetModel
    var tagModel: TagModel
    var calProps: CalendarProps
    
    //var longPollTask: Task<Void, Error>?
    var refreshTask: Task<Void, Error>?
    
    var isLoading = false
    var loadTimes: [(id: UUID, date: Date, load: Double)] = []
        
    init(
        store: AppStore,
        calModel: CalendarModel,
        payModel: PayMethodModel,
        catModel: CategoryModel,
        keyModel: KeywordModel,
        repModel: RepeatingTransactionModel,
        plaidModel: PlaidModel,
        webSocketManager: WebSocketManager,
        dashboardModel: DashboardModel,
        budgetModel: BudgetModel,
        tagModel: TagModel,
        calProps: CalendarProps
    ) {
        self.store = store
        self.calModel = calModel
        self.payModel = payModel
        self.catModel = catModel
        self.keyModel = keyModel
        self.repModel = repModel
        self.plaidModel = plaidModel
        self.webSocketManager = webSocketManager
        self.dashboardModel = dashboardModel
        self.budgetModel = budgetModel
        self.tagModel = tagModel
        self.calProps = calProps
    }
 
    
    /// Establish a UUID for each device for the long poll server. The long poll will not respond to the device that makes the change.
    @MainActor
    func setDeviceUUID() {
        if let uuid = UserDefaults(suiteName: "group.dev.cburnett837.MakeItRain")?.string(forKey: "deviceUUID") {
            AppState.shared.deviceUUID = uuid
            Cody.shared.deviceUUID = uuid
        } else {
            let uuid = UUID().uuidString
            UserDefaults(suiteName: "group.dev.cburnett837.MakeItRain")?.set(uuid, forKey: "deviceUUID")
            AppState.shared.deviceUUID = uuid
            Cody.shared.deviceUUID = uuid
        }
//        
//        if let uuid = UserDefaults.fetchOneString(requestedKey: "deviceUUID") {
//            AppState.shared.deviceUUID = uuid
//        } else {
//            let uuid = UUID().uuidString
//            UserDefaults.updateStringValue(valueToUpdate: uuid, keyToUpdate: "deviceUUID")
//            AppState.shared.deviceUUID = uuid
//        }
    }
    
    
    func checkIfDownloadingDataIsNeeded() async -> Bool {
        print("-- \(#function)")
        
        let submit = CheckIfShouldDownloadModel(lastNetworkTime: AppState.shared.lastNetworkTime ?? Date())
        let model = RequestModel(requestType: "check_for_changes", model: submit)
        typealias ResultResponse = Result<CheckIfShouldDownloadModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model, retainTime: false, timeout: 10)
        
        switch await result {
        case .success(let model):
            if let model = model {
                return model.shouldDownload
            } else {
                return true
            }
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            return true
        }
    }
    
    
    @MainActor
    func downloadEverything(
        setDefaultPayMethod: Bool,
        createNewStructs: Bool,
        refreshTechnique: RefreshTechnique,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) async {
        /// - Parameters:
        ///   - setDefaultPayMethod: Determine if the defaultPaymentMethod should be set.
        ///     I.E. true when launching the app fresh, or false when clicking the refresh buttons.
        ///   - createNewStructs: Determine whether to update the the objects that are in place, or destroy them and make new ones.
        ///     If true, this will tell the calModel to append the `CBTransactions` to the `CBDay`'s, as opposed to updating the existing ones. True will also result in the loading spinners being activated.
        ///   - refreshTechnique: Where this function was initiated from.
        ///     `.viaSceneChange, .viaTempListSceneChange` are used to keep a transaction alive and open if it is already open. (However `.viaTempListSceneChange` will fail at that job if the network status changes).
        ///     `.viaTempListButton, .viaTempListSceneChange` will both remove any existing transactions from the calendar, as to allow a complete refresh when returning to the calendar from the temp list.
        ///     `.viaInitial, .viaButton, .viaLongPoll` are not used, and are only used for clarity.
        
        
        print("-- \(#function) -- Called from: \(file) : \(line) : \(function)")
        
        withAnimation {
            isLoading = true
        }
        
        AppState.shared.lastNetworkTime = .now
        
        /// Time the downloading of the data.
        let start = CFAbsoluteTimeGetCurrent()
        
        /// Run this in case the user changes notificaiton settings, we will know about it ASAP.
        /// Must be MainActor.
        /// Run in a task so we don't have to wait for it.
        Task { AppState.shared.notificationsAreAllowed = await NotificationManager.shared.registerForPushNotifications() }
        
        /// Run in a task so we don't have to wait for it.
        Task { await setUserAvatars() }
                        
        WidgetCenter.shared.reloadTimelines(ofKind: "PlaidWidget")
        
//        /// Set user avatar.
//        let context = DataManager.shared.createContext()
//        let pred1 = NSPredicate(format: "relatedID == %@", String(AppState.shared.user!.id))
//        let pred2 = NSPredicate(format: "relatedTypeID == %@", NSNumber(value: 47))
//        let comp = NSCompoundPredicate(andPredicateWithSubpredicates: [pred1, pred2])
//        
//        if let perLogo = DataManager.shared.getOne(
//            context: context,
//            type: PersistentLogo.self,
//            predicate: .compound(comp),
//            createIfNotFound: true
//        ) {
//            print("Setting user avatar")
//            AppState.shared.user!.avatar = perLogo.photoData
//        } else {
//            print("did not find user avatar")
//        }
//        
        
        
        /// If coming from the tempList, remove all the data so it's guaranteed fresh.
        /// createNewStructs will be true here.
        if refreshTechnique == .viaTempListButton || refreshTechnique == .viaTempListSceneChange {
            //let _ = calModel.months.map { $0.days.map { $0.transactions.removeAll() } }
            calModel.months.forEach { $0.days.forEach { $0.transactions.removeAll() } }
        }
              
        /// Check if the user has bad connection.
        /// If so, network tasks will be cancelled, and a variable will be set in ``AppState`` and the app will flip to the temporary list.
        #warning("Concurrency: Come back to this and check")
        Task {
            if await hasBadConnection() {
                self.refreshTask?.cancel()
                //self.longPollTask?.cancel()
                webSocketManager.stopListening()
            }
        }
        
        #warning("Concurrency: Come back to this and check")
        webSocketManager.startListening()
        /// Restart long poll (if applicable).
        //longPollServerForChanges()
                
        /// Reset loading visuals (if applicable).
        /// Don't show the loading cover on the month if refreshing via scene change.
        calModel.months.forEach {
            $0.changeLoadingSpinners(toShowing: true, includeCalendar: createNewStructs)
        }
        
        /// Grab anything that got stuffed into temporary storage while the network connection was bad, and send it to the server before trying to download any new data.
        /// If I remove MainActor here, the app completely freezes on the splash screen..
        await submitCachedTransactionsIfApplicable()
        await submitCachedAccessorialsIfApplicable()
                                                     
        /// Populate accessorials from cache.
        payModel.methsAreCachedAtLaunch = false
        await payModel.populateFromCoreData(setDefaultPayMethod: setDefaultPayMethod, calModel: calModel)
        await catModel.populateFromCoreData()
        await catModel.populateCategoryGroupsFromCoreData()
        await keyModel.populateFromCoreData()
                            
        var next: CBMonth?
        var prev: CBMonth?
        
        /// See if the user is looking at a month view, accessorial view, or neither.
        var currentNavSelection = NavigationManager.shared.selection == nil ? NavigationManager.shared.selectedMonth : NavigationManager.shared.selection
        
        /// If the user is not looking at a month or accessorial view (such as when looking at the yearly grid), set nav selection to the current month.
        #if os(iOS)
        if currentNavSelection == nil {
            currentNavSelection = NavDest.getMonthFromInt(AppState.shared.todayMonth)
        }
        #endif
        
        if let currentNavSelection {
            /// If viewing a month, determine current and adjacent months.
            if NavDest.justMonths.contains(currentNavSelection) {
                /// Grab Payment Methods (only when logging in. We need this to have a payment method in place before the viewing month loads.)
                /// If not logging in, methods will be downloaded the accessory download function.
                if AppState.shared.isLoggingInForFirstTime, !payModel.methsAreCachedAtLaunch {
                    await payModel.fetchPaymentMethods(calModel: calModel)
                }
                
                let viewingMonth = calModel.months.get(byEnumId: currentNavSelection.id)
                
                payModel.prepareStartingAmounts(for: viewingMonth, calModel: calModel)
                                
                /// If not at the beginning or end of the data, download the months adjacent to the viewing month.
                if ![.lastDecember, .nextJanuary].contains(viewingMonth.enumID) {
                    next = calModel.months.getAdjacent(num: (currentNavSelection.monthNum ?? 0), direction: .next)
                    prev = calModel.months.getAdjacent(num: (currentNavSelection.monthNum ?? 0), direction: .prev)
                }
                
                //viewingMonth.hasBeenLoadedFromServer = true
                //AppState.shared.shouldShowSplash = false
        
                /// Download viewing month.
                await downloadViewingMonth(
                    viewingMonth,
                    createNewStructs: createNewStructs,
                    refreshTechnique: refreshTechnique
                )
                
                /// Download other months and accessorials.
                await downloadOtherMonthsAndAccessorials(
                    viewingMonth: viewingMonth,
                    next: next,
                    prev: prev,
                    createNewStructs: createNewStructs,
                    refreshTechnique: refreshTechnique
                )
                                
            } else {
                #warning("Fix this")
                /// Run this code if we come back from a sceneChange and are not viewing a month.
                /// If we're not viewing a month, then we must be viewing an accessorial view, so download those first.
                if NavDest.justAccessorials.contains(currentNavSelection) {
                    
                    /// Download user settings.
                    if refreshTechnique != .viaInitial {
                        await AppSettings.shared.fetch()
                    }
                    
                    /// Download other months and accessorials.
                    await downloadAccessorials(createNewStructs: createNewStructs)
                    
                    /// Download viewing month.
                    await downloadViewingMonth(
                        calModel.sMonth,
                        createNewStructs: createNewStructs,
                        refreshTechnique: refreshTechnique
                    )
                    
                    
                    /// Download Plaid stuff.
                    //await downloadPlaidStuff()
                    
                    /// Download adjacent months.
//                    await downloadAdjacentMonths(
//                        next: next,
//                        prev: prev,
//                        createNewStructs: createNewStructs,
//                        refreshTechnique: refreshTechnique
//                    )
                    
                    /// Download other months only.
                    await downloadOtherMonths(
                        viewingMonth: calModel.sMonth,
                        next: next,
                        prev: prev,
                        createNewStructs: createNewStructs,
                        refreshTechnique: refreshTechnique
                    )
                }
            }
        } else {
            fatalError("Nav Selection is nil")
        }
        
        self.refreshTask = nil
        
        let final = CFAbsoluteTimeGetCurrent() - (start)
        
        /// Log metrics in the debug page. These are not persisted between app hard-launches.
        let metric = (id: UUID(), date: Date(), load: final)
        loadTimes.append(metric)
        
        print("🔴Everything took \(final) seconds to fetch")
                
        withAnimation {
            isLoading = false
        }
    }
    
    
    
    // MARK: - Downloading Stuff
//    @MainActor private func downloadPlaidStuff() async {
//        let plaidStart = CFAbsoluteTimeGetCurrent()
//        
//        await withTaskGroup(of: Void.self) { group in
//            group.addTask {
//                //print("fetching plaid transactions");
//                let fetchModel = PlaidServerModel(rowNumber: 1)
//                await self.plaidModel.fetchPlaidTransactionsFromServer(fetchModel, accumulate: false)
//            }
//        
//            group.addTask {
//                //print("fetching plaid balances");
//                await self.plaidModel.fetchPlaidBalancesFromServer()
//            }
//        }
//        
//        let plaidElapsed = CFAbsoluteTimeGetCurrent() - plaidStart
//        print("⏰ It took \(plaidElapsed) seconds to fetch the plaid data")
//    }
    
    
    
    func hasBadConnection() async -> Bool {
        //print("-- \(#function)")
        
        let model = RequestModel(requestType: "check_connection", model: CodablePlaceHolder())
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model, timeout: 10)
        
        switch await result {
        case .success:
            AppState.shared.hasBadConnection = false
            return false
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.hasBadConnection = true
            AppState.shared.showAlert("Connection Problem")
            return true
        }
    }
    
    
    @MainActor
    private func downloadViewingMonth(
        _ viewingMonth: CBMonth,
        createNewStructs: Bool,
        refreshTechnique: RefreshTechnique
    ) async  {
        /// Grab the viewing month first.
        //print("fetching \(viewingMonth.num)");
        let start = CFAbsoluteTimeGetCurrent()
        
        viewingMonth.changeLoadingSpinners(toShowing: true, includeCalendar: createNewStructs)
        
        await self.fetchMonthlyData(
            month: viewingMonth,
            createNewStructs: createNewStructs,
            refreshTechnique: refreshTechnique
        )
        
        let currentElapsed = CFAbsoluteTimeGetCurrent() - start
        print("⏰ It took \(currentElapsed) seconds to fetch the first month")        
        /// During initial download, this willl flip from the splash screen to `RootView`.
        /// `RootView` task will open the calendar sheet.
        AppState.shared.shouldShowSplash = false
    }
        
    
//    @MainActor private func downloadAdjacentMonths(next: CBMonth?, prev: CBMonth?, createNewStructs: Bool, refreshTechnique: RefreshTechnique) async {
//        /// Grab months adjacent to viewing month.
//        let adjacentStart = CFAbsoluteTimeGetCurrent()
//        await withTaskGroup(of: Void.self) { group in
//            if let next {
//                group.addTask {
//                    //print("fetching \(next.num)");
//                    
//                    next.changeLoadingSpinners(toShowing: true, includeCalendar: createNewStructs)
//                    
//                    await self.calModel.fetchFromServer(
//                        month: next,
//                        createNewStructs: createNewStructs,
//                        refreshTechnique: refreshTechnique
//                    )
//                }
//            }
//            if let prev {
//                group.addTask {
//                    //print("fetching \(prev.num)");
//                    
//                    prev.changeLoadingSpinners(toShowing: true, includeCalendar: createNewStructs)
//                    
//                    await self.calModel.fetchFromServer(
//                        month: prev,
//                        createNewStructs: createNewStructs,
//                        refreshTechnique: refreshTechnique
//                    )
//                }
//            }
//        }
//        
//        let adjacentElapsed = CFAbsoluteTimeGetCurrent() - adjacentStart
//        print("⏰ It took \(adjacentElapsed) seconds to fetch the Adjacent months")
//    }
    
    
    @MainActor
    private func downloadOtherMonths(
        viewingMonth: CBMonth,
        next: CBMonth?,
        prev: CBMonth?,
        createNewStructs: Bool,
        refreshTechnique: RefreshTechnique
    ) async {
        /// Grab all the other months & extra data (payment methods, categories, etc)
        let everythingElseStart = CFAbsoluteTimeGetCurrent()
        await withTaskGroup(of: Void.self) { group in
            for month in calModel.months {
                
                month.changeLoadingSpinners(toShowing: true, includeCalendar: createNewStructs)
                
                //if let next, month.num == next.num { continue }
                //if let prev, month.num == prev.num { continue }
                
                if month.num != viewingMonth.num {
                    group.addTask {
                        //print("fetching \(month.num)");
                        await self.fetchMonthlyData(
                            month: month,
                            createNewStructs: createNewStructs,
                            refreshTechnique: refreshTechnique
                        )
                    }
                }
            }
        }
        
        let everytingElseElapsed = CFAbsoluteTimeGetCurrent() - everythingElseStart
        print("⏰ It took \(everytingElseElapsed) seconds to fetch all other months")
    }
    
    
    @MainActor
    private func downloadAccessorials(createNewStructs: Bool) async {
        /// Grab all the other months & extra data (payment methods, categories, etc)
        let everythingElseStart = CFAbsoluteTimeGetCurrent()
        await withTaskGroup(of: Void.self) { group in
                
            /// Grab Payment Methods (only if not logging in. If logging in, they are fetched before the viewing month is fetched).
            if !AppState.shared.isLoggingInForFirstTime {
                group.addTask {
                    await self.payModel.fetchPaymentMethods(calModel: self.calModel)
                    await self.payModel.prepareStartingAmounts(for: self.calModel.sMonth, calModel: self.calModel)
                }
            }
            
            /// Grab Logos.
            group.addTask { await self.fetchLogos() }
            
            /// Grab Categories, Category Groups, Keywords, Repeating Transactions, Plaid Banks, Christmas Budget, Suggested Titles, Tags.
            group.addTask { await self.fetchAccessorials() }
            
            /// Grab Receipts.
            group.addTask { await self.calModel.fetchReceiptsFromServer(funcModel: self) }
        }
        
        let everytingElseElapsed = CFAbsoluteTimeGetCurrent() - everythingElseStart
        print("⏰ It took \(everytingElseElapsed) seconds to fetch all logos, accessorials, and receipts.")
    }
    
        
    @MainActor
    private func downloadOtherMonthsAndAccessorials(
        viewingMonth: CBMonth,
        next: CBMonth?,
        prev: CBMonth?,
        createNewStructs: Bool,
        refreshTechnique: RefreshTechnique
    ) async {
        /// Grab all the other months & extra data (payment methods, categories, etc)
        //let everythingElseStart = CFAbsoluteTimeGetCurrent()
        
        await withTaskGroup(of: Void.self) { group in
            //group.addTask { await self.downloadPlaidStuff() }
            
            group.addTask {
                let dm = self.dashboardModel
                dm.beginDate = viewingMonth.legitDays.first!.date!.startDateOfMonth
                dm.endDate = viewingMonth.legitDays.last!.date!.endDateOfMonth
                await dm.initialFetchIfApplicable(calModel: self.calModel)
                dm.isDirty = false
            }
            
            for month in calModel.months {
                if month.num != viewingMonth.num {
                    group.addTask {
                        //print("fetching \(month.num)")
                        await self.fetchMonthlyData(month: month, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique)
                    }
                }
            }
            
            /// Grab Payment Methods (only if not logging in. If logging in, they are fetched before the viewing month is fetched).
            if !AppState.shared.isLoggingInForFirstTime {
                group.addTask { await self.payModel.fetchPaymentMethods(calModel: self.calModel) }
            }
            
            /// Grab Logos.
            group.addTask { await self.fetchLogos() }
            
            /// Grab Categories, Category Groups, Keywords, Repeating Transactions, Plaid Banks, Christmas Budget, Suggested Titles, Tags.
            group.addTask { await self.fetchAccessorials() }
            
            
//            group.addTask {
//                let dm = await self.calModel.dashboardModel
//                dm.beginDate = viewingMonth.legitDays.first!.date!.startDateOfMonth
//                dm.endDate = viewingMonth.legitDays.last!.date!.endDateOfMonth
//                await dm.initialFetchIfApplicable(catModel: self.catModel)
//                dm.isDirty = false
//            }
            
            /// Grab Receipts.
            //group.addTask { await self.calModel.fetchReceiptsFromServer(funcModel: self) }
        }
        //let everytingElseElapsed = CFAbsoluteTimeGetCurrent() - everythingElseStart
        //print("⏰ It took \(everytingElseElapsed) seconds to fetch all other months, logos, receipts, and accessorials.")
    }
    
    
    
    func fetchAccessorials(
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) async {
        NSLog("\(file):\(line) : \(function)")
        LogManager.log()
        
        let start = CFAbsoluteTimeGetCurrent()
        
        /// For testing bad network connection.
        //try? await Task.sleep(for: .seconds(10))
        
        let user = AppState.shared.user
        user?.year = await calModel.sYear
        
        let model = RequestModel(requestType: "fetch_accessorials", model: user)
        
        typealias ResultResponse = Result<AccessorialModelDecodable?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            if let model {
                if let settings = model.settings {
                    AppSettings.shared.setFromServerData(setting: settings)
                }
                                
                await self.payModel.handleIncoming(meths: model.paymentMethods, calModel: calModel, repModel: repModel, incomingDataType: .viaStandardRefresh)
                await self.catModel.handleIncoming(cats: model.categories, repModel: repModel, incomingDataType: .viaStandardRefresh)
                await self.catModel.handleIncoming(groups: model.categoryGroups, incomingDataType: .viaStandardRefresh)
                await self.keyModel.handleIncoming(keys: model.keywords, incomingDataType: .viaStandardRefresh)
                await self.repModel.handleIncoming(reps: model.repeatingTransactions, incomingDataType: .viaStandardRefresh)
                await self.tagModel.handleIncoming(tags: model.tags, incomingDataType: .viaStandardRefresh)
                await self.calModel.handleIncoming(titles: model.suggestedTitles, incomingDataType: .viaStandardRefresh)
                await self.calModel.handleIncoming(locations: model.suggestedLocations, incomingDataType: .viaStandardRefresh)
                //await self.budgetModel.handleIncoming(appSuiteBudgets: model.appSuiteBudgets, incomingDataType: .viaStandardRefresh)
                await self.budgetModel.handleIncoming(budgets: model.budgets, incomingDataType: .viaStandardRefresh)
                await self.budgetModel.handleIncoming(globalBudget: model.globalBudget, incomingDataType: .viaStandardRefresh)
                await self.plaidModel.handleIncoming(banks: model.plaidBanks, incomingDataType: .viaStandardRefresh)
                
                store.dashboardFilters = model.dashboardFilters
                for each in store.dashboardFilters {
                    await each.payMethod?.loadLogoFromCoreDataIfNeeded()
                }
                
                
                //await Countries.handleIncoming(currencies: model.countryCurrencies, incomingDataType: .viaStandardRefresh)
            }
            
            print("⏰ It took \(CFAbsoluteTimeGetCurrent() - start) seconds to fetch the accessorials")

        case .failure(let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("fetchAccessorials Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch the accessorials.")
            }
        }
    }
    
    
    
    
    
    
    // MARK: - Fetch From Server
    @MainActor
    func fetchMonthlyData(month: CBMonth, createNewStructs: Bool, refreshTechnique: RefreshTechnique) async {
        //print("-- \(#function) \(month.actualNum) \(month.year) -- \(Date())")
        LogManager.log()
        
        //let start = CFAbsoluteTimeGetCurrent()
        
        //try? await Task.sleep(for: .seconds(10))
                            
        let model = RequestModel(requestType: "fetch_monthly_data", model: month)
        typealias ResultResponse = Result<TransactionAndStartingAmountModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            if let model {
                month.amountString = model.budget.currencyWithDecimals()
                month.populatedId = model.populatedId
                
                if let plaidTrans = model.plaidTransactionsWithCount {
                    await self.plaidModel.handleIncoming(transactionsWithCount: plaidTrans, incomingDataType: .viaStandardRefresh)
                }
                
                if let balances = model.plaidBalances {
                    plaidModel.balances = balances
                }
                
                await self.calModel.handleIncomingData(for: month, using: model, createNewStructs: createNewStructs, refreshTechnique: refreshTechnique)
                month.hasBeenLoadedFromServer = true
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

    
    @MainActor
    //nonisolated
    func submitCachedTransactionsIfApplicable() async {
        let context = DataManager.shared.createContext()

        let tempTransactionIDs: [String] = await DataManager.shared.perform(context: context) {
            let entities = DataManager.shared.getMany(context: context, type: TempTransaction.self) ?? []
            return entities.compactMap(\.id)
        }

        guard !tempTransactionIDs.isEmpty else { return }

        for id in tempTransactionIDs {
            guard let trans = await CBTransaction.loadFromCoreData(id: id) else { continue }            
            guard trans.payMethod != nil else { continue }
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await self.calModel.saveTemp(trans: trans)
                }
            }
        }
    }

    
    @MainActor
    //nonisolated
    func submitCachedAccessorialsIfApplicable() async {
        let context = DataManager.shared.createContext()
        let pendingPredicate = NSPredicate(format: "isPending == %@", NSNumber(value: true))

        let pending = await DataManager.shared.perform(context: context) {
            let catIDs = (DataManager.shared.getMany(context: context, type: PersistentCategory.self, predicate: .single(pendingPredicate)) ?? []).compactMap(\.id)
            let groupIDs = (DataManager.shared.getMany(context: context, type: PersistentCategoryGroup.self, predicate: .single(pendingPredicate)) ?? []).compactMap(\.id)
            let keyIDs = (DataManager.shared.getMany(context: context, type: PersistentKeyword.self, predicate: .single(pendingPredicate)) ?? []).compactMap(\.id)
            let methIDs = (DataManager.shared.getMany(context: context, type: PersistentPaymentMethod.self, predicate: .single(pendingPredicate)) ?? []).compactMap(\.id)

            return (catIDs: catIDs, groupIDs: groupIDs, keyIDs: keyIDs, methIDs: methIDs)
        }

        await withTaskGroup(of: Void.self) { group in
            for id in pending.catIDs {
                if let category = await CBCategory.loadFromCoreData(id: id) {
                    group.addTask {
                        await self.catModel.submit(category)
                    }
                }
            }
        }
        
        await withTaskGroup(of: Void.self) { group in
            for id in pending.groupIDs {
                if let catGroup = await CBCategoryGroup.loadFromCoreData(id: id) {
                    group.addTask {
                        await self.catModel.submit(catGroup)
                    }
                }
            }
        }
        
        await withTaskGroup(of: Void.self) { group in
            for id in pending.keyIDs {
                if let keyword = await CBKeyword.loadFromCoreData(id: id) {
                    group.addTask {
                        await self.keyModel.submit(keyword)
                    }
                }
            }

        }
        
        await withTaskGroup(of: Void.self) { group in
            for id in pending.methIDs {
                if let method = await CBPaymentMethod.loadFromCoreData(id: id) {
                    group.addTask {
                        await self.payModel.submit(method)
                    }
                }
            }
        }

//        for id in pending.groupIDs {
//            if let group = await CBCategoryGroup.loadFromCoreData(id: id) {
//                await catModel.submit(group)
//            }
//        }
//
//        for id in pending.keyIDs {
//            if let keyword = await CBKeyword.loadFromCoreData(id: id) {
//                await keyModel.submit(keyword)
//            }
//        }
//
//        for id in pending.methIDs {
//            if let method = await CBPaymentMethod.loadFromCoreData(id: id) {
//                await payModel.submit(method)
//            }
//        }
    }

    
    
    
        
    @MainActor
    func getPlaidDebitSums() -> Decimal {
        let debits = payModel.paymentMethods
            .filter { $0.accountType == .checking }
            .filter { $0.isPermittedAndNotHidden }
            .filter { $0.accountHolderFilter() }
        
        let debitIDs = debits.map { $0.id }
        
        /// Code below works fine. 12/21/25
//        var cashAmount: Double = 0.0
//        let cashAccounts = debits.filter { $0.accountType == .cash }
//        for account in cashAccounts {
//            let amount: Double = calModel.calculateChecking(
//                for: calModel.sMonth,
//                using: account,
//                and: .giveMeEodAsOfToday
//            )
//            cashAmount += amount
//        }
        
        let plaidAmount = plaidModel.balances
            .filter { debitIDs.contains($0.payMethodID) }
            .map { $0.amount }
            .reduce(0.0, +)
        
        /// Removing the cash option because it makes weird calculations if you withdrawl money from a checking account and the checking balance has not yet updated from plaid. 12/21/25
        //return cashAmount + plaidAmount
        return plaidAmount
    }
    
    
    @MainActor
    func getPlaidCreditSums() -> Decimal {
        let creditIDs = payModel.paymentMethods
            .filter { $0.isCreditOrLoan }
            .filter { $0.isPermittedAndNotHidden }
            .filter { $0.accountHolderFilter() }
            .map { $0.id }
        
        return plaidModel.balances
            .filter { creditIDs.contains($0.payMethodID) }
            .map { $0.amount }
            .reduce(0.0, +)
    }
    
    
    @MainActor
    func getPlaidBalance(matching meth: CBPaymentMethod?) -> CBPlaidBalance? {
        plaidModel.balances
            .filter({ $0.payMethodID == meth?.id })
            .filter({ bal in
                if let meth = payModel.paymentMethods.filter({ $0.id == bal.payMethodID }).first {
                    return meth.isPermitted
                } else {
                    return false
                }
            })
            .filter({ bal in
                if let meth = payModel.paymentMethods.filter({ $0.id == bal.payMethodID }).first {
                    return !meth.isHidden
                } else {
                    return false
                }
            })
            .first
    }
    
    

    @MainActor
    func getPlaidBalancePrettyString(_ meth: CBPaymentMethod, withTime: Bool = true) -> String? {
        if calModel.sMonth.isNow {
            var result: String? {
                if meth.isUnified {
                    
                    let methIds = payModel.paymentMethods
                        .filter({ meth.isDebitOrUnified ? $0.isDebitOrCash : $0.isCreditOrLoan })
                        .filter({ $0.isPermitted && !$0.isHidden })
                        .map { $0.id }
                    
                    let bals = plaidModel.balances.filter({ methIds.contains($0.payMethodID) })
                    let times = bals.compactMap { $0.enteredDate }
                    let mostRecent = Date().timeSince(times.max())
                    
                    if meth.isDebitOrUnified {
                        return "\(self.getPlaidDebitSums().currencyWithDecimals()) (\(mostRecent))"
                    } else {
                        return "\(self.getPlaidCreditSums().currencyWithDecimals()) (\(mostRecent))"
                    }
                } else if meth.accountType == .cash {
                    return nil
                    //let bal = calModel.calculateChecking(for: calModel.sMonth, using: meth, and: .giveMeEodAsOfToday)
                    //let balStr = bal.currencyWithDecimals()
                    //return "\(balStr) (Manually)"
                    
                } else if let balance = self.getPlaidBalance(matching: meth), let curCode = meth.country?.currencyCode {
                    if withTime {
                        return "\(balance.amount.currencyWithDecimals(currencyCode: curCode)) (\(Date().timeSince(balance.enteredDate)))"
                    } else {
                        return "\(balance.amount.currencyWithDecimals(currencyCode: curCode))"
                    }
                                        
                } else if let balance = self.getPlaidBalance(matching: meth) {
                    if withTime {
                        return "\(balance.amount.currencyWithDecimals()) (\(Date().timeSince(balance.enteredDate)))"
                    } else {
                        return "\(balance.amount.currencyWithDecimals())"
                    }
                    
                }
//                else if let balance = plaidModel.balances.filter({ $0.payMethodID == meth.id }).first {
//                    return "\(balance.amount.currencyWithDecimals()) (\(Date().timeSince(balance.enteredDate)))"
//                    
//                }
                else {
                    return nil
                }
            }
            return result
        }
        return nil
    }
    
    
    
    
    
    
    @MainActor
    func fetchLogos(file: String = #file, line: Int = #line, function: String = #function) async {
        /// THE WAY LOGOS WORK.
        /// The base64 string representing the logo data is stored on the server.
        /// When the app launches, it will download the base64 string and store it in core data.
        /// When payment methods (for example) download, we fetch the base64 string from coredata and update the logo property in the payment method with `Data` created via the base64 string.
        /// When a logo needs to be shown via ``BusinessLogo``, the ``BusinessLogo`` view will run a task that checks if the UIImage created from the base64 data already exists in NSCache.
        /// If it does, it will just grab the UIImage and display it. If not, it will create the image, and cache it for future views to use.
        
        NSLog("\(file):\(line) : \(function)")
        LogManager.log()
        let start = CFAbsoluteTimeGetCurrent()

        /// Gather the logos from core data.
        let persistentLogos: [CBLogo] = await {
            let context = DataManager.shared.createContext()
            return await DataManager.shared.perform(context: context) {
                (DataManager.shared.getMany(context: context, type: PersistentLogo.self) ?? [])
                    .compactMap { entity in
                        guard entity.id != nil, entity.relatedID != nil else { return nil }
                        return CBLogo(entity: entity)
                    }
            }
        }()

        /// Fetch latest logo data from the server.
        let submitModel = LogoMaybeShouldUpdateModel(logos: persistentLogos)
        let model = RequestModel(requestType: "fetch_logos", model: submitModel)
        typealias ResultResponse = Result<[CBLogo]?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)

        switch await result {
        case .success(let response):
            LogManager.networkingSuccessful()
            
            guard let logos = response, !logos.isEmpty else {
                print("⏰ It took \(CFAbsoluteTimeGetCurrent() - start) seconds to fetch logos")
                return
            }
            
            /// Update core data with the latest logo info from the server.
            let context = DataManager.shared.createContext()
            await DataManager.shared.perform(context: context) {
                for logo in logos {
                    let pred1 = NSPredicate(format: "relatedID == %@", logo.relatedID)
                    let pred2 = NSPredicate(format: "relatedTypeID == %@", NSNumber(value: logo.relatedRecordType.id))
                    let comp = NSCompoundPredicate(andPredicateWithSubpredicates: [pred1, pred2])
                    
                    if let perLogo = DataManager.shared.getOne(
                        context: context,
                        type: PersistentLogo.self,
                        predicate: .compound(comp),
                        createIfNotFound: true
                    ) {
                        perLogo.photoData = logo.baseString.flatMap { Data(base64Encoded: $0) }
                        perLogo.id = logo.id
                        perLogo.relatedID = logo.relatedID
                        perLogo.relatedTypeID = Int64(logo.relatedRecordType.id)
                        perLogo.localUpdatedDate = logo.updatedDate
                        perLogo.serverUpdatedDate = logo.updatedDate
                    }
                }
                let _ = DataManager.shared.save(context: context)
            }

            
            //let paymentMethodTypeID = XrefModel.getItem(from: .logoTypes, byEnumID: .paymentMethod).id
            //let plaidBankTypeID = XrefModel.getItem(from: .logoTypes, byEnumID: .plaidBank).id
            //let avatarTypeID = XrefModel.getItem(from: .logoTypes, byEnumID: .avatar).id
            
            
            let paymentMethodTypeID = XrefLogoParentType.paymentMethod.id
            let plaidBankTypeID = XrefLogoParentType.plaidBank.id
            let avatarTypeID = XrefLogoParentType.avatar.id
            
            
            // 3) Write updates to Core Data on context queue.
//            let snapshots: [(relatedID: String, typeID: Int, data: Data?)] = logos.map {
//                ($0.relatedID, $0.relatedRecordType.id, $0.baseString.flatMap { Data(base64Encoded: $0) } )
//            }
            
            for logo in logos {
                var data: Data?
                
                if let base = logo.baseString {
                    data = Data(base64Encoded: base)
                }
                
                if let data = data {
                    ImageCache.shared.saveToCache(
                        parentTypeId: logo.relatedRecordType.id,
                        parentId: logo.relatedID,
                        id: logo.relatedID,
                        data: data
                    )
                } else {
                    ImageCache.shared.removeFromCache(
                        parentTypeId: logo.relatedRecordType.id,
                        parentId: logo.relatedID,
                        id: logo.relatedID,
                    )
                }
                
                if logo.relatedRecordType.id == paymentMethodTypeID {
                    if let meth = payModel.getPaymentMethod(by: logo.relatedID) {
                        meth.logo = data
                        changePaymentMethodLogoLocally(meth: meth, logoData: data)
                    }
                    
                } else if logo.relatedRecordType.id == plaidBankTypeID {
                    plaidModel.getBank(by: logo.relatedID)?.logo = data
                    
                } else if logo.relatedRecordType.id == avatarTypeID {
                    changeAvatarLocally(to: data, id: logo.relatedID)
                }
            }
            

//            for snap in snapshots {
//                if let data = snap.data {
//                    ImageCache.shared.saveToCache(
//                        parentTypeId: snap.typeID,
//                        parentId: snap.relatedID,
//                        id: snap.relatedID,
//                        data: data
//                    )
//                } else {
//                    ImageCache.shared.removeFromCache(
//                        parentTypeId: snap.typeID,
//                        parentId: snap.relatedID,
//                        id: snap.relatedID,
//                    )
//                }
//                
//                print("The logo type id is \(snap.typeID)")
//                
//                if snap.typeID == paymentMethodTypeID {
//                    let meth = payModel.getPaymentMethod(by: snap.relatedID)
//                    meth.logo = snap.data
//                    changePaymentMethodLogoLocally(meth: meth, logoData: snap.data)
//                    
//                } else if snap.typeID == plaidBankTypeID {
//                    plaidModel.getBank(by: snap.relatedID)?.logo = snap.data
//                    
//                } else if snap.typeID == avatarTypeID {
//                    changeAvatarLocally(to: snap.data, id: snap.relatedID)
//                }
//            }

            print("⏰ It took \(CFAbsoluteTimeGetCurrent() - start) seconds to fetch logos")

        case .failure(let error):
            switch error {
            case .taskCancelled:
                print("fetchLogos Server Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch logos.")
            }
        }
    }

    
//    @MainActor func setUserAvatars() {
//        for user in AppState.shared.accountUsers {
//            let pred1 = NSPredicate(format: "relatedID == %@", String(user.id))
//            let pred2 = NSPredicate(format: "relatedTypeID == %@", NSNumber(value: XrefModel.getItem(from: .logoTypes, byEnumID: .avatar).id))
//            let comp = NSCompoundPredicate(andPredicateWithSubpredicates: [pred1, pred2])
//    
//            /// Fetch the logo out of core data since the encoded strings can be heavy and I don't want to use Async Image for every logo.
//            let context = DataManager.shared.createContext()
//            if let logo = DataManager.shared.getOne(
//               context: context,
//               type: PersistentLogo.self,
//               predicate: .compound(comp),
//               createIfNotFound: false
//            ) {
//                user.avatar = logo.photoData
//                if user.id == AppState.shared.user!.id {
//                    AppState.shared.user?.avatar = logo.photoData
//                }
//            }
//        }
//    }
    
    
    @MainActor
    func setUserAvatars() async {
        let context = DataManager.shared.createContext()
        let avatarTypeID = XrefLogoParentType.avatar.id
        //let avatarTypeID = XrefModel.getItem(from: .logoTypes, byEnumID: .avatar).id
        let userIDs = Set(AppState.shared.accountUsers.map(\.id).map(String.init))

        let avatarMap: [Int: Data] = await DataManager.shared.perform(context: context) {
            let pred1 = NSPredicate(format: "relatedTypeID == %@", NSNumber(value: avatarTypeID))
            let pred2 = NSPredicate(format: "relatedID IN %@", Array(userIDs))
            let comp = NSCompoundPredicate(andPredicateWithSubpredicates: [pred1, pred2])

            let logos = DataManager.shared.getMany(context: context, type: PersistentLogo.self, predicate: .compound(comp)) ?? []

            var map: [Int: Data] = [:]
            for logo in logos {
                guard
                    let idString = logo.relatedID,
                    let id = Int(idString),
                    let data = logo.photoData
                else {
                    continue
                }
                map[id] = data
            }
            return map
        }

        for user in AppState.shared.accountUsers {
            user.avatar = avatarMap[user.id]
        }
        
        if let current = AppState.shared.user {
            current.avatar = avatarMap[current.id]
            Cody.shared.avatar = avatarMap[current.id]
        }
    }

    
    
    @MainActor
    func changePaymentMethodLogoLocally(meth: CBPaymentMethod, logoData: Data?) {
        print("-- \(#function)")
        /// Transactions
        calModel.justTransactions
            .filter { $0.payMethod?.id == meth.id }
            .forEach { $0.payMethod?.logo = logoData }
        
        /// Advanced search results.
        calModel.searchedTransactions
            .filter { $0.payMethod?.id == meth.id }
            .forEach { $0.payMethod?.logo = logoData }
        
        /// Temp transactions.
        calModel.tempTransactions
            .filter { $0.payMethod?.id == meth.id }
            .forEach { $0.payMethod?.logo = logoData }
        
        /// Repeating transactions.
        repModel.repTransactions
            .filter { $0.payMethod?.id == meth.id || $0.payMethodPayTo?.id == meth.id }
            .forEach { $0.payMethod?.logo = logoData }
        
        /// Plaid Transactions
        plaidModel.trans
            .filter { $0.payMethod?.id == meth.id }
            .forEach { $0.payMethod?.logo = logoData }
        
        /// Starting Amounts
        calModel.months
            .flatMap { $0.startingAmounts.filter { $0.payMethod?.id == meth.id } }
            .forEach { $0.payMethod?.logo = logoData }
    }
    
    
    @MainActor
    func changeAvatarLocally(to dataOrNil: Data?, id: String) {
        /// Logged in user.
        AppState.shared.user?.avatar = dataOrNil
        Cody.shared.avatar = dataOrNil
        
        /// Account users.
        if let user = AppState.shared.accountUsers.filter({ String($0.id) == id }).first {
            user.avatar = dataOrNil
        }
        
//        /// Payment methods.
//        for each in payModel.paymentMethods {
//            if String(each.enteredBy.id) == id { each.enteredBy.avatar = dataOrNil }
//            if String(each.updatedBy.id) == id { each.updatedBy.avatar = dataOrNil }
//            if let holderId = each.holderOne?.id, String(holderId) == id { each.holderOne?.avatar = dataOrNil }
//            if let holderId = each.holderTwo?.id, String(holderId) == id { each.holderTwo?.avatar = dataOrNil }
//            if let holderId = each.holderThree?.id, String(holderId) == id { each.holderThree?.avatar = dataOrNil }
//            if let holderId = each.holderFour?.id, String(holderId) == id { each.holderFour?.avatar = dataOrNil }
//        }
//        
//        /// Categories.
//        for each in catModel.categories {
//            if String(each.enteredBy.id) == id { each.enteredBy.avatar = dataOrNil }
//            if String(each.updatedBy.id) == id { each.updatedBy.avatar = dataOrNil }
//        }
//        
//        /// Repeating Transactions.
//        for each in repModel.repTransactions {
//            if String(each.enteredBy.id) == id { each.enteredBy.avatar = dataOrNil }
//            if String(each.updatedBy.id) == id { each.updatedBy.avatar = dataOrNil }
//        }
//        
//        /// Transactions.
//        for each in calModel.justTransactions {
//            if String(each.enteredBy.id) == id { each.enteredBy.avatar = dataOrNil }
//            if String(each.updatedBy.id) == id { each.updatedBy.avatar = dataOrNil }
//        }
//        
//        /// Temporary transactions.
//        for each in calModel.tempTransactions {
//            if String(each.enteredBy.id) == id { each.enteredBy.avatar = dataOrNil }
//            if String(each.updatedBy.id) == id { each.updatedBy.avatar = dataOrNil }
//        }
//        
//        /// Advanced search results.
//        for each in calModel.searchedTransactions {
//            if String(each.enteredBy.id) == id { each.enteredBy.avatar = dataOrNil }
//            if String(each.updatedBy.id) == id { each.updatedBy.avatar = dataOrNil }
//        }
//        
//        /// Keywords.
//        for each in keyModel.keywords {
//            if String(each.enteredBy.id) == id { each.enteredBy.avatar = dataOrNil }
//            if String(each.updatedBy.id) == id { each.updatedBy.avatar = dataOrNil }
//        }
//        
//        /// Plaid banks.
//        for each in plaidModel.banks {
//            if String(each.enteredBy.id) == id { each.enteredBy.avatar = dataOrNil }
//            if String(each.updatedBy.id) == id { each.updatedBy.avatar = dataOrNil }
//            
//            /// Plaid accounts.
//            for each in each.accounts {
//                if String(each.enteredBy.id) == id { each.enteredBy.avatar = dataOrNil }
//                if String(each.updatedBy.id) == id { each.updatedBy.avatar = dataOrNil }
//            }
//        }
                                                            
        
        
//        #warning("Need starting amonunts")
//        #warning("Need budgets")
        
//        /// Starting Amounts
//        calModel.months
//            .flatMap { $0.startingAmounts }
//            .forEach { amt in
//                if String(amt.enteredBy.id) == id { amt.enteredBy.avatar = dataOrNil }
//                if String(amt.updatedBy.id) == id { amt.updatedBy.avatar = dataOrNil }
//            }
//        
//        /// Budgets
//        calModel.months
//            .flatMap { $0.budgets }
//            .forEach { budget in
//                if String(budget.enteredBy.id) == id { budget.enteredBy.avatar = dataOrNil }
//                if String(budget.updatedBy.id) == id { budget.updatedBy.avatar = dataOrNil }
//            }
    }
        
    
    
    // MARK: - Initial Download
    func downloadInitial() {
        @Bindable var navManager = NavigationManager.shared
        /// Set navigation destination to current month
        #if os(iOS)
        navManager.selectedMonth = NavDest.getMonthFromInt(AppState.shared.todayMonth)
        #else
        navManager.selection = NavDest.getMonthFromInt(AppState.shared.todayMonth)
        #endif
                            
        refreshTask = Task {
            /// Populate all months with their days.
            await calModel.prepareMonths()
            #if os(iOS)
            if let selectedMonth = navManager.selectedMonth {
                /// Set the calendar model to use the current month (ignore starting amounts and calculations).
                await calModel.setSelectedMonthFromNavigation(navID: selectedMonth, calculateStartingAndEod: false, shouldLoadDashboard: true)
                /// Download everything, and populate the days in the respective months with transactions.
                await downloadEverything(setDefaultPayMethod: true, createNewStructs: true, refreshTechnique: .viaInitial)
            } else {
                print("Selected Month Not Set")
            }
            #else
            if let selectedMonth = navManager.selection {
                /// Set the calendar model to use the current month (ignore starting amounts and calculations).
                await calModel.setSelectedMonthFromNavigation(navID: selectedMonth, calculateStartingAndEod: false, shouldLoadDashboard: true)
                /// Download everything, and populate the days in the respective months with transactions.
                await downloadEverything(setDefaultPayMethod: true, createNewStructs: true, refreshTechnique: .viaInitial)
            }
            #endif
        }
    }
    
            
    @MainActor
    @discardableResult
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
    
    
    @MainActor
    @discardableResult
    func changeCountry() async -> Bool {
        print("-- \(#function)")
        LogManager.log()
        
        let user = AppState.shared.user!
        user.countryID = AppState.shared.country.id
        
        let model = RequestModel(requestType: "update_country", model: user)
        
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
    
    
//    @MainActor
//    func fetchExchangeRates() async {
//        print("-- \(#function)")
//        LogManager.log()
//        
//        let user = AppState.shared.user!
//        let model = RequestModel(requestType: "fetch_exchange_rates", model: user)
//        
//        typealias ResultResponse = Result<Array<CountryCurrencyDecodable>?, AppError>
//        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
//                    
//        switch await result {
//        case .success(let model):
//            if let model {
//                Countries.handleIncoming(currencies: model, incomingDataType: .viaStandardRefresh)
//            }
//            
//        case .failure(let error):
//            LogManager.error(error.localizedDescription)
//            AppState.shared.showAlert("There was a problem syncing the category. Will try again at a later time.")
//        }
//    }
    
    
//    @MainActor
//    @discardableResult
//    func fetchAppSuiteBudgets() async -> Bool {
//        print("-- \(#function)")
//        LogManager.log()
//        /// Use the reset month model since it contains the year property.
//        let reqModel = ResetMonthModel(month: 20, year: calModel.sYear)
//        let model = RequestModel(requestType: "fetch_app_suite_budgets", model: reqModel)
//        
//        typealias ResultResponse = Result<Array<CBBudgetItem>?, AppError>
//        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
//                    
//        switch await result {
//        case .success(let model):
//            if let model {
//                budgetModel.appSuiteBudgets = model
//            }
//            
//            LogManager.networkingSuccessful()
//            return true
//            
//        case .failure(let error):
//            LogManager.error(error.localizedDescription)
//            AppState.shared.showAlert("There was a problem syncing the category. Will try again at a later time.")
//            return false
//        }
//    }
    
    
    // MARK: - Logout
    @MainActor
    func logout() {
        print("-- \(#function)")
        /// Clearing all session data related to login and loading indicators.
        AuthState.shared.clearLoginState()
        
        calModel.months.forEach {
            $0.changeLoadingSpinners(toShowing: true, includeCalendar: true)
        }
        
        webSocketManager.stopListening()
        
        /// Cancel the long polling task.
//        if let _ = longPollTask {
//            longPollTask!.cancel()
//            longPollTask = nil
//        }
        
        /// Cancel the refresh task.
        if let _ = refreshTask {
            refreshTask!.cancel()
            refreshTask = nil
        }
        
        /// Clear all the downloaded data.
        store.removeAll()
        Cody.shared.reset()
        ImageCache.shared.empty()
        
        NavigationManager.shared.selectedMonth = nil
        NavigationManager.shared.selection = nil
        NavigationManager.shared.navPath.removeAll()
                        
        let context = DataManager.shared.createContext()
        context.perform {
            let _ = DataManager.shared.deleteAll(context: context, for: PersistentPaymentMethod.self)
            let _ = DataManager.shared.deleteAll(context: context, for: PersistentCategory.self)
            let _ = DataManager.shared.deleteAll(context: context, for: PersistentCategoryGroup.self)
            let _ = DataManager.shared.deleteAll(context: context, for: PersistentKeyword.self)
            let _ = DataManager.shared.deleteAll(context: context, for: PersistentToast.self)
            let _ = DataManager.shared.deleteAll(context: context, for: PersistentLogo.self)
            let _ = DataManager.shared.deleteAll(context: context, for: TempTransaction.self)
            let _ = DataManager.shared.save(context: context)
        }
    }
    
    
    @discardableResult
    func downloadFile(file: CBFile) async -> Data? {
        let fileModel = FileRequestModel(path: "budget_app.\(file.fileType.rawValue).\(file.uuid).\(file.fileType.ext)")
        let requestModel = RequestModel(requestType: "download_file", model: fileModel)
        let result = await NetworkManager().downloadFile(requestModel: requestModel)
        
        switch result {
        case .success(let data):
            if let data = data {                
                ImageCache.shared.saveToCache(
                    //parentTypeId: XrefModel.getItem(from: .fileTypes, byEnumID: .transaction).id,
                    parentTypeId: XrefFileType.transaction.id,
                    parentId: file.relatedID,
                    id: file.id,
                    data: data
                )
                
                return data
                
//                #if os(iOS)
//                    self.uiImage = UIImage(data: data)
//                #else
//                    self.nsImage = NSImage(data: data)
//                #endif
            }
            
            return nil
            
        case .failure(let error):
            switch error {
            case .taskCancelled:
                print("\(#function) Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem downloading the image.")
            }
            
            return nil
        }
    }
    
    
    @MainActor
    func itemizeReceipt(file: CBFile) {
        Task {
            if let data = await self.downloadFile(file: file),
               let uiImage = UIImage(data: data),
               let data = uiImage.jpegData(compressionQuality: 0) {
                let base = data.base64EncodedString()
                
                let manager = IntelligenceManager()
                
                typealias ResultResponse = Result<ReceiptResponse?, AppError>
                async let result: ResultResponse = await manager.request(base64Image: base)
                //await print(result)
                
                switch await result {
                case .success(let receipt):
                    if let receipt {
                        guard receipt.isReceipt else {
                            AppState.shared.showToast(title: "That photo was not a receipt.", subtitle: "Skipping itemization.")
                            print("Photo was not a receipt")
                            withAnimation {
                                file.isItemizing = false
                            }
                            return
                        }
                        
                        let lineItems = receipt.items
                            .flatMap { item in
                                //let itemEmoji = item.emoji.isEmpty ? "" : "\(item.emoji) "
                                //let parent = "\(itemEmoji)\(item.itemName) - \(item.cost)"
                                let parent = "\(item.itemName) - \(item.cost)"

                                let subLines = item.subLines.map { subLine in
                                    //let emoji = subLine.emoji.isEmpty ? "" : "\(subLine.emoji) "
                                    //return "\(emoji)\(subLine.itemName) - \(subLine.cost)"
                                    return "\(subLine.itemName) - \(subLine.cost)"
                                }

                                return [parent] + subLines
                            }
                            .joined(separator: "\n")
                        
                        
                        if let trans = calModel.getTransaction(by: file.relatedID) {
                            if trans.notes == "" {
                                trans.notes = AttributedString("Items:\n\(lineItems)")
                            } else {
                                trans.notes += AttributedString("\n\nItems:\n\(lineItems)")
                            }
                            
                            if calProps.transEditID == nil {
                                await calModel.saveTransaction(id: trans.id)
                            }
                        } else {
                            print("Could not find trans.")
                        }
                    }
                    
                    
                    
                case .failure(let error):
                    switch error {
                    case .taskCancelled:
                        print("\(#function) Task Cancelled")
                    default:
                        LogManager.error(error.localizedDescription)
                        AppState.shared.showAlert("There was a problem trying to itemize the receipt.")
                    }
                }
                
                withAnimation {
                    file.isItemizing = false
                }
                //props.itemizingFile = nil
            }
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
