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
        .onChange(of: useCalculator) { persistentUseCalculator = $1 }
        .task { useCalculator = persistentUseCalculator }
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
            
            Group {
                #if os(iOS)
                
                UITextFieldWrapper(placeholder: "Amount", text: $trans.amountString, toolbar: {
                    KeyboardToolbarView(
                        focusedField: focusedField.projectedValue,
                        disableDown: true,
                        accessoryImage3: useCalculator ? "numbers" : "square.grid.4x3.fill",
                        accessoryFunc3: { changeView() },
                        accessoryImage4: "plus.forwardslash.minus",
                        accessoryFunc4: { Helpers.plusMinus($trans.amountString) }
                    )
                })
                .uiTag(1)
                .uiClearButtonMode(.whileEditing)
                .uiStartCursorAtEnd(true)
                .uiTextAlignment(.left)
                .uiKeyboardType(useCalculator ? .custom(.calculator) : .custom(.numpad))
                
                
                
//                if useCalculator {
//                    UITextFieldWrapper(placeholder: "Amount", text: $trans.amountString, toolbar: {
//                        KeyboardToolbarView(
//                            focusedField: focusedField.projectedValue,
//                            disableDown: true,
//                            accessoryImage3: "numbers",
//                            accessoryFunc3: { changeView() },
//                            accessoryImage4: "plus.forwardslash.minus",
//                            accessoryFunc4: { Helpers.plusMinus($trans.amountString) }
//                        )
//                    })
//                    .uiTag(1)
//                    .uiClearButtonMode(.whileEditing)
//                    .uiStartCursorAtEnd(true)
//                    .uiTextAlignment(.left)
//                    .uiKeyboardType(.custom(.calculator))
//                } else {
//                    UITextFieldWrapper(placeholder: "Amount", text: $trans.amountString, toolbar: {
//                        KeyboardToolbarView(
//                            focusedField: focusedField.projectedValue,
//                            disableDown: true,
//                            accessoryImage3: "square.grid.4x3.fill",
//                            accessoryFunc3: { changeView() },
//                            accessoryImage4: "plus.forwardslash.minus",
//                            accessoryFunc4: { Helpers.plusMinus($trans.amountString) }
//                        )
//                    })
//                    .uiTag(1)
//                    .uiClearButtonMode(.whileEditing)
//                    .uiStartCursorAtEnd(true)
//                    .uiTextAlignment(.left)
//                    .uiKeyboardType(.custom(.numpad))
//                }
                
                #else
                StandardTextField("Amount", text: $trans.amountString, focusedField: $focusedField, focusValue: 1)
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
//            .calculateAndFormatCurrencyLiveAndOnUnFocus(
//                focusValue: 1,
//                focusedField: focusedField.wrappedValue,
//                amountString: trans.amountString,
//                amountStringBinding: $trans.amountString,
//                amount: trans.amount
//            )
            .onChange(of: focusedField.wrappedValue) { oldValue, newValue in
                if newValue == 1 && trans.amountString.isEmpty && (trans.payMethod ?? CBPaymentMethod()).isDebit {
                    trans.amountString = "-"
                }
                
                
//                if newValue == 1 {
//                    Helpers.formatCurrency(
//                        focusValue: focusValue,
//                        oldFocus: oldValue,
//                        newFocus: newValue,
//                        amountString: amountStringBinding,
//                        amount: amount
//                    )
//                }
            }
            /// Keep the amount in sync with the payment method at the time the payment method was changed.
            .onChange(of: trans.payMethod) { oldValue, newValue in
                if let oldValue, let newValue {
                    if (oldValue.isDebit && newValue.isCreditOrLoan) || (oldValue.isCreditOrLoan && newValue.isDebit) {
                        Helpers.plusMinus($trans.amountString)
                    }
                }
            }
        }
    }
    
    
    func changeView() {
        print("-- \(#function)")
        useCalculator.toggle()
        DispatchQueue.main.async/*After(deadline: .now() + 0.2)*/ {
            focusedField.wrappedValue = 1
        }
        
    }
}
