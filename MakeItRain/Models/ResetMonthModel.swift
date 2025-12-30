//
//  ResetMonthModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 11/1/24.
//

import Foundation
struct ResetMonthModel: Encodable {
    var month: Int
    var year: Int
    
    enum CodingKeys: CodingKey { case user_id, account_id, device_uuid, month, year }
    
    func encode(to encoder: Encoder) throws {
        
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 2
        
        var fetchMonth = -1
        if month == 0 {
            fetchMonth = 12
        } else if month == 13 {
            fetchMonth = 1
        } else {
            fetchMonth = month
        }
        
        var fetchYear = 0
        if month == 0 {
            fetchYear = year - 1
        } else if month == 13 {
            fetchYear = year + 1
        } else {
            fetchYear = year
        }
        
        let optionalString = formatter.string(from: fetchMonth as NSNumber)!
        //let optionalString = formatter.string(from: calNum as NSNumber)!
                
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(optionalString, forKey: .month)
        try container.encode(String(fetchYear), forKey: .year)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
    }
    
    
}
