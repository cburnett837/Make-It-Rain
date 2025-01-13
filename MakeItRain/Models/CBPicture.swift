//
//  Picture.swift
//  Christmas List
//
//  Created by Cody Burnett on 11/28/23.
//

import Foundation

@Observable
class CBPicture: Codable, Identifiable, Hashable {
    var id: String
    var transactionID: String
    var uuid: String
    var active: Bool
    
    var isPlaceholder: Bool = false
    
    enum CodingKeys: CodingKey { case id, transaction_id, uuid, active, user_id, account_id, device_uuid }
    
    init(transactionID: String, uuid: String) {
        self.id = UUID().uuidString
        self.transactionID = transactionID
        self.uuid = uuid
        self.active = true
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Int(id), forKey: .id) // This weird Int() thing is for the drag and drop
        try container.encode(transactionID, forKey: .transaction_id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(active ? 1 : 0, forKey: .active)
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
        
        do {
            transactionID = try String(container.decode(Int.self, forKey: .transaction_id))
        } catch {
            transactionID = try container.decode(String.self, forKey: .transaction_id)
        }
        
        
        uuid = try container.decode(String.self, forKey: .uuid)
        let active = try container.decode(Int.self, forKey: .active)
        self.active = active == 1 ? true : false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CBPicture, rhs: CBPicture) -> Bool {
        if lhs.uuid == rhs.uuid {return true} else {return false}
    }
}

