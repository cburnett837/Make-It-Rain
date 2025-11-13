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
    @State private var showDeleteAlert = false
    @State private var transDeleteID: String?
    
    @State private var showLoadingSpinner = false
    @State private var transEditID: String?
    @State private var editTrans: CBTransaction?
    
    var body: some View {
        @Bindable var calModel = calModel
        @Bindable var appState = AppState.shared
        NavigationStack {
            VStack {
                if calModel.tempTransactions.isEmpty {
                    ContentUnavailableView("Problem Connecting To Server", systemImage: "network.slash", description: Text("You can add transactions here, and they will attempt to sync the next time you open the app."))
                } else {
                    List(selection: $transEditID) {
                        ForEach(catModel.categories) { cat in
                            if !calModel.tempTransactions.filter({$0.category?.id == cat.id}).isEmpty {
                                Section(cat.title) {
                                    ForEach(calModel.tempTransactions.filter {$0.category?.id == cat.id}) { trans in
                                        TransLineItem(trans: trans, showDeleteAlert: $showDeleteAlert, transDeleteID: $transDeleteID)
                                    }
                                }
                            }
                        }
                        
                        if !calModel.tempTransactions.filter({$0.category == nil}).isEmpty {
                            Section("(No Category)") {
                                ForEach(calModel.tempTransactions.filter {$0.category == nil}) { trans in
                                    TransLineItem(trans: trans, showDeleteAlert: $showDeleteAlert, transDeleteID: $transDeleteID)
                                }
                            }
                        }
                    }
                                        
                    Text("Currently Offline")
                        .foregroundStyle(.gray)
                        .italic()
                        .font(.caption)
                }
            }
            .toolbar {
                #if os(iOS)
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        funcModel.refreshTask = Task {
                            await fetchTransactionsFromCache()
                            //authState.isThinking = true
                            showLoadingSpinner = true
                            if AuthState.shared.isLoggedIn {
                                await funcModel.downloadEverything(setDefaultPayMethod: false, createNewStructs: true, refreshTechnique: .viaTempListButton)
                            } else {
                                
                                if let apiKey = await AuthState.shared.getApiKeyFromKeychain() {
                                    await AuthState.shared.attemptLogin(using: .apiKey, with: LoginModel(apiKey: apiKey))
                                }
                            }
                            showLoadingSpinner = false
                        }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    .opacity(showLoadingSpinner ? 0 : 1)
                    .overlay {
                        ProgressView()
                            .opacity(showLoadingSpinner ? 1 : 0)
                    }
                    
                    Button {
                        transEditID = UUID().uuidString
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        transEditID = UUID().uuidString
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Temp Transactions")
                }
                #endif
            }
            .navigationTitle("Transactions")
        }
        .toast()
        .alert("Delete transaction?", isPresented: $showDeleteAlert, presenting: transDeleteID, actions: { id in
            Button("Delete", role: .destructive) {
                calModel.tempTransactions.removeAll { $0.id == id }
                Task {
                    let context = DataManager.shared.createContext()
                    let _ = DataManager.shared.delete(context: context, type: TempTransaction.self, predicate: .byId(.string(id)))
                }
                
            }
            
            Button("Cancel", role: .cancel) {
                showDeleteAlert = false
            }
        })
        
        .sheet(item: $editTrans) { trans in
            TransactionEditView(trans: trans, transEditID: $transEditID, day: selectedDay!, isTemp: true)
                .onDisappear { transEditID = nil }
        }
        .onChange(of: transEditID, { oldValue, newValue in
            /// When `newValue` is false, save to the server. We have to use this because `.popover(isPresented:)` has no onDismiss option.
            if oldValue != nil && newValue == nil {
                Task {
                    await saveTransaction(id: oldValue!)
                }
                
            } else {
                editTrans = calModel.getTransaction(by: transEditID!, from: .tempList)
            }
        })
        
        
        .task {
            calModel.prepareMonths()
            
            let targetMonth = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
            
            
            if let month = calModel.months.filter({ $0.enumID == targetMonth }).first {
                funcModel.prepareStartingAmounts(for: month)
            }
            
            calModel.setSelectedMonthFromNavigation(navID: targetMonth!, prepareStartAmount: false)
            
            let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.num == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
            selectedDay = targetDay
            
            await funcModel.populateCategoriesFromCache()
            await funcModel.populatePaymentMethodsFromCache(setDefaultPayMethod: true)
            await fetchTransactionsFromCache()
        }
        
        #if os(iOS)
        .onChange(of: scenePhase) { oldPhrase, newPhase in
            if newPhase == .inactive {
                print("scenePhase: Inactive")
            } else if newPhase == .active {
                print("scenePhase: Active")
                Task {
                    await lifeCycleChange()
                }
            } else if newPhase == .background {
                print("scenePhase: Background")
            }
        }
        #else
        // MARK: - Handling Lifecycles (Mac)
        .onChange(of: AppState.shared.macWokeUp) { oldValue, newValue in
            if newValue { Task { await lifeCycleChange() } }
        }
        .onChange(of: AppState.shared.macSlept) { oldValue, newValue in
            if newValue { Task { await lifeCycleChange() } }
        }
        .onChange(of: AppState.shared.macWindowDidBecomeMain) { oldValue, newValue in
            if newValue { Task { await lifeCycleChange() } }
        }
        #endif
        
        
    }
    
    func lifeCycleChange() async {
        await fetchTransactionsFromCache()
        
        funcModel.refreshTask = Task {
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
            calModel.tempTransactions.removeAll { $0.id == id }
                        
            if !trans.title.isEmpty && trans.payMethod == nil {
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
                    
                    AppState.shared.showToast(title: "Failed To Add", subtitle: "Account was missing", body: "", symbol: "exclamationmark.triangle", symbolColor: .orange)
                }
            }
            return
        }
        
        /// Not using the result to check. Only calling this to cause logging to happen.
        let _ = trans.hasChanges()
        
        trans.tempAction = .edit
        
        let context = DataManager.shared.createContext()
        await context.perform {
            if let entity = DataManager.shared.getOne(context: context, type: TempTransaction.self, predicate: .byId(.string(trans.id)), createIfNotFound: true) {
                
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
        calModel.tempTransactions.removeAll()
        
        let context = DataManager.shared.createContext()
        
        await context.perform {
            if let entities = DataManager.shared.getMany(context: context, type: TempTransaction.self) {
                for entity in entities {
                    var category: CBCategory?
                    var payMethod: CBPaymentMethod?
                    
                    if let categoryID = entity.categoryID {
                        if let perCategory = DataManager.shared.getOne(context: context, type: PersistentCategory.self, predicate: .byId(.string(categoryID)), createIfNotFound: false) {
                            category = CBCategory(entity: perCategory)
                        }
                    }
                    
                    if let payMethodID = entity.payMethodID {
                        if let perPayMethod = DataManager.shared.getOne(context: context, type: PersistentPaymentMethod.self, predicate: .byId(.string(payMethodID)), createIfNotFound: false) {
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
                        let trans = CBTransaction(entity: entity, payMethod: payMethod, category: category, logs: logs)
                        if trans.action == .delete || trans.tempAction == .delete {
                            
                        } else {
                            calModel.tempTransactions.append(trans)
                        }
                    }
                }
            }
        }
    }
    
    
    struct TransLineItem: View {
        @Bindable var trans: CBTransaction
        
        @Binding var showDeleteAlert: Bool
        @Binding var transDeleteID: String?
        
        var body: some View {
            HStack(alignment: .circleAndTitle, spacing: 4) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(trans.title)
                        Spacer()
                        Text(trans.amountString)
                            .foregroundStyle(.gray)
                            .font(.caption)
                    }
                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                                                                
                    HStack {
                        Text(trans.date?.string(to: .monthDayShortYear) ?? "N/A")
                            .foregroundStyle(.gray)
                            .font(.caption)
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundStyle(trans.payMethod?.color ?? .primary)
                            
                            Text(trans.payMethod?.title ?? "N/A")
                                .foregroundStyle(.gray)
                                .font(.caption)
                        }
                    }
                }
            }
            .swipeActions(content: {
                Button {
                    transDeleteID = trans.id
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                }
                .tint(.red)
                
            })
            .contentShape(Rectangle())
        }
    }
    
}
