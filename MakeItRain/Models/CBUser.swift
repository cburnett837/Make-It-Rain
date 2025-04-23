//
//  CBUser.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/6/24.
//


import Foundation
import SwiftUI

class CBUser: Codable, Identifiable, Hashable, Equatable {
    var id: Int
    var accountID: Int
    var name: String
    var initials: String
    var email: String
    var notificationToken: String = ""
    //var hasPaymentMethodsExisiting: Bool = false
    
    enum CodingKeys: CodingKey { case id, account_id, name, initials, email, device_uuid, notification_token }
    
    init() {
        self.id = 0
        self.accountID = 0
        self.name = ""
        self.email = ""
        self.initials = ""
    }
        
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
        
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        accountID = try container.decode(Int.self, forKey: .account_id)
        name = try container.decode(String.self, forKey: .name)
        initials = try container.decode(String.self, forKey: .initials)
        email = try container.decode(String.self, forKey: .email)
        //let hasPaymentMethodsExisiting = try container.decodeIfPresent(Int.self, forKey: .has_payment_methods_existing)
        //self.hasPaymentMethodsExisiting = hasPaymentMethodsExisiting == 1
    }
    
    
    var deepCopy: CBUser?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let copy = CBUser()
            copy.id = self.id
            copy.accountID = self.accountID
            copy.name = self.name
            copy.initials = self.initials
            copy.email = self.email
            self.deepCopy = copy
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.accountID = deepCopy.accountID
                self.name = deepCopy.name
                self.initials = deepCopy.initials
                self.email = deepCopy.email
            }
        case .clear:
            break
        }
    }
    
    
    
    static func == (lhs: CBUser, rhs: CBUser) -> Bool {
        if lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.email == rhs.email {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    
    var isLoggedIn: Bool {
        AppState.shared.user?.id == self.id
    }
    
    var isNotLoggedIn: Bool {
        AppState.shared.user?.id != self.id
    }
    
    func `is`(_ user: CBUser?) -> Bool {
        if let user {
            return self.id == user.id
        } else {
            return false
        }
    }
    
    func isNot(_ user: CBUser?) -> Bool {
        if let user {
            return self.id != user.id
        } else {
            return true
        }
    }
    
}





struct CBLogin: Decodable {
    var accountID: Int
    var user: CBUser
    var accountUsers: [CBUser]
    var hasPaymentMethodsExisiting: Bool = false
    var apiKey: String?
    
    enum CodingKeys: CodingKey { case account_id, user, account_users, has_payment_methods_existing, api_key }
        
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accountID = try container.decode(Int.self, forKey: .account_id)
        user = try container.decode(CBUser.self, forKey: .user)
        accountUsers = try container.decode(Array<CBUser>.self, forKey: .account_users)
        apiKey = try container.decode(String?.self, forKey: .api_key)
        let hasPaymentMethodsExisiting = try container.decodeIfPresent(Int.self, forKey: .has_payment_methods_existing)
        self.hasPaymentMethodsExisiting = hasPaymentMethodsExisiting == 1
    }
}
