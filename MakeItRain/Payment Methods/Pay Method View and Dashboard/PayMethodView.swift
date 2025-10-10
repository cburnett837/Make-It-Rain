//
//  EditPaymentMethodView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/14/24.
//

import SwiftUI
import Charts
//import LinkKit


struct PayMethodView: View {
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
    @Local(\.incomeColor) var incomeColor
    @Local(\.useWholeNumbers) var useWholeNumbers
    @AppStorage("selectedPaymentMethodTab") var selectedTab: DetailsOrInsights = .details
    @AppStorage(LocalKeys.Charts.Options.showOverviewDataPerMethodOnUnified) var showOverviewDataPerMethodOnUnifiedChart = false

    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(CalendarModel.self) private var calModel
    @Environment(EventModel.self) private var eventModel
    @Environment(PayMethodModel.self) private var payModel
    
    @State private var viewModel = PayMethodViewModel()
    
    @Bindable var payMethod: CBPaymentMethod
    
    /// This is only here to blank out the selection hilight on the iPhone list
    @Binding var editID: String?
        
    @State private var showDeleteAlert = false
    @State private var labelWidth: CGFloat = 20.0
    @State private var showColorPicker = false
    
    @FocusState private var focusedField: Int?
    
    @State private var accountTypeMenuColor: Color = Color(.tertiarySystemFill)
    
    @Namespace private var namespace

        
    var isValidToSave: Bool {
        (payMethod.action == .add && !payMethod.title.isEmpty)
        || (payMethod.hasChanges() && !payMethod.title.isEmpty)
    }
    
    
    var title: String {
        if selectedTab == .details {
            if payMethod.isUnified {
                payMethod.title
            } else {
                payMethod.action == .add ? "New Account" : "Edit Account"
            }
        } else {
            payMethod.title
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
                VStack {
                    if payMethod.isUnified {
                        chartPage
                    } else {
                        VStack {
                            //if (payMethod.accountType == .credit || payMethod.accountType == .loan) {
                                Picker("",selection: $selectedTab.animation(pickerAnimation)) {
                                    Text("Details")
                                        .tag(DetailsOrInsights.details)
                                    Text("Insights")
                                        .tag(DetailsOrInsights.insights)
                                }
                                .labelsHidden()
                                .pickerStyle(.segmented)
                                .scenePadding(.horizontal)
//                            }
                                                                                    
                            if selectedTab == .details {
                                editPagePhone
                            } else {
                                chartPage
                            }
                        }
                    }
                }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        GlassEffectContainer {
                            if selectedTab == .insights {
                                refreshButton
                                    .glassEffectID("refresh", in: namespace)
//                                PaymentMethodChartStyleMenu(vm: viewModel)
//                                    .glassEffectID("style", in: namespace)
                                
                            } else {
                                if !payMethod.isUnified {
                                    deleteButton
                                        .glassEffectID("delete", in: namespace)
                                }
                            }
                        }
                    }
                    
                    if selectedTab == .insights {
                        ToolbarSpacer(.fixed, placement: .topBarLeading)
                        
                        ToolbarItem(placement: .topBarLeading) {
                            GlassEffectContainer {
                                PaymentMethodChartStyleMenu(vm: viewModel)
                                    .glassEffectID("style", in: namespace)
//                                refreshButton
//                                    .glassEffectID("refresh", in: namespace)
                            }
                        }
                    } else {
                        ToolbarSpacer(.fixed, placement: .topBarLeading)
                        
                        ToolbarItem(placement: .topBarLeading) {
                            GlassEffectContainer {
                                if (payMethod.accountType == .credit || payMethod.accountType == .loan) && payMethod.dueDate != nil {
                                    notificationButton.disabled(payMethod.isUnified)
                                        .glassEffectID("notify", in: namespace)
                                }
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        if isValidToSave {
                            closeButton
                                #if os(iOS)
                                .buttonStyle(.glassProminent)
                                #endif
                        } else {
                            closeButton
                        }
                    }
                    
                    ToolbarItem(placement: .bottomBar) {
                        EnteredByAndUpdatedByView(enteredBy: payMethod.enteredBy, updatedBy: payMethod.updatedBy, enteredDate: payMethod.enteredDate, updatedDate: payMethod.updatedDate)
                    }
                    .sharedBackgroundVisibility(.hidden)
                }
            }
            
            #else
            
            VStack {
                Group {
                    if selectedTab == .details {
                        editPageMac
                    } else {
                        chartPage
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
    
    
    // MARK: - Edit Page
    var editPagePhone: some View {
        StandardContainerWithToolbar(.list) {
            Section("Title") {
                titleRow
            }
            
            Section {
                typeRowPhone
                colorRow
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

            
            
//            if payMethod.accountType == .checking || payMethod.accountType == .credit {
//                Section {
//                    last4Row
//                } footer: {
//                    Text("If you wish to use the smart receipt feature offered by ChatGPT, enter the last 4 digits of your card information. If not, you can leave this field blank.")
//                        .validate(payMethod.last4 ?? "", rules: .regex(.onlyNumbers, "Only numbers are allowed"))
//                }
//            }
            
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
        }
    }
    
    
    
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
                
    
    // MARK: - Title
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
    
    
        
    // MARK: - Type
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
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
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
    
    
    
    // MARK: - Last 4
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
            .uiKeyboardType(.numberPad)
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
    
    
    
    // MARK: - Due Date
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
                .uiKeyboardType(.decimalPad)
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
    
    
    
    // MARK: - Limit
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
                .uiKeyboardType(.decimalPad)
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
    
    
    
    // MARK: - Interest Rate
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
            .uiKeyboardType(.decimalPad)
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
    
    
    
    // MARK: - Loan Duration
    @ViewBuilder
    var loanDurationRow: some View {
        #if os(iOS)
        HStack {
            Label {
                HStack(spacing: 2) {
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
            .uiKeyboardType(.numberPad)
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
    
    
    
    // MARK: - Is Private
    var isPrivateRow: some View {
        #if os(iOS)
        Toggle(isOn: $payMethod.isPrivate.animation()) {
            Label {
                Text("Mark as Private")
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
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
    
   
    
    // MARK: - Is Hidden
    var isHiddenRow: some View {
        #if os(iOS)
        Toggle(isOn: $payMethod.isHidden.animation()) {
            Label {
                Text("Mark as Hidden")
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
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
 
    
    
    // MARK: - Reminder
    var reminderRow: some View {
        #if os(iOS)
        HStack {
            Picker(selection: $payMethod.notificationOffset) {
                Text("2 days before")
                    .tag(2)
                Text("1 day before")
                    .tag(1)
                Text("Day of")
                    .tag(0)
            } label: {
                Label {
                    Text("Reminder")
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                } icon: {
                    Image(systemName: "alarm")
                        .foregroundStyle(.gray)
                }
            }
        }
        
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
    
    
    
    // MARK: - Color
    var colorRow: some View {
        #if os(iOS)
        Button {
            showColorPicker = true
        } label: {
            HStack {
                Label {
                    Text("Color")
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                } icon: {
                    Image(systemName: "lightspectrum.horizontal")
                        .foregroundStyle(.gray)
                }
                Spacer()
                //StandardColorPicker(color: $payMethod.color)
                Image(systemName: "circle.fill")
                    .font(.system(size: 24))
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

    var profitLossText: String { payMethod.isCredit ? "Available Balance": "Profit/Loss" }
    var incomeText: String { payMethod.isCredit ? "Income / Refunds": "Income / Refunds / Deposits" }

    @ViewBuilder
    var chartPage: some View {
        if payMethod.action == .add {
            ContentUnavailableView("Insights are not available when adding a new account", systemImage: "square.stack.3d.up.slash.fill")
        } else {
            VStack {
                PayMethodDashboard(vm: viewModel, editID: $editID, payMethod: payMethod)
            }
            .opacity(viewModel.isLoadingHistory ? 0 : 1)
            .overlay {
                ProgressView("Loading Insights…")
                    .tint(.none)
                    .opacity(viewModel.isLoadingHistory ? 1 : 0)
            }
            .focusable(false)
        }
    }
    
    
    
    
    
    
    // MARK: - Header & Footer Views
    var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Image(systemName: "trash")
        }
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
        .tint(.none)
        .confirmationDialog("Delete \"\(payMethod.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive, action: deletePaymentMethod)
            //Button("No", role: .cancel) { showDeleteAlert = false }
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
                .foregroundStyle(colorScheme == .dark ? .white : .black)
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
//                .foregroundStyle(colorScheme == .dark ? .white : .black)
//        }
//    }
        
    var closeButton: some View {
        Button {
            editID = nil; dismiss()
        } label: {
            Image(systemName: isValidToSave ? "checkmark" : "xmark")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
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
    
    
    
    
    // MARK: - Functions
    func prepareView() async {
        
        if payMethod.isUnified {
            selectedTab = .insights
        }
        
        payMethod.deepCopy(.create)
        /// Just for formatting.
        payMethod.limitString = payMethod.limit?.currencyWithDecimals(useWholeNumbers ? 0 : 2)
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
        }
    }
    
    
    func deletePaymentMethod() {
        Task {
            dismiss()
            await payModel.delete(payMethod, andSubmit: true, calModel: calModel, eventModel: eventModel)
        }
    }
}
