//
//  CBCategory.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/28/24.
//

import Foundation
import SwiftUI
import CoreData

@Observable
class CBCategory: Codable, Identifiable, Hashable, Equatable {
    var id: String
    var uuid: String?
    var title: String
    //var titleLower: String { title.lowercased() }
    var amount: Double? {
        Double(amountString?.replacing("$", with: "").replacing(",", with: "") ?? "0.0") ?? 0.0
    }
    var amountString: String?
    var color: Color
    var emoji: String?
    var active: Bool
    var action: CategoryAction
    var type: XrefItem = XrefModel.getItem(from: .categoryTypes, byEnumID: .expense)
    var listOrder: Int?
    //var unwrappedListOrder: Int { listOrder ?? 0 }
    var enteredBy: CBUser = AppState.shared.user!
    var updatedBy: CBUser = AppState.shared.user!
    var enteredDate: Date
    var updatedDate: Date
    var isNil: Bool = false
    var topTitles: [CBSuggestedTitle] = []
    
    var isIncome: Bool { self.type == XrefModel.getItem(from: .categoryTypes, byEnumID: .income) }
    var isPayment: Bool { self.type == XrefModel.getItem(from: .categoryTypes, byEnumID: .payment) }
    var isExpense: Bool { self.type == XrefModel.getItem(from: .categoryTypes, byEnumID: .expense) }
    var isSavings: Bool { self.type == XrefModel.getItem(from: .categoryTypes, byEnumID: .savings) }
    var isHidden = false
    
    var appSuiteKey: AppSuiteKey?
    
    enum CodingKeys: CodingKey { case id, uuid, title, amount, hex_code, emoji, active, user_id, account_id, device_uuid, type_id, list_order, entered_by, updated_by, entered_date, updated_date, is_nil, top_titles, is_hidden, app_suite_key }
        
    init() {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.title = ""
        self.color = .primary
        //self.emoji = "questionmark.circle.fill"
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
        self.title = ""
        self.color = .primary
        //self.emoji = "questionmark.circle.fill"
        self.active = true
        self.action = .add
        self.enteredBy = AppState.shared.user!
        self.updatedBy = AppState.shared.user!
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    
    
//    init(entity: PersistentCategory) {
//        self.id = entity.id!
//        self.title = entity.title ?? ""
//        self.color = Color.fromHex(entity.hexCode) ?? .clear
//        //self.color = Color.fromName(entity.hexCode ?? "white")
//        if entity.isNil {
//            self.emoji = nil
//        } else {
//            self.emoji = entity.emoji ?? ""
//        }
//        
//        self.active = true
//        self.action = CategoryAction.fromString(entity.action!)
//        
//        self.amountString = entity.amount.currencyWithDecimals()
//        //#warning("remove this when Laura installs")
//        //self.type = XrefModel.getItem(from: .categoryTypes, byID: Int(entity.typeID) == 0 ? 27 : Int(entity.typeID))
//        self.type = XrefModel.getItem(from: .categoryTypes, byID: Int(entity.typeID))
//        self.listOrder = Int(entity.listOrder)
//        
////        self.enteredBy = AppState.shared.user!
////        self.updatedBy = AppState.shared.user!
////        self.enteredDate = Date()
////        self.updatedDate = Date()
//        
//        self.enteredBy = AppState.shared.getUserBy(id: Int(entity.enteredByID)) ?? AppState.shared.user!
//        self.updatedBy = AppState.shared.getUserBy(id: Int(entity.updatedByID)) ?? AppState.shared.user!
//        self.enteredDate = entity.enteredDate ?? Date()
//        self.updatedDate = entity.updatedDate ?? Date()
//                                
//        self.isNil = entity.isNil
//        self.isHidden = entity.isHidden
//        if let key = entity.appSuiteKey {
//            self.appSuiteKey = AppSuiteKey.fromString(key)
//        }
//        
//    }
    
    
    /// For Christmas or other special events
    init(title: String, appSuiteKey: AppSuiteKey) {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.title = title
        self.color = .red
        //self.emoji = "questionmark.circle.fill"
        self.active = true
        self.action = .edit
        self.enteredBy = AppState.shared.user!
        self.updatedBy = AppState.shared.user!
        self.enteredDate = Date()
        self.updatedDate = Date()
        
        self.appSuiteKey = appSuiteKey
    }
    
    
//    init(entity: TempCategory) {
//        self.id = entity.id!
//        self.title = entity.title ?? ""
//        self.color = Color.fromHex(entity.hexCode) ?? .clear
//        self.emoji = entity.emoji ?? ""
//        self.active = true
//        self.action = CategoryAction.fromString(entity.action!)
//        
//        self.amountString = entity.amount.currencyWithDecimals()
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
        try container.encode(type.id, forKey: .type_id)
        try container.encode(listOrder, forKey: .list_order)
        try container.encode(enteredBy, forKey: .entered_by) // for the Transferable protocol
        try container.encode(updatedBy, forKey: .updated_by) // for the Transferable protocol
        try container.encode(enteredDate.string(to: .serverDateTime), forKey: .entered_date) // for the Transferable protocol
        try container.encode(updatedDate.string(to: .serverDateTime), forKey: .updated_date) // for the Transferable protocol
        
        try container.encode(isNil ? 1 : 0, forKey: .is_nil) // for the Transferable protocol
        try container.encode(isHidden ? 1 : 0, forKey: .is_hidden)
        try container.encode(appSuiteKey?.rawValue, forKey: .app_suite_key)
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
        self.amountString = amount?.currencyWithDecimals()
        
        //let colorDescription = try container.decode(String?.self, forKey: .hex_code)
        //self.color = Color.fromName(colorDescription ?? "white")
        let hexCode = try container.decode(String?.self, forKey: .hex_code)
        let color = Color.fromHex(hexCode) ?? .primary
        
        if color == .white || color == .black {
            self.color = .primary
        } else {
            self.color = color
        }
        
        self.emoji = try container.decode(String?.self, forKey: .emoji)
        
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1 ? true : false
        
        
        let typeID = try container.decode(Int?.self, forKey: .type_id)
        if let typeID = typeID {
            self.type = XrefModel.getItem(from: .categoryTypes, byID: typeID)
        }
        
        listOrder = try container.decode(Int?.self, forKey: .list_order)
        
        // For the None option
        let isNil = try container.decode(Int?.self, forKey: .is_nil)
        if isNil == nil {
            self.isNil = false
        } else {
            self.isNil = isNil == 1
        }
        
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
        
        
        self.topTitles = try container.decodeIfPresent(Array<CBSuggestedTitle>.self, forKey: .top_titles) ?? []
        
        let isHidden = try container.decode(Int?.self, forKey: .is_hidden)
        self.isHidden = isHidden == 1
        
        if let appSuiteKey = try container.decode(String?.self, forKey: .app_suite_key) {
            self.appSuiteKey = AppSuiteKey.fromString(appSuiteKey)
        }
        
    }
    
    
    
    
    
    static var empty: CBCategory {
        CBCategory()
    }
    
    
    func hasChanges() -> Bool {
        if let deepCopy = deepCopy {
            if self.title == deepCopy.title
            && self.amount == deepCopy.amount
            && self.color == deepCopy.color
            && self.type.id == deepCopy.type.id
            && self.listOrder == deepCopy.listOrder
            && self.isHidden == deepCopy.isHidden
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
            copy.type = self.type
            copy.listOrder = self.listOrder
            copy.isHidden = self.isHidden
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
                self.type = deepCopy.type
                self.isHidden = deepCopy.isHidden
                self.listOrder = deepCopy.listOrder
            }
        case .clear:
            break
        }
    }
    
    
    func setFromAnotherInstance(category: CBCategory) {
        self.title = category.title
        
        self.amountString = category.amount?.currencyWithDecimals()
        
        self.color = category.color
        self.emoji = category.emoji
        self.active = category.active
        self.type = category.type
        self.listOrder = category.listOrder
        self.topTitles = category.topTitles
        self.isHidden = category.isHidden
        
        self.enteredBy = category.enteredBy
        self.updatedBy = category.updatedBy
        self.enteredDate = category.enteredDate
        self.updatedDate = category.updatedDate
        self.appSuiteKey = category.appSuiteKey
    }
    
    
    
    
    
    
    
    static func == (lhs: CBCategory, rhs: CBCategory) -> Bool {
        if lhs.id == rhs.id
            && lhs.uuid == rhs.uuid
            && lhs.title == rhs.title
            && lhs.amount == rhs.amount
            && lhs.color == rhs.color
            && lhs.emoji == rhs.emoji
            && lhs.type == rhs.type
            && lhs.listOrder == rhs.listOrder
            && lhs.isNil == rhs.isNil
            && lhs.isHidden == rhs.isHidden
            && lhs.active == rhs.active {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}



extension CBCategory {
    struct Snapshot: Sendable {
        let id: String
        let title: String
        let hexCode: String?
        let emoji: String?
        let actionRaw: String
        let amount: Double
        let typeID: Int
        let listOrder: Int?
        let enteredByID: Int
        let updatedByID: Int
        let enteredDate: Date?
        let updatedDate: Date?
        let isNil: Bool
        let isHidden: Bool
        let appSuiteKeyRaw: String?
    }

    
    @MainActor
    convenience init(snapshot s: Snapshot) {
        self.init()
        self.id = s.id
        self.title = s.title
        self.color = Color.fromHex(s.hexCode) ?? .clear
        self.emoji = s.isNil ? nil : (s.emoji ?? "")
        self.active = true
        self.action = CategoryAction.fromString(s.actionRaw)
        self.amountString = s.amount.currencyWithDecimals()
        self.type = XrefModel.getItem(from: .categoryTypes, byID: s.typeID)
        self.listOrder = s.listOrder
        self.enteredBy = AppState.shared.getUserBy(id: s.enteredByID) ?? AppState.shared.user!
        self.updatedBy = AppState.shared.getUserBy(id: s.updatedByID) ?? AppState.shared.user!
        self.enteredDate = s.enteredDate ?? Date()
        self.updatedDate = s.updatedDate ?? Date()
        self.isNil = s.isNil
        self.isHidden = s.isHidden
        if let raw = s.appSuiteKeyRaw { self.appSuiteKey = AppSuiteKey.fromString(raw) }
    }

    
    @MainActor
    static func loadFromCoreData(id: String) async -> CBCategory? {
        let snapshot = await CBCategory.createSnapshotFromCoreData(id: id)
        guard let snapshot else { return nil }
        return CBCategory(snapshot: snapshot)
    }
    
    
    @MainActor
    static func createSnapshotFromCoreData(id: String) async -> CBCategory.Snapshot? {
        let context = DataManager.shared.createContext()

        return await DataManager.shared.perform(context: context) {
            guard let entity = DataManager.shared.getOne(context: context, type: PersistentCategory.self, predicate: .byId(.string(id)), createIfNotFound: false) else { return nil }

            return Snapshot(
                id: entity.id ?? "0",
                title: entity.title ?? "",
                hexCode: entity.hexCode,
                emoji: entity.emoji,
                actionRaw: entity.action ?? CategoryAction.edit.rawValue,
                amount: entity.amount,
                typeID: Int(entity.typeID),
                listOrder: Int(entity.listOrder),
                enteredByID: Int(entity.enteredByID),
                updatedByID: Int(entity.updatedByID),
                enteredDate: entity.enteredDate,
                updatedDate: entity.updatedDate,
                isNil: entity.isNil,
                isHidden: entity.isHidden,
                appSuiteKeyRaw: entity.appSuiteKey
            )
        }
    }
}
