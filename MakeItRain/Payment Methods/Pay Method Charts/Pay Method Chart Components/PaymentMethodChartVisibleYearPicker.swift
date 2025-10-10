//
//  PaymentMethodChartVisibleYearPicker.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/9/25.
//


import SwiftUI

struct PaymentMethodChartVisibleYearPicker: View {
    @Bindable var vm: PayMethodViewModel
    
    var body: some View {
        Picker(selection: $vm.visibleYearCount) {
            Text("1Y").tag(PayMethodChartRange.year1)
            Text("2Y").tag(PayMethodChartRange.year2)
            Text("3Y").tag(PayMethodChartRange.year3)
            Text("4Y").tag(PayMethodChartRange.year4)
            Text("5Y").tag(PayMethodChartRange.year5)
            Text("10Y").tag(PayMethodChartRange.year10)
        } label: {
            Text("\(String(vm.visibleYearCount.rawValue))Y")
                .foregroundStyle(.gray)
        }
        .pickerStyle(.menu)
        .onChange(of: vm.visibleYearCount) { vm.setChartScrolledToDate($1) }
    }
}
