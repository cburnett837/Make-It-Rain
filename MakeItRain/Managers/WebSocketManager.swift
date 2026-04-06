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
    var socketTask: URLSessionWebSocketTask?
    var listeningTask: Task<Void, Never>?
    var pingTask: Task<Void, Never>?
    var lastPong: Date?
    
    //var funcModel: FuncModel
    var calModel: CalendarModel
    var payModel: PayMethodModel
    var catModel: CategoryModel
    var keyModel: KeywordModel
    var repModel: RepeatingTransactionModel
    var plaidModel: PlaidModel
    var funcModelRefreshFunction: (() async -> Void)?
    
    init(
        calModel: CalendarModel,
        payModel: PayMethodModel,
        catModel: CategoryModel,
        keyModel: KeywordModel,
        repModel: RepeatingTransactionModel,
        plaidModel: PlaidModel
    ) {
        //self.funcModel = funcModel
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
                    print("recv:", result)
                    
                    switch result {
                    case .data(let data):
                        
                        let serverText = String(data: data, encoding: .utf8) ?? ""
                        print(serverText)
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
                        let decodedData = try! JSONDecoder().decode(LongPollModel.self, from: data)
                        #else
                        let decodedData = try! JSONDecoder().decode(LongPollModel.self, from: data)
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
        || model.fitTransactions != nil
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
//                        if AppState.shared.user?.id == 1 {
//                            if let fitTransactions = model.fitTransactions { self.handleLongPollFitTransactions(fitTransactions) }
//                        }
            if let startingAmounts = model.startingAmounts {
                self.handleLongPollStartingAmounts(startingAmounts)
            }
            if let repeatingTransactions = model.repeatingTransactions, !repeatingTransactions.isEmpty {
                await repModel.handleIncoming(reps: repeatingTransactions, incomingDataType: .viaLongPoll)
            }
            if let payMethods = model.payMethods {
                await payModel.handleLongPoll(payMethods, calModel: calModel, repModel: repModel)
                payModel.prepareStartingAmounts(for: calModel.sMonth, calModel: calModel)
            }
            if let categories = model.categories, !categories.isEmpty {
                await catModel.handleIncoming(cats: categories, calModel: calModel, keyModel: keyModel, repModel: repModel, incomingDataType: .viaLongPoll)
            }
            if let categoryGroups = model.categoryGroups, !categoryGroups.isEmpty {
                await catModel.handleIncoming(groups: categoryGroups, incomingDataType: .viaLongPoll)
            }
            if let keywords = model.keywords, !keywords.isEmpty {
                //await keyModel.handleLongPoll(keywords)
                await keyModel.handleIncoming(keys: keywords, incomingDataType: .viaLongPoll)
            }
            if let budgets = model.budgets {
                self.handleLongPollBudgets(budgets)
            }
            if let openRecords = model.openRecords, !openRecords.isEmpty {
                await self.handleLongPollOpenRecords(openRecords)
            }
            if let logos = model.logos {
                await self.handleLongPollLogos(logos)
            }
            if let settings = model.settings {
                self.handleLongPollSettings(settings)
            }
            if let plaidBanks = model.plaidBanks, !plaidBanks.isEmpty {
                await plaidModel.handleIncoming(banks: plaidBanks, incomingDataType: .viaLongPoll)
            }
            if let plaidAccounts = model.plaidAccounts {
                await plaidModel.handleLongPollPlaidAccounts(plaidAccounts)
            }
            if let plaidBalances = model.plaidBalances, !plaidBalances.isEmpty {
                plaidModel.handleLongPollPlaidBalances(plaidBalances)
            }
            if let plaidTransactionsWithCount = model.plaidTransactionsWithCount {
                await plaidModel.handleIncoming(transactionsWithCount: plaidTransactionsWithCount, incomingDataType: .viaLongPoll)
            }
            //if let receipts = model.receipts { self.handleLongPollReceipts(receipts) }
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
    
    
//    @MainActor
//    private func handleLongPollRepeatingTransactions(_ repeatingTransactions: Array<CBRepeatingTransaction>) async {
//        print("-- \(#function)")
//        for transaction in repeatingTransactions {
//            if repModel.doesExist(transaction) {
//                if !transaction.active {
//                    repModel.delete(transaction, andSubmit: false)
//                } else {
//                    if let index = repModel.getIndex(for: transaction) {
//                        repModel.repTransactions[index].setFromAnotherInstance(repTransaction: transaction)
//                        repModel.repTransactions[index].deepCopy?.setFromAnotherInstance(repTransaction: transaction)
//                    }
//                }
//            } else {
//                if transaction.active {
//                    withAnimation { repModel.upsert(transaction) }
//                }
//            }
//        }
//    }
    
    
//    @MainActor private func handleLongPollPaymentMethods(_ payMethods: Array<CBPaymentMethod>) async {
//        print("-- \(#function)")
//
//        //let ogListOrders = payModel.paymentMethods.map { $0.listOrder ?? 0 }.sorted()
//        //var newListOrders: [Int] = []
//
//        let context = DataManager.shared.createContext()
//        for payMethod in payMethods {
//            //newListOrders.append(payMethod.listOrder ?? 0)
//            if payModel.doesExist(payMethod) {
//                if !payMethod.active {
//                    payModel.delete(payMethod, andSubmit: false, calModel: calModel)
//                    continue
//                } else {
//                    if let index = payModel.getIndex(for: payMethod) {
//
//
////                        if let logoData = payMethod.logo {
////                            let paymentMethodTypeID = XrefModel.getItem(from: .logoTypes, byEnumID: .paymentMethod).id
////                            await ImageCache.shared.saveToCache(
////                                parentTypeId: paymentMethodTypeID,
////                                parentId: payMethod.id,
////                                id: logo.id,
////                                data: logoData
////                            )
////                        }
//
//
//
//                        payModel.paymentMethods[index].setFromAnotherInstance(payMethod: payMethod)
//                        payModel.paymentMethods[index].deepCopy?.setFromAnotherInstance(payMethod: payMethod)
//                    }
//                }
//            } else {
//                if payMethod.active {
//                    withAnimation { payModel.upsert(payMethod) }
//                }
//            }
//
//            if payMethod.isPermitted {
//                let _ = await payModel.updateCache(for: payMethod)
//            } else {
//                DataManager.shared.delete(context: context, type: PersistentPaymentMethod.self, predicate: .byId(.string(payMethod.id)))
//            }
//            //print("SaveResult: \(saveResult)")
//
//            calModel.justTransactions
//                .filter { $0.payMethod?.id == payMethod.id }
//                .forEach { $0.payMethod?.setFromAnotherInstance(payMethod: payMethod) }
//
//            calModel.months
//                .flatMap { $0.startingAmounts.compactMap { $0.payMethod } }
//                .filter { $0.id == payMethod.id }
//                .forEach { $0.setFromAnotherInstance(payMethod: payMethod) }
//
//            repModel.repTransactions
//                .filter { $0.payMethod?.id == payMethod.id }
//                .forEach { $0.payMethod?.setFromAnotherInstance(payMethod: payMethod) }
//        }
//
//        payModel.determineIfUserIsRequiredToAddPaymentMethod()
//
//        self.prepareStartingAmounts(for: calModel.sMonth)
//
////        if newListOrders != ogListOrders {
////            DataChangeTriggers.shared.viewDidChange(.paymentMethodListOrders)
////        }
//
//    }
    
    
//    @MainActor private func handleLongPollCategories(_ categories: Array<CBCategory>) async {
//        print("-- \(#function)")
//        for category in categories {
//            if catModel.doesExist(category) {
//                if !category.active {
//                    catModel.delete(category, andSubmit: false, calModel: calModel, keyModel: keyModel)
//                    continue
//                } else {
//                    if let index = catModel.getIndex(for: category) {
//                        catModel.categories[index].setFromAnotherInstance(category: category)
//                        catModel.categories[index].deepCopy?.setFromAnotherInstance(category: category)
//                    }
//                }
//            } else {
//                if category.active {
//                    withAnimation { catModel.upsert(category) }
//                }
//            }
//            let _ = await catModel.updateCache(
//                for: category,
//                createIfNotFound: false,
//                findById: category.id,
//                action: .edit,
//                isPending: false
//            )
//            //print("SaveResult: \(saveResult)")
//
//            calModel.justTransactions.filter { $0.category?.id == category.id }.forEach { $0.category = category }
//            repModel.repTransactions.filter { $0.category?.id == category.id }.forEach { $0.category = category }
//        }
//
//        //let categorySortMode = SortMode.fromString(UserDefaults.standard.string(forKey: "categorySortMode") ?? "")
//
//        withAnimation {
//            catModel.categories.sort(by: Helpers.categorySorter())
//        }
//    }
    
//
//    @MainActor private func handleLongPollCategoryGroups(_ groups: Array<CBCategoryGroup>) async {
//        print("-- \(#function)")
//        for group in groups {
//            if catModel.doesExist(group) {
//                if !group.active {
//                    catModel.delete(group, andSubmit: false)
//                    continue
//                } else {
//                    if let index = catModel.getIndex(for: group) {
//                        catModel.categoryGroups[index].setFromAnotherInstance(group: group)
//                        catModel.categoryGroups[index].deepCopy?.setFromAnotherInstance(group: group)
//                    }
//                }
//            } else {
//                if group.active {
//                    withAnimation { catModel.upsert(group) }
//                }
//            }
//
//            let _ = await catModel.updateCache(
//                for: group,
//                createIfNotFound: false,
//                findById: group.id,
//                action: .edit,
//                isPending: false
//            )
//        }
//    }
//
//
//    @MainActor private func handleLongPollKeywords(_ keywords: Array<CBKeyword>) async {
//        print("-- \(#function)")
//        for keyword in keywords {
//            if keyModel.doesExist(keyword) {
//                if !keyword.active {
//                    keyModel.delete(keyword, andSubmit: false)
//                    continue
//                } else {
//                    if let index = keyModel.getIndex(for: keyword){
//                        keyModel.keywords[index].setFromAnotherInstance(keyword: keyword)
//                        keyModel.keywords[index].deepCopy?.setFromAnotherInstance(keyword: keyword)
//                    }
//                }
//            } else {
//                if keyword.active {
//                    withAnimation { keyModel.upsert(keyword) }
//                }
//            }
//            let _ = await keyModel.updateCoreData(for: CBKeyword.Snapshot(keyword))
//            //print("SaveResult: \(saveResult)")
//        }
//    }
    
    
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
    
    
    
    
//    @MainActor
//    private func handleLongPollLogos(_ logos: Array<CBLogo>) {
//        print("-- \(#function)")
//        let context = DataManager.shared.createContext()
//
//        for logo in logos {
//            print("incoming base64 for logo \(String(describing: logo.baseString))")
//
//            /// Try and decode the data, if not, wipe out the logos.
//            var logoData: Data?
//            if let baseString = logo.baseString {
//                logoData = Data(base64Encoded: baseString)
//            }
//
//            if let perLogo = DataManager.shared.getOne(context: context, type: PersistentLogo.self, predicate: .byId(.string(logo.id)), createIfNotFound: false) {
//                perLogo.photoData = logoData
//                perLogo.serverUpdatedDate = logo.updatedDate
//                perLogo.localUpdatedDate = logo.updatedDate
//            }
//
//            if logo.relatedRecordType.enumID == .paymentMethod {
//                let meth = payModel.getPaymentMethod(by: logo.relatedID)
//                meth.logo = logoData
//
//                changePaymentMethodLogoLocally(meth: meth, logoData: logoData)
//
//                #warning("Need starting amounts")
//            }
//
//            if logo.relatedRecordType.enumID == .plaidBank {
//                if let bank = plaidModel.getBank(by: logo.relatedID) {
//                    bank.logo = logoData
//                }
//            }
//
//            if logo.relatedRecordType.enumID == .avatar {
//                let relatedID = logo.relatedID
//                changeAvatarLocally(to: logoData, id: relatedID)
//            }
//        }
//
//        let _ = DataManager.shared.save(context: context)
//    }
//
    
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
                let meth = payModel.getPaymentMethod(by: logo.relatedID)
                meth.logo = logo.data
                self.changePaymentMethodLogoLocally(meth: meth, logoData: logo.data)
                
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
    
    
//    @MainActor
//    private func handleLongPollPlaidBanks(_ banks: Array<CBPlaidBank>) async {
//        print("-- \(#function)")
//        for bank in banks {
//            if plaidModel.doesExist(bank) {
//                if !bank.active {
//                    plaidModel.delete(bank, andSubmit: false)
//                    continue
//                } else {
//                    if let index = plaidModel.getIndex(for: bank) {
//                        plaidModel.banks[index].setFromAnotherInstance(bank: bank)
//                        plaidModel.banks[index].deepCopy?.setFromAnotherInstance(bank: bank)
//                    }
//                }
//            } else {
//                if bank.active {
//                    plaidModel.upsert(bank)
//                }
//            }
//        }
//    }
//    
//    
//    @MainActor
//    private func handleLongPollPlaidAccounts(_ accounts: Array<CBPlaidAccount>) async {
//        print("-- \(#function)")
//        var eventIdsThatGotChanged: Array<String> = []
//        
//        for act in accounts {
//            if let index = plaidModel.banks.firstIndex(where: { $0.id == act.bankID }) {
//                let bank = plaidModel.banks[index]
//                
//                eventIdsThatGotChanged.append(bank.id)
//                
//                if bank.doesExist(act) {
//                    if !act.active {
//                        bank.deleteAccount(id: act.id)
//                        continue
//                    } else {
//                        if let index = bank.getIndex(for: act) {
//                            bank.accounts[index].setFromAnotherInstance(account: act)
//                            bank.accounts[index].deepCopy?.setFromAnotherInstance(account: act)
//                        }
//                    }
//                } else {
//                    if act.active {
//                        bank.upsert(act)
//                    }
//                }
//            }
//        }
//    }
//    
//        
//    @MainActor
//    private func handleLongPollPlaidTransactions(_ transactionsWithCount: CBPlaidTransactionListWithCount) {
//        print("-- \(#function)")
//        plaidModel.totalTransCount = transactionsWithCount.count
//        if let safeTrans = transactionsWithCount.trans {
//            for trans in safeTrans {
//                if plaidModel.doesExist(trans) {
//                    if !trans.active {
//                        plaidModel.delete(trans)
//                        continue
//                    } else {
//                        if trans.isAcknowledged {
//                            plaidModel.delete(trans)
//                            continue
//                        } else {
//                            if let index = plaidModel.getIndex(for: trans) {
//                                plaidModel.trans[index].setFromAnotherInstance(trans: trans)
//                            }
//                        }
//                    }
//                } else {
//                    if !trans.isAcknowledged {
//                        plaidModel.upsert(trans)
//                    }
//                }
//            }
//        }
//    }
//    
//    
//    @MainActor
//    private func handleLongPollPlaidBalances(_ balances: Array<CBPlaidBalance>) {
//        print("-- \(#function)")
//        for bal in balances {
//            if plaidModel.doesExist(bal) {
//                if !bal.active {
//                    plaidModel.delete(bal)
//                    continue
//                } else {
//                    if let index = plaidModel.getIndex(for: bal) {
//                        plaidModel.balances[index].setFromAnotherInstance(bal: bal)
//                    }
//                }
//            } else {
//                plaidModel.upsert(bal)
//            }
//        }
//    }
    
    
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
}


