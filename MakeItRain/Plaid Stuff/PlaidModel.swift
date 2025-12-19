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
    
    var totalTransCount = 0
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
        guard let bank = getBank(by: id) else { return }
            
        if bank.action == .delete {
            bank.updatedBy = AppState.shared.user!
            bank.updatedDate = Date()
            delete(bank, andSubmit: true)
            return
        }
        
        if bank.title.isEmpty {
            /// User blanked out the title of an existing transaction.
            if bank.action == .edit {
                bank.title = bank.deepCopy?.title ?? ""
                AppState.shared.showAlert("Removing a title is not allowed. If you want to delete \(bank.title), please use the delete button instead.")
            } else {
                /// Remove the dud that is in `.add` mode since it's being upserted into the list on creation.
                withAnimation { banks.removeAll { $0.id == id } }
            }
            return
        }
                            
        if bank.hasChanges() {
            bank.updatedBy = AppState.shared.user!
            bank.updatedDate = Date()
            Task {
                let _ = await submit(bank)
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
        
        let id = bank.id
        let logo = bank.logo
        //print(keyword.action)
        
        let context = DataManager.shared.createContext()
        await context.perform {
            let pred1 = NSPredicate(format: "relatedID == %@", id)
            let pred2 = NSPredicate(format: "relatedTypeID == %@", NSNumber(value: XrefModel.getItem(from: .logoTypes, byEnumID: .plaidBank).id))
            let comp = NSCompoundPredicate(andPredicateWithSubpredicates: [pred1, pred2])
            
            if let perLogo = DataManager.shared.getOne(
                context: context,
                type: PersistentLogo.self,
                predicate: .compound(comp),
                createIfNotFound: true
            ) {
                perLogo.id = UUID().uuidString
                perLogo.relatedID = id
                perLogo.relatedTypeID = Int64(XrefModel.getItem(from: .logoTypes, byEnumID: .plaidBank).id)
                perLogo.photoData = logo
                perLogo.localUpdatedDate = Date()
            }
            
            let _ = DataManager.shared.save(context: context)
        }
        
        
        typealias ResultResponse = Result<ReturnIdModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
                    
        switch await result {
        case .success(let model):
            LogManager.networkingSuccessful()
            
            isThinking = false
            if bank.action == .delete {
                if model?.uuid == "problem_removing_bank_from_plaid_api" {
                    AppState.shared.showAlert("There was a problem communicating with the plaid API.")
                } else {
                    bank.active = false
                }
            } else {
                bank.action = .edit
            }
            
            #if os(macOS)
            fuckYouSwiftuiTableRefreshID = UUID()
            #endif
            return true
            
        case .failure(let error):
            LogManager.error(error.localizedDescription)
            AppState.shared.showAlert("There was a problem syncing the bank. Will try again at a later time.")
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
    
    
    func delete(_ bank: CBPlaidBank, andSubmit: Bool) {
        bank.action = .delete
//        /// Remove the banks from the plaid model
//        banks.removeAll { $0.id == bank.id }
                
        bank.accounts.forEach { act in
            act.active = false
            /// Remove all the plaid transactions associated with account from the bank.
            trans.removeAll { $0.internalAccountID == act.id }
            /// Remove the balance associated with the account.
            balances.removeAll { $0.payMethodID == act.paymentMethodID }
        }
        
        if andSubmit {
            Task { @MainActor in
                let _ = await submit(bank)
            }
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
        case .success:
            LogManager.networkingSuccessful()
            
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
    
    
//    func delete(_ account: CBPlaidAccount, andSubmit: Bool) {
//        account.action = .delete
//        if let bank = banks.filter({ $0.id == account.bankID }).first {
//            withAnimation { bank.accounts.removeAll { $0.id == account.id } }
//            
//            if andSubmit {
//                Task { @MainActor in
//                    let _ = await submit(account)
//                }
//            }
//        }
//    }
    
    
    
    
    // MARK: - Plaid Specific Stuff
    @MainActor
    func getTransactions() async -> String? {
        let plaidModel = PlaidServerModel()
        
        //try? await Task.sleep(nanoseconds: UInt64(6 * Double(NSEC_PER_SEC)))
        
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
    func fetchPlaidTransactionsFromServer(_ plaidModel: PlaidServerModel, accumulate: Bool) async {
        //print("-- \(#function)")
        LogManager.log()
        
        let start = CFAbsoluteTimeGetCurrent()
        
        //try? await Task.sleep(nanoseconds: UInt64(5 * Double(NSEC_PER_SEC)))
        //print("DONE FETCHING")
                            
        //let month = months.filter { $0.num == monthNum }.first!
        let model = RequestModel(requestType: "fetch_plaid_transactions", model: plaidModel)
        typealias ResultResponse = Result<CBPlaidTransactionListWithCount?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            if let model, let trans = model.trans {
                if !trans.isEmpty {
                    
                    totalTransCount = model.count
                    
                    var activeIds: Array<Int> = []
                    
                    for each in trans {
                        //print(each.title)
                        activeIds.append(each.id)
                        let index = self.trans.firstIndex(where: { $0.id == each.id })
                        if let index {
                            /// If the trans is already in the list, update it from the server.
                            self.trans[index].setFromAnotherInstance(trans: each)
                        } else {
                            withAnimation {
                                /// Add the trans  to the list (like when the trans was added from plaid).
                                self.trans.append(each)
                            }
                            
                        }
                    }
                    
                    if !accumulate {
                        /// Delete from model.
                        for tran in self.trans {
                            if !activeIds.contains(tran.id) {
                                withAnimation {
                                    self.trans.removeAll { $0.id == tran.id }
                                }
                            }
                        }
                    }
                    
                } else {
                    print("model.trans is empty")
                    if !accumulate {
                        withAnimation {
                            self.trans.removeAll()
                        }
                    }
                }
            } else {
                print("Model was nil or model.trans was nil")
            }
            
            let currentElapsed = CFAbsoluteTimeGetCurrent() - start
            print("⏰It took \(currentElapsed) seconds to fetch the plaid transactions")
            
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
        case .success:
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
        case .success:
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
        return !balances.filter { $0.payMethodID == balance.payMethodID && $0.internalAccountID == balance.internalAccountID }.isEmpty
    }
    
//    func getBalance(by id: String) -> CBPlaidBalance? {
//        return balances.filter { $0.id == id }.first
//    }

    func upsert(_ balance: CBPlaidBalance) {
        if !doesExist(balance) {
            balances.append(balance)
        }
    }
    
    func getIndex(for balance: CBPlaidBalance) -> Int? {
        return balances.firstIndex(where: { $0.payMethodID == balance.payMethodID && $0.internalAccountID == balance.internalAccountID })
    }
    
    func delete(_ balance: CBPlaidBalance) {
        balances.removeAll { $0.payMethodID == balance.payMethodID && $0.internalAccountID == balance.internalAccountID }
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
            print("⏰It took \(currentElapsed) seconds to fetch the plaid balances")
            
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
    
    
    
    @MainActor
    func forceSyncBalance(for bank: CBPlaidBank) async {
        //print("-- \(#function)")
        LogManager.log()
        
        let start = CFAbsoluteTimeGetCurrent()
        
        //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        //print("DONE FETCHING")
        
        let plaidModel = PlaidServerModel(bank: bank)
                            
        //let month = months.filter { $0.num == monthNum }.first!
        let model = RequestModel(requestType: "plaid_force_sync_balances_for_bank", model: plaidModel)
        typealias ResultResponse = Result<Array<CBPlaidBalance>?, AppError>
        async let result: ResultResponse = await NetworkManager().arrayRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            if let model {
                for balance in model {
                    let index = balances.firstIndex(where: { $0.internalAccountID == balance.internalAccountID })
                    if let index {
                        /// If the balance is already in the list, update it from the server.
                        balances[index].setFromAnotherInstance(bal: balance)
                    } else {
                        /// Add the balance to the list (like when the balance was added on another device).
                        balances.append(balance)
                    }
                }
            }
            
            let currentElapsed = CFAbsoluteTimeGetCurrent() - start
            print("⏰It took \(currentElapsed) seconds to force sync plaid balances for bankID \(bank.id).")
            
        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("calModel forceSyncBalance Server Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to force sync plaid balances for bankID \(bank.id).")
            }
        }
    }
    
    
    
    @MainActor
    func forceSyncTransactions(for bank: CBPlaidBank) async {
        //print("-- \(#function)")
        LogManager.log()
        
        let start = CFAbsoluteTimeGetCurrent()
        
        //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        //print("DONE FETCHING")
        
        let plaidModel = PlaidServerModel(bank: bank)
                            
        //let month = months.filter { $0.num == monthNum }.first!
        let model = RequestModel(requestType: "plaid_force_sync_transactions_for_bank", model: plaidModel)
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            let currentElapsed = CFAbsoluteTimeGetCurrent() - start
            print("⏰It took \(currentElapsed) seconds to force sync plaid transactions for bankID \(bank.id).")
            
            AppState.shared.showAlert(title: "\(bank.title) Sync Initiated", subtitle: "You will be notified when new transactions are available")
            
        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("calModel forceSyncBalance Server Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to force sync plaid transactions for bankID \(bank.id).")
            }
        }
    }
    
    
    
    @MainActor
    func fetchAllAvailableTransactionHistory(for bank: CBPlaidBank) async {
        //print("-- \(#function)")
        LogManager.log()
        
        let start = CFAbsoluteTimeGetCurrent()
        
        //try? await Task.sleep(nanoseconds: UInt64(10 * Double(NSEC_PER_SEC)))
        //print("DONE FETCHING")
        
        let plaidModel = PlaidServerModel(bank: bank)
                            
        //let month = months.filter { $0.num == monthNum }.first!
        let model = RequestModel(requestType: "plaid_fetch_all_available_transaction_history_for_bank", model: plaidModel)
        typealias ResultResponse = Result<ResultCompleteModel?, AppError>
        async let result: ResultResponse = await NetworkManager().singleRequest(requestModel: model)
        
        switch await result {
        case .success(let model):
            let currentElapsed = CFAbsoluteTimeGetCurrent() - start
            print("⏰It took \(currentElapsed) seconds to fetch all available plaid transaction history for bankID \(bank.id).")
            
        case .failure (let error):
            switch error {
            case .taskCancelled:
                /// Task get cancelled when switching years. So only show the alert if the error is not related to the task being cancelled.
                print("calModel forceSyncBalance Server Task Cancelled")
            default:
                LogManager.error(error.localizedDescription)
                AppState.shared.showAlert("There was a problem trying to fetch all available plaid transaction history for bankID \(bank.id).")
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
