//
//  DayContextMenu.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/16/25.
//

import SwiftUI

struct DayContextMenu: View {
    @Local(\.colorTheme) var colorTheme
    @Environment(CalendarProps.self) private var calProps
    @Environment(CalendarModel.self) private var calModel
        
    @Bindable var day: CBDay
    @Binding var selectedDay: CBDay?
    //@Binding var transEditID: String?
    //@Binding var showTransferSheet: Bool
    //@Binding var showCamera: Bool
    //@Binding var showPhotosPicker: Bool
    //@Binding var overviewDay: CBDay?
    //@Binding var bottomPanelContent: BottomPanelContent?
    
    init(
        day: CBDay,
        selectedDay: Binding<CBDay?>,
        //transEditID: Binding<String?>,
        //showTransferSheet: Binding<Bool>,
        //showCamera: Binding<Bool>,
        //showPhotosPicker: Binding<Bool>,
        //overviewDay: Binding<CBDay?> = Binding.constant(nil),
        //bottomPanelContent: Binding<BottomPanelContent?> = Binding.constant(nil)
    ) {
        self.day = day
        self._selectedDay = selectedDay
        //self._transEditID = transEditID
        //self._showTransferSheet = showTransferSheet
        //self._showCamera = showCamera
        //self._showPhotosPicker = showPhotosPicker
        //self._overviewDay = overviewDay
        //self._bottomPanelContent = bottomPanelContent
    }
    
    var body: some View {
        Section {
            Button {
                selectedDay = day
                calProps.transEditID = UUID().uuidString
            } label: {
                Label {
                    Text("New Transaction")
                } icon: {
                    Image(systemName: "plus.square.fill")
                }
            }
            
            Button {
                selectedDay = day
                calProps.showTransferSheet = true
            } label: {
                Label {
                    Text("New Transfer / Payment")
                } icon: {
                    Image(systemName: "arrowshape.turn.up.forward.fill")
                }
            }
        }        
        
    
        Section {
            Button {
                //let newID = UUID().uuidString
                //let trans = CBTransaction(uuid: newID)
                //trans.date = day.date!
                //calModel.pendingSmartTransaction = trans
                //calModel.pictureTransactionID = newID
                
                calModel.smartTransactionDate = day.date!
                calModel.isUploadingSmartTransactionPicture = true
                
                calProps.showCamera = true
            } label: {
                Label {
                    Text("Capture Receipt")
                } icon: {
                    Image(systemName: "camera.fill")
                }
            }
            
            Button {
                //let newID = UUID().uuidString
                //let trans = CBTransaction(uuid: newID)
                //trans.date = day.date!
                calModel.smartTransactionDate = day.date!
                calModel.isUploadingSmartTransactionPicture = true
                //calModel.pendingSmartTransaction = trans
                //calModel.pictureTransactionID = newID
                calProps.showPhotosPicker = true
            } label: {
                Label {
                    Text("Select Receipt")
                } icon: {
                    Image(systemName: "photo.badge.plus")
                }
            }
        }
        
        if let _ = calModel.getCopyOfTransaction() {
            Section {
                Button {
                    withAnimation {
                        if let trans = calModel.getCopyOfTransaction() {
                            trans.date = day.date!
                                                            
                            if !calModel.isUnifiedPayMethod {
                                trans.payMethod = calModel.sPayMethod!
                            }
                            
                            day.upsert(trans)
                            calModel.dragTarget = nil
                            calModel.saveTransaction(id: trans.id, day: day)
                            
                            calModel.transactionToCopy = nil
                        }
                    }
                } label: {
                    Text("Paste Transaction")
                }
            }
        }
        
        Button {
            withAnimation {
                calProps.overviewDay = day
                /// Set `selectedDay` to the same day as the overview day that way any transactions or transfers initiated via the bottom panel will have the date of the bottom panel.
                /// (Since `TransactionEditView` and `TransferSheet` use `selectedDate` as their default date.)
                selectedDay = day
                
                calProps.bottomPanelContent = .overviewDay
            }
        } label: {
            Text("Overview")
        }
                                                
//        Button {
//            if let transactionToPaste = calModel.getCopyOfTransaction() {
//                transactionToPaste.date = day.date!
//                                                
//                if !calModel.isUnifiedPayMethod {
//                    transactionToPaste.payMethod = calModel.sPayMethod!
//                }
//                
//                day.upsert(transactionToPaste)
//                calModel.saveTransaction(id: transactionToPaste.id, day: day)
//            }
//        } label: {
//            Label {
//                Text("Paste")
//            } icon: {
//                Image(systemName: "doc.on.clipboard")
//            }
//        }
    }
}
