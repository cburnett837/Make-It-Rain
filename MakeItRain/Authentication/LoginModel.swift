//
//  Credentials.swift
//  Transport Explorer
//
//  Created by Cody Burnett on 8/24/23.
//

import Foundation
//
//struct ServerCredentials: Codable {
//    public var userID: Int?
//    public var accountID: Int?
//    public var userName: String?
//    public var email: String?
//    
//    enum CodingKeys: CodingKey { case id, account_id, username, email, user_id }
//    
//    init() {
//        self.userID = AppState.shared.userID
//        self.accountID = AppState.shared.userAccountID
//    }
//    
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(userID, forKey: .user_id)
//        try container.encode(accountID, forKey: .account_id)
//    }
//    
//            
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        userID = try container.decode(Int?.self, forKey: .id)
//        accountID = try container.decode(Int?.self, forKey: .account_id)
//        userName = try container.decode(String?.self, forKey: .username)
//        email = try container.decode(String?.self, forKey: .email)
//    }
//}

struct LoginModel: Codable {
    var email: String?
    var password: String?
    var apiKey: String?
}

//
//struct AccountFetchModel: Codable {
//    var userID: String
//    var accountID: String
//}
