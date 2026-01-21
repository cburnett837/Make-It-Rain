//
//  StandardAmountTextField.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/15/25.
//

import SwiftUI

struct StandardAmountTextField<T: CanEditAmount & Observation.Observable>: View {
    //@Local(\.colorTheme) var colorTheme
    
    #if os(macOS)
    @Environment(CalendarModel.self) private var calModel
    #endif
    
    var symbolWidth: CGFloat = 0
    var focusedField: FocusState<Int?>
    var focusID: Int
    var showSymbol: Bool = true
    var negativeOnFocusIfEmpty = true
    
    var obj: T
    
    var body: some View {
        @Bindable var obj = obj
        HStack(alignment: .circleAndTitle) {
            if showSymbol {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.gray)
                    .frame(width: symbolWidth)
                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Group {
                    #if os(iOS)
                    StandardUITextField("Amount", text: $obj.amountString, toolbar: {
                        KeyboardToolbarView(
                            focusedField: focusedField.projectedValue,
                            accessoryImage3: "plus.forwardslash.minus",
                            accessoryFunc3: {
                                Helpers.plusMinus($obj.amountString)
                            })
                    })
                    .cbClearButtonMode(.whileEditing)
                    .cbFocused(focusedField, equals: focusID)
                    //.cbKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
                    .cbKeyboardType(.custom(.numpad))
                    #else
                    StandardTextField("Amount", text: $obj.amountString, focusedField: focusedField.projectedValue, focusValue: 1)
                    #endif
                }
                .formatCurrencyLiveAndOnUnFocus(
                    focusValue: focusID,
                    focusedField: focusedField.wrappedValue,
                    amountString: obj.amountString,
                    amountStringBinding: $obj.amountString,
                    amount: obj.amount
                )
                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                .onChange(of: focusedField.wrappedValue) { oldValue, newValue in
                    if focusedField.wrappedValue == focusID && obj.amountString.isEmpty && negativeOnFocusIfEmpty {
                        obj.amountString = "-"
                    }
                }
                
                HStack(spacing: 1) {
                    Text("Transaction Type: ")
                        .foregroundStyle(.gray)
                    
                    Text(obj.amountTypeLingo)
                        .bold(true)
                        .foregroundStyle(Color.theme)
                        .onTapGesture {
                            Helpers.plusMinus($obj.amountString)
                            /// Just do on Mac because the calendar view is still visable.
                            #if os(macOS)
                            let _ = calModel.calculateTotal(for: calModel.sMonth)
                            #endif
                        }
                }
                .validate(obj.amountString, rules: .regex(.currency, "The field contains invalid characters"))
                .font(.caption)
                .multilineTextAlignment(.leading)
                .padding(.leading, 6)
                .disabled(obj.amountString.isEmpty)
            }
        }
    }
}
