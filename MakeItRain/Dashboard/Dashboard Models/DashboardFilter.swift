//
//  DashboardFilter.swift
//  MakeItRain
//
//  Created by Cody Burnett on 8/21/26.
//

import Foundation

@Observable
class DashboardFilter: Codable, Identifiable {
    var id: String
    var uuid: String?
    var title: String
    var beginDate: Date
    var endDate: Date
    var categories: [CBCategory]
    var categoryGroups: [CBCategoryGroup]
    var payMethod: CBPaymentMethod?
    //var payMethodIds: [String]?
    
    var action: DashboardFilterAction
    
    enum CodingKeys: CodingKey { case id, uuid, title, categories, category_groups, user_id, account_id, device_uuid, begin_date, end_date, pay_method, pay_method_ids, action }
    
    /// For new
    init(
        title: String,
        beginDate: Date,
        endDate: Date,
        categories: [CBCategory],
        groups: [CBCategoryGroup],
        payMethod: CBPaymentMethod?,
        //payMethodIds: [String]?
    ) {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.title = title
        self.beginDate = beginDate
        self.endDate = endDate
        self.categories = categories
        self.categoryGroups = groups
        self.payMethod = payMethod
        //self.payMethodIds = payMethodIds
        self.action = .add
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(title, forKey: .title)
        try container.encode(categories, forKey: .categories)
        try container.encode(categoryGroups, forKey: .category_groups)
        try container.encode(payMethod, forKey: .pay_method)
        //try container.encode(payMethodIds, forKey: .pay_method_ids)
        try container.encode(beginDate.string(to: .serverDate), forKey: .begin_date)
        try container.encode(endDate.string(to: .serverDate), forKey: .end_date)
        try container.encode(Cody.shared.id, forKey: .user_id)
        try container.encode(Cody.shared.accountID, forKey: .account_id)
        try container.encode(Cody.shared.deviceUUID, forKey: .device_uuid)
        
        try container.encode(action.serverKey, forKey: .action)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            id = try String(container.decode(Int.self, forKey: .id))
        } catch {
            id = try container.decode(String.self, forKey: .id)
        }
        self.title = try container.decode(String.self, forKey: .title)
        //self.beginDate = try container.decode(Date.self, forKey: .begin_date)
        //self.endDate = try container.decode(Date.self, forKey: .end_date)
        
        if let date = try container.decode(String?.self, forKey: .begin_date) {
            self.beginDate = date.toDateObj(from: .serverDate)!
        } else {
            fatalError()
        }
        
        if let date = try container.decode(String?.self, forKey: .end_date) {
            self.endDate = date.toDateObj(from: .serverDate)!
        } else {
            fatalError()
        }
        
        self.categories = try container.decode([CBCategory].self, forKey: .categories)
        self.categoryGroups = try container.decode([CBCategoryGroup].self, forKey: .category_groups)
        self.payMethod = try container.decode(CBPaymentMethod?.self, forKey: .pay_method)
        //self.payMethodIds = try container.decode(Array<String>?.self, forKey: .pay_method_ids)
        self.action = .edit
    }
}
