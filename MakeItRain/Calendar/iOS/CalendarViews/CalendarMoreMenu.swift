//
//  CalendarMoreMenu.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/3/25.
//

import SwiftUI
#if os(iOS)
struct CalendarMoreMenu: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarProps.self) private var calProps
    @Environment(CalendarModel.self) private var calModel
    
    /// Retain this here so we don't lose the data when we leave the sheet
    @State private var categoryAnalysisModel = CategoryInsightsModel()
    
    var body: some View {
        @Bindable var calProps = calProps
        Menu {
            Section("Analytics") {
                dashboardSheetButton
                analysisSheetButton
                budgetSheetButton
                transactionListSheetButton
            }
            
            Section("Tools") {
                multiSelectButton
            }
            
            Section("More") {
                refreshButton
                settingsSheetButton
            }
        } label: {
            Image(systemName: "ellipsis")
                .schemeBasedForegroundStyle()
                //.symbolEffect(.rotate, options: SymbolEffectOptions.repeat(.continuous).speed(3), isActive: funcModel.isLoading)
                .tint(.none)
        }
        .sheet(isPresented: $calProps.showDashboardSheet) {
            CalendarDashboard()
        }
        .sheet(isPresented: $calProps.showAnalysisSheet) {
            CategoryInsightsSheet(showAnalysisSheet: $calProps.showAnalysisSheet, model: categoryAnalysisModel)
        }
        .sheet(isPresented: $calProps.showTransactionListSheet) {
            TransactionListView(showTransactionListSheet: $calProps.showTransactionListSheet)
        }
        .sheet(isPresented: $calProps.showCalendarOptionsSheet) {
            CalendarOptionsSheet(selectedDay: $calProps.selectedDay)
        }
        .sheet(isPresented: $calProps.showBudgetSheet) {
            BudgetTable()
        }
    }
    
    
    var dashboardSheetButton: some View {
        Button {
            if AppState.shared.isIphone {
                /// Sheet is in ``CalendarMoreMenu``.
                calProps.showDashboardSheet = true
            } else {
                /// Inspector is in ``RootViewPad``.
                calProps.inspectorContent = .dashboard
                calProps.showInspector = true
            }
        } label: {
            Label("Dashboard", systemImage: "rectangle.grid.1x3.fill")
        }
    }
    
    
    var budgetSheetButton: some View {
        Button {
            if AppState.shared.isIphone {
                /// Sheet is in ``CalendarMoreMenu``.
                calProps.showBudgetSheet = true
            } else {
                /// Inspector is in ``RootViewPad``.
                calProps.inspectorContent = .budgets
                calProps.showInspector = true
            }
        } label: {
            Label("Budgets", systemImage: "chart.pie")
        }
    }
    
    
    var analysisSheetButton: some View {
        Button {
            if AppState.shared.isIphone {
                /// Sheet is in ``CalendarMoreMenu``.
                calProps.showAnalysisSheet = true
            } else {
                /// Inspector is in ``RootViewPad``.
                calProps.inspectorContent = .analysisSheet
                calProps.showInspector = true
            }
        } label: {
            Label("Insights", systemImage: "chart.bar.doc.horizontal")
        }
    }
    
    
    var transactionListSheetButton: some View {
        Button {
            if AppState.shared.isIphone {
                /// Sheet is in ``CalendarMoreMenu``.
                calProps.showTransactionListSheet = true
            } else {
                /// Inspector is in ``RootViewPad``.
                calProps.inspectorContent = .transactionList
                calProps.showInspector = true
            }
        } label: {
            Label("All Transactions", systemImage: "list.bullet")
        }
    }
    
    
    var multiSelectButton: some View {
        Button {
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

