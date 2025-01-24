//
//  LongPollModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/4/24.
//

import Foundation

class LongPollModel: Decodable {
    let transactions: Array<CBTransaction>?
    let startingAmounts: Array<CBStartingAmount>?
    let repeatingTransactions: Array<CBRepeatingTransaction>?
    let payMethods: Array<CBPaymentMethod>?
    let categories: Array<CBCategory>?
    let keywords: Array<CBKeyword>?
    let budgets: Array<CBBudget>?
    let events: Array<CBEvent>?
    let invitations: Array<CBEventParticipant>?
    
    enum CodingKeys: CodingKey { case transactions, starting_amounts, repeating_transactions, pay_methods, categories, keywords, budgets, events, invitations }
    
    init () {
        self.transactions = nil
        self.startingAmounts = nil
        self.repeatingTransactions = nil
        self.payMethods = nil
        self.categories = nil
        self.keywords = nil
        self.budgets = nil
        self.events = nil
        self.invitations = nil
    }
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.transactions = try container.decode(Array<CBTransaction>?.self, forKey: .transactions)
        self.startingAmounts = try container.decode(Array<CBStartingAmount>?.self, forKey: .starting_amounts)
        self.repeatingTransactions = try container.decode(Array<CBRepeatingTransaction>?.self, forKey: .repeating_transactions)
        self.payMethods = try container.decode(Array<CBPaymentMethod>?.self, forKey: .pay_methods)
        self.categories = try container.decode(Array<CBCategory>?.self, forKey: .categories)
        self.keywords = try container.decode(Array<CBKeyword>?.self, forKey: .keywords)
        self.budgets = try container.decode(Array<CBBudget>?.self, forKey: .budgets)
        self.events = try container.decode(Array<CBEvent>?.self, forKey: .events)
        self.invitations = try container.decode(Array<CBEventParticipant>?.self, forKey: .invitations)
    }
}
