//
//  ForceRefreshBalanceModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 6/16/25.
//

import Foundation

class PlaidForceRefreshCost: Identifiable, Decodable {
    var id: String {
        "\(month)_\(year)"
    }
    var totalCost: Double
    var month: Int
    var year: Int
        
    enum CodingKeys: CodingKey { case total_cost, month, year }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalCost = try container.decode(Double?.self, forKey: .total_cost) ?? 0.0
        month = try container.decode(Int.self, forKey: .month)
        year = try container.decode(Int.self, forKey: .year)
    }
}

