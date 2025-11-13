//
//  PaymentMethodChartStyleMenu.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/8/25.
//

import SwiftUI

struct PaymentMethodChartStyleMenu: View {
    @AppStorage(LocalKeys.Charts.Options.showOverviewDataPerMethodOnUnified) var showOverviewDataPerMethodOnUnifiedChart = false
    
    @Environment(\.colorScheme) var colorScheme
    
    @Bindable var vm: PayMethodViewModel
    
    var body: some View {
        Menu {
            Section("This Year Style") {
                Picker(selection: $vm.chartCropingStyle) {
                    Text("Whole year")
                        .tag(ChartCropingStyle.showFullCurrentYear)
                    Text("Through current month")
                        .tag(ChartCropingStyle.endAtCurrentMonth)
                } label: {
                    Text(vm.chartCropingStyle.prettyValue)
                }
                .pickerStyle(.menu)
            }
            
            Section("Overview Style") {
                Picker(selection: $showOverviewDataPerMethodOnUnifiedChart) {
                    Text("View as summary only")
                        .tag(false)
                    Text("View by payment method")
                        .tag(true)
                } label: {
                    Text(showOverviewDataPerMethodOnUnifiedChart ? "By payment method" : "As summary only")
                }
                .pickerStyle(.menu)
                
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
                .schemeBasedForegroundStyle()
        }
    }
}
