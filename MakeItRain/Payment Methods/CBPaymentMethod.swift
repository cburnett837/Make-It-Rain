//
//  CBPaymentMethod.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/20/24.
//

import Foundation
import SwiftUI

@Observable
class CBPaymentMethod: Codable, Identifiable {
    var id: String
    var uuid: String?
    var title: String
    
    var dueDate: Int? {
        Int(dueDateString?.replacing(/[a-z]+/, with: "", maxReplacements: 1) ?? "0")
    }
    var dueDateString: String?
    
    var limit: Double? {
        Double(limitString?.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "") ?? "0.0") ?? 0.0
    }
    var limitString: String?
    
    
    var accountType: AccountType
    var color: Color
    var isDefault = false
    var active: Bool
    var action: PaymentMethodAction
    
    var notificationOffset: Int? = 0
    var notifyOnDueDate: Bool = false
    var last4: String?
    var enteredBy: CBUser = AppState.shared.user!
    var updatedBy: CBUser = AppState.shared.user!
    var enteredDate: Date
    var updatedDate: Date
    
    var isUnified: Bool {
        accountType == .unifiedChecking || accountType == .unifiedCredit
    }
        
    init() {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.title = ""
        self.color = UserDefaults.fetchOneBool(requestedKey: "preferDarkMode") == true ? .white : .black
        self.accountType = .checking
        self.action = .add
        self.color = UserDefaults.fetchOneBool(requestedKey: "preferDarkMode") == true ? .white : .black
        //self.color = .primary
        self.active = true
        self.notificationOffset = 0
        self.notifyOnDueDate = false
        self.last4 = nil
        self.enteredBy = AppState.shared.user!
        self.updatedBy = AppState.shared.user!
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    
    init(uuid: String) {
        self.id = uuid
        self.uuid = uuid
        self.title = ""
        self.accountType = .checking
        self.action = .add
        self.color = UserDefaults.fetchOneBool(requestedKey: "preferDarkMode") == true ? .white : .black
        //self.color = .primary
        self.active = true
        self.notificationOffset = 0
        self.notifyOnDueDate = false
        self.last4 = nil
        self.enteredBy = AppState.shared.user!
        self.updatedBy = AppState.shared.user!
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    
//    init(unifiedAccountType: AccountType) {
//        
//        if unifiedAccountType == .unifiedChecking {
//            self.id = 100000000
//            self.title = "All Checking"
//        } else if unifiedAccountType == .unifiedCredit {
//            self.id = 100000001
//            self.title = "All Credit"
//        } else {
//            self.id = 0
//            self.title = ""
//        }
//        
//        self.accountType = unifiedAccountType
//        self.action = .edit
//        self.color = .white
//        self.active = true
//    
    init(entity: PersistentPaymentMethod) {
        self.id = entity.id!
        self.title = entity.title ?? ""
        self.dueDateString = String(entity.dueDate)
        
        let useWholeNumbers = UserDefaults.standard.bool(forKey: "useWholeNumbers")
        self.limitString = entity.limit.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        self.accountType = AccountType(rawValue: entity.accountType ?? "") ?? .checking
        self.color = Color.fromHex(entity.hexCode) ?? .clear
        //self.color = Color.fromName(entity.hexCode ?? "white")
        self.action = .edit
        self.isDefault = entity.isDefault
        self.active = true
        self.notificationOffset = Int(entity.notificationOffset)
        self.notifyOnDueDate = entity.notifyOnDueDate
        self.last4 = entity.last4
        self.enteredBy = AppState.shared.user!
        self.updatedBy = AppState.shared.user!
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    
    
    enum CodingKeys: CodingKey { case id, uuid, title, due_date, limit, account_type, hex_code, is_default, active, user_id, account_id, device_uuid, notification_offset, notify_on_due_date, last_4_digits, entered_by, updated_by, entered_date, updated_date }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(title, forKey: .title)
        try container.encode(dueDate, forKey: .due_date)
        try container.encode(limit, forKey: .limit)
        try container.encode(accountType.rawValue, forKey: .account_type)
        try container.encode(color.toHex(), forKey: .hex_code)
        //try container.encode(color.description, forKey: .hex_code)
        try container.encode(isDefault ? 1 : 0, forKey: .is_default)
        try container.encode(active ? 1 : 0, forKey: .active)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(notificationOffset, forKey: .notification_offset)
        try container.encode(notifyOnDueDate ? 1 : 0, forKey: .notify_on_due_date)
        try container.encode(last4, forKey: .last_4_digits)
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
        
        
        title = try container.decode(String.self, forKey: .title)
        
        let dueDate = try container.decode(Int?.self, forKey: .due_date)
        self.dueDateString = String(dueDate ?? 0)
        
        let limit = try container.decode(Double?.self, forKey: .limit)
        let useWholeNumbers = UserDefaults.standard.bool(forKey: "useWholeNumbers")
        self.limitString = limit?.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        let accountType = try container.decode(String.self, forKey: .account_type)
        self.accountType = AccountType(rawValue: accountType) ?? .checking
        
        let hexCode = try container.decode(String?.self, forKey: .hex_code)
        self.color = Color.fromHex(hexCode) ?? .primary
        //let colorDescription = try container.decode(String?.self, forKey: .hex_code)
        //self.color = Color.fromName(colorDescription ?? "white")
        
        
        
        let isDefault = try container.decode(Int?.self, forKey: .is_default)
        self.isDefault = isDefault == 1 ? true : false
        
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1 ? true : false
        
        self.notificationOffset = try container.decode(Int?.self, forKey: .notification_offset)
        
        let notifyOnDueDate = try container.decode(Int?.self, forKey: .notify_on_due_date)
        self.notifyOnDueDate = notifyOnDueDate == 1 ? true : false
        
        self.last4 = try container.decode(String?.self, forKey: .last_4_digits)
        
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
    
    
    static var empty: CBPaymentMethod {
        CBPaymentMethod()
    }
    
    
    func hasChanges() -> Bool {
        if let deepCopy = deepCopy {
            if self.title == deepCopy.title
            && self.dueDate == deepCopy.dueDate
            && self.limit == deepCopy.limit
            && self.accountType == deepCopy.accountType
            && self.notificationOffset == deepCopy.notificationOffset
            && self.notifyOnDueDate == deepCopy.notifyOnDueDate
            && self.last4 == deepCopy.last4
            && self.color == deepCopy.color {
                return false
            }
        }
        return true
    }
    
    
    var deepCopy: CBPaymentMethod?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let copy = CBPaymentMethod.empty
            copy.id = self.id
            copy.uuid = self.uuid
            copy.title = self.title
            copy.dueDateString = self.dueDateString
            copy.limitString = self.limitString
            copy.accountType = self.accountType
            copy.color = self.color
            copy.isDefault = self.isDefault
            copy.active = self.active
            copy.notificationOffset = self.notificationOffset
            copy.notifyOnDueDate = self.notifyOnDueDate
            copy.last4 = self.last4
            copy.active = self.active
            //copy.action = self.action
            self.deepCopy = copy
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.uuid = deepCopy.uuid
                self.title = deepCopy.title
                self.dueDateString = deepCopy.dueDateString
                self.limitString = deepCopy.limitString
                self.accountType = deepCopy.accountType
                self.color = deepCopy.color
                self.isDefault = deepCopy.isDefault
                self.active = deepCopy.active
                self.notificationOffset = deepCopy.notificationOffset
                self.notifyOnDueDate = deepCopy.notifyOnDueDate
                self.last4 = deepCopy.last4
                self.active = deepCopy.active
                //self.action = deepCopy.action
            }
        case .clear:
            break
        }
    }
    
    
    func setFromAnotherInstance(payMethod: CBPaymentMethod) {
        self.title = payMethod.title
        self.dueDateString = payMethod.dueDateString
        
        let useWholeNumbers = UserDefaults.standard.bool(forKey: "useWholeNumbers")
        self.limitString = payMethod.limit?.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        self.accountType = payMethod.accountType
        self.color = payMethod.color
        self.isDefault = payMethod.isDefault
        self.active = payMethod.active
        self.notificationOffset = payMethod.notificationOffset
        self.notifyOnDueDate = payMethod.notifyOnDueDate
        self.last4 = payMethod.last4
    }
            
    
    @MainActor func changeDefault(_ to: Bool) {
        self.isDefault = to
        guard let entity = DataManager.shared.getOne(type: PersistentPaymentMethod.self, predicate: .byId(.string(self.id)), createIfNotFound: false) else { return }
        entity.isDefault = to
        let _ = DataManager.shared.save()
    }
}


extension CBPaymentMethod: Equatable, Hashable {
    static func == (lhs: CBPaymentMethod, rhs: CBPaymentMethod) -> Bool {
        if lhs.id == rhs.id
        && lhs.uuid == rhs.uuid
        && lhs.title == rhs.title
        && lhs.dueDate == rhs.dueDate
        && lhs.limit == rhs.limit
        && lhs.accountType == rhs.accountType
        && lhs.color == rhs.color
        && lhs.isDefault == rhs.isDefault
        && lhs.notificationOffset == rhs.notificationOffset
        && lhs.notifyOnDueDate == rhs.notifyOnDueDate
        && lhs.last4 == rhs.last4
        && lhs.active == rhs.active {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
