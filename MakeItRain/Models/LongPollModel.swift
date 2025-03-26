//
//  LongPollModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/4/24.
//

import Foundation

class LongPollModel: Decodable {
    let returnTime: Int?
    
    let transactions: Array<CBTransaction>?
    let startingAmounts: Array<CBStartingAmount>?
    let repeatingTransactions: Array<CBRepeatingTransaction>?
    let payMethods: Array<CBPaymentMethod>?
    let categories: Array<CBCategory>?
    let keywords: Array<CBKeyword>?
    let budgets: Array<CBBudget>?
    let events: Array<CBEvent>?
    let invitations: Array<CBEventParticipant>?
    let fitTransactions: Array<CBFitTransaction>?
    
    enum CodingKeys: CodingKey { case return_time, transactions, starting_amounts, repeating_transactions, pay_methods, categories, keywords, budgets, events, invitations, fit_transactions }
    
    init () {
        self.returnTime = nil
        self.transactions = nil
        self.startingAmounts = nil
        self.repeatingTransactions = nil
        self.payMethods = nil
        self.categories = nil
        self.keywords = nil
        self.budgets = nil
        self.events = nil
        self.invitations = nil
        self.fitTransactions = nil
    }
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.returnTime = try container.decode(Int.self, forKey: .return_time)
        self.transactions = try container.decodeIfPresent(Array<CBTransaction>.self, forKey: .transactions)
        self.startingAmounts = try container.decodeIfPresent(Array<CBStartingAmount>.self, forKey: .starting_amounts)
        self.repeatingTransactions = try container.decodeIfPresent(Array<CBRepeatingTransaction>.self, forKey: .repeating_transactions)
        self.payMethods = try container.decodeIfPresent(Array<CBPaymentMethod>.self, forKey: .pay_methods)
        self.categories = try container.decodeIfPresent(Array<CBCategory>.self, forKey: .categories)
        self.keywords = try container.decodeIfPresent(Array<CBKeyword>.self, forKey: .keywords)
        self.budgets = try container.decodeIfPresent(Array<CBBudget>.self, forKey: .budgets)
        self.events = try container.decodeIfPresent(Array<CBEvent>.self, forKey: .events)
        self.invitations = try container.decodeIfPresent(Array<CBEventParticipant>.self, forKey: .invitations)
        self.fitTransactions = try container.decodeIfPresent(Array<CBFitTransaction>.self, forKey: .fit_transactions)
    }
}
