//
//  CBLogin.swift
//  MakeItRain
//
//  Created by Cody Burnett on 12/30/25.
//


import Foundation
import SwiftUI

struct CBLogin: Decodable {
    var accountID: Int
    var user: CBUser
    var accountUsers: [CBUser]
    var hasPaymentMethodsExisiting: Bool = false
    var apiKey: String?
    //var settings: AppSettings
    
    enum CodingKeys: CodingKey { case account_id, user, account_users, has_payment_methods_existing, api_key/*, settings*/ }
        
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accountID = try container.decode(Int.self, forKey: .account_id)
        user = try container.decode(CBUser.self, forKey: .user)
        accountUsers = try container.decode(Array<CBUser>.self, forKey: .account_users)
        apiKey = try container.decode(String?.self, forKey: .api_key)
        let hasPaymentMethodsExisiting = try container.decodeIfPresent(Int.self, forKey: .has_payment_methods_existing)
        self.hasPaymentMethodsExisiting = hasPaymentMethodsExisiting == 1
        //self.settings = try container.decode(AppSettings.self, forKey: .settings)
    }
}
