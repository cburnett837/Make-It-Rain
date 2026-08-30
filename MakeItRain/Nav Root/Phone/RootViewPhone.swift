//
//  RootViewIphone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/16/24.
//

import SwiftUI


#if os(iOS)
struct RootViewPhone: View {
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(KeywordModel.self) var keyModel
    @Environment(RepeatingTransactionModel.self) var repModel
    @Environment(PlaidModel.self) var plaidModel
    @Environment(DashboardModel.self) var dashboardModel
    
    /// Using a navigation link instead of a button for the settings button the toolbar causes the icon to be a tiny bit wider than a normal button.
    /// So use a navPath so we can append to the path via the settings button.
    @State private var calendarNavPath: [NavDest] = []
    @State private var advancedSearchNavPath = NavigationPath()
    @State private var dashboardNavPath: [NavDest] = []
    @State private var moreNavPath: [NavDest] = []
    @State private var toolbarVisibility = Visibility.visible
    @State private var sel: NavDest?
    
    var body: some View {
        @Bindable var navManager = NavigationManager.shared
        TabView(selection: $sel) {
            Tab(NavDest.calendar.displayName, systemImage: NavDest.calendar.symbol, value: .calendar) {
                calendarGridNavPhone
                    .toolbar(toolbarVisibility, for: .tabBar)
            }
            
            Tab(NavDest.dashboard.displayName, systemImage: NavDest.dashboard.symbol, value: .dashboard) {
                dashboard
            }
            
            Tab(NavDest.paymentMethods.displayName, systemImage: NavDest.paymentMethods.symbol, value: .paymentMethods) {
                /// NavStack is in the view.
                PayMethodsTable()
            }
            
            Tab(NavDest.more.displayName, systemImage: NavDest.more.symbol, value: .more) {
                moreTabList
            }
            .badge(plaidModel.banksWithIssues.count)
            
            Tab(NavDest.search.displayName, systemImage: NavDest.search.symbol, value: .search, role: .search) {
                NavigationStack(path: $advancedSearchNavPath) {
                    AdvancedSearchView(navPath: $advancedSearchNavPath)
                }
            }
        }
    }
    
    
    var calendarGridNavPhone: some View {
        NavigationStack(path: $calendarNavPath) {
            CalendarNavGridPhone(calendarNavPath: $calendarNavPath)
                .onAppear { toolbar(to: .visible) }
                .navigationDestination(for: NavDest.self) { dest in
                    switch dest {
                    case .settings:
                        SettingsView(showSettings: .constant(false))
                            .onAppear { toolbar(to: .hidden) }
                    case .toasts:
                        ToastList()
                            .onAppear { toolbar(to: .hidden) }
                    default:
                        EmptyView()
                    }
                }
        }
    }
    
    
    var dashboard: some View {
        NavigationStack(path: $dashboardNavPath) {
            Dashboard(navPath: $dashboardNavPath, model: dashboardModel, isForSelectedMonth: false)
                .navigationDestination(for: NavDest.self) { dest in
                    switch dest {
                    case .dashboardNumericBreakdown:
                        DashboardNumericDetails(model: dashboardModel, isForSelectedMonth: false)
                        
                    case .dashboardTransactionList(let data, let category):
                        DashboardTransactionList(data: data, category: category)
                        
                    default:
                        Text("Unsupported destination")
                    }
                }
        }
    }
    
    
    var plaidNavLink: some View {
        NavigationLink(value: NavDest.plaid) {
            Label {
                Text(NavDest.plaid.displayName)
            } icon: {
                if plaidModel.atLeastOneBankHasAnIssue {
                    Image(systemName: "creditcard.trianglebadge.exclamationmark")
                        .foregroundStyle(Color.theme == .orange ? .red : .orange)
                } else {
                    Image(systemName: NavDest.plaid.symbol)
                }
            }
        }
    }
    
    
    var moreTabList: some View {
        NavigationStack(path: $moreNavPath) {
            List {
                Section {
                    //NavLinkPhone(destination: .paymentMethods)
                    if AppState.shared.methsExist {
                        NavLinkPhone(destination: .budgets)
                        NavLinkPhone(destination: .categories)
                        NavLinkPhone(destination: .repeatingTransactions)
                        NavLinkPhone(destination: .keywords)
                        NavLinkPhone(destination: .recentReceipts)
                    }
                }
                
                Section("Plaid Integration") {
                    plaidNavLink
                }
                
                Section("Misc") {
                    NavLinkPhone(destination: .toasts)
                    
                    if AppState.shared.user?.id == 1 {
                        NavLinkPhone(destination: .debug)
                            .badge(funcModel.loadTimes.count)
                    }
                    
                    NavLinkPhone(destination: .settings)
                }
            }
            .listStyle(.plain)
            .navigationTitle("More")
            .navigationDestination(for: NavDest.self) { dest in
                NavDest.view(for: dest, navPath: $moreNavPath)
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
