//
//  RepeatingAndBudgetSubmissionModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/1/24.
//

import Foundation

struct RepeatingAndBudgetSubmissionModel: Encodable {
    var month: Int
    var year: Int
    var transactions: Array<CBTransaction>
    var budgets: Array<CBBudgetItem>
    //var budgetGroups: Array<CBBudgetItemGroup>
    var isTransfer: Bool
    
    enum CodingKeys: CodingKey { case user_id, account_id, transactions, budgets, device_uuid, has_submitted, month, year, is_transfer, budget_amount }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(month, forKey: .month)
        try container.encode(year, forKey: .year)
        try container.encode(transactions, forKey: .transactions)
        try container.encode(budgets, forKey: .budgets)
        //try container.encode(budgetGroups, forKey: .budget_groups)
        try container.encode(1, forKey: .has_submitted)
        try container.encode(isTransfer ? 1 : 0, forKey: .is_transfer)
        try container.encode(Cody.shared.id, forKey: .user_id)
        try container.encode(Cody.shared.accountID, forKey: .account_id)
        try container.encode(Cody.shared.deviceUUID, forKey: .device_uuid)
    }
}


struct PopulateSubmissionModel: Encodable {
    var month: Int
    var year: Int
    var transactions: Array<CBRepTransactionCreateModel>
    var budgets: Array<CBBudgetItem>
    //var budgetGroups: Array<CBBudgetItemGroup>
    var isTransfer: Bool
    var budget: Decimal
    
    enum CodingKeys: CodingKey { case user_id, account_id, transactions, budgets, device_uuid, has_submitted, month, year, is_transfer, budget_amount }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(month, forKey: .month)
        try container.encode(year, forKey: .year)
        try container.encode(transactions, forKey: .transactions)
        try container.encode(budgets, forKey: .budgets)
        try container.encode(budget, forKey: .budget_amount)
        //try container.encode(budgetGroups, forKey: .budget_groups)
        try container.encode(1, forKey: .has_submitted)
        try container.encode(isTransfer ? 1 : 0, forKey: .is_transfer)
        try container.encode(Cody.shared.id, forKey: .user_id)
        try container.encode(Cody.shared.accountID, forKey: .account_id)
        try container.encode(Cody.shared.deviceUUID, forKey: .device_uuid)
    }
}
