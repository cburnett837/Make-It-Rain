//
//  DayContextMenu.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/16/25.
//

import SwiftUI

struct DayContextMenu: View {
    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
    
    @Environment(CalendarModel.self) private var calModel
    @Environment(CalendarViewModel.self) private var calViewModel
    
    @Bindable var day: CBDay
    
    @Binding var selectedDay: CBDay?
    @Binding var transEditID: String?
    @Binding var showTransferSheet: Bool
    @Binding var showCamera: Bool
    @Binding var showPhotosPicker: Bool
    
    var body: some View {
        Section {
            Button {
                transEditID = UUID().uuidString
                selectedDay = day
            } label: {
                Label {
                    Text("New Transaction")
                } icon: {
                    Image(systemName: "plus.square.fill")
                }
            }
            
            Button {
                selectedDay = day
                showTransferSheet = true
            } label: {
                Label {
                    Text("New Transfer")
                } icon: {
                    Image(systemName: "arrowshape.turn.up.forward.fill")
                }
            }
        }        
        
    
        Section {
            Button {
                let newID = UUID().uuidString
                let trans = CBTransaction(uuid: newID)
                trans.date = day.date!
                calModel.pendingSmartTransaction = trans
                calModel.pictureTransactionID = newID
                showCamera = true
            } label: {
                Label {
                    Text("Capture Receipt")
                } icon: {
                    Image(systemName: "camera.fill")
                }
            }
            
            Button {
                let newID = UUID().uuidString
                let trans = CBTransaction(uuid: newID)
                trans.date = day.date!
                calModel.pendingSmartTransaction = trans
                calModel.pictureTransactionID = newID
                showPhotosPicker = true
            } label: {
                Label {
                    Text("Select Receipt")
                } icon: {
                    Image(systemName: "photo.badge.plus")
                }
            }
        }
        
        if let trans = calModel.getCopyOfTransaction() {
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
