//
//  CBPaymentMethod.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/20/24.
//

import Foundation
import SwiftUI

@Observable
class CBPaymentMethod: Codable, Identifiable {
    var id: String
    var uuid: String?
    var title: String
    
    var dueDate: Int? {
        Int(dueDateString?.replacing(/[a-z]+/, with: "", maxReplacements: 1) ?? "0")
    }
    var dueDateString: String?
    
    var limit: Double? {
        Double(limitString?.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "") ?? "0.0") ?? 0.0
    }
    var limitString: String?
        
    var accountType: AccountType
    var color: Color
    var isViewingDefault = false
    var isEditingDefault = false
    var active: Bool
    var action: PaymentMethodAction
    
    var notificationOffset: Int? = 0
    var notifyOnDueDate: Bool = false
    var last4: String?
    
    var interestRate: Double? {
        Double(interestRateString?.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "") ?? "0.0") ?? 0.0
    }
    var interestRateString: String?
    
    var loanDuration: Double? {
        Double(loanDurationString?.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "") ?? "0.0") ?? 0.0
    }
    var loanDurationString: String?
    
    
    
    var enteredBy: CBUser = AppState.shared.user!
    var updatedBy: CBUser = AppState.shared.user!
    var enteredDate: Date
    var updatedDate: Date
    
    
    // MARK: - Analytic Variables
    var breakdowns: Array<PayMethodMonthlyBreakdown> = []
    /// This is here so the unified payment method can hold it's children for analysis purposes.
    var breakdownsRegardlessOfPaymentMethod: [PayMethodMonthlyBreakdown] = []
    
    var profitLossMinPercentage: Double = 0.0
    var profitLossMaxPercentage: Double = 0.0
    
    var profitLossMinAmount: Double { Double(profitLossMinAmountString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0 }
    var profitLossMinAmountString: String = ""
    
    var profitLossMaxAmount: Double { Double(profitLossMaxAmountString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0 }
    var profitLossMaxAmountString: String = ""
    
    var minEod: Double { Double(minEodString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0 }
    var minEodString: String = ""
    
    var maxEod: Double { Double(maxEodString.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 0.0 }
    var maxEodString: String = ""
    
    
    // MARK: - View Helper Variables
    var isUnified: Bool { accountType == .unifiedChecking || accountType == .unifiedCredit }
    var isCredit: Bool { accountType == .unifiedCredit || accountType == .credit }
    var isDebit: Bool { accountType == .unifiedChecking || accountType == .checking || accountType == .cash }
    
    
    init() {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid
        self.title = ""
        self.color = .primary
        self.accountType = .checking
        self.action = .add
        self.active = true
        self.notificationOffset = 0
        self.notifyOnDueDate = false
        self.enteredBy = AppState.shared.user!
        self.updatedBy = AppState.shared.user!
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    
    init(uuid: String) {
        self.id = uuid
        self.uuid = uuid
        self.title = ""
        self.accountType = .checking
        self.action = .add
        self.color = .primary
        self.active = true
        self.notificationOffset = 0
        self.notifyOnDueDate = false
        self.enteredBy = AppState.shared.user!
        self.updatedBy = AppState.shared.user!
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    
//    init(unifiedAccountType: AccountType) {
//        
//        if unifiedAccountType == .unifiedChecking {
//            self.id = 100000000
//            self.title = "All Checking"
//        } else if unifiedAccountType == .unifiedCredit {
//            self.id = 100000001
//            self.title = "All Credit"
//        } else {
//            self.id = 0
//            self.title = ""
//        }
//        
//        self.accountType = unifiedAccountType
//        self.action = .edit
//        self.color = .white
//        self.active = true
//    
    init(entity: PersistentPaymentMethod) {
        self.id = entity.id!
        self.title = entity.title ?? ""
        self.dueDateString = String(entity.dueDate)
        
        let useWholeNumbers = LocalStorage.shared.useWholeNumbers
        self.limitString = entity.limit.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        self.accountType = AccountType(rawValue: Int(entity.accountType)) ?? .checking
        self.color = Color.fromHex(entity.hexCode) ?? .clear
        //self.color = Color.fromName(entity.hexCode ?? "white")
        self.action = .edit
        self.isViewingDefault = entity.isViewingDefault
        self.isEditingDefault = entity.isEditingDefault
        self.active = true
        self.notificationOffset = Int(entity.notificationOffset)
        self.notifyOnDueDate = entity.notifyOnDueDate
        self.last4 = entity.last4
        self.interestRateString = String(entity.interestRate)
        self.loanDurationString = String(entity.loanDuration)
        self.enteredBy = AppState.shared.user!
        self.updatedBy = AppState.shared.user!
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    
    
    enum CodingKeys: CodingKey { case id, uuid, title, due_date, limit, account_type_id, hex_code, is_viewing_default, is_editing_default, active, user_id, account_id, device_uuid, notification_offset, notify_on_due_date, last_4_digits, entered_by, updated_by, entered_date, updated_date, breakdowns, interest_rate, loan_duration }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(title, forKey: .title)
        try container.encode(dueDate, forKey: .due_date)
        try container.encode(limit, forKey: .limit)
        try container.encode(accountType.rawValue, forKey: .account_type_id)
        try container.encode(color.toHex(), forKey: .hex_code)
        //try container.encode(color.description, forKey: .hex_code)
        try container.encode(isViewingDefault ? 1 : 0, forKey: .is_viewing_default)
        try container.encode(isEditingDefault ? 1 : 0, forKey: .is_editing_default)
        try container.encode(active ? 1 : 0, forKey: .active)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(notificationOffset, forKey: .notification_offset)
        try container.encode(notifyOnDueDate ? 1 : 0, forKey: .notify_on_due_date)
        try container.encode(last4, forKey: .last_4_digits)
        try container.encode(interestRate, forKey: .interest_rate)
        try container.encode(loanDuration, forKey: .loan_duration)
        try container.encode(enteredBy, forKey: .entered_by) // for the Transferable protocol
        try container.encode(updatedBy, forKey: .updated_by) // for the Transferable protocol
        try container.encode(enteredDate.string(to: .serverDateTime), forKey: .entered_date) // for the Transferable protocol
        try container.encode(updatedDate.string(to: .serverDateTime), forKey: .updated_date) // for the Transferable protocol
    }
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            id = try String(container.decode(Int.self, forKey: .id))
        } catch {
            id = try container.decode(String.self, forKey: .id)
        }
        
        
        title = try container.decode(String.self, forKey: .title)
        
        let dueDate = try container.decode(Int?.self, forKey: .due_date)
        self.dueDateString = String(dueDate ?? 0)
        
        let limit = try container.decode(Double?.self, forKey: .limit)
        let useWholeNumbers = LocalStorage.shared.useWholeNumbers
        self.limitString = limit?.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        let accountType = try container.decode(Int.self, forKey: .account_type_id)
        self.accountType = AccountType(rawValue: accountType) ?? .checking
        
        let hexCode = try container.decode(String?.self, forKey: .hex_code)
        self.color = Color.fromHex(hexCode) ?? .primary
        //let colorDescription = try container.decode(String?.self, forKey: .hex_code)
        //self.color = Color.fromName(colorDescription ?? "white")
        
        
        
        let isViewingDefault = try container.decode(Int?.self, forKey: .is_viewing_default)
        self.isViewingDefault = isViewingDefault == 1 ? true : false
        
        let isEditingDefault = try container.decode(Int?.self, forKey: .is_editing_default)
        self.isEditingDefault = isEditingDefault == 1 ? true : false
        
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1 ? true : false
        
        self.notificationOffset = try container.decode(Int?.self, forKey: .notification_offset)
        
        let notifyOnDueDate = try container.decode(Int?.self, forKey: .notify_on_due_date)
        self.notifyOnDueDate = notifyOnDueDate == 1 ? true : false
        
        self.last4 = try container.decode(String?.self, forKey: .last_4_digits)
        
        //self.interestRate = try container.decode(Double?.self, forKey: .interest_rate)
        //self.loanDuration = try container.decode(Int?.self, forKey: .loan_duration)
        
        if let interestRate = try container.decode(Double?.self, forKey: .interest_rate) {
            self.interestRateString = String(interestRate)
        }
        
        if let loanDuration = try container.decode(Double?.self, forKey: .loan_duration) {
            self.loanDurationString = String(loanDuration)
        }
        
        action = .edit
        
        enteredBy = try container.decode(CBUser.self, forKey: .entered_by)
        updatedBy = try container.decode(CBUser.self, forKey: .updated_by)
        
        let enteredDate = try container.decode(String?.self, forKey: .entered_date)
        if let enteredDate {
            self.enteredDate = enteredDate.toDateObj(from: .serverDateTime)!
        } else {
            fatalError("Could not determine enteredDate date")
        }
        
        let updatedDate = try container.decode(String?.self, forKey: .updated_date)
        if let updatedDate {
            self.updatedDate = updatedDate.toDateObj(from: .serverDateTime)!
        } else {
            fatalError("Could not determine updatedDate date")
        }
        
        
        self.breakdowns = try container.decodeIfPresent(Array<PayMethodMonthlyBreakdown>.self, forKey: .breakdowns) ?? []
    }
    
    
    func getAmount(for date: Date) -> Double? {
        breakdowns.filter { Calendar.current.isDate(date, equalTo: $0.date, toGranularity: .month) }.first?.income
    }
    
    static var empty: CBPaymentMethod {
        CBPaymentMethod()
    }
    
    
    func hasChanges() -> Bool {
        if let deepCopy = deepCopy {
            if self.title == deepCopy.title
            && self.dueDate == deepCopy.dueDate
            && self.limit == deepCopy.limit
            && self.accountType == deepCopy.accountType
            && self.notificationOffset == deepCopy.notificationOffset
            && self.notifyOnDueDate == deepCopy.notifyOnDueDate
            && self.last4 == deepCopy.last4
            && self.interestRate == deepCopy.interestRate
            && self.loanDuration == deepCopy.loanDuration
            && self.color == deepCopy.color {
                return false
            }
        }
        return true
    }
    
    
    var deepCopy: CBPaymentMethod?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let copy = CBPaymentMethod.empty
            copy.id = self.id
            copy.uuid = self.uuid
            copy.title = self.title
            copy.dueDateString = self.dueDateString
            copy.limitString = self.limitString
            copy.accountType = self.accountType
            copy.color = self.color
            copy.isViewingDefault = self.isViewingDefault
            copy.isEditingDefault = self.isEditingDefault
            copy.active = self.active
            copy.notificationOffset = self.notificationOffset
            copy.notifyOnDueDate = self.notifyOnDueDate
            copy.last4 = self.last4
            copy.interestRateString = self.interestRateString
            copy.loanDurationString = self.loanDurationString
            copy.active = self.active
            //copy.action = self.action
            self.deepCopy = copy
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.uuid = deepCopy.uuid
                self.title = deepCopy.title
                self.dueDateString = deepCopy.dueDateString
                self.limitString = deepCopy.limitString
                self.accountType = deepCopy.accountType
                self.color = deepCopy.color
                self.isViewingDefault = deepCopy.isViewingDefault
                self.isEditingDefault = deepCopy.isEditingDefault
                self.active = deepCopy.active
                self.notificationOffset = deepCopy.notificationOffset
                self.notifyOnDueDate = deepCopy.notifyOnDueDate
                self.last4 = deepCopy.last4
                self.interestRateString = deepCopy.interestRateString
                self.loanDurationString = deepCopy.loanDurationString
                self.active = deepCopy.active
                //self.action = deepCopy.action
            }
        case .clear:
            break
        }
    }
    
    
    func setFromAnotherInstance(payMethod: CBPaymentMethod) {
        self.title = payMethod.title
        self.dueDateString = payMethod.dueDateString
        
        let useWholeNumbers = LocalStorage.shared.useWholeNumbers
        self.limitString = payMethod.limit?.currencyWithDecimals(useWholeNumbers ? 0 : 2)
        
        self.accountType = payMethod.accountType
        self.color = payMethod.color
        self.isViewingDefault = payMethod.isViewingDefault
        self.isEditingDefault = payMethod.isEditingDefault
        self.active = payMethod.active
        self.notificationOffset = payMethod.notificationOffset
        self.notifyOnDueDate = payMethod.notifyOnDueDate
        self.last4 = payMethod.last4
        self.interestRateString = payMethod.interestRateString
        self.loanDurationString = payMethod.loanDurationString
    }
            
    
    func changeDefault(_ to: Bool) async {
        self.isViewingDefault = to
        guard let entity = await DataManager.shared.getOne(type: PersistentPaymentMethod.self, predicate: .byId(.string(self.id)), createIfNotFound: false) else { return }
        entity.isViewingDefault = to
        let _ = await DataManager.shared.save()
    }
}


extension CBPaymentMethod: Equatable, Hashable {
    static func == (lhs: CBPaymentMethod, rhs: CBPaymentMethod) -> Bool {
        if lhs.id == rhs.id
        && lhs.uuid == rhs.uuid
        && lhs.title == rhs.title
        && lhs.dueDate == rhs.dueDate
        && lhs.limit == rhs.limit
        && lhs.accountType == rhs.accountType
        && lhs.color == rhs.color
        && lhs.isViewingDefault == rhs.isViewingDefault
        && lhs.isEditingDefault == rhs.isEditingDefault
        && lhs.notificationOffset == rhs.notificationOffset
        && lhs.notifyOnDueDate == rhs.notifyOnDueDate
        && lhs.last4 == rhs.last4
        && lhs.interestRate == rhs.interestRate
        && lhs.loanDuration == rhs.loanDuration
        && lhs.active == rhs.active {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
