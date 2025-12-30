//
//  NewTransactionMenuButton.swift
//  MakeItRain
//
//  Created by Cody Burnett on 6/2/25.
//

import SwiftUI

struct NewTransactionMenuButton: View {
    @Environment(CalendarModel.self) private var calModel
        
    #if os(iOS)
    let touchAndHoldPlusButtonTip = TouchAndHoldPlusButtonTip()
    #endif
    @Binding var transEditID: String?
    @Binding var showTransferSheet: Bool
    @Binding var showPhotosPicker: Bool
    @Binding var showCamera: Bool
    
    var body: some View {
        Menu {
            Section("Create") {
                newTransactionButton
                newTransferButton
            }
            
            Section("Smart Receipts") {
                TakePhotoButton(showCamera: $showCamera)
                SelectPhotoButton(showPhotosPicker: $showPhotosPicker)
            }
        } label: {
            Image(systemName: "plus")
                /// This is needed to fix the liquid class bug.
                .allowsHitTesting(false)
                //.tint(.none)
                .schemeBasedForegroundStyle()
        } primaryAction: {
            print("Button clicked")
            transEditID = UUID().uuidString
        }
        #if os(iOS)
        .popoverTip(touchAndHoldPlusButtonTip)
        #endif
    }
    
    
    var newTransactionButton: some View {
        Button {
            transEditID = UUID().uuidString
            #if os(iOS)
            TouchAndHoldPlusButtonTip.didSelectSmartReceiptOrTransferOption = true
            touchAndHoldPlusButtonTip.invalidate(reason: .actionPerformed)
            #endif
        } label: {
            Label {
                Text("New Transaction")
            } icon: {
                Image(systemName: "plus")
            }
        }
    }
    
    
    var newTransferButton: some View {
        Button {
            showTransferSheet = true
            #if os(iOS)
            TouchAndHoldPlusButtonTip.didSelectSmartReceiptOrTransferOption = true
            touchAndHoldPlusButtonTip.invalidate(reason: .actionPerformed)
            #endif
        } label: {
            Label {
                Text("New Transfer / Payment")
            } icon: {
                Image(systemName: "arrowshape.turn.up.forward")
            }
        }
    }
}
