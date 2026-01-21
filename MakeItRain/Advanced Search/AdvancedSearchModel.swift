//
//  AdvancedSearchModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/29/25.
//


import SwiftUI

enum BeforeAfterOrOn: String, CaseIterable {
    case before, on, after
}

@Observable
class AdvancedSearchModel: Encodable {
    var payMethods: Array<CBPaymentMethod> = []
    var categories: Array<CBCategory> = []
    var months: Array<CBMonth> = []
    var years: Array<Int> = []
    var searchTerms: Array<String> = []
    var newSearchTerm: String = ""
    var amountType: AmountType = .all
    var includeExcluded: Bool = true
    var onlyWithPhotos: Bool = false
    var cutOffDate: Date? = nil
    var cutOffDateType: BeforeAfterOrOn = .on
    var beginDate: Date? = nil
    var endDate: Date? = nil

    
    enum CodingKeys: CodingKey { case payment_methods, categories, months, years, amount_type, include_excluded, only_with_photos, search_terms, user_id, account_id, device_uuid, cut_off_date, cut_off_date_type, begin_date, end_date }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(payMethods, forKey: .payment_methods)
        try container.encode(categories, forKey: .categories)
        try container.encode(months, forKey: .months)
        try container.encode(years, forKey: .years)
        try container.encode(amountType.rawValue, forKey: .amount_type)
        try container.encode(includeExcluded ? 1 : 0, forKey: .include_excluded)
        try container.encode(onlyWithPhotos ? 1 : 0, forKey: .only_with_photos)
        try container.encode(searchTerms, forKey: .search_terms)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(cutOffDate?.string(to: .serverDate), forKey: .cut_off_date)
        try container.encode(cutOffDateType.rawValue, forKey: .cut_off_date_type)
        try container.encode(beginDate?.string(to: .serverDate), forKey: .begin_date)
        try container.encode(endDate?.string(to: .serverDate), forKey: .end_date)
    }
    
    func isValid() -> Bool {
        if categories.isEmpty
        && payMethods.isEmpty
        && months.isEmpty
        && years.isEmpty
        && searchTerms.isEmpty
        && newSearchTerm.isEmpty
        && cutOffDate == nil
        && beginDate == nil
        && endDate == nil {
            return false
        }
        return true
    }
}
