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
    let relatedID: String?
    let updatedDate: Date?
    
    enum CodingKeys: CodingKey { case uuid, id, type, related_id, updated_date }
    
    init() {
        let uuid = UUID().uuidString
        self.uuid = uuid
        self.id = uuid
        self.type = nil
        self.relatedID = nil
        self.updatedDate = nil
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try container.decode(String?.self, forKey: .uuid)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        relatedID = try container.decodeIfPresent(String.self, forKey: .related_id)
        
        let updatedDate = try container.decodeIfPresent(String.self, forKey: .updated_date)
        if let updatedDate {
            self.updatedDate = updatedDate.toDateObj(from: .serverDateTime)!
        } else {
            self.updatedDate = nil
        }
    }
}
