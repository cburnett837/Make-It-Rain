//
//  TransactionAndStartingAmountModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/1/25.
//


import Foundation

class TransactionAndStartingAmountModel: Decodable {
    let populatedId: Int
    let hasPopulated: Bool
    let transactions: Array<CBTransaction>
    let startingAmounts: Array<CBStartingAmount>
    let budgets: Array<CBBudgetItem>?
    let plaidTransactionsWithCount: CBPlaidTransactionListWithCount?
    let plaidBalances: Array<CBPlaidBalance>?
    let budget: Double
    
    enum CodingKeys: CodingKey { case transactions, starting_amounts, budgets, has_populated, plaid_transactions_with_count, plaid_balances, budget, populated_id }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        populatedId = try container.decode(Int.self, forKey: .populated_id)
        transactions = try container.decode(Array<CBTransaction>.self, forKey: .transactions)
        startingAmounts = try container.decode(Array<CBStartingAmount>.self, forKey: .starting_amounts)
        budgets = try container.decode(Array<CBBudgetItem>.self, forKey: .budgets)
        let hasPopulated = try container.decode(Int.self, forKey: .has_populated)
        self.hasPopulated = hasPopulated == 1
        
        plaidTransactionsWithCount = try container.decodeIfPresent(CBPlaidTransactionListWithCount.self, forKey: .plaid_transactions_with_count)
        plaidBalances = try container.decodeIfPresent(Array<CBPlaidBalance>.self, forKey: .plaid_balances)
        
        budget = try container.decode(Double.self, forKey: .budget)
        
    }
}
