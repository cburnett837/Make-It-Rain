//
//  PaymentMethodChartDisplayYearPicker.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/9/25.
//

import SwiftUI

struct PaymentMethodChartDisplayYearPicker: View {
    @Bindable var vm: PayMethodViewModel
    
    var body: some View {
        displayYearAndArrows
    }
    
    @ViewBuilder
    var displayYearAndArrows: some View {
        HStack {
            Button {
                vm.moveYears(forward: false)
            } label: {
                Image(systemName: "chevron.left")
            }
            .contentShape(Rectangle())
            .foregroundStyle(.gray)
            
            displayYears
            
            Button {
                vm.moveYears(forward: true)
            } label: {
                Image(systemName: "chevron.right")
            }
            .contentShape(Rectangle())
            .foregroundStyle(.gray)
        }            
    }
    
    var displayYears: some View {
        HStack(spacing: 5) {
            let lower = vm.visibleDateRangeForHeader.lowerBound.year
            let upper = vm.visibleDateRangeForHeader.upperBound.year
            
            var ytdText: String {
                if vm.chartCropingStyle == .endAtCurrentMonth {
                    if upper == lower && lower == AppState.shared.todayYear
                    || upper != lower && upper == AppState.shared.todayYear {
                        return " (YTD)"
                    }
                }
                return ""
            }
            
            if upper != lower {
                Text(String(lower))
                Text("-")
            }
                                                
            Text("\(String(upper))\(ytdText)")
        }
    }
}




