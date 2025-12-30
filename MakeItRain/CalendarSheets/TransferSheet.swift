//
//  TransferSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/24/24.
//

import SwiftUI

struct TransferSheet: View {
    private enum TransferType { case cashAdvance, deposit, payment, transfer, savings, withdrawal }
    
    @Local(\.useWholeNumbers) var useWholeNumbers
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(CalendarModel.self) private var calModel
    @Environment(CategoryModel.self) private var catModel
        
    var defaultDate: Date
    
    @State private var date: Date = Date()
    @State private var labelWidth: CGFloat = 20.0
    @State private var transfer = CBTransfer()
    @FocusState private var focusedField: Int?

    private var transferType: TransferType {
        if transfer.from?.accountType == .credit || transfer.from?.accountType == .loan {
            return .cashAdvance
        } else if transfer.from?.accountType == .cash && transfer.to?.accountType == .checking {
            return .deposit
        } else if transfer.to?.accountType == .credit || transfer.to?.accountType == .loan {
            return .payment
        } else if transfer.from?.accountType == .checking && transfer.to?.accountType == .cash {
            return .withdrawal
        } else if transfer.to?.accountType == .savings {
            return .savings
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
        case .savings:
            "New Savings"
        case .withdrawal:
            "New Withdrawal"
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
        case .savings:
            "Savings"
        case .withdrawal:
            "Withdrawal"
        }
    }
    
    
    var isValidToSave: Bool {
        (transfer.from != nil && transfer.to != nil && transfer.amount != 0.0)
    }
    
    var body: some View {
        NavigationStack {
            #if os(iOS)
            bodyPhone
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        closeButton
//                        if isValidToSave {
//                            closeButton
//                                .buttonStyle(.glassProminent)
//                        } else {
//                            closeButton
//                        }
                    }
                }
            #else
            bodyMac
            #endif
        }
        .task {
            self.date = defaultDate
        }
        .onChange(of: transferType) {
            if $1 == .payment { transfer.category = catModel.categories.first { $0.isPayment } }
            if $1 == .savings { transfer.category = catModel.categories.first { $0.isSavings } }
        }
    }
    
    #if os(macOS)
    var bodyMac: some View {
        StandardContainer {
            LabeledRow("From", labelWidth) {
                PayMethodSheetButtonMac(payMethod: $transfer.from, whichPaymentMethods: .allExceptUnified)
            }
            
            LabeledRow("To", labelWidth) {
                PayMethodSheetButtonMac(payMethod: $transfer.to, whichPaymentMethods: .allExceptUnified)
            }
            
            StandardDivider()
            
            LabeledRow("Category", labelWidth) {
                CategorySheetButtonMac(category: $transfer.category)
            }
            
            StandardDivider()
            
            LabeledRow("Amount", labelWidth) {
                StandardTextField("Amount", text: $transfer.amountString, focusedField: $focusedField, focusValue: 1)
                    .formatCurrencyLiveAndOnUnFocus(
                        focusValue: 1,
                        focusedField: focusedField,
                        amountString: transfer.amountString,
                        amountStringBinding: $transfer.amountString,
                        amount: transfer.amount
                    )
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
            transferButtonMac
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
//        .task {
//            //print(day?.date)
//        }
    }
    #endif
    
    
    #if os(iOS)
    var bodyPhone: some View {
        StandardContainerWithToolbar(.list) {
            
            Section("Amount") {
                amountRowPhone
            }
            
            Section {
                dateRow
            }
            
            Section {
                PayMethodSheetButtonPhone(
                    text: "From",
                    logoFallBackType: .customImage(.init(name: transfer.from?.fallbackImage, color: transfer.from?.color)),
                    payMethod: $transfer.from,
                    whichPaymentMethods: .allExceptUnified
                )
                
                PayMethodSheetButtonPhone(
                    text: "To",
                    logoFallBackType: .customImage(.init(name: transfer.to?.fallbackImage, color: transfer.to?.color)),
                    payMethod: $transfer.to,
                    whichPaymentMethods: .allExceptUnified
                )
                
                CategorySheetButtonPhone(category: $transfer.category)
            }
                        
               
            transferButtonPhone
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
    }
    #endif
   
        
    var amountRowPhone: some View {
        HStack(spacing: 0) {
            Label {
                Text("")
            } icon: {
                Image(systemName: "dollarsign.circle")
                    .foregroundStyle(.gray)
            }
            
            Group {
                #if os(iOS)
                UITextFieldWrapper(placeholder: "Transfer Amount", text: $transfer.amountString, toolbar: {
                    KeyboardToolbarView(focusedField: $focusedField, removeNavButtons: true)
                })
                .uiTag(1)
                .uiClearButtonMode(.whileEditing)
                .uiStartCursorAtEnd(true)
                .uiTextAlignment(.left)
                .uiKeyboardType(.custom(.numpad))
                //.uiKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
                //.uiTextColor(.secondaryLabel)
                //.uiTextAlignment(.right)
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
    
    
    var dateRow: some View {
        HStack(spacing: 0) {
            Label {
                Text("Date")
            } icon: {
                Image(systemName: "calendar")
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            DatePicker("", selection: $date, displayedComponents: [.date])
                .frame(maxWidth: .infinity, alignment: .trailing)
                .labelsHidden()
        }
        .listRowInsets(EdgeInsets())
        .padding(.horizontal, 16)
    }
    
    
    var transferButtonPhone: some View {
        Button(action: validateForm) {
            Text("Create \(transferLingo)")
        }
        .foregroundStyle(Color.theme)
        .disabled(transfer.from == nil || transfer.to == nil || transfer.amount == 0.0)
    }
    
    
    var transferButtonMac: some View {
        Button(action: validateForm) {
            Text("Create \(transferLingo)")
        }
        .padding(.bottom, 6)
        #if os(macOS)
        .foregroundStyle(Color.theme)
        .buttonStyle(.codyStandardWithHover)
        #else
        .tint(Color.theme)
        .buttonStyle(.borderedProminent)
        #endif
        .disabled(transfer.from == nil || transfer.to == nil || transfer.amount == 0.0)
    }
    
    
    var closeButton: some View {
        Button {
            dismiss()
//            if isValidToSave {
//                validateForm()
//            } else {
//                dismiss()
//            }
            
        } label: {
            //Image(systemName: isValidToSave ? "checkmark" : "xmark")
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
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
                                    
            if transfer.from?.accountType == .credit || transfer.from?.accountType == .loan {
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
                fromTrans.isPaymentOrigin = true
                toTrans.isPaymentDest = true
            } else {
                fromTrans.isTransferOrigin = true
                toTrans.isTransferDest = true
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
            
            
            fromTrans.status = .editing
            toTrans.status = .editing
            
            
            let _ = calModel.calculateTotal(for: calModel.sMonth)
            
            await calModel.addMultiple(
                trans: [fromTrans, toTrans],
                budgets: [],
                isTransfer: true
            )
        }
    }
}

