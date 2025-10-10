//
//  ChartDateRangeHeader.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/8/25.
//

import SwiftUI

struct ChartDateRangeHeader: View {
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Bindable var vm: PayMethodViewModel
    @Bindable var payMethod: CBPaymentMethod
    
    var body: some View {
        VStack(spacing: 5) {
            chartVisibleYearPicker
            chartHeader
        }
    }
    
    
    @ViewBuilder
    var displayYearAndArrows: some View {
        Button {
            vm.moveYears(forward: false)
        } label: {
            Image(systemName: "chevron.left")
        }
        .contentShape(Rectangle())
        
        displayYears
        
        Button {
            vm.moveYears(forward: true)
        } label: {
            Image(systemName: "chevron.right")
        }
        .contentShape(Rectangle())
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
    
    var chartVisibleYearPicker: some View {
        Picker("", selection: $vm.visibleYearCount) {
            Text("1Y").tag(PayMethodChartRange.year1)
            Text("2Y").tag(PayMethodChartRange.year2)
            Text("3Y").tag(PayMethodChartRange.year3)
            Text("4Y").tag(PayMethodChartRange.year4)
            Text("5Y").tag(PayMethodChartRange.year5)
            Text("10Y").tag(PayMethodChartRange.year10)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .onChange(of: vm.visibleYearCount) { vm.setChartScrolledToDate($1) }
    }
    
    
    var chartHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("Insights By \(vm.viewByQuarter ? "Quarter" : "Month")")
                        .font(.title3)
                        .bold()
                    
                    Spacer()
                    
                    if payMethod.isCredit {
                        Text("Payments: \(vm.visiblePayments.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                            .foregroundStyle(.gray)
                            .font(.subheadline)
                    } else {
                        Text("Income: \(vm.visibleIncome.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                            .foregroundStyle(.gray)
                            .font(.subheadline)
                    }
                }
                
                HStack {
                    displayYearAndArrows
                                        
                    Spacer()
                    
                    Text("Expenses: \(vm.visibleExpenses.currencyWithDecimals(useWholeNumbers ? 0 : 2))")
                }
                .foregroundStyle(.gray)
                .font(.subheadline)
                //.padding(.bottom, 5)
                                                
            }
        }
    }
}
