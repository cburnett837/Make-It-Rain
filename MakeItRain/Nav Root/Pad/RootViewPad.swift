//
//  RootViewPad.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/24/25.
//

import SwiftUI

enum CalendarInspectorContent {
    case budgetTable, analysisSheet, transactionList, plaidTransactions, multiSelectOptions, smartTransactionsWithIssues
}

#if os(iOS)
struct RootViewPad: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(CalendarProps.self) var calProps
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(CategoryModel.self) var catModel
    @Environment(KeywordModel.self) var keyModel
    @Environment(RepeatingTransactionModel.self) var repModel
    @Environment(EventModel.self) var eventModel
    @Environment(PlaidModel.self) var plaidModel
    
    //@FocusState private var focusedField: Int?
    //@FocusState private var searchFocus: Int?
    let monthNavigationNamespace: Namespace.ID
        
    //@State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
        
    var body: some View {
        @Bindable var navManager = NavigationManager.shared
        @Bindable var calProps = calProps
        
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
        .inspector(isPresented: $calProps.showInspector) {
            if let content = calProps.inspectorContent {
                Group {
                    switch content {
                    case .budgetTable:
                        CalendarDashboard()
                        
                    case .analysisSheet:
                        AnalysisSheet(showAnalysisSheet: $calProps.showInspector)
                            .onDisappear { calModel.isInMultiSelectMode = false }
                        
                    case .transactionList:
                        TransactionListView(showTransactionListSheet: $calProps.showInspector)
                        
                    case .plaidTransactions:
                        PlaidTransactionOverlay(showInspector: $calProps.showInspector)
                        
                    case .multiSelectOptions:
                        MultiSelectTransactionOptionsSheet(showInspector: $calProps.showInspector)
                        
                    case .smartTransactionsWithIssues:
                        SmartTransactionsWithIssuesOverlay(showInspector: $calProps.showInspector)
                    }
                }
                .inspectorColumnWidth(min: 300, ideal: 450, max: 600)
                .presentationBackground(.thinMaterial)
                /// Clear multi select mode since you can navigate to the analytic inspector via the multi select inspector.
                
            } else {
                /// Have a fallback view with options in case the inspector gets left open.
                /// Inspector state is retained by the SwiftUI framework.
                noInspectorContentView
            }
        }
        /// Hide the inspector when leaving the calendar.
        .onChange(of: navManager.selection) { old, new in
            calProps.showInspector = false
            calProps.inspectorContent = nil
        }
    }
    
    
    var noInspectorContentView: some View {
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                Button("Insights") { calProps.inspectorContent = .analysisSheet }
                Button("Transactions") { calProps.inspectorContent = .transactionList }
                Button("Multi-select") {
                    calModel.isInMultiSelectMode.toggle()
                    calProps.inspectorContent = .multiSelectOptions
                }
            }
            .navigationTitle("Inspector")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        calProps.showInspector = false
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                }
            }
            #endif
        }
        .inspectorColumnWidth(min: 200, ideal: 250, max: 300)
    }
}

#endif
