//
//  CBFitTransaction.swift
//  MakeItRain
//
//  Created by Cody Burnett on 2/19/25.
//

import Foundation
import SwiftUI

@Observable
class CBFitTransaction: Codable, Identifiable {
    var id: Int
    var fitID: String
    var title: String
    var amount: Double {
        Double(amountString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
    }
    var amountString: String
    var date: Date?
    var prettyDate: String? {
        if let date = self.date {
            return date.string(to: .monthDayShortYear)
        }
        return nil
    }
    var dateComponents: DateComponents? {
        //return Calendar.current.dateComponents(in: .current, from: date)
        
        if let date = self.date {
            return Calendar.current.dateComponents(in: .current, from: date)
        } else {
            return nil
        }
    }
    var payMethod: CBPaymentMethod?
    var category: CBCategory?
    
    var isAcknowledged: Bool
    
    enum CodingKeys: CodingKey { case id, fitid, title, amount, date, is_acknowledged, payment_method, category, device_uuid, user_id, account_id }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(fitID, forKey: .fitid)
        try container.encode(isAcknowledged ? 1 : 0, forKey: .is_acknowledged)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        fitID = try container.decode(String.self, forKey: .fitid)
        title = try container.decode(String.self, forKey: .title)
        self.payMethod = try container.decode(CBPaymentMethod?.self, forKey: .payment_method)
        self.category = try container.decode(CBCategory?.self, forKey: .category)
        
        let amount = try container.decode(String.self, forKey: .amount)
        
        self.amountString = (Double(amount) ?? 0.0).currencyWithDecimals()
        
        let date = try container.decode(String?.self, forKey: .date)
        if let date {
            self.date = date.toDateObj(from: .serverDate)!
        }
        
        let isAcknowledged = try container.decode(Int?.self, forKey: .is_acknowledged)
        self.isAcknowledged = isAcknowledged == 1 ? true : false
    }
    
    func setFromAnotherInstance(trans: CBFitTransaction) {
        self.id = trans.id
        self.fitID = trans.fitID
        self.title = trans.title
        self.amountString = trans.amountString
        self.date = trans.date
        self.payMethod = trans.payMethod
        self.category = trans.category
        self.isAcknowledged = trans.isAcknowledged                
    }
}
