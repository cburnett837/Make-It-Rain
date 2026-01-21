//
//  ChartDateRangeHeader.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/8/25.
//

import SwiftUI

struct ChartDateRangeHeader: View {
    
    @Bindable var vm: PayMethodViewModel
    @Bindable var payMethod: CBPaymentMethod
    
    var body: some View {
        VStack(spacing: 5) {
            chartVisibleYearPicker
            chartHeader
        }        
    }
    
    
    var chartHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("Insights By \(vm.viewByQuarter ? "Quarter" : "Month")")
                        .font(.title3)
                        .bold()
                    
                    Spacer()
                    
                    if payMethod.isCreditOrUnified {
                        Text("Payments: \(vm.visiblePayments.currencyWithDecimals())")
                            .foregroundStyle(.gray)
                            .font(.subheadline)
                    } else {
                        Text("Income: \(vm.visibleIncome.currencyWithDecimals())")
                            .foregroundStyle(.gray)
                            .font(.subheadline)
                    }
                }
                
                HStack {
                    displayYearAndArrows
                    
                    //displayMonthAndArrows
                                        
                    Spacer()
                    
                    Text("Expenses: \(vm.visibleExpenses.currencyWithDecimals())")
                }
                .foregroundStyle(.gray)
                .font(.subheadline)
                //.padding(.bottom, 5)
                                                
            }
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
        
        vm.displayYearsView
        
        Button {
            vm.moveYears(forward: true)
        } label: {
            Image(systemName: "chevron.right")
        }
        .contentShape(Rectangle())
    }
    
    
    @ViewBuilder
    var displayMonthAndArrows: some View {
        Button {
            vm.moveMonths(forward: false)
        } label: {
            Image(systemName: "chevron.left")
        }
        .contentShape(Rectangle())
        
        vm.displayMonthView
        
        Button {
            vm.moveMonths(forward: true)
        } label: {
            Image(systemName: "chevron.right")
        }
        .contentShape(Rectangle())
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
}
