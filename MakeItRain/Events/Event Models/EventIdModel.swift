//
//  EventIdModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 1/21/25.
//

import Foundation

class EventIdModel: Decodable {
    let eventID: String
    let participantIds: Array<ReturnIdModel>?
    let items: Array<ReturnIdModel>?
    let transactions: Array<ReturnIdModel>?
    let categories: Array<ReturnIdModel>?
    
    enum CodingKeys: CodingKey { case event_id, participant_ids, items, transactions, categories }
    
    init() {
        self.eventID = UUID().uuidString
        self.participantIds = []
        self.items = []
        self.transactions = []
        self.categories = []
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        eventID = try container.decode(String.self, forKey: .event_id)
        participantIds = try container.decodeIfPresent(Array<ReturnIdModel>.self, forKey: .participant_ids)
        items = try container.decodeIfPresent(Array<ReturnIdModel>.self, forKey: .items)
        transactions = try container.decodeIfPresent(Array<ReturnIdModel>.self, forKey: .transactions)
        categories = try container.decodeIfPresent(Array<ReturnIdModel>.self, forKey: .categories)
    }
}


//class EventItemIdModel: Decodable {
//    let id: String
//    let uuid: String?
//    let transactionIds: Array<ReturnIdModel>?
//    
//    enum CodingKeys: CodingKey { case id, uuid, transaction_ids }
//    
//    init() {
//        let uuid = UUID().uuidString
//        self.id = uuid
//        self.uuid = uuid
//        self.transactionIds = []
//    }
//    
//    required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        id = try container.decode(String.self, forKey: .id)
//        uuid = try container.decode(String?.self, forKey: .uuid)
//        transactionIds = try container.decodeIfPresent(Array<ReturnIdModel>.self, forKey: .transaction_ids)
//    }
//}
