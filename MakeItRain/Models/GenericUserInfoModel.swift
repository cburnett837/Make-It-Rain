//
//  GenericUserInfoModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/14/26.
//


import SwiftUI

struct GenericUserInfoModel: Encodable {
    enum CodingKeys: CodingKey { case user_id, account_id, device_uuid }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Cody.shared.id, forKey: .user_id)
        try container.encode(Cody.shared.accountID, forKey: .account_id)
        try container.encode(Cody.shared.deviceUUID, forKey: .device_uuid)
    }
}
