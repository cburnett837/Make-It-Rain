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
    let budgets: Array<CBBudgetItem>?
    let monthlyBudgets: Array<CBMonth>? /// Just for the budgets
    let globalBudget: CBBudget?
    
    let openRecords: Array<CBOpenOrClosedRecord>?
    
    let plaidBanks: Array<CBPlaidBank>?
    let plaidAccounts: Array<CBPlaidAccount>?
    let plaidTransactionsWithCount: CBPlaidTransactionListWithCount?
    let plaidBalances: Array<CBPlaidBalance>?
    
    let logos: Array<CBLogo>?
    let settings: AppSettings?
    let receipts: Array<CBTransaction>?
    
    let countryId: Int?
    
    enum CodingKeys: CodingKey { case return_time, transactions, starting_amounts, repeating_transactions, pay_methods, categories, category_groups, keywords, budgets, open_records, plaid_banks, plaid_accounts, plaid_transactions, plaid_balances, logos, settings, receipts, monthly_budgets, global_budget, country_id }
    
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
        
        self.openRecords = nil
        
        self.plaidBanks = nil
        self.plaidAccounts = nil
        self.plaidTransactionsWithCount = nil
        self.plaidBalances = nil
        
        self.logos = nil
        self.settings = nil
        self.receipts = nil
        self.monthlyBudgets = nil
        self.globalBudget = nil
        self.countryId = nil
    }
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.returnTime = try container.decodeIfPresent(Int.self, forKey: .return_time)
        self.transactions = try container.decodeIfPresent(Array<CBTransaction>.self, forKey: .transactions)
        self.startingAmounts = try container.decodeIfPresent(Array<CBStartingAmount>.self, forKey: .starting_amounts)
        self.repeatingTransactions = try container.decodeIfPresent(Array<CBRepeatingTransaction>.self, forKey: .repeating_transactions)
        self.payMethods = try container.decodeIfPresent(Array<CBPaymentMethod>.self, forKey: .pay_methods)
        self.categories = try container.decodeIfPresent(Array<CBCategory>.self, forKey: .categories)
        self.categoryGroups = try container.decodeIfPresent(Array<CBCategoryGroup>.self, forKey: .category_groups)
        self.keywords = try container.decodeIfPresent(Array<CBKeyword>.self, forKey: .keywords)
        self.budgets = try container.decodeIfPresent(Array<CBBudgetItem>.self, forKey: .budgets)
                
        self.openRecords = try container.decodeIfPresent(Array<CBOpenOrClosedRecord>.self, forKey: .open_records)
        
        self.plaidBanks = try container.decodeIfPresent(Array<CBPlaidBank>.self, forKey: .plaid_banks)
        self.plaidAccounts = try container.decodeIfPresent(Array<CBPlaidAccount>.self, forKey: .plaid_accounts)
        self.plaidTransactionsWithCount = try container.decodeIfPresent(CBPlaidTransactionListWithCount.self, forKey: .plaid_transactions)
        self.plaidBalances = try container.decodeIfPresent(Array<CBPlaidBalance>.self, forKey: .plaid_balances)
        
        self.logos = try container.decodeIfPresent(Array<CBLogo>.self, forKey: .logos)
        self.settings = try container.decodeIfPresent(AppSettings.self, forKey: .settings)
        self.receipts = try container.decodeIfPresent(Array<CBTransaction>.self, forKey: .receipts)
        self.monthlyBudgets = try container.decodeIfPresent(Array<CBMonth>.self, forKey: .monthly_budgets)
        self.globalBudget = try container.decodeIfPresent(CBBudget.self, forKey: .global_budget)
        self.countryId = try container.decodeIfPresent(Int.self, forKey: .country_id)
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
        try container.encode(Cody.shared.id, forKey: .user_id)
        try container.encode(Cody.shared.accountID, forKey: .account_id)
        try container.encode(Cody.shared.deviceUUID, forKey: .device_uuid)
                
        #if os(macOS)
        try container.encode(String(ProcessInfo.processInfo.operatingSystemVersionString), forKey: .device_os)
        try container.encode(String(ProcessInfo.processInfo.hostName), forKey: .device_name)
        #else
        try container.encode(String(UIDevice.current.systemVersion), forKey: .device_os)
        try container.encode(String(UIDevice.current.name), forKey: .device_name)
        #endif
    }
}
