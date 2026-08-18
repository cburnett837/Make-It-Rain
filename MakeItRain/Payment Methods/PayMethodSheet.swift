//
//  PayMethodSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/21/24.
//

import SwiftUI

struct PayMethodSheet: View {
    private enum WhichView: String { case select, edit }
        
    @AppStorage("paymentMethodSheetViewMode") private var paymentMethodSheetViewMode: WhichView = .select    
    @Local(\.useBusinessLogos) var useBusinessLogos

    @Environment(\.layoutDirection) private var layoutDirection: LayoutDirection
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss)private var dismiss
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(PlaidModel.self) private var plaidModel
    @Environment(FuncModel.self) private var funcModel
    
    @FocusState private var focusedField: Int?
    @State private var searchText = ""
    
    @Binding var payMethod: CBPaymentMethod?
    let whichPaymentMethods: ApplicablePaymentMethods
    var isPendingSmartTransaction: Bool = false
    var showStartingAmountOption: Bool = false
    var showNoneOption: Bool = false
    var noneText: String = "Show all transactions and their daily sum."
    //let theSections: [PaymentMethodSection] = [.debit, .credit, .other]
    
    var monthText: String {
        if calModel.isPlayground {
            "\(calModel.sMonth.name) Playground"
        } else {
            "\(calModel.sMonth.actualNum)/\(String(calModel.sMonth.year))"
        }
    }
  
    
    var body: some View {
        let _ = Self._printChanges()
        NavigationStack {
            StandardContainerWithToolbar(.list, scrollDismissesKeyboard: .never) {
                if paymentMethodSheetViewMode == .select {
                    methList
                    
                    if showNoneOption {
                        noneSection
                    }
                } else {
                    startingAmountsList
                }
            }
            .onAppear {
                if !showStartingAmountOption {
                    self.paymentMethodSheetViewMode = .select
                }
            }
            .task { prepareView() }
            #if os(iOS)
            .searchable(text: $searchText, prompt: Text("Search"))
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .title) {
                    if showStartingAmountOption {
                        Picker("", selection: $paymentMethodSheetViewMode) {
                            Text("Accounts")
                                .tag(WhichView.select)
                            Text("Amounts")
                                .tag(WhichView.edit)
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                    } else {
                        Text("Accounts")
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) { moreMenu }
                if AppState.shared.isIphone {
                    ToolbarItem(placement: .bottomBar) { PayMethodFilterMenu() }
                }
                
                ToolbarSpacer(.flexible, placement: AppState.shared.isIpad ? .topBarLeading : .bottomBar)
                
                //if AppState.shared.isIphone {
                    DefaultToolbarItem(kind: .search, placement: .bottomBar)
                //}
                
                ToolbarSpacer(.flexible, placement: AppState.shared.isIpad ? .topBarLeading : .bottomBar)
                ToolbarItem(placement: AppState.shared.isIpad ? .topBarLeading : .bottomBar) { PayMethodSortMenu() }
                
                if AppState.shared.isIpad {
                    ToolbarSpacer(.flexible, placement: .topBarLeading)
                    ToolbarItem(placement: .topBarLeading) { PayMethodFilterMenu() }
                
//                    ToolbarItem(placement: .topBarTrailing) {
//                        Picker("", selection: $paymentMethodSheetViewMode) {
//                            Text("Accounts")
//                                .tag(WhichView.select)
//                            Text("Starting Amounts")
//                                .tag(WhichView.edit)
//                        }
//                        .labelsHidden()
//                        //.pickerStyle(.segmented)
//                    }
//                    ToolbarSpacer(.flexible, placement: .topBarTrailing)
                }
                ToolbarItem(placement: .topBarTrailing) { closeButton }
                #else
                ToolbarItemGroup(placement: .destructiveAction) {
                    HStack {
                        moreMenu
                        PayMethodFilterMenu()
//                        if showStartingAmountOption {
//                            Picker("", selection: $paymentMethodSheetViewMode) {
//                                Text("Accounts")
//                                    .tag(WhichView.select)
//                                Text("Amounts")
//                                    .tag(WhichView.edit)
//                            }
//                            .labelsHidden()
//                            .pickerStyle(.segmented)
//                        } else {
//                            Text("Accounts")
//                        }
                    }
                    
                }
                
                ToolbarItemGroup(placement: .confirmationAction) {
                    HStack {
                        PayMethodSortMenu()
                        closeButton
                    }
                }
                #endif
            }
        }
        #if os(iOS)
        .background(Color(uiColor: .systemGroupedBackground))
        #endif
        //.background(Color(.systemBackground))
    }
    
    
    var methList: some View {
        ForEach(payModel.sections) { section in
            Section(section.rawValue) {
                ForEach(payModel.getMethodsFor(
                    section: section,
                    type: whichPaymentMethods,
                    sText: searchText,
                    includeHidden: whichPaymentMethods == .remainingAvailbleForPlaid,
                    calModel: calModel,
                    plaidModel: plaidModel
                )) { meth in
                    methLine(meth)
                        .onTapGesture {
                            selectPaymentMethod(meth)
                        }
                }
            }
        }
    }
    
    
    var moreMenu: some View {
        Menu {
            useBusinessLogosToggle
        } label: {
            Image(systemName: "ellipsis")
                .schemeBasedForegroundStyle()
        }
        #if os(macOS)
        .buttonStyle(.roundMacButton)
        #endif
    }
    
    
    var useBusinessLogosToggle: some View {
        Toggle(isOn: $useBusinessLogos) {
            Text("Use Business Logos")
        }
    }
    
    
    var noneSection: some View {
        Section {
            HStack {
                Text("None")
                Spacer()
                if payMethod == nil {
                    Image(systemName: "checkmark")
                }
            }
            .schemeBasedForegroundStyle()
            .contentShape(Rectangle())
            .onTapGesture {
                payMethod = nil
                dismiss()
            }
        } footer: {
            Text(noneText)
        }
    }
    
    
    var pagePicker: some View {
        Picker("", selection: $paymentMethodSheetViewMode) {
            Text("Accounts")
                .tag(WhichView.select)
            Text("Starting Amounts")
                .tag(WhichView.edit)
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .scenePadding(.horizontal)
        //.padding(.bottom, 5)
        #if os(iOS)
        .background(Color(uiColor: .systemGroupedBackground))
        #endif
        //.background(Color(.systemBackground)) // force matching
    }
    
    
    @ViewBuilder
    func methLine(_ meth: CBPaymentMethod) -> some View {
        HStack {
            Label {
                VStack(alignment: .leading) {
                    Text(meth.title)
                    if showStartingAmountOption
                        && AppState.shared.todayMonth == calModel.sMonth.actualNum
                        && AppState.shared.todayYear == calModel.sMonth.year {
                        Text(funcModel.getPlaidBalancePrettyString(meth) ?? "N/A")
                            .foregroundStyle(.gray)
                            .font(.caption)
                    }
                }
            } icon: {
                //methColorCircle(meth)
                //BusinessLogo(parent: meth, fallBackType: meth.isUnified ? .gradient : .color)
                #if os(iOS)
                PayMethodLogoMashup(meth: meth)
//                BusinessLogo(config: .init(
//                    parent: meth,
//                    fallBackType: meth.isUnified ? .gradient : .color
//                ))
                #else
                BusinessLogo(config: .init(
                    parent: meth,
                    fallBackType: meth.isUnified ? .gradient : .color,
                    size: 20
                ))
                .padding(.trailing, 10)
                #endif
            }
                                            
            Spacer()
            if showStartingAmountOption {
                transactionCountBadge(meth)
            }
            
                                 
            if payMethod?.id == meth.id {
                Image(systemName: "checkmark")
            }
        }
        .contentShape(Rectangle())
    }
   
    
    @ViewBuilder
    func transactionCountBadge(_ meth: CBPaymentMethod) -> some View {
        let count = calModel.getTransCount(for: meth, and: calModel.sMonth)
        if count > 0 {
            TextWithCircleBackground(text: "\(count)")
        }
    }
    
    
    @ViewBuilder
    var startingAmountsList: some View {
        ForEach(payModel.sections) { section in
            Section(section.rawValue) {
                ForEach(payModel.getMethodsFor(
                    section: section,
                    type: whichPaymentMethods,
                    sText: searchText,
                    calModel: calModel,
                    plaidModel: plaidModel
                )) { meth in
                    if let amount = calModel.sMonth.startingAmounts.filter ({ $0.payMethod?.id == meth.id }).first,
                       let meth = amount.payMethod {
                        StartingAmountLine(startingAmount: amount, payMethod: meth) { meth in
                            selectPaymentMethod(meth)
                        }
                    }
                }
            }
        }
    }
    
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
        #if os(macOS)
        .buttonStyle(.roundMacButton)
        #endif
    }
    
    
    func prepareView() {
        if showStartingAmountOption {
            for each in calModel.sMonth.startingAmounts {
                each.deepCopy(.create)
            }
        }
    }
    
    
    
    func selectPaymentMethod(_ meth: CBPaymentMethod) {
        payMethod = meth
        dismiss()
    }
}


fileprivate struct StartingAmountLine: View {
    
    @Environment(\.layoutDirection) private var layoutDirection: LayoutDirection
    @Environment(CalendarModel.self) var calModel
    @Environment(PayMethodModel.self) var payModel
    @Environment(AppStore.self) private var store
    
    @Bindable var startingAmount: CBStartingAmount
    var payMethod: CBPaymentMethod
    
    var selectPaymentMethod: (CBPaymentMethod) -> ()
    
    @State private var showTools = false
    @State private var showCountrySheet = false
    @State private var editOriginalAmount = false
    @State private var showDialog = false
    @FocusState private var focusedField: Int?
    
    let converter = CurrencyConverter()
    
    var body: some View {
        VStack {
            HStack(alignment: .circleAndTitle) {
                Label {
                    Text("\(payMethod.title)")
                } icon: {
                    PayMethodLogoMashup(meth: payMethod)
                }
                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                .contentShape(Rectangle())
                .onTapGesture {
                    selectPaymentMethod(payMethod)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Group {
                        #if os(iOS)
                        if payMethod.isUnified {
                            Text(startingAmount.amountString.isEmpty ? (AppSettings.shared.useWholeNumbers ? "$0" : "$0.00") : startingAmount.amountString)
                                .foregroundStyle(.secondary)
                        } else {
                            
                            VStack(alignment: .leading) {
                                iPhoneTextField
                                                   
                                if startingAmount.condataOriginalCountry != AppState.shared.country {
                                    HStack(spacing: 0) {
                                        Spacer()
                                        if let cunt = startingAmount.condataOriginalCountry {
                                            Text(startingAmount.condataOriginalAmount.currencyWithDecimals(currencyCode: cunt.currencyCode))
                                        }
                                        
                                        if let methCurCode = startingAmount.payMethod?.country?.currencyCode, methCurCode != AppState.shared.country.currencyCode {
                                            Text(" / ")
                                            Text("(\(startingAmount.condataPayMethodAmount.currencyWithDecimals(currencyCode: methCurCode)))")
                                        }
                                    }
                                    .foregroundStyle(.secondary)
                                    .font(.caption2)
                                }
                                
                            }
                        }
                        
                        #else
                        macTextField
                        #endif
                    }
                    .focused($focusedField, equals: 0)
                    .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                }
            }
            .opacity(editOriginalAmount ? 0 : 1)
            .overlay {
                ForeignAmountTextField(
                    obj: startingAmount,
                    showCountrySheet: $showCountrySheet,
                    focusedField: $focusedField,
                    editOriginalAmount: editOriginalAmount
                )
            }
            
            if (showTools || editOriginalAmount) && startingAmount.condataOriginalCountry != AppState.shared.country {
                ForeignAmountToolsScroller(
                    obj: startingAmount,
                    editOriginalAmount: $editOriginalAmount,
                    showCountrySheet: $showCountrySheet,
                    focusedField: $focusedField,
                    showCountryOptions: false
                )
            }
        }
        /// Convert foreign currency when the original amount changes.
        .onChange(of: startingAmount.condataOriginalAmountString) {
            if startingAmount.condataOriginalCountry != nil {
                converter.convert(obj: startingAmount, calModel: calModel)
            }
        }
        .onChange(of: focusedField) { oldFocus, newFocus in
            let setCur = AppState.shared.country.currencyCode
            let didFocus = newFocus == 0
            let didUnfocus = oldFocus == 0
            
            if didUnfocus {
                /// Clear out the negative symbol if that's all that is there.
                if startingAmount.amountString == "-" {
                    startingAmount.amountString = ""
                }
                
                if !startingAmount.amountString.isEmpty {
                    /// When unfocusing the field, format the currency with symbol & commas.
                    startingAmount.amountString = startingAmount.amount.currencyWithDecimals(currencyCode: setCur)
                }
                
                if startingAmount.condataOriginalCountry != nil {
                    showTools = false
                }
                                    
            } else if didFocus {
                /// When focusing the field, remove the currency symbol and commas.
                startingAmount.amountString = CurrencyHelpers.cleanAmountString(startingAmount.amountString, currencyCode: setCur)
                
                /// If the field is blank, when switching between payment methods, toggle the "-" if applicable to respect an expense/payment.
                if startingAmount.amountString.isEmpty && startingAmount.payMethod?.isDebitOrCash == false {
                    startingAmount.amountString = "-"
                }
                
                if startingAmount.condataOriginalCountry != nil {
                    showTools = true
                }
            }
            
            
            /// Handle when leaving the foreign currency field, and the country sheet is not showing.
            /// When accessing the country sheet, and using its search field, it will mess up with focus of the main textfield.
            /// This seems to be an issue with sheets specifically, as that behavior does not happen with a navdest.
            if (oldFocus == 10 || (oldFocus == 10 && newFocus == nil)) && !showCountrySheet {
                converter.convert(obj: startingAmount, calModel: calModel)
                withAnimation {
                    //print(oldFocus, newFocus)
                    //print("CHANGING VIA FOCUS")
                    editOriginalAmount = false
                }
            }
        }
        .onChange(of: startingAmount.amountString) { oldValue, newValue in
            if startingAmount.payMethod?.isDebitOrCash == true {
                CalcHelper.updateUnifiedStartingAmount(month: calModel.sMonth, for: .unifiedChecking, store: store)
            } else if startingAmount.payMethod?.isCreditOrLoan == true {
                CalcHelper.updateUnifiedStartingAmount(month: calModel.sMonth, for: .unifiedCredit, store: store)
            }
            
            
        }
        .sheet(isPresented: $showCountrySheet, onDismiss: {
            if !editOriginalAmount {
                startingAmount.condataOriginalAmountString = startingAmount.amountString
                converter.convert(obj: startingAmount, calModel: calModel)
            }
        }) {
            CountryPicker(country: $startingAmount.condataOriginalCountry)
        }
    }
    
    #if os(iOS)
    @ViewBuilder
    var iPhoneTextField: some View {
        var placeholder: String {
            if startingAmount.payMethod?.country == AppState.shared.country {
                "Starting Amount"
            } else {
                "Starting Amount (\(AppState.shared.country.currencyCode))"
            }
        }
        /// WARNING!: Can't use the focus arrows because the textfields won't focus unless they are visible on screen. Veriified with apples dummy project.
        /// https://developer.apple.com/documentation/swiftui/focus-cookbook-sample
        UITextFieldWrapper(placeholder: placeholder, text: $startingAmount.amountString, toolbar: {
//            KeyboardToolbarView(
//                focusedField: $focusedField,
//                accessoryText1: "AutoFill",
//                accessoryFunc1: { autoFillAmount() },
//                accessoryImage3: "plus.forwardslash.minus",
//                accessoryFunc3: { Helpers.plusMinus($startingAmount.amountString) }
//            )
//            
            KeyboardToolbarView2(
                focusedField: $focusedField,
                disableDown: true,
                view1: { AnyView(autofillButton) },
                view4: { AnyView(plequalsButton) }
            )
        })
        .uiKeyboardType(.custom(.numpad))
        //.uiKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
        .uiTag(0)
        .uiTextAlignment(layoutDirection == .leftToRight ? .right : .left)
        .uiClearButtonMode(.whileEditing)
        .uiStartCursorAtEnd(true)
    }
    #endif
    
    #if os(macOS)
    var macTextField: some View {
        TextField("Starting Amount", text: $startingAmount.amountString)
            .multilineTextAlignment(.trailing)
            .contextMenu {
                Button("AutoFill") {
                    autoFillAmount()
//                    if calModel.sMonth.num != 0 {
//                        let targetMonth = calModel.months.filter { $0.num == calModel.sMonth.num - 1 }.first!
//                        let _ = calModel.calculateTotal(for: targetMonth, using: payMethod)
//                        let eodTotal = targetMonth.days.last!.eodTotal
//                        startingAmount.amountString = eodTotal.currencyWithDecimals()
//                    }
                }
            }
    }
    #endif
    
    
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
            if startingAmount.condataOriginalCountry == nil {
                FlagCircle(code: startingAmount.condataOriginalCountry?.code ?? Countries.homeCountry.code)
            } else {
                Image(systemName: "flag")
            }
            
        }
        .disabled(startingAmount.condataOriginalCountry != nil)
    }
    
    var plequalsButton: some View {
        Button {
            Helpers.plusMinus($startingAmount.amountString)
            Helpers.plusMinus($startingAmount.condataOriginalAmountString)
        } label: {
            Image(systemName: "plus.forwardslash.minus")
        }
        .schemeBasedTint()
    }
    
    var autofillButton: some View {
        Button("AutoFill") {
            autoFillAmount()
        }
        .schemeBasedTint()
    }
    
    func autoFillAmount() {
        if calModel.sMonth.num != 0 {
            //if let targetMonth = calModel.months.getAdjacent(num: calModel.sMonth.num , direction: .prev) {
            if let targetMonth = calModel.months.filter({ $0.num == calModel.sMonth.num - 1 }).first {
                let eod = CalcHelper.calculateTotal(
                    for: targetMonth,
                    using: payMethod,
                    and: .giveMeLastDayEod,
                    store: store
                )
                print("The EOD for \(startingAmount.payMethod?.title ?? "N/A") is \(eod)")
                
                startingAmount.amountString = eod.currencyWithDecimals(currencyCode: startingAmount.payMethod?.country?.currencyCode)
                return
            }
        }
    }
}
