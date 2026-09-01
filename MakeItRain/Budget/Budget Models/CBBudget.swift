//
//  CBBudget.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/9/26.
//

import Foundation

@Observable
class CBBudget: Codable, Identifiable, Hashable, Equatable, IsEditableBudget, HasUserUpdateInfo {
    var id: String
    var uuid: String?
    var amount: Decimal {
        CurrencyHelpers.parseAmountStringToDecimal(amountString) ?? 0.0
        //Decimal(amountString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
    }
    var amountString: String

    var active: Bool
    var action: BudgetAction
    
    var enteredBy: CBUser = AppState.shared.user!
    var updatedBy: CBUser = AppState.shared.user!
    var enteredById: Int?
    var updatedById: Int?
    var enteredDate: Date
    var updatedDate: Date

    
    init() {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.amountString = ""
        self.active = true
        self.action = .add
        
        self.enteredBy = AppState.shared.user!
        self.updatedBy = AppState.shared.user!
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    
    
    init(uuid: String) {
        self.id = uuid
        self.uuid = uuid
        self.amountString = ""
        self.active = true
        self.action = .add
        
        self.enteredBy = AppState.shared.user!
        self.updatedBy = AppState.shared.user!
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    
    
    
    enum CodingKeys: CodingKey { case id, uuid, amount, active, user_id, account_id, device_uuid, entered_by, updated_by, entered_date, updated_date, entered_by_id, updated_by_id }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(amount, forKey: .amount)
        try container.encode(active ? 1 : 0, forKey: .active)
        try container.encode(Cody.shared.id, forKey: .user_id)
        try container.encode(Cody.shared.accountID, forKey: .account_id)
        try container.encode(Cody.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(enteredById, forKey: .entered_by_id) // for the Transferable protocol
        try container.encode(updatedById, forKey: .updated_by_id) // for the Transferable protocol
        try container.encode(enteredDate, forKey: .entered_date) // for the Transferable protocol
        try container.encode(updatedDate, forKey: .updated_date) // for the Transferable protocol
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
        
        if let enteredById = try container.decode(Int?.self, forKey: .entered_by_id) {
            self.enteredBy = AppState.shared.getUserBy(id: enteredById) ?? CBUser()
        }
        
        if let updatedById = try container.decode(Int?.self, forKey: .updated_by_id) {
            self.updatedBy = AppState.shared.getUserBy(id: updatedById) ?? CBUser()
        }

        enteredDate = try container.decode(Date.self, forKey: .entered_date)
        updatedDate = try container.decode(Date.self, forKey: .updated_date)
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
        self.enteredBy = budget.enteredBy
        self.updatedBy = budget.updatedBy
        self.enteredDate = budget.enteredDate
        self.updatedDate = budget.updatedDate
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
