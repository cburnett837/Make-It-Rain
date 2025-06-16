//
//  CBNotificationToken.swift
//  MakeItRain
//
//  Created by Cody Burnett on 6/12/25.
//

import Foundation

class CBNotificationToken: Encodable {
    var id: Int
    var accountID: Int
    var notificationToken: String = ""
    //var hasPaymentMethodsExisiting: Bool = false
    
    enum CodingKeys: CodingKey { case id, account_id, device_uuid, notification_token }
    
    init(user: CBUser, token: String) {
        self.id = user.id
        self.accountID = user.accountID
        self.notificationToken = token
    }
        
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(notificationToken, forKey: .notification_token)

    }
}


