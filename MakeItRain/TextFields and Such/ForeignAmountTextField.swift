//
//  ForeignAmountTextField.swift
//  MakeItRain
//
//  Created by Cody Burnett on 8/1/26.
//


import SwiftUI

struct ForeignAmountTextField<T: CurrencyConvertable & Observation.Observable>: View {
//    @AppStorage("useCalculatorKeyboard") private var persistentUseCalculator = false
//    @State private var useCalculator = false
    
    @Bindable var obj: T
    @Binding var showCountrySheet: Bool
    var focusedField: FocusState<Int?>.Binding
    var editOriginalAmount: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            Label {
                Text("")
            } icon: {
                if let cunt = obj.condataOriginalCountry {
                    FlagCircle(code: cunt.code)
                } else {
                    Image(systemName: "dollarsign.circle")
                        .foregroundStyle(.gray)
                }
            }
            
            TransactionAmountRow(
                amountTypeLingo: obj.amountTypeLingo,
                amountString: $obj.amountString,
                originalAmountString: $obj.condataOriginalAmountString,
                payMethodAmountString: $obj.condataPayMethodAmountString,
//                isCalculator: useCalculator,
                isCalculator: false
            ) {
                foreignCurrencyTextField
            }
        }
        .opacity(editOriginalAmount ? 1 : 0)
    }
    
    
    var foreignCurrencyTextField: some View {
        #if os(iOS)
        Group {
            UITextFieldWrapper(placeholder: "Amount (\(obj.condataOriginalCountry?.currencyCode ?? "Foreign"))", text: $obj.condataOriginalAmountString, toolbar: {
                KeyboardToolbarView2(
                    focusedField: focusedField,
                    disableDown: true,
                    view1: { AnyView(showCountryButton) },
//                    view2: { AnyView(calculatorToggleButton) },
                    view4: { AnyView(plequalsButton) }
                )
            })
            .uiTag(10)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.left)
            .uiKeyboardType(.custom(.numpad))
//            .uiKeyboardType(useCalculator ? .custom(.calculator) : .custom(.numpad))
        }
        .focused(focusedField, equals: 10)
//        .task { useCalculator = persistentUseCalculator }
//        .onChange(of: useCalculator) { persistentUseCalculator = $1 }
        #else
        TextField("", text: $obj.condataOriginalAmountString, prompt: Text("Foreign Amount")
            .foregroundColor(.gray)
            .font(.system(size: 14, weight: .light))
        )
        #endif
    }
    
    var showCountryButton: some View {
        Button {
            showCountrySheet = true
        } label: {
            FlagCircle(code: obj.condataOriginalCountry?.code ?? Countries.homeCountry.code)
        }
        
    }
    
//    var calculatorToggleButton: some View {
//        Button {
//            changeView()
//        } label: {
//            Image(systemName: useCalculator ? "numbers" : "square.grid.4x3.fill")
//        }
//        .schemeBasedTint()
//    }
    
    var plequalsButton: some View {
        Button {
            //Helpers.plusMinus($obj.amountString)
            Helpers.plusMinus($obj.condataOriginalAmountString)
        } label: {
            Image(systemName: "plus.forwardslash.minus")
        }
        .schemeBasedTint()
    }
    
//    func changeView() {
//        //print("-- \(#function)")
//        useCalculator.toggle()
//        DispatchQueue.main.async/*After(deadline: .now() + 0.2)*/ {
//            focusedField.wrappedValue = 10
//        }
//    }
}


struct ForeignAmountToolsScroller<T: CurrencyConvertable & Observation.Observable>: View {
    @Environment(CalendarModel.self) private var calModel
    @Environment(AppStore.self) private var store
    
    let converter = CurrencyConverter()
    
    @Bindable var obj: T
    @Binding var editOriginalAmount: Bool
    @Binding var showCountrySheet: Bool
    var focusedField: FocusState<Int?>.Binding
    var showCountryOptions = true
    
    var quickPickCountries: [Country] {
        let countries = Countries.list.filter {
            var theList: Array<String?> = []
            
            /// Add original currency country if it doesn't match the app's country
            if let cuntCode = obj.condataOriginalCountry?.code, cuntCode != AppState.shared.country.code {
                theList.append(cuntCode)
            }
            
            /// Add payment methods  country if it doesn't match the app's country
            if let cuntCode = obj.payMethod?.country?.code, cuntCode != AppState.shared.country.code {
                theList.append(cuntCode)
            }
            
            /// Only add the home country if the original currency country is different.
            if obj.condataOriginalCountry != nil {
                theList.append(Countries.homeCountry.code)
            }
            
            /// Only add the currnet location country if it is different from the apps country.
            if LocationManager.shared.currentCountry != AppState.shared.country.code {
                theList.append(LocationManager.shared.currentCountry)
            }
                
            return theList.contains($0.code)
        }
        
        return Array(Set(countries)).sorted { $0.name < $1.name }
    }
    
    var showTools: Bool {
        /// 1. If a foreign country is set, show the edit button.
        /// 2. If you are editing, and a foreign country is set, show the clear button.
        /// 3. Are editing
        /// 4. Are editing & the country list is populated
        /// 5. Are editing & away from home country (Changing an existing foreign amount when away from home)
        /// 6. Are not editing & away from home country & a foreign country is not set. (Like when adding a new trans when away from home)
        obj.condataOriginalCountry != nil
        || (editOriginalAmount && obj.condataOriginalCountry != nil)
        || editOriginalAmount
        || (!quickPickCountries.isEmpty && editOriginalAmount)
        || (editOriginalAmount && AppState.shared.isAwayFromHomeCountry)
        || (!editOriginalAmount && AppState.shared.isAwayFromHomeCountry && obj.condataOriginalCountry == nil)
    }
    
    var body: some View {
        if showTools {
            ScrollView(.horizontal) {
                HStack {
                    
                    /// If a foreign country is set, show the edit button.
                    if obj.condataOriginalCountry != nil {
                        editOriginalButton
                    }
                    
                    /// If you are editing, and a foreign country is set, show the clear button.
                    if editOriginalAmount && obj.condataOriginalCountry != nil {
                        clearCountryButton
                    }
                    
                    if showCountryOptions {
                        /// if you...
                        /// 1. Are editing
                        /// 2. Are editing & the country list is populated
                        /// 3. Are editing & away from home country (Changing an existing foreign amount when away from home)
                        /// 4. Are not editing & away from home country & a foreign country is not set. (Like when adding a new trans when away from home)
                        if editOriginalAmount
                        || (!quickPickCountries.isEmpty && editOriginalAmount)
                        || (editOriginalAmount && AppState.shared.isAwayFromHomeCountry)
                        || (!editOriginalAmount && AppState.shared.isAwayFromHomeCountry && obj.condataOriginalCountry == nil) {
                            ForEach(quickPickCountries) { quickPickCountryButton(for: $0) }
                            
                            moreButton
                        }
                    }
                    
                }
            }
            .scrollIndicators(.hidden)
        } else {
            EmptyView()
        }
        
    }
    
    
    @ViewBuilder
    func quickPickCountryButton(for country: Country) -> some View {
        Button {
            obj.condataOriginalCountry = country
            
            if !editOriginalAmount {
                obj.condataOriginalAmountString = obj.amountString
                converter.convert(obj: obj, calModel: calModel)
            }
        } label: {
            HStack {
                FlagCircle(code: country.code, size: 14)
                Text(country.currencyCode)
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
                .opacity(obj.condataOriginalCountry?.id == country.id ? 1 : 0)
        )
    }
    
    
    var moreButton: some View {
//        NavigationLink {
//            CountryPicker(country: $trans.condataOriginalCountry)
//        } label: {
//            Text("More…")
//                .foregroundStyle(.gray)
//                .font(.subheadline)
//                #if os(iOS)
//                .padding(8)
//                .background(Capsule().foregroundStyle(.thickMaterial))
//                #else
//                .buttonStyle(.roundMacButton(horizontalPadding: 10))
//                #endif
//        }

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
    
    
    var editOriginalButton: some View {
        Button {
            if editOriginalAmount {
                converter.convert(obj: obj, calModel: calModel)
                withAnimation {
                    editOriginalAmount = false
                    focusedField.wrappedValue = nil
                }
                
            } else {
                withAnimation {
                    editOriginalAmount = true
                    focusedField.wrappedValue = 10
                }
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                    focusedField = 10
//                }
            }
        } label: {
            Text(editOriginalAmount ? "Done" : "Edit \(obj.condataOriginalCountry?.currencyCode ?? "")")
                .foregroundStyle(editOriginalAmount ? Color.theme : .gray)
                //.foregroundStyle(.gray)
                .font(.subheadline)
            
        }
        #if os(iOS)
        .padding(8)
        .background(Capsule().foregroundStyle(.thickMaterial))
        #else
        .buttonStyle(.roundMacButton(horizontalPadding: 10))
        #endif
    }
    
    
    var clearCountryButton: some View {
        Button {
            obj.condataOriginalAmountString = ""
            obj.condataOriginalCountry = nil
            obj.condataOriginCountryToPayMethodCountryExchangeRate = nil
            obj.condataPayMethodCountryToAccountCountryExchangeRate = nil
            obj.condataPayMethodAmountString = ""
            withAnimation { editOriginalAmount = false }
        } label: {
            Text("Reset")
                .foregroundStyle(.red)
                .font(.subheadline)
            
        }
        #if os(iOS)
        .padding(8)
        .background(Capsule().foregroundStyle(.thickMaterial))
        #else
        .buttonStyle(.roundMacButton(horizontalPadding: 10))
        #endif
    }
    
}
