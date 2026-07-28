//
//  WatchStuff.swift
//  MakeItRain
//
//  Created by Cody Burnett on 6/28/26.
//

import Foundation
import WidgetKit



struct PlaidResult: Codable {
    var isPlaceholder: Bool
    var count: Int
    var trans: [PlaidTransLite]
    
    enum CodingKeys: CodingKey {
        case count, trans
    }
    
    init (isPlaceholder: Bool, count: Int, trans: [PlaidTransLite]) {
        self.isPlaceholder = isPlaceholder
        self.count = count
        self.trans = trans
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        count = try container.decode(Int.self, forKey: .count)
        trans = try container.decode(Array<PlaidTransLite>.self, forKey: .trans)
        isPlaceholder = false
    }
}


struct PlaidTransLite: Identifiable, Codable {
    var id: Int
    var title: String
    var amountString: String
    var payMethodId: Int
    var logo: Data?

    var amount: Double {
        Double(amountString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
    }

    enum CodingKeys: CodingKey {
        case id, title, amount, payment_method_id, logo
    }

    init(id: Int, title: String, amount: String, payMethodId: Int, logo: Data? = nil) {
        self.id = id
        self.title = title
        self.amountString = amount
        self.payMethodId = payMethodId
        self.logo = logo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        amountString = try container.decode(String.self, forKey: .amount)
        payMethodId = try container.decode(Int.self, forKey: .payment_method_id)
        logo = try container.decodeIfPresent(Data.self, forKey: .logo)
    }
    
    /// Needed to store in the cache.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(amountString, forKey: .amount)
        try container.encode(payMethodId, forKey: .payment_method_id)
        try container.encodeIfPresent(logo, forKey: .logo)
    }
}


extension Double {
    func currencyWithDecimals() -> String {
        formatted(
            .currency(code: "USD")
            .precision(.fractionLength(0))
        )
    }
}



struct CBUser: Decodable, Identifiable, Encodable {
    var id: Int
    var accountID: Int
    var name: String
    var initials: String
    var email: String
    
    enum CodingKeys: CodingKey { case id, account_id, name, initials, email, avatar, device_uuid, year }
    
    init(id: Int, accountID: Int, name: String, initials: String, email: String) {
        self.id = id
        self.accountID = accountID
        self.name = name
        self.initials = initials
        self.email = email
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(accountID, forKey: .account_id)
        try container.encode(name, forKey: .name)
        try container.encode(initials, forKey: .initials)
        try container.encode(email, forKey: .email)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        accountID = try container.decode(Int.self, forKey: .account_id)
        name = try container.decode(String.self, forKey: .name)
        initials = try container.decode(String.self, forKey: .initials)
        email = try container.decode(String.self, forKey: .email)
    }
}


struct CBNotificationToken: Encodable {
    var id: Int?
    var userID: Int?
    var accountID: Int?
    var deviceUUID: String?
    var notificationToken: String = ""
    
    enum CodingKeys: CodingKey { case id, user_id, account_id, device_uuid, notification_token }
    
    init(token: String) {
        self.notificationToken = token
        
        if let ud = UserDefaults(suiteName: "group.dev.cburnett837.MakeItRain")?.data(forKey: "user") {
            do {
                let user = try JSONDecoder().decode(CBUser.self, from: ud)
                self.id = user.id
                self.userID = user.id
                self.accountID = user.accountID
            } catch {
                print("Unable to Decode User (\(error))")
            }
        }
        
        if let uuid = UserDefaults(suiteName: "group.dev.cburnett837.MakeItRain")?.string(forKey: "deviceUUID") {
            self.deviceUUID = uuid
        }
    }
        
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(1, forKey: .user_id)
        try container.encode(1, forKey: .account_id)
        try container.encode(deviceUUID, forKey: .device_uuid)
        try container.encode(notificationToken, forKey: .notification_token)

    }
}



enum BudgetWidgetAPI {
    static func fetchBudgetData() async -> PlaidResult? {
        print("I should download")
        //return []
        
        //guard let apiKey = KeychainHelper.readAuthToken() else { return nil }
        //let apiKey = "O1D3ulL8J_MvBJNy3dmY3au5aLKkI9hvxbQ2-cDUvCk"
        
        var apiKey: String? = nil
        do {
            apiKey = try KeychainManager().getFromKeychain(key: "api_key")
        } catch {
            print(error.localizedDescription)
        }
        
        guard let apiKey else {
            print("Api key was not set!")
            return nil
        }
        
        let earl = String(format: "\(Keys.prodBaseURL)/budget_app")
        let url = URL(string: earl)
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "Api-Key")
        request.setValue(Keys.authPhrase, forHTTPHeaderField: "Auth-Phrase")
        request.setValue(Keys.authID, forHTTPHeaderField: "Auth-ID")
        request.setValue(Keys.userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 60
        
        guard let token = await WidgetCenter.shared.currentPushInfo?.token.map({ String(format: "%02x", $0) }).joined() else { return nil }
        print(token)
        
        let tokenModel = CBNotificationToken(token: token)
        let requestModel = RequestModel(requestType: "download_plaid_trans_for_widget", model: tokenModel)

        do {
            let jsonData = try! JSONEncoder().encode(requestModel)
            request.httpBody = jsonData
            let (data, response) = try await URLSession.shared.data(for: request)
            
            print("jsonData: \(String(data: data, encoding: .utf8)!)")

            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { return nil }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            return try! decoder.decode(PlaidResult?.self, from: data)
        } catch {
            return nil
        }
    }

    
    static func registerWidgetPushToken(token: String) async {
        struct Body: Codable {
            let token: String
            let widgetKind: String
        }
        
        print("The widget token is \(token)")
        
        if let bundleID = Bundle.main.bundleIdentifier {
            print("Bundle ID: \(bundleID)")
        } else {
            print("Could not retrieve bundle identifier.")
        }
        
        let tokenModel = CBNotificationToken(token: token)
        let requestModel = RequestModel(requestType: "add_new_notification_token_for_widget", model: tokenModel)
        
        var apiKey: String? = nil
        do {
            apiKey = try KeychainManager().getFromKeychain(key: "api_key")
        } catch {
            print(error.localizedDescription)
        }
        
        guard let apiKey else {
            print("Api key was not set!")
            return
        }
        
        //let apiKey = "O1D3ulL8J_MvBJNy3dmY3au5aLKkI9hvxbQ2-cDUvCk"
        
        let earl = String(format: "\(Keys.prodBaseURL)/budget_app")
        let url = URL(string: earl)
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "Api-Key")
        request.setValue(Keys.authPhrase, forHTTPHeaderField: "Auth-Phrase")
        request.setValue(Keys.authID, forHTTPHeaderField: "Auth-ID")
        request.setValue(Keys.userAgent, forHTTPHeaderField: "User-Agent")

        do {
            let jsonData = try! JSONEncoder().encode(requestModel)
            request.httpBody = jsonData
            _ = try await URLSession.shared.data(for: request)
        } catch {
            // Widget extensions should fail silently.
        }
    }
}
