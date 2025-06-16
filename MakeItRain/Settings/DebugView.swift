//
//  DebugView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/15/25.
//

import SwiftUI

struct DebugView: View {
    @AppStorage("debugPrint") var debugPrint = false

    @Environment(FuncModel.self) var funcModel
    
    @State private var plaidCosts: Array<PlaidForceRefreshCost> = []
    
    var body: some View {
        List {
            Section {
                dumpCoreDataButton
            }
            
            Section("Xcode") {
                consolePrintToggle
            }
            
            loadTimeSection
            
            plaidForceRefreshSection
        }
        .navigationTitle("Debug")
        .toolbar {
            #if os(macOS)
            macToolbar()
            #else
            phoneToolbar()
            #endif
        }
        .task {
            await fetchPlaidCosts()
        }
    }
    
    
    var dumpCoreDataButton: some View {
        Button("Clear Core Data") {
            let context = DataManager.shared.createContext()
            context.perform {
                /// Remove all from cache.
                let _ = DataManager.shared.deleteAll(context: context, for: PersistentPaymentMethod.self)
                //print(saveResult1)
                let _ = DataManager.shared.deleteAll(context: context, for: PersistentCategory.self)
                //print(saveResult2)
                let _ = DataManager.shared.deleteAll(context: context, for: PersistentKeyword.self)
                //print(saveResult3)
                
                let _ = DataManager.shared.save(context: context)
            }
        }
    }
    
    
    var consolePrintToggle: some View {
        Toggle(isOn: $debugPrint) {
            Label {
                VStack(alignment: .leading) {
                    Text("Console print")
                }
            } icon: {
                Image(systemName: "apple.terminal")
            }
        }
        .onChange(of: debugPrint) { oldValue, newValue in
            if newValue {
                UserDefaults.standard.set("YES", forKey: "debugPrint")
                AppState.shared.debugPrintString = "YES"
            } else {
                UserDefaults.standard.set("NO", forKey: "debugPrint")
                AppState.shared.debugPrintString = "NO"
            }
        }
    }
    
    
    var loadTimeSection: some View {
        Section {
            if funcModel.loadTimes.isEmpty {
                Text("App Initial Load Times")
            } else {
                ForEach(funcModel.loadTimes, id: \.id) { metric in
                    HStack {
                        Text("\(metric.date.string(to: .dateTime))")
                        Spacer()
                        Text("\(metric.load)")
                    }
                }
            }
        } header: {
            HStack {
                Text("Load Times")
                Spacer()
                Button("Clear") {
                    funcModel.loadTimes.removeAll()
                }
                .font(.caption)
            }
            
        } footer: {
            Text("Note: These times are not retained between app launches")
        }
    }
    
    
    var plaidForceRefreshSection: some View {
        Section("Plaid Force Refresh Costs") {
            Button("Refresh") {
                Task { await fetchPlaidCosts() }
            }
            ForEach(plaidCosts) { cost in
                HStack {
                    Text("\(cost.month)-\(String(cost.year))")
                    Spacer()
                    Text(cost.totalCost.currencyWithDecimals(2))
                }
            }
        }
    }
    
    
    
    #if os(macOS)
    @ToolbarContentBuilder
    func macToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            HStack {
                ToolbarNowButton()
                    .disabled(!AppState.shared.methsExist)
                ToolbarRefreshButton()
                    .toolbarBorder()
                    .disabled(!AppState.shared.methsExist)
            }
        }
        ToolbarItem(placement: .principal) {
            ToolbarCenterView(enumID: .debug)
        }
        ToolbarItem {
            Spacer()
        }
    }
    
    #else
    
    @ToolbarContentBuilder
    func phoneToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if AppState.shared.isIpad {
                HStack(spacing: 20) {
                    ToolbarRefreshButton()
                        .disabled(!AppState.shared.methsExist)
                    
                    ToolbarLongPollButton()
                }
            }
        }
        
        if AppState.shared.isIphone {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 20) {
                    ToolbarRefreshButton()
                        .disabled(!AppState.shared.methsExist)
                }
            }
        }
    }
    
    #endif
    
    
    @MainActor
    func fetchPlaidCosts() async {
        let model = RequestModel(requestType: "plaid_get_force_refresh_cost", model: AppState.shared.user!)
        typealias ResultResponse = Result<Array<PlaidForceRefreshCost>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            if let model {
                self.plaidCosts = model
            }
        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("calModel fetchPlaidTransactionsFromServer Server Task Cancelled")
            default:
                AppState.shared.showAlert("There was a problem trying to fetch costs.")
            }
        }
    }
    
}
