//
//  StartingAmountSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/13/24.
//

import SwiftUI

#if os(macOS)
struct StartingAmountSheet: View {
    @Local(\.useBusinessLogos) var useBusinessLogos
    @Environment(\.layoutDirection) private var layoutDirection: LayoutDirection
    @Environment(\.dismiss) var dismiss
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(PlaidModel.self) var plaidModel
    @FocusState private var focusedField: Int?
    
    var body: some View {
        @Bindable var calModel = calModel
        @Bindable var payModel = payModel
        
        NavigationStack {
            StandardContainerWithToolbar(.list, scrollDismissesKeyboard: .never) {
                
                ForEach(payModel.sections) { section in
                    Section(section.rawValue) {
                        ForEach(payModel.getMethodsFor(
                            section: section,
                            type: .allExceptUnified,
                            sText: "",
                            calModel: calModel,
                            plaidModel: plaidModel
                        )) { meth in
                            if let amount = calModel.sMonth.startingAmounts.filter ({ $0.payMethod.id == meth.id }).first {
                                StartingAmountLine(startingAmount: amount, payMethod: amount.payMethod)
                            }
                        }
                    }
                }
            }
            .task {
                for each in calModel.sMonth.startingAmounts {
                    each.deepCopy(.create)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .destructiveAction) {
                    HStack {
                        moreMenu
                        PayMethodFilterMenu()
                    }
                }
                
                ToolbarItemGroup(placement: .confirmationAction) {
                    HStack {
                        PayMethodSortMenu()
                        closeButton
                    }
                }
            }
        }
    }
    
    
    var moreMenu: some View {
        Menu {
            useBusinessLogosToggle
        } label: {
            Image(systemName: "ellipsis")
                .schemeBasedForegroundStyle()
        }
        .buttonStyle(.roundMacButton)
    }
    
    
    var useBusinessLogosToggle: some View {
        Toggle(isOn: $useBusinessLogos) {
            Text("Use Business Logos")
        }
    }
    
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
        .buttonStyle(.roundMacButton)
    }
}


fileprivate struct StartingAmountLine: View {
    @Environment(\.layoutDirection) private var layoutDirection: LayoutDirection
    @Environment(CalendarModel.self) var calModel
    
    @Bindable var startingAmount: CBStartingAmount
    var payMethod: CBPaymentMethod
    @State private var showDialog = false
    @FocusState private var focusedField: Int?

    
    var body: some View {
        HStack {
            Label {
                Text("\(payMethod.title)")
            } icon: {
                BusinessLogo(config: .init(
                    parent: payMethod,
                    fallBackType: payMethod.isUnified ? .gradient : .color,
                    size: 20
                ))
                .padding(.trailing, 10)
            }
                        
            Spacer()
            
            TextField("Starting Amount", text: $startingAmount.amountString)
                .multilineTextAlignment(.trailing)
                .contextMenu {
                    Button("AutoFill") {
                        if calModel.sMonth.num != 0 {
                            let targetMonth = calModel.months.filter { $0.num == calModel.sMonth.num - 1 }.first!
                            let _ = calModel.calculateTotal(for: targetMonth, using: payMethod)
                            let eodTotal = targetMonth.days.last!.eodTotal
                            startingAmount.amountString = eodTotal.currencyWithDecimals()
                        }
                    }
                }
                .focused($focusedField, equals: 0)
                .formatCurrencyLiveAndOnUnFocus(
                    focusValue: 0,
                    focusedField: focusedField,
                    amountString: startingAmount.amountString,
                    amountStringBinding: $startingAmount.amountString,
                    amount: startingAmount.amount
                )
        }
        .task {
            startingAmount.amountString = startingAmount.amount.currencyWithDecimals()
        }
    }
}

#endif


