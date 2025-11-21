//
//  CBStartingAmount.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/24/24.
//

import Foundation

@Observable
class CBStartingAmount: Codable, Identifiable, Hashable, Equatable {
    var id: String
    var uuid: String?
    var month: Int
    var year: Int
    var date: Date {
        Helpers.createDate(month: month, year: year)!
    }
    
    var amount: Double {
        Double(amountString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
    }
    var amountString: String = ""
        
    var active: Bool
    var payMethod: CBPaymentMethod
    var action: StartingAmountAction        
            
    enum CodingKeys: CodingKey { case id, uuid, month, year, amount, payment_method, user_id, account_id, device_uuid, active }
    
    
    init() {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.month = 0
        self.year = 0
        self.amountString = ""
        self.payMethod = CBPaymentMethod()
        self.action = .add
        self.active = true
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(month, forKey: .month)
        try container.encode(year, forKey: .year)
        try container.encode(amount, forKey: .amount)
        try container.encode(payMethod, forKey: .payment_method)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
    }
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            id = try String(container.decode(Int.self, forKey: .id))
        } catch {
            id = try container.decode(String.self, forKey: .id)
        }
        let amount = try container.decode(Double.self, forKey: .amount)
        //self.amountString = "$\(amount)"
        let useWholeNumbers = LocalStorage.shared.useWholeNumbers
        self.amountString = amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        month = try container.decode(Int.self, forKey: .month)
        year = try container.decode(Int.self, forKey: .year)
        self.payMethod = try container.decode(CBPaymentMethod.self, forKey: .payment_method)
        action = .edit
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1 ? true : false
    }
    
    
    
    func hasChanges() -> Bool {
        if let deepCopy = deepCopy {
            if self.month == deepCopy.month
            && self.year == deepCopy.year
            && self.amountString == deepCopy.amountString
            && self.payMethod == deepCopy.payMethod {
                return false
            }
        }
        return true
    }
    
    
    var deepCopy: CBStartingAmount?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let copy = CBStartingAmount()
            copy.id = self.id
            copy.month = self.month
            copy.year = self.year
            copy.amountString = self.amountString
            copy.payMethod = self.payMethod
            self.deepCopy = copy
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.month = deepCopy.month
                self.year = deepCopy.year
                self.amountString = deepCopy.amountString
                self.payMethod = deepCopy.payMethod
            }
        case .clear:
            break
        }
    }
    
    
    
    
    static func == (lhs: CBStartingAmount, rhs: CBStartingAmount) -> Bool {
        if lhs.id == rhs.id
            && lhs.month == rhs.month
            && lhs.year == rhs.year
            && lhs.amountString == rhs.amountString
            && lhs.payMethod == rhs.payMethod
        {
            return true
        }
        return false
    }
    
    
    func setFromAnotherInstance(startingAmount: CBStartingAmount) {
        self.month = startingAmount.month
        self.year = startingAmount.year
        self.amountString = startingAmount.amountString
        self.payMethod = startingAmount.payMethod
    }
    
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
