//
//  TransactionTypeButton.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/30/25.
//

import SwiftUI

struct TransactionTypeButton: View {
    @Local(\.colorTheme) var colorTheme

    var amountTypeLingo: String
    @Binding var amountString: String
    
    var body: some View {
        HStack(spacing: 1) {
            Text("Trans Type: ")
                .foregroundStyle(.gray)
            
            Text(amountTypeLingo)
                .bold(true)
                .foregroundStyle(Color.fromName(colorTheme))
                .onTapGesture {
                    Helpers.plusMinus($amountString)
                }
        }
        .validate(amountString, rules: .regex(.currency, "The field contains invalid characters"))
        .disabled(amountString.isEmpty)
    }
}




struct TransactionAmountRow<Content: View>: View {
    @Local(\.colorTheme) var colorTheme

    var amountTypeLingo: String
    @Binding var amountString: String
    @ViewBuilder var content: Content
    
    var body: some View {
        HStack {
            content
            HStack(spacing: 1) {
                Button {
                    Helpers.plusMinus($amountString)
                } label: {
                    Text(amountTypeLingo)
                        .font(.subheadline)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(uiColor: .quaternarySystemFill))
                //.disabled(amountString.isEmpty)
            }
        }
        
        .validate(amountString, rules: .regex(.currency, "The field contains invalid characters"))
        
    }
}
