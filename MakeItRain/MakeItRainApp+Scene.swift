//
//  MakeItRainApp+Scene.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/25/25.
//

import SwiftUI

extension MakeItRainApp {
    #if os(macOS)
    @SceneBuilder
    var macAlertAndToastOverlayWindow: some Scene {
        Window("", id: MacAlertAndToastOverlay.id) {
            MacAlertAndToastOverlay()
                .environment(funcModel)
                .environment(calModel)
                .environment(payModel)
                .environment(catModel)
                .environment(keyModel)
                .environment(repModel)
                .environment(plaidModel)
                .environment(calProps)
                .environment(dataChangeTriggers)
        }
        .windowStyle(.hiddenTitleBar)
        .auxilaryWindow()
    }
    
    
    @SceneBuilder
    var dashboardWindow: some Scene {
        Window("Budget", id: "budgetWindow") {
            CalendarDashboard()
                .frame(minWidth: 300, minHeight: 200)
                .environment(calModel)
                .environment(payModel)
                .environment(catModel)
                .environment(keyModel)
                .environment(repModel)
                .environment(plaidModel)
                .environment(calProps)
                .environment(dataChangeTriggers)
        }
        .auxilaryWindow()
    }
        
    @SceneBuilder
    var plaidWindow: some Scene {
        Window("Pending Plaid Transactions", id: "pendingPlaidTransactions") {
            PlaidTransactionOverlay(showInspector: .constant(true), navPath: .constant(.init()))
                .frame(minWidth: 300, minHeight: 200)
                .environment(calModel)
                .environment(payModel)
                .environment(plaidModel)
                .environment(catModel)
                .environment(keyModel)
                .environment(calProps)
                .environment(dataChangeTriggers)
        }
        .auxilaryWindow()
    }

    @SceneBuilder
    var insightsWindow: some Scene {
        Window("Category Analysis", id: "analysisSheet") {
            Text("not ready yet")
//            CategoryInsightsSheet(showAnalysisSheet: .constant(true))
//                .frame(minWidth: 300, minHeight: 500)
//                .environment(funcModel)
//                .environment(calModel)
//                .environment(payModel)
//                .environment(catModel)
//                .environment(keyModel)
//                .environment(repModel)
//                .environment(plaidModel)
//                .environment(calProps)
//                .environment(dataChangeTriggers)
//                //.environment(mapModel)
        }
        .auxilaryWindow()
    }

    @SceneBuilder
    var multiSelectWindow: some Scene {
        Window("Multi-Select", id: "multiSelectSheet") {
            MultiSelectTransactionOptionsSheet(showInspector: .constant(true), navPath: .constant(NavigationPath()))
                .frame(minHeight: 500)
                .frame(width: 250)
                .environment(funcModel)
                .environment(calModel)
                .environment(payModel)
                .environment(catModel)
                .environment(keyModel)
                .environment(repModel)
                .environment(plaidModel)
                .environment(calProps)
                .environment(dataChangeTriggers)
        }
        .auxilaryWindow()
    }

    @SceneBuilder
    var monthlyPlaceholderWindow: some Scene {
        WindowGroup("MonthlyWindowPlaceHolder", id: "monthlyWindow", for: NavDestination?.self) { dest in
            let width = ((NSScreen.main?.visibleFrame.width ?? 500) / 3) * 2
            let height = ((NSScreen.main?.visibleFrame.height ?? 500) / 4) * 3
                        
            if let dest = dest.wrappedValue {
                CalendarViewMac(enumID: dest!, isInWindow: true)
                    /// Frame is required to prevent the window from entering full screen if the main window is full screen
                    .frame(
                        minWidth: width,
                        maxWidth: (NSScreen.main?.visibleFrame.width ?? 500) - 1,
                        minHeight: height,
                        maxHeight: (NSScreen.main?.visibleFrame.height ?? 500) - 1
                    )
                    .environment(funcModel)
                    .environment(calModel)
                    .environment(payModel)
                    .environment(catModel)
                    .environment(keyModel)
                    .environment(repModel)
                    .environment(plaidModel)
                    .environment(calProps)
                    .environment(dataChangeTriggers)
                    //.environment(mapModel)
                    .onAppear {
                        if let window = NSApp.windows.first(where: { $0.title.contains("MonthlyWindowPlaceHolder") }) {
                            window.title = AppState.shared.monthlySheetWindowTitle
                        }
                    }
                    .onDisappear {
                        calModel.windowMonth = nil
                    }
            }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.expanded)
        .auxilaryWindow(openIn: .center)
    }

    @SceneBuilder
    var settingsWindow: some Scene {
        Settings {
            SettingsView(showSettings: .constant(false))
                .frame(maxWidth: 400, minHeight: 600)
                .environment(funcModel)
                .environment(calModel)
                .environment(payModel)
                .environment(catModel)
                .environment(keyModel)
                .environment(repModel)
                .environment(plaidModel)
                .environment(calProps)
                .environment(dataChangeTriggers)
                //.environment(mapModel)
        }
    }


    #endif
}
