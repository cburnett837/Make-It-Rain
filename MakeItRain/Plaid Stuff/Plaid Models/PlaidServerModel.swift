//
//  PlaidModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/21/25.
//

import Foundation

class PlaidServerModel: Codable {
    var token: String?
    var bank: CBPlaidBank?
    var institutionID: String?
    var linkMode: PlaidLinkMode?
    var rowNumber: Int?
    
    init(token: String? = nil, bank: CBPlaidBank? = nil, institutionID: String? = nil, linkMode: PlaidLinkMode? = nil, rowNumber: Int? = nil) {
        self.token = token
        self.bank = bank
        self.institutionID = institutionID
        self.linkMode = linkMode
        self.rowNumber = rowNumber
    }
    
    enum CodingKeys: CodingKey { case token, bank, institution_id, link_mode, user_id, account_id, device_uuid, row_number }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(token, forKey: .token)
        try container.encode(bank, forKey: .bank)
        try container.encode(institutionID, forKey: .institution_id)
        try container.encode(linkMode?.rawValue, forKey: .link_mode)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(rowNumber, forKey: .row_number)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        token = try container.decode(String?.self, forKey: .token)
        institutionID = try container.decode(String?.self, forKey: .institution_id)
    }
}

