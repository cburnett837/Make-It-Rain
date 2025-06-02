//
//  CBPlaidAccount.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/22/25.
//

import Foundation


@Observable
class CBPlaidAccount: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var bankID: String
    var title: String
    var accountType: String?
    var active: Bool
    var action: PlaidAccountAction
    var paymentMethodID: String?
    
    var enteredBy: CBUser = AppState.shared.user!
    var updatedBy: CBUser = AppState.shared.user!
    var enteredDate: Date
    var updatedDate: Date
    
    /// For deep copies
    init() {
        let uuid = UUID().uuidString
        self.id = uuid
        self.bankID = uuid
        self.title = ""
        self.active = true
        self.action = .edit /// Different than normal since a `PlaidBank` will never be be created directly by the user.
        self.enteredBy = AppState.shared.user!
        self.updatedBy = AppState.shared.user!
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    
        
    enum CodingKeys: CodingKey { case id, bank_id, title, account_type, active, user_id, account_id, device_uuid, entered_by, updated_by, entered_date, updated_date, payment_method_id }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(bankID, forKey: .bank_id)
        try container.encode(title, forKey: .title)
        try container.encode(paymentMethodID, forKey: .payment_method_id)
        try container.encode(accountType, forKey: .account_type)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(enteredBy, forKey: .entered_by) // for the Transferable protocol
        try container.encode(updatedBy, forKey: .updated_by) // for the Transferable protocol
        try container.encode(enteredDate.string(to: .serverDateTime), forKey: .entered_date) // for the Transferable protocol
        try container.encode(updatedDate.string(to: .serverDateTime), forKey: .updated_date) // for the Transferable protocol
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            id = try String(container.decode(Int.self, forKey: .id))
        } catch {
            id = try container.decode(String.self, forKey: .id)
        }
        
        do {
            bankID = try String(container.decode(Int.self, forKey: .bank_id))
        } catch {
            bankID = try container.decode(String.self, forKey: .bank_id)
        }
        
        do {
            if let paymentMethodID = try container.decode(Int?.self, forKey: .payment_method_id) {
                self.paymentMethodID = String(paymentMethodID)
            }
        } catch {
            paymentMethodID = try container.decode(String?.self, forKey: .payment_method_id)
        }
        
        
        
                
        
        title = try container.decode(String.self, forKey: .title)
        accountType = try container.decode(String?.self, forKey: .account_type)
        
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1 ? true : false
        
        action = .edit
        
        enteredBy = try container.decode(CBUser.self, forKey: .entered_by)
        updatedBy = try container.decode(CBUser.self, forKey: .updated_by)
        
        let enteredDate = try container.decode(String?.self, forKey: .entered_date)
        if let enteredDate {
            self.enteredDate = enteredDate.toDateObj(from: .serverDateTime)!
        } else {
            fatalError("Could not determine enteredDate date")
        }
        
        let updatedDate = try container.decode(String?.self, forKey: .updated_date)
        if let updatedDate {
            self.updatedDate = updatedDate.toDateObj(from: .serverDateTime)!
        } else {
            fatalError("Could not determine updatedDate date")
        }
        
    }
    
    
    
    func hasChanges() -> Bool {
        if let deepCopy = deepCopy {
            if self.title == deepCopy.title {
                return false
            }
        }
        return true
    }
    
    
    var deepCopy: CBPlaidAccount?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let copy = CBPlaidAccount()
            copy.id = self.id
            copy.bankID = self.bankID
            copy.paymentMethodID = self.paymentMethodID
            copy.title = self.title
            copy.accountType = self.accountType
            copy.active = self.active
            //copy.action = self.action
            self.deepCopy = copy
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.bankID = deepCopy.bankID
                self.paymentMethodID = deepCopy.paymentMethodID
                self.title = deepCopy.title
                self.accountType = deepCopy.accountType
                self.active = deepCopy.active
                //self.action = deepCopy.action
            }
        case .clear:
            break
        }
    }
    
    
    func setFromAnotherInstance(account: CBPlaidAccount) {
        self.title = account.title
        self.accountType = account.accountType
        self.active = account.active
        self.paymentMethodID = account.paymentMethodID
    }
    
    
    static func == (lhs: CBPlaidAccount, rhs: CBPlaidAccount) -> Bool {
        if lhs.id == rhs.id
        && lhs.bankID == rhs.bankID
        && lhs.paymentMethodID == rhs.paymentMethodID
        && lhs.title == rhs.title
        && lhs.accountType == rhs.accountType
        && lhs.active == rhs.active {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
