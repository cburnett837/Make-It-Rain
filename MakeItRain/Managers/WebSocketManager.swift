//
//  WebSocketManager.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/5/26.
//

import Foundation
import SwiftUI


@Observable
class WebSocketManager {
    @ObservationIgnored private let store: AppStore
    //var funcModel: FuncModel
    var calModel: CalendarModel
    var payModel: PayMethodModel
    var catModel: CategoryModel
    var keyModel: KeywordModel
    var repModel: RepeatingTransactionModel
    var plaidModel: PlaidModel
    
    var socketTask: URLSessionWebSocketTask?
    var listeningTask: Task<Void, Never>?
    var pingTask: Task<Void, Never>?
    var lastPong: Date?        
    var funcModelRefreshFunction: (() async -> Void)?
    
    init(
        store: AppStore,
        calModel: CalendarModel,
        payModel: PayMethodModel,
        catModel: CategoryModel,
        keyModel: KeywordModel,
        repModel: RepeatingTransactionModel,
        plaidModel: PlaidModel
    ) {
        self.store = store
        self.calModel = calModel
        self.payModel = payModel
        self.catModel = catModel
        self.keyModel = keyModel
        self.repModel = repModel
        self.plaidModel = plaidModel
    }
    
    
    func connect() {
        if listeningTask == nil || listeningTask!.isCancelled {
            startListening()
            ping()
        }
    }
    
    
    
    func ping() {
        guard let ws = socketTask else { return }

        pingTask = Task {
            while !Task.isCancelled {
                // Sleep first so we don't ping immediately
                try? await Task.sleep(for: .seconds(300))
                
                if Task.isCancelled { break }
                guard socketTask != nil else { break }
                
                // sendPing uses callback, so bridge to async
                let ok = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
                    print("Sending Ping...")
                    ws.sendPing { error in
                        cont.resume(returning: error == nil)
                    }
                }
                
                if ok {
                    lastPong = Date() // URLSession doesn't expose pong; treat ping-ack as liveness
                } else {
                    stopListening()
                    break
                }
                
                // Optional: if you want a timeout policy based on lastPongAt
                if let last = lastPong, Date().timeIntervalSince(last) > 60 {
                    stopListening()
                    break
                }
            }
        }
    }
    
    
    func stopListening() {
        print("-- \(#function)")
        let reason = "Connection closed by client".data(using: .utf8)
        socketTask?.cancel(with: .normalClosure, reason: reason)
        socketTask = nil
        
        listeningTask?.cancel()
        listeningTask = nil
        
        pingTask?.cancel()
        pingTask = nil
    }
    
    
    func alertAboutTimeout() {
        AppState.shared.longPollFailed = true

        stopListening()

        let alertConfig = AlertConfig(
            title: "There was a problem subscribing to multi-device updates.",
            symbol: .init(name: "ipad.and.iphone.slash", color: .red),
            primaryButton:
                AlertConfig.AlertButton(config: .init(text: "Retry", role: .primary, function: {
                    Task {
                        AppState.shared.longPollFailed = false
                        await self.funcModelRefreshFunction?()
                        //await self.downloadEverything(setDefaultPayMethod: false, createNewStructs: false, refreshTechnique: .viaLongPoll)
                    }
                }))
        )
        AppState.shared.showAlert(config: alertConfig)
    }
    
    
    func startListening(ticker: Int = 4) {
        print("-- \(#function)")
        
        if ticker == 0 {
            alertAboutTimeout()
            return
        }
        
        guard listeningTask == nil else {
            print("Listening task already exists. Bailing")
            return
        }
        if let task = listeningTask {
            if !task.isCancelled {
                print("Listening task already exists and is not cancelled. Bailing")
                return
            }
        }
        
        listeningTask = Task {
            var request = URLRequest(url: URL(string: AppState.shared.devMode ? Keys.devBaseWebsocketURL : Keys.prodBaseWebsocketURL)!)
            request.setValue(Keys.authPhrase, forHTTPHeaderField: "Auth-Phrase")
            request.setValue(Keys.authID, forHTTPHeaderField: "Auth-ID")
            request.setValue(AppState.shared.apiKey, forHTTPHeaderField: "Api-Key")
            
            let ws = URLSession.shared.webSocketTask(with: request)
            socketTask = ws
            ws.resume()
            
            do {
                let auth = try JSONEncoder().encode(LongPollSubscribeModel(lastReturnTime: 0))
                try await ws.send(.data(auth))
            } catch {
                print("Auth send failed:", error)
                try? await Task.sleep(for: .seconds(5))
                stopListening()
                ping()
                startListening(ticker: ticker - 1)
            }
            
            do {
                while !Task.isCancelled {
                    let result = try await ws.receive()
                    //print("recv:", result)
                    
                    switch result {
                    case .data(let data):
                        
                        let serverText = String(data: data, encoding: .utf8) ?? ""
                        //print(serverText)
                        //print("GOT SERVER RESPONSE")
                        if AppState.shared.debugPrint { print(serverText) }
                        
                        #if targetEnvironment(simulator)
                        let decodedData = try! JSONDecoder().decode(LongPollModel.self, from: data)
                        #else
                        let decodedData = try! JSONDecoder().decode(LongPollModel.self, from: data)
                        #endif
                        
                        await self.handleLongPollResult(model: decodedData)
                    
                    case .string(let s):
                        let data: Data = Data(s.utf8)
                        #if targetEnvironment(simulator)
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let decodedData = try! decoder.decode(LongPollModel.self, from: data)
                        #else
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let decodedData = try! decoder.decode(LongPollModel.self, from: data)
                        #endif

                        await self.handleLongPollResult(model: decodedData)
                        
                    default:
                        throw NSError(domain: "UnknownMessage", code: 0)
                    }
                }
//            } catch is CancellationError {
//                if Task.isCancelled {
//                    stopListening()
//                } else {
//                    try? await Task.sleep(for: .seconds(5))
//                    startListening(ticker: ticker - 1)
//                }
                
            } catch {
                if Task.isCancelled {
                    stopListening()
                    
                } else if error.isExpectedWebSocketClose {
                    
                    try? await Task.sleep(for: .seconds(5))
                    stopListening()
                    ping()
                    startListening(ticker: ticker - 1)
                                        
                } else {
                    print("Receive loop error:", error)
                }
            }
        }
    }
    
    
    @MainActor
    func handleLongPollResult(model: LongPollModel) async {
        if model.transactions != nil
        || model.startingAmounts != nil
        || model.repeatingTransactions != nil
        || model.payMethods != nil
        || model.categories != nil
        || model.categoryGroups != nil
        || model.keywords != nil
        || model.budgets != nil
        || model.openRecords != nil
        || model.plaidBanks != nil
        || model.plaidAccounts != nil
        || model.plaidTransactionsWithCount != nil
        || model.plaidBalances != nil
        || model.logos != nil
        || model.settings != nil
        //|| model.receipts != nil
        {
            
            #warning("This all needs to be fixed in regards to coredata. Right now, each update of the cache or delete from the cache uses its own context, and saves after each operation. If I used a single background context, when deleting a payment method via the long poll, the save operation will fail. It is recommended to perform all operations, and then call save at the end. But this will require some work to implement. 11/6/25")
            //try? await Task.sleep(nanoseconds: UInt64(5 * Double(NSEC_PER_SEC)))
            
            if let transactions = model.transactions {
                await self.handleLongPollTransactions(transactions)
            }

            if let startingAmounts = model.startingAmounts, !startingAmounts.isEmpty {
                self.handleLongPollStartingAmounts(startingAmounts)
            }
            
            if let repeatingTransactions = model.repeatingTransactions, !repeatingTransactions.isEmpty {
                await repModel.handleIncoming(reps: repeatingTransactions, incomingDataType: .viaLongPoll)
            }
            
            if let payMethods = model.payMethods, !payMethods.isEmpty {
                await payModel.handleIncoming(meths: payMethods, calModel: calModel, repModel: repModel, incomingDataType: .viaLongPoll)
                //await payModel.handleLongPoll(payMethods, calModel: calModel, repModel: repModel)
                payModel.prepareStartingAmounts(for: calModel.sMonth, calModel: calModel)
            }
            
            if let categories = model.categories, !categories.isEmpty {
                await catModel.handleIncoming(cats: categories, repModel: repModel, incomingDataType: .viaLongPoll)
            }
            
            if let categoryGroups = model.categoryGroups, !categoryGroups.isEmpty {
                await catModel.handleIncoming(groups: categoryGroups, incomingDataType: .viaLongPoll)
            }
            
            if let keywords = model.keywords, !keywords.isEmpty {
                //await keyModel.handleLongPoll(keywords)
                await keyModel.handleIncoming(keys: keywords, incomingDataType: .viaLongPoll)
            }
            
            if let budgets = model.budgets, !budgets.isEmpty {
                self.handleLongPollBudgets(budgets)
            }
            
            if let openRecords = model.openRecords, !openRecords.isEmpty {
                await self.handleLongPollOpenRecords(openRecords)
            }
            
            if let logos = model.logos, !logos.isEmpty {
                await self.handleLongPollLogos(logos)
            }
            
            if let settings = model.settings {
                self.handleLongPollSettings(settings)
            }
            
            if let plaidBanks = model.plaidBanks, !plaidBanks.isEmpty {
                await plaidModel.handleIncoming(banks: plaidBanks, incomingDataType: .viaLongPoll)
            }
            
            if let plaidAccounts = model.plaidAccounts, !plaidAccounts.isEmpty {
                await plaidModel.handleLongPollPlaidAccounts(plaidAccounts)
            }
            
            if let plaidBalances = model.plaidBalances, !plaidBalances.isEmpty {
                plaidModel.handleLongPollPlaidBalances(plaidBalances)
            }
            
            if let plaidTransactionsWithCount = model.plaidTransactionsWithCount {
                await plaidModel.handleIncoming(transactionsWithCount: plaidTransactionsWithCount, incomingDataType: .viaLongPoll)
            }
        }
    }
            
    
    @MainActor
    private func handleLongPollTransactions(_ transactions: Array<CBTransaction>) async {
        print("-- \(#function)")
        await calModel.handleTransactions(transactions, refreshTechnique: .viaLongPoll)
        
        let months = transactions
            .filter { $0.date != nil }
            .compactMap { $0.dateComponents?.month }
            .uniqued()
        
        months.forEach { month in
            //let montObj = calModel.months.filter{ $0.num == month }.first!
            let montObj = calModel.months.get(byNum: month)!
            let _ = calModel.calculateTotal(for: montObj)
        }
        
        DataChangeTriggers.shared.viewDidChange(.calendar)
    }
    
    
    @MainActor
    private func handleLongPollStartingAmounts(_ startingAmounts: Array<CBStartingAmount>) {
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
                        
            if let targetMonth = calModel.months.get(by: (month, year)) {
                let targetAmount = targetMonth.startingAmounts.filter { $0.payMethod.id == startingAmount.payMethod.id }.first
                if let targetAmount {
                    
                    if !startingAmount.active {
                        targetAmount.amountString = ""
                    } else {
                        targetAmount.setFromAnotherInstance(startingAmount: startingAmount)
                    }
                } else {
                    payModel.prepareStartingAmounts(for: targetMonth, calModel: calModel)
                    //calModel.prepareStartingAmount(for: startingAmount.payMethod)
                    let targetAmount = targetMonth.startingAmounts.filter { $0.payMethod.id == startingAmount.payMethod.id }.first
                    if let targetAmount {
                        targetAmount.setFromAnotherInstance(startingAmount: startingAmount)
                    }
                    
                }
            }
            
            //let montObj = calModel.months.filter { $0.num == month }.first!
            let montObj = calModel.months.get(byNum: month)!
            let _ = calModel.calculateTotal(for: montObj)
        }
    }
    
    
    @MainActor
    private func handleLongPollBudgets(_ budgets: Array<CBBudget>) {
        print("-- \(#function)")
        for budget in budgets {
            if budget.appSuiteKey == nil {
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
            } else {
                print("Budget \(budget.id) incomign")
                if let index = calModel.appSuiteBudgets.firstIndex(where: { $0.id == budget.id }) {
                    calModel.appSuiteBudgets[index].setFromAnotherInstance(budget: budget)
                } else {
                    calModel.appSuiteBudgets.append(budget)
                }
            }
        }
    }
    
    
    @MainActor
    private func handleLongPollLogos(_ logos: [CBLogo]) async {
        //return
        print("-- \(#function)")
        guard !logos.isEmpty else { return }

        // Snapshot values so no Core Data objects or non-sendable refs cross boundaries.
        struct IncomingLogo: Sendable {
            let id: String
            let relatedID: String
            let typeID: Int
            let updatedDate: Date
            let data: Data?
        }

        let incoming: [IncomingLogo] = logos.map {
            IncomingLogo(
                id: $0.id,
                relatedID: $0.relatedID,
                typeID: $0.relatedRecordType.id,
                updatedDate: $0.updatedDate,
                data: $0.baseString.flatMap { Data(base64Encoded: $0) }
            )
        }

        // Persist on Core Data queue only.
        let context = DataManager.shared.createContext()
        await DataManager.shared.perform(context: context) {
            for logo in incoming {
                if let perLogo = DataManager.shared.getOne(
                    context: context,
                    type: PersistentLogo.self,
                    predicate: .byId(.string(logo.id)),
                    createIfNotFound: false
                ) {
                    perLogo.photoData = logo.data
                    perLogo.serverUpdatedDate = logo.updatedDate
                    perLogo.localUpdatedDate = logo.updatedDate
                }
            }
            let _ = DataManager.shared.save(context: context)
        }

        // Apply UI/model updates on MainActor.
        let paymentMethodTypeID = XrefModel.getItem(from: .logoTypes, byEnumID: .paymentMethod).id
        let plaidBankTypeID = XrefModel.getItem(from: .logoTypes, byEnumID: .plaidBank).id
        let avatarTypeID = XrefModel.getItem(from: .logoTypes, byEnumID: .avatar).id

        for logo in incoming {
            if let logoData = logo.data {
                /// Don't use the logo id in the save because the logo gets cached with the relatedID as the ID in ``ImageCache``.
                /// This is because the CBLogo is not available in the parent that contains the logo... why specifically, I don't know.
                ImageCache.shared.saveToCache(
                    parentTypeId: logo.typeID,
                    parentId: logo.relatedID,
                    id: logo.relatedID,
                    data: logoData
                )
            } else {
                //print("removing from cache \(logo.typeID), \(logo.relatedID)")
                ImageCache.shared.removeFromCache(
                    parentTypeId: logo.typeID,
                    parentId: logo.relatedID,
                    id: logo.relatedID,
                )
            }
            
            if logo.typeID == paymentMethodTypeID {
                if let meth = payModel.getPaymentMethod(by: logo.relatedID) {
                    meth.logo = logo.data
                    self.changePaymentMethodLogoLocally(meth: meth, logoData: logo.data)
                }                
                
            } else if logo.typeID == plaidBankTypeID {
                plaidModel.getBank(by: logo.relatedID)?.logo = logo.data
                
            } else if logo.typeID == avatarTypeID {
                self.changeAvatarLocally(to: logo.data, id: logo.relatedID)
            }
       }
    }

    
    @MainActor
    private func handleLongPollSettings(_ settings: AppSettings) {
        AppSettings.shared.setFromAnotherInstance(setting: settings)
    }
      
    
    @MainActor
    private func handleLongPollOpenRecords(_ openRecords: Array<CBOpenOrClosedRecord>) async {
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
            .flatMap { $0.startingAmounts.filter { $0.payMethod.id == meth.id } }
            .forEach { $0.payMethod.logo = logoData }
    }
    
    
    @MainActor
    func changeAvatarLocally(to dataOrNil: Data?, id: String) {
        /// Logged in user.
        AppState.shared.user?.avatar = dataOrNil
        
        /// Account users.
        if let user = AppState.shared.accountUsers.filter({ String($0.id) == id }).first {
            user.avatar = dataOrNil
        }
    }
}
