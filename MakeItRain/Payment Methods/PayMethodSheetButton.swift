//
//  PayMethodSheetButton.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/25/24.
//

import SwiftUI


struct LogoInfo {
    var include: Bool
    var fallBackType: LogoFallBackType
}

#if os(macOS)
struct PayMethodSheetButtonMac: View {
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
            PayMethodSheet(payMethod: $payMethod, whichPaymentMethods: whichPaymentMethods)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
        }
    }
}
#endif

#if os(iOS)
struct PayMethodSheetButtonPhone: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(PlaidModel.self) private var plaidModel
    
    @State private var showPayMethodSheet = false
    @State private var payMethodMenuColor: Color = Color(.tertiarySystemFill)
        
    var text: String
    var logoInfo: LogoInfo?
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
                if let logoInfo = logoInfo {
                    Label {
                        Text(text)
                            .schemeBasedForegroundStyle()
                    } icon: {
                        //BusinessLogo(parent: payMethod, fallBackType: (payMethod ?? CBPaymentMethod()).isUnified ? .gradient : .color)
                        BusinessLogo(parent: payMethod, fallBackType: logoInfo.fallBackType)
                    }
                } else {
                    Text(text)
                        .schemeBasedForegroundStyle()
                }
                                
                Spacer()
                
                HStack(spacing: 4) {
                    Text(payMethod?.title ?? "Select Account")
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .tint(.none)
                .foregroundStyle(Color(.secondaryLabel))
            }
        }        
        .contentShape(Rectangle())
        .focusable(false)
        .onHover { payMethodMenuColor = $0 ? Color(.systemFill) : Color(.tertiarySystemFill) }
        .sheet(isPresented: $showPayMethodSheet) {
            PayMethodSheet(payMethod: $payMethod, whichPaymentMethods: whichPaymentMethods)
        }
    }
}
#endif
