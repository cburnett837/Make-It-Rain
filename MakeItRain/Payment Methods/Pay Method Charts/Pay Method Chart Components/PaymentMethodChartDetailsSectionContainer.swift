//
//  PaymentMethodChartDetailsSectionContainer.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/9/25.
//

import SwiftUI

struct PaymentMethodChartDetailsSectionContainer<Content: View>: View {
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Bindable var vm: PayMethodViewModel
    @Bindable var payMethod: CBPaymentMethod
    @ViewBuilder var theChart: Content

    var body: some View {
        Section {
            theChart
        } header: {
            HStack {
                PaymentMethodChartDisplayYearPicker(vm: vm)
                Spacer()
                PaymentMethodChartVisibleYearPicker(vm: vm)
            }
            .padding(.bottom, -8)
            
        } footer: {
            VStack(alignment: .leading) {
                if payMethod.isCredit {
                    Text("Payments: \(vm.visiblePayments.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                } else {
                    Text("Income: \(vm.visibleIncome.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                }
                
                Text("Expenses: \(vm.visibleExpenses.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
            }
        }
    }
}
