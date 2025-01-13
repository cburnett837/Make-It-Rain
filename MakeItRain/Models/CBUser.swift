//
//  CBUser.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/6/24.
//


import Foundation
import SwiftUI

struct CBUser: Codable, Identifiable {
    var id: Int
    var accountID: Int
    var name: String
    var initials: String
    var email: String
    var notificationToken: String = ""
    var hasPaymentMethodsExisiting: Bool = false
    
    enum CodingKeys: CodingKey { case id, account_id, name, initials, email, device_uuid, notification_token, has_payment_methods_existing }
    
//    init() {
//        self.id = 0
//        self.accountID = 0
//        self.name = ""
//        self.email = ""
//    }
//    
//    init() {
//        self.id = 0
//        self.accountID = 0
//        self.name = ""
//        self.email = ""
//    }
        
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(accountID, forKey: .account_id)
        try container.encode(name, forKey: .name)
        try container.encode(initials, forKey: .initials)
        try container.encode(email, forKey: .email)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(notificationToken, forKey: .notification_token)

    }
        
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        accountID = try container.decode(Int.self, forKey: .account_id)
        name = try container.decode(String.self, forKey: .name)
        initials = try container.decode(String.self, forKey: .initials)
        email = try container.decode(String.self, forKey: .email)
        let hasPaymentMethodsExisiting = try container.decodeIfPresent(Int.self, forKey: .has_payment_methods_existing)
        self.hasPaymentMethodsExisiting = hasPaymentMethodsExisiting == 1
    }
}
