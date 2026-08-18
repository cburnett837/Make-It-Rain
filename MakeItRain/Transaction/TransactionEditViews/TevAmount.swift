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
    @Binding var showCountrySheet: Bool
    var focusedField: FocusState<Int?>.Binding
    
    @State private var useCalculator = false
    //@State private var showCountrySheet = false
    
    var body: some View {
        TransactionAmountRow(
            amountTypeLingo: trans.amountTypeLingo,
            amountString: $trans.amountString,
            originalAmountString: $trans.condataOriginalAmountString,
            payMethodAmountString: $trans.condataPayMethodAmountString,
            isCalculator: useCalculator
            //foreignAmount: $trans.
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
//        .onChange(of: focusedField.wrappedValue) { oldFocus, newFocus in
//            let setCur = AppState.shared.country.currencyCode
//            
//            let didFocus = newFocus == 1
//            let didUnfocus = oldFocus == 1
//            
//            if didUnfocus {
//                /// When unfocusing the field, format the currency with symbol & commas.
//                trans.amountString = trans.amount.currencyWithDecimals(currencyCode: setCur)
//                
//            } else if didFocus {
//                /// When focusing the field, remove the currency symbol and commas.
//                trans.amountString = CurrencyHelpers.cleanAmountString(trans.amountString, currencyCode: setCur)
//                
//                /// If the field is blank, when switching between payment methods, toggle the "-" if applicable to respect an expense/payment.
//                if trans.amountString.isEmpty && trans.payMethod?.isDebitOrCash == true {
//                    trans.amountString = "-"
//                }
//            }
//        }
        /// Keep the amount in sync with the payment method at the time the payment method was changed.
//        .onChange(of: trans.payMethod) { oldMeth, newMeth in
//            guard let oldMeth, let newMeth else { return }
////            
////            if let methCunt = newMeth.country {
////                trans.country = methCunt
////            }
//            
//            if (oldMeth.isDebitOrCash && newMeth.isCreditOrLoan) || (oldMeth.isCreditOrLoan && newMeth.isDebitOrCash) {
//                Helpers.plusMinus($trans.amountString)
//                Helpers.plusMinus($trans.condataOriginalAmountString)
//                Helpers.plusMinus($trans.condataPayMethodAmountString)
//            }
//        }
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
                                        
                    if trans.condataOriginalCountry != AppState.shared.country || trans.payMethod?.country != AppState.shared.country {
                        HStack(spacing: 0) {
                            if let cunt = trans.condataOriginalCountry {
                                Text(trans.condataOriginalAmount.currencyWithDecimals(currencyCode: cunt.currencyCode))
                            }
                            
                            if let methCurCode = trans.payMethod?.country?.currencyCode, methCurCode != AppState.shared.country.currencyCode {
                                Text(" / ")
                                Text("(\(trans.condataPayMethodAmount.currencyWithDecimals(currencyCode: methCurCode)))")
                            }
                        }
                        .foregroundStyle(.secondary)
                        .font(.caption2)
                    }
                    
                }
               
            } label: {
                EmptyView()
            }
            .labelsHidden()
        }
    }
    
    
    @ViewBuilder
    var amountTextField: some View {
        var placeholder: String {
            if trans.condataOriginalCountry == nil {
                "Amount"
            } else {
                "Amount (\(AppState.shared.country.currencyCode))"
            }
        }
        
        Group {
            #if os(iOS)
            UITextFieldWrapper(
                placeholder: placeholder,
                text: $trans.amountString,
                onClear: {
                    trans.condataOriginalAmountString = ""
                }, toolbar: {
                    KeyboardToolbarView2(
                        focusedField: focusedField.projectedValue,
                        disableDown: true,
                        view1: { AnyView(showCountryButton) },
                        view2: { AnyView(calculatorToggleButton) },
                        view4: { AnyView(plequalsButton) }
                    )
                }
            )
            .uiTag(1)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.left)
            .uiKeyboardType(useCalculator ? .custom(.calculator) : .custom(.numpad))
            #else
            TextField("", text: $trans.amountString, prompt: Text(placeholder)
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .light))
            )
            #endif
        }
//        .sheet(isPresented: $showCountrySheet, onDismiss: {
//            focusedField.wrappedValue = 1
//        }) {
//            CountryPicker(country: $trans.condataOriginalCountry)
//        }
        .focused(focusedField.projectedValue, equals: 1)
    }
    
    
    var showCountryButton: some View {
//        NavigationLink {
//            CountryPicker(country: $trans.condataOriginalCountry)
//        } label: {
//            if trans.condataOriginalCountry == nil {
//                FlagCircle(code: trans.condataOriginalCountry?.code ?? Countries.homeCountry.code)
//            } else {
//                Image(systemName: "flag")
//            }
//        }
//        .disabled(trans.condataOriginalCountry != nil)
//        
        Button {
            //focusedField.wrappedValue = nil
            showCountrySheet = true
        } label: {
//            if trans.condataOriginalCountry == nil {
//                FlagCircle(code: trans.condataOriginalCountry?.code ?? Countries.homeCountry.code)
//            } else {
//                Image(systemName: "flag")
//            }
            
            Image(systemName: "flag")
            
        }
        .schemeBasedTint()
        .disabled(trans.condataOriginalCountry != nil && trans.condataOriginalCountry != AppState.shared.country)
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
            Helpers.plusMinus($trans.condataOriginalAmountString)
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








struct TevAmountSAFE: View {
    @AppStorage("useCalculatorKeyboard") private var persistentUseCalculator = false
    @Environment(CalendarModel.self) private var calModel
    @Environment(AppStore.self) private var store
    
    @Bindable var trans: CBTransaction
    @Binding var showConverterSheet: Bool
    var focusedField: FocusState<Int?>.Binding
    
    @State private var useCalculator = false
    //@State private var showCountrySheet = false
    
    var body: some View {
        TransactionAmountRow(
            amountTypeLingo: trans.amountTypeLingo,
            amountString: $trans.amountString,
            originalAmountString: $trans.condataOriginalAmountString,
            payMethodAmountString: $trans.condataPayMethodAmountString,
            isCalculator: useCalculator
            //foreignAmount: $trans.
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
            let setCur = AppState.shared.country.currencyCode
            
            let didFocus = newFocus == 1
            let didUnfocus = oldFocus == 1
            
            if didUnfocus {
                /// When unfocusing the field, format the currency with symbol & commas.
                trans.amountString = trans.amount.currencyWithDecimals(currencyCode: setCur)
                
            } else if didFocus {
                /// When focusing the field, remove the currency symbol and commas.
                trans.amountString = CurrencyHelpers.cleanAmountString(trans.amountString, currencyCode: setCur)
                
                /// If the field is blank, when switching between payment methods, toggle the "-" if applicable to respect an expense/payment.
                if trans.amountString.isEmpty && trans.payMethod?.isDebitOrCash == true {
                    trans.amountString = "-"
                }
            }
        }
        /// Keep the amount in sync with the payment method at the time the payment method was changed.
        .onChange(of: trans.payMethod) { oldMeth, newMeth in
            guard let oldMeth, let newMeth else { return }
//
//            if let methCunt = newMeth.country {
//                trans.country = methCunt
//            }
            
            if (oldMeth.isDebitOrCash && newMeth.isCreditOrLoan) || (oldMeth.isCreditOrLoan && newMeth.isDebitOrCash) {
                Helpers.plusMinus($trans.amountString)
                Helpers.plusMinus($trans.condataOriginalAmountString)
                Helpers.plusMinus($trans.condataPayMethodAmountString)
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
                                        
                    HStack(spacing: 0) {
                        if let cunt = trans.condataOriginalCountry {
                            Text(trans.condataOriginalAmount.currencyWithDecimals(currencyCode: cunt.currencyCode))
                        }
                        
                        if let methCurCode = trans.payMethod?.country?.currencyCode, methCurCode != AppState.shared.country.currencyCode {
                            Text(" / ")
                            Text("(\(trans.condataPayMethodAmount.currencyWithDecimals(currencyCode: methCurCode)))")
                        }
                    }
                    .foregroundStyle(.secondary)
                    .font(.caption2)
                    
                }
               
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
                KeyboardToolbarView2(
                    focusedField: focusedField.projectedValue,
                    disableDown: true,
                    view1: {
                        AnyView(
                            Button {
                                //focusedField.wrappedValue = nil
                                showConverterSheet = true
                            } label: {
                                FlagCircle(code: trans.condataOriginalCountry?.code ?? Countries.homeCountry.code)
                            }
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
                                Helpers.plusMinus($trans.condataOriginalAmountString)
                            } label: {
                                Image(systemName: "plus.forwardslash.minus")
                            }
                            .schemeBasedTint()
                        )
                    }
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
//        .sheet(isPresented: $showCountrySheet, onDismiss: {
//            focusedField.wrappedValue = 1
//        }) {
//            CountryPicker(country: $trans.condataOriginalCountry)
//        }
        .focused(focusedField.projectedValue, equals: 1)
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
