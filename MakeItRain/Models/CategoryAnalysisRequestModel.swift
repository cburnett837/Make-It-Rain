//
//  CategoryAnalysisRequestModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/6/25.
//

import Foundation

class AnalysisRequestModel: Encodable {
    let recordIDs: Array<String>
    let fetchYearStart: Int
    let fetchYearEnd: Int
    
    enum CodingKeys: CodingKey { case record_ids, fetch_year_start, fetch_year_end, user_id, account_id, device_uuid }
    
    
    init(recordIDs: Array<String>, fetchYearStart: Int, fetchYearEnd: Int) {
        self.recordIDs = recordIDs
        self.fetchYearStart = fetchYearStart
        self.fetchYearEnd = fetchYearEnd
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(recordIDs, forKey: .record_ids)
        try container.encode(fetchYearStart, forKey: .fetch_year_start)
        try container.encode(fetchYearEnd, forKey: .fetch_year_end)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
    }
}
