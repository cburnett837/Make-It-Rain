//
//  ContentView.swift
//  Make It Rain Watch Watch App
//
//  Created by Cody Burnett on 6/27/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab {
                TransactionList()
            } label: {
                Label("Trans", systemImage: "dollarsign")
                
            }
            
            Tab {
                MetaData()
            } label: {
                Label("Metadata", systemImage: "person")
            }
        }
    }
}

struct TransactionList: View {
    @Environment(\.scenePhase) var scenePhase
    
    @State private var trans: [PlaidTransLite] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView()
                } else {
                    List {
                        Section {
                            ForEach(trans) { trans in
                                HStack {
                                    if let data = trans.logo, let image = UIImage(data: data) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .frame(width: 20, height: 20, alignment: .center)
                                            .clipShape(Circle())
                                    }
                                    
                                    Text(trans.title)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Text("\(trans.amount.currencyWithDecimals())")
                                }
                                .font(.subheadline)
                                
                            }
                        }
                    }
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            isLoading = true
                            await fetch()
                            isLoading = false
                        }
                    } label: {
                        Image(systemName: "arrow.trianglehead.clockwise")
                    }
                }
            }
            .task {
                WatchPhoneSync.shared.start()
                await fetch()
                isLoading = false
            }
            .onChange(of: scenePhase) {
                if $1 == .active {
                    Task {
                        isLoading = true
                        await fetch()
                        isLoading = false
                    }
                }
            }
        }
    }
    
    func fetch() async {
        if let result = await BudgetWidgetAPI.fetchBudgetData() {
            self.trans = result.trans
        }
    }
}

struct MetaData: View {
    @State private var token: String?
    @State private var user: CBUser?
    
    var body: some View {
        NavigationStack {
            List {
                Section("Details") {
                    row("Token", token)
                    row("Name", user?.name)
                    row("User ID", user?.id)
                    row("Account ID", user?.accountID)
                }
            }
            .navigationTitle("Metadata")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        getData()
                    } label: {
                        Image(systemName: "arrow.trianglehead.clockwise")
                    }
                }
            }
            .task {
                WatchPhoneSync.shared.start()
                getData()
            }
        }
    }
    
    @ViewBuilder
    func row(_ title: String, _ value: String?) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value ?? "N/A")
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    func row(_ title: String, _ value: Int?) -> some View {
        HStack {
            Text(title)
            Spacer()
            if let value {
                Text("\(value)")
                    .foregroundStyle(.secondary)
            } else {
                Text("N/A")
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    func getData() {
        if let ud = UserDefaults(suiteName: "group.dev.cburnett837.MakeItRain")?.data(forKey: "user") {
            do {
                self.user = try JSONDecoder().decode(CBUser.self, from: ud)
            } catch {
                print("Unable to Decode User (\(error))")
            }
        }
        
        do {
            self.token = try KeychainManager().getFromKeychain(key: "api_key")
        } catch {
            print(error.localizedDescription)
        }
    }
}
