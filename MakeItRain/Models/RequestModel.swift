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

class ResultCompleteModel: Codable {
    let result: String?
    
    enum CodingKeys: CodingKey { case result }
    
    init(){
        self.result = nil
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        result = try container.decode(String.self, forKey: .result)
    }
}

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

class ParentChildIdModel: Decodable {
    let parentID: String
    let childIDs: Array<ReturnIdModel>
    
    enum CodingKeys: CodingKey { case parent_id, child_ids }
    
    init() {
        self.parentID = UUID().uuidString
        self.childIDs = []
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        parentID = try container.decode(String.self, forKey: .parent_id)
        childIDs = try container.decode(Array<ReturnIdModel>.self, forKey: .child_ids)
    }
}




class CheckIfShouldDownloadModel: Codable {
    var shouldDownload: Bool = false
    var lastNetworkTime: String?
    
    enum CodingKeys: CodingKey { case user_id, account_id, device_uuid, should_download, last_network_time }
    
    init(lastNetworkTime: Date) {
        self.lastNetworkTime = lastNetworkTime.string(to: .serverDateTime)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(lastNetworkTime, forKey: .last_network_time)
    }
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let result = try container.decode(Int?.self, forKey: .should_download)
        self.shouldDownload = result == 1 ? true : false
    }
}



class CodablePlaceHolder: Codable {
    let thing: String?
    var deviceName: String = UserDefaults.standard.string(forKey: "deviceName") ?? "device name undetermined"
    
    init() {
        self.thing = nil
    }
}


class LongPollSubscribeModel: Encodable {
    let lastReturnTime: Int?
    var deviceName: String = UserDefaults.standard.string(forKey: "deviceName") ?? "device name undetermined"
    
    enum CodingKeys: CodingKey { case last_return_time, user_id, account_id, device_uuid, device_os, device_name }
        
    init(lastReturnTime: Int?) {
        self.lastReturnTime = lastReturnTime
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lastReturnTime, forKey: .last_return_time)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
                
        #if os(macOS)
        try container.encode(String(ProcessInfo.processInfo.operatingSystemVersionString), forKey: .device_os)
        try container.encode(String(ProcessInfo.processInfo.hostName), forKey: .device_name)
        #else
        try container.encode(String(UIDevice.current.systemVersion), forKey: .device_os)
        try container.encode(String(UIDevice.current.name), forKey: .device_name)
        #endif
    }
}




class TransactionAndStartingAmountModel: Decodable {
    let hasPopulated: Bool
    let transactions: Array<CBTransaction>
    let startingAmounts: Array<CBStartingAmount>
    let budgets: Array<CBBudget>?
    
    enum CodingKeys: CodingKey { case transactions, starting_amounts, budgets, has_populated }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        transactions = try container.decode(Array<CBTransaction>.self, forKey: .transactions)
        startingAmounts = try container.decode(Array<CBStartingAmount>.self, forKey: .starting_amounts)
        budgets = try container.decode(Array<CBBudget>.self, forKey: .budgets)
        let hasPopulated = try container.decode(Int.self, forKey: .has_populated)
        self.hasPopulated = hasPopulated == 1
    }
}


class AccessorialModel: Decodable {
    let payMethods: Array<CBPaymentMethod>
    let categories: Array<CBCategory>
    let keywords: Array<CBKeyword>
    let repeatingTransactions: Array<CBRepeatingTransaction>
    
    enum CodingKeys: CodingKey { case payment_methods, categories, keywords, repeating_transactions }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        payMethods = try container.decode(Array<CBPaymentMethod>.self, forKey: .payment_methods)
        categories = try container.decode(Array<CBCategory>.self, forKey: .categories)
        keywords = try container.decode(Array<CBKeyword>.self, forKey: .keywords)
        repeatingTransactions = try container.decode(Array<CBRepeatingTransaction>.self, forKey: .repeating_transactions)
    }
}


class CategoryListOrderUpdatModel: Encodable {
    let categories: Array<CBCategory>
    
    enum CodingKeys: CodingKey { case categories, user_id, account_id, device_uuid }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(categories, forKey: .categories)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
    }
    
    init(categories: Array<CBCategory>) {
        self.categories = categories
    }
}
