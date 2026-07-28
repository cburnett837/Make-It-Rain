//
//  CBBudget.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/9/26.
//

import Foundation

@Observable
class CBBudget: Codable, Identifiable, Hashable, Equatable, IsEditableBudget {
    var id: String
    var uuid: String?
    var amount: Decimal {
        CurrencyHelpers.parseAmountStringToDecimal(amountString) ?? 0.0
        //Decimal(amountString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
    }
    var amountString: String

    var active: Bool
    var action: BudgetAction

    
    init() {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.amountString = ""
        self.active = true
        self.action = .add
    }
    
    
    init(uuid: String) {
        self.id = uuid
        self.uuid = uuid
        self.amountString = ""
        self.active = true
        self.action = .add
    }
    
    
    
    enum CodingKeys: CodingKey { case id, uuid, amount, active, user_id, account_id, device_uuid }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(amount, forKey: .amount)
        try container.encode(active ? 1 : 0, forKey: .active)
        try container.encode(Cody.shared.id, forKey: .user_id)
        try container.encode(Cody.shared.accountID, forKey: .account_id)
        try container.encode(Cody.shared.deviceUUID, forKey: .device_uuid)
    }
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            id = try String(container.decode(Int.self, forKey: .id))
        } catch {
            id = try container.decode(String.self, forKey: .id)
        }
                
        let amount = try container.decode(Decimal.self, forKey: .amount)
        self.amountString = amount.currencyWithDecimals()
    
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1 ? true : false
        
        action = .edit
    }
    
    func hasChanges() -> Bool {
        if let deepCopy = deepCopy {
            if self.amount == deepCopy.amount {
                return false
            }
        }
        return true
    }
    
    
    var deepCopy: CBBudget?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let budget = CBBudget()
            budget.id = self.id
            budget.amountString = self.amountString
            budget.active = self.active
            self.deepCopy = budget
            
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.amountString = deepCopy.amountString
                self.active = deepCopy.active
            }
        case .clear:
            break
        }
    }
    
    func setFromAnotherInstance(budget: CBBudget) {
        self.amountString = budget.amount.currencyWithDecimals()
        self.active = budget.active
    }
    
   
    
    static func == (lhs: CBBudget, rhs: CBBudget) -> Bool {
        if lhs.id == rhs.id
        && lhs.amount == rhs.amount {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}
