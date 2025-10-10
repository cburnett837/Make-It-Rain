//
//  NowButton.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/24/25.
//

import SwiftUI

struct NowButton: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(CalendarModel.self) var calModel
    
    var body: some View {
        Button {
            withAnimation {
                NavigationManager.shared.selection = nil
                NavigationManager.shared.selectedMonth = NavDestination.getMonthFromInt(AppState.shared.todayMonth)
                calModel.sYear = AppState.shared.todayYear
                if !AppState.shared.isIpad {
                    calModel.showMonth = true
                }
                
            }
        } label: {
            Text("Now")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }
}
