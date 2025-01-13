//
//  PaymentMethodSheetButton.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/25/24.
//

import SwiftUI

struct PaymentMethodSheetButton: View {
    @State private var showPayMethodSheet = false
    @State private var payMethodMenuColor: Color = Color(.tertiarySystemFill)
    @Binding var payMethod: CBPaymentMethod?
    let whichPaymentMethods: ApplicablePaymentMethods
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            //.stroke(.gray, lineWidth: 1)
            .fill(payMethodMenuColor)
            #if os(macOS)
            .frame(height: 27)
            #else
            .frame(height: 34)
            #endif
            .overlay {
                MenuOrListButton(title: payMethod?.title, alternateTitle: "Select Payment Method") {
                    showPayMethodSheet = true
                }
            }
            .onHover { payMethodMenuColor = $0 ? Color(.systemFill) : Color(.tertiarySystemFill) }
            .sheet(isPresented: $showPayMethodSheet) {
                #if os(macOS)
                PaymentMethodSheet(payMethod: $payMethod, whichPaymentMethods: whichPaymentMethods)
                    .frame(minWidth: 300, minHeight: 500)
                    .presentationSizing(.fitted)
                #else
                PaymentMethodSheet(payMethod: $payMethod, whichPaymentMethods: whichPaymentMethods)
                #endif
            }
    }
}
