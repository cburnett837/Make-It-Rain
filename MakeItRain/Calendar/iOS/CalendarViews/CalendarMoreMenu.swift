//
//  CalendarMoreMenu.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/3/25.
//

import SwiftUI

struct CalendarMoreMenu: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarProps.self) private var calProps
    @Environment(CalendarModel.self) private var calModel
    
    var body: some View {
        @Bindable var calProps = calProps
        Menu {
            Section("Analytics") {
                budgetSheetButton
                analysisSheetButton
            }
            
            Section {
                transactionListSheetButton
                multiSelectButton
            }
            
            Section {
                refreshButton
                settingsSheetButton
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                //.symbolEffect(.rotate, options: SymbolEffectOptions.repeat(.continuous).speed(3), isActive: funcModel.isLoading)
                .tint(.none)
        }
        .sheet(isPresented: $calProps.showBudgetSheet) {
            CalendarDashboard()
        }
        .sheet(isPresented: $calProps.showAnalysisSheet) {
            AnalysisSheet(showAnalysisSheet: $calProps.showAnalysisSheet)
        }
        .sheet(isPresented: $calProps.showTransactionListSheet) {
            TransactionListView(showTransactionListSheet: $calProps.showTransactionListSheet)
        }
        .sheet(isPresented: $calProps.showCalendarOptionsSheet) {
            CalendarOptionsSheet(selectedDay: $calProps.selectedDay)
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
            Label { Text("Multi-Select") } icon: { Image(systemName: "rectangle.and.hand.point.up.left.filled") }
        }
    }
    
    
    var budgetSheetButton: some View {
        Button {
            if AppState.shared.isIphone {
                /// Sheet is in ``CalendarMoreMenu``.
                calProps.showBudgetSheet = true
            } else {
                /// Inspector is in ``RootViewPad``.
                calProps.inspectorContent = .budgetTable
                calProps.showInspector = true
            }
        } label: {
            Label { Text("Dashboard") } icon: { Image(systemName: "chart.pie") }
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
            Label { Text("Insights") } icon: { Image(systemName: "chart.bar.doc.horizontal") }
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
            Label { Text("Transaction List") } icon: { Image(systemName: "list.bullet") }
        }
    }
    
    
    var settingsSheetButton: some View {
        Button {
            /// Sheet is in ``CalendarMoreMenu``.
            calProps.showCalendarOptionsSheet = true
        } label: {
            Label { Text("Settings") } icon: { Image(systemName: "gear") }
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
}
