//
//  RootViewPad.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/24/25.
//

import SwiftUI

#if os(iOS)
struct RootViewPad: View {
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(KeywordModel.self) var keyModel
    @Environment(RepeatingTransactionModel.self) var repModel
    @Environment(EventModel.self) var eventModel
    
    //@FocusState private var focusedField: Int?
    //@FocusState private var searchFocus: Int?
    let monthNavigationNamespace: Namespace.ID
        
    //@State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
        
    var body: some View {
        @Bindable var navManager = NavigationManager.shared
        NavigationSplitView(columnVisibility: $navManager.columnVisibility) {
            NavSidebarPad(monthNavigationNamespace: monthNavigationNamespace)
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
                    
                case .debug:
                    DebugView()
                    
                case .plaid:
                    PlaidTable()
                    
                default:
                    EmptyView()
                }
            }
        }
    }
}

#endif
