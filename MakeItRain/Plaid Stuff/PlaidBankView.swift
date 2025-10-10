//
//  PlaidBankView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/22/25.
//


import SwiftUI

#if os(iOS)
struct PlaidBankView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(PlaidModel.self) private var plaidModel
    @Environment(PayMethodModel.self) private var payModel
    @Local(\.useWholeNumbers) var useWholeNumbers
    
    @Bindable var bank: CBPlaidBank
    
    /// This is only here to blank out the selection hilight on the iPhone list
    @Binding var editID: String?
        
    @State private var showDeleteAlert = false
    @State private var labelWidth: CGFloat = 20.0
    
    @FocusState private var focusedField: Int?
    
    @State private var editAccount: CBPlaidAccount?
    @State private var editAccountID: String?
    @State private var showInfoSheet = false
    
    @State private var isForceSyncingBalances = false
    @State private var isForceSyncingTransactions = false
    @State private var showForceSyncTransactionsInitiatedAlert = false
    
    var body: some View {
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                titleRow
                accountSection
                
                if bank.requiresUpdate {
                    Section {
                        PlaidLinkView(plaidModel: plaidModel, linkMode: .updateBank, bank: bank)
                    } footer: {
                        Text("\(bank.title) is requesting an update. This could be due to a changed password, or some other related reason.")
                    }
                }
                
                
                if AppState.shared.user?.id == 1 {
                    Section {
                        Button {
                            isForceSyncingBalances = true
                            Task {
                                await plaidModel.forceSyncBalance(for: bank)
                                isForceSyncingBalances = false
                            }
                        } label: {
                            if isForceSyncingBalances {
                                ProgressView()
                            } else {
                                Text("Force sync balances")
                            }
                        }
                        .disabled(isForceSyncingBalances)
                        
                        
                        Button {
                            isForceSyncingTransactions = true
                            Task {
                                await plaidModel.forceSyncTransactions(for: bank)
                                isForceSyncingTransactions = false
                                showForceSyncTransactionsInitiatedAlert = true
                            }
                        } label: {
                            if isForceSyncingTransactions {
                                ProgressView()
                            } else {
                                Text("Force sync transactions")
                            }
                        }
                        .disabled(isForceSyncingTransactions)
                        
                    } footer: {
                        VStack(alignment: .leading) {
                            Text("Last Plaid To Bank Sync: \(bank.lastTimePlaidSyncedWithInstitutionDate?.string(to: .monthDayHrMinAmPm) ?? "N/A")")
                            
                            Text("Last Cody Sync: \(bank.lastTimeICheckedPlaidSyncedDate?.string(to: .monthDayHrMinAmPm) ?? "N/A")")
                        }
                    }
                }
                
                Section {
                    PlaidLinkView(plaidModel: plaidModel, linkMode: .addAccount, bank: bank)
                } footer: {
                    Text("Revise your linked accounts from \(bank.title). Note, you must select all accounts you wish to have linked. Even if you have already linked them.")
                }
            }
            .navigationTitle("Plaid Bank")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { deleteButton }
                ToolbarSpacer(.fixed, placement: .topBarLeading)
                ToolbarItem(placement: .topBarLeading) {
                    if AppState.shared.user?.id == 1 {
                        infoButton
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            
            .alert("Sync Initiated", isPresented: $showForceSyncTransactionsInitiatedAlert, actions: {
                Button("OK") {}
            }, message: {
                Text("You will be notified when new transactions are available")
            })
        }
        
        .task { await prepareView() }
        .onChange(of: editAccountID) { oldValue, newValue in
            if let newValue {
                editAccount = bank.getAccount(by: newValue)
            } else {
                if let account = bank.getAccount(by: oldValue!) {
                    if bank.saveAccount(id: oldValue!) {
                        account.updatedDate = Date()
                        Task {
                            let _ = await plaidModel.submit(account)
                        }
                    }
                }
            }
        }
        .sheet(item: $editAccount, onDismiss: {
            editAccountID = nil
        }, content: { account in
            PlaidAccountView(account: account, bank: bank, editID: $editAccountID)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        })
        .sheet(isPresented: $showInfoSheet) {
            PlaidSyncInfoSheet()
        }
        
    }
    
    
    var accountSection: some View {
        Section("Accounts") {
            ForEach(bank.accounts) { account in
                HStack(alignment: .circleAndTitle) {
                    if account.paymentMethodID == nil {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .alignmentGuide(.circleAndTitle) { $0[VerticalAlignment.center] }
                    }
                    
                    VStack(alignment: .leading) {
                        Text(account.title)
                            .alignmentGuide(.circleAndTitle) { $0[VerticalAlignment.center] }
                        
                        if account.paymentMethodID == nil {
                            Text("Please link this account with a Make It Rain account.")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        } else {
                            if let payMethod = payModel.paymentMethods.filter({ $0.id == account.paymentMethodID! }).first {
                                HStack {
                                    Circle()
                                        .fill(payMethod.color)
                                        .frame(width: 12, height: 12)
                                    Text("\(payMethod.title)")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                            }
                            
                            
                            if let balance = plaidModel.balances.filter({ $0.payMethodID == account.paymentMethodID! }).first {
                                HStack {
                                    //Text("Balance as of \(balance.lastTimeICheckedPlaidSyncedDate?.string(to: .monthDayYearHrMinAmPm) ?? "N/A"):")
                                    Text("Balance as of \(balance.enteredDate?.string(to: .monthDayYearHrMinAmPm) ?? "N/A"):")
                                    
                                    Spacer()
                                    
                                    Text(balance.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2))
                                }
                                .foregroundStyle(.gray)
                                .font(.caption)
                            }
                        }
                    }
                                            
                    Spacer()
                    Text(account.accountType ?? "N/A")
                        .alignmentGuide(.circleAndTitle) { $0[VerticalAlignment.center] }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    editAccountID = account.id
                }
            }
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
                UITextFieldWrapper(placeholder: "Title", text: $bank.title, toolbar: {
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
    
//    
//    var header: some View {
//        SheetHeader(
//            title: "Plaid Bank",
//            close: { editID = nil; dismiss() },
//            view3: { deleteButton }
//        )
//    }
    
    
    var closeButton: some View {
        Button {
            editID = nil; dismiss()
        } label: {
            Image(systemName: "checkmark")
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
        .confirmationDialog("Delete \"\(bank.title)\"?", isPresented: $showDeleteAlert, actions: {
            Button("Yes", role: .destructive, action: deleteBank)
            //Button("No", role: .cancel) { showDeleteAlert = false }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(bank.title)\"?\nThis will also delete all associated transactions.")
            #else
            Text("This will also delete all associated transactions.")
            #endif
        })
    }
    
    var infoButton: some View {
        Button {
            showInfoSheet = true
        } label: {
            Image(systemName: "info")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }
    
    
    // MARK: - Functions
    func prepareView() async {
        bank.deepCopy(.create)
        //focusedField = 0
        
//        if let accounts = await plaidModel.fetchAccounts(for: bank) {
//            self.accounts = accounts
//        }
        
        //await viewModel.fetchHistory(for: payMethod, payModel: payModel, setChartAsNew: true)
        
    }
    
    
    func deleteBank() {
        Task {
            dismiss()
            await plaidModel.delete(bank, andSubmit: true)
        }
    }
}
#endif
