//
//  ParentChildIdModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/1/25.
//


import Foundation

class ParentChildIdModel: Decodable {
    let parentID: ReturnIdModel
    let childIDs: Array<ReturnIdModel>
    
    enum CodingKeys: CodingKey { case parent_id, child_ids }        
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        parentID = try container.decode(ReturnIdModel.self, forKey: .parent_id)
        childIDs = try container.decode(Array<ReturnIdModel>.self, forKey: .child_ids)
    }
}
