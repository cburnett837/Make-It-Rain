//
//  StartingAmountSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/13/24.
//

import SwiftUI

struct StartingAmountSheet: View {
    @Environment(\.layoutDirection) private var layoutDirection: LayoutDirection
    @Environment(\.dismiss) var dismiss
    @Local(\.useWholeNumbers) var useWholeNumbers
    
    @Environment(CalendarModel.self) var calModel
    
    @Environment(PayMethodModel.self) var payModel
    @FocusState private var focusedField: Int?
    
    var body: some View {
        @Bindable var calModel = calModel
        @Bindable var payModel = payModel
        
        StandardContainer(.list) {
            if !cashMethods.isEmpty {
                Section("Checking / Cash") {
                    ForEach(cashMethods.startIndex..<cashMethods.endIndex, id: \.self) { i in
                        let focusID = i
                        if let amount = calModel.sMonth.startingAmounts.filter({ $0.payMethod.id == cashMethods[i].id }).first {
                            StartingAmountLine(startingAmount: amount, payMethod: cashMethods[i], focusedField: _focusedField, focusID: focusID)
                        }
                        
                    }
                }
            }
                                
            if !creditMethods.isEmpty {
                Section("Credit") {
                    ForEach(creditMethods.startIndex..<creditMethods.endIndex, id: \.self) { i in
                        let focusID = i + cashMethods.count
                        if let amount = calModel.sMonth.startingAmounts.filter({ $0.payMethod.id == creditMethods[i].id }).first {
                            StartingAmountLine(startingAmount: amount, payMethod: creditMethods[i], focusedField: _focusedField, focusID: focusID)
                        }
                    }
                }
            }
            
            if !otherMethods.isEmpty {
                Section("Other") {
                    ForEach(otherMethods.startIndex..<otherMethods.endIndex, id: \.self) { i in
                        let focusID = i + cashMethods.count + creditMethods.count
                        if let amount = calModel.sMonth.startingAmounts.filter({ $0.payMethod.id == otherMethods[i].id }).first {
                            StartingAmountLine(startingAmount: amount, payMethod: otherMethods[i], focusedField: _focusedField, focusID: focusID)
                        }
                        
                    }
                }
            }
        } header: {
            SheetHeader(
                title: "Starting Amounts",
                //subtitle: "\(calModel.sMonth.name) \(calModel.sMonth.year)",
                close: { dismiss() }
            )
        } footer: {
            Text("\(calModel.sMonth.name) \(String(calModel.sMonth.year))")
               .font(.caption2)
               .foregroundStyle(.gray)
        }
        .task {
            for each in calModel.sMonth.startingAmounts {
                each.deepCopy(.create)
            }
        }
    }
    
    var cashMethods: [CBPaymentMethod] {
        return payModel.paymentMethods.filter { $0.accountType == .cash || $0.accountType == .checking }
    }
    
    var creditMethods: [CBPaymentMethod] {
        payModel.paymentMethods.filter { $0.accountType == .credit }
    }
    
    var otherMethods: [CBPaymentMethod] {
        payModel.paymentMethods.filter {
            $0.accountType != .checking
            && $0.accountType != .cash
            && $0.accountType != .credit
            && !$0.isUnified
        }
    }
    
    
    
    struct StartingAmountLine: View {
        @Local(\.useWholeNumbers) var useWholeNumbers
        @Environment(\.layoutDirection) private var layoutDirection: LayoutDirection
        @Environment(CalendarModel.self) var calModel
        
        @Bindable var startingAmount: CBStartingAmount
        var payMethod: CBPaymentMethod
        @State private var showDialog = false
        var focusedField: FocusState<Int?>
        var focusID: Int
        
        var body: some View {
            HStack {
                Image(systemName: "circle.fill")
                    .foregroundStyle(payMethod.color)
                Text("\(payMethod.title)")
                Spacer()
                
                Group {
                    #if os(iOS)
                    UITextFieldWrapper(placeholder: "Starting Amount", text: $startingAmount.amountString, toolbar: {
                        KeyboardToolbarView(
                            focusedField: focusedField.projectedValue,
                            accessoryText1: "AutoFill",
                            accessoryFunc1: {
                                if calModel.sMonth.num != 0 {
                                    let targetMonth = calModel.months.filter { $0.num == calModel.sMonth.num - 1 }.first!
                                    let _ = calModel.calculateTotal(for: targetMonth, using: payMethod)
                                    let eodTotal = targetMonth.days.last!.eodTotal
                                    startingAmount.amountString = eodTotal.currencyWithDecimals(useWholeNumbers ? 0 : 2)
                                }
                            },
                            accessoryImage3: "plus.forwardslash.minus",
                            accessoryFunc3: {
                                Helpers.plusMinus($startingAmount.amountString)
                            })
                    })
                    .uiKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
                    .uiTag(focusID)
                    .uiTextAlignment(layoutDirection == .leftToRight ? .right : .left)
                    .uiClearButtonMode(.whileEditing)
                    .uiStartCursorAtEnd(true)
                    #else
                    TextField("Starting Amount", text: $startingAmount.amountString)
                        .multilineTextAlignment(.trailing)
                        .contextMenu {
                            Button("AutoFill") {
                                if calModel.sMonth.num != 0 {
                                    let targetMonth = calModel.months.filter { $0.num == calModel.sMonth.num - 1 }.first!
                                    let _ = calModel.calculateTotal(for: targetMonth, using: payMethod)
                                    let eodTotal = targetMonth.days.last!.eodTotal
                                    startingAmount.amountString = eodTotal.currencyWithDecimals(useWholeNumbers ? 0 : 2)
                                }
                            }
                        }
                    #endif
                }
                .focused(focusedField.projectedValue, equals: focusID)
                .formatCurrencyLiveAndOnUnFocus(
                    focusValue: focusID,
                    focusedField: focusedField.wrappedValue,
                    amountString: startingAmount.amountString,
                    amountStringBinding: $startingAmount.amountString,
                    amount: startingAmount.amount
                )
                
                
                
//                .onChange(of: focusedField) { oldValue, newValue in
//                    if newValue == focusID {
//                        if startingAmount.amount == 0.0 {
//                            startingAmount.amountString = ""
//                        }
//                    } else {
//                        if oldValue == focusID && !startingAmount.amountString.isEmpty {
//                            if startingAmount.amountString == "$" || startingAmount.amountString == "-$" {
//                                startingAmount.amountString = ""
//                            } else {
//                                startingAmount.amountString = startingAmount.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
//                            }
//                        }
//                    }
//                }
            }
        }
    }
}
