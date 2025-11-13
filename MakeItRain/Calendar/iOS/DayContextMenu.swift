//
//  DayContextMenu.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/16/25.
//

import SwiftUI

struct DayContextMenu: View {
    //@Local(\.colorTheme) var colorTheme
    @Environment(CalendarProps.self) private var calProps
    @Environment(CalendarModel.self) private var calModel
        
    @Bindable var day: CBDay
    @Binding var selectedDay: CBDay?
    
    init(day: CBDay, selectedDay: Binding<CBDay?>) {
        self.day = day
        self._selectedDay = selectedDay
    }
    
    var body: some View {
        /// Sections for the more menu in the dayoverview. Doesn't affect the context menu on the day in the calendar.
        Section {
            newTransButton
            newTransferButton
        }
        
        Section {
            captureReceiptButton
            selectReceiptButton
        }
        
        
        if let _ = calModel.getCopyOfTransaction() {
            pasteTransactionButton
        }
        
        overviewButton
    }
    
    
    var newTransButton: some View {
        Button {
            selectedDay = day
            calProps.transEditID = UUID().uuidString
        } label: {
            Label("New Transaction", systemImage: "plus")
        }
    }
    
    var newTransferButton: some View {
        Button {
            selectedDay = day
            calProps.showTransferSheet = true
        } label: {
            Label("New Transfer / Payment", systemImage: "arrowshape.turn.up.forward")
        }
    }
    
    
    var captureReceiptButton: some View {
        Button {
            calModel.smartTransactionDate = day.date!
            calModel.isUploadingSmartTransactionFile = true
            calProps.showCamera = true
        } label: {
            Label("Capture Receipt", systemImage: "camera")
        }
    }
    
    var selectReceiptButton: some View {
        Button {
            calModel.smartTransactionDate = day.date!
            calModel.isUploadingSmartTransactionFile = true
            calProps.showPhotosPicker = true
        } label: {
            Label("Select Receipt", systemImage: "photo.badge.plus")
        }
    }
    
    var pasteTransactionButton: some View {
        Button {
            calModel.pasteTransaction(to: day)
        } label: {
            Label("Paste Transaction", systemImage: "document.on.clipboard")
        }
    }
    
    var overviewButton: some View {
        Button {
            withAnimation {
                calProps.overviewDay = day
                /// Set `selectedDay` to the same day as the overview day that way any transactions or transfers initiated via the bottom panel will have the date of the bottom panel.
                /// (Since ``TransactionEditView`` and ``TransferSheet`` use `selectedDate` as their default date.)
                selectedDay = day
                
                #if os(iOS)
                if AppState.shared.isIphone {
                    calProps.bottomPanelContent = .overviewDay
                } else {
                    /// Inspector is in ``RootViewPad``.
                    calProps.inspectorContent = .overviewDay
                    calProps.showInspector = true
                }
                #endif
            }
        } label: {
            Label("Overview", systemImage: "eye.fill")
        }
    }
}
