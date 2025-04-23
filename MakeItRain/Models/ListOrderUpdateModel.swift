//
//  ListOrderUpdateModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/1/25.
//


import Foundation

struct ListOrderUpdate: Encodable {
    var id: String
    var listorder: Int
    
    enum CodingKeys: CodingKey { case id, list_order }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(listorder, forKey: .list_order)
    }
}

class ListOrderUpdateModel: Encodable {
    let items: Array<ListOrderUpdate>
    let updateType: ListOrderUpdateType
    
    enum CodingKeys: CodingKey { case items, user_id, account_id, device_uuid, update_type }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(items, forKey: .items)
        try container.encode(updateType.rawValue, forKey: .update_type)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
    }
    
    init(items: Array<ListOrderUpdate>, updateType: ListOrderUpdateType) {
        self.items = items
        self.updateType = updateType
    }
}
