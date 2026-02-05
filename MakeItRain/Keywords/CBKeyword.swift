//
//  CBKeyword.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/20/24.
//

import Foundation
import SwiftUI
import GRDB

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
    
    init(entity: PersistentKeyword) {
        self.id = entity.id!
        self.keyword = entity.keyword ?? ""
        self.renameTo = entity.renameTo
        self.triggerType = KeywordTriggerType(rawValue: entity.triggerType ?? "") ?? .contains
        
        if let categoryEntity = entity.category {
            self.category = CBCategory(entity: categoryEntity)
        } else {
            self.category = CBCategory()
        }
                
        self.action = .edit
        self.active = true
        self.action = KeywordAction.fromString(entity.action!)
        //self.enteredBy = AppState.shared.user!
        //self.updatedBy = AppState.shared.user!
        //self.enteredDate = Date()
        //self.updatedDate = Date()
        
        self.enteredBy = AppState.shared.getUserBy(id: Int(entity.enteredByID)) ?? AppState.shared.user!
        self.updatedBy = AppState.shared.getUserBy(id: Int(entity.updatedByID)) ?? AppState.shared.user!
        self.enteredDate = entity.enteredDate ?? Date()
        self.updatedDate = entity.updatedDate ?? Date()
        self.isIgnoredSuggestion = entity.isIgnoredSuggestion
    }
    
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

//
//extension CBKeyword: PersistableRecord, FetchableRecord {
//    enum Columns {
//        static var keyword = Column(CodingKeys.keyword)
//        static var triggerType = Column(CodingKeys.trigger_type)
//        static var categoryID = Column(CodingKeys.category_id)
//        static var active = Column(CodingKeys.active)
//        static var enteredBy = Column(CodingKeys.entered_by)
//        static var updatedBy = Column(CodingKeys.updated_by)
//        static var enteredDate = Column(CodingKeys.entered_date)
//        static var updatedDate = Column(CodingKeys.updated_date)
//    }
//}
