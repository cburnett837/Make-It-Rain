//
//  CurrencyConverterSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 7/29/26.
//

import SwiftUI

protocol CurrencyConvertable: AnyObject {
    var date: Date? {get set}
    var payMethod: CBPaymentMethod? {get set}
    /// AMOUNT DETAILS
    var country: Country? {get set}
    var amountString: String {get set}
    var amount: Decimal {get}
    
    /// PRECONVERSION AMOUNT DETAILS
    var condataOriginalCountry: Country? {get set}
    var condataOriginalAmountString: String {get set}
    var condataOriginalAmount: Decimal {get}
    
    /// CONVERSION DETAILS
    var condataOriginCountryToPayMethodCountryExchangeRate: Decimal? {get set}
    var condataPayMethodCountryToAccountCountryExchangeRate: Decimal? {get set}
    var condataPayMethodAmountString: String {get set}
    var condataPayMethodAmount: Decimal {get}
    
    var hostExRate: Decimal? {get set}
    
    var amountTypeLingo: String {get}
}

struct CurrencyConverter {
    @MainActor
    func convert<T: CurrencyConvertable & Observation.Observable>(obj: T, calModel: CalendarModel) {
        /// NOTE! All exchange rates are in USD. So when going from COP to GBP, convert via USD.
        guard let cunt = obj.condataOriginalCountry,
            let date = obj.date,
              
            /// Get the USD exchange rate for currency of the origin country.
            let fromExRate = CurrencyHelpers.getExchangeRate(date: date, currencyCode: cunt.currencyCode, months: calModel.months),
              
            /// Get the USD exchange rate for the currency of the selected payment method's country.
            let payMethExRate = CurrencyHelpers.getExchangeRate(date: date, currencyCode: obj.payMethod?.country?.currencyCode ?? "USD", months: calModel.months),
              
            /// Get the USD exchange rate.
            let usdExRate = CurrencyHelpers.getExchangeRate(date: date, currencyCode: "USD", months: calModel.months),
              
            /// Get the USD exchange rate for the appwide currency.
            let hostExRate = CurrencyHelpers.getExchangeRate(date: date, currencyCode: AppState.shared.country.currencyCode, months: calModel.months),
            
                
            /// Convert from the origin country to USD.
            let usdAmount = CurrencyHelpers.convert(amount: obj.condataOriginalAmount, fromRate: fromExRate, toRate: usdExRate),
                
            /// Convert from USD to pay method currency.
            let payMethAmount = CurrencyHelpers.convert(amount: usdAmount, fromRate: usdExRate, toRate: payMethExRate),
            
            /// Convert from the origin country to the payment methods country.
            //let payMethAmount = CurrencyHelpers.convert(amount: trans.condataOriginalAmount, fromRate: fromExRate, toRate: payMethExRate),
                                            
            /// Convert from the dest payment method's country rate to App currency.
            let finalAmount = CurrencyHelpers.convert(amount: payMethAmount, fromRate: payMethExRate, toRate: hostExRate)
        else {
            return
        }
        
        print("Setting here 🐱, rawAmount: \(obj.condataOriginalAmount), fromRate: \(fromExRate), payMethRate: \(payMethExRate), usdRate: \(usdExRate), usdAmount: \(usdAmount), payMethAmount: \(payMethAmount)")
        
        
        obj.country = AppState.shared.country
        obj.amountString = finalAmount.currencyWithDecimals(currencyCode: AppState.shared.country.currencyCode)
                                
        obj.condataPayMethodAmountString = payMethAmount.currencyWithDecimals(currencyCode: obj.payMethod?.country?.currencyCode)
        
        obj.condataOriginCountryToPayMethodCountryExchangeRate = fromExRate
        obj.condataPayMethodCountryToAccountCountryExchangeRate = payMethExRate
        
        obj.hostExRate = hostExRate
    }
    
    
    func formatCurrency<T: CurrencyConvertable & Observation.Observable>(obj: T, oldFocus: Int?, newFocus: Int?) {
        let setCur = AppState.shared.country.currencyCode
        let selCur = obj.condataOriginalCountry?.currencyCode
        
        let didFocus = newFocus == 1
        let didUnfocus = oldFocus == 1
        
        if didUnfocus {
            /// When unfocusing the field, format the currency with symbol & commas.
            obj.condataOriginalAmountString = obj.condataOriginalAmount.currencyWithDecimals(currencyCode: selCur ?? setCur)
            
        } else if didFocus {
            /// When focusing the field, remove the currency symbol and commas.
            obj.condataOriginalAmountString = CurrencyHelpers.cleanAmountString(obj.condataOriginalAmountString, currencyCode: selCur ?? setCur)
            
            /// If the field is blank, when switching between payment methods, toggle the "-" if applicable to respect an expense/payment.
            if obj.condataOriginalAmountString.isEmpty && obj.payMethod?.isDebitOrCash == true {
                obj.condataOriginalAmountString = "-"
            }
        }
    }
    
    func pretty(_ val: Decimal?) -> String {
        if let val {
            return val.formatted(.number.precision(.fractionLength(2)))
        }
        return "N/A"
    }
}

struct CurrencyConverterSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(CalendarModel.self) private var calModel
    
    @Bindable var trans: CBTransaction
    @Bindable var day: CBDay
    @FocusState private var focusedField: Int?
    
    @State private var useCalculator = false
    @State private var showCountrySheet = false
    
    let converter = CurrencyConverter()
    
    //@State private var rawAmountString: String = ""
    //    var rawAmount: Decimal {
    //        CurrencyHelpers.parseAmountStringToDecimal(rawAmountString) ?? 0.0
    //    }
    
    
    //@State private var payMethodRate: Decimal?
    //@State private var exchangeRate: Decimal?
    //@State private var country: Country?
    
//    var countryText: String {
//        if let country = trans.condataOriginalCountry {
//            "\(country.flagEmoji) \(country.currencyCode)"
//        } else {
//            "Select Currency"
//        }
//    }
    
    var payMethodDoesNotMatchAppCurrency: Bool {
        trans.payMethod?.country?.currencyCode != AppState.shared.country.currencyCode
    }
    
//    var finalExRateString: String {
//        let theRate = payMethodDoesNotMatchAppCurrency
//        ? trans.condataPayMethodCountryToAccountCountryExchangeRate
//        : trans.condataOriginCountryToPayMethodCountryExchangeRate
//
//        let theRateString = theRate?.formatted(.number.precision(.fractionLength(2)))
//
//        let targetCur = payMethodDoesNotMatchAppCurrency
//        ? trans.payMethod?.country?.currencyCode
//        : trans.condataOriginalCountry?.currencyCode
//
//        //return "1 USD = \(theRateString ?? "N/A") \(targetCur ?? "N/A") "
//        return theRateString ?? "N/A"
//    }
    
    var fromOriginToUsdExRateString: String {
        let theRate = trans.condataOriginCountryToPayMethodCountryExchangeRate
        let theRateString = theRate?.formatted(.number.precision(.fractionLength(2)))
        //return "1 USD = \(theRateString ?? "N/A") \(trans.condataOriginalCountry?.currencyCode ?? "N/A")"
        return theRateString ?? "N/A"
    }
    
    var fromOriginToMethExRateString: String {
        let theRate = trans.condataOriginCountryToPayMethodCountryExchangeRate
        let theRateString = theRate?.formatted(.number.precision(.fractionLength(2)))
        //return "1 USD = \(theRateString ?? "N/A") \(trans.condataOriginalCountry?.currencyCode ?? "N/A")"
        return theRateString ?? "N/A"
    }
    
    var fromMethToAccountExRateString: String {
        let theRate = trans.condataPayMethodCountryToAccountCountryExchangeRate
        let theRateString = theRate?.formatted(.number.precision(.fractionLength(2)))
        //return "1 USD = \(theRateString ?? "N/A") \(trans.payMethod?.country?.currencyCode ?? "N/A")"
        return theRateString ?? "N/A"
    }
    
    var hostExRateString: String {
        let theRateString = trans.hostExRate?.formatted(.number.precision(.fractionLength(2)))
        return theRateString ?? "N/A"
    }
    
    var quickPickCountries: [Country] {
        let countries = Countries.list.filter {
            [
                Countries.homeCountry.code,
                LocationManager.shared.currentCountry,
                trans.payMethod?.country?.code,
                trans.condataOriginalCountry?.code
            ].contains($0.code)
        }
        
        return Array(Set(countries)).sorted { $0.name < $1.name }
    }
    
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    fromTextField
                } header: {
                    Text("From Currency")
                } footer: {
                    quickPickCountriesView
                }
                
                if trans.condataOriginalCountry != nil {
                    exchangeDetailsSection
                }
                
                conversionDetailsSection
                
                Button("Apply Rate of \(trans.amount.currencyWithDecimals(currencyCode: trans.payMethod?.country?.currencyCode ?? "N/A"))") {
                    dismiss()
                }
            }
            .navigationTitle("Converter")
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            #endif
        }
        .onChange(of: trans.date) { converter.convert(obj: trans, calModel: calModel) }
        .onChange(of: trans.payMethod) { converter.convert(obj: trans, calModel: calModel) }
        .onChange(of: trans.condataOriginalAmountString) { converter.convert(obj: trans, calModel: calModel) }
        .onChange(of: trans.condataOriginalCountry) {
            converter.convert(obj: trans, calModel: calModel)
            if focusedField == nil {
                converter.formatCurrency(obj: trans, oldFocus: 1, newFocus: nil)
            } else {
                converter.formatCurrency(obj: trans, oldFocus: nil, newFocus: 1)
            }
        }
        .onChange(of: focusedField) {
            converter.formatCurrency(obj: trans, oldFocus: $0, newFocus: $1)
        }
        .sheet(isPresented: $showCountrySheet) {
            CountryPicker(country: $trans.condataOriginalCountry)
        }
        .task {
            /// Perform the conversions when opening the sheet that way if a payment method gets changed, it will be recalculated.
            if trans.condataOriginalAmountString.isEmpty && !trans.amountString.isEmpty {
                trans.condataOriginalAmountString = trans.amountString
                return
            }
            
            if trans.condataOriginalCountry != nil {
                converter.convert(obj: trans, calModel: calModel)
            }
            
        }
    }
    
    @ViewBuilder
    func line(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
    
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    var fromTextField: some View {
        Group {
            #if os(iOS)
            UITextFieldWrapper(placeholder: "Foreign Amount", text: $trans.condataOriginalAmountString, toolbar: {
                KeyboardToolbarView2(
                    focusedField: $focusedField,
                    disableDown: true,
                    view1: {
                        AnyView(
                            Button {
                                focusedField = nil
                                showCountrySheet = true
                            } label: {
                                FlagCircle(code: trans.condataOriginalCountry?.code ?? Countries.homeCountry.code)
            //                                Text(trans.condataOriginalCountry?.flagEmoji ?? Countries.homeCountry.flagEmoji)
                            }
                        )
                    },
                    view4: {
                        AnyView(
                            Button {
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
            .uiKeyboardType(.custom(.numpad))
            #else
            TextField("", text: $trans.condataOriginalAmountString, prompt: Text("Foreign Amount")
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .light))
            )
            #endif
        }
        
        .focused($focusedField, equals: 1)
        
    }
    
    
    
    var conversionDetailsSection: some View {
        Section {
            TevDatePicker(
                trans: trans,
                day: day,
                focusedField: $focusedField
            )
            
            PayMethodSheetButton(
                text: "Account",
                logoFallBackType: .customImage(.init(
                    name: trans.payMethod?.fallbackImage,
                    color: trans.payMethod?.color
                )),
                payMethod: $trans.payMethod,
                whichPaymentMethods: .allExceptUnified
            )
            
//            if payMethodDoesNotMatchAppCurrency {
//                HStack(spacing: 0) {
//                    Label {
//                        Text("Account Amount")
//                    } icon: {
//                        if let cunt = trans.payMethod?.country {
//                            FlagCircle(code: cunt.code, size: 30)
//                        } else {
//                            Image(systemName: "dollarsign.circle")
//                                .foregroundStyle(.gray)
//                        }
//
//                    }
//                    Spacer()
//                    Text("\(trans.payMethod?.country?.currencyCode ?? "N/A") \(trans.condataPayMethodAmount.currencyWithDecimals(2, currencyCode: trans.payMethod?.country?.currencyCode ?? "N/A"))")
//
//                }
//            }
//
//            HStack(spacing: 0) {
//                Label {
//                    Text("Final Amount")
//                } icon: {
//                    FlagCircle(code: AppState.shared.country.code, size: 30)
//
//                }
//                Spacer()
//                Text("\(AppState.shared.country.currencyCode) \(trans.amount.currencyWithDecimals(2, currencyCode: AppState.shared.country.currencyCode))")
//                    .foregroundStyle(.green)
//            }
//            .bold()
                        
            
            
        } header: {
            Text("Conversion Details")
        }
    }
    
    var exchangeDetailsSection: some View {
        Section("Exchange Details") {
            VStack {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                    GridRow {
//                        HStack {
//                            FlagCircle(code: "us", size: 14)
//                            Text("USD")
//                        }
//
//                        Text("")
                        
                        HStack {
                            FlagCircle(code: AppState.shared.country.code, size: 14)
                            Text(AppState.shared.country.currencyCode)
                        }
                        
                        Text("")
                        
                        HStack {
                            if let cunt = trans.condataOriginalCountry {
                                FlagCircle(code: cunt.code, size: 14)
                                Text(cunt.currencyCode)
                            }
                        }
                        
                        if payMethodDoesNotMatchAppCurrency {
                            Text("")
                            
                            HStack {
                                if let cunt = trans.payMethod?.country {
                                    FlagCircle(code: cunt.code, size: 14)
                                    Text(cunt.currencyCode)
                                }
                            }
                        }
                    }
                    //.font(.caption)
                    .bold()
                    
//                    Divider()
//
//                    GridRow {
//                        Text(hostExRateString)
//
//                        Text("=")
//                            .foregroundStyle(.secondary)
//
//                        Text(fromOriginToMethExRateString)
//
//                        if payMethodDoesNotMatchAppCurrency {
//                            Text("=")
//                                .foregroundStyle(.secondary)
//
//                            Text(fromMethToAccountExRateString)
//                        }
//
//                    }
//                    .padding(.vertical, 5)
                    
                    
                    
                    Divider()
                                        
                    GridRow {
                        Text(converter.pretty(trans.amount))
                        
                        Text("=")
                            .foregroundStyle(.secondary)
                        
                        Text(converter.pretty(trans.condataOriginalAmount))
                        if payMethodDoesNotMatchAppCurrency {
                            Text("=")
                                .foregroundStyle(.secondary)
                            
                            Text(converter.pretty(trans.condataPayMethodAmount))
                        }
                        
                    }
                    .padding(.vertical, 5)
                }
                .font(.caption)
                .lineLimit(1)
                .textCase(nil)
            }
        }
    }
    
    
//    var accountSection: some View {
//        Section {
//            line(
//                title: "Account Amount",
//                value: "\(trans.payMethod?.country?.currencyCode ?? "N/A") \(trans.condataPayMethodAmount.currencyWithDecimals(2, currencyCode: trans.payMethod?.country?.currencyCode ?? "N/A"))"
//            )
//
//            line(
//                title: "\(trans.condataOriginalCountry?.currencyCode ?? "N/A") -> USD",
//                value: methExRateString
//            )
//
//            line(
//                title: "USD -> \(trans.payMethod?.country?.currencyCode ?? "N/A")",
//                value: methExRateString2
//            )
//        } header: {
//            Text("Amount related to meth")
//        } footer: {
//            Text("The conversion rate that will be used to convert from \(trans.condataOriginalCountry?.currencyCode ?? "N/A") to USD to \(trans.payMethod?.country?.currencyCode ?? "N/A")")
//        }
//    }
    
    
//    var finalSection: some View {
//        Section {
//            line(
//                title: "Final Amount",
//                value: "\(AppState.shared.country.currencyCode) \(trans.amount.currencyWithDecimals(2, currencyCode: AppState.shared.country.currencyCode))"
//            )
//
//            line(
//                title: "Exchange Rate",
//                value: finalExRateString
//            )
//        } header: {
//            Text("Converted Amount")
//        } footer: {
//            if payMethodDoesNotMatchAppCurrency {
//                Text("The conversion rate that will be used to convert from \(trans.payMethod?.country?.currencyCode ?? "N/A") to \(AppState.shared.country.currencyCode)")
//            }
//        }
//    }
    
    
    
    
    var quickPickCountriesView: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(quickPickCountries) { quickPickCountryButton(for: $0) }
                
                countryPickerButton
            }
        }
        .scrollIndicators(.hidden)
    }
    
    
    
    
    
    @ViewBuilder
    func quickPickCountryButton(for country: Country) -> some View {
        Button {
            trans.condataOriginalCountry = country
            
            converter.convert(obj: trans, calModel: calModel)
            converter.formatCurrency(obj: trans, oldFocus: nil, newFocus: nil)
            
            if focusedField == nil {
                converter.formatCurrency(obj: trans, oldFocus: 1, newFocus: nil)
            } else {
                converter.formatCurrency(obj: trans, oldFocus: nil, newFocus: 1)
            }
        } label: {
            HStack {
                FlagCircle(code: country.code, size: 14)
                Text("\(country.currencyCode)?")
                    .foregroundStyle(.gray)
                    .font(.subheadline)
            }
        }
        #if os(iOS)
        .padding(8)
        .background(Capsule().foregroundStyle(.thickMaterial))
        #else
        .buttonStyle(.roundMacButton(horizontalPadding: 10))
        #endif
        .overlay(
            Capsule()
                .strokeBorder(Color.theme, lineWidth: 1)
                .opacity(trans.condataOriginalCountry?.id == country.id ? 1 : 0)
                
        )
    }
    
    var countryPickerButton: some View {
        Button {
            showCountrySheet = true
        } label: {
            Text("More…")
                .foregroundStyle(.gray)
                .font(.subheadline)
        }
        #if os(iOS)
        .padding(8)
        .background(Capsule().foregroundStyle(.thickMaterial))
        #else
        .buttonStyle(.roundMacButton(horizontalPadding: 10))
        #endif
    }
    
//    func convert() {
//        /// NOTE! All exchange rates are in USD. So when going from COP to GBP, convert via USD.
//        guard let cunt = trans.condataOriginalCountry,
//            let date = trans.date,
//
//            /// Get the USD exchange rate for currency of the origin country.
//            let fromExRate = CurrencyHelpers.getExchangeRate(date: date, currencyCode: cunt.currencyCode, months: calModel.months),
//
//            /// Get the USD exchange rate for the currency of the selected payment method's country.
//            let payMethExRate = CurrencyHelpers.getExchangeRate(date: date, currencyCode: trans.payMethod?.country?.currencyCode ?? "USD", months: calModel.months),
//
//            /// Get the USD exchange rate.
//            let usdExRate = CurrencyHelpers.getExchangeRate(date: date, currencyCode: "USD", months: calModel.months),
//
//            /// Get the USD exchange rate for the appwide currency.
//            let hostExRate = CurrencyHelpers.getExchangeRate(date: date, currencyCode: AppState.shared.country.currencyCode, months: calModel.months),
//
//
//            /// Convert from the origin country to USD.
//            let usdAmount = CurrencyHelpers.convert(amount: trans.condataOriginalAmount, fromRate: fromExRate, toRate: usdExRate),
//
//            /// Convert from USD to pay method currency.
//            let payMethAmount = CurrencyHelpers.convert(amount: usdAmount, fromRate: usdExRate, toRate: payMethExRate),
//
//            /// Convert from the origin country to the payment methods country.
//            //let payMethAmount = CurrencyHelpers.convert(amount: trans.condataOriginalAmount, fromRate: fromExRate, toRate: payMethExRate),
//
//            /// Convert from the dest payment method's country rate to App currency.
//            let finalAmount = CurrencyHelpers.convert(amount: payMethAmount, fromRate: payMethExRate, toRate: hostExRate)
//        else {
//            return
//        }
//
//        print("Setting here 🐱, rawAmount: \(trans.condataOriginalAmount), fromRate: \(fromExRate), payMethRate: \(payMethExRate), usdRate: \(usdExRate), usdAmount: \(usdAmount), payMethAmount: \(payMethAmount)")
//
//
//        trans.country = AppState.shared.country
//        trans.amountString = finalAmount.currencyWithDecimals(currencyCode: AppState.shared.country.currencyCode)
//
//        trans.condataPayMethodAmountString = payMethAmount.currencyWithDecimals(currencyCode: trans.payMethod?.country?.currencyCode)
//
//        trans.condataOriginCountryToPayMethodCountryExchangeRate = fromExRate
//        trans.condataPayMethodCountryToAccountCountryExchangeRate = payMethExRate
//
//
//
//
//
//
//        /*
//         DB columns
//         amount --> finalAmount
//         amount_country_id --> AppState.shared.country.currencyCode
//
//         convertedmetadata__pay_method_amount (addcolumn) --> payMethAmount
//         convertedmetadata__pay_method_country_id (addcolumn) --> trans.payMethod?.country?.currencyCode
//
//         convertedmetadata__original_amount (currently original_unconverted_amount) --> rawAmount
//         convertedmetadata__original_country_id (currently country_id) --> country
//
//         convertedmetadata__origin_country_to_pay_method_country_exchange_rate --> fromExRate
//         convertedmetadata__pay_method_country_to_account_country_exchange_rate --> payMethExRate
//         */
//
//    }
    
}
