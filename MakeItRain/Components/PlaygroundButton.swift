//
//  PlaygroundButton.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/8/25.
//


import SwiftUI

#if os(macOS)
struct PlaygroundButton: View {
    @Environment(CalendarModel.self) private var calModel
    
    
    var body: some View {
        @Bindable var navManager = NavigationManager.shared
        Button("Playground") {
            calModel.sYear = 1900
            navManager.selection = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
            
            Task {
                if let month = calModel.months.filter({ $0.enumID == navManager.selection }).first {
                    calModel.sMonth = month
                } else {
                    fatalError("Could not determine month")
                }
            }
            
        }
        .toolbarBorder()
        .help("View a playground where you can test things out.")
    }
}
#endif
