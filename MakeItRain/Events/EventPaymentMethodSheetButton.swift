////
////  EventPayMethodSheetButton.swift
////  MakeItRain
////
////  Created by Cody Burnett on 4/2/25.
////
//
//
//import SwiftUI
//
//struct EventPayMethodSheetButton: View {
//    @State private var showPayMethodSheet = false
//    @State private var payMethodMenuColor: Color = Color(.tertiarySystemFill)
//    @Binding var payMethod: CBPaymentMethod?
//    var trans: CBEventTransaction?
//    let whichPaymentMethods: ApplicablePaymentMethods
//    
//    
//    var body: some View {
//        StandardRectangle(fill: payMethodMenuColor) {
//            MenuOrListButton(title: payMethod?.title, alternateTitle: "Select Payment Method") {
//                showPayMethodSheet = true
//            }
//        }
//        .onHover { payMethodMenuColor = $0 ? Color(.systemFill) : Color(.tertiarySystemFill) }
//        .sheet(isPresented: $showPayMethodSheet) {
//            PayMethodSheet(payMethod: $payMethod, trans: trans, calcAndSaveOnChange: saveOnChange, whichPaymentMethods: whichPaymentMethods)
//            #if os(macOS)
//                .frame(minWidth: 300, minHeight: 500)
//                .presentationSizing(.fitted)
//            #endif
//        }
//    }
//}
