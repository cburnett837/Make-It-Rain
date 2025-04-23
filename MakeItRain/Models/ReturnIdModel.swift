//
//  ReturnIdModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/1/25.
//


import Foundation

class ReturnIdModel: Decodable {
    let id: String
    let uuid: String?
    let type: String?
    
    enum CodingKeys: CodingKey { case uuid, id, type }
    
    init() {
        let uuid = UUID().uuidString
        self.uuid = uuid
        self.id = uuid
        self.type = nil
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try container.decode(String?.self, forKey: .uuid)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decodeIfPresent(String.self, forKey: .type)
    }
}
