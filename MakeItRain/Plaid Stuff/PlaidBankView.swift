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
    
    var isValidToSave: Bool {
        bank.hasChanges() && !bank.title.isEmpty
    }
    
    var body: some View {
        let _ = Self._printChanges()
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
                        forceSyncBalanceButton
                        forceSyncTransactionsButtons
                    } footer: {
                        lastSyncInfoFooter
                    }
                }
                
                Section {
                    fetchAvailableHistoryButton
                } footer: {
                    Text("Fetch all the transactions that plaid has previously synced for you. This will allow you to accept or reject transactions that you may have missed in the past. (This will only go back aproximately 2 years max.)")
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
                ToolbarItem(placement: .topBarLeading) { if AppState.shared.user?.id == 1 { infoButton } }
                ToolbarItem(placement: .topBarTrailing) {
                    AnimatedCloseButton(isValidToSave: isValidToSave, closeButton: closeButton)
                }
            }
        }
        
        .task { await prepareView() }
        .onChange(of: editAccountID) { updateAccountInfo(oldValue: $0, newValue: $1) }
        .sheet(item: $editAccount, onDismiss: {
            editAccountID = nil
        }) { account in
            PlaidAccountView(account: account, bank: bank, editID: $editAccountID)
            #if os(macOS)
                .frame(minWidth: 300, minHeight: 500)
                .presentationSizing(.fitted)
            #endif
        }
        .sheet(isPresented: $showInfoSheet) {
            PlaidSyncInfoSheet()
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
    
    
    // MARK: - Account Section
    var accountSection: some View {
        Section("Accounts") {
            ForEach(bank.accounts) { account in
                VStack {
                    HStack(alignment: .circleAndTitle) {
                        if account.paymentMethodID == nil {
                            linkRequiredSymbol
                        }
                        
                        VStack(alignment: .leading) {
                            accountTitle(for: account)
                            
                            if account.paymentMethodID == nil {
                                linkRequiredMessage
                            } else {
                                makeItRainLinkedAccount(for: account)
                            }
                        }
                                                
                        Spacer()
                        
                        accountType(for: account)
                    }
                    
                    currentBalance(for: account)
                }
                
                .contentShape(Rectangle())
                .onTapGesture {
                    editAccountID = account.id
                }
            }
        }
    }
        
    
    var linkRequiredSymbol: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .foregroundStyle(.orange)
            .alignmentGuide(.circleAndTitle) { $0[VerticalAlignment.center] }
    }
    
    
    var linkRequiredMessage: some View {
        Text("Please link this account with a Make It Rain account.")
            .foregroundStyle(.secondary)
            .font(.caption)
    }
    
    
    func accountType(for account: CBPlaidAccount) -> some View {
        Text(account.accountType?.capitalized ?? "Unknown Account Type")
            .alignmentGuide(.circleAndTitle) { $0[VerticalAlignment.center] }
    }
    
    
    @ViewBuilder
    func accountTitle(for account: CBPlaidAccount) -> some View {
        Text(account.title)
            .alignmentGuide(.circleAndTitle) { $0[VerticalAlignment.center] }
    }
    
    
    @ViewBuilder
    func makeItRainLinkedAccount(for account: CBPlaidAccount) -> some View {
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
    }
           
    
    @ViewBuilder
    func currentBalance(for account: CBPlaidAccount) -> some View {
        if let balance = plaidModel.balances.filter({ $0.payMethodID == account.paymentMethodID }).first {
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
    
    
    
    // MARK: - Cody Buttons
    var forceSyncBalanceButton: some View {
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
    }
    
    
    var forceSyncTransactionsButtons: some View {
        Button {
            isForceSyncingTransactions = true
            Task {
                await plaidModel.forceSyncTransactions(for: bank)
                isForceSyncingTransactions = false
            }
        } label: {
            if isForceSyncingTransactions {
                ProgressView()
            } else {
                Text("Force sync transactions")
            }
        }
        .disabled(isForceSyncingTransactions)
    }
    
    var fetchAvailableHistoryButton: some View {
        Button {
            Task {
                AppState.shared.showAlert(title: "History Request Initiated", subtitle: "Depending on how much history there is, this may take a few minutes.")
                plaidModel.trans.removeAll()
                await plaidModel.fetchAllAvailableTransactionHistory(for: bank)
            }
        } label: {
            Text("Fetch all available history")
        }
    }
    
    
    var lastSyncInfoFooter: some View {
        VStack(alignment: .leading) {
            Text("Last Plaid To Bank Sync: \(bank.lastTimePlaidSyncedWithInstitutionDate?.string(to: .monthDayHrMinAmPm) ?? "N/A")")
            
            Text("Last Cody Sync: \(bank.lastTimeICheckedPlaidSyncedDate?.string(to: .monthDayHrMinAmPm) ?? "N/A")")
        }
    }
    
    
    
    // MARK: - Toolbar Buttons
    var closeButton: some View {
        Button {
            editID = nil; dismiss()
        } label: {
            Image(systemName: isValidToSave ? "checkmark" : "xmark")
                .schemeBasedForegroundStyle()
        }
        //.buttonStyle(.glass)
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
            Button("No", role: .close) { showDeleteAlert = false }
        }, message: {
            #if os(iOS)
            Text("Delete \"\(bank.title)\"?\n\nThis will remove plaids link to this bank.\nYou can re-add \(bank.title) again in the future.\n\nNOTE: Some banks, such as Chase and Wells Fargo, require you to remove the plaid integration via your security preferences on their website.")
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
                .schemeBasedForegroundStyle()
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
    
    
    func updateAccountInfo(oldValue: String?, newValue: String?) {
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
    
    
    func deleteBank() {
        //Task {
            bank.action = .delete
            dismiss()
            //await plaidModel.delete(bank, andSubmit: true)
        //}
    }
}
#endif
