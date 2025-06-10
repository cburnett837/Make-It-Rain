//
//  RootViewIphone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/16/24.
//

import SwiftUI

#if os(iOS)
struct RootViewPhone: View {
    @Local(\.colorTheme) var colorTheme

    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(KeywordModel.self) var keyModel
    @Environment(RepeatingTransactionModel.self) var repModel
    @Environment(EventModel.self) var eventModel
    @Environment(PlaidModel.self) var plaidModel
    
    let monthNavigationNamespace: Namespace.ID
    
    @State private var toolbarVisibility = Visibility.visible

    
    var body: some View {
        @Bindable var navManager = NavigationManager.shared
        TabView {
            Tab("Calendar", systemImage: "calendar") {
                NavigationStack {
                    CalendarNavGridPhone(monthNavigationNamespace: monthNavigationNamespace)
                        .onAppear { toolbar(to: .visible) }
                        .navigationDestination(for: NavDestination.self) { dest in
                            switch dest {
                            case .settings:
                                SettingsView(showSettings: .constant(false))
                                    .onAppear { toolbar(to: .hidden) }                            
                                
                            default:
                                EmptyView()
                            }
                        }
                }
                .toolbar(toolbarVisibility, for: .tabBar)
            }
            
            Tab("Categories", systemImage: "books.vertical") {
                NavigationStack {
                    CategoriesTable()
                }
            }
            
//            Tab("Events", systemImage: "beach.umbrella") {
//                NavigationStack {
//                    EventsTable()
//                }
//            }
//            .badge(eventModel.invitations.count)
            
            
            Tab("Accounts", systemImage: "creditcard") {
                NavigationStack {
                    PayMethodsTable()
                }
            }
            
            
            Tab("Search", systemImage: "magnifyingglass") {
                NavigationStack {
                    AdvancedSearchView()
                }
            }
            
            Tab("More", systemImage: "ellipsis") {
                NavigationStack {
                    moreTabList
                }
                .toolbar(toolbarVisibility, for: .tabBar)
            }
            .badge(plaidModel.banksWithIssues.count)
        }
    }
    
    var moreTabList: some View {
        List {
//            NavigationLink(value: NavDestination.paymentMethods) {
//                Label { Text("Payment Methods") } icon: { Image(systemName: "creditcard") }
//            }
            
            Section("Extras") {
                NavigationLink(value: NavDestination.events) {
                    Label { Text("Events") } icon: { Image(systemName: "beach.umbrella") }
                }
                
                if AppState.shared.methsExist {
                    NavigationLink(value: NavDestination.repeatingTransactions) {
                        Label { Text("Reoccuring Transactions") } icon: { Image(systemName: "repeat") }
                    }
                    
                    NavigationLink(value: NavDestination.keywords) {
                        Label { Text("Keywords") } icon: { Image(systemName: "textformat.abc.dottedunderline") }
                    }
                }
            }
            
            Section("Plaid Integration") {
                NavigationLink(value: NavDestination.plaid) {
                    Label { Text("Plaid") } icon: {
                        if plaidModel.atLeastOneBankHasAnIssue {
                            Image(systemName: "creditcard.trianglebadge.exclamationmark")
                                .foregroundStyle(Color.fromName(colorTheme) == .orange ? .red : .orange)
                        } else {
                            Image(systemName: "list.bullet")
                        }
                    }
                }
            }
            
            Section("Settings") {
                if AppState.shared.user?.id == 1 {
                    NavigationLink(value: NavDestination.debug) {
                        Label { Text("Debug") } icon: { Image(systemName: "ladybug") }
                    }
                    .badge(funcModel.loadTimes.count)
                }
                
                NavigationLink(value: NavDestination.settings) {
                    Label { Text("Settings") } icon: { Image(systemName: "gear") }
                }
            }
        }
        .listStyle(.plain)
        .onAppear { toolbar(to: .visible) }
        .navigationTitle("More")
        //.navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: NavDestination.self) { dest in
            switch dest {
            case .repeatingTransactions:
                RepeatingTransactionsTable()
                    .onAppear { toolbar(to: .hidden) }
                
            case .paymentMethods:
                PayMethodsTable()
                    .onAppear { toolbar(to: .hidden) }
                
            case .events:
                EventsTable()
                    .onAppear { toolbar(to: .hidden) }
                                               
            case .keywords:
                KeywordsTable()
                    .onAppear { toolbar(to: .hidden) }
                
            case .settings:
                SettingsView(showSettings: .constant(true))
                    .onAppear { toolbar(to: .hidden) }
                
            case .debug:
                DebugView()
                    .onAppear { toolbar(to: .hidden) }
                
            case .plaid:
                PlaidTable()
                    .onAppear { toolbar(to: .hidden) }
                
            default:
                EmptyView()
            }
        }
    }
    
    func toolbar(to visibility: Visibility) {
        withAnimation {
            toolbarVisibility = visibility
        }
    }
}

#endif
