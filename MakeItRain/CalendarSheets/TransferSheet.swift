//
//  TransferSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/24/24.
//

import SwiftUI

struct TransferSheet2: View {
    @AppStorage("appColorTheme") var appColorTheme: String = Color.blue.description
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    
    @Environment(\.dismiss) var dismiss
    @Environment(CalendarModel.self) private var calModel
    
    
    @State var date: Date
    
    @State private var labelWidth: CGFloat = 20.0
    @State private var transfer = CBTransfer()
    @FocusState private var focusedField: Int?

    
    var title: String {
        if transfer.from?.accountType == .credit {
            return "New Cash Advance"
        } else if transfer.from?.accountType == .cash && transfer.to?.accountType == .checking {
            return "New Deposit"
        } else if transfer.to?.accountType == .credit {
            return "New Payment"
        } else {
            return "New Transfer"
        }
    }
    
    
    var transferLingo: String {
        if transfer.from?.accountType == .credit {
            return "Cash advance"
        } else if transfer.from?.accountType == .cash && transfer.to?.accountType == .checking {
            return "Deposit"
        } else if transfer.to?.accountType == .credit {
            return "Payment"
        } else {
            return "Transfer"
        }
    }
    
    var body: some View {
        SheetContainerView {
            LabeledRow("From", labelWidth) {
                PaymentMethodSheetButton(payMethod: $transfer.from, whichPaymentMethods: .allExceptUnified)
            }
            
            LabeledRow("To", labelWidth) {
                PaymentMethodSheetButton(payMethod: $transfer.to, whichPaymentMethods: .allExceptUnified)
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
    
    var transferButton: some View {
        Button(action: validateForm) {
            Text("Transfer")
        }
        .padding(.bottom, 6)
        #if os(macOS)
        .foregroundStyle(Color.fromName(appColorTheme))
        .buttonStyle(.codyStandardWithHover)
        #else
        .tint(Color.fromName(appColorTheme))
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
                                    
            if transfer.from?.accountType == .credit {
                fromTrans.amountString = (transfer.amount * 1).currencyWithDecimals(useWholeNumbers ? 0 : 2)
            } else {
                fromTrans.amountString = (transfer.amount * -1).currencyWithDecimals(useWholeNumbers ? 0 : 2)
            }
            
            fromTrans.payMethod = transfer.from
            fromTrans.category = transfer.category
            fromTrans.updatedBy = AppState.shared.user!
            fromTrans.relatedTransactionType = XrefModel.getItem(from: .relatedTransactionType, byEnumID: .transaction)
                        
            let toTrans = calModel.getTransaction(by: UUID().uuidString, from: .normalList)
            toTrans.title = "\(transferLingo) from \(transfer.from?.title ?? "N/A")"
            toTrans.date = date
            toTrans.relatedTransactionType = XrefModel.getItem(from: .relatedTransactionType, byEnumID: .transaction)
            
            if transfer.to?.accountType == .credit {
                toTrans.amountString = (transfer.amount * -1).currencyWithDecimals(useWholeNumbers ? 0 : 2)
            } else {
                toTrans.amountString = (transfer.amount * 1).currencyWithDecimals(useWholeNumbers ? 0 : 2)
            }
            
            toTrans.payMethod = transfer.to
            toTrans.category = transfer.category
            toTrans.updatedBy = AppState.shared.user!
                                    
            let transferMonth = date.month
            let transferDay = date.day
            let transferYear = date.year
            
            if transferYear == calModel.sYear || (transferMonth == 1 && transferYear == calModel.sYear + 1) || (transferMonth == 12 && transferYear == calModel.sYear - 1) {
                if let theMonth = calModel.months.filter({ $0.actualNum == transferMonth && $0.year == transferYear }).first {
                    if let theDay = theMonth.days.filter({ $0.dateComponents?.day == transferDay }).first {
                        theDay.upsert(fromTrans)
                        theDay.upsert(toTrans)
                    }
                }
            }
            
            calModel.calculateTotalForMonth(month: calModel.sMonth)
            
            await calModel.submitMultiple(trans: [fromTrans, toTrans], budgets: [], isTransfer: true)
        }
    }
}

