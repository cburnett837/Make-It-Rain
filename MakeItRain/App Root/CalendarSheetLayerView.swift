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
//
//struct SafeAreaInsetsKey: EnvironmentKey {
//    static let defaultValue: EdgeInsets = EdgeInsets()
//}
//
//extension EnvironmentValues {
//    var safeAreaInsets: EdgeInsets {
//        get { self[SafeAreaInsetsKey.self] }
//        set { self[SafeAreaInsetsKey.self] = newValue }
//    }
//}

struct CalendarSheetLayerView: View {
    //@Local(\.colorTheme) var colorTheme
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
            .fullScreenCover(isPresented: $calModel.showMonth, onDismiss: {
                //print("Cal sheet onDismiss")
                if calModel.categoryFilterWasSetByCategoryPage {
                    calModel.sCategories.removeAll()
                    calModel.categoryFilterWasSetByCategoryPage = false
                    calModel.sPayMethod = calModel.sPayMethodBeforeFilterWasSetByCategoryPage
                    calModel.sPayMethodBeforeFilterWasSetByCategoryPage = nil
                }
            }) {
                calendarSheet
            }
            #endif
    }
    
    #if os(iOS)
    var calendarSheet: some View {
        Group {
            if let selectedMonth = NavigationManager.shared.selectedMonth {
                if NavDestination.justMonths.contains(selectedMonth) {
                    //GeometryReader { geo in
                        CalendarViewPhone(enumID: selectedMonth)
                            //.environment(\.safeAreaInsets, geo.safeAreaInsets)
                            .tint(Color.theme)
                            .navigationTransition(.zoom(sourceID: selectedMonth, in: monthNavigationNamespace))
                            .if(AppState.shared.methsExist) {
                                $0.calendarLoadingSpinner(id: selectedMonth, text: "Loading…")
                            }
                    //}
                }
            }
        }
    }
    #endif
}
