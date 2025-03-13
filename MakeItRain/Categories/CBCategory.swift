//
//  CBCategory.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/28/24.
//

import Foundation
import SwiftUI

@Observable
class CBCategory: Codable, Identifiable, Hashable, Equatable {
    var id: String
    var uuid: String?
    var title: String
    var amount: Double? {
        Double(amountString?.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "") ?? "0.0") ?? 0.0
    }
    var amountString: String?
    var color: Color
    var emoji: String?
    var active: Bool
    var action: CategoryAction
    var isIncome: Bool
    var listOrder: Int?
    
    enum CodingKeys: CodingKey { case id, uuid, title, amount, hex_code, emoji, active, user_id, account_id, device_uuid, is_income, list_order }
        
    init() {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.title = ""
        self.color = UserDefaults.fetchOneBool(requestedKey: "preferDarkMode") == true ? .white : .black
        //self.color = .primary
        //self.emoji = "questionmark.circle.fill"
        self.active = true
        self.action = .add
        self.isIncome = false
    }
    
    init(uuid: String) {
        self.id = uuid
        self.uuid = uuid
        self.title = ""
        self.color = UserDefaults.fetchOneBool(requestedKey: "preferDarkMode") == true ? .white : .black
        //self.color = .primary
        //self.emoji = "questionmark.circle.fill"
        self.active = true
        self.action = .add
        self.isIncome = false
    }
    
    
    init(entity: PersistentCategory) {
        self.id = entity.id!
        self.title = entity.title ?? ""
        self.color = Color.fromHex(entity.hexCode) ?? .clear
        //self.color = Color.fromName(entity.hexCode ?? "white")
        self.emoji = entity.emoji ?? ""
        self.active = true
        self.action = CategoryAction.fromString(entity.action!)
        
        let useWholeNumbers = UserDefaults.standard.bool(forKey: "useWholeNumbers")
        self.amountString = entity.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        self.isIncome = entity.isIncome
        self.listOrder = Int(entity.listOrder)
    }
    
//    init(entity: TempCategory) {
//        self.id = entity.id!
//        self.title = entity.title ?? ""
//        self.color = Color.fromHex(entity.hexCode) ?? .clear
//        self.emoji = entity.emoji ?? ""
//        self.active = true
//        self.action = CategoryAction.fromString(entity.action!)
//        
//        let useWholeNumbers = UserDefaults.standard.bool(forKey: "useWholeNumbers")
//        self.amountString = entity.amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
//    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(title, forKey: .title)
        try container.encode(amount, forKey: .amount)
        try container.encode(color.toHex(), forKey: .hex_code)
        //try container.encode(color.description, forKey: .hex_code)
        try container.encode(emoji, forKey: .emoji)
        try container.encode(active ? 1 : 0, forKey: .active)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(isIncome ? 1 : 0, forKey: .is_income)
        try container.encode(listOrder, forKey: .list_order)
    }
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            id = try String(container.decode(Int.self, forKey: .id))
        } catch {
            id = try container.decode(String.self, forKey: .id)
        }
        title = try container.decode(String.self, forKey: .title)
        
        let amount = try container.decode(Double?.self, forKey: .amount)
        let useWholeNumbers = UserDefaults.standard.bool(forKey: "useWholeNumbers")
        self.amountString = amount?.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        //let colorDescription = try container.decode(String?.self, forKey: .hex_code)
        //self.color = Color.fromName(colorDescription ?? "white")
        let hexCode = try container.decode(String?.self, forKey: .hex_code)
        self.color = Color.fromHex(hexCode) ?? .primary
        
        self.emoji = try container.decode(String?.self, forKey: .emoji)
        
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1 ? true : false
        
        let isIncome = try container.decode(Int?.self, forKey: .is_income)
        self.isIncome = isIncome == 1 ? true : false
        
        listOrder = try container.decode(Int?.self, forKey: .list_order)
        
        action = .edit
    }
    
    
    
    
    
    static var empty: CBCategory {
        CBCategory()
    }
    
    
    func hasChanges() -> Bool {
        if let deepCopy = deepCopy {
            if self.title == deepCopy.title
            && self.amount == deepCopy.amount
            && self.color == deepCopy.color
            && self.isIncome == deepCopy.isIncome
            && self.listOrder == deepCopy.listOrder
            && self.emoji == deepCopy.emoji {
                return false
            }
        }
        return true
    }
    
    
    var deepCopy: CBCategory?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let copy = CBCategory.empty
            copy.id = self.id
            copy.uuid = self.uuid
            copy.title = self.title
            copy.amountString = self.amountString
            copy.color = self.color
            copy.emoji = self.emoji
            copy.active = self.active
            copy.action = self.action
            copy.isIncome = self.isIncome
            copy.listOrder = self.listOrder
            self.deepCopy = copy
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.uuid = deepCopy.uuid
                self.title = deepCopy.title
                self.amountString = deepCopy.amountString
                self.color = deepCopy.color
                self.emoji = deepCopy.emoji
                self.active = deepCopy.active
                self.action = deepCopy.action
                self.isIncome = deepCopy.isIncome
                self.listOrder = deepCopy.listOrder
            }
        case .clear:
            break
        }
    }
    
    
    func setFromAnotherInstance(category: CBCategory) {
        self.title = category.title
        
        let useWholeNumbers = UserDefaults.standard.bool(forKey: "useWholeNumbers")
        self.amountString = category.amount?.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        self.color = category.color
        self.emoji = category.emoji
        self.active = category.active
        self.isIncome = category.isIncome
        self.listOrder = category.listOrder
    }
    
    
    
    
    
    
    
    static func == (lhs: CBCategory, rhs: CBCategory) -> Bool {
        if lhs.id == rhs.id
            && lhs.uuid == rhs.uuid
            && lhs.title == rhs.title
            && lhs.amount == rhs.amount
            && lhs.color == rhs.color
            && lhs.emoji == rhs.emoji
            && lhs.isIncome == rhs.isIncome
            && lhs.listOrder == rhs.listOrder
            && lhs.active == rhs.active {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
