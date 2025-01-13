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
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @FocusState private var focusedField: Int?
    
//    init() {
//        for meth in payModel.paymentMethods.filter({ !$0.isUnified }) {
//            calModel.prepareStartingAmount(for: meth)
//        }
//    }
    
    var body: some View {
        startingAmount
    }
    
    var cashMethods: [CBPaymentMethod] {
        return payModel.paymentMethods.filter { $0.accountType == .cash || $0.accountType == .checking }
    }
    
    var creditMethod: [CBPaymentMethod] {
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
    
    var startingAmount: some View {
        Group {
            @Bindable var calModel = calModel
            @Bindable var payModel = payModel
            VStack(spacing: 0) {
                SheetHeader(title: "Starting Amounts", subtitle: "\(calModel.sMonth.name) \(calModel.sMonth.year)", close: { dismiss() })
                    .padding()
                
                List {
                    if !cashMethods.isEmpty {
                        Section("Checking / Cash") {
                            ForEach(cashMethods.startIndex..<cashMethods.endIndex, id: \.self) { i in
                                let focusID = i
                                let amount = calModel.sMonth.startingAmounts.filter { $0.payMethod.id == cashMethods[i].id }.first
                                StartingAmountLine(startingAmount: amount!, payMethod: cashMethods[i], focusID: focusID)
                            }
                        }
                    }
                                        
                    if !creditMethod.isEmpty {
                        Section("Credit") {
                            ForEach(creditMethod.startIndex..<creditMethod.endIndex, id: \.self) { i in
                                let focusID = i + cashMethods.count
                                let amount = calModel.sMonth.startingAmounts.filter { $0.payMethod.id == creditMethod[i].id }.first
                                StartingAmountLine(startingAmount: amount!, payMethod: creditMethod[i], focusID: focusID)
                            }
                        }
                    }
                    
                    if !otherMethods.isEmpty {
                        Section("Other") {
                            ForEach(otherMethods.startIndex..<otherMethods.endIndex, id: \.self) { i in
                                let focusID = i + cashMethods.count + creditMethod.count
                                let amount = calModel.sMonth.startingAmounts.filter { $0.payMethod.id == otherMethods[i].id }.first
                                StartingAmountLine(startingAmount: amount!, payMethod: otherMethods[i], focusID: focusID)
                            }
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        
//        .task {
//            for meth in payModel.paymentMethods.filter({ !$0.isUnified }) {
//                calModel.prepareStartingAmount(for: meth)
//            }
//        }
    }
    
    
    
    struct StartingAmountLine: View {
        @AppStorage("useWholeNumbers") var useWholeNumbers = false
    
        @Environment(\.layoutDirection) private var layoutDirection: LayoutDirection
        @Environment(CalendarModel.self) var calModel
        
        @Bindable var startingAmount: CBStartingAmount
        var payMethod: CBPaymentMethod
        @State private var showDialog = false
        @FocusState var focusedField: Int?
        var focusID: Int
        
        var body: some View {
            HStack {
                Image(systemName: "circle.fill")
                    .foregroundStyle(payMethod.color)
                Text("\(payMethod.title)")
                Spacer()
                
                Group {
                    #if os(iOS)
                    UITextFieldWrapperFancy(placeholder: "Starting Amount", text: $startingAmount.amountString, toolbar: {
                        KeyboardToolbarView(
                            focusedField: $focusedField,
                            accessoryText1: "AutoFill",
                            accessoryFunc1: {
                                if calModel.sMonth.num != 0 {
                                    let targetMonth = calModel.months.filter { $0.num == calModel.sMonth.num - 1 }.first!
                                    calModel.calculateTotalForMonth(month: targetMonth, paymentMethod: payMethod)
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
                                    calModel.calculateTotalForMonth(month: targetMonth, paymentMethod: payMethod)
                                    let eodTotal = targetMonth.days.last!.eodTotal
                                    startingAmount.amountString = eodTotal.currencyWithDecimals(useWholeNumbers ? 0 : 2)
                                }
                            }
                        }
                    #endif
                }
                .focused($focusedField, equals: focusID)
                .onChange(of: focusedField) { oldValue, newValue in
                    if newValue == focusID {
                        if startingAmount.amount == 0.0 {
                            startingAmount.amountString = ""
                        }
                    } else {
                        if oldValue == focusID && !startingAmount.amountString.isEmpty {
                            if startingAmount.amountString == "$" || startingAmount.amountString == "-$" {
                                startingAmount.amountString = ""
                            } else {
                                startingAmount.amountString = startingAmount.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
                            }
                        }
                    }
                }
            }
        }
    }
}
