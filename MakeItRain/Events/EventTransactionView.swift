//
//  TransactionEditViewBackuo.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/21/25.
//

import Foundation
import SwiftUI
import PhotosUI
import SafariServices
import TipKit


struct FakeTransEditView: View {
    @AppStorage("useWholeNumbers") var useWholeNumbers = false
    
    @Environment(\.dismiss) var dismiss
    
    @Bindable var trans: CBEventTransaction
    @Bindable var event: CBEvent
    var item: CBEventItem?
    
    @State private var showDeleteAlert = false
    @State private var showUserSheet = false
    @State private var showPaymentMethodSheet = false
    @State private var showCategorySheet = false
    @State private var showPaymentMethodMissingAlert = false
    
    @State private var demoTest: String = "Hey there"
    
    @FocusState private var focusedField: Int?
    
    var title: String { trans.action == .add ? "New Transaction" : "Edit Transaction" }
        
    var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Image(systemName: "trash")
        }
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
    }
    
    
    var paymentMethodMissing: Bool {
        return trans.status == XrefModel.getItem(from: .eventTransactionStatuses, byEnumID: .claimed) && trans.payMethod == nil
    }
    
    var header: some View {
        Group {
            SheetHeader(
                title: title,
                close: {
                    if paymentMethodMissing {
                        showPaymentMethodMissingAlert = true
                    } else {
                        dismiss()
                    }
                },
                view3: { deleteButton }
            )
            .padding()
            
            Divider()
                .padding(.horizontal)
        }
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            header
                                    
            List {
                Section("Details") {
                    HStack {
                        Text("Title")
                        Spacer()
                        #if os(iOS)
                        UITextFieldWrapper(placeholder: "Transaction Title", text: $trans.title, toolbar: {
                            KeyboardToolbarView(focusedField: $focusedField)
                        })
                        .uiTag(0)
                        .uiTextAlignment(.right)
                        .uiClearButtonMode(.whileEditing)
                        .uiStartCursorAtEnd(true)
                        #else
                        TextField("Transaction Title", text: $trans.title)
                            .multilineTextAlignment(.trailing)
                        #endif
                    }
                    .focused($focusedField, equals: 0)
                    
                    HStack {
                        Text("Amount")
                        Spacer()
                        
                        Group {
                            #if os(iOS)
                            UITextFieldWrapper(placeholder: "Total", text: $trans.amountString, toolbar: {
                                KeyboardToolbarView(
                                    focusedField: $focusedField,
                                    accessoryImage3: "plus.forwardslash.minus",
                                    accessoryFunc3: {
                                        Helpers.plusMinus($trans.amountString)
                                    })
                            })
                            .uiKeyboardType(useWholeNumbers ? .numberPad : .decimalPad)
                            .uiTag(1)
                            .uiTextAlignment(.right)
                            .uiClearButtonMode(.whileEditing)
                            .uiStartCursorAtEnd(true)
                            #else
                            TextField("Total", text: $trans.amountString)
                                .multilineTextAlignment(.trailing)
                            #endif
                        }
                        .focused($focusedField, equals: 1)
                        .formatCurrencyLiveAndOnUnFocus(
                            focusValue: 1,
                            focusedField: focusedField,
                            amountString: trans.amountString,
                            amountStringBinding: $trans.amountString,
                            amount: trans.amount
                        )
                        
                    }
                                                            
//                    .onChange(of: trans.amountString) {
//                        Helpers.liveFormatCurrency(oldValue: $0, newValue: $1, text: $trans.amountString)
//                    }
//                    .onChange(of: focusedField) {
//                        if let string = Helpers.formatCurrency(focusValue: 1, oldFocus: $0, newFocus: $1, amountString: trans.amountString, amount: trans.amount) {
//                            trans.amountString = string
//                        }
//                    }
//                    
//                    .onChange(of: focusedField) { oldValue, newValue in
//                        if newValue == 1 {
//                            if trans.amount == 0.0 {
//                                trans.amountString = ""
//                            }
//                        } else {
//                            if oldValue == 1 && !trans.amountString.isEmpty {
//                                if trans.amountString == "$" || trans.amountString == "-$" {
//                                    trans.amountString = ""
//                                } else {
//                                    trans.amountString = trans.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
//                                }
//                            }
//                        }
//                    }
                    
                    HStack {
                        Text("Date")
                        Spacer()
                        #if os(iOS)
                        UIKitDatePicker(date: $trans.date, alignment: .trailing) // Have to use because of reformatting issue
                        #else
                        DatePicker("", selection: $trans.date ?? Date(), displayedComponents: [.date])
                            .labelsHidden()
                        #endif
                    }
                }
                
                Section("Section / Category") {
                    HStack {
                        Text("Item")
                        Spacer()
                        
                        Picker(selection: $trans.item) {
                            Section {
                                Text("None")
                                    .tag(nil as CBEventItem?)
                            }
                            Section {
                                ForEach(event.items.filter { $0.active }) { item in
                                    Text(item.title)
                                        .tag(item)
                                }
                            }
                        } label: {
                            Text(trans.item?.title ?? "Select Item")
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                    
                    
                    HStack {
                        Text("Category")
                        Spacer()
                        
                        Picker(selection: $trans.category) {
                            Section {
                                Text("None")
                                    .tag(nil as CBEventCategory?)
                            }
                            Section {
                                ForEach(event.categories.filter { $0.active }) { cat in
                                    Text(cat.title)
                                        .tag(cat)
                                }
                            }
                        } label: {
                            Text(trans.category?.title ?? "Select Item")
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                    
                    
                }
                
                Section {
                    Button(trans.status.enumID == .claimed ? "Put up for grabs" : "Claim transaction") {
                        if trans.status.enumID == .claimed {
                            trans.paidBy = nil
                            trans.payMethod = nil
                            trans.status = XrefModel.getItem(from: .eventTransactionStatuses, byEnumID: .pending)
                            trans.isBeingClaimed = false
                            trans.isBeingUnClaimed = true
                        } else {
                            withAnimation {
                                trans.paidBy = AppState.shared.user!
                                trans.status = XrefModel.getItem(from: .eventTransactionStatuses, byEnumID: .claimed)
                                trans.isBeingClaimed = true
                                trans.isBeingUnClaimed = false
                            }
                        }
                    }
                    
                    
                    if trans.status.enumID == .claimed {
                        HStack {
                            Text("Payment Method")
                            Spacer()
                            Button((trans.payMethod == nil ? "Select" : trans.payMethod?.title) ?? "Select") {
                                showPaymentMethodSheet = true
                            }
                        }
                        .sheet(isPresented: $showPaymentMethodSheet) {
                            PaymentMethodSheet(payMethod: $trans.payMethod, whichPaymentMethods: .allExceptUnified)
                            #if os(macOS)
                                .frame(minWidth: 300, minHeight: 500)
                                .presentationSizing(.fitted)
                            #endif
                        }
                    }
                } header: {
                    Text("Payment")
                } footer: {
                    if let paidBy = trans.paidBy {
                        Text("Paid by \(paidBy.name)")
                    }
                }

                
//                Section("Payee") {
//                    Button(trans.status.enumID == .claimed ? "Put up for grabs" : "Claim transaction") {
//                        if trans.status.enumID == .claimed {
//                            trans.status = XrefModel.getItem(from: .eventTransactionStatuses, byEnumID: .pending)
//                        } else {
//                            trans.status = XrefModel.getItem(from: .eventTransactionStatuses, byEnumID: .claimed)
//                        }
//                        trans.paidBy = AppState.shared.user!
//                    }
//                    
//                    HStack {
//                        Text("Who Paid")
//                        Spacer()
//                        
//                        Button(trans.paidBy?.name ?? "Select Payee") {
//                            showUserSheet = true
//                        }
//                    }
//                    
//                    HStack {
//                        Text("Status")
//                        Spacer()
//                        Menu("\(trans.status.description)") {
//                            ForEach(XrefModel.eventTransactionStatuses) { status in
//                                Button(status.description) {
//                                    trans.status = status
//                                    trans.paidBy = AppState.shared.user!
//                                }
//                            }
//                        }
//                    }
//                    
//                    if trans.status.enumID == .claimed {
//                        HStack {
//                            Text("Payment Method")
//                            Spacer()
//                            Button((trans.realTransaction.payMethod == nil ? "Select" : trans.realTransaction.payMethod?.title) ?? "Select") {
//                                showPaymentMethodSheet = true
//                            }
//                        }
//                        .sheet(isPresented: $showPaymentMethodSheet) {
//                            PaymentMethodSheet(payMethod: $trans.realTransaction.payMethod, whichPaymentMethods: .allExceptUnified)
//                            #if os(macOS)
//                                .frame(minWidth: 300, minHeight: 500)
//                                .presentationSizing(.fitted)
//                            #endif
//                        }
//                        
//                        HStack {
//                            Text("Category")
//                            Spacer()
//                        }
//                    }
//                }
                
                
                
            }
        }
        .interactiveDismissDisabled(paymentMethodMissing)
        .task {
            
            trans.isBeingClaimed = false
            trans.isBeingUnClaimed = false
            
            //print(trans.payMethod)
//            if trans.action == .add {
//                trans.paidBy = AppState.shared.user!
//            }
            
            if trans.date == nil {
                trans.date = Date()
            }
            
            if item != nil {
                trans.item = item
            }
            event.upsert(trans)
            
            if trans.action == .add {
                focusedField = 0
            }
        }
        .confirmationDialog("Delete \"\(trans.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive) {
                dismiss()
                event.deleteTransaction(id: trans.id)
            }
            
            Button("No", role: .cancel) {
                showDeleteAlert = false
            }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(trans.title)\"?\nThis will not delete any associated transactions.")
            #else
            Text("This will not delete any associated transactions.")
            #endif
        })
        .sheet(isPresented: $showUserSheet) {
            UserSheet(selectedUser: $trans.paidBy, availableUsers: event.participants.map { $0.user })
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        }
        .onChange(of: trans.paidBy) { oldValue, newValue in
            if let newValue {
                if !AppState.shared.user(is: newValue) {
                    dismiss()
                }
            }
        }
        .alert("Payment Method Missing", isPresented: $showPaymentMethodMissingAlert) {
            Button("OK") {}
        }
    }
}
