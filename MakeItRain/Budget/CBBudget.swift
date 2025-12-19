//
//  CBBudget.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/30/24.
//

import Foundation
import SwiftUI

@Observable
class CBBudget: Codable, Identifiable, Hashable, Equatable {
    var id: String
    var uuid: String?
    var category: CBCategory?
    var categoryGroup: CBCategoryGroup?
    var type: XrefItem {
        if category == nil {
            XrefModel.getItem(from: .budgetTypes, byEnumID: .categoryGroup)
        } else {
            XrefModel.getItem(from: .budgetTypes, byEnumID: .category)
        }
    }
    
    var month: Int?
    var year: Int
    var date: Date? {
        if let month {
            Helpers.createDate(month: month, year: year)!
        } else {
            nil
        }
    }
    
    var amount: Double {
        Double(amountString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
    }
    var amountString: String
    
    /// Amount 2 is only for fetching the analytics in the category sheet.
    var amount2: Double {
        Double(amountString2.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
    }
    var amountString2: String
        
    var active: Bool
    var action: BudgetAction
    
    var appSuiteKey: AppSuiteKey?

    
    init() {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid        
        self.category = nil
        self.month = 0
        self.year = 0
        self.amountString = ""
        self.amountString2 = ""
        self.active = true
        self.action = .add
    }
    
    
    init(uuid: String) {
        self.id = uuid
        self.uuid = uuid
        self.category = nil
        self.month = 0
        self.year = 0
        self.amountString = ""
        self.amountString2 = ""
        self.active = true
        self.action = .add
    }
    
    
    
    enum CodingKeys: CodingKey { case id, uuid, category, category_group, month, year, amount, amount2, active, user_id, account_id, device_uuid, app_suite_key, type_id }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(category, forKey: .category)
        try container.encode(categoryGroup, forKey: .category_group)
        try container.encode(month, forKey: .month)
        try container.encode(year, forKey: .year)
        try container.encode(amount, forKey: .amount)
        try container.encode(active ? 1 : 0, forKey: .active)
        try container.encode(AppState.shared.user?.id, forKey: .user_id)
        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(appSuiteKey?.rawValue, forKey: .app_suite_key)
        try container.encode(type.id, forKey: .type_id)
    }
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            id = try String(container.decode(Int.self, forKey: .id))
        } catch {
            id = try container.decode(String.self, forKey: .id)
        }
        self.category = try container.decodeIfPresent(CBCategory.self, forKey: .category)
        //print(try container.decodeIfPresent(CBCategoryGroup.self, forKey: .category_group)?.title)
        self.categoryGroup = try container.decodeIfPresent(CBCategoryGroup.self, forKey: .category_group)
        month = try container.decode(Int?.self, forKey: .month)
        year = try container.decode(Int.self, forKey: .year)
                
        let amount = try container.decode(Double.self, forKey: .amount)
        self.amountString = amount.currencyWithDecimals(LocalStorage.shared.useWholeNumbers ? 0 : 2)
        
        /// Amount 2 is only for fetching the analytics in the category sheet.
        let amount2 = try container.decodeIfPresent(Double.self, forKey: .amount2)
        self.amountString2 = amount2?.currencyWithDecimals(LocalStorage.shared.useWholeNumbers ? 0 : 2) ?? ""
        
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1 ? true : false
        
        action = .edit
        
        if let appSuiteKey = try container.decode(String?.self, forKey: .app_suite_key) {
            self.appSuiteKey = AppSuiteKey.fromString(appSuiteKey)
        }
        
//        let typeID = try container.decode(Int?.self, forKey: .type_id)
//        if let typeID = typeID {
//            self.type = XrefModel.getItem(from: .budgetTypes, byID: typeID)
//        }
    }
    
    
    static var empty: CBBudget {
        CBBudget()
    }
    
    
    
    func hasChanges() -> Bool {
        if let deepCopy = deepCopy {
            if self.month == deepCopy.month
            && self.year == deepCopy.year
            && self.amount == deepCopy.amount
            && self.amount2 == deepCopy.amount2
            && self.type.id == deepCopy.type.id
            && self.category?.id == deepCopy.category?.id
            && self.categoryGroup?.id == deepCopy.categoryGroup?.id {
                return false
            }
        }
        return true
    }
    
    
    var deepCopy: CBBudget?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let budget = CBBudget.empty
            budget.id = self.id
            budget.month = self.month
            budget.year = self.year
            budget.amountString = self.amountString
            budget.amountString2 = self.amountString2
            budget.category = self.category
            budget.categoryGroup = self.categoryGroup
            budget.active = self.active
            //budget.type = self.type
            budget.appSuiteKey = self.appSuiteKey
            self.deepCopy = budget
            
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.month = deepCopy.month
                self.year = deepCopy.year
                self.amountString = deepCopy.amountString
                self.amountString2 = deepCopy.amountString2
                self.category = deepCopy.category
                self.categoryGroup = deepCopy.categoryGroup
                self.active = deepCopy.active
                //self.type = deepCopy.type
                self.appSuiteKey = deepCopy.appSuiteKey
            }
        case .clear:
            break
        }
    }
    
    func setFromAnotherInstance(budget: CBBudget) {
        self.month = budget.month
        self.year = budget.year
                
        self.amountString = budget.amount.currencyWithDecimals(LocalStorage.shared.useWholeNumbers ? 0 : 2)
        self.amountString2 = budget.amount2.currencyWithDecimals(LocalStorage.shared.useWholeNumbers ? 0 : 2)
        
        self.category = budget.category
        self.categoryGroup = budget.categoryGroup
        self.active = budget.active
        self.appSuiteKey = budget.appSuiteKey
        //self.type = budget.type
    }
    
   
    
    static func == (lhs: CBBudget, rhs: CBBudget) -> Bool {
        if lhs.id == rhs.id
        && lhs.month == rhs.month
        && lhs.year == rhs.year
        && lhs.amount == rhs.amount
        && lhs.amount2 == rhs.amount2
        && lhs.type == rhs.type
        && lhs.category?.id == rhs.category?.id
        && lhs.categoryGroup?.id == rhs.categoryGroup?.id {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}



//
//@Observable
//class CBBudgetGroup: Codable, Identifiable, Hashable, Equatable {
//    var id: String
//    var uuid: String?
//    var group: CBCategoryGroup?
//    var type: XrefItem = XrefModel.getItem(from: .budgetTypes, byEnumID: .categoryGroup)
//    var month: Int?
//    var year: Int
//    var date: Date? {
//        if let month {
//            Helpers.createDate(month: month, year: year)!
//        } else {
//            nil
//        }
//    }
//    
//    var amount: Double {
//        Double(amountString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
//    }
//    var amountString: String
//    
//    /// Amount 2 is only for fetching the analytics in the category sheet.
//    var amount2: Double {
//        Double(amountString2.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
//    }
//    var amountString2: String
//        
//    var active: Bool
//    var action: BudgetAction
//    
//    var appSuiteKey: AppSuiteKey?
//
//    
//    init() {
//        let uuid = UUID().uuidString
//        self.id = uuid
//        self.uuid = uuid
//        self.group = nil
//        self.month = 0
//        self.year = 0
//        self.amountString = ""
//        self.amountString2 = ""
//        self.active = true
//        self.action = .add
//    }
//    
//    
//    init(uuid: String) {
//        self.id = uuid
//        self.uuid = uuid
//        self.group = nil
//        self.month = 0
//        self.year = 0
//        self.amountString = ""
//        self.amountString2 = ""
//        self.active = true
//        self.action = .add
//    }
//    
//    
//    
//    enum CodingKeys: CodingKey { case id, uuid, group, month, year, amount, amount2, active, user_id, account_id, device_uuid, app_suite_key, type_id }
//    
//    
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(id, forKey: .id)
//        try container.encode(uuid, forKey: .uuid)
//        try container.encode(group, forKey: .group)
//        try container.encode(month, forKey: .month)
//        try container.encode(year, forKey: .year)
//        try container.encode(amount, forKey: .amount)
//        try container.encode(active ? 1 : 0, forKey: .active)
//        try container.encode(AppState.shared.user?.id, forKey: .user_id)
//        try container.encode(AppState.shared.user?.accountID, forKey: .account_id)
//        try container.encode(AppState.shared.deviceUUID, forKey: .device_uuid)
//        try container.encode(appSuiteKey?.rawValue, forKey: .app_suite_key)
//        try container.encode(type.id, forKey: .type_id)
//    }
//    
//    
//    required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        do {
//            id = try String(container.decode(Int.self, forKey: .id))
//        } catch {
//            id = try container.decode(String.self, forKey: .id)
//        }
//        self.group = try container.decode(CBCategoryGroup?.self, forKey: .group)
//        month = try container.decode(Int?.self, forKey: .month)
//        year = try container.decode(Int.self, forKey: .year)
//                
//        let amount = try container.decode(Double.self, forKey: .amount)
//        self.amountString = amount.currencyWithDecimals(LocalStorage.shared.useWholeNumbers ? 0 : 2)
//        
//        /// Amount 2 is only for fetching the analytics in the category sheet.
//        let amount2 = try container.decodeIfPresent(Double.self, forKey: .amount2)
//        self.amountString2 = amount2?.currencyWithDecimals(LocalStorage.shared.useWholeNumbers ? 0 : 2) ?? ""
//        
//        let isActive = try container.decode(Int?.self, forKey: .active)
//        self.active = isActive == 1 ? true : false
//        
//        action = .edit
//        
//        if let appSuiteKey = try container.decode(String?.self, forKey: .app_suite_key) {
//            self.appSuiteKey = AppSuiteKey.fromString(appSuiteKey)
//        }
//        
//        let typeID = try container.decode(Int?.self, forKey: .type_id)
//        if let typeID = typeID {
//            self.type = XrefModel.getItem(from: .budgetTypes, byID: typeID)
//        }
//    }
//    
//    
//    static var empty: CBBudgetGroup {
//        CBBudgetGroup()
//    }
//    
//    
//    
//    func hasChanges() -> Bool {
//        if let deepCopy = deepCopy {
//            if self.month == deepCopy.month
//            && self.year == deepCopy.year
//            && self.amount == deepCopy.amount
//            && self.amount2 == deepCopy.amount2
//            && self.type.id == deepCopy.type.id
//            && self.group == deepCopy.group {
//                return false
//            }
//        }
//        return true
//    }
//    
//    
//    var deepCopy: CBBudgetGroup?
//    func deepCopy(_ mode: ShadowCopyAction) {
//        switch mode {
//        case .create:
//            let budget = CBBudgetGroup.empty
//            budget.id = self.id
//            budget.month = self.month
//            budget.year = self.year
//            budget.amountString = self.amountString
//            budget.amountString2 = self.amountString2
//            budget.group = self.group
//            budget.active = self.active
//            budget.type = self.type
//            budget.appSuiteKey = self.appSuiteKey
//            self.deepCopy = budget
//            
//        case .restore:
//            if let deepCopy = self.deepCopy {
//                self.id = deepCopy.id
//                self.month = deepCopy.month
//                self.year = deepCopy.year
//                self.amountString = deepCopy.amountString
//                self.amountString2 = deepCopy.amountString2
//                self.group = deepCopy.group
//                self.active = deepCopy.active
//                self.type = deepCopy.type
//                self.appSuiteKey = deepCopy.appSuiteKey
//            }
//        case .clear:
//            break
//        }
//    }
//    
//    func setFromAnotherInstance(budget: CBBudgetGroup) {
//        self.month = budget.month
//        self.year = budget.year
//                
//        self.amountString = budget.amount.currencyWithDecimals(LocalStorage.shared.useWholeNumbers ? 0 : 2)
//        self.amountString2 = budget.amount2.currencyWithDecimals(LocalStorage.shared.useWholeNumbers ? 0 : 2)
//        
//        self.group = budget.group
//        self.active = budget.active
//        self.appSuiteKey = budget.appSuiteKey
//        self.type = budget.type
//    }
//    
//   
//    
//    static func == (lhs: CBBudgetGroup, rhs: CBBudgetGroup) -> Bool {
//        if lhs.id == rhs.id
//        && lhs.month == rhs.month
//        && lhs.year == rhs.year
//        && lhs.amount == rhs.amount
//        && lhs.amount2 == rhs.amount2
//        && lhs.type == rhs.type
//        && lhs.group == rhs.group {
//            return true
//        }
//        return false
//    }
//    
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//    }
//    
//}
//

//
//@Observable
//class CBChristmasBudget: Decodable {
//    var amount: Double {
//        Double(amountString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
//    }
//    var amountString: String
//            
//    enum CodingKeys: CodingKey { case amount }
//            
//    required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        let amount = try container.decode(Double.self, forKey: .amount)
//        self.amountString = amount.currencyWithDecimals(LocalStorage.shared.useWholeNumbers ? 0 : 2)
//    }
//}

