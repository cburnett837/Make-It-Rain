//
//  PaymentMethodFilterMenu.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/27/25.
//

import SwiftUI

struct PayMethodFilterMenu: View {
    var body: some View {
        @Bindable var appSettings = AppSettings.shared
        Menu {
            Picker("Filter", selection: $appSettings.paymentMethodFilterMode) {
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
        .onChange(of: appSettings.paymentMethodFilterMode) { oldValue, newValue in
            appSettings.sendToServer(setting: .init(settingId: 57, setting: appSettings.paymentMethodFilterMode.rawValue))
        }
    }
}

