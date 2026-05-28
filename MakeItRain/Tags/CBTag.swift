//
//  CBTag.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/18/24.
//


import Foundation
import SwiftUI

@Observable
class CBTag: Codable, Identifiable {
    var id: String
    var uuid: String
    var title: String
    var active: Bool
    var action: TagAction
    var isNew = false
    var isHidden: Bool = false
    var amountString: String? /// Just here for ``BudgetItem`` Protocol Conformance
    
    init() {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.title = ""
        self.active = true
        self.action = .add
        self.isNew = true
    }
    
    init(tag: String) {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.title = tag
        self.active = true
        self.action = .add
        self.isNew = true
    }
    
    enum CodingKeys: CodingKey { case id, uuid, title, active, user_id, account_id, device_uuid, is_new, is_hidden }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Int(id), forKey: .id) // This weird Int() thing is for the drag and drop
        try container.encode(uuid, forKey: .uuid)
        try container.encode(title, forKey: .title)
        try container.encode(active ? 1 : 0, forKey: .active)
        try container.encode(isNew ? 1 : 0, forKey: .is_new)
        try container.encode(isHidden ? 1 : 0, forKey: .is_hidden)
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
        self.uuid = ""
        //uuid = try container.decode(String.self, forKey: .uuid)
        title = try container.decode(String.self, forKey: .title)
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1 ? true : false
        self.isNew = false
        
        let isHidden = try container.decode(Int?.self, forKey: .is_hidden)
        self.isHidden = isHidden == 1 ? true : false
        
        action = .edit
    }
    
    func hasChanges() -> Bool {
        if let deepCopy = deepCopy {
            if self.title == deepCopy.title {
                return false
            }
        }
        return true
    }
    
    
    var deepCopy: CBTag?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let copy = CBTag()
            copy.id = self.id
            copy.title = self.title
            copy.isHidden = self.isHidden
            copy.active = self.active
            self.deepCopy = copy
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.title = deepCopy.title
                self.isHidden = deepCopy.isHidden
                self.active = deepCopy.active
                //self.action = deepCopy.action
            }
        case .clear:
            break
        }
    }
    
    
    func setFromAnotherInstance(tag: CBTag) {
        self.id = tag.id
        self.title = tag.title
        self.active = tag.active
        self.isNew = tag.isNew
        self.isHidden = tag.isHidden
    }
    
    
    static func == (lhs: CBTag, rhs: CBTag) -> Bool {
        if lhs.id == rhs.id
        && lhs.title == rhs.title
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
