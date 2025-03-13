//
//  AlertAndToastAndCalendarLayerView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/13/25.
//

import SwiftUI

struct AlertAndToastAndCalendarLayerView: View {
    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
    @Environment(CalendarModel.self) private var calModel
    @Namespace private var monthNavigationNamespace
    
    @Binding var selectedDay: CBDay?
    
    var body: some View {
        @Bindable var appState = AppState.shared
        @Bindable var calModel = calModel
        @Bindable var undoManager = UndodoManager.shared
        
        Rectangle()
            .fill(Color.clear)
            .ignoresSafeArea(.all)
            /// Toasts.
            .toast()
            /// Undo / Redo options.
            .alert("Undo / Redo", isPresented: $undoManager.showAlert) {
                VStack {
                    if UndodoManager.shared.canUndo {
                        Button {
                            if let old = UndodoManager.shared.undo() {
                                undoManager.returnMe = old
                            }
                        } label: {
                            Text("Undo")
                        }
                    }
                    
                    if UndodoManager.shared.canRedo {
                        Button {
                            if let new = UndodoManager.shared.redo() {
                                undoManager.returnMe = new
                            }
                        } label: {
                            Text("Redo")
                        }
                    }
                    
                    Button(role: .cancel) {
                    } label: {
                        Text("Cancel")
                    }
                }
            }
            /// Custom alerts.
            .overlay {
                if let config = AppState.shared.alertConfig {
                    Rectangle()
                        //.fill(.ultraThickMaterial)
                        .fill(Color.darkGray3)
                        .opacity(0.8)
                        .ignoresSafeArea()
                        .overlay { CustomAlert(config: config) }
                        .opacity(appState.showCustomAlert ? 1 : 0)
                                            
                }
            }
            /// Calendar full screen cover. (Main calendar view for iPhone, accessory calendar view for iPad).
            .overlay {
                Rectangle()
                    .fill(Color.clear)
                    //.if(!AppState.shared.isIpad) {
                    .fullScreenCover(isPresented: $calModel.showMonth) {
                        if let selectedMonth = NavigationManager.shared.selectedMonth {
                            
                            if NavDestination.justMonths.contains(selectedMonth) {
                                
                                CalendarViewPhone(enumID: selectedMonth, selectedDay: $selectedDay)
                                    .tint(Color.fromName(appColorTheme))
                                    .navigationTransition(.zoom(sourceID: selectedMonth, in: monthNavigationNamespace))
                                    .if(AppState.shared.methsExist) {
                                        $0.loadingSpinner(id: selectedMonth, text: "Loading…")
                                    }
                            }
                        }
                    }
                    //}
            }
    }
}
