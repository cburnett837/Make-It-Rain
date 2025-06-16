//
//  TransferSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/24/24.
//

import SwiftUI

struct TransferSheet: View {
    
    private enum TransferType {
        case cashAdvance, deposit, payment, transfer
    }
    
    @Local(\.colorTheme) var colorTheme
    @Local(\.useWholeNumbers) var useWholeNumbers
    
    @Environment(\.dismiss) var dismiss
    @Environment(CalendarModel.self) private var calModel
    @Environment(CategoryModel.self) private var catModel
    
    
    @State var date: Date
    
    @State private var labelWidth: CGFloat = 20.0
    @State private var transfer = CBTransfer()
    @FocusState private var focusedField: Int?

    private var transferType: TransferType {
        if transfer.from?.accountType == .credit {
            return .cashAdvance
        } else if transfer.from?.accountType == .cash && transfer.to?.accountType == .checking {
            return .deposit
        } else if transfer.to?.accountType == .credit || transfer.to?.accountType == .loan {
            return .payment
        } else {
            return .transfer
        }
    }
    
    
    var title: String {
        switch transferType {
        case .cashAdvance:
            "New Cash Advance"
        case .deposit:
            "New Deposit"
        case .payment:
            "New Payment"
        case .transfer:
            "New Transfer"
        }
    }
    
    
    var transferLingo: String {
        switch transferType {
        case .cashAdvance:
            "Cash advance"
        case .deposit:
            "Deposit"
        case .payment:
            "Payment"
        case .transfer:
            "Transfer"
        }
    }
    
    var body: some View {
        Group {
            #if os(macOS)
            body1
            #else
            body2
            #endif        
        }
        .onChange(of: transferType) {
            if $1 == .payment {
                transfer.category = catModel.categories.first { $0.isPayment }
            }
        }
    }
    
    var body1: some View {
        StandardContainer {
            LabeledRow("From", labelWidth) {
                PayMethodSheetButton(payMethod: $transfer.from, whichPaymentMethods: .allExceptUnified)
            }
            
            LabeledRow("To", labelWidth) {
                PayMethodSheetButton(payMethod: $transfer.to, whichPaymentMethods: .allExceptUnified)
            }
            
            StandardDivider()
            
            LabeledRow("Category", labelWidth) {
                CategorySheetButton(category: $transfer.category)
            }
            
            StandardDivider()
            
            LabeledRow("Amount", labelWidth) {
                Group {
                    #if os(iOS)
                    StandardUITextField("Amount", text: $transfer.amountString, toolbar: {
                        KeyboardToolbarView(focusedField: $focusedField, removeNavButtons: true)
                    })
                    .cbClearButtonMode(.whileEditing)
                    .cbFocused(_focusedField, equals: 1)
                    .cbKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
                    #else
                    StandardTextField("Amount", text: $transfer.amountString, focusedField: $focusedField, focusValue: 1)
                    #endif
                }
                .formatCurrencyLiveAndOnUnFocus(
                    focusValue: 1,
                    focusedField: focusedField,
                    amountString: transfer.amountString,
                    amountStringBinding: $transfer.amountString,
                    amount: transfer.amount
                )

//                    StandardTextField("Amount", text: $transfer.amountString, focusedField: $focusedField, focusValue: 0)
//                        .onChange(of: transfer.amountString) { oldValue, newValue in
//                            transfer.amountString = transfer.amountString.replacingOccurrences(of: "-", with: "")
//                        }
//                        #if os(iOS)
//                        .keyboardType(.decimalPad)
//                        #endif
            }
            
            StandardDivider()
            
            LabeledRow("Date", labelWidth) {
                DatePicker("", selection: $date, displayedComponents: [.date])
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .labelsHidden()
            }
        } header: {
            SheetHeader(title: title, close: { dismiss() })
        } footer: {
            transferButton
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
//        .task {
//            //print(day?.date)
//        }
    }
    
    
    var body2: some View {
        StandardContainer(.list) {
            Section("Account Details") {
                payFromRow2
                payToRow2
            }
                        
            Section {
                categoryRow2
            }
            
            Section {
                amountRow2
                DatePicker("Date", selection: $date, displayedComponents: [.date])
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
                        
            transferButton2
            
        } header: {
            SheetHeader(title: title, close: { dismiss() })
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
    }
    
    
    
    
    var payFromRow2: some View {
        HStack {
            Text("From")
            Spacer()
            PayMethodSheetButton2(payMethod: $transfer.from, whichPaymentMethods: .allExceptUnified)
        }
    }
    
    
    var payToRow2: some View {
        HStack {
            Text("To")
            Spacer()
            PayMethodSheetButton2(payMethod: $transfer.to, whichPaymentMethods: .allExceptUnified)
        }
    }
    
    
    var categoryRow2: some View {
        HStack {
            Text("Category")
            Spacer()
            CategorySheetButton2(category: $transfer.category)
        }
    }
    
    
    
    var amountRow2: some View {
        HStack {
            Text("Amount")
            Spacer()
            
            Group {
                #if os(iOS)
                UITextFieldWrapper(placeholder: "Amount", text: $transfer.amountString, toolbar: {
                    KeyboardToolbarView(focusedField: $focusedField, removeNavButtons: true)
                })
                .uiTag(1)
                .uiClearButtonMode(.whileEditing)
                .uiStartCursorAtEnd(true)
                .uiTextAlignment(.right)
                .uiKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
                .uiTextColor(.secondaryLabel)
                .uiTextAlignment(.right)
                #else
                StandardTextField("Amount", text: $transfer.amountString, focusedField: $focusedField, focusValue: 1)
                #endif
            }
            .focused($focusedField, equals: 1)
            .formatCurrencyLiveAndOnUnFocus(
                focusValue: 1,
                focusedField: focusedField,
                amountString: transfer.amountString,
                amountStringBinding: $transfer.amountString,
                amount: transfer.amount
            )
        }
        .validate(transfer.amountString, rules: .regex(.positiveCurrency, "The entered amount must be positive currency"))
    }
    
    
    var transferButton2: some View {
        Button(action: validateForm) {
            Text("Create \(transferLingo)")
        }
        .foregroundStyle(Color.fromName(colorTheme))
        .disabled(transfer.from == nil || transfer.to == nil || transfer.amount == 0.0)
    }
    
    
    
    
    
    
    var transferButton: some View {
        Button(action: validateForm) {
            Text("Create \(transferLingo)")
        }
        .padding(.bottom, 6)
        #if os(macOS)
        .foregroundStyle(Color.fromName(colorTheme))
        .buttonStyle(.codyStandardWithHover)
        #else
        .tint(Color.fromName(colorTheme))
        .buttonStyle(.borderedProminent)
        #endif
        .disabled(transfer.from == nil || transfer.to == nil || transfer.amount == 0.0)
    }
    
    func validateForm() {
        if transfer.from == nil {
            AppState.shared.showAlert("From must be filled out")
            return
            
        } else if transfer.to == nil {
            AppState.shared.showAlert("To must be filled out")
            return
            
        } else if transfer.amount == 0.0 {
            AppState.shared.showAlert("You must enter a dollar amount greater than 0")
            return
            
        } else {
            createTransfer()
        }
    }
    
    
    func createTransfer() {
        Task {
            dismiss()
            
            let fromTrans = calModel.getTransaction(by: UUID().uuidString, from: .normalList)
            fromTrans.title = "\(transferLingo) to \(transfer.to?.title ?? "N/A")"
            fromTrans.date = date
                                    
            if transfer.from?.accountType == .credit || transfer.to?.accountType == .loan {
                fromTrans.amountString = (transfer.amount * 1).currencyWithDecimals(useWholeNumbers ? 0 : 2)
            } else {
                fromTrans.amountString = (transfer.amount * -1).currencyWithDecimals(useWholeNumbers ? 0 : 2)
            }
            
            fromTrans.payMethod = transfer.from
            fromTrans.category = transfer.category
            fromTrans.updatedBy = AppState.shared.user!
            fromTrans.updatedDate = Date()
            fromTrans.relatedTransactionType = XrefModel.getItem(from: .relatedTransactionType, byEnumID: .transaction)
                        
            let toTrans = calModel.getTransaction(by: UUID().uuidString, from: .normalList)
            toTrans.title = "\(transferLingo) from \(transfer.from?.title ?? "N/A")"
            toTrans.date = date
            toTrans.relatedTransactionType = XrefModel.getItem(from: .relatedTransactionType, byEnumID: .transaction)
            
            if transfer.to?.accountType == .credit || transfer.to?.accountType == .loan {
                toTrans.amountString = (transfer.amount * -1).currencyWithDecimals(useWholeNumbers ? 0 : 2)
            } else {
                toTrans.amountString = (transfer.amount * 1).currencyWithDecimals(useWholeNumbers ? 0 : 2)
            }
            
            toTrans.payMethod = transfer.to
            toTrans.category = transfer.category
            toTrans.updatedBy = AppState.shared.user!
            toTrans.updatedDate = Date()
            
            
            if transferType == .payment {
                toTrans.isPayment = true
            }
            
                                    
            let transferMonth = date.month
            let transferDay = date.day
            let transferYear = date.year
            
            
            fromTrans.relatedTransactionID = toTrans.id
            fromTrans.relatedTransactionType = XrefModel.getItem(from: .relatedTransactionType, byEnumID: .transaction)
            
            toTrans.relatedTransactionID = fromTrans.id
            toTrans.relatedTransactionType = XrefModel.getItem(from: .relatedTransactionType, byEnumID: .transaction)
            
            
            
            if transferYear == calModel.sYear || (transferMonth == 1 && transferYear == calModel.sYear + 1) || (transferMonth == 12 && transferYear == calModel.sYear - 1) {
                if let theMonth = calModel.months.filter({ $0.actualNum == transferMonth && $0.year == transferYear }).first {
                    if let theDay = theMonth.days.filter({ $0.dateComponents?.day == transferDay }).first {
                        theDay.upsert(fromTrans)
                        theDay.upsert(toTrans)
                    }
                }
            }
            
            let _ = calModel.calculateTotal(for: calModel.sMonth)
            
            await calModel.addMultiple(trans: [fromTrans, toTrans], budgets: [], isTransfer: true)
        }
    }
}

