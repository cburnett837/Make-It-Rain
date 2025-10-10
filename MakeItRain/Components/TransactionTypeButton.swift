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
            Text("Transaction Type: ")
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
