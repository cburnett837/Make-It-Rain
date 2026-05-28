//
//  RootViewPad.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/24/25.
//

import SwiftUI

enum CalendarInspectorContent {
    case dashboard, transactionList, plaidTransactions, multiSelectOptions, smartTransactionsWithIssues, budgets, overviewDay, paymentMethods, dashboardTransactionList
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
    @Environment(PlaidModel.self) var plaidModel
    @Environment(AppStore.self) var store
    
    
    //@FocusState private var focusedField: Int?
    //@FocusState private var searchFocus: Int?
        
    /// Used to navigate to additional pages in the bottom panel. (Plaid transactions reject all before date)
    //@State private var navPath = NavigationPath()
    @State private var navPath: [NavDest] = []
    //@State private var categoryAnalysisModel = CivViewModel()
    //@State private var overviewAnalysisModel = CivViewModel()
    @State private var moreNavPath = NavigationPath()

    
    //@State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
        
    var body: some View {
        //let _ = Self._printChanges()
        @Bindable var navManager = NavigationManager.shared
        @Bindable var calProps = calProps
        
        NavigationSplitView(columnVisibility: $navManager.columnVisibility) {
            NavSidebarPad()
        } detail: {
            if let selectedMonth = navManager.selectedMonth, calModel.isShowingFullScreenCoverOnIpad == false {
                //CalendarViewPhone(enumID: selectedMonth, store: store)
                CalendarViewPhone(enumID: selectedMonth)
                    .if(AppState.shared.methsExist) {
                        $0.calendarLoadingSpinner(id: selectedMonth, text: "Loading…")
                    }
                
            } else if let dest = navManager.selection {
                NavDest.view(for: dest, navPath: $moreNavPath)                
            }
        }
        .inspector(isPresented: $calProps.showInspector) {
            if let content = calProps.inspectorContent {
                inspectorContent(content)
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
    
    
    @ViewBuilder func inspectorContent(_ content: CalendarInspectorContent) -> some View {
        @Bindable var calProps = calProps
        Group {
            switch content {
            case .dashboard:
                Text("Hey")
                //CategoryInsightsViewWrapperIpad(showAnalysisSheet: $calProps.showInspector, model: categoryAnalysisModel, overviewModel: overviewAnalysisModel)
                    //.onDisappear { calModel.isInMultiSelectMode = false }
                
            case .dashboardTransactionList:
                Text("Transaction List")
                
            case .transactionList:
                TransactionListView(showTransactionListSheet: $calProps.showInspector)
                
            case .plaidTransactions:
                PlaidTransactionOverlay(showInspector: $calProps.showInspector, navPath: $navPath)
                
            case .multiSelectOptions:
                MultiSelectTransactionOptionsSheet(showInspector: $calProps.showInspector, navPath: $navPath)
                
            case .smartTransactionsWithIssues:
                SmartTransactionsWithIssuesOverlay(showInspector: $calProps.showInspector)
                
            case .budgets:
                Text("Budgets")
                //BudgetTable(navPath: $navPath)
                
            case .overviewDay:
                DayOverviewView(day: $calProps.overviewDay, showInspector: $calProps.showInspector)
                
            case .paymentMethods:
                Text("Not available")
            }
        }
        //.toolbarRole(.navigationStack)
        .inspectorColumnWidth(min: 300, ideal: 450, max: 600)
        .presentationBackground(.thinMaterial)
    }
    
    
    var noInspectorContentView: some View {
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                Button { calProps.inspectorContent = .dashboard } label: { Label("Dashboard", systemImage: "rectangle.grid.1x3.fill") }
                Button { calProps.inspectorContent = .budgets } label: { Label("Budgets", systemImage: "chart.pie") }
                Button { calProps.inspectorContent = .transactionList } label: { Label("All Transactions", systemImage: "list.bullet") }
                                
                Section {
                    Button {
                        calModel.isInMultiSelectMode = true
                        calProps.inspectorContent = .multiSelectOptions
                    } label: {
                        Label("Multi-Select", systemImage: "rectangle.and.hand.point.up.left.filled")
                    }
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
                            .schemeBasedForegroundStyle()
                    }
                }
            }
            #endif
        }
        .inspectorColumnWidth(min: 200, ideal: 250, max: 300)
    }
}

#endif
