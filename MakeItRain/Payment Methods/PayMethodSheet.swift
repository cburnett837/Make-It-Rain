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
                    if let amount = calModel.sMonth.startingAmounts.filter ({ $0.payMethod.id == meth.id }).first {
                        StartingAmountLine(startingAmount: amount, payMethod: amount.payMethod) { meth in
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
    
    @State private var showDialog = false
    @FocusState private var focusedField: Int?
    
    var body: some View {
        HStack(alignment: .circleAndTitle) {
            Label {
                Text("\(payMethod.title)")
            } icon: {
                PayMethodLogoMashup(meth: payMethod)
                //BusinessLogo(parent: payMethod, fallBackType: payMethod.isUnified ? .gradient : .color)
//                BusinessLogo(config: .init(
//                    parent: payMethod,
//                    fallBackType: payMethod.isUnified ? .gradient : .color
//                ))
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
                        iPhoneTextField
                    }
                    
                    #else
                    macTextField
                    #endif
                }
                .focused($focusedField, equals: 0)
                .alignmentGuide(.circleAndTitle, computeValue: { $0[VerticalAlignment.center] })
                
                #warning("CURRENCY! FIX ME")
//                if let converted = startingAmount.convertedDisplayAmount {
//                    let setCunt = AppState.shared.country
//                    Text("Converted to \(CurrencyHelpers.formatAmountText(amount: converted, currencyCode: setCunt.currencyCode))")
//                        .foregroundStyle(.secondary)
//                        .font(.caption2)
//                }
            }
            
//            .formatCurrencyLiveAndOnUnFocus(
//                focusValue: 0,
//                focusedField: focusedField,
//                amountString: startingAmount.amountString,
//                amountStringBinding: $startingAmount.amountString,
//                amount: startingAmount.amount
//            )
            .onChange(of: focusedField) { oldFocus, newFocus in
                let didFocus = newFocus == 0
                let didUnfocus = oldFocus == 0
                let methCur = calModel.sPayMethod?.country?.currencyCode
                let setCur = AppState.shared.country.currencyCode
                
                if didUnfocus {
                    /// When unfocusing the field, format the currency with symbol & commas.
                    startingAmount.amountString = CurrencyHelpers.formatAmountText(
                        amount: startingAmount.amount,
                        currencyCode: startingAmount.payMethod.country?.currencyCode ?? "USD"
                    )
                } else if didFocus {
                    /// When focusing the field, remove the currency symbol and commas.
//                    if let cleaned = CurrencyHelpers.cleanAmountString(startingAmount.amountString, currencyCode: methCur ?? setCur) {
//                        startingAmount.amountString = cleaned
//                    }
                    startingAmount.amountString = CurrencyHelpers.cleanAmountString(startingAmount.amountString, currencyCode: methCur ?? setCur)
                    
                    /// If the field is blank, when switching between payment methods, toggle the "-" if applicable to respect an expense/payment.
                    if startingAmount.amountString.isEmpty && startingAmount.payMethod.isDebitOrCash == true {
                        startingAmount.amountString = "-"
                    }
                }
            }
            .onChange(of: startingAmount.amountString) { oldValue, newValue in
                if startingAmount.payMethod.isDebitOrCash {
                    CalcHelper.updateUnifiedStartingAmount(month: calModel.sMonth, for: .unifiedChecking, store: store)
                } else if startingAmount.payMethod.isCreditOrLoan {
                    CalcHelper.updateUnifiedStartingAmount(month: calModel.sMonth, for: .unifiedCredit, store: store)
                }
                
                
            }
//            .task {
//                startingAmount.amountString = startingAmount.amount.currencyWithDecimals()
//            }
        }
    }
    
    #if os(iOS)
    var iPhoneTextField: some View {
        /// WARNING!: Can't use the focus arrows because the textfields won't focus unless they are visible on screen. Veriified with apples dummy project.
        /// https://developer.apple.com/documentation/swiftui/focus-cookbook-sample
        UITextFieldWrapper(placeholder: "Starting Amount", text: $startingAmount.amountString, toolbar: {
            KeyboardToolbarView(
                focusedField: $focusedField,
                accessoryText1: "AutoFill",
                accessoryFunc1: { autoFillAmount() },
                accessoryImage3: "plus.forwardslash.minus",
                accessoryFunc3: { Helpers.plusMinus($startingAmount.amountString) })
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
                //let eodTotal = eod//targetMonth.days.last!.eodTotal
                //startingAmount.amountString = eod.currencyWithDecimals()
                
                
//                let USA = Countries.fetch(by: 225)!
//                if let amountConverted = Countries.convert(amount: eod, from: USA, to: AppState.shared.country),
//                   let country = payMethod.country {
//        //            self.convertedDisplayAmount = Countries.convert(amount: amount, from: USA, to: AppState.shared.country)
//                    self.amountString = CurrencyHelpers.formatAmountText(amount: amountConverted, currencyCode: country.currencyCode)
                    
                    
                print("The EOD for \(startingAmount.payMethod.title) is \(eod)")
                //startingAmount.amountString = eod.currencyWithDecimals()
                
//                if let cunt = startingAmount.payMethod.country {
//                    startingAmount.amountString = CurrencyHelpers.formatAmountText(amount: eod, currencyCode: cunt.currencyCode)
//                } else {
//                    startingAmount.amountString = eod.currencyWithDecimals()
//                }
                
                
                /// Tackle App = USA, starting amount currency = COP
                /// NOTE! EOD is always the app's currency type
                //let setCunt = AppState.shared.country
                
                
                startingAmount.amountString = eod.currencyWithDecimals(currencyCode: startingAmount.payMethod.country?.currencyCode)
                return
                
//                if let methCunt = startingAmount.payMethod.country {
//                    //let exchangeRate =
//                    
//                }
//                
//                
//                
//                
//                if let cunt = startingAmount.payMethod.country {
//                    let setCunt = AppState.shared.country
//                    if cunt != setCunt {
//                        print("🐶0.0")
//                        if let converted = Countries.convert(
//                            amount: eod,
//                            from: setCunt,
//                            to: cunt
//                        ) {
//                            print("🐶0.1")
//                            startingAmount.amountString = CurrencyHelpers.formatAmountText(
//                                amount: converted,
//                                currencyCode: cunt.currencyCode
//                            )
//                        }
//                    } else {
//                        print("🐶0.2")
//                        startingAmount.amountString = eod.currencyWithDecimals()
//                    }
//                } else {
//                    print("🐶0.3")
//                    startingAmount.amountString = eod.currencyWithDecimals()
//                }
            }
        }
    }
}
