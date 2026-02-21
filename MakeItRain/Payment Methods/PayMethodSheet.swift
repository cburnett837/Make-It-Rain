//
//  PayMethodSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/21/24.
//

import SwiftUI

public enum PaymentMethodFilterMode: String, CaseIterable {
    case all, justPrimary, primaryAndSecondary
    
    var prettyValue: String {
        switch self {
        case .all:
            "All Accounts"
        case .justPrimary:
            "Primary Accounts"
        case .primaryAndSecondary:
            "Primary & Secondary Accounts"
        }
    }
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "all": return .all
        case "justPrimary": return .justPrimary
        case "primaryAndSecondary": return .primaryAndSecondary
        default: return .all
        }
    }
}

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
            Text("Show all transactions and their daily sum.")
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
                BusinessLogo(config: .init(
                    parent: meth,
                    fallBackType: meth.isUnified ? .gradient : .color
                ))
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
    
    @Bindable var startingAmount: CBStartingAmount
    var payMethod: CBPaymentMethod
    
    var selectPaymentMethod: (CBPaymentMethod) -> ()
    
    @State private var showDialog = false
    @FocusState private var focusedField: Int?
    
    var body: some View {
        HStack {
            Label {
                Text("\(payMethod.title)")
            } icon: {
                //BusinessLogo(parent: payMethod, fallBackType: payMethod.isUnified ? .gradient : .color)
                BusinessLogo(config: .init(
                    parent: payMethod,
                    fallBackType: payMethod.isUnified ? .gradient : .color
                ))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selectPaymentMethod(payMethod)
            }
            
            Spacer()
            
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
            .formatCurrencyLiveAndOnUnFocus(
                focusValue: 0,
                focusedField: focusedField,
                amountString: startingAmount.amountString,
                amountStringBinding: $startingAmount.amountString,
                amount: startingAmount.amount
            )
            .task {
                startingAmount.amountString = startingAmount.amount.currencyWithDecimals()
            }
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
                    if calModel.sMonth.num != 0 {
                        let targetMonth = calModel.months.filter { $0.num == calModel.sMonth.num - 1 }.first!
                        let _ = calModel.calculateTotal(for: targetMonth, using: payMethod)
                        let eodTotal = targetMonth.days.last!.eodTotal
                        startingAmount.amountString = eodTotal.currencyWithDecimals()
                    }
                }
            }
    }
    #endif
    
    func autoFillAmount() {
        if calModel.sMonth.num != 0 {
            let targetMonth = calModel.months.filter { $0.num == calModel.sMonth.num - 1 }.first!            
            let eod = calModel.calculateTotal(for: targetMonth, using: payMethod, and: .giveMeLastDayEod)
            let eodTotal = eod//targetMonth.days.last!.eodTotal
            startingAmount.amountString = eodTotal.currencyWithDecimals()
        }
    }
}

