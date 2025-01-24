//
//  TransferSheet.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/24/24.
//

import SwiftUI

struct TransferSheet: View {
    @AppStorage("appColorTheme") var appColorTheme: String = Color.green.description
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    
    @Environment(\.dismiss) var dismiss
    @Environment(CalendarModel.self) private var calModel
    
    @Binding var day: CBDay?
    
    
    init(day: Binding<CBDay?>) {
        self._day = day
    }
    
    init(day: Binding<CBDay>) {
        self._day = Binding(
            get: { day.wrappedValue },
            set: { _ in }
        )
    }
    
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
        VStack {
            SheetHeader(title: title, close: { dismiss() })
                .padding(.bottom, 12)
                .padding(.horizontal, 20)
                .padding(.top)
            Divider()
            
            ScrollView {
                LabeledRow("From", labelWidth) {
                    PaymentMethodSheetButton(payMethod: $transfer.from, whichPaymentMethods: .allExceptUnified)
                }
                
                LabeledRow("To", labelWidth) {
                    PaymentMethodSheetButton(payMethod: $transfer.to, whichPaymentMethods: .allExceptUnified)
                }
                
                Divider()
                
                LabeledRow("Category", labelWidth) {
                    CategorySheetButton(category: $transfer.category)
                }
                
                Divider()
                
                LabeledRow("Amount", labelWidth) {
                    StandardTextField("Amount", text: $transfer.amountString, focusedField: $focusedField, focusValue: 0)
                        .onChange(of: transfer.amountString) { oldValue, newValue in
                            transfer.amountString = transfer.amountString.replacingOccurrences(of: "-", with: "")
                        }
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
                
//                LabeledRow("Date", labelWidth) {
//                    DatePicker(selection: $trans.date ?? Date(), displayedComponents: [.date]) {
//                        EmptyView()
//                    }
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .labelsHidden()
//                }
            }
            .scrollDismissesKeyboard(.immediately)
            .padding()
                        
            Button(action: createTransfer) {
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
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        .task {
            //print(day?.date)
        }
    }
    
    
    func createTransfer() {
        Task {
            dismiss()
            
            let fromTrans = calModel.getTransaction(by: UUID().uuidString, from: .normalList)
            fromTrans.title = "\(transferLingo) to \(transfer.to?.title ?? "N/A")"
            fromTrans.date = day?.date!
                                    
            if transfer.from?.accountType == .credit {
                fromTrans.amountString = (transfer.amount * 1).currencyWithDecimals(useWholeNumbers ? 0 : 2)
            } else {
                fromTrans.amountString = (transfer.amount * -1).currencyWithDecimals(useWholeNumbers ? 0 : 2)
            }
            
            
            fromTrans.payMethod = transfer.from
            fromTrans.category = transfer.category
            fromTrans.updatedBy = AppState.shared.user!
            day?.upsert(fromTrans)
            
           
            let toTrans = calModel.getTransaction(by: UUID().uuidString, from: .normalList)
            toTrans.title = "\(transferLingo) from \(transfer.from?.title ?? "N/A")"
            toTrans.date = day?.date!
            
            if transfer.to?.accountType == .credit {
                toTrans.amountString = (transfer.amount * -1).currencyWithDecimals(useWholeNumbers ? 0 : 2)
            } else {
                toTrans.amountString = (transfer.amount * 1).currencyWithDecimals(useWholeNumbers ? 0 : 2)
            }
            
            toTrans.payMethod = transfer.to
            toTrans.category = transfer.category
            fromTrans.updatedBy = AppState.shared.user!
            day?.upsert(toTrans)
            
            calModel.calculateTotalForMonth(month: calModel.sMonth)
            
            await calModel.submitMultiple(trans: [fromTrans, toTrans], budgets: [], isTransfer: true)
        }
    }
}



struct TransferSheet2: View {
    @AppStorage("appColorTheme") var appColorTheme: String = Color.green.description
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
        VStack {
            SheetHeader(title: title, close: { dismiss() })
                .padding(.bottom, 12)
                .padding(.horizontal, 20)
                .padding(.top)
            Divider()
            
            ScrollView {
                LabeledRow("From", labelWidth) {
                    PaymentMethodSheetButton(payMethod: $transfer.from, whichPaymentMethods: .allExceptUnified)
                }
                
                LabeledRow("To", labelWidth) {
                    PaymentMethodSheetButton(payMethod: $transfer.to, whichPaymentMethods: .allExceptUnified)
                }
                
                Divider()
                
                LabeledRow("Category", labelWidth) {
                    CategorySheetButton(category: $transfer.category)
                }
                
                Divider()
                
                LabeledRow("Amount", labelWidth) {
                    StandardTextField("Amount", text: $transfer.amountString, focusedField: $focusedField, focusValue: 0)
                        .onChange(of: transfer.amountString) { oldValue, newValue in
                            transfer.amountString = transfer.amountString.replacingOccurrences(of: "-", with: "")
                        }
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
                
                Divider()
                
                LabeledRow("Date", labelWidth) {
                    DatePicker(selection: $date, displayedComponents: [.date]) {
                        EmptyView()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .labelsHidden()
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .padding()
                        
            Button(action: createTransfer) {
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
        }
        .onPreferenceChange(MaxSizePreferenceKey.self) { labelWidth = max(labelWidth, $0) }
        .task {
            //print(day?.date)
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

