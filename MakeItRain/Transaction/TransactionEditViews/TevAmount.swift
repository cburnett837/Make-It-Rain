//
//  TransactionEditViewAmount.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/2/25.
//

import SwiftUI

struct TevAmount: View {
    @AppStorage("useCalculatorKeyboard") private var persistentUseCalculator = false
    @Environment(CalendarModel.self) private var calModel
    @Environment(AppStore.self) private var store
    
    @Bindable var trans: CBTransaction
    var focusedField: FocusState<Int?>.Binding
    
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
        .onChange(of: focusedField.wrappedValue) { oldFocus, newFocus in
            let transCur = trans.country?.currencyCode
            let setCur = AppState.shared.country.currencyCode
            
            let didFocus = newFocus == 1
            let didUnfocus = oldFocus == 1
            
            if didUnfocus {
                /// When unfocusing the field, format the currency with symbol & commas.
//                trans.amountString = CurrencyHelpers.formatAmountText(
//                    amount: trans.amount,
//                    currencyCode: trans.country?.currencyCode ?? "USD"
//                )
//                
                trans.amountString = trans.amount.currencyWithDecimals(currencyCode: trans.country?.currencyCode ?? "USD")
                
            } else if didFocus {
                /// When focusing the field, remove the currency symbol and commas.
//                if let cleaned = CurrencyHelpers.cleanAmountString(trans.amountString, currencyCode: transCur ?? setCur) {
//                    trans.amountString = cleaned
//                }
                
                trans.amountString = CurrencyHelpers.cleanAmountString(trans.amountString, currencyCode: transCur ?? setCur)
                
                /// If the field is blank, when switching between payment methods, toggle the "-" if applicable to respect an expense/payment.
                if trans.amountString.isEmpty && trans.payMethod?.isDebitOrCash == true {
                    trans.amountString = "-"
                }
            }
        }
        /// Keep the amount in sync with the payment method at the time the payment method was changed.
        .onChange(of: trans.payMethod) { oldMeth, newMeth in
            guard let oldMeth, let newMeth else { return }
            
            if let methCunt = newMeth.country {
                trans.country = methCunt
            }
            
            if (oldMeth.isDebitOrCash && newMeth.isCreditOrLoan) || (oldMeth.isCreditOrLoan && newMeth.isDebitOrCash) {
                Helpers.plusMinus($trans.amountString)
            }
        }
    }
    
//    var showConversionOne: Bool {
//        
//    }
    
    @ViewBuilder
    var amountRow: some View {
        HStack(spacing: 0) {
            Label {
                Text("")
            } icon: {
                Image(systemName: "dollarsign.circle")
                    .foregroundStyle(.gray)
            }
            
            /// Wrap in LabeledContent since the mac sheet is in a form. Using LabeledContent will push the text to the leading edge.
            LabeledContent {
                VStack(alignment: .leading) {
                    amountTextField
                                        
                    if let converted = CurrencyHelpers.convertedDisplayAmountForTransLineItem(
                        trans: trans,
                        months: calModel.months,
                        convertUsing: .amount,
                        convertTo: trans.payMethod?.country?.currencyCode != trans.country?.currencyCode ? trans.payMethod?.country?.currencyCode : nil
                    ) {
                        let setCode = AppState.shared.country.currencyCode
                        let methCode = trans.payMethod?.country?.currencyCode
                        let cuntCode = trans.country?.currencyCode
                        
                        if methCode != cuntCode && cuntCode != nil, let methCode {
                            Text("\(methCode): \(converted.currencyWithDecimals(currencyCode: methCode))")
                                .foregroundStyle(.secondary)
                                .font(.caption2)
                            
                        } else if methCode != setCode {
                            Text("\(setCode): \(converted.currencyWithDecimals(currencyCode: setCode))")
                                .foregroundStyle(.secondary)
                                .font(.caption2)
                        }
                        
                        if methCode != cuntCode && methCode != setCode && cuntCode != setCode {
                            if let converted = CurrencyHelpers.convertedDisplayAmountForTransLineItem(
                                trans: trans,
                                months: calModel.months,
                                convertUsing: .amount,
                                convertTo: setCode
                            ) {
                                Text("\(setCode): \(converted.currencyWithDecimals(currencyCode: setCode))")
                                    .foregroundStyle(.secondary)
                                    .font(.caption2)
                            }
                        }

                        
//                        if methCode != cuntCode || methCode != setCode {
//                            if let curCode = trans.country?.currencyCode,
//                               let exchangeRate = CurrencyHelpers.getMostRecentExchangeRate(for: curCode, months: calModel.months) {
//                                Text("Converstion Rate: \(exchangeRate.currencyWithDecimals(currencyCode: curCode))")
//                                    .foregroundStyle(.secondary)
//                                    .font(.caption2)
//                            }
//                        }
                        
                        
                        
                    }
//                    
//                    if let cunt = trans.country {
//                        let setCunt = AppState.shared.country
//                        if cunt != setCunt {
//                            let USA = Countries.fetch(by: 225)!
//                            
//                            if let usdAmount = trans.amountUsd,
//                               let converted = Countries.convert(amount: trans.amount, from: cunt, to: setCunt) {
//                                Text("Converted to \(CurrencyHelpers.formatAmountText(amount: converted, currencyCode: setCunt.currencyCode))")
//                                    .foregroundStyle(.secondary)
//                                    .font(.caption2)
//                            }
//                        }
//                    }
                }
               
            } label: {
                EmptyView()
            }
            .labelsHidden()
        }
    }
    
    @State private var showCountrySheet = false
    var amountTextField: some View {
        Group {
            #if os(iOS)
            UITextFieldWrapper(placeholder: "Amount", text: $trans.amountString, toolbar: {
                KeyboardToolbarView2(
                    focusedField: focusedField.projectedValue,
                    disableDown: true,
                    view1: {
                        AnyView(
                            Button {
                                focusedField.wrappedValue = nil
                                showCountrySheet = true
                            } label: {
                                Text(trans.country?.flagEmoji ?? Countries.homeCountry.flagEmoji)
                            }
                            .sheet(isPresented: $showCountrySheet, onDismiss: {
                                focusedField.wrappedValue = 1
                            }) {
                                CountryPicker(country: $trans.country)
                            }
                            
//                            Menu {
//                                ForEach(Countries.list) { country in
//                                    Button {
//                                        trans.country = country
//                                        if !trans.amountString.isEmpty {
//                                            trans.amountString = CurrencyHelpers.formatAmountText(
//                                                amount: trans.amount,
//                                                currencyCode: country.currencyCode
//                                            )
//                                        }
//                                        
//                                    } label: {
//                                        Text("\(country.flagEmoji) \(country.name) (\(country.currencyCode))")
//                                            .foregroundStyle(.gray)
//                                            .font(.subheadline)
//                                    }
//                                }
//                            } label: {
//                                Text(trans.country?.flagEmoji ?? Countries.homeCountry.flagEmoji)
//                                //Image(systemName: "dollarsign")
//                            }
//                            .schemeBasedTint()
                        )
                    },
                    view2: {
                        AnyView(
                            Button {
                                changeView()
                            } label: {
                                Image(systemName: useCalculator ? "numbers" : "square.grid.4x3.fill")
                            }
                            .schemeBasedTint()
                        )
                    },
                    view4: {
                        AnyView(
                            Button {
                                Helpers.plusMinus($trans.amountString)
                            } label: {
                                Image(systemName: "plus.forwardslash.minus")
                            }
                            .schemeBasedTint()
                        )
                    }
                )
//                
//                KeyboardToolbarView(
//                    focusedField: focusedField.projectedValue,
//                    disableDown: true,
//                    accessoryImage3: useCalculator ? "numbers" : "square.grid.4x3.fill",
//                    accessoryFunc3: { changeView() },
//                    accessoryImage4: useCalculator ? nil : "plus.forwardslash.minus",
//                    accessoryFunc4: useCalculator ? nil : { Helpers.plusMinus($trans.amountString) }
//                )
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
//        .formatCurrencyLiveAndOnUnFocus(
//            focusValue: 1,
//            focusedField: focusedField.wrappedValue,
//            amountString: trans.amountString,
//            amountStringBinding: $trans.amountString,
//            amount: trans.amount
//        )
//        .onChange(of: trans.amountString) {
//            if let thing = Helpers.parseAmount(trans.amountString) {
//                trans.amountString = String(thing)
//            } else {
//                trans.amountString = ""
//            }
//        }
    }
    
    
    var calculatorToggleButton: some View {
        Button {
            changeView()
        } label: {
            Image(systemName: useCalculator ? "numbers" : "square.grid.4x3.fill")
        }
        .schemeBasedTint()
    }
    
    var plequalsButton: some View {
        Button {
            Helpers.plusMinus($trans.amountString)
        } label: {
            Image(systemName: "plus.forwardslash.minus")
        }
        .schemeBasedTint()
    }
    
    
    func changeView() {
        //print("-- \(#function)")
        useCalculator.toggle()
        DispatchQueue.main.async/*After(deadline: .now() + 0.2)*/ {
            focusedField.wrappedValue = 1
        }        
    }
}
