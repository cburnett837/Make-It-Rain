//
//  PayMethodSheetButton.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/25/24.
//

import SwiftUI

struct PayMethodSheetButton: View {
    @State private var showPayMethodSheet = false
    @State private var payMethodMenuColor: Color = Color(.tertiarySystemFill)
    @Binding var payMethod: CBPaymentMethod?
    var trans: CBTransaction? = nil
    var saveOnChange: Bool = false
    let whichPaymentMethods: ApplicablePaymentMethods
    
    var body: some View {
        StandardRectangle(fill: payMethodMenuColor) {
            MenuOrListButton(title: payMethod?.title, alternateTitle: "Select Account")
        }
        .contentShape(Rectangle())
        //.padding(.leading, 2)
        .focusable(false)        
        .onTapGesture {
            showPayMethodSheet = true
        }
        .onHover { payMethodMenuColor = $0 ? Color(.systemFill) : Color(.tertiarySystemFill) }
        .sheet(isPresented: $showPayMethodSheet) {
            PayMethodSheet(payMethod: $payMethod, trans: trans, calcAndSaveOnChange: saveOnChange, whichPaymentMethods: whichPaymentMethods)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        }
    }
}



struct PayMethodSheetButton2: View {
    @State private var showPayMethodSheet = false
    @State private var payMethodMenuColor: Color = Color(.tertiarySystemFill)
    @Binding var payMethod: CBPaymentMethod?
    var trans: CBTransaction? = nil
    var saveOnChange: Bool = false
    let whichPaymentMethods: ApplicablePaymentMethods
    
    var body: some View {
        Button {
            showPayMethodSheet = true
        } label: {
            HStack {
                Spacer()
                HStack(spacing: 4) {
                    Text(payMethod?.title ?? "Select Account")
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                        //.bold()
                        //.scaleEffect(0.6)
                }
                .tint(.none)
                #if os(iOS)
                .foregroundStyle(Color(.secondaryLabel))
                #else
                .foregroundStyle(.secondary)
                #endif
            }
        }        
        .contentShape(Rectangle())
        .focusable(false)
        .onHover { payMethodMenuColor = $0 ? Color(.systemFill) : Color(.tertiarySystemFill) }
        .sheet(isPresented: $showPayMethodSheet) {
            PayMethodSheet(payMethod: $payMethod, trans: trans, calcAndSaveOnChange: saveOnChange, whichPaymentMethods: whichPaymentMethods)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        }
    }
}
