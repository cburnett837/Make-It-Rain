//
//  CBCategoryGroup.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/25/25.
//

import Foundation
import SwiftUI

@Observable
class CBCategoryGroup: Codable, Identifiable, Hashable, Equatable {
    var id: String
    var uuid: String?
    var title: String
    var amount: Double? {
        Double(amountString?.replacing("$", with: "").replacing(",", with: "") ?? "0.0") ?? 0.0
    }
    var amountString: String?
    var categories: [CBCategory] = []
    var active: Bool
    var action: CategoryGroupAction
    var enteredBy: CBUser = AppState.shared.user!
    var updatedBy: CBUser = AppState.shared.user!
    var enteredDate: Date
    var updatedDate: Date
    
    enum CodingKeys: CodingKey { case id, uuid, title, amount, categories, active, user_id, account_id, device_uuid, entered_by, updated_by, entered_date, updated_date }
        
    init() {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.title = ""
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
        self.active = true
        self.action = .add
        self.enteredBy = AppState.shared.user!
        self.updatedBy = AppState.shared.user!
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    
//    init(entity: PersistentCategoryGroup) {
//        self.id = entity.id!
//        self.title = entity.title ?? ""
//        self.active = true
//        self.action = CategoryGroupAction.fromString(entity.action!)
//        
//        self.amountString = entity.amount.currencyWithDecimals()
//        //#warning("remove this when Laura installs")
//        
//        self.enteredBy = AppState.shared.getUserBy(id: Int(entity.enteredByID)) ?? AppState.shared.user!
//        self.updatedBy = AppState.shared.getUserBy(id: Int(entity.updatedByID)) ?? AppState.shared.user!
//        self.enteredDate = entity.enteredDate ?? Date()
//        self.updatedDate = entity.updatedDate ?? Date()
//                            
//        
//        if let set = entity.categories as? Set<PersistentCategory> {
//            self.categories = set
//                .map { CBCategory(entity: $0) }
//                .sorted { $0.listOrder ?? 0 < $1.listOrder ?? 0 }
//        } else {
//            self.categories = []
//        }                        
//    }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(title, forKey: .title)
        try container.encode(amount, forKey: .amount)
        try container.encode(categories, forKey: .categories)
        try container.encode(active ? 1 : 0, forKey: .active)
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
        title = try container.decode(String.self, forKey: .title)
        
        let amount = try container.decode(Double?.self, forKey: .amount)
        self.amountString = amount?.currencyWithDecimals()
                
        self.categories = try container.decode(Array<CBCategory>.self, forKey: .categories)
        
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
            if self.title == deepCopy.title
            && self.amount == deepCopy.amount
            && self.categories == deepCopy.categories {
                return false
            }
        }
        return true
    }
    
    
    var deepCopy: CBCategoryGroup?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let copy = CBCategoryGroup()
            copy.id = self.id
            copy.uuid = self.uuid
            copy.title = self.title
            copy.amountString = self.amountString
            copy.categories = self.categories.compactMap ({ $0.deepCopy(.create); return $0.deepCopy })
            copy.active = self.active
            copy.action = self.action
            self.deepCopy = copy
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.uuid = deepCopy.uuid
                self.title = deepCopy.title
                self.amountString = deepCopy.amountString
                self.categories = deepCopy.categories
                self.active = deepCopy.active
                self.action = deepCopy.action
            }
        case .clear:
            break
        }
    }
    
    
    func setFromAnotherInstance(group: CBCategoryGroup) {
        self.title = group.title
        self.amountString = group.amount?.currencyWithDecimals()
        self.categories = group.categories
        self.active = group.active
    }
    
    
    
    
    
    
    
    static func == (lhs: CBCategoryGroup, rhs: CBCategoryGroup) -> Bool {
        if lhs.id == rhs.id
            && lhs.uuid == rhs.uuid
            && lhs.title == rhs.title
            && lhs.amount == rhs.amount
            && lhs.categories == rhs.categories
            && lhs.active == rhs.active {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


import CoreData

extension CBCategoryGroup {
    struct Snapshot: Sendable {
        let id: String
        let title: String
        let amount: Double
        let actionRaw: String
        let enteredByID: Int
        let updatedByID: Int
        let enteredDate: Date?
        let updatedDate: Date?
        let categoryIDs: [String]
    }

    @MainActor
    convenience init(snapshot s: Snapshot, categories: [CBCategory]) {
        self.init()
        self.id = s.id
        self.title = s.title
        self.active = true
        self.action = CategoryGroupAction.fromString(s.actionRaw)
        self.amountString = s.amount.currencyWithDecimals()
        self.enteredBy = AppState.shared.getUserBy(id: s.enteredByID) ?? AppState.shared.user!
        self.updatedBy = AppState.shared.getUserBy(id: s.updatedByID) ?? AppState.shared.user!
        self.enteredDate = s.enteredDate ?? Date()
        self.updatedDate = s.updatedDate ?? Date()
        self.categories = categories.sorted { ($0.listOrder ?? 0) < ($1.listOrder ?? 0) }
    }

    @MainActor
    static func loadFromCoreData(id: String) async -> CBCategoryGroup? {
        let context = DataManager.shared.createContext()

        let snapshot: Snapshot? = await DataManager.shared.perform(context: context) {
            guard let entity = DataManager.shared.getOne(
                context: context,
                type: PersistentCategoryGroup.self,
                predicate: .byId(.string(id)),
                createIfNotFound: false
            ) else { return nil }

            let categoryIDs: [String]
            if let set = entity.categories as? Set<PersistentCategory> {
                categoryIDs = set.compactMap(\.id)
            } else {
                categoryIDs = []
            }

            return Snapshot(
                id: entity.id ?? "0",
                title: entity.title ?? "",
                amount: entity.amount,
                actionRaw: entity.action ?? CategoryGroupAction.edit.rawValue,
                enteredByID: Int(entity.enteredByID),
                updatedByID: Int(entity.updatedByID),
                enteredDate: entity.enteredDate,
                updatedDate: entity.updatedDate,
                categoryIDs: categoryIDs
            )
        }

        guard let snapshot else { return nil }

        var categories: [CBCategory] = []
        categories.reserveCapacity(snapshot.categoryIDs.count)

        for categoryID in snapshot.categoryIDs {
            if let category = await CBCategory.loadFromCoreData(id: categoryID) {
                categories.append(category)
            }
        }

        return CBCategoryGroup(snapshot: snapshot, categories: categories)
    }
}
