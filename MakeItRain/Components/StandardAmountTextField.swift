//
//  StandardAmountTextField.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/15/25.
//

import SwiftUI

struct StandardAmountTextField<T: CanEditAmount & Observation.Observable>: View {
    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    #if os(macOS)
    @Environment(CalendarModel.self) private var calModel
    #endif
    @Environment(MapModel.self) private var mapModel
    
    var symbolWidth: CGFloat
    var focusedField: FocusState<Int?>
    var focusID: Int
    var showSymbol: Bool = true
    
    var obj: T
    
    var body: some View {
        @Bindable var obj = obj
        HStack(alignment: .circleAndTitle) {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundColor(.gray)
                .frame(width: symbolWidth)
                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
            
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
                    .cbKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
                    #else
                    StandardTextField("Amount", text: $obj.amountString, focusedField: focusedField.projectedValue, focusValue: 1)
                    #endif
                }
                .formatCurrencyLiveAndOnUnFocus(
                    focusValue: focusID,
                    focusedField: focusID,
                    amountString: obj.amountString,
                    amountStringBinding: $obj.amountString,
                    amount: obj.amount
                )
                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                
                (Text("Transaction Type: ") + Text(obj.amountTypeLingo)
                    .bold(true)
                    .foregroundStyle(Color.fromName(appColorTheme)))
                    .foregroundStyle(.gray)
                    .font(.caption)
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 6)
                    .disabled(obj.amountString.isEmpty)
                    .onTapGesture {
                        Helpers.plusMinus($obj.amountString)
                        /// Just do on Mac because the calendar view is still visable.
                        #if os(macOS)
                        calModel.calculateTotalForMonth(month: calModel.sMonth)
                        #endif
                    }
            }
        }
    }
}
