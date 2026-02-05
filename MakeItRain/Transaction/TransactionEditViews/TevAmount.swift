//
//  TransactionEditViewAmount.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/2/25.
//

import SwiftUI

struct TevAmount: View {
    @Bindable var trans: CBTransaction
    var focusedField: FocusState<Int?>.Binding
    @AppStorage("useCalculatorKeyboard") private var persistentUseCalculator = false
    @State private var useCalculator = false
    
    var body: some View {
        TransactionAmountRow(
            amountTypeLingo: trans.amountTypeLingo,
            amountString: $trans.amountString,
            isCalculator: useCalculator
        ) {
            amountRow
        }
        .overlay {
            Color.red
                .frame(height: 2)
                .opacity(trans.factorInCalculations ? 0 : 1)
        }
        .task { useCalculator = persistentUseCalculator }
        .onChange(of: useCalculator) { persistentUseCalculator = $1 }
        .onChange(of: focusedField.wrappedValue) {
            guard let meth = trans.payMethod else { return }
            if $1 == 1 && trans.amountString.isEmpty && meth.isDebitOrCash {
                trans.amountString = "-"
            }
        }
        /// Keep the amount in sync with the payment method at the time the payment method was changed.
        .onChange(of: trans.payMethod) { oldMeth, newMeth in
            if let oldMeth, let newMeth {
                if (oldMeth.isDebitOrCash && newMeth.isCreditOrLoan) || (oldMeth.isCreditOrLoan && newMeth.isDebitOrCash) {
                    Helpers.plusMinus($trans.amountString)
                }
            }
        }
    }
    
    
    @ViewBuilder
    var amountRow: some View {
        HStack(spacing: 0) {
            Label {
                Text("")
            } icon: {
                Image(systemName: "dollarsign.circle")
                    .foregroundStyle(.gray)
            }
            
            /// Wrap in LabeledContent since the mac sheet is in a form. Using LabeledContent will push the text to the leading edge,
            LabeledContent {
                amountTextField
            } label: {
                EmptyView()
            }
            .labelsHidden()
        }
    }
    
    
    var amountTextField: some View {
        Group {
            #if os(iOS)
            UITextFieldWrapper(placeholder: "Amount", text: $trans.amountString, toolbar: {
                KeyboardToolbarView(
                    focusedField: focusedField.projectedValue,
                    disableDown: true,
                    accessoryImage3: useCalculator ? "numbers" : "square.grid.4x3.fill",
                    accessoryFunc3: { changeView() },
                    accessoryImage4: useCalculator ? nil : "plus.forwardslash.minus",
                    accessoryFunc4: useCalculator ? nil : { Helpers.plusMinus($trans.amountString) }
                )
            })
            .uiTag(1)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.left)
            .uiKeyboardType(useCalculator ? .custom(.calculator) : .custom(.numpad))
            #else
            TextField("", text: $trans.amountString, prompt: Text("Amount")
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .light))
            )
            #endif
        }
        .focused(focusedField.projectedValue, equals: 1)
        .formatCurrencyLiveAndOnUnFocus(
            focusValue: 1,
            focusedField: focusedField.wrappedValue,
            amountString: trans.amountString,
            amountStringBinding: $trans.amountString,
            amount: trans.amount
        )
    }
    
    
    func changeView() {
        print("-- \(#function)")
        useCalculator.toggle()
        DispatchQueue.main.async/*After(deadline: .now() + 0.2)*/ {
            focusedField.wrappedValue = 1
        }        
    }
}
