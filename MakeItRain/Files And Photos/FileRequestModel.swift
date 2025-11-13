//
//  FileRequestModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 6/5/25.
//


import Foundation
import Foundation

class FileRequestModel: Encodable {
    var sessionID = ""
    var path = ""
    
    enum CodingKeys: CodingKey { case path, session_id, user_id, account_id, device_uuid }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(path, forKey: .path)
        try container.encode(sessionID, forKey: .session_id)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
    }
    
    init(path: String) {
        self.path = path
    }
}
