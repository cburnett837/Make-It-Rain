//
//  AlertAndToastAndCalendarLayerView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/13/25.
//

import SwiftUI

struct AlertAndToastLayerView: View {
    //@Local(\.colorTheme) var colorTheme
    @Environment(CalendarModel.self) private var calModel
    @Binding var showCamera: Bool
    
    var body: some View {
        @Bindable var appState = AppState.shared
        @Bindable var calModel = calModel
        @Bindable var undoManager = UndodoManager.shared
        
        Rectangle()
            .fill(Color.clear)
            .ignoresSafeArea(.all)
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
//            .alert(AppState.shared.alertConfig?.title ?? "N/A",
//                isPresented: $appState.showCustomAlert,
//                presenting: AppState.shared.alertConfig,
//                actions: { config in
//                    config.primaryButton
//                    config.secondaryButton
//                
//                    Button(role: .cancel) {
//                        
//                    }
//                },
//                message: { config in
//                    Text(config.subtitle ?? "")
//                }
//            )
            #if os(iOS)
            .overlay {
                if let config = AppState.shared.alertConfig {
                    Rectangle()
                        .fill(Color.black)
                        
                        .glassEffect(in: .rect())
                        //.fill(.ultraThickMaterial)
                        //.fill(Color.darkGray3)
                        .opacity(0.3)
                        .ignoresSafeArea()
                        .overlay { CustomAlert(config: config) }
                        .opacity(appState.showCustomAlert ? 1 : 0)
                        .accessibilityIdentifier("UniversalAlertContent")
                }
            }
            #else
            .overlay {
                if let config = AppState.shared.alertConfig {
                    CustomAlert(config: config)
                }
            }
            #endif
            #if os(iOS) 
            .photoPickerAndCameraSheet(
                fileUploadCompletedDelegate: calModel,
                parentType: .transaction,
                allowMultiSelection: false,
                showPhotosPicker: .constant(false),
                showCamera: $showCamera
            )
            #endif
            /// Toasts.
            .toast()
    }
}
