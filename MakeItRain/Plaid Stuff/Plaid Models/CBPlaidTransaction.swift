//
//  CBPlaidTransaction.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/27/25.
//

import Foundation
import SwiftUI



@Observable
class CBPlaidTransaction: Codable, Identifiable {
    var id: Int
    var plaidID: String
    var internalAccountID: String?
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
    var active: Bool
    
    enum CodingKeys: CodingKey { case id, plaid_id, internal_account_id, title, amount, date, is_acknowledged, payment_method, category, device_uuid, user_id, account_id, active }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(plaidID, forKey: .plaid_id)
        try container.encode(isAcknowledged ? 1 : 0, forKey: .is_acknowledged)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        plaidID = try container.decode(String.self, forKey: .plaid_id)
        title = try container.decode(String.self, forKey: .title)
        self.payMethod = try container.decode(CBPaymentMethod?.self, forKey: .payment_method)
        self.category = try container.decode(CBCategory?.self, forKey: .category)
        
        
        do {
            internalAccountID = try String(container.decode(Int.self, forKey: .internal_account_id))
        } catch {
            internalAccountID = try container.decode(String.self, forKey: .internal_account_id)
        }
        
        
        let amount = try container.decode(String.self, forKey: .amount)
        let useWholeNumbers = LocalStorage.shared.useWholeNumbers
        self.amountString = (Double(amount) ?? 0.0).currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        let date = try container.decode(String?.self, forKey: .date)
        if let date {
            self.date = date.toDateObj(from: .serverDate)!
        }
        
        let isAcknowledged = try container.decode(Int?.self, forKey: .is_acknowledged)
        self.isAcknowledged = isAcknowledged == 1 ? true : false
        
        let active = try container.decode(Int?.self, forKey: .active)
        self.active = active == 1 ? true : false
    }
    
    func setFromAnotherInstance(trans: CBPlaidTransaction) {
        self.id = trans.id
        self.plaidID = trans.plaidID
        self.internalAccountID = trans.internalAccountID
        self.title = trans.title
        self.amountString = trans.amountString
        self.date = trans.date
        self.payMethod = trans.payMethod
        self.category = trans.category
        self.isAcknowledged = trans.isAcknowledged
        self.active = trans.active
    }
}




//@Observable
//class CBPlaidTransactionOG: Codable, Identifiable, Equatable, Hashable {
//    var id: String
//    var internalAccountID: String
//    var title: String
//    var amount: String
//    var date: Date
//    var isAcknowledged: Bool = false
//    var transactionID: String?
//    var active: Bool = true
//    var enteredBy: CBUser = AppState.shared.user!
//    var updatedBy: CBUser = AppState.shared.user!
//    var enteredDate: Date
//    var updatedDate: Date
//    
//    var action: PlaidBankAction = .edit
//    var deepCopy: CBPlaidTransaction?
//
//    // MARK: - Init
//
//    init() {
//        let uuid = UUID().uuidString
//        self.id = uuid
//        self.internalAccountID = ""
//        self.title = ""
//        self.amount = ""
//        self.date = Date()
//        self.enteredDate = Date()
//        self.updatedDate = Date()
//    }
//
//    // MARK: - Codable
//
//    enum CodingKeys: CodingKey {
//        case id, account_id, user_id, internal_account_id, title, amount, date,
//             category_id, is_acknowledged, did_change, transaction_id, renamed_from_id,
//             active, entered_by_id, entered_date, updated_by_id, updated_date,
//             updated_by_device_uuid, external_id, external_account_id
//    }
//
//    required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//
//        do {
//            id = try String(container.decode(Int.self, forKey: .id))
//        } catch {
//            id = try container.decode(String.self, forKey: .id)
//        }
//        
//        internalAccountID = String(try container.decode(Int.self, forKey: .internal_account_id))
//        title = try container.decode(String.self, forKey: .title)
//        amount = try container.decode(String.self, forKey: .amount)
//        transactionID = try? String(container.decode(Int.self, forKey: .transaction_id))
//        
//        let dateString = try container.decode(String.self, forKey: .date)
//        date = dateString.toDateObj(from: .serverDateTime) ?? Date()
//
//        let acknowledged = try container.decode(Int?.self, forKey: .is_acknowledged)
//        self.isAcknowledged = acknowledged == 1 ? true : false
//        
//
//        let isActive = try container.decode(Int?.self, forKey: .active)
//        self.active = isActive == 1 ? true : false
//
//        enteredBy = try container.decode(CBUser.self, forKey: .entered_by_id)
//        updatedBy = try container.decode(CBUser.self, forKey: .updated_by_id)
//
//        let enteredDateStr = try container.decode(String.self, forKey: .entered_date)
//        let updatedDateStr = try container.decode(String.self, forKey: .updated_date)
//        enteredDate = enteredDateStr.toDateObj(from: .serverDateTime) ?? Date()
//        updatedDate = updatedDateStr.toDateObj(from: .serverDateTime) ?? Date()
//    }
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//
//        try container.encode(id, forKey: .id)
//        try container.encode(Int(internalAccountID), forKey: .internal_account_id)
//        try container.encode(title, forKey: .title)
//        try container.encode(amount, forKey: .amount)
//        try container.encode(date.string(to: .serverDateTime), forKey: .date)
//        try container.encode(isAcknowledged ? 1 : 0, forKey: .is_acknowledged)
//        try container.encodeIfPresent(Int(transactionID ?? ""), forKey: .transaction_id)
//        try container.encode(active ? 1 : 0, forKey: .active)
//        try container.encode(enteredBy, forKey: .entered_by_id)
//        try container.encode(updatedBy, forKey: .updated_by_id)
//        try container.encode(enteredDate.string(to: .serverDateTime), forKey: .entered_date)
//        try container.encode(updatedDate.string(to: .serverDateTime), forKey: .updated_date)
//    }
//
//    // MARK: - Helpers
//
//    func deepCopy(_ mode: ShadowCopyAction) {
//        switch mode {
//        case .create:
//            let copy = CBPlaidTransaction()
//            copy.id = self.id
//            copy.internalAccountID = self.internalAccountID
//            copy.title = self.title
//            copy.amount = self.amount
//            copy.date = self.date
//            copy.isAcknowledged = self.isAcknowledged
//            copy.transactionID = self.transactionID
//            copy.active = self.active
//            copy.enteredDate = self.enteredDate
//            copy.updatedDate = self.updatedDate
//            self.deepCopy = copy
//        case .restore:
//            if let deepCopy = self.deepCopy {
//                self.id = deepCopy.id
//                self.internalAccountID = deepCopy.internalAccountID
//                self.title = deepCopy.title
//                self.amount = deepCopy.amount
//                self.date = deepCopy.date
//                self.isAcknowledged = deepCopy.isAcknowledged
//                self.transactionID = deepCopy.transactionID
//                self.active = deepCopy.active
//                self.enteredBy = deepCopy.enteredBy
//                self.enteredDate = deepCopy.enteredDate
//                self.updatedBy = deepCopy.updatedBy
//                self.updatedDate = deepCopy.updatedDate
//            }
//        case .clear:
//            deepCopy = nil
//        }
//    }
//
//    func setFromAnotherInstance(transaction: CBPlaidTransaction) {
//        self.internalAccountID = transaction.internalAccountID
//        self.title = transaction.title
//        self.amount = transaction.amount
//        self.date = transaction.date
//        self.isAcknowledged = transaction.isAcknowledged
//        self.transactionID = transaction.transactionID
//        self.active = transaction.active
//        self.enteredDate = transaction.enteredDate
//        self.updatedDate = transaction.updatedDate
//    }
//
//    // MARK: - Equatable + Hashable
//
//    static func == (lhs: CBPlaidTransaction, rhs: CBPlaidTransaction) -> Bool {
//        lhs.id == rhs.id &&
//        lhs.title == rhs.title &&
//        lhs.amount == rhs.amount &&
//        lhs.date == rhs.date
//    }
//
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//    }
//}
