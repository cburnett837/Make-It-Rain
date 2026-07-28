//
//  DashboardRequestModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/16/26.
//


import SwiftUI
import Charts

struct DashboardRequestModel: Encodable {
    var beginDate: Date
    var endDate: Date
    var categories: [CBCategory]
    var categoryGroups: [CBCategoryGroup]
    var payMethod: CBPaymentMethod?
    var payMethodIds: Array<String>?
    
    enum CodingKeys: CodingKey { case categories, category_groups, user_id, account_id, device_uuid, begin_date, end_date, pay_method, pay_method_ids }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(categories, forKey: .categories)
        try container.encode(categoryGroups, forKey: .category_groups)
        try container.encode(payMethod, forKey: .pay_method)
        try container.encode(payMethodIds, forKey: .pay_method_ids)
        try container.encode(beginDate.string(to: .serverDate), forKey: .begin_date)
        try container.encode(endDate.string(to: .serverDate), forKey: .end_date)
        try container.encode(Cody.shared.id, forKey: .user_id)
        try container.encode(Cody.shared.accountID, forKey: .account_id)
        try container.encode(Cody.shared.deviceUUID, forKey: .device_uuid)
    }
}
