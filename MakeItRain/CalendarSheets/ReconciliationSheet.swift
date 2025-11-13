////
////  ReconciliationSheet.swift
////  MakeItRain
////
////  Created by Cody Burnett on 10/8/25.
////
//
//import SwiftUI
//
//struct ReconciliationSheet: View {
//    //@Local(\.colorTheme) var colorTheme
//    @Local(\.useWholeNumbers) var useWholeNumbers
//    @Environment(\.colorScheme) var colorScheme
//    @Environment(\.dismiss) var dismiss
//    @Environment(CalendarModel.self) private var calModel
//    @Environment(CategoryModel.self) private var catModel
//    
//    @State var date: Date
//    
//    @State private var account: CBPaymentMethod?
//    @State private var amountString: String = ""
//    var amount: Double {
//        Double(amountString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0
//    }
//        
//    @FocusState private var focusedField: Int?
//
//    var isValidToSave: Bool {
//        (account != nil && amount != 0.0)
//    }
//    
//    var body: some View {
//        NavigationStack {
//            #if os(iOS)
//            bodyPhone
//                .navigationTitle("New Reconciliation")
//                .navigationBarTitleDisplayMode(.inline)
//                .toolbar {
//                    ToolbarItem(placement: .topBarTrailing) {
//                        if isValidToSave {
//                            closeButton
//                                #if os(iOS)
//                                .buttonStyle(.glassProminent)
//                                #endif
//                        } else {
//                            closeButton
//                                
//                        }
//                    }
//                }
//            #else
//            bodyMac
//            #endif
//        }
//        .task {
//            
//        }
//    }
//    
//    
//    var bodyPhone: some View {
//        StandardContainerWithToolbar(.list) {
//            Section {
//                accountRow
//                amountRowPhone
//                DatePicker("Date", selection: $date, displayedComponents: [.date])
//                    .frame(maxWidth: .infinity, alignment: .leading)
//            }
//                        
//            transferButtonPhone
//        }
//    }
//    
//    var accountRow: some View {
//        HStack {
//            Text("From")
//            Spacer()
//            //PayMethodSheetButton2(payMethod: $account, whichPaymentMethods: .allExceptUnified)
//        }
//    }
//    
//        
//    var amountRowPhone: some View {
//        HStack {
//            Text("Amount")
//            Spacer()
//            
//            Group {
//                #if os(iOS)
//                UITextFieldWrapper(placeholder: "Amount", text: $amountString, toolbar: {
//                    KeyboardToolbarView(focusedField: $focusedField, removeNavButtons: true)
//                })
//                .uiTag(1)
//                .uiClearButtonMode(.whileEditing)
//                .uiStartCursorAtEnd(true)
//                .uiTextAlignment(.right)
//                .uiKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
//                .uiTextColor(.secondaryLabel)
//                .uiTextAlignment(.right)
//                #else
//                StandardTextField("Amount", text: $transfer.amountString, focusedField: $focusedField, focusValue: 1)
//                #endif
//            }
//            .focused($focusedField, equals: 1)
//            .formatCurrencyLiveAndOnUnFocus(
//                focusValue: 1,
//                focusedField: focusedField,
//                amountString: amountString,
//                amountStringBinding: $amountString,
//                amount: amount
//            )
//        }
//        .validate(amountString, rules: .regex(.positiveCurrency, "The entered amount must be positive currency"))
//    }
//    
//    
//    var transferButtonPhone: some View {
//        Button(action: validateForm) {
//            Text("Create Reconciliation")
//        }
//        .foregroundStyle(Color.theme)
//        .disabled(!isValidToSave)
//    }
//        
//    
//    var closeButton: some View {
//        Button {
//            dismiss()
//        } label: {
//            Image(systemName: isValidToSave ? "checkmark" : "xmark")
//                .schemeBasedForegroundStyle()
//        }
//    }
//
//
//    
//    func validateForm() {
//        if account == nil {
//            AppState.shared.showAlert("From must be filled out")
//            return
//            
//        } else if amount == 0.0 {
//            AppState.shared.showAlert("You must enter a dollar amount")
//            return
//            
//        } else {
//            createTransfer()
//        }
//    }
//    
//    
//    func createTransfer() {
//        Task {
//            dismiss()
//            
//            let trans = calModel.getTransaction(by: UUID().uuidString, from: .normalList)
//            trans.title = "Reconciliation"
//            trans.date = date
//                                    
//            if account?.accountType == .credit || account?.accountType == .loan {
//                trans.amountString = (amount * 1).currencyWithDecimals(useWholeNumbers ? 0 : 2)
//            } else {
//                trans.amountString = (amount * -1).currencyWithDecimals(useWholeNumbers ? 0 : 2)
//            }
//            
//            trans.payMethod = account
//            trans.updatedBy = AppState.shared.user!
//            trans.updatedDate = Date()
//                                                                                                
//            let transferMonth = date.month
//            let transferDay = date.day
//            let transferYear = date.year
//            
//            if transferYear == calModel.sYear || (transferMonth == 1 && transferYear == calModel.sYear + 1) || (transferMonth == 12 && transferYear == calModel.sYear - 1) {
//                if let theMonth = calModel.months.filter({ $0.actualNum == transferMonth && $0.year == transferYear }).first {
//                    if let theDay = theMonth.days.filter({ $0.dateComponents?.day == transferDay }).first {
//                        theDay.upsert(trans)
//                    }
//                }
//            }
//            
//            let _ = calModel.calculateTotal(for: calModel.sMonth)
//            
//            await calModel.addMultiple(trans: [trans], budgets: [], isTransfer: true)
//        }
//    }
//}
//
