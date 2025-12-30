//
//  PhotoTakeAndSelectButtons.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/22/25.
//

import SwiftUI


struct TakePhotoButton: View {
    @Environment(CalendarModel.self) private var calModel
    @Binding var showCamera: Bool
    
    #if os(iOS)
    let touchAndHoldPlusButtonTip = TouchAndHoldPlusButtonTip()
    #endif
    
    var body: some View {
        Button {            
            calModel.isUploadingSmartTransactionFile = true
            showCamera = true
            #if os(iOS)
            TouchAndHoldPlusButtonTip.didSelectSmartReceiptOrTransferOption = true
            touchAndHoldPlusButtonTip.invalidate(reason: .actionPerformed)
            #endif
        } label: {
            Label {
                Text("Capture Receipt")
            } icon: {
                Image(systemName: "camera")
            }
        }
    }
}

struct SelectPhotoButton: View {
    @Environment(CalendarModel.self) private var calModel
    @Binding var showPhotosPicker: Bool
    
    #if os(iOS)
    let touchAndHoldPlusButtonTip = TouchAndHoldPlusButtonTip()
    #endif
    
    var body: some View {
        Button {
            calModel.isUploadingSmartTransactionFile = true
            showPhotosPicker = true
            #if os(iOS)
            TouchAndHoldPlusButtonTip.didSelectSmartReceiptOrTransferOption = true
            touchAndHoldPlusButtonTip.invalidate(reason: .actionPerformed)
            #endif
        } label: {
            Label {
                Text("Select Reciept")
            } icon: {
                Image(systemName: "photo.badge.plus")
            }
        }
    }
}
