//
//  AdvancedSearchModel.swift
//  MakeItRain
//
//  Created by Cody Burnett on 4/29/25.
//


import SwiftUI

@Observable
class AdvancedSearchModel: Encodable {
    var payMethods: Array<CBPaymentMethod> = []
    var categories: Array<CBCategory> = []
    var months: Array<CBMonth> = []
    var years: Array<Int> = []
    var searchTerms: Array<String> = []
    var newSearchTerm: String = ""

    
    enum CodingKeys: CodingKey { case payment_methods, categories, months, years, search_terms, user_id, account_id, device_uuid }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(payMethods, forKey: .payment_methods)
        try container.encode(categories, forKey: .categories)
        try container.encode(months, forKey: .months)
        try container.encode(years, forKey: .years)
        try container.encode(searchTerms, forKey: .search_terms)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
    }
    
    func isValid() -> Bool {
        if categories.isEmpty
        && payMethods.isEmpty
        && months.isEmpty
        && years.isEmpty
        && searchTerms.isEmpty
        && newSearchTerm.isEmpty {
            return false
        }
        return true
    }
}