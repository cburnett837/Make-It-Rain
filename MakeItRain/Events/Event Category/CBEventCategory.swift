//
//  CBEventCategory.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/26/25.
//

import Foundation
import SwiftUI

@Observable
class CBEventCategory: Codable, Identifiable, Hashable, Equatable {
    var id: String
    var uuid: String?
    var eventID: String
    var title: String
    var color: Color
    var emoji: String?
    var listOrder: Int?
    var active: Bool
    var action: EventCategoryAction
    
    enum CodingKeys: CodingKey { case id, uuid, event_id, title, hex_code, emoji, active, user_id, account_id, device_uuid, action, list_order }
        
    init(eventID: String) {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.eventID = eventID
        self.title = ""
        self.color = .primary
        self.active = true
        self.action = .add
    }
    
    init(uuid: String, eventID: String) {
        self.id = uuid
        self.uuid = uuid
        self.eventID = eventID
        self.title = ""
        self.color = .primary
        self.active = true
        self.action = .add
    }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(eventID, forKey: .event_id)
        try container.encode(title, forKey: .title)
        try container.encode(color.toHex(), forKey: .hex_code)
        //try container.encode(color.description, forKey: .hex_code)
        try container.encode(emoji, forKey: .emoji)
        try container.encode(listOrder, forKey: .list_order)
        try container.encode(active ? 1 : 0, forKey: .active)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(action.serverKey, forKey: .action)
    }
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            id = try String(container.decode(Int.self, forKey: .id))
        } catch {
            id = try container.decode(String.self, forKey: .id)
        }
        
        do {
            eventID = try String(container.decode(Int.self, forKey: .event_id))
        } catch {
            eventID = try container.decode(String.self, forKey: .event_id)
        }
        
        title = try container.decode(String.self, forKey: .title)
                
        let hexCode = try container.decode(String?.self, forKey: .hex_code)
        self.color = Color.fromHex(hexCode) ?? .primary
        
        self.emoji = try container.decode(String?.self, forKey: .emoji)
        
        listOrder = try container.decode(Int?.self, forKey: .list_order)
        
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1 ? true : false
                
        action = .edit
    }
       
    
    
    func hasChanges() -> Bool {
        if let deepCopy = deepCopy {
            if self.title == deepCopy.title
            && self.color == deepCopy.color
            && self.listOrder == deepCopy.listOrder
            && self.emoji == deepCopy.emoji {
                return false
            }
        }
        return true
    }
    
    
    var deepCopy: CBEventCategory?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let copy = CBEventCategory(uuid: UUID().uuidString, eventID: self.eventID)
            copy.id = self.id
            copy.uuid = self.uuid
            copy.eventID = self.eventID
            copy.title = self.title
            copy.color = self.color
            copy.emoji = self.emoji
            copy.listOrder = self.listOrder
            copy.active = self.active
            copy.action = self.action
            self.deepCopy = copy
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.uuid = deepCopy.uuid
                self.eventID = deepCopy.eventID
                self.title = deepCopy.title
                self.color = deepCopy.color
                self.emoji = deepCopy.emoji
                self.listOrder = deepCopy.listOrder
                self.active = deepCopy.active
                self.action = deepCopy.action
            }
        case .clear:
            break
        }
    }
    
    
    func setFromAnotherInstance(category: CBEventCategory) {
        self.id = category.id
        self.uuid = category.uuid
        self.eventID = category.eventID
        self.title = category.title
        self.color = category.color
        self.emoji = category.emoji
        self.listOrder = category.listOrder
        self.active = category.active
    }
    
    
    
    
    
    
    
    static func == (lhs: CBEventCategory, rhs: CBEventCategory) -> Bool {
        if lhs.id == rhs.id
        && lhs.uuid == rhs.uuid
        && lhs.eventID == rhs.eventID
        && lhs.title == rhs.title
        && lhs.color == rhs.color
        && lhs.emoji == rhs.emoji
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
