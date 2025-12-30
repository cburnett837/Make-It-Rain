//
//  IdSubmitModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/29/25.
//

import Foundation
class IdSubmitModel: Encodable {
    let id: String?
    
    enum CodingKeys: CodingKey { case id, user_id, account_id, device_uuid }
    
    init(id: String?) {
        self.id = id
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)

    }
}
