//
//  PaymentMethodFilterMenu.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/27/25.
//

import SwiftUI

struct PayMethodFilterMenu: View {
    @Local(\.paymentMethodFilterMode) var paymentMethodFilterMode

    var body: some View {
        Menu {
            Picker("Filter", selection: $paymentMethodFilterMode) {
                ForEach(PaymentMethodFilterMode.allCases, id: \.self) { filter in
                    Text(filter.prettyValue)
                        .tag(filter)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        } label: {
            Label("Filter", systemImage: "line.3.horizontal.decrease")
        }
        .schemeBasedTint()
    }
}

