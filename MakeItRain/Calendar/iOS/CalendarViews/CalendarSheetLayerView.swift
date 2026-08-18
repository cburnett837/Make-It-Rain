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
    @Environment(CalendarModel.self) private var calModel
    @Environment(AppStore.self) private var store
    
    @Namespace private var namespace
        
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .ignoresSafeArea(.all)
            .overlay(overlayRectangle)            
    }
    
    @ViewBuilder
    var overlayRectangle: some View {
        @Bindable var calModel = calModel
        Rectangle()
            .fill(Color.clear)
            .ignoresSafeArea(.all)
            #if os(iOS)
            .fullScreenCover(isPresented: $calModel.showMonth, onDismiss: {
                if store.categoryFilterWasSetByCategoryPage {
                    calModel.sCategories.removeAll()
                    store.categoryFilterWasSetByCategoryPage = false
                    calModel.sPayMethod = calModel.sPayMethodBeforeFilterWasSetByCategoryPage
                    calModel.sPayMethodBeforeFilterWasSetByCategoryPage = nil
                }
            }) {
                calendarSheet
            }
            #endif
    }
    
    
    #if os(iOS)
    @ViewBuilder
    var calendarSheet: some View {
        if let selectedMonth = NavigationManager.shared.selectedMonth {
            if NavDest.justMonths.contains(selectedMonth) {
                CalendarViewPhone(enumID: selectedMonth)
                    .tint(Color.theme)
                    .navigationTransition(.zoom(sourceID: selectedMonth, in: namespace))
                    .if(AppState.shared.methsExist) {
                        $0.calendarLoadingSpinner(id: selectedMonth, text: "Loading…")
                    }
            }
        }
    }
    #endif
}
