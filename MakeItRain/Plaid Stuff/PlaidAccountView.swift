//
//  PlaidAccountView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/28/25.
//

import SwiftUI

#if os(iOS)
struct PlaidAccountView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(PlaidModel.self) private var plaidModel
    @Environment(PayMethodModel.self) private var payModel
    
    @Bindable var account: CBPlaidAccount
    @Bindable var bank: CBPlaidBank
    
    /// This is only here to blank out the selection hilight on the iPhone list
    @Binding var editID: String?
        
    @State private var showDeleteAlert = false
    @State private var labelWidth: CGFloat = 20.0
    
    @FocusState private var focusedField: Int?
    
    @State private var resultingPayMethod: CBPaymentMethod?
    
    @State private var showPayMethodSheet = false

    
    var body: some View {
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                titleRow
                
                if account.paymentMethodID == nil {
                    Section {
                        Button("Link to Make It Rain") {
                            showPayMethodSheet = true
                        }
                    } footer: {
                        Text("In order to see transactions from this plaid account, please link it with a Make It Rain account.")
                    }
                } else {
                    if let payMethod = payModel.paymentMethods.filter({ $0.id == account.paymentMethodID! }).first {
                        Section {
                            HStack {
                                Circle()
                                    .fill(payMethod.color)
                                    .frame(width: 12, height: 12)
                                Text("\(payMethod.title)")
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showPayMethodSheet = true
                            }
                            
                            Button("Unlink") {
                                account.paymentMethodID = nil
                                plaidModel.trans.removeAll(where: { $0.payMethod?.id == payMethod.id })
                                
                                Task {
                                    await plaidModel.submit(account)
                                }
                            }
                            .tint(.red)
                        } header: {
                            Text("Make It Rain Account")
                        } footer: {
                            Text("If you unlink this account, you will no longer receive transactions from it.")
                        }
                    }
                }
                
            }
            .navigationTitle(account.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { deleteButton }
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
        }
        .task { await prepareView() }
        .sheet(isPresented: $showPayMethodSheet) {
            if let resultingPayMethod = resultingPayMethod {
                account.paymentMethodID = resultingPayMethod.id
                Task {
                    await plaidModel.submit(account)
                }
            }
            
            resultingPayMethod = nil
        } content: {
            PayMethodSheet(payMethod: $resultingPayMethod, whichPaymentMethods: .remainingAvailbleForPlaid)
        }
    }
    
    
    var titleRow: some View {
        HStack(spacing: 0) {
            Label {
                Text("")
            } icon: {
                Image(systemName: "t.circle")
                    .foregroundStyle(.gray)
            }
            Group {
                #if os(iOS)
                UITextFieldWrapper(placeholder: "Name", text: $account.title, toolbar: {
                    KeyboardToolbarView(focusedField: $focusedField)
                })
                .uiTag(0)
                .uiClearButtonMode(.whileEditing)
                .uiStartCursorAtEnd(true)
                .uiTextAlignment(.left)
                //.uiFont(UIFont.systemFont(ofSize: 24.0))
                
                //            StandardUITextField("Name", text: $bank.title, toolbar: {
                //                KeyboardToolbarView(focusedField: $focusedField)
                //            })
                //            .cbFocused(_focusedField, equals: 0)
                //            .cbClearButtonMode(.whileEditing)
                #else
                StandardTextField("Name", text: $bank.title, focusedField: $focusedField, focusValue: 0)
                #endif
            }
            .focused($focusedField, equals: 0)
        }
            
        
    }
    
    
//    var header: some View {
//        SheetHeader(
//            title: account.title,
//            close: { editID = nil; dismiss() },
//            view3: { deleteButton }
//        )
//    }
    
    
    var closeButton: some View {
        Button {
            editID = nil; dismiss()
        } label: {
            Image(systemName: "xmark")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
        .buttonStyle(.glassProminent)
    }
    
    
    var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Image(systemName: "trash")
        }
        .sensoryFeedback(.warning, trigger: showDeleteAlert) { !$0 && $1 }
        .tint(.none)
        .confirmationDialog("Delete \"\(account.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive, action: deleteAccount)
//            Button("No", role: .cancel) { showDeleteAlert = false }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(account.title)\"?\nThis will also delete all associated transactions.")
            #else
            Text("This will also delete all associated transactions.")
            #endif
        })
    }
    
    // MARK: - Functions
    func prepareView() async {
        account.deepCopy(.create)
        //focusedField = 0
        
//        if let accounts = await plaidModel.fetchAccounts(for: bank) {
//            self.accounts = accounts
//        }
        
        //await viewModel.fetchHistory(for: payMethod, payModel: payModel, setChartAsNew: true)
        
    }
    
    
    func deleteAccount() {
        bank.deleteAccount(id: account.id)
        dismiss()
    }
}
#endif
