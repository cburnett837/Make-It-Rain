//
//  PaymentMethodChartDetailsSectionContainer.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/9/25.
//

import SwiftUI

struct PaymentMethodChartDetailsSectionContainer<Content: View>: View {
    
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
                if payMethod.isCreditOrUnified {
                    Text("Payments: \(vm.visiblePayments.currencyWithDecimals())")
                } else {
                    Text("Income: \(vm.visibleIncome.currencyWithDecimals())")
                }
                
                Text("Expenses: \(vm.visibleExpenses.currencyWithDecimals())")
            }
        }
    }
}
