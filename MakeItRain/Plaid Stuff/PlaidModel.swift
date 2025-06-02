//
//  PlaidModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/22/25.
//

import Foundation
import SwiftUI
#if os(iOS)
import LinkKit
#endif

@Observable
class PlaidModel {
    //var isPresentingLink = false
    var isThinking = false
    
    var isFetchingMoreTransactions = false
    
    var atLeastOneBankHasAnIssue: Bool {
        !banksWithIssues.isEmpty
    }
    
    var banksWithIssues: Array<CBPlaidBank> {
        banks.filter { $0.hasIssues }
    }
    
    
    var banks: Array<CBPlaidBank> = []
    var trans: Array<CBPlaidTransaction> = []
    var balances: Array<CBPlaidBalance> = []
    var fuckYouSwiftuiTableRefreshID: UUID = UUID()
    
    
    
    // MARK: - Bank Stuff
    func doesExist(_ bank: CBPlaidBank) -> Bool {
        return !banks.filter { $0.id == bank.id }.isEmpty
    }
    
    func getBank(by id: String) -> CBPlaidBank? {
        return banks.filter { $0.id == id }.first
    }

    func upsert(_ bank: CBPlaidBank) {
        if !doesExist(bank) {
            banks.append(bank)
        }
    }
    
    func getIndex(for bank: CBPlaidBank) -> Int? {
        return banks.firstIndex(where: { $0.id == bank.id })
    }
    
    func saveBank(id: String) {
        if let bank = getBank(by: id) {
            Task {
                if bank.title.isEmpty {
                    if (bank.action == .edit || bank.action == .delete) && bank.title.isEmpty {
                        bank.title = bank.deepCopy?.title ?? ""
                        AppState.shared.showAlert("Removing a title is not allowed. If you want to delete \(bank.title), please use the delete button instead.")
                    } else {
                        banks.removeAll { $0.id == id }
                    }
                    return
                }
                                    
                if bank.hasChanges() {
                    bank.updatedBy = AppState.shared.user!
                    bank.updatedDate = Date()
                    let _ = await submit(bank)
                }
            }
        }
    }
    
    
    @MainActor
    func fetchBanks() async {
        let model = RequestModel(requestType: "fetch_plaid_banks", model: AppState.shared.user!)
        
        typealias ResultResponse = Result<Array<CBPlaidBank>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            if let model {
                self.banks = model
            }

        case .failure(let error):
            print(error)
            AppState.shared.showAlert("There was a problem trying to fetch plaid banks.")
        }
    }
    
//    @MainActor
//    func fetchAccounts(for bank: CBPlaidBank) async -> Array<CBPlaidAccount>? {
//        let model = RequestModel(requestType: "fetch_plaid_accounts_for_bank", model: bank)
//        
//        typealias ResultResponse = Result<Array<CBPlaidAccount>?, AppError>
//        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
//                    
//        switch await result {
//        case .success(let model):
//            if let model {
//                return model
//            } else {
//                return nil
//            }
//
//        case .failure(let error):
//            print(error)
//            AppState.shared.showAlert("There was a problem trying to fetch plaid accounts.")
//            return nil
//        }
//    }
    
    
    @MainActor
    func submit(_ bank: CBPlaidBank) async -> Bool {
        isThinking = true
        
        let model = RequestModel(requestType: bank.action.serverKey, model: bank)
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        typealias ResultResponse = Result<ReturnIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
        
        
        //print(keyword.action)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            /// Get the new ID from the server after adding a new activity.
            
            isThinking = false
            if bank.action == .delete {
                bank.active = false
            } else {
                bank.action = .edit
            }
            
            #if os(macOS)
            fuckYouSwiftuiTableRefreshID = UUID()
            #endif
            return true
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem syncing the keyword. Will try again at a later time.")
//            keyword.deepCopy(.restore)
//
//            switch keyword.action {
//            case .add: keywords.removeAll { $0.id == keyword.id }
//            case .edit: break
//            case .delete: keywords.append(keyword)
//            }
        }
        
        isThinking = false
        bank.action = .edit
        #if os(macOS)
        fuckYouSwiftuiTableRefreshID = UUID()
        #endif
        return false
    }
    
    
    func delete(_ bank: CBPlaidBank, andSubmit: Bool) async {
        bank.action = .delete
        banks.removeAll { $0.id == bank.id }
                
        bank.accounts.forEach { act in
            trans.removeAll(where: { $0.internalAccountID == act.id })
        }
        
        if andSubmit {
            let _ = await submit(bank)
        }
    }
    
    
    
    
    
    
    
    // MARK: - Account Stuff
    
    @MainActor
    func submit(_ account: CBPlaidAccount) async -> Bool {
        isThinking = true
        
        let model = RequestModel(requestType: account.action.serverKey, model: account)
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        typealias ResultResponse = Result<ReturnIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            /// Get the new ID from the server after adding a new activity.
            
            isThinking = false
            account.action = .edit
            #if os(macOS)
            fuckYouSwiftuiTableRefreshID = UUID()
            #endif
            return true
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem syncing the keyword. Will try again at a later time.")
//            keyword.deepCopy(.restore)
//
//            switch keyword.action {
//            case .add: keywords.removeAll { $0.id == keyword.id }
//            case .edit: break
//            case .delete: keywords.append(keyword)
//            }
        }
        
        isThinking = false
        account.action = .edit
        #if os(macOS)
        fuckYouSwiftuiTableRefreshID = UUID()
        #endif
        return false
    }
    
    
    func delete(_ bank: CBPlaidAccount, andSubmit: Bool) async {
        bank.action = .delete
        banks.removeAll { $0.id == bank.id }
        if andSubmit {
            let _ = await submit(bank)
        }
    }
    
    
    
    
    // MARK: - Plaid Specific Stuff
    @MainActor
    func getTransactions() async -> String? {
        let plaidModel = PlaidServerModel()
        
        let model = RequestModel(requestType: "plaid_get_transactions", model: plaidModel)
        
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            print(model?.result ?? "No transactions")
            return model?.result

        case .failure(let error):
            print(error)
            AppState.shared.showAlert("There was a problem trying to fetch plaid transactions.")
            return nil
        }
    }
    
    @MainActor
    func getAccountsForItem() async -> String? {
        let plaidModel = PlaidServerModel()
        let model = RequestModel(requestType: "plaid_get_accounts_for_item", model: plaidModel)
        
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            print(model?.result ?? "No transactions")
            return model?.result

        case .failure(let error):
            print(error)
            AppState.shared.showAlert("There was a problem trying to fetch plaid accounts.")
            return nil
        }
    }
    
    
    
    
    
    // MARK: - Trans Stuff
    func doesExist(_ tran: CBPlaidTransaction) -> Bool {
        return !trans.filter { $0.id == tran.id }.isEmpty
    }
    
    func upsert(_ tran: CBPlaidTransaction) {
        if !doesExist(tran) {
            trans.append(tran)
        }
    }
    
    func getIndex(for tran: CBPlaidTransaction) -> Int? {
        return trans.firstIndex { $0.id == tran.id }
    }
    
    func delete(_ tran: CBPlaidTransaction) {
        trans.removeAll { $0.id == tran.id }
    }
    
    
    
    @MainActor
    func fetchPlaidTransactionsFromServer(_ plaidModel: PlaidServerModel) async {
        //print("-- \(#function)")
        LogManager.log()
        
        let start = CFAbsoluteTimeGetCurrent()
        
        //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        //print("DONE FETCHING")
                            
        //let month = months.filter { $0.num == monthNum }.first!
        let model = RequestModel(requestType: "fetch_plaid_transactions", model: plaidModel)
        typealias ResultResponse = Result<Array<CBPlaidTransaction>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            if let model {
                for each in model {
                    
                    let index = trans.firstIndex(where: { $0.id == each.id })
                    if let index {
                        /// If the trans is already in the list, update it from the server.
                        trans[index].setFromAnotherInstance(trans: each)
                    } else {
                        /// Add the trans  to the list (like when the trans was added from plaid).
                        trans.append(each)
                    }
                }
                //self.trans = model
                
            }
            
            let currentElapsed = CFAbsoluteTimeGetCurrent() - start
            print("🔴It took \(currentElapsed) seconds to fetch the plaid transaction")
            
        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("calModel fetchPlaidTransactionsFromServer Server Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch fit transactions.")
            }
        }
    }
    
    
    @MainActor
    func denyPlaidTransaction(_ trans: CBPlaidTransaction) async {
        print("-- \(#function)")
        
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        let model = RequestModel(requestType: "deny_plaid_transaction", model: trans)
            
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to deny the plaid transaction.")
            #warning("Undo behavior")
        }
        //LoadingManager.shared.stopDelayedSpinner()
    }
    
    
    @MainActor
    func clearPlaidTransactionBeforeDate(_ trans: CBTransaction) async {
        ///NOTE: Just using a `CBTransaction` since it contains the properties (date) that I need to clear the transactions.
        print("-- \(#function)")
        
        //LoadingManager.shared.startDelayedSpinner()
        LogManager.log()
        let model = RequestModel(requestType: "clear_plaid_transactions", model: trans)
            
        /// Used to test the snapshot data race
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem trying to clear the plaid transaction.")
            #warning("Undo behavior")
        }
        //LoadingManager.shared.stopDelayedSpinner()
    }
    
    
    
    
    // MARK: - Balance Stuff
    func doesExist(_ balance: CBPlaidBalance) -> Bool {
        return !balances.filter { $0.id == balance.id }.isEmpty
    }
    
    func getBalance(by id: String) -> CBPlaidBalance? {
        return balances.filter { $0.id == id }.first
    }

    func upsert(_ balance: CBPlaidBalance) {
        if !doesExist(balance) {
            balances.append(balance)
        }
    }
    
    func getIndex(for balance: CBPlaidBalance) -> Int? {
        return balances.firstIndex(where: { $0.id == balance.id })
    }
    
    func delete(_ balance: CBPlaidBalance) {
        balances.removeAll { $0.id == balance.id }
    }
    
    
    @MainActor
    func fetchPlaidBalancesFromServer() async {
        //print("-- \(#function)")
        LogManager.log()
        
        let start = CFAbsoluteTimeGetCurrent()
        
        //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        //print("DONE FETCHING")
                            
        //let month = months.filter { $0.num == monthNum }.first!
        let model = RequestModel(requestType: "fetch_plaid_balances", model: AppState.shared.user!)
        typealias ResultResponse = Result<Array<CBPlaidBalance>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            if let model {
                self.balances = model
            }
            
            let currentElapsed = CFAbsoluteTimeGetCurrent() - start
            print("🔴It took \(currentElapsed) seconds to fetch the plaid balances")
            
        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("calModel fetchPlaidTransactionsFromServer Server Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch plaid balances.")
            }
        }
    }
    
    
    
    
    
    #if os(iOS)
    // MARK: - Link Stuff
    func createHandler(bank: CBPlaidBank, linkMode: PlaidLinkMode, isPresentingLink: Binding<Bool>) async -> Result<Handler, Plaid.CreateError>? {
        if let configuration = await createLinkTokenConfiguration(bank: bank, linkMode: linkMode, isPresentingLink: isPresentingLink.projectedValue) {
            // This only results in an error if the token is malformed.
            return Plaid.create(configuration)
        }
        return nil
        
    }
    
    var isSettingUpBankOnServer = false

    private func createLinkTokenConfiguration(bank: CBPlaidBank, linkMode: PlaidLinkMode, isPresentingLink: Binding<Bool>) async -> LinkTokenConfiguration? {
        
        let tokenModel = PlaidServerModel(bank: bank, linkMode: linkMode)
        
        
        if let linkToken = await getLinkToken(tokenModel: tokenModel) {
            print("LinkToken: \(linkToken)")
            var linkConfiguration = LinkTokenConfiguration(token: linkToken) { [weak self] success in
                /// Closure is called when a user successfully links an Item. It should take a single LinkSuccess argument,
                /// containing the publicToken String and a metadata of type SuccessMetadata.
                /// Ref - https://plaid.com/docs/link/ios/#onsuccess
                print("public-token: \(success.publicToken) metadata: \(success.metadata)")
                
                
                print("selected Accounts")
                print(success.metadata.accounts)
                
                let institutionID = success.metadata.institution.id
                let model = PlaidServerModel(token: success.publicToken, bank: bank, institutionID: institutionID, linkMode: linkMode)
                Task {
                    self?.isSettingUpBankOnServer = true
                    let result = await self?.exchangePublicToken(model)
                    
                    if result == "bank_already_exists" {
                        AppState.shared.showAlert("This bank account has already been linked.")
                        self?.isSettingUpBankOnServer = false
                        
                    } else if result == "bank_updated" {
                        AppState.shared.showAlert("This bank has been fixed.")
                        self?.isSettingUpBankOnServer = false
                        
                    } else if result == "account_added" {
                        AppState.shared.showAlert("Your new account(s) have been updated.")
                        self?.isSettingUpBankOnServer = false
                        
                    } else {
                        await self?.fetchBanks()
                        self?.isSettingUpBankOnServer = false
                    }
                }
                                
                print("CLOSING")
                isPresentingLink.wrappedValue = false
            }

            /// Optional closure is called when a user exits Link without successfully linking an Item,
            /// or when an error occurs during Link initialization. It should take a single LinkExit argument,
            /// containing an optional error and a metadata of type ExitMetadata.
            /// Ref - https://plaid.com/docs/link/ios/#onexit
            linkConfiguration.onExit = { exit in
                if let error = exit.error {
                    print("exit with \(error)\n\(exit.metadata)")
                } else {
                    // User exited the flow without an error.
                    print("exit with \(exit.metadata)")
                }
                print("CLOSING")
                isPresentingLink.wrappedValue = false
            }

            /// Optional closure is called when certain events in the Plaid Link flow have occurred, for example,
            /// when the user selected an institution. This enables your application to gain further insight into
            /// what is going on as the user goes through the Plaid Link flow.
            /// Ref - https://plaid.com/docs/link/ios/#onevent
            linkConfiguration.onEvent = { event in
                print("LINK EVENT: \(event)")
                print()
            }

            return linkConfiguration
            
        } else {
            return nil
        }
        
    }
    
    
    @MainActor
    func getLinkToken(tokenModel: PlaidServerModel) async -> String? {
        /// Networking
        let model = RequestModel(requestType: "plaid_create_link_token", model: tokenModel)
        
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            print(model?.result ?? "No link token from server")
            return model?.result

        case .failure(let error):
            print(error)
            AppState.shared.showAlert("There was a problem trying to fetch plaid link token.")
            return nil
        }
    }
    
    
    @MainActor
    func exchangePublicToken(_ plaidModel: PlaidServerModel) async -> String? {
        
        let model = RequestModel(requestType: "plaid_exchange_public_token", model: plaidModel)
        
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            print(model?.result ?? "No link token from server")
            return model?.result

        case .failure(let error):
            print(error)
            AppState.shared.showAlert("There was a problem trying to fetch plaid link token.")
            return nil
        }
    }
    
    #endif
}
