//
//  ExchangeRate.swift
//  MakeItRain
//
//  Created by Cody Burnett on 6/4/26.
//

import Foundation

struct ExchangeRate: Hashable, Identifiable, Decodable {
    var id: Int
    let currencyCode: String
    var usdRate: Decimal?
    var date: Date?
    
    enum CodingKeys: CodingKey { case id, currency_code, usd_rate, rate_date }
        
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        currencyCode = try container.decode(String.self, forKey: .currency_code)
        usdRate = try container.decode(Decimal.self, forKey: .usd_rate)
        
        let date = try container.decode(String?.self, forKey: .rate_date)
        if let date {
            self.date = date.toDateObj(from: .serverDate)!
        } else {
            //fatalError("Could not determine transaction date")
        }
    }
        
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
