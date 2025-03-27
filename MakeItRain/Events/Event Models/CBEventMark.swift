//
//  Untitled.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/26/25.
//
import Foundation

class CBEventViewMode: Codable {
    var id: String = UUID().uuidString
    var eventID: String
    var mode: EventViewMode
    var user: CBUser = AppState.shared.user!

    init(eventID: String, mode: EventViewMode) {
        self.eventID = eventID
        self.mode = mode
    }

    enum CodingKeys: CodingKey { case event_id, user_id, account_id, device_uuid, mode, user }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eventID, forKey: .event_id)
        try container.encode(mode.rawValue, forKey: .mode)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
    }
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        user = try container.decode(CBUser.self, forKey: .user)
        
        
        do {
            eventID = try String(container.decode(Int.self, forKey: .event_id))
        } catch {
            eventID = try container.decode(String.self, forKey: .event_id)
        }
        
        
        self.mode = .open
    }
}
