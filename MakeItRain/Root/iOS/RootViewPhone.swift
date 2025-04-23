//
//  RootViewIphone.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/16/24.
//

import SwiftUI

#if os(iOS)
struct RootViewPhone: View {
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(KeywordModel.self) var keyModel
    @Environment(RepeatingTransactionModel.self) var repModel
    @Environment(EventModel.self) var eventModel
    
    //@FocusState private var focusedField: Int?
    //@FocusState private var searchFocus: Int?
    @Namespace private var monthNavigationNamespace
    
    @State private var showPendingInviteSheet = false
    
    //@State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
        
    var body: some View {
        Group {
            if AppState.shared.isIpad {
                navIpad
            } else {
                navIphone
            }
        }
        .sheet(isPresented: $showPendingInviteSheet) {
            EventPendingInviteView()
        }
    }
    
    
    var navIphone: some View {
        Group {
            @Bindable var navManager = NavigationManager.shared
            TabView {
                Tab("Calendar", systemImage: "calendar") {
                    
                    
                    NavigationStack(path: $navManager.navPath) {
                        NavSidebar()
                            .navigationTitle("")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItemGroup(placement: .topBarLeading) {
                                    if calModel.sMonth.actualNum != AppState.shared.todayMonth && calModel.sYear != AppState.shared.todayYear {
                                        nowButton
                                    }
                                    
                                    ToolbarLongPollButton()
                                }
                                
                                ToolbarItemGroup(placement: .topBarTrailing) {
                                    if !eventModel.invitations.isEmpty {
                                        showEventInviteButton
                                    }
                                    NavigationLink(value: NavDestination.search) {
                                        Image(systemName: "magnifyingglass")
                                    }
                                    .matchedTransitionSource(id: NavDestination.search, in: monthNavigationNamespace)
                                    
                                    NavigationLink(value: NavDestination.settings) {
                                        Image(systemName: "gear")
                                    }
                                    .matchedTransitionSource(id: NavDestination.settings, in: monthNavigationNamespace)
                                }
                            }
                            .navigationDestination(for: NavDestination.self) { dest in
                                switch dest {
                                case .repeatingTransactions:
                                    RepeatingTransactionsTable()
                                    
                                case .paymentMethods:
                                    PayMethodsTable()
                                    
                                case .categories:
                                    CategoriesTable()
                                    
                                case .keywords:
                                    KeywordsTable()
                                    
                                case .search:
                                    AdvancedSearchView()
                                        .navigationTransition(.zoom(sourceID: NavDestination.search, in: monthNavigationNamespace))
                                    
                                case .analytics:
                                    Text("analytics")
                                    
                                case .events:
                                    EventsTable()
                                    
                                case .settings:
                                    SettingsView(showSettings: .constant(true))
                                        .navigationTransition(.zoom(sourceID: NavDestination.settings, in: monthNavigationNamespace))
                                    
                                default:
                                    EmptyView()
                                }
                            }
                    }
                }
                
                Tab("Categories", systemImage: "books.vertical") {
                    NavigationStack {
                        CategoriesTable()
                    }
                }
                
                
                Tab("Events", systemImage: "beach.umbrella") {
                    NavigationStack {
                        EventsTable()
                    }
                }
                
                Tab("Search", systemImage: "magnifyingglass") {
                    NavigationStack {
                        AdvancedSearchView()
                    }
                }
                
                Tab("Payment Methods", systemImage: "creditcard") {
                    NavigationStack {
                        PayMethodsTable()
                    }
                }
                
                Tab("Reoccuring Transactions", systemImage: "repeat") {
                    NavigationStack {
                        RepeatingTransactionsTable()
                    }
                }
                
                Tab("Keywords", systemImage: "textformat.abc.dottedunderline") {
                    NavigationStack {
                        KeywordsTable()
                    }
                }
                
                Tab("Settings", systemImage: "gear") {
                    NavigationStack {
                        SettingsView(showSettings: .constant(true))
                    }
                }
            }
        }
    }
    
    
    var navIpad: some View {
        Group {
            @Bindable var navManager = NavigationManager.shared
            NavigationSplitView(columnVisibility: $navManager.columnVisibility) {
                NavSidebar()
                    .navigationTitle("")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarLeading) {
                            if calModel.sMonth.actualNum != AppState.shared.todayMonth && calModel.sYear != AppState.shared.todayYear {
                                nowButton
                            }
                            
                            ToolbarLongPollButton()
                        }
                        
                        
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            if !eventModel.invitations.isEmpty {
                                showEventInviteButton
                            }
                            Button {
                                NavigationManager.shared.selectedMonth = nil
                                NavigationManager.shared.selection = .search
                            } label: {
                                Image(systemName: "magnifyingglass")
                            }
                            
                            Button {
                                NavigationManager.shared.selectedMonth = nil
                                NavigationManager.shared.selection = .settings
                            } label: {
                                Image(systemName: "gear")
                            }
                        }
                    }
            } detail: {
                if let selectedMonth = navManager.selectedMonth, calModel.isShowingFullScreenCoverOnIpad == false {
                    CalendarViewPhone(enumID: selectedMonth)
                        .if(AppState.shared.methsExist) {
                            $0.loadingSpinner(id: selectedMonth, text: "Loading…")
                        }
                    
                } else if let selection = navManager.selection {
                    switch selection {
                    case .repeatingTransactions:
                        RepeatingTransactionsTable()
                        
                    case .paymentMethods:
                        PayMethodsTable()
                        
                    case .categories:
                        CategoriesTable()
                        
                    case .keywords:
                        KeywordsTable()
                        
                    case .search:
                        AdvancedSearchView()
                        
                    case .analytics:
                        Text("analytics")
                        
                    case .events:
                        EventsTable()
                        
                    case .settings:
                        SettingsView(showSettings: .constant(true))
                        
                    default:
                        EmptyView()
                    }
                }
            }
        }
    }
    
    
    var nowButton: some View {
        Button {
            withAnimation {
                NavigationManager.shared.selection = nil
                NavigationManager.shared.selectedMonth = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
                calModel.sYear = AppState.shared.todayYear
                if !AppState.shared.isIpad {
                    calModel.showMonth = true
                }
                
            }
        } label: {
            Text("Now")
        }
    }
    
    var showEventInviteButton: some View {
        Button {
            showPendingInviteSheet = true
        } label: {
            Image(systemName: "envelope.badge")
                .foregroundStyle(.red)
        }
    }
}

#endif
