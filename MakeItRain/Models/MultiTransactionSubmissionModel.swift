//
//  MultiTransactionSubmissionModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/28/25.
//

import Foundation
struct MultiTransactionSubmissionModel: Encodable {
    var transactions: Array<CBTransaction>
    
    enum CodingKeys: CodingKey { case user_id, account_id, transactions, device_uuid }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(transactions, forKey: .transactions)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
    }
}
