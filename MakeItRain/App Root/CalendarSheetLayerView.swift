//
//  CalendarSheetLayerView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/6/25.
//


import SwiftUI
#if os(iOS)
import UIKit
#endif

struct CalendarSheetLayerView: View {
    @Local(\.colorTheme) var colorTheme
    @Environment(CalendarModel.self) private var calModel
    
    let monthNavigationNamespace: Namespace.ID
        
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .ignoresSafeArea(.all)
            .overlay(overlayRectangle)            
    }
    
    var overlayRectangle: some View {
        @Bindable var calModel = calModel
        return Rectangle()
            .fill(Color.clear)
            .ignoresSafeArea(.all)
            #if os(iOS)
            .fullScreenCover(isPresented: $calModel.showMonth) { calendarSheet }
            #endif
    }
    
    #if os(iOS)
    var calendarSheet: some View {
        Group {
            if let selectedMonth = NavigationManager.shared.selectedMonth {
                if NavDestination.justMonths.contains(selectedMonth) {
                    CalendarViewPhone(enumID: selectedMonth)
                        .tint(Color.fromName(colorTheme))
                        .navigationTransition(.zoom(sourceID: selectedMonth, in: monthNavigationNamespace))
                        .if(AppState.shared.methsExist) {
                            $0.loadingSpinner(id: selectedMonth, text: "Loading…")
                        }
                }
            }
        }
    }
    #endif
}
