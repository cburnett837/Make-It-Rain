//
//  CheckIfShouldDownloadModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/1/25.
//


import Foundation

class CheckIfShouldDownloadModel: Codable {
    var shouldDownload: Bool = false
    var lastNetworkTime: String?
    
    enum CodingKeys: CodingKey { case user_id, account_id, device_uuid, should_download, last_network_time }
    
    init(lastNetworkTime: Date) {
        self.lastNetworkTime = lastNetworkTime.string(to: .serverDateTime)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(lastNetworkTime, forKey: .last_network_time)
    }
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let result = try container.decode(Int?.self, forKey: .should_download)
        self.shouldDownload = result == 1 ? true : false
    }
}
