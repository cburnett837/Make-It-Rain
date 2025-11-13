//
//  IncomeOptionToggle.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/30/25.
//


import SwiftUI
import Charts

struct ChartIncomeOptionMenu: View {
    //@Local(\.colorTheme) var colorTheme
    @Bindable var vm: PayMethodViewModel
    
    /// Need this to prevent the button from animating.
    @State private var incomeText = ""
    
    var body: some View {
        VStack(alignment: .trailing) {
            HStack {
                Menu {
                    Button { change(to: .income) } label: {
                        menuOptionLabel(title: "Income only", isChecked: vm.incomeType == .income)
                    }
                    Button { change(to: .positiveAmounts) } label: {
                        menuOptionLabel(title: "Money in only (no income)", isChecked: vm.incomeType == .positiveAmounts)
                    }
                    Button { change(to: .incomeAndPositiveAmounts) } label: {
                        menuOptionLabel(title: "All money in", isChecked: vm.incomeType == .incomeAndPositiveAmounts)
                    }
                    Button { change(to: .startingAmountsAndPositiveAmounts) } label: {
                        menuOptionLabel(title: "Starting amount & all money in", isChecked: vm.incomeType == .startingAmountsAndPositiveAmounts)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(incomeText)
                            .lineLimit(1)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.footnote)
                    }
                    .transaction {
                        $0.disablesAnimations = true
                        $0.animation = nil
                    }
                }
            }
        }
        .onAppear {
            setText(incomeType: vm.incomeType)
        }
    }
    
    @ViewBuilder func menuOptionLabel(title: String, isChecked: Bool) -> some View {
        HStack {
            Text(title)
            if isChecked {
                Image(systemName: "checkmark")
            }
        }
    }
    
    func change(to option: IncomeType) {
        setText(incomeType: option)
        withAnimation {
            vm.incomeType = option
        }
    }
    
    func setText(incomeType: IncomeType) {
        switch incomeType {
        case .income:
            self.incomeText = IncomeType.income.prettyValue
            
        case .incomeAndPositiveAmounts:
            self.incomeText = IncomeType.incomeAndPositiveAmounts.prettyValue
            
        case .positiveAmounts:
            self.incomeText = IncomeType.positiveAmounts.prettyValue
            
        case .startingAmountsAndPositiveAmounts:
            self.incomeText = IncomeType.startingAmountsAndPositiveAmounts.prettyValue
        }
    }
}
