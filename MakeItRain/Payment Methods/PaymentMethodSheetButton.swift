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
    var trans: CBTransaction? = nil
    var saveOnChange: Bool = false
    let whichPaymentMethods: ApplicablePaymentMethods
    
    var body: some View {
        StandardRectangle(fill: payMethodMenuColor) {
            MenuOrListButton(title: payMethod?.title, alternateTitle: "Select Payment Method") {
                showPayMethodSheet = true
            }
        }        
        .onHover { payMethodMenuColor = $0 ? Color(.systemFill) : Color(.tertiarySystemFill) }
        .sheet(isPresented: $showPayMethodSheet) {
            PaymentMethodSheet(payMethod: $payMethod, trans: trans, calcAndSaveOnChange: saveOnChange, whichPaymentMethods: whichPaymentMethods)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        }
    }
}



