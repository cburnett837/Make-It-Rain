//
//  TempTransactionList.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/4/24.
//

import SwiftUI

struct TempTransactionList: View {
    #if os(iOS)
    @Environment(\.scenePhase) var scenePhase
    #endif
    
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(CategoryModel.self) private var catModel
    @Environment(KeywordModel.self) private var keyModel
    
    @State private var selectedDay: CBDay?
    @State private var showLoadingSpinner = false
    @State private var transEditID: String?
    @State private var editTrans: CBTransaction?
    
    @State private var searchText = ""
    
    @FocusState private var searchFocused: Int?
    
    var filteredTransactions: Array<CBTransaction> {
        calModel.tempTransactions.filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var searchPrompt: String {
        searchFocused == 0 ? "Search by transaction name or #" : "Search"
    }
    
    var body: some View {
        @Bindable var calModel = calModel
        @Bindable var appState = AppState.shared
        
        NavigationStack {
            VStack {
                if calModel.tempTransactions.isEmpty {
                    ContentUnavailableView("Problem Connecting To Server", systemImage: "network.slash", description: Text("You can add transactions here, and they will attempt to sync the next time you open the app."))
                } else {
                    List(filteredTransactions, selection: $transEditID) { trans in
                        TransactionListLine(trans: trans, withDate: true)
                    }
                }
            }
            .navigationTitle("Offline Transactions")
            .navigationSubtitle("Transactions will sync when you have internet")
            .searchable(text: $searchText, prompt: searchPrompt)
            .searchFocused($searchFocused, equals: 0)
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .toolbar { toolbar }
        }
        .task { await prepareView() }
        .toast()
        .sheet(item: $editTrans) { trans in
            TransactionEditView(trans: trans, transEditID: $transEditID, day: selectedDay!, isTemp: true)
                .onDisappear { transEditID = nil }
        }
        .onChange(of: transEditID) { oldId, newId in
            if oldId != nil && newId == nil {
                Task { await saveTransaction(id: oldId!) }
            } else {
                editTrans = calModel.getTransaction(by: transEditID!, from: .tempList)
            }
        }
        
        #if os(iOS)
        .onChange(of: scenePhase) {
            if $1 == .active { refresh() }
        }
        #else
        // MARK: - Handling Lifecycles (Mac)
        .onChange(of: AppState.shared.macWokeUp) {
            if $1 { refresh() }
        }
        .onChange(of: AppState.shared.macSlept) {
            if $1 { refresh() }
        }
        .onChange(of: AppState.shared.macWindowDidBecomeMain) {
            if $1 { refresh() }
        }
        #endif
        
        
    }
    
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        #if os(iOS)
        ToolbarItemGroup(placement: .topBarTrailing) { refreshButton }
        DefaultToolbarItem(kind: .search, placement: .bottomBar)
        ToolbarSpacer(.flexible, placement: .bottomBar)
        ToolbarItem(placement: .bottomBar) { newTransactionButton }
        #else
        ToolbarItem(placement: .primaryAction) { newTransactionButton }
        ToolbarItem(placement: .principal) { Text("Temp Transactions") }
        #endif
    }
    
    
    var refreshButton: some View {
        Button {
            refresh()
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
        }
        .opacity(showLoadingSpinner ? 0 : 1)
        .overlay {
            ProgressView()
                .opacity(showLoadingSpinner ? 1 : 0)
        }
    }
    
    
    var newTransactionButton: some View {
        Button {
            transEditID = UUID().uuidString
        } label: {
            Image(systemName: "plus")
        }
    }
        
    
    @ViewBuilder
    func deleteTransactionButton(id: String) -> some View {
        Button("Delete", role: .destructive) {
            calModel.tempTransactions.removeAll { $0.id == id }
            Task {
                let context = DataManager.shared.createContext()
                let _ = DataManager.shared.delete(context: context, type: TempTransaction.self, predicate: .byId(.string(id)))
            }
        }
    }
    
    
    func prepareView() async {
        /// Populate each month object with its day objects.
        calModel.prepareMonths()
        
        let targetMonth = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
        
        if let month = calModel.months.filter({ $0.enumID == targetMonth }).first {
            funcModel.prepareStartingAmounts(for: month)
        }
        
        /// Set the selected month so the app functions normally.
        calModel.setSelectedMonthFromNavigation(navID: targetMonth!, calculateStartingAndEod: false)
        
        /// Get today from the current selected month and set it to the selected day for the transaction.
        let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.num == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
        selectedDay = targetDay
        
        /// Grab categories, payment methods, and transactions from the cache.
        await funcModel.populateCategoriesFromCache()
        await funcModel.populatePaymentMethodsFromCache(setDefaultPayMethod: true)
        await fetchTransactionsFromCache()
    }
    
    
    func refresh() {
        funcModel.refreshTask = Task {
            await fetchTransactionsFromCache()
            showLoadingSpinner = true
            if AuthState.shared.isLoggedIn {
                await funcModel.downloadEverything(setDefaultPayMethod: false, createNewStructs: true, refreshTechnique: .viaTempListSceneChange)
            } else {
                if let apiKey = await AuthState.shared.getApiKeyFromKeychain() {
                    await AuthState.shared.attemptLogin(using: .apiKey, with: LoginModel(apiKey: apiKey))
                }
            }
            showLoadingSpinner = false
        }
    }
    
    
    func saveTransaction(id: String) async {
        print("-- \(#function)")
        let trans = calModel.getTransaction(by: id, from: .tempList)
        
        if trans.title.isEmpty || trans.payMethod == nil {
            withAnimation {
                calModel.tempTransactions.removeAll { $0.id == id }
            }
                        
            if !trans.title.isEmpty && trans.payMethod == nil {
                Task {
                    try? await Task.sleep(for: .seconds(1))
                    //try? await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
                    AppState.shared.showToast(title: "Failed To Add", subtitle: "Account was missing", body: "", symbol: "exclamationmark.triangle", symbolColor: .orange)
                }
            }
            return
        }
        
        /// Not using the result to check. Only calling this to cause logging to happen.
        let _ = trans.hasChanges()
        
        trans.tempAction = .edit
        trans.intendedServerAction = trans.action
        trans.action = .edit
        
        let context = DataManager.shared.createContext()
        await context.perform {
            if let entity = DataManager.shared.getOne(context: context, type: TempTransaction.self, predicate: .byId(.string(trans.id)), createIfNotFound: true) {
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
                entity.notificationOffset = Int64(trans.notificationOffset ?? 0)
                entity.notifyOnDueDate = trans.notifyOnDueDate
                entity.action = trans.action.rawValue
                entity.tempAction = trans.tempAction.rawValue
                entity.isPending = true
                
                
                var set: Set<TempTransactionLog> = Set()
                
                for each in trans.logs {
                    if let entity = DataManager.shared.createBlank(context: context, type: TempTransactionLog.self) {
                        entity.field = each.field.rawValue
                        entity.oldValue = each.old
                        entity.newValue = each.new
                        entity.transactionID = each.itemID
                        set.insert(entity)
                    }
                }
                entity.logs = NSSet(set: set)
//                entity.logs = NSSet(set: Set(trans.logs.compactMap {
//                    if let entity = DataManager.shared.createBlank(context: context, type: TempTransactionLog.self) {
//                        entity.field = $0.field.rawValue
//                        entity.oldValue = $0.old
//                        entity.newValue = $0.new
//                        entity.transactionID = $0.itemID
//                        set.insert(entity)
//                    }
//                    
//                }))
                
                
                let _ = DataManager.shared.save(context: context)
            }
        }
    }
    
    
    
    func fetchTransactionsFromCache() async {
        // Clear immediately on main actor
        await MainActor.run {
            withAnimation {
                calModel.tempTransactions.removeAll()
            }
        }
        
        let context = DataManager.shared.createContext()
        
        // Step 1 — Load everything in background
        let loadedTransactions: [CBTransaction] = await context.perform {
            
            var results: [CBTransaction] = []
            
            if let entities = DataManager.shared.getMany(context: context, type: TempTransaction.self) {
                for entity in entities {
                    var category: CBCategory?
                    var payMethod: CBPaymentMethod?
                    
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
                    
                    var logs: [CBLog] = []
                    if let logEntities = entity.logs {
                        let groupID = UUID().uuidString
                        logEntities.forEach { e in
                            logs.append(
                                CBLog(transEntity: e as! TempTransactionLog, groupID: groupID)
                            )
                        }
                    }
                    
                    if let payMethod {
                        let trans = CBTransaction(entity: entity, payMethod: payMethod, category: category, logs: logs)
                        
                        if trans.action != .delete && trans.tempAction != .delete {
                            results.append(trans)
                        }
                    }
                }
            }
            
            return results
        }
        
        // Step 2 — Apply diffs back on the main actor
        await MainActor.run {
            withAnimation {
                for trans in loadedTransactions {
                    if let index = calModel.tempTransactions.firstIndex(where: { $0.id == trans.id }) {
                        calModel.tempTransactions[index].setFromAnotherInstance(transaction: trans)
                    } else {
                        calModel.tempTransactions.append(trans)
                    }
                }
            }
        }
    }
    
//    
//    
//    func fetchTransactionsFromCacheOG() async {
//        withAnimation {
//            calModel.tempTransactions.removeAll()
//        }
//        
//        let context = DataManager.shared.createContext()
//        
//        await context.perform {
//            if let entities = DataManager.shared.getMany(context: context, type: TempTransaction.self) {
//                for entity in entities {
//                    var category: CBCategory?
//                    var payMethod: CBPaymentMethod?
//                    
//                    if let categoryID = entity.categoryID {
//                        if let perCategory = DataManager.shared.getOne(context: context, type: PersistentCategory.self, predicate: .byId(.string(categoryID)), createIfNotFound: false) {
//                            category = CBCategory(entity: perCategory)
//                        }
//                    }
//                    
//                    if let payMethodID = entity.payMethodID {
//                        if let perPayMethod = DataManager.shared.getOne(context: context, type: PersistentPaymentMethod.self, predicate: .byId(.string(payMethodID)), createIfNotFound: false) {
//                            payMethod = CBPaymentMethod(entity: perPayMethod)
//                        }
//                    }
//                    
//                    var logs: Array<CBLog> = []
//                    if let logEntities = entity.logs {
//                        let groupID = UUID().uuidString
//                        logEntities.forEach { entity in
//                            let log = CBLog(transEntity: entity as! TempTransactionLog, groupID: groupID)
//                            logs.append(log)
//                        }
//                    }
//                    
//                                            
//                    if let payMethod = payMethod {
//                        let trans = CBTransaction(entity: entity, payMethod: payMethod, category: category, logs: logs)
//                        if trans.action == .delete || trans.tempAction == .delete {
//                            
//                        } else {
//                            print("Appending \(trans.title)")
//                            
//                            if let index = calModel.tempTransactions.firstIndex(where: { $0.id == trans.id }) {
//                                calModel.tempTransactions[index].setFromAnotherInstance(transaction: trans)
//                            } else {
//                                calModel.tempTransactions.append(trans)
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    
//    struct TransLineItem: View {
//        @Bindable var trans: CBTransaction
//        
//        @Binding var showDeleteAlert: Bool
//        @Binding var transDeleteID: String?
//        
//        var body: some View {
//            HStack(alignment: .circleAndTitle, spacing: 4) {
//                VStack(alignment: .leading, spacing: 2) {
//                    HStack {
//                        Text(trans.title)
//                        Spacer()
//                        Text(trans.amountString)
//                            .foregroundStyle(.gray)
//                            .font(.caption)
//                    }
//                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
//                                                                
//                    HStack {
//                        Text(trans.date?.string(to: .monthDayShortYear) ?? "N/A")
//                            .foregroundStyle(.gray)
//                            .font(.caption)
//                        Spacer()
//                        HStack(spacing: 4) {
//                            Circle()
//                                .frame(width: 6, height: 6)
//                                .foregroundStyle(trans.payMethod?.color ?? .primary)
//                            
//                            Text(trans.payMethod?.title ?? "N/A")
//                                .foregroundStyle(.gray)
//                                .font(.caption)
//                        }
//                    }
//                }
//            }
//            .swipeActions(content: {
//                Button {
//                    transDeleteID = trans.id
//                    showDeleteAlert = true
//                } label: {
//                    Image(systemName: "trash")
//                }
//                .tint(.red)
//                
//            })
//            .contentShape(Rectangle())
//        }
//    }
//    
}
