//
//  CBBudget.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/30/24.
//

import Foundation
import SwiftUI

@Observable
class CBBudget: Codable, Identifiable, Hashable, Equatable {
    var id: Int
    var category: CBCategory?
    var month: Int
    var year: Int
    var amount: Double {
        Double(amountString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0
    }
    var amountString: String    
    var active: Bool
    var action: BudgetAction
    
    init() {
        self.id = 0
        self.category = nil
        self.month = 0
        self.year = 0
        self.amountString = ""
        self.active = true
        self.action = .add
    }
    
    
    enum CodingKeys: CodingKey { case id, category, month, year, amount, active, user_id, account_id, device_uuid }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(category, forKey: .category)
        try container.encode(month, forKey: .month)
        try container.encode(year, forKey: .year)
        try container.encode(amount, forKey: .amount)
        try container.encode(active ? 1 : 0, forKey: .active)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
    }
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        self.category = try container.decode(CBCategory?.self, forKey: .category)
        month = try container.decode(Int.self, forKey: .month)
        year = try container.decode(Int.self, forKey: .year)
        
        let amount = try container.decode(Double.self, forKey: .amount)
        let useWholeNumbers = UserDefaults.standard.bool(forKey: "useWholeNumbers")
        self.amountString = amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1 ? true : false
        
        action = .edit
    }
    
    
    static var empty: CBBudget {
        CBBudget()
    }
    
    
    
    func hasChanges() -> Bool {
        if let deepCopy = deepCopy {
            if self.month == deepCopy.month
            && self.year == deepCopy.year
            && self.amount == deepCopy.amount
            && self.category?.id == deepCopy.category?.id {
                return false
            }
        }
        return true
    }
    
    
    var deepCopy: CBBudget?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let trans = CBBudget.empty
            trans.id = self.id
            trans.month = self.month
            trans.year = self.year
            trans.amountString = self.amountString
            trans.category = self.category
            trans.active = self.active
            self.deepCopy = trans
            
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.month = deepCopy.month
                self.year = deepCopy.year
                self.amountString = deepCopy.amountString
                self.category = deepCopy.category
                self.active = deepCopy.active
            }
        }
    }
    
    func setFromAnotherInstance(budget: CBBudget) {
        self.month = budget.month
        self.year = budget.year
                
        let useWholeNumbers = UserDefaults.standard.bool(forKey: "useWholeNumbers")
        self.amountString = budget.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        self.category = budget.category
        self.active = budget.active
    }
    
   
    
    static func == (lhs: CBBudget, rhs: CBBudget) -> Bool {
        if lhs.id == rhs.id
        && lhs.month == rhs.month
        && lhs.year == rhs.year
        && lhs.amount == rhs.amount
        && lhs.category?.id == rhs.category?.id {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}

