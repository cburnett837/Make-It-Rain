//
//  CalendarMoreMenu.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/3/25.
//

import SwiftUI
#if os(iOS)
struct CalendarMoreMenu: View {
    @Local(\.phoneLineItemDisplayItem) var phoneLineItemDisplayItem
    @Environment(\.colorScheme) var colorScheme
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarProps.self) private var calProps
    @Environment(CalendarModel.self) private var calModel
    
    var body: some View {
        let _ = Self._printChanges()
        @Bindable var calProps = calProps
        Menu {
            Section("Analytics") {
                ControlGroup {
                    dashboardSheetButton
                    //analysisSheetButton
                    budgetSheetButton
                    transactionListSheetButton
                }
                //transactionListSheetButton
            }
            
            Section("Tools") {
                multiSelectButton
                exportCsvButton
            }
            
            Section("More") {
                refreshButton
                settingsSheetButton
            }
        } label: {
            Label("More", systemImage: "ellipsis")
            //.schemeBasedTint()
            //.schemeBasedForegroundStyle()

//            Label("More", systemImage: "ellipsis")
//                .schemeBasedTint()
            //Image(systemName: "ellipsis")
                //.schemeBasedForegroundStyle()
                //.symbolEffect(.rotate, options: SymbolEffectOptions.repeat(.continuous).speed(3), isActive: funcModel.isLoading)
                //.tint(.none)
        }
        .schemeBasedTint()
//        .sheet(isPresented: $calProps.showDashboardSheet) {
//            CalendarDashboard()
//        }
//        .sheet(isPresented: $calProps.showAnalysisSheet) {
//            CategoryInsightsSheet(showAnalysisSheet: $calProps.showAnalysisSheet, model: categoryAnalysisModel)
//        }
        .sheet(isPresented: $calProps.showTransactionListSheet) {
            TransactionListView(showTransactionListSheet: $calProps.showTransactionListSheet)
        }
        .sheet(isPresented: $calProps.showCalendarOptionsSheet) {
            CalendarOptionsSheet(selectedDay: $calProps.selectedDay)
        }
//        .sheet(isPresented: $calProps.showBudgetSheet) {
//            BudgetTable()
//        }
    }
    
    
    var dashboardSheetButton: some View {
        Button {
            if AppState.shared.isIphone {
                /// Sheet is in ``CalendarMoreMenu``.
                //calProps.showDashboardSheet = true
                calProps.navPath.append(CalendarNavDest.dashboard)
            } else {
                /// Inspector is in ``RootViewPad``.
                calProps.inspectorContent = .dashboard
                calProps.showInspector = true
            }
        } label: {
            Label("Dashboard", systemImage: "list.bullet.below.rectangle")
        }
    }
    
    
    var budgetSheetButton: some View {
        Button {
            if AppState.shared.isIphone {
                /// Sheet is in ``CalendarMoreMenu``.
                //calProps.showBudgetSheet = true
                calProps.navPath.append(CalendarNavDest.budgets)
            } else {
                /// Inspector is in ``RootViewPad``.
                calProps.inspectorContent = .budgets
                calProps.showInspector = true
            }
        } label: {
            Label("Budgets", systemImage: "chart.bar")
        }
    }
    
    
//    var analysisSheetButton: some View {
//        Button {
//            if AppState.shared.isIphone {
//                /// Sheet is in ``CalendarMoreMenu``.
//                calProps.showAnalysisSheet = true
//            } else {
//                /// Inspector is in ``RootViewPad``.
//                calProps.inspectorContent = .analysisSheet
//                calProps.showInspector = true
//            }
//        } label: {
//            Label("Insights", systemImage: "chart.bar.doc.horizontal")
//        }
//    }
    
    
    var transactionListSheetButton: some View {
        Button {
            if AppState.shared.isIphone {
                /// Sheet is in ``CalendarMoreMenu``.
                //calProps.showTransactionListSheet = true
                calProps.navPath.append(CalendarNavDest.transactionList)
            } else {
                /// Inspector is in ``RootViewPad``.
                calProps.inspectorContent = .transactionList
                calProps.showInspector = true
            }
        } label: {
            Label("Trans List", systemImage: "list.bullet")
        }
    }
                

    var multiSelectButton: some View {
        Button {
            
            if phoneLineItemDisplayItem != .both {
                calProps.phoneLineItemDisplayItemWhenMultiSelectWasOpened = phoneLineItemDisplayItem
                withAnimation {
                    phoneLineItemDisplayItem = .both
                }
            }
            
            calModel.sCategoriesForAnalysis.removeAll()
            calModel.multiSelectTransactions.removeAll()
            
            if AppState.shared.isIphone {
                /// Bottom panel is in ``CalendarViewPhone``.
                withAnimation {
                    calModel.isInMultiSelectMode = true
                    calProps.bottomPanelContent = .multiSelectOptions
                }
            } else {
                calModel.isInMultiSelectMode = true
                /// Inspector is in ``RootViewPad``.
                calProps.inspectorContent = .multiSelectOptions
                calProps.showInspector = true
            }
        } label: {
            Label("Multi-Select", systemImage: "rectangle.and.hand.point.up.left.filled")
        }
    }
    
    
    var refreshButton: some View {
        Button {
            funcModel.isLoading = true
            funcModel.refreshTask?.cancel()
            funcModel.refreshTask = Task {
                calModel.prepareForRefresh()
                let targetDay = calModel.sMonth.days.filter { $0.dateComponents?.day == AppState.shared.todayDay }.first
                calProps.selectedDay = targetDay
                                
                await funcModel.downloadEverything(setDefaultPayMethod: false, createNewStructs: true, refreshTechnique: .viaButton)
            }
        } label: {
            Label {
                Text(funcModel.isLoading ? "Refreshing…" : "Refresh")
            } icon: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .symbolEffect(.rotate, options: SymbolEffectOptions.repeat(.continuous).speed(3), isActive: funcModel.isLoading)
            }
        }
        .disabled(funcModel.isLoading)
    }
    
    
    @ViewBuilder
    var exportCsvButton: some View {
        let rows = calModel.sMonth
            .justTransactions
            .filter { $0.active && $0.isPermitted }
            .map { $0.convertToCsvRecord() }
        
        ExportCsvButton(
            fileName: "Transactions-\(calModel.sMonth.name)-\(calModel.sYear).csv",
            headers: CBTransaction.getCsvHeaders(),
            rows: rows
        ) {
            Label("Export CSV", systemImage: "tablecells")
        }
    }
    
    
    var settingsSheetButton: some View {
        Button {
            /// Sheet is in ``CalendarMoreMenu``.
            calProps.showCalendarOptionsSheet = true
        } label: {
            Label("Settings", systemImage: "gear")
        }
    }
}
#endif

