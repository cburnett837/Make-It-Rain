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
                        fetchTransactionsFromCache()
                        funcModel.refreshTask = Task {
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
                let _ = DataManager.shared.delete(type: TempTransaction.self, predicate: .byId(.string(id)))
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
                saveTransaction(id: oldValue!)
            } else {
                editTrans = calModel.getTransaction(by: transEditID!, from: .tempList)
            }
        })
        
        
        .task {
            calModel.prepareMonths()
            
            let targetMonth = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
            calModel.setSelectedMonthFromNavigation(navID: targetMonth!, prepareStartAmount: false)
            
            let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == (calModel.sMonth.num == AppState.shared.todayMonth ? AppState.shared.todayDay : 1) }.first
            selectedDay = targetDay
            
            funcModel.populateCategoriesFromCache()
            funcModel.populatePaymentMethodsFromCache(setDefaultPayMethod: true)
            fetchTransactionsFromCache()
        }
        
        #if os(iOS)
        .onChange(of: scenePhase) { oldPhrase, newPhase in
            if newPhase == .inactive {
                print("scenePhase: Inactive")
            } else if newPhase == .active {
                print("scenePhase: Active")
                lifeCycleChange()
            } else if newPhase == .background {
                print("scenePhase: Background")
            }
        }
        #else
        // MARK: - Handling Lifecycles (Mac)
        .onChange(of: AppState.shared.macWokeUp) { oldValue, newValue in
            if newValue { lifeCycleChange() }
        }
        .onChange(of: AppState.shared.macSlept) { oldValue, newValue in
            if newValue { lifeCycleChange() }
        }
        .onChange(of: AppState.shared.macWindowDidBecomeMain) { oldValue, newValue in
            if newValue { lifeCycleChange() }
        }
        #endif
        
        
    }
    
    func lifeCycleChange() {
        fetchTransactionsFromCache()
        
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
    
    
    func saveTransaction(id: String) {
        print("-- \(#function)")
        let trans = calModel.getTransaction(by: id, from: .tempList)
        
        if trans.title.isEmpty || trans.payMethod == nil {
            calModel.tempTransactions.removeAll { $0.id == id }
                        
            if !trans.title.isEmpty && trans.payMethod == nil {
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
                    
                    AppState.shared.showToast(title: "Failed To Add", subtitle: "Payment Method was missing", body: "", symbol: "exclamationmark.triangle", symbolColor: .orange)
                }
            }
            return
        }
        
        /// Not using the result to check. Only calling this to cause logging to happen.
        let _ = trans.hasChanges()
        
        trans.tempAction = .edit
        
        
        guard let entity = DataManager.shared.getOne(type: TempTransaction.self, predicate: .byId(.string(trans.id)), createIfNotFound: true) else { return }
        
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
        //entity.pictures = trans.pictures
        entity.factorInCalculations = trans.factorInCalculations
        entity.notificationOffset = Int64(trans.notificationOffset ?? 0)
        entity.notifyOnDueDate = trans.notifyOnDueDate
        entity.action = trans.action.rawValue
        entity.tempAction = trans.tempAction.rawValue
        entity.isPending = true
        entity.logs = NSSet(set: Set(trans.logs.compactMap { $0.createCoreDataEntity() }))
        
        
        let _ = DataManager.shared.save()
    }
    
    
    func fetchTransactionsFromCache() {
        do {
            calModel.tempTransactions.removeAll()
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
                        let trans = CBTransaction(entity: entity, payMethod: payMethod, category: category, logs: logs)
                        if trans.action == .delete || trans.tempAction == .delete {
                            
                        } else {
                            calModel.tempTransactions.append(trans)
                        }
                    }
                }
            }
        } catch {
            print(error.localizedDescription)
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
