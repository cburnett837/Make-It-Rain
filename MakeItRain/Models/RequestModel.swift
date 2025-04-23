//
//  RequestModel.swift
//  JarvisPhoneApp
//
//  Created by Cody Burnett on 7/25/24.
//

import Foundation
#if os(iOS)
import UIKit
#endif

class RequestModel<T: Encodable>: Encodable {
    var sessionID = ""
    var requestType = ""
    var model: T?
    
    enum CodingKeys: CodingKey { case request_type, json_data, session_id }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(requestType, forKey: .request_type)
        try container.encode(model, forKey: .json_data)
        try container.encode(sessionID, forKey: .session_id)
    }
    
    init(requestType: String, model: T? = nil) {
        self.requestType = requestType
        self.model = model
    }
}


//class RequestModel2<T: Encodable>: Encodable {
//    var sessionID = ""
//    var requestType = ""
//    var model: Array<T>?
//    
//    enum CodingKeys: CodingKey { case request_type, json_data, session_id }
//    
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(requestType, forKey: .request_type)
//        try container.encode(model, forKey: .json_data)
//        try container.encode(sessionID, forKey: .session_id)
//    }
//    
//    init(requestType: String, model: Array<T>? = nil) {
//        self.requestType = requestType
//        self.model = model
//    }
//}



//class ParentReturnIdModel: Decodable {
//    let parentID: Int
//    let idModels: Array<ReturnIdModel>
//    
//    enum CodingKeys: CodingKey { case parent_id, id_models }
//    
//    init (){
//        self.parentID = 0
//        self.idModels = []
//    }
//    
//    
//    required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.parentID = try container.decode(Int.self, forKey: .parent_id)
//        self.idModels = try container.decode(Array<ReturnIdModel>.self, forKey: .id_models)
//    }
//}


//
//class AccessorialModel: Decodable {
//    let payMethods: Array<CBPaymentMethod>
//    let categories: Array<CBCategory>
//    let keywords: Array<CBKeyword>
//    let repeatingTransactions: Array<CBRepeatingTransaction>
//    
//    enum CodingKeys: CodingKey { case payment_methods, categories, keywords, repeating_transactions }
//    
//    required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        payMethods = try container.decode(Array<CBPaymentMethod>.self, forKey: .payment_methods)
//        categories = try container.decode(Array<CBCategory>.self, forKey: .categories)
//        keywords = try container.decode(Array<CBKeyword>.self, forKey: .keywords)
//        repeatingTransactions = try container.decode(Array<CBRepeatingTransaction>.self, forKey: .repeating_transactions)
//    }
//}
