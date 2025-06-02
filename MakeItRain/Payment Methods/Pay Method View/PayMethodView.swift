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
    @AppStorage("selectedPaymentMethodTab") var selectedPaymentMethodTab: String = "details"

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
    
    @FocusState private var focusedField: Int?
    
    @State private var accountTypeMenuColor: Color = Color(.tertiarySystemFill)
        
    
    var title: String {
        if selectedPaymentMethodTab == "details" {
            if payMethod.isUnified {
                payMethod.title
            } else {
                payMethod.action == .add ? "New Account" : "Edit Account"
            }
        } else {
            payMethod.title
        }
    }
    

    
    
    var body: some View {
        Group {
            #if os(iOS)
            if payMethod.isUnified {
                chartPage
            } else {
                TabView(selection: $selectedPaymentMethodTab) {
                    Tab(value: "details") {
                        editPage
                    } label: {
                        Label("Details", systemImage: "list.bullet")
                    }
                    
                    Tab(value: "analytics") {
                        chartPage
                    } label: {
                        Label("Insights", systemImage: "chart.xyaxis.line")
                    }
                }
                //.tint(payMethod.color)
            }
            
            #else
            
            VStack {
                Group {
                    if selectedPaymentMethodTab == "details" {
                        editPage
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
        .confirmationDialog("Delete \"\(payMethod.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive, action: deletePaymentMethod)
            Button("No", role: .cancel) { showDeleteAlert = false }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(payMethod.title)\"?\nThis will also delete all associated transactions and event transactions.")
            #else
            Text("This will also delete all associated transactions and event transactions.")
            #endif
        })
    }
    
    
    // MARK: - Edit Page
    var editPage: some View {
        StandardContainer {
            titleRow
            typeRow
            
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
        LabeledRow("Name", labelWidth) {
            #if os(iOS)
            StandardUITextField("Name", text: $payMethod.title, toolbar: {
                KeyboardToolbarView(focusedField: $focusedField)
            })
            .cbFocused(_focusedField, equals: 0)
            .cbClearButtonMode(.whileEditing)
            #else
            StandardTextField("Name", text: $payMethod.title, focusedField: $focusedField, focusValue: 0)
            #endif
        }
    }
    
    
    var typeRow: some View {
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
    
    
    var last4Row: some View {
        LabeledRow("Last 4", labelWidth) {
            Group {
                #if os(iOS)
                StandardUITextField("Last 4 Digits", text: $payMethod.last4 ?? "", toolbar: {
                    KeyboardToolbarView(focusedField: $focusedField)
                })
                .cbKeyboardType(.numberPad)
                .cbFocused(_focusedField, equals: 1)
                .cbClearButtonMode(.whileEditing)
                .cbMaxLength(4)
                #else
                StandardTextField("Last 4 Digits", text: $payMethod.last4 ?? "", focusedField: $focusedField, focusValue: 1)
                #endif
            }
        } subContent: {
            Text("If you wish to use the smart receipt feature offered by ChatGPT, enter the last 4 digits of your card information. If not, you can leave this field blank.")
                .validate(payMethod.last4 ?? "", rules: .regex(.onlyNumbers, "Only numbers are allowed"))
        }
    }
    
    
    var dueDateRow: some View {
        LabeledRow("Due Date", labelWidth) {
            Group {
                #if os(iOS)
                StandardUITextField("(day number only)", text: $payMethod.dueDateString ?? "", onBeginEditing: {
                    payMethod.dueDateString = payMethod.dueDateString?.replacing(/[a-z]+/, with: "", maxReplacements: 1)
                }, toolbar: {
                    KeyboardToolbarView(focusedField: $focusedField)
                })
                .cbFocused(_focusedField, equals: 2)
                .cbClearButtonMode(.whileEditing)
                .cbKeyboardType(.numberPad)
                .cbMaxLength(2)
                #else
                StandardTextField("(day number only)", text: $payMethod.dueDateString ?? "", focusedField: $focusedField, focusValue: 2)
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
    }
    
    @ViewBuilder
    var limitRow: some View {
        var limitLingo: String {
            if payMethod.accountType == .credit {
                "Limit"
            } else {
                "Amount"
            }
        }
        
        LabeledRow(limitLingo, labelWidth) {
            Group {
                #if os(iOS)
                StandardUITextField(limitLingo, text: $payMethod.limitString ?? "", toolbar: {
                    KeyboardToolbarView(focusedField: $focusedField)
                })
                .cbFocused(_focusedField, equals: 3)
                .cbClearButtonMode(.whileEditing)
                .cbKeyboardType(.decimalPad)
                #else
                StandardTextField(limitLingo, text: $payMethod.limitString ?? "", focusedField: $focusedField, focusValue: 3)
                #endif
            }
            .formatCurrencyLiveAndOnUnFocus(
                focusValue: 3,
                focusedField: focusedField,
                amountString: payMethod.limitString,
                amountStringBinding: $payMethod.limitString ?? "",
                amount: payMethod.limit
            )
        } subContent: {
            EmptyView()
                .validate(payMethod.limitString ?? "", rules: .regex(.currency, "The entered amount must be currency"))
        }
    }
    
    @ViewBuilder
    var interestRateRow: some View {
        LabeledRow("Interest Rate", labelWidth) {
            Group {
                #if os(iOS)
                StandardUITextField("Interest Rate", text: $payMethod.interestRateString ?? "", toolbar: {
                    KeyboardToolbarView(focusedField: $focusedField)
                })
                .cbFocused(_focusedField, equals: 4)
                .cbClearButtonMode(.whileEditing)
                .cbKeyboardType(.decimalPad)
                #else
                StandardTextField("Interest Rate", text: $payMethod.interestRateString ?? "", focusedField: $focusedField, focusValue: 4)
                #endif
            }
            
        } subContent: {
            EmptyView()
                .validate(payMethod.interestRateString ?? "", rules: .regex(.onlyDecimals, "Only decimal numbers are allowed"))
        }
    }
    
    @ViewBuilder
    var loanDurationRow: some View {
        LabeledRow("Loan Duration", labelWidth) {
            Group {
                #if os(iOS)
                StandardUITextField("Loan Duration", text: $payMethod.loanDurationString ?? "", toolbar: {
                    KeyboardToolbarView(focusedField: $focusedField)
                })
                .cbFocused(_focusedField, equals: 5)
                .cbClearButtonMode(.whileEditing)
                .cbKeyboardType(.numberPad)
                #else
                StandardTextField("Loan Duration", text: $payMethod.loanDurationString ?? "", focusedField: $focusedField, focusValue: 5)
                #endif
            }
            
        } subContent: {
            Text("(Months)")
                .validate(payMethod.loanDurationString ?? "", rules: .regex(.onlyNumbers, "Only numbers are allowed"))
        }
    }
    
    
    var reminderRow: some View {
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
    }
    
    
    var colorRow: some View {
        LabeledRow("Color", labelWidth) {
            #if os(iOS)
            StandardColorPicker(color: $payMethod.color)
            #else
            HStack {
                ColorPicker("", selection: $payMethod.color, supportsOpacity: false)
                    .labelsHidden()
                Capsule()
                    .fill(payMethod.color)
                    .onTapGesture {
                        AppState.shared.showToast(title: "Color Picker", subtitle: "Click the circle to the left to change the color.", body: nil, symbol: "theatermask.and.paintbrush", symbolColor: payMethod.color)
                    }
            }
            #endif
        }
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

    var chartPage: some View {
        Group {
            if payMethod.action == .add {
                ContentUnavailableView("Insights are not available when adding a new account", systemImage: "square.stack.3d.up.slash.fill")
            } else {
                PayMethodChart(vm: viewModel, editID: $editID, payMethod: payMethod)
                    .opacity(viewModel.isLoadingHistory ? 0 : 1)
                    .overlay {
                        ProgressView("Loading Insights…")
                            .tint(.none)
                            .opacity(viewModel.isLoadingHistory ? 1 : 0)
                    }
                    .focusable(false)
            }
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
    }
    
    var notificationButton: some View {
        Button {
            payMethod.notifyOnDueDate.toggle()
        } label: {
            Image(systemName: payMethod.notifyOnDueDate ? "bell.slash.fill" : "bell.fill")
        }
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
                        .foregroundStyle(selectedPaymentMethodTab == "details" ? payMethod.color : .gray)
                }
                .onTapGesture {
                    selectedPaymentMethodTab = "details"
                }
            Rectangle()
                .fill(.clear)
                .frame(height: 50)
                .contentShape(Rectangle())
                .overlay {
                    Label("Insights", systemImage: "chart.xyaxis.line")
                        .foregroundStyle(selectedPaymentMethodTab == "analytics" ? payMethod.color : .gray)
                }
                .onTapGesture {
                    selectedPaymentMethodTab = "analytics"
                }
        }
        //.fixedSize(horizontal: false, vertical: true)
        .frame(height: 50)
    }
    
    
    
    
    // MARK: - Functions
    func prepareView() async {
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
