//
//  CBPlaidBalance.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/29/25.
//

import Foundation

@Observable
class CBPlaidBalance: Decodable, Identifiable {
    var id: String
    var internalAccountID: String?
    var payMethodID: String
    var amount: Double {
        Double(amountString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0
    }
    var amountString: String
    var enteredDate: Date?
    var lastTimePlaidSyncedWithInstitutionDate: Date?
    var lastTimeICheckedPlaidSyncedDate: Date?
    var active: Bool
    
    enum CodingKeys: CodingKey { case id, internal_account_id, amount, entered_date, active, payment_method_id, last_time_plaid_synced_with_institution_date, last_time_i_checked_plaid_synced_date }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            id = try String(container.decode(Int.self, forKey: .id))
        } catch {
            id = try container.decode(String.self, forKey: .id)
        }
        
        
        do {
            internalAccountID = try String(container.decode(Int.self, forKey: .internal_account_id))
        } catch {
            internalAccountID = try container.decode(String.self, forKey: .internal_account_id)
        }
        
        let amount = try container.decode(Double.self, forKey: .amount)
        let useWholeNumbers = LocalStorage.shared.useWholeNumbers
        self.amountString = amount.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        let enteredDate = try container.decode(String?.self, forKey: .entered_date)
        if let enteredDate {
            self.enteredDate = enteredDate.toDateObj(from: .serverDateTime)!
        }
        
        let lastTimePlaidSyncedWithInstitutionDate = try container.decode(String?.self, forKey: .last_time_plaid_synced_with_institution_date)
        if let lastTimePlaidSyncedWithInstitutionDate {
            self.lastTimePlaidSyncedWithInstitutionDate = lastTimePlaidSyncedWithInstitutionDate.toDateObj(from: .serverDateTime)!
        }
        
        let lastTimeICheckedPlaidSyncedDate = try container.decode(String?.self, forKey: .last_time_i_checked_plaid_synced_date)
        if let lastTimeICheckedPlaidSyncedDate {
            self.lastTimeICheckedPlaidSyncedDate = lastTimeICheckedPlaidSyncedDate.toDateObj(from: .serverDateTime)!
        }
        
        let active = try container.decode(Int?.self, forKey: .active)
        self.active = active == 1 ? true : false
        
        
        do {
            payMethodID = try String(container.decode(Int.self, forKey: .payment_method_id))
        } catch {
            payMethodID = try container.decode(String.self, forKey: .payment_method_id)
        }        
    }
    
    func setFromAnotherInstance(bal: CBPlaidBalance) {
        self.id = bal.id
        self.internalAccountID = bal.internalAccountID
        self.amountString = bal.amountString
        self.enteredDate = bal.enteredDate
        self.active = bal.active
        self.payMethodID = bal.payMethodID
        self.lastTimePlaidSyncedWithInstitutionDate = bal.lastTimePlaidSyncedWithInstitutionDate
        self.lastTimeICheckedPlaidSyncedDate = bal.lastTimeICheckedPlaidSyncedDate
    }
}
