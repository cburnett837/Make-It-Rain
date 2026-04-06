//
//  AccessorialModelDecodable.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/3/26.
//

import Foundation

struct AccessorialModelDecodable: Decodable {
    var categories: [CBCategory]
    var categoryGroups: [CBCategoryGroup]
    var repeatingTransactions: [CBRepeatingTransaction]
    var keywords: [CBKeyword]
    var tags: [CBTag]
    var suggestedTitles: [CBSuggestedTitle]
    var appSuiteBudgets: [CBBudget]
    var plaidBanks: [CBPlaidBank]
    
    enum CodingKeys: CodingKey { case categories, category_groups, repeating_transactions, keywords, tags, suggested_titles, app_suite_budgets, plaid_banks }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.categories = try container.decode(Array<CBCategory>.self, forKey: .categories)
        self.categoryGroups = try container.decode(Array<CBCategoryGroup>.self, forKey: .category_groups)
        self.repeatingTransactions = try container.decode(Array<CBRepeatingTransaction>.self, forKey: .repeating_transactions)
        self.keywords = try container.decode(Array<CBKeyword>.self, forKey: .keywords)
        self.tags = try container.decode(Array<CBTag>.self, forKey: .tags)
        self.suggestedTitles = try container.decode(Array<CBSuggestedTitle>.self, forKey: .suggested_titles)
        self.appSuiteBudgets = try container.decode(Array<CBBudget>.self, forKey: .app_suite_budgets)
        self.plaidBanks = try container.decode(Array<CBPlaidBank>.self, forKey: .plaid_banks)
    }
}
