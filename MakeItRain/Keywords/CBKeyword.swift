//
//  CBKeyword.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/20/24.
//

import Foundation
import SwiftUI
import CoreData

@Observable
class CBKeyword: Codable, Identifiable {
    var id: String
    var uuid: String?
    var keyword: String
    var triggerType: KeywordTriggerType
    var category: CBCategory?
    var active: Bool
    var action: KeywordAction
    var enteredBy: CBUser = AppState.shared.user!
    var updatedBy: CBUser = AppState.shared.user!
    var enteredDate: Date
    var updatedDate: Date
    var renameTo: String?
    var isIgnoredSuggestion: Bool = false
    
    
    /// For deep copies
    init() {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.keyword = ""
        self.triggerType = .contains
        self.category = CBCategory()
        self.active = true
        self.action = .add
        self.enteredBy = AppState.shared.user!
        self.updatedBy = AppState.shared.user!
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    
    /// For new
    init(uuid: String) {
        self.id = uuid
        self.uuid = uuid
        self.keyword = ""
        self.triggerType = .contains
        self.category = nil
        self.active = true
        self.action = .add
        self.enteredBy = AppState.shared.user!
        self.updatedBy = AppState.shared.user!
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    
//    init(entity: PersistentKeyword) {
//        self.id = entity.id!
//        self.keyword = entity.keyword ?? ""
//        self.renameTo = entity.renameTo
//        self.triggerType = KeywordTriggerType(rawValue: entity.triggerType ?? "") ?? .contains
//        
//        if let categoryEntity = entity.category {
//            self.category = CBCategory(entity: categoryEntity)
//        } else {
//            self.category = CBCategory()
//        }
//                
//        self.action = .edit
//        self.active = true
//        self.action = KeywordAction.fromString(entity.action!)
//        //self.enteredBy = AppState.shared.user!
//        //self.updatedBy = AppState.shared.user!
//        //self.enteredDate = Date()
//        //self.updatedDate = Date()
//        
//        self.enteredBy = AppState.shared.getUserBy(id: Int(entity.enteredByID)) ?? AppState.shared.user!
//        self.updatedBy = AppState.shared.getUserBy(id: Int(entity.updatedByID)) ?? AppState.shared.user!
//        self.enteredDate = entity.enteredDate ?? Date()
//        self.updatedDate = entity.updatedDate ?? Date()
//        self.isIgnoredSuggestion = entity.isIgnoredSuggestion
//    }
    
//    init(entity: TempKeyword) {
//        self.id = entity.id!
//        self.keyword = entity.keyword ?? ""
//        self.triggerType = KeywordTriggerType(rawValue: entity.triggerType ?? "") ?? .contains
//        
//        if let categoryEntity = entity.category {
//            self.category = CBCategory(entity: categoryEntity)
//        } else {
//            self.category = CBCategory()
//        }
//                
//        self.active = true
//        self.action = KeywordAction.fromString(entity.action!)
//    }
//    
    
    enum CodingKeys: CodingKey { case id, uuid, keyword, trigger_type, category, category_id, active, user_id, account_id, device_uuid, entered_by, updated_by, entered_date, updated_date, rename_to, is_ignored_suggestion }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(keyword, forKey: .keyword)
        try container.encode(triggerType.rawValue, forKey: .trigger_type)
        try container.encode(category, forKey: .category)
        try container.encode(renameTo, forKey: .rename_to)
        try container.encode(isIgnoredSuggestion ? 1 : 0, forKey: .is_ignored_suggestion)
        //try container.encode(category?.id, forKey: .category_id)
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
        keyword = try container.decode(String.self, forKey: .keyword)
        
        let keywordTriggerType = try container.decode(String.self, forKey: .trigger_type)
        self.triggerType = KeywordTriggerType(rawValue: keywordTriggerType) ?? .contains
        
        self.category = try container.decode(CBCategory?.self, forKey: .category)
        //self.categoryID = try container.decode(String.self, forKey: .category_id)
        
        self.renameTo = try container.decode(String?.self, forKey: .rename_to)
        
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1
        
        let isIgnoredSuggestion = try container.decode(Int?.self, forKey: .is_ignored_suggestion)
        self.isIgnoredSuggestion = isIgnoredSuggestion == 1
        
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
    
    
    static var empty: CBKeyword {
        CBKeyword()
    }
    
    
    func hasChanges() -> Bool {
        if let deepCopy = deepCopy {
            if self.keyword == deepCopy.keyword
            && self.triggerType == deepCopy.triggerType
            && self.renameTo == deepCopy.renameTo
            && self.isIgnoredSuggestion == deepCopy.isIgnoredSuggestion
            && self.category == deepCopy.category {
                return false
            }
        }
        return true
    }
    
    
    var deepCopy: CBKeyword?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let copy = CBKeyword.empty
            copy.id = self.id
            copy.uuid = self.uuid
            copy.keyword = self.keyword
            copy.triggerType = self.triggerType
            copy.category = self.category
            copy.renameTo = self.renameTo
            copy.isIgnoredSuggestion = self.isIgnoredSuggestion
            copy.active = self.active
            //copy.action = self.action
            self.deepCopy = copy
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.uuid = deepCopy.uuid
                self.keyword = deepCopy.keyword
                self.triggerType = deepCopy.triggerType
                self.category = deepCopy.category
                self.renameTo = deepCopy.renameTo
                self.isIgnoredSuggestion = deepCopy.isIgnoredSuggestion
                self.active = deepCopy.active
                //self.action = deepCopy.action
            }
        case .clear:
            break
        }
    }
    
    
    func setFromAnotherInstance(keyword: CBKeyword) {
        self.keyword = keyword.keyword
        self.triggerType = keyword.triggerType
        self.category = keyword.category
        self.renameTo = keyword.renameTo
        self.isIgnoredSuggestion = keyword.isIgnoredSuggestion
        self.active = keyword.active
        
        self.enteredBy = keyword.enteredBy
        self.updatedBy = keyword.updatedBy
        self.enteredDate = keyword.enteredDate
        self.updatedDate = keyword.updatedDate
    }
    
    
    
}


extension CBKeyword: Equatable, Hashable {
    static func == (lhs: CBKeyword, rhs: CBKeyword) -> Bool {
        if lhs.id == rhs.id
        && lhs.uuid == rhs.uuid
        && lhs.keyword == rhs.keyword
        && lhs.triggerType == rhs.triggerType
        && lhs.category == rhs.category
        && lhs.renameTo == rhs.renameTo
        && lhs.isIgnoredSuggestion == rhs.isIgnoredSuggestion
        && lhs.active == rhs.active {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


extension CBKeyword {
    struct Snapshot: Sendable {
        let id: String
        let keyword: String
        let renameTo: String?
        let triggerTypeRaw: String
        let actionRaw: String
        let enteredByID: Int
        let updatedByID: Int
        let enteredDate: Date?
        let updatedDate: Date?
        let isIgnoredSuggestion: Bool
        
        let categoryID: String?
        let categoryTitle: String?
        let categoryAmount: Double?
        let categoryHexCode: String?
        let categoryEmoji: String?
        
        /// Extension contains inits for...
        /// `init(_ keyword: CBKeyword) {}`
        /// `init(_ entity: PersistentKeyword) {}`
    }

    @MainActor
    convenience init(snapshot s: Snapshot, category: CBCategory?) {
        self.init()
        self.id = s.id
        self.keyword = s.keyword
        self.renameTo = s.renameTo
        self.triggerType = KeywordTriggerType(rawValue: s.triggerTypeRaw) ?? .contains
        self.category = category ?? CBCategory()
        self.active = true
        self.action = KeywordAction.fromString(s.actionRaw)
        self.enteredBy = AppState.shared.getUserBy(id: s.enteredByID) ?? AppState.shared.user!
        self.updatedBy = AppState.shared.getUserBy(id: s.updatedByID) ?? AppState.shared.user!
        self.enteredDate = s.enteredDate ?? Date()
        self.updatedDate = s.updatedDate ?? Date()
        self.isIgnoredSuggestion = s.isIgnoredSuggestion
    }
    
    
    @discardableResult
    func updateCoreData(action: KeywordAction, isPending: Bool, createIfNotFound: Bool) async -> Result<Bool, CoreDataError> {
        let snapshot = CBKeyword.Snapshot(self)
        let context = DataManager.shared.createContext()
        
        return await context.perform {
            if let entity = DataManager.shared.getOne(context: context, type: PersistentKeyword.self, predicate: .byId(.string(snapshot.id)), createIfNotFound: createIfNotFound) {
                entity.id = snapshot.id
                entity.keyword = snapshot.keyword
                entity.triggerType = snapshot.triggerTypeRaw
                entity.action = action.rawValue
                entity.isPending = isPending
                entity.renameTo = snapshot.renameTo
                entity.isIgnoredSuggestion = snapshot.isIgnoredSuggestion
                entity.enteredByID = Int64(snapshot.enteredByID)
                entity.updatedByID = Int64(snapshot.updatedByID)
                entity.enteredDate = snapshot.enteredDate
                entity.updatedDate = snapshot.updatedDate
                
                if let categoryID = snapshot.categoryID,
                   let catEnt = DataManager.shared.getOne(context: context, type: PersistentCategory.self, predicate: .byId(.string(categoryID)), createIfNotFound: createIfNotFound) {
                    if catEnt.id == nil {
                        catEnt.id = categoryID
                        catEnt.title = snapshot.categoryTitle
                        catEnt.amount = snapshot.categoryAmount ?? 0.0
                        catEnt.hexCode = snapshot.categoryHexCode
                        catEnt.emoji = snapshot.categoryEmoji
                        catEnt.action = "edit"
                        catEnt.isPending = false
                    }                    
                    
                    entity.category = catEnt
                }
                
                return DataManager.shared.save(context: context)
                
            } else {
                return .failure(.notFound)
            }
        }
    }
    
    
    @discardableResult
    func updateAfterSubmit(id: String, lookupId: String, action: KeywordAction) async -> Result<Bool, CoreDataError> {
        self.action = .edit
        
        if action == .add {
            self.id = id
            self.uuid = nil
        }
        
        let context = DataManager.shared.createContext()
        return await context.perform {
            if let entity = DataManager.shared.getOne(context: context, type: PersistentKeyword.self, predicate: .byId(.string(lookupId)), createIfNotFound: true) {
                if action == .add {
                    entity.id = id
                    entity.action = KeywordAction.edit.rawValue
                }
                entity.isPending = false
                return DataManager.shared.save(context: context)
                
            } else {
                return .failure(.notFound)
            }
        }
    }
    
            
    @MainActor
    static func loadFromCoreData(id: String) async -> CBKeyword? {
        let snapshot = await CBKeyword.createSnapshotFromCoreData(id: id)
        guard let snapshot else { return nil }
        
        let category: CBCategory? = if let categoryID = snapshot.categoryID {
            await CBCategory.loadFromCoreData(id: categoryID)
        } else {
            nil
        }

        return CBKeyword(snapshot: snapshot, category: category)
    }

    
    @MainActor
    static func createSnapshotFromCoreData(id: String) async -> CBKeyword.Snapshot? {
        let context = DataManager.shared.createContext()

        return await DataManager.shared.perform(context: context) {
            guard let entity = DataManager.shared.getOne(context: context, type: PersistentKeyword.self, predicate: .byId(.string(id)), createIfNotFound: false) else { return nil }

            return Snapshot(
                id: entity.id ?? "0",
                keyword: entity.keyword ?? "",
                renameTo: entity.renameTo,
                triggerTypeRaw: entity.triggerType ?? KeywordTriggerType.contains.rawValue,
                actionRaw: entity.action ?? KeywordAction.edit.rawValue,
                enteredByID: Int(entity.enteredByID),
                updatedByID: Int(entity.updatedByID),
                enteredDate: entity.enteredDate,
                updatedDate: entity.updatedDate,
                isIgnoredSuggestion: entity.isIgnoredSuggestion,
                categoryID: entity.category?.id,
                categoryTitle: entity.category?.title,
                categoryAmount: entity.category?.amount ?? 0.0,
                categoryHexCode: entity.category?.hexCode,
                categoryEmoji: entity.category?.emoji
            )
        }
    }
}


extension CBKeyword.Snapshot {
    init(_ keyword: CBKeyword) {
        self.id = keyword.id
        self.keyword = keyword.keyword
        self.renameTo = keyword.renameTo
        self.triggerTypeRaw = keyword.triggerType.rawValue
        self.actionRaw = keyword.action.rawValue
        self.enteredByID = keyword.enteredBy.id
        self.updatedByID = keyword.updatedBy.id
        self.enteredDate = keyword.enteredDate
        self.updatedDate = keyword.updatedDate
        self.isIgnoredSuggestion = keyword.isIgnoredSuggestion
        self.categoryID = keyword.category?.id
        self.categoryTitle = keyword.category?.title
        self.categoryAmount = keyword.category?.amount ?? 0.0
        self.categoryHexCode = keyword.category?.color.toHex()
        self.categoryEmoji = keyword.category?.emoji
        
    }

    init(_ entity: PersistentKeyword) {
        self.id = entity.id ?? ""
        self.keyword = entity.keyword ?? ""
        self.renameTo = entity.renameTo
        self.triggerTypeRaw = entity.triggerType ?? ""
        self.actionRaw = entity.action ?? ""
        self.enteredByID = Int(entity.enteredByID)
        self.updatedByID = Int(entity.updatedByID)
        self.enteredDate = entity.enteredDate
        self.updatedDate = entity.updatedDate
        self.isIgnoredSuggestion = entity.isIgnoredSuggestion
        self.categoryID = entity.category?.id
        self.categoryTitle = entity.category?.title
        self.categoryAmount = entity.category?.amount ?? 0.0
        self.categoryHexCode = entity.category?.hexCode
        self.categoryEmoji = entity.category?.emoji
    }
}
