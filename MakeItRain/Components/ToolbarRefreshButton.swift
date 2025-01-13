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
            Task {
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
        }        
        //.disabled(calModel.refreshTask != nil)
        .help("Refresh all data from the server")
    }
}
