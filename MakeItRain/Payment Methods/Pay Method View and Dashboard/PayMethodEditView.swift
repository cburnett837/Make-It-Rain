//
//  EditPaymentMethodView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/14/24.
//

import SwiftUI
import Charts
import LocalAuthentication

struct PayMethodEditView: View {
    enum Offset: Int {
        case dayBack0 = 0
        case dayBack1 = 1
        case dayBack2 = 2
    }
    
    enum ChartRange: Int {
        case year1 = 1
        case year2 = 2
        case year3 = 3
        case year4 = 4
        case year5 = 5
    }
        
    @AppStorage("selectedPaymentMethodTab") var selectedTab: DetailsOrInsights = .details
    @AppStorage(LocalKeys.Charts.Options.showOverviewDataPerMethodOnUnified) var showOverviewDataPerMethodOnUnifiedChart = false

    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(CalendarModel.self) private var calModel
    @Environment(PayMethodModel.self) private var payModel
    @Environment(PlaidModel.self) private var plaidModel

    
    @State private var viewModel = PayMethodViewModel()
    
    @Bindable var payMethod: CBPaymentMethod
    
    /// This is only here to blank out the selection hilight on the iPhone list
    @Binding var editID: String?
        
    @State private var showDeleteAlert = false
    @State private var labelWidth: CGFloat = 20.0
    @State private var showColorPicker = false
    @State private var showLogoSearchPage = false
    
    @FocusState private var focusedField: Int?
    
    @State private var accountTypeMenuColor: Color = Color(.tertiarySystemFill)
    
    @Namespace private var namespace

        
    var isValidToSave: Bool {
        (payMethod.action == .add && !payMethod.title.isEmpty)
        || (payMethod.hasChanges() && !payMethod.title.isEmpty)
    }
    
    
    var title: String {
        if payMethod.isUnified {
            payMethod.title
        } else {
            payMethod.action == .add ? "New Account" : "Edit Account"
        }
    }
        
    
    #if os(iOS)
    var limitLingo: String { payMethod.accountType == .credit ? "Credit Limit" : "Loan Amount" }
    #else
    var limitLingo: String { payMethod.accountType == .credit ? "Limit" : "Amount" }
    #endif
    
    var pickerAnimation: Animation? {
        payMethod.accountType == .credit || payMethod.accountType == .loan ? nil : .default
    }
    
    var body: some View {
        Group {
            #if os(iOS)
            NavigationStack {
                editPagePhone
                    .background(Color(.systemBackground)) // force matching
                    .navigationTitle(title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { toolbar }
            }
            
            #else
            
            VStack {
                Group {
                    if selectedTab == .details {
                        editPageMac
                    } else {
                        #if os(iOS)
                        chartPage
                        #else
                        Text("Not ready yet")
                        #endif
                    }
                }
                .frame(maxHeight: .infinity)
                
                fakeMacTabBar
            }
            
            #endif
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        .task { await prepareView() }
    }
       
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .topBarLeading) {
            if !payMethod.isUnified {
                deleteButton
                    .glassEffectID("delete", in: namespace)
            }
        }
                
        ToolbarSpacer(.fixed, placement: .topBarLeading)
        
        ToolbarItem(placement: .topBarLeading) {
            if (payMethod.accountType == .credit || payMethod.accountType == .loan) && payMethod.dueDate != nil {
                notificationButton.disabled(payMethod.isUnified)
                    .glassEffectID("notify", in: namespace)
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            AnimatedCloseButton(isValidToSave: isValidToSave, closeButton: closeButton)
        }
        
        ToolbarItem(placement: .bottomBar) {
            EnteredByAndUpdatedByView(enteredBy: payMethod.enteredBy, updatedBy: payMethod.updatedBy, enteredDate: payMethod.enteredDate, updatedDate: payMethod.updatedDate)
        }
        .sharedBackgroundVisibility(.hidden)
        #else
        
        ToolbarItem(placement: .confirmationAction) {
            AnimatedCloseButton(isValidToSave: isValidToSave, closeButton: closeButton)
        }
        #endif

    }
    
    
    // MARK: - Edit Page
    @ViewBuilder
    var editPagePhone: some View {
        List {
        Section("Title") {
            titleRow
        }
            
        Section {
            accountHolders
            typeRowPhone
            colorRow
            
            LogoPickerRow(parent: payMethod, parentType: .paymentMethod, fallbackType: payMethod.isUnified ? .gradient : .color)
            
            if payMethod.accountType == .checking || payMethod.accountType == .credit {
                last4Row
            }
        } header: {
            Text("Details")
        } footer: {
            if payMethod.accountType == .checking || payMethod.accountType == .credit {
                Text("If you wish to use the smart receipt feature offered by ChatGPT, enter the last 4 digits of your card information. If not, you can leave this field blank.")
                    .validate(payMethod.last4 ?? "", rules: .regex(.onlyNumbers, "Only numbers are allowed"))
            }
        }
        
        if payMethod.accountType == .credit || payMethod.accountType == .loan {
            Section("Credit Details") {
                dueDateRow
                limitRow
                interestRateRow
                if payMethod.accountType == .loan {
                    loanDurationRow
                }
            }
        }
        
        if (payMethod.accountType == .credit || payMethod.accountType == .loan) && payMethod.dueDate != nil && payMethod.notifyOnDueDate {
            Section {
                reminderRow
            } footer: {
                Text("Alerts will be sent out at 9:00 AM")
            }
        }
                                
        if !payMethod.isUnified {
            Section {
                isPrivateRow
            } footer: {
                Text("Transactions, Search Results, Etc. belonging to this account will only be visible to you.")
            }
            
            Section {
                isHiddenRow
            } footer: {
                Text("Hide this account from **my** menus. (This will not delete any data).")
            }
        }
//
//            Section {
//                colorRow
//            }
        
//        Section {
//            deleteButton
        }
    }
    
    
    
//    var editPagePhoneOG: some View {
//        StandardContainerWithToolbar(.list) {
//            
//            
//            //BigBusinessLogo(parent: payMethod, fallBackType: payMethod.isUnified ? .gradient : .color)
//            
//            Section("Title") {
//                titleRow
//            }
//            
//            Section {
//                typeRowPhone
//                colorRow
//                logoRow
//                if payMethod.accountType == .checking || payMethod.accountType == .credit {
//                    last4Row
//                }
//            } header: {
//                Text("Details")
//            } footer: {
//                if payMethod.accountType == .checking || payMethod.accountType == .credit {
//                    Text("If you wish to use the smart receipt feature offered by ChatGPT, enter the last 4 digits of your card information. If not, you can leave this field blank.")
//                        .validate(payMethod.last4 ?? "", rules: .regex(.onlyNumbers, "Only numbers are allowed"))
//                }
//            }
//
//            
//            
////            if payMethod.accountType == .checking || payMethod.accountType == .credit {
////                Section {
////                    last4Row
////                } footer: {
////                    Text("If you wish to use the smart receipt feature offered by ChatGPT, enter the last 4 digits of your card information. If not, you can leave this field blank.")
////                        .validate(payMethod.last4 ?? "", rules: .regex(.onlyNumbers, "Only numbers are allowed"))
////                }
////            }
//            
//            if payMethod.accountType == .credit || payMethod.accountType == .loan {
//                Section("Credit Details") {
//                    dueDateRow
//                    limitRow
//                    interestRateRow
//                    if payMethod.accountType == .loan {
//                        loanDurationRow
//                    }
//                }
//            }
//            
//            if (payMethod.accountType == .credit || payMethod.accountType == .loan) && payMethod.dueDate != nil && payMethod.notifyOnDueDate {
//                Section {
//                    reminderRow
//                } footer: {
//                    Text("Alerts will be sent out at 9:00 AM")
//                }
//            }
//                                    
//            if !payMethod.isUnified {
//                Section {
//                    isPrivateRow
//                } footer: {
//                    Text("Transactions, Search Results, Etc. belonging to this account will only be visible to you.")
//                }
//                
//                Section {
//                    isHiddenRow
//                } footer: {
//                    Text("Hide this account from **my** menus. (This will not delete any data).")
//                }
//            }
////
////            Section {
////                colorRow
////            }
//        }
//    }
    
    
    
    var editPageMac: some View {
        StandardContainer {
            titleRow
            typeRowMac
            
            if payMethod.accountType == .checking || payMethod.accountType == .credit {
                StandardDivider()
                last4Row
            }
            
            if payMethod.accountType == .credit || payMethod.accountType == .loan {
                StandardDivider()
                dueDateRow
                limitRow
            }
            
            if payMethod.accountType == .credit || payMethod.accountType == .loan {
                StandardDivider()
                interestRateRow
            }
            
            if payMethod.accountType == .loan {
                loanDurationRow
            }
            
            if !payMethod.isUnified {
                StandardDivider()
                isPrivateRow
                StandardDivider()
                isHiddenRow
            }
                                    
            if (payMethod.accountType == .credit || payMethod.accountType == .loan) && payMethod.dueDate != nil && payMethod.notifyOnDueDate {
                StandardDivider()
                reminderRow
            }
            
            StandardDivider()
            colorRow
            
            StandardDivider()
            //PlaidLinkView(payMethod: payMethod)
                        
            Spacer()
                .frame(height: 30)
           
        } header: {
            header
        }
    }
                
    
    var titleRow: some View {
        #if os(iOS)
        HStack(spacing: 0) {
            Label {
                Text("")
            } icon: {
                Image(systemName: "t.circle")
                    .foregroundStyle(.gray)
            }
            
            UITextFieldWrapper(placeholder: "Credit, Debit, Etc.", text: $payMethod.title, toolbar: {
                KeyboardToolbarView(focusedField: $focusedField)
            })
            .uiTag(0)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.left)
            //.uiTextColor(.secondaryLabel)
            //.uiFont(UIFont.systemFont(ofSize: 24.0))
        }
        .focused($focusedField, equals: 0)
        
        #else
        LabeledRow("Name", labelWidth) {
            StandardTextField("Credit, Debit, Etc.", text: $payMethod.title, focusedField: $focusedField, focusValue: 0)
                .foregroundStyle(.secondary)
        }
        #endif
    }
    
    
    var typeRowMac: some View {
        LabeledRow("Type", labelWidth) {
            StandardRectangle {
                Menu {
                    Section {
                        Button("Checking") { payMethod.accountType = AccountType.checking }
                        Button("Cash") { payMethod.accountType = AccountType.cash }
                    }
                    
                    Section {
                        Button("Credit") { payMethod.accountType = AccountType.credit }
                        Button("Loan") { payMethod.accountType = AccountType.loan }
                    }
                    
                    Section {
                        Button("Savings") { payMethod.accountType = AccountType.savings }
                        Button("401K") { payMethod.accountType = AccountType.k401 }
                        Button("Investment") { payMethod.accountType = AccountType.investment }
                    }
                } label: {
                    HStack {
                        //Text(payMethod.accountType.rawValue.capitalized)
                        Text(XrefModel.getItem(from: .accountTypes, byID: payMethod.accountType.rawValue).description)
                            .schemeBasedForegroundStyle()
                        Spacer()
                    }
                }
                #if os(macOS)
                /// Negate the native macOS padding on the menu
                .padding(.leading, -2)
                #endif
                .chevronMenuOverlay()
            }
        }
    }
    
    
    var accountHolders: some View {
        NavigationLink {
            AccountHolders(payMethod: payMethod)
        } label: {
            Label {
                Text("Account Holders")
            } icon: {
                Image(systemName: "person.2")
                    .foregroundStyle(.gray)
            }

        }

    }
    
    
    var typeRowPhone: some View {
        Picker(selection: $payMethod.accountType) {
            Section {
                Text("Checking").tag(AccountType.checking)
                Text("Cash").tag(AccountType.cash)
            }
            
            Section {
                Text("Credit").tag(AccountType.credit)
                Text("Loan").tag(AccountType.loan)
            }
            
            Section {
                Text("Savings").tag(AccountType.savings)
                Text("401K").tag(AccountType.k401)
                Text("Investment").tag(AccountType.investment)
                Text("Crypto").tag(AccountType.crypto)
                Text("Brokerage").tag(AccountType.brokerage)
            }
        } label: {
            Label {
                Text("Account Type")
            } icon: {
                Image(systemName: "dollarsign.bank.building")
                    .foregroundStyle(.gray)
            }
        }
        .pickerStyle(.menu)
        .tint(.secondary)
    }
    

    var last4Row: some View {
        #if os(iOS)
        HStack {
            Label {
                Text("Last 4 Digits")
            } icon: {
                Image(systemName: "creditcard.and.numbers")
                    .foregroundStyle(.gray)
            }
            
            UITextFieldWrapper(placeholder: "****", text: $payMethod.last4 ?? "", toolbar: {
                KeyboardToolbarView(focusedField: $focusedField)
            })
            .uiTag(1)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.right)
            .uiMaxLength(4)
            //.uiKeyboardType(.numberPad)
            .uiKeyboardType(.system(.numberPad))
            .uiTextColor(.secondaryLabel)
        }
        .focused($focusedField, equals: 1)
        
        #else
        LabeledRow("Last 4", labelWidth) {
            StandardTextField("Last 4 Digits", text: $payMethod.last4 ?? "", focusedField: $focusedField, focusValue: 1)
        } subContent: {
            Text("If you wish to use the smart receipt feature offered by ChatGPT, enter the last 4 digits of your card information. If not, you can leave this field blank.")
                .validate(payMethod.last4 ?? "", rules: .regex(.onlyNumbers, "Only numbers are allowed"))
        }
        #endif
    }
    
        
    var dueDateRow: some View {
        Group {
            #if os(iOS)
            HStack {
                Label {
                    Text("Due Date")
                } icon: {
                    Image(systemName: "calendar")
                        .foregroundStyle(.gray)
                }
                Spacer()
                UITextFieldWrapper(placeholder: "(day number only)", text: $payMethod.dueDateString ?? "", onBeginEditing: {
                    payMethod.dueDateString = payMethod.dueDateString?.replacing(/[a-z]+/, with: "", maxReplacements: 1)
                }, toolbar: {
                    KeyboardToolbarView(focusedField: $focusedField)
                })
                .uiTag(2)
                .uiClearButtonMode(.whileEditing)
                .uiStartCursorAtEnd(true)
                .uiTextAlignment(.right)
                .uiMaxLength(2)
                //.uiKeyboardType(.decimalPad)
                .uiKeyboardType(.custom(.numpad))
                .uiTextColor(.secondaryLabel)
            }
            .focused($focusedField, equals: 2)

            #else
            LabeledRow("Due Date", labelWidth) {
                StandardTextField("(day number only)", text: $payMethod.dueDateString ?? "", focusedField: $focusedField, focusValue: 2)
            }
            #endif
        }
        .onChange(of: focusedField) { oldValue, newValue in
            if newValue == 2 {
                if payMethod.dueDate == 0 {
                    payMethod.dueDateString = ""
                }
            } else {
                if oldValue == 2 && !(payMethod.dueDateString ?? "").isEmpty {
                    payMethod.dueDateString = (payMethod.dueDate ?? 0).withOrdinal()
                }
            }
        }
    }
    
        
    @ViewBuilder
    var limitRow: some View {
        Group {
            #if os(iOS)
            HStack {
                Label {
                    Text(limitLingo)
                } icon: {
                    Image(systemName: "dollarsign")
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                UITextFieldWrapper(placeholder: limitLingo, text: $payMethod.limitString ?? "", toolbar: {
                    KeyboardToolbarView(focusedField: $focusedField)
                })
                .uiTag(3)
                .uiClearButtonMode(.whileEditing)
                .uiStartCursorAtEnd(true)
                .uiTextAlignment(.right)
                //.uiKeyboardType(.decimalPad)
                .uiKeyboardType(.custom(.numpad))
                .uiTextColor(.secondaryLabel)
                .focused($focusedField, equals: 3)
            }
            .validate(payMethod.limitString ?? "", rules: .regex(.positiveCurrency, "The entered amount must be positive currency"))

            #else
            LabeledRow(limitLingo, labelWidth) {
                StandardTextField(limitLingo, text: $payMethod.limitString ?? "", focusedField: $focusedField, focusValue: 3)
            } subContent: {
                EmptyView()
                    .validate(payMethod.limitString ?? "", rules: .regex(.positiveCurrency, "The entered amount must be positive currency"))
            }
            #endif
        }
        .formatCurrencyLiveAndOnUnFocus(
            focusValue: 3,
            focusedField: focusedField,
            amountString: payMethod.limitString,
            amountStringBinding: $payMethod.limitString ?? "",
            amount: payMethod.limit
        )
        
    }
    
        
    @ViewBuilder
    var interestRateRow: some View {
        #if os(iOS)
        HStack {
            Label {
                Text("Interest Rate")
            } icon: {
                Image(systemName: "percent")
                    .foregroundStyle(.gray)
            }
            Spacer()
            UITextFieldWrapper(placeholder: "Interest Rate", text: $payMethod.interestRateString ?? "", toolbar: {
                KeyboardToolbarView(focusedField: $focusedField)
            })
            .uiTag(4)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.right)
            //.uiKeyboardType(.decimalPad)
            .uiKeyboardType(.custom(.numpad))
            .uiTextColor(.secondaryLabel)
            .focused($focusedField, equals: 4)
        }
        
        #else
        LabeledRow("Interest Rate", labelWidth) {
            StandardTextField("Interest Rate", text: $payMethod.interestRateString ?? "", focusedField: $focusedField, focusValue: 4)
        } subContent: {
            EmptyView()
                .validate(payMethod.interestRateString ?? "", rules: .regex(.onlyDecimals, "Only decimal numbers are allowed"))
        }
        #endif
    }
    
    
    @ViewBuilder
    var loanDurationRow: some View {
        #if os(iOS)
        HStack {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Loan Duration")
                    Text("(months)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "ruler")
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            UITextFieldWrapper(placeholder: "Loan Duration", text: $payMethod.loanDurationString ?? "", toolbar: {
                KeyboardToolbarView(focusedField: $focusedField)
            })
            .uiTag(5)
            .uiClearButtonMode(.whileEditing)
            .uiStartCursorAtEnd(true)
            .uiTextAlignment(.right)
            //.uiKeyboardType(.numberPad)
            .uiKeyboardType(.system(.numberPad))
            .uiTextColor(.secondaryLabel)
            .focused($focusedField, equals: 5)
            .validate(payMethod.loanDurationString ?? "", rules: .regex(.onlyDecimals, "Only numbers are allowed"))
        }
        
        #else
        LabeledRow("Loan Duration", labelWidth) {
            StandardTextField("Loan Duration", text: $payMethod.loanDurationString ?? "", focusedField: $focusedField, focusValue: 5)
        } subContent: {
            Text("(Months)")
                .validate(payMethod.loanDurationString ?? "", rules: .regex(.onlyNumbers, "Only numbers are allowed"))
        }
        #endif
    }
            

    var isPrivateRow: some View {
        #if os(iOS)
        Toggle(isOn: $payMethod.isPrivate.animation()) {
            Label {
                Text("Mark as Private")
                    .schemeBasedForegroundStyle()
            } icon: {
                Image(systemName: "person.slash")
                    .foregroundStyle(.gray)
            }
        }
        
        #else
        LabeledRow("Private", labelWidth) {
            Toggle(isOn: $payMethod.isPrivate.animation()) {
                Text("Mark as Private")
            }
        } subContent: {
            Text("Transactions, Search Results, Etc. belonging to \(payMethod.title) will only be visible to you.")
        }
        #endif
        
    }
    
   
    var isHiddenRow: some View {
        #if os(iOS)
        Toggle(isOn: $payMethod.isHidden.animation()) {
            Label {
                Text("Mark as Hidden")
                    .schemeBasedForegroundStyle()
            } icon: {
                Image(systemName: "eye.slash")
                    .foregroundStyle(.gray)
            }
        }
        
        #else
        LabeledRow("Hidden", labelWidth) {
            Toggle(isOn: $payMethod.isHidden.animation()) {
                Text("Mark as Hidden")
            }
        } subContent: {
            Text("Hide this account from view (This will not delete any data).")
        }
        #endif
        
    }
 
    
    var reminderRow: some View {
        #if os(iOS)
        
        ReminderPicker(notificationOffset: $payMethod.notificationOffset)
        
        #else
        LabeledRow("Reminder", labelWidth) {
            Picker("", selection: $payMethod.notificationOffset) {
                Text("2 days before")
                    .tag(2)
                Text("1 day before")
                    .tag(1)
                Text("Day of")
                    .tag(0)
            }
            .labelsHidden()
            .pickerStyle(.palette)
            
        } subContent: {
            Text("Alerts will be sent out at 9:00 AM")
        }
        #endif
        
    }
    
    
    var colorRow: some View {
        #if os(iOS)
        Button {
            showColorPicker = true
        } label: {
            HStack {
                Label {
                    Text("Color")
                        .schemeBasedForegroundStyle()
                } icon: {
                    Image(systemName: "lightspectrum.horizontal")
                        .foregroundStyle(.gray)
                }
                Spacer()
                //StandardColorPicker(color: $payMethod.color)
                Image(systemName: "circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(payMethod.color.gradient)
            }
        }
        .colorPickerSheet(isPresented: $showColorPicker, selection: $payMethod.color, supportsAlpha: false)
        
        #else
        LabeledRow("Color", labelWidth) {
            HStack {
                ColorPicker("", selection: $payMethod.color, supportsOpacity: false)
                    .labelsHidden()
                Capsule()
                    .fill(payMethod.color)
                    .onTapGesture {
                        AppState.shared.showToast(title: "Color Picker", subtitle: "Click the circle to the left to change the color.", body: nil, symbol: "theatermask.and.paintbrush", symbolColor: payMethod.color)
                    }
            }
        }
        #endif
    }
    
    
//    @ViewBuilder
//    var logoRow: some View {
//        #if os(iOS)
//        Group {
//            if payMethod.logo == nil {
//                Button {
//                    showLogoSearchPage = true
//                } label: {
//                    logoLabel
//                }
//            } else {
//                Menu {
//                    Button("Clear Logo") { payMethod.logo = nil }
//                    Button("Change Logo") { showLogoSearchPage = true }
//                } label: {
//                    logoLabel
//                }
//            }
//        }
//        .sheet(isPresented: $showLogoSearchPage) {
//            LogoSearchPage(parent: payMethod, parentType: .paymentMethod)
//        }
//        
//        #else
//        LabeledRow("Color", labelWidth) {
//            HStack {
//                ColorPicker("", selection: $payMethod.color, supportsOpacity: false)
//                    .labelsHidden()
//                Capsule()
//                    .fill(payMethod.color)
//                    .onTapGesture {
//                        AppState.shared.showToast(title: "Color Picker", subtitle: "Click the circle to the left to change the color.", body: nil, symbol: "theatermask.and.paintbrush", symbolColor: payMethod.color)
//                    }
//            }
//        }
//        #endif
//    }
//    
//    
//    var logoLabel: some View {
//        HStack {
//            Label {
//                Text("Logo")
//                    .schemeBasedForegroundStyle()
//            } icon: {
//                Image(systemName: "circle.hexagongrid")
//                    .foregroundStyle(.gray)
//            }
//            Spacer()
//            //StandardColorPicker(color: $payMethod.color)
//            BusinessLogo(config: .init(
//                parent: payMethod,
//                fallBackType: payMethod.isUnified ? .gradient : .color
//            ))
//            
//            //BusinessLogo(parent: payMethod, fallBackType: payMethod.isUnified ? .gradient : .color)
//        }
//    }
    
        
    
    // MARK: - Chart Stuff
    var configType: PayMethodChartDataType {
        switch payMethod.accountType {
        case .checking:
            .debitPaymentMethod
        case .credit:
            .creditPaymentMethod
        case .cash:
            .debitPaymentMethod
        case .unifiedChecking:
            .unifiedDebitPaymentMethod
        case .unifiedCredit:
            .unifiedCreditPaymentMethod
        default:
            .other
        }
    }


//    @ViewBuilder
//    var chartPage: some View {
//        if payMethod.action == .add {
//            ContentUnavailableView("Insights are not available when adding a new account", systemImage: "square.stack.3d.up.slash.fill")
//        } else {
//            VStack {
//                PayMethodDashboard(vm: viewModel, payMethod: payMethod)
//            }
//            .opacity(viewModel.isLoadingHistory ? 0 : 1)
//            .overlay {
//                ProgressView("Loading Insights…")
//                    .tint(.none)
//                    .opacity(viewModel.isLoadingHistory ? 1 : 0)
//            }
//            .focusable(false)
//        }
//    }
    
    
    
    
    
    
    // MARK: - Header & Footer Views
    var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            //Text("Delete Account")
                //.foregroundStyle(.red)
            Image(systemName: "trash")
        }
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
        .tint(.none)
        .confirmationDialog("Delete \"\(payMethod.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive, action: deletePaymentMethod)
            #if os(iOS)
            Button("No", role: .close) { showDeleteAlert = false }
            #else
            Button("No") { showDeleteAlert = false }
            #endif
        }, message: {
            #if os(iOS)
            Text("Delete \"\(payMethod.title)\"?\nThis will also delete all associated transactions and event transactions.")
            #else
            Text("This will also delete all associated transactions and event transactions.")
            #endif
        })
    }
    
    var notificationButton: some View {
        Button {
            payMethod.notifyOnDueDate.toggle()
        } label: {
            Image(systemName: payMethod.notifyOnDueDate ? "bell.slash.fill" : "bell.fill")
        }
        .tint(.none)
    }
    
    var refreshButton: some View {
        Button {
            payMethod.breakdowns.removeAll()
            payMethod.breakdownsRegardlessOfPaymentMethod.removeAll()
            Task {
                viewModel.fetchYearStart = AppState.shared.todayYear - 10
                viewModel.fetchYearEnd = AppState.shared.todayYear
                viewModel.payMethods.removeAll()
                viewModel.isLoadingHistory = true
                await viewModel.fetchHistory(for: payMethod, payModel: payModel, setChartAsNew: true)
            }
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
                .schemeBasedForegroundStyle()
        }
        .symbolEffect(.rotate, options: SymbolEffectOptions.repeat(.continuous).speed(3), isActive: viewModel.isLoadingHistory)
    }
    
//    var styleMenu: some View {
//        Menu {
//            Section("This Year Style") {
//                Picker(selection: $viewModel.chartCropingStyle) {
//                    Text("Whole year")
//                        .tag(ChartCropingStyle.showFullCurrentYear)
//                    Text("Through current month")
//                        .tag(ChartCropingStyle.endAtCurrentMonth)
//                } label: {
//                    Text(viewModel.chartCropingStyle.prettyValue)
//                }
//                .pickerStyle(.menu)
//            }
//            
//            Section("Overview Style") {
//                Picker(selection: $showOverviewDataPerMethodOnUnifiedChart) {
//                    Text("View as summary only")
//                        .tag(false)
//                    Text("View by payment method")
//                        .tag(true)
//                } label: {
//                    Text(showOverviewDataPerMethodOnUnifiedChart ? "By payment method" : "As summary only")
//                }
//                .pickerStyle(.menu)
//                
//            }
//        } label: {
//            Image(systemName: "line.3.horizontal.decrease")
//                .schemeBasedForegroundStyle()
//        }
//    }
        
    var closeButton: some View {
        Button {
            editID = nil; dismiss()
        } label: {
            Image(systemName: isValidToSave ? "checkmark" : "xmark")
                .schemeBasedForegroundStyle()
        }
    }
    
    var header: some View {
        Group {
            if (payMethod.accountType == .credit || payMethod.accountType == .loan) && payMethod.dueDate != nil {
                SheetHeader(
                    title: title,
                    close: { editID = nil; dismiss() },
                    view1: { notificationButton.disabled(payMethod.isUnified) },
                    view3: { deleteButton.disabled(payMethod.isUnified) }
                )
            } else {
                SheetHeader(
                    title: title,
                    close: { editID = nil; dismiss() },
                    view3: { deleteButton.disabled(payMethod.isUnified) }
                )
            }
        }
    }
        
    var fakeMacTabBar: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(.clear)
                .frame(height: 50)
                .contentShape(Rectangle())
                .overlay {
                    Label("Details", systemImage: "list.bullet")
                        .foregroundStyle(selectedTab == .details ? payMethod.color : .gray)
                }
                .onTapGesture {
                    selectedTab = .details
                }
            Rectangle()
                .fill(.clear)
                .frame(height: 50)
                .contentShape(Rectangle())
                .overlay {
                    Label("Insights", systemImage: "chart.xyaxis.line")
                        .foregroundStyle(selectedTab == .insights ? payMethod.color : .gray)
                }
                .onTapGesture {
                    selectedTab = .insights
                }
        }
        //.fixedSize(horizontal: false, vertical: true)
        .frame(height: 50)
    }
    
    
    private struct AccountHolders: View {
        @Bindable var payMethod: CBPaymentMethod
        
        var body: some View {
            NavigationStack {
                List {
                    Section("Primary") {
                        holderLine(id: 1, isPrimary: true)
                    }
                    Section("Secondary") {
                        holderLine(id: 2, isPrimary: false)
                        holderLine(id: 3, isPrimary: false)
                        holderLine(id: 4, isPrimary: false)
                    }
                }
                .navigationTitle("Account Holders")
            }
        }
        
        @ViewBuilder func holderLine(id: Int, isPrimary: Bool) -> some View {
            HStack {
                
                let user: CBUser? = switch id {
                case 1:
                    payMethod.holderOne
                case 2:
                    payMethod.holderTwo
                case 3:
                    payMethod.holderThree
                case 4:
                    payMethod.holderFour
                default:
                    nil
                }
                
                if let user = user {
                    UserAvatar(user: user)
                } else {
                    Image(systemName: "person.crop.circle")
                        .foregroundStyle(.gray)
                }
                
                
                accountUsersMenu(id: id)
                Spacer()
            }
        }
         
        @ViewBuilder func accountUsersMenu(id: Int) -> some View {
            Menu {
                let users = AppState.shared
                .accountUsers
                .filter {
                    payMethod.holderOne != $0
                    && payMethod.holderTwo != $0
                    && payMethod.holderThree != $0
                    && payMethod.holderFour != $0
                }
                
                Section {
                    Button("None") {
                        switch id {
                        case 1:
                            payMethod.holderOne = nil
                            payMethod.holderOneType = nil
                        case 2:
                            payMethod.holderTwo = nil
                            payMethod.holderTwoType = nil
                        case 3:
                            payMethod.holderThree = nil
                            payMethod.holderThreeType = nil
                        case 4:
                            payMethod.holderFour = nil
                            payMethod.holderFourType = nil
                        default:
                            break
                        }
                    }
                }
                
                
                ForEach(users) { user in
                    Button(user.name) {
                        switch id {
                        case 1:
                            payMethod.holderOne = user
                            payMethod.holderOneType = XrefModel.getItem(from: .paymentMethodHolderTypes, byEnumID: .primary)
                        case 2:
                            payMethod.holderTwo = user
                            payMethod.holderTwoType = XrefModel.getItem(from: .paymentMethodHolderTypes, byEnumID: .secondary)
                        case 3:
                            payMethod.holderThree = user
                            payMethod.holderThreeType = XrefModel.getItem(from: .paymentMethodHolderTypes, byEnumID: .secondary)
                        case 4:
                            payMethod.holderFour = user
                            payMethod.holderFourType = XrefModel.getItem(from: .paymentMethodHolderTypes, byEnumID: .secondary)
                        default:
                            break
                        }
                    }
                }
            } label: {
                let text: String? = switch id {
                case 1: payMethod.holderOne?.name
                case 2: payMethod.holderTwo?.name
                case 3: payMethod.holderThree?.name
                case 4: payMethod.holderFour?.name
                default: nil
                }
                
                Text(text ?? "Select Person")
                    .foregroundStyle(Color.theme)
            }
        }
    }
    
    
    
    // MARK: - Functions
    func prepareView() async {
        payMethod.deepCopy(.create)
        /// Just for formatting.
        payMethod.limitString = payMethod.limit?.currencyWithDecimals()
        payMethod.dueDateString = (payMethod.dueDate ?? 0).withOrdinal()
        payModel.upsert(payMethod)
        
        #if os(macOS)
        /// Focus on the title textfield.
        focusedField = 0
        #else
        if payMethod.action == .add {
            focusedField = 0
        }
        #endif
        
        if payMethod.action != .add {
            await viewModel.fetchHistory(for: payMethod, payModel: payModel, setChartAsNew: true)
        } else {
            viewModel.isLoadingHistory = false
        }
    }
    
    
    func deletePaymentMethod() {
        //Task {
            payMethod.action = .delete
            dismiss()
            //await payModel.delete(payMethod, andSubmit: true, calModel: calModel, eventModel: eventModel)
        //}
    }
}
