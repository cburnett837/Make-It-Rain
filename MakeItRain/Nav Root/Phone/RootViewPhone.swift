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
        
    @State private var toolbarVisibility = Visibility.visible
    @State private var sel: NavDest?
    
    /// Using a navigation link instead of a button for the settings button the toolbar causes the icon to be a tiny bit wider than a normal button.
    /// So use a navPath so we can append to the path via the settings button.
    @State private var calendarNavPath = NavigationPath()
    @State private var advancedSearchNavPath = NavigationPath()
    @State private var dashboardNavPath: [NavDest] = []
    @State private var moreNavPath = NavigationPath()
    //@State private var dashboardModel = DashboardModel()
    
    var body: some View {
        @Bindable var navManager = NavigationManager.shared
        TabView(selection: $sel) {
            Tab(NavDest.calendar.displayName, systemImage: NavDest.calendar.symbol, value: .calendar) {
                NavigationStack(path: $calendarNavPath) {
                    calendarGridNavPhone
                }
                .toolbar(toolbarVisibility, for: .tabBar)
            }
            
            Tab(NavDest.dashboard.displayName, systemImage: NavDest.dashboard.symbol, value: .dashboard) {
                NavigationStack(path: $dashboardNavPath) {
                    Dashboard(
                        navPath: $dashboardNavPath,
                        showAnalysisSheet: .constant(true),
                        model: dashboardModel,
                        isForSelectedMonth: false
                    )
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
            
//            Tab(NavDest.categories.displayName, systemImage: NavDest.categories.symbol, value: .categories) {
//                NavigationStack {
//                    CategoriesTable()
//                }
//            }
            
            Tab(NavDest.paymentMethods.displayName, systemImage: NavDest.paymentMethods.symbol, value: .paymentMethods) {
                /// NavStack is in the view.
                PayMethodsTable()
            }
            
            Tab(NavDest.more.displayName, systemImage: NavDest.more.symbol, value: .more) {
                NavigationStack(path: $moreNavPath) {
                    moreTabList/*.toolbar(toolbarVisibility, for: .tabBar)*/
                }
            }
            .badge(plaidModel.banksWithIssues.count)
            
            Tab(NavDest.search.displayName, systemImage: NavDest.search.symbol, value: .search, role: .search) {
                NavigationStack(path: $advancedSearchNavPath) {
                    AdvancedSearchView(navPath: $advancedSearchNavPath)
                }
            }
        }
//        .tabViewBottomAccessory(isEnabled: sel == .dashboard) {
//            showDateRangeSheetButton
//        }
        
        
//        .onChange(of: sel) { oldValue, newValue in
//            if oldValue == NavDest.categories {
//                if calModel.categoryFilterWasSetByCategoryPage {
//                    calModel.sCategories.removeAll()
//                    calModel.categoryFilterWasSetByCategoryPage = false
//                }
//            }
//        }
    }
    
    
    var calendarGridNavPhone: some View {
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
        .navigationDestination(for: NavDest.self) { NavDest.view(for: $0, navPath: $moreNavPath) }
    }
    
    
    func toolbar(to visibility: Visibility) {
        withAnimation {
            toolbarVisibility = visibility
        }
    }
}

#endif


//
//#if os(iOS)
//struct RootViewPhoneOG: View {
//    //@Local(\.colorTheme) var colorTheme
//
//    @Environment(FuncModel.self) var funcModel
//    @Environment(CalendarModel.self) var calModel
//    @Environment(PayMethodModel.self) var payModel
//    @Environment(CategoryModel.self) var catModel
//    @Environment(KeywordModel.self) var keyModel
//    @Environment(RepeatingTransactionModel.self) var repModel
//    
//    @Environment(PlaidModel.self) var plaidModel
//    
//    let monthNavigationNamespace: Namespace.ID
//    
//    @State private var toolbarVisibility = Visibility.visible
//    @State private var sel: String = ""
//
//    
//    var body: some View {
//        @Bindable var navManager = NavigationManager.shared
//        TabView(selection: $sel) {
//            Tab("Calendar", systemImage: "calendar", value: "calendar") {
//                NavigationStack {
//                    CalendarNavGridPhone(monthNavigationNamespace: monthNavigationNamespace)
//                        .onAppear { toolbar(to: .visible) }
//                        .navigationDestination(for: NavDest.self) { dest in
//                            switch dest {
//                            case .settings:
//                                SettingsView(showSettings: .constant(false))
//                                    .onAppear { toolbar(to: .hidden) }                            
//                                
//                            default:
//                                EmptyView()
//                            }
//                        }
//                }
//                .toolbar(toolbarVisibility, for: .tabBar)
//            }
//            
//            Tab("Categories", systemImage: "books.vertical", value: "categories") {
//                NavigationStack {
//                    CategoriesTable()
//                }
//            }
//            
////            Tab("Events", systemImage: "beach.umbrella") {
////                NavigationStack {
////                    EventsTable()
////                }
////            }
////            .badge(eventModel.invitations.count)
//            
//            
//            Tab("Accounts", systemImage: "creditcard", value: "accounts") {
//                NavigationStack {
//                    PayMethodsTable()
//                }
//            }
//            
//            Tab("Search", systemImage: "magnifyingglass", value: "search", role: .search) {
//                NavigationStack {
//                    AdvancedSearchView()
//                }
//            }
//            
//            Tab("More", systemImage: "ellipsis", value: "more") {
//                NavigationStack {
//                    moreTabList
//                }
//                .toolbar(toolbarVisibility, for: .tabBar)
//            }
//            .badge(plaidModel.banksWithIssues.count)
//        }
//        .tabViewStyle(.sidebarAdaptable)
//        
//        //.tabBarMinimizeBehavior(.onScrollDown)
////        .tabViewBottomAccessory {
////            switch sel {
////            case "calendar":
////                TextField("Search", text: .constant(""))
////            case "categories":
////                TextField("Search", text: .constant(""))
////            case "accounts":
////                TextField("Search", text: .constant(""))
////            case "search":
////                TextField("Search", text: .constant(""))
////            case "more":
////                TextField("Search", text: .constant(""))
////            default:
////                TextField("Search", text: .constant(""))
////            }
////        }
//    }
//    
//    var moreTabList: some View {
//        List {
////            NavigationLink(value: NavDest.paymentMethods) {
////                Label { Text("Payment Methods") } icon: { Image(systemName: "creditcard") }
////            }
//            
//            Section {
////                NavigationLink(value: NavDest.events) {
////                    Label { Text("Events") } icon: { Image(systemName: "beach.umbrella") }
////                }
//                
//                if AppState.shared.methsExist {
//                    NavigationLink(value: NavDest.repeatingTransactions) {
//                        Label { Text("Recurring Transactions") } icon: { Image(systemName: "repeat") }
//                    }
//                    
//                    NavigationLink(value: NavDest.keywords) {
//                        Label { Text("Rules") } icon: { Image(systemName: "textformat.abc.dottedunderline") }
//                    }
//                }
//            }
//            
//            Section("Plaid Integration") {
//                NavigationLink(value: NavDest.plaid) {
//                    Label { Text("Plaid") } icon: {
//                        if plaidModel.atLeastOneBankHasAnIssue {
//                            Image(systemName: "creditcard.trianglebadge.exclamationmark")
//                                .foregroundStyle(Color.theme == .orange ? .red : .orange)
//                        } else {
//                            Image(systemName: "building.columns")
//                        }
//                    }
//                }
//            }                        
//            
//            Section("Misc") {
//                NavigationLink(value: NavDest.toasts) {
//                    Label { Text("Notifications") } icon: { Image(systemName: "bell.badge") }
//                }
//                
//                if AppState.shared.user?.id == 1 {
//                    NavigationLink(value: NavDest.debug) {
//                        Label { Text("Debug") } icon: { Image(systemName: "ladybug") }
//                    }
//                    .badge(funcModel.loadTimes.count)
//                }
//                
//                
//                NavigationLink(value: NavDest.settings) {
//                    Label { Text("Settings") } icon: { Image(systemName: "gear") }
//                }
//            }
//        }
//        .listStyle(.plain)
//        .onAppear { toolbar(to: .visible) }
//        .navigationTitle("More")
//        //.navigationBarTitleDisplayMode(.inline)
//        .navigationDestination(for: NavDest.self) { dest in
//            switch dest {
//            case .repeatingTransactions:
//                RepeatingTransactionsTable()
//                    .onAppear { toolbar(to: .hidden) }
//                
//            case .paymentMethods:
//                PayMethodsTable()
//                    .onAppear { toolbar(to: .hidden) }
//                
//            case .events:
//                EventsTable()
//                    .onAppear { toolbar(to: .hidden) }
//                                               
//            case .keywords:
//                KeywordsTable()
//                    .onAppear { toolbar(to: .hidden) }
//                
//            case .settings:
//                SettingsView(showSettings: .constant(true))
//                    .onAppear { toolbar(to: .hidden) }
//                
//            case .debug:
//                DebugView()
//                    .onAppear { toolbar(to: .hidden) }
//                
//            case .plaid:
//                PlaidTable()
//                    .onAppear { toolbar(to: .hidden) }
//            
//            case .toasts:
//                ToastList()
//                    .onAppear { toolbar(to: .hidden) }
//                
//            default:
//                EmptyView()
//            }
//        }
//    }
//    
//    func toolbar(to visibility: Visibility) {
//        withAnimation {
//            toolbarVisibility = visibility
//        }
//    }
//}
//
//#endif
