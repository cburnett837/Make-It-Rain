//
//  CategoryAnalyticChartRefreshButton.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/10/25.
//


import SwiftUI
import Charts

struct CatChartRefreshButton: View {
    @Bindable var model: CatChartViewModel
    
    var body: some View {
        Button {
            Task {
                model.fetchYearStart = AppState.shared.todayYear - 10
                model.fetchYearEnd = AppState.shared.todayYear
                //data.removeAll()
                //model.isLoadingHistory = true
                await model.fetchHistory(setChartAsNew: true)
            }
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
        }
        .tint(.none)
        .symbolEffect(.rotate, options: SymbolEffectOptions.repeat(.continuous).speed(3), isActive: model.isLoadingHistory)
        .symbolEffect(.rotate, options: SymbolEffectOptions.repeat(.continuous).speed(3), isActive: model.isLoadingMoreHistory)
        #if os(macOS)
        .buttonStyle(.roundMacButton)
        #endif
    }
}
