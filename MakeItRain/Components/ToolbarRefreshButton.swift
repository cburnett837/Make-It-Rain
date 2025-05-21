//
//  ToolbarRefreshButton.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/6/24.
//

import SwiftUI

struct ToolbarRefreshButton: View {
    @Environment(FuncModel.self) var funcModel
    @Environment(CalendarModel.self) private var calModel
    
    var body: some View {
        Button {
            funcModel.isLoading = true
            funcModel.refreshTask?.cancel()
            funcModel.refreshTask = Task {
                LoadingManager.shared.showInitiallyLoadingSpinner = true
                calModel.months.forEach { month in
                    month.days.removeAll()
                    month.budgets.removeAll()
                }
                calModel.prepareMonths()
                await funcModel.downloadEverything(setDefaultPayMethod: false, createNewStructs: true, refreshTechnique: .viaButton)
            }
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
                //.opacity(funcModel.isLoading ? 0 : 1)
                .symbolEffect(.rotate, options: SymbolEffectOptions.repeat(.continuous).speed(3), isActive: funcModel.isLoading)
                //.symbolEffect(.rotate, options: SymbolEffectOptions.repeat(.continuous), value: funcModel.isLoading)
            
        }
        //.disabled(calModel.refreshTask != nil)
        .help("Refresh all data from the server")
        .disabled(funcModel.isLoading)
//        .overlay {
//            ProgressView()
//                .tint(.none)
//                .opacity(funcModel.isLoading ? 1 : 0)
//        }
    }
}
