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
    var tag: String
    var active: Bool
    var action: TagAction
    var isNew = false
    
    init() {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.tag = ""
        self.active = true
        self.action = .add
        self.isNew = true
    }
    
    init(tag: String) {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.tag = tag
        self.active = true
        self.action = .add
        self.isNew = true
    }
    
    enum CodingKeys: CodingKey { case id, uuid, tag, active, user_id, account_id, device_uuid, is_new }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Int(id), forKey: .id) // This weird Int() thing is for the drag and drop
        try container.encode(uuid, forKey: .uuid)
        try container.encode(tag, forKey: .tag)
        try container.encode(active ? 1 : 0, forKey: .active)
        try container.encode(isNew ? 1 : 0, forKey: .is_new)
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
        self.uuid = ""
        //uuid = try container.decode(String.self, forKey: .uuid)
        tag = try container.decode(String.self, forKey: .tag)
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1 ? true : false
        self.isNew = false
        
        action = .edit
    }
    
    
    static var empty: CBTag {
        CBTag()
    }
    
    
    func hasChanges() -> Bool {
        if let deepCopy = deepCopy {
            if self.tag == deepCopy.tag {
                return false
            }
        }
        return true
    }
    
    
    var deepCopy: CBTag?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let copy = CBTag.empty
            copy.id = self.id
            copy.tag = self.tag
            copy.active = self.active
            self.deepCopy = copy
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.tag = deepCopy.tag
                self.active = deepCopy.active
                //self.action = deepCopy.action
            }
        case .clear:
            break
        }
    }
    
    
    func setFromAnotherInstance(tag: CBTag) {
        self.tag = tag.tag
        self.active = tag.active
    }
    
    
    
}


extension CBTag: Equatable, Hashable {
    static func == (lhs: CBTag, rhs: CBTag) -> Bool {
        if lhs.id == rhs.id
        && lhs.tag == rhs.tag
        && lhs.active == rhs.active {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


import Foundation
