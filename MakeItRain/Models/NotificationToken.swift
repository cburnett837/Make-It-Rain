//
//  NotificationToken.swift
//  JarvisPhoneApp
//
//  Created by Cody Burnett on 8/17/24.
//

import Foundation
import SwiftUI

class NotificationToken: Encodable {
    @AppStorage("deviceName") var deviceName = ""
    //var deviceName: String? = "iphone_mine"
    var token: String? = ""
    
    enum CodingKeys: CodingKey { case token, device_name }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(token, forKey: .token)
        try container.encode(deviceName, forKey: .device_name)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        token = try container.decode(String.self, forKey: .token)
    }
    
    init(token: String) {
        self.token = token
    }
}
