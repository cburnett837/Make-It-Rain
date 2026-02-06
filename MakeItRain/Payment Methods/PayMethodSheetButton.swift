//
//  PayMethodSheetButton.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/25/24.
//

import SwiftUI

struct PayMethodSheetButton: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(PlaidModel.self) private var plaidModel
    
    @State private var showPayMethodSheet = false
    @State private var payMethodMenuColor: Color = Color(.tertiarySystemFill)
        
    var text: String
    var logoFallBackType: LogoFallBackType?
    var isDisabled: Bool = false
    //var withLogo: Bool = true
    //var fallBackType: LogoFallBackType
    @Binding var payMethod: CBPaymentMethod?
    //var trans: CBTransaction? = nil
    //var saveOnChange: Bool = false
    let whichPaymentMethods: ApplicablePaymentMethods
    
    var body: some View {
        Button {
            showPayMethodSheet = true
        } label: {
            HStack {
                if let logoFallBackType = logoFallBackType {
                    Label {
                        Text(text)
                            .schemeBasedForegroundStyle()
                    } icon: {
                        //BusinessLogo(parent: payMethod, fallBackType: (payMethod ?? CBPaymentMethod()).isUnified ? .gradient : .color)
                        //BusinessLogo(parent: payMethod, fallBackType: logoFallBackType)
                        #if os(iOS)
                        BusinessLogo(config: .init(
                            parent: payMethod,
                            fallBackType: logoFallBackType
                        ))
                        #else
                        BusinessLogo(config: .init(
                            parent: payMethod,
                            fallBackType: logoFallBackType,
                            size: 20
                        ))
                        
                        #endif
                    }
                } else {
                    Text(text)
                        .schemeBasedForegroundStyle()
                }
                                
                Spacer()
                
                HStack(spacing: 4) {
                    Text(payMethod?.title ?? "Select Account")
                    if !isDisabled {
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                }
                .tint(.none)
                #if os(iOS)
                .foregroundStyle(Color(.secondaryLabel))
                #else
                .foregroundStyle(.secondary)
                #endif
            }
        }
        #if os(macOS)
        .buttonStyle(.plain)
        #endif
        .disabled(isDisabled)
        .contentShape(Rectangle())
        .focusable(false)
        .onHover { payMethodMenuColor = $0 ? Color(.systemFill) : Color(.tertiarySystemFill) }
        .sheet(isPresented: $showPayMethodSheet) {
            PayMethodSheet(payMethod: $payMethod, whichPaymentMethods: whichPaymentMethods)
                #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
                #endif
        }
    }
}
