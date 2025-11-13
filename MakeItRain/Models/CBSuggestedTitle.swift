//
//  CBSuggestedTitle.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/31/25.
//

import Foundation

struct CBSuggestedTitle: Decodable, Identifiable {
    var id: UUID
    var title: String
    var transactionCount: Int
    
    enum CodingKeys: CodingKey { case title, transaction_count }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        title = try container.decode(String.self, forKey: .title)
        transactionCount = try container.decode(Int.self, forKey: .transaction_count)
    }
}
