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
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showPayMethodSheet = false
    @State private var payMethodMenuColor: Color = Color(.tertiarySystemFill)
        
    var text: String
    var image: String? = nil
    @Binding var payMethod: CBPaymentMethod?
    var trans: CBTransaction? = nil
    var saveOnChange: Bool = false
    let whichPaymentMethods: ApplicablePaymentMethods
    
    var body: some View {
        Button {
            showPayMethodSheet = true
        } label: {
            HStack {
                if let image = image {
                    Label {
                        Text(text)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    } icon: {
                        Image(systemName: image)
                            .foregroundStyle(payMethod == nil ? .gray : payMethod!.color)
                            //.frame(width: symbolWidth)
                    }
                } else {
                    Text(text)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                }
                                
                Spacer()
                
                HStack(spacing: 4) {
                    Text(payMethod?.title ?? "Select Account")
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
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
