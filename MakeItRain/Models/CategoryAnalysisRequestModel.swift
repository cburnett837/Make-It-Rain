//
//  CategoryAnalysisRequestModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/6/25.
//

import Foundation

class AnalysisRequestModel: Encodable {
    let recordIDs: Array<String>
    let groupID: String?
    let fetchYearStart: Int
    let fetchYearEnd: Int
    let isUnifiedRequest: Bool
    
    enum CodingKeys: CodingKey { case record_ids, fetch_year_start, fetch_year_end, user_id, account_id, device_uuid, is_unified_request, group_id }
    
    
    init(recordIDs: Array<String>, groupID: String?, fetchYearStart: Int, fetchYearEnd: Int, isUnifiedRequest: Bool) {
        self.recordIDs = recordIDs
        self.groupID = groupID
        self.fetchYearStart = fetchYearStart
        self.fetchYearEnd = fetchYearEnd
        self.isUnifiedRequest = isUnifiedRequest
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(recordIDs, forKey: .record_ids)
        try container.encode(groupID, forKey: .group_id)
        try container.encode(fetchYearStart, forKey: .fetch_year_start)
        try container.encode(fetchYearEnd, forKey: .fetch_year_end)
        try container.encode(isUnifiedRequest ? 1 : 0, forKey: .is_unified_request)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
    }
}



class CategoryAnalysisResponseModel: Decodable, Identifiable {
    var id: String
    var uuid: String?
    var category: CBCategory?
    var month: Int
    var year: Int
    var date: Date {
        Helpers.createDate(month: month, year: year)!
    }
    
    var expensesString: String
    var expenses: Double {
        Double(expensesString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
    }
    
    var incomeString: String
    var income: Double {
        Double(incomeString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
    }
    
    var budgetString: String
    var budget: Double {
        Double(budgetString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
    }
    
    
    enum CodingKeys: CodingKey { case id, uuid, category, month, year, expenses, income, budget, user_id, account_id, device_uuid }
            
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            id = try String(container.decode(Int.self, forKey: .id))
        } catch {
            id = try container.decode(String.self, forKey: .id)
        }
        self.category = try container.decode(CBCategory?.self, forKey: .category)
        month = try container.decode(Int.self, forKey: .month)
        year = try container.decode(Int.self, forKey: .year)
                
        let expenses = try container.decode(Double.self, forKey: .expenses)
        self.expensesString = expenses.currencyWithDecimals()
                
        let income = try container.decode(Double.self, forKey: .income)
        self.incomeString = income.currencyWithDecimals()
        
        let budget = try container.decode(Double.self, forKey: .budget)
        self.budgetString = budget.currencyWithDecimals()
    }
}

