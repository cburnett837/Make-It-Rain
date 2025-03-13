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
    
    //@FocusState private var focusedField: Int?
    //@FocusState private var searchFocus: Int?
    @Binding var selectedDay: CBDay?
    @Namespace private var monthNavigationNamespace
        
    var body: some View {
        Group {
            if AppState.shared.isIpad {
                navIpad
            } else {
                navIphone
            }
        }
    }
    
    
    var navIphone: some View {
        Group {
            @Bindable var navManager = NavigationManager.shared
            NavigationStack(path: $navManager.navPath) {
                NavSidebar(selectedDay: $selectedDay)
                    .navigationTitle("")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        if calModel.sMonth.actualNum != AppState.shared.todayMonth && calModel.sYear != AppState.shared.todayYear {
                            ToolbarItemGroup(placement: .topBarLeading) {
                                Button {
                                    navManager.selectedMonth = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
                                    calModel.sYear = AppState.shared.todayYear
                                    calModel.showMonth = true
                                } label: {
                                    Text("Now")
                                }
                            }
                        }
                        
                        ToolbarItemGroup(placement: .topBarTrailing) {
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
    }
    
    var navIpad: some View {
        Group {
            @Bindable var navManager = NavigationManager.shared
            NavigationSplitView {
                NavSidebar(selectedDay: $selectedDay)
                    .navigationTitle("")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        if calModel.sMonth.actualNum != AppState.shared.todayMonth && calModel.sYear != AppState.shared.todayYear {
                            ToolbarItemGroup(placement: .topBarLeading) {
                                Button {
                                    navManager.selectedMonth = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
                                    calModel.sYear = AppState.shared.todayYear
                                } label: {
                                    Text("Now")
                                }
                            }
                        }
                        
                        ToolbarItemGroup(placement: .topBarTrailing) {
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
                    CalendarViewPhone(enumID: selectedMonth, selectedDay: $selectedDay)
                        .if(AppState.shared.methsExist) {
                            $0.loadingSpinner(id: selectedMonth, text: "Loading…")
                        }
                    
                } else if let selection = navManager.selection {
                    switch navManager.selection {
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
                        
                    case .none:
                        EmptyView()
                        
                    default:
                        EmptyView()
                    }
                }
                
//                switch navManager.selection {
//                case .january, .february, .march, .april, .may, .june, .july, .august, .september, .october, .november, .december, .lastDecember, .nextJanuary:
//                    
//                    if let selection = navManager.selection {
//                        CalendarViewPhone(enumID: navManager.selection!, selectedDay: $selectedDay)
//                            .if(AppState.shared.methsExist) {
//                                $0.loadingSpinner(id: selection, text: "Loading…")
//                            }
//                    }
//                    
//                case .repeatingTransactions:
//                    RepeatingTransactionsTable()
//                    
//                case .paymentMethods:
//                    PayMethodsTable()
//                    
//                case .categories:
//                    CategoriesTable()
//                    
//                case .keywords:
//                    KeywordsTable()
//                    
//                case .search:
//                    AdvancedSearchView()
//                    
//                case .analytics:
//                    Text("analytics")
//                    
//                case .events:
//                    EventsTable()
//                    
//                case .settings:
//                    SettingsView(showSettings: .constant(true))
//                    
//                case .none:
//                    EmptyView()
//                    
//                @unknown default:
//                    EmptyView()
//                }
            }
        }
    }
}

#endif
