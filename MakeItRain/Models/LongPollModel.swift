//
//  LongPollModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/4/24.
//

import Foundation
#if os(iOS)
import UIKit
#endif

class LongPollModel: Decodable {
    let returnTime: Int?
    
    let transactions: Array<CBTransaction>?
    let startingAmounts: Array<CBStartingAmount>?
    let repeatingTransactions: Array<CBRepeatingTransaction>?
    let payMethods: Array<CBPaymentMethod>?
    let categories: Array<CBCategory>?
    let categoryGroups: Array<CBCategoryGroup>?
    let keywords: Array<CBKeyword>?
    let budgets: Array<CBBudget>?
    
    let fitTransactions: Array<CBFitTransaction>?
    let openRecords: Array<CBOpenOrClosedRecord>?
    
    let plaidBanks: Array<CBPlaidBank>?
    let plaidAccounts: Array<CBPlaidAccount>?
    let plaidTransactionsWithCount: CBPlaidTransactionListWithCount?
    let plaidBalances: Array<CBPlaidBalance>?
    
    let logos: Array<CBLogo>?
    let settings: AppSettings?
    
    enum CodingKeys: CodingKey { case return_time, transactions, starting_amounts, repeating_transactions, pay_methods, categories, category_groups, keywords, budgets, fit_transactions, open_records, plaid_banks, plaid_accounts, plaid_transactions, plaid_balances, logos, settings }
    
    init () {
        self.returnTime = nil
        self.transactions = nil
        self.startingAmounts = nil
        self.repeatingTransactions = nil
        self.payMethods = nil
        self.categories = nil
        self.categoryGroups = nil
        self.keywords = nil
        self.budgets = nil
        
        self.fitTransactions = nil
        self.openRecords = nil
        
        self.plaidBanks = nil
        self.plaidAccounts = nil
        self.plaidTransactionsWithCount = nil
        self.plaidBalances = nil
        
        self.logos = nil
        self.settings = nil
    }
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.returnTime = try container.decode(Int.self, forKey: .return_time)
        self.transactions = try container.decodeIfPresent(Array<CBTransaction>.self, forKey: .transactions)
        self.startingAmounts = try container.decodeIfPresent(Array<CBStartingAmount>.self, forKey: .starting_amounts)
        self.repeatingTransactions = try container.decodeIfPresent(Array<CBRepeatingTransaction>.self, forKey: .repeating_transactions)
        self.payMethods = try container.decodeIfPresent(Array<CBPaymentMethod>.self, forKey: .pay_methods)
        self.categories = try container.decodeIfPresent(Array<CBCategory>.self, forKey: .categories)
        self.categoryGroups = try container.decodeIfPresent(Array<CBCategoryGroup>.self, forKey: .category_groups)
        self.keywords = try container.decodeIfPresent(Array<CBKeyword>.self, forKey: .keywords)
        self.budgets = try container.decodeIfPresent(Array<CBBudget>.self, forKey: .budgets)
                
        self.fitTransactions = try container.decodeIfPresent(Array<CBFitTransaction>.self, forKey: .fit_transactions)
        self.openRecords = try container.decodeIfPresent(Array<CBOpenOrClosedRecord>.self, forKey: .open_records)
        
        self.plaidBanks = try container.decodeIfPresent(Array<CBPlaidBank>.self, forKey: .plaid_banks)
        self.plaidAccounts = try container.decodeIfPresent(Array<CBPlaidAccount>.self, forKey: .plaid_accounts)
        self.plaidTransactionsWithCount = try container.decodeIfPresent(CBPlaidTransactionListWithCount.self, forKey: .plaid_transactions)
        self.plaidBalances = try container.decodeIfPresent(Array<CBPlaidBalance>.self, forKey: .plaid_balances)
        
        self.logos = try container.decodeIfPresent(Array<CBLogo>.self, forKey: .logos)
        self.settings = try container.decodeIfPresent(AppSettings.self, forKey: .settings)
    }
}



class LongPollSubscribeModel: Encodable {
    let lastReturnTime: Int?
    var deviceName: String = UserDefaults.standard.string(forKey: "deviceName") ?? "device name undetermined"
    
    enum CodingKeys: CodingKey { case last_return_time, user_id, account_id, device_uuid, device_os, device_name }
        
    init(lastReturnTime: Int?) {
        self.lastReturnTime = lastReturnTime
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lastReturnTime, forKey: .last_return_time)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
                
        #if os(macOS)
        try container.encode(String(ProcessInfo.processInfo.operatingSystemVersionString), forKey: .device_os)
        try container.encode(String(ProcessInfo.processInfo.hostName), forKey: .device_name)
        #else
        try container.encode(String(UIDevice.current.systemVersion), forKey: .device_os)
        try container.encode(String(UIDevice.current.name), forKey: .device_name)
        #endif
    }
}
