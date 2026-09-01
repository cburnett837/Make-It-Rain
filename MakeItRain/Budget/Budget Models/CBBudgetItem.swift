//
//  CBBudgetItem.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/30/24.
//

import Foundation
import SwiftUI


protocol BudgetItem: AnyObject, Identifiable, Hashable {
    var id: String { get }
    var title: String { get }
    var amountString: String? { get set }
    var budgetType: BudgetItemType { get }
    
    func hasChanges() -> Bool
}

enum BudgetItemType: Int, CaseIterable {
    case categoryGroup = 52
    case category = 51
    case tag = 65
    
    var prettyValue: String {
        switch self {
        case .categoryGroup:
            "Category Group"
        case .category:
            "Category"
        case .tag:
            "Tag"
        }
    }
    
    var sectionHeaderText: String {
        switch self {
        case .categoryGroup:
            "Group Budgets"
        case .category:
            "Categorical Budgets"
        case .tag:
            "Tag Budgets"
        }
    }
}

extension CBCategory: BudgetItem {
    var budgetType: BudgetItemType { .category }
}

extension CBCategoryGroup: BudgetItem {
    var budgetType: BudgetItemType { .categoryGroup }
}

extension CBTag: BudgetItem {
    var budgetType: BudgetItemType { .tag }
}

@Observable
class CBBudgetItem: Codable, Identifiable, Hashable, Equatable, IsEditableBudget, HasUserUpdateInfo {
    var id: String
    var uuid: String?
    var monthId: Int?
    var item: (any BudgetItem)?
    
    var category: CBCategory? {
        get { item as? CBCategory }
        set { item = newValue }
    }

    var categoryGroup: CBCategoryGroup? {
        get { item as? CBCategoryGroup }
        set { item = newValue }
    }
    
    var tag: CBTag? {
        get { item as? CBTag }
        set { item = newValue }
    }
    
//    var type: BudgetItemType {
//        item?.budgetType ?? .category
//    }
    
    var type: BudgetItemType
    
    var catIsIncome: Bool { self.category?.isIncome == true }    
    var catIsExpense: Bool { self.category?.isExpense == true || self.categoryGroup != nil }
        
    var amount: Decimal {
        CurrencyHelpers.parseAmountStringToDecimal(amountString) ?? 0.0
        //Decimal(amountString.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
    }
    var amountString: String
    
    /// Amount 2 is only for fetching the analytics in the category sheet.
    var amount2: Decimal {
        CurrencyHelpers.parseAmountStringToDecimal(amountString2) ?? 0.0
        //Decimal(amountString2.replacing("$", with: "").replacing(",", with: "")) ?? 0.0
    }
    var amountString2: String
        
    var active: Bool
    var action: BudgetItemAction
    
    var appSuiteKey: AppSuiteKey?
    
    var enteredBy: CBUser = AppState.shared.user!
    var updatedBy: CBUser = AppState.shared.user!
    var enteredById: Int?
    var updatedById: Int?
    var enteredDate: Date
    var updatedDate: Date

    
    init(type: BudgetItemType) {
        let uuid = UUID().uuidString
        self.id = uuid
        self.uuid = uuid        
        self.item = nil
        self.amountString = ""
        self.amountString2 = ""
        self.active = true
        self.action = .add
        self.type = type
        
        self.enteredBy = AppState.shared.user!
        self.updatedBy = AppState.shared.user!
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    
    
    init(uuid: String, type: BudgetItemType) {
        self.id = uuid
        self.uuid = uuid
        self.item = nil
        self.amountString = ""
        self.amountString2 = ""
        self.active = true
        self.action = .add
        //self.type = .category
        self.type = type
        
        self.enteredBy = AppState.shared.user!
        self.updatedBy = AppState.shared.user!
        self.enteredDate = Date()
        self.updatedDate = Date()
    }
    
    
    
    enum CodingKeys: CodingKey { case id, uuid, category, category_group, category_id, category_group_id, amount, amount2, active, user_id, account_id, device_uuid, app_suite_key, type_id, item_id, tag, budget_month_id, item_title, entered_by, updated_by, entered_date, updated_date, entered_by_id, updated_by_id }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(monthId, forKey: .budget_month_id)
        try container.encode(item?.id, forKey: .item_id)
        try container.encode(item?.title, forKey: .item_title)
        try container.encode(amount, forKey: .amount)
        try container.encode(active ? 1 : 0, forKey: .active)
        try container.encode(enteredById, forKey: .entered_by_id) // for the Transferable protocol
        try container.encode(updatedById, forKey: .updated_by_id) // for the Transferable protocol
        try container.encode(enteredDate, forKey: .entered_date) // for the Transferable protocol
        try container.encode(updatedDate, forKey: .updated_date) // for the Transferable protocol
        try container.encode(Cody.shared.id, forKey: .user_id)
        try container.encode(Cody.shared.accountID, forKey: .account_id)
        try container.encode(Cody.shared.deviceUUID, forKey: .device_uuid)
        try container.encode(appSuiteKey?.rawValue, forKey: .app_suite_key)
        try container.encode(type.rawValue, forKey: .type_id)
    }
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            id = try String(container.decode(Int.self, forKey: .id))
        } catch {
            id = try container.decode(String.self, forKey: .id)
        }
        
        monthId = try container.decode(Int?.self, forKey: .budget_month_id)
        
        let decodedCategory = try container.decodeIfPresent(CBCategory.self, forKey: .category)
        let decodedGroup = try container.decodeIfPresent(CBCategoryGroup.self, forKey: .category_group)
        let decodedTag = try container.decodeIfPresent(CBTag.self, forKey: .tag)
        self.item = decodedCategory ?? decodedGroup ?? decodedTag
        
        
        self.type = (
            decodedCategory != nil
            ? .category
            : (decodedGroup != nil
               ? .categoryGroup
               : (decodedTag != nil
                  ? .tag :
                    .category
                 )
              )
            )
                
        let amount = try container.decode(Decimal.self, forKey: .amount)
        self.amountString = amount.currencyWithDecimals()
        
        /// Amount 2 is only for fetching the analytics in the category sheet.
        let amount2 = try container.decodeIfPresent(Decimal.self, forKey: .amount2)
        self.amountString2 = amount2?.currencyWithDecimals() ?? ""
        
        let isActive = try container.decode(Int?.self, forKey: .active)
        self.active = isActive == 1 ? true : false
        
        action = .edit
        
        if let appSuiteKey = try container.decode(String?.self, forKey: .app_suite_key) {
            self.appSuiteKey = AppSuiteKey(rawValue: appSuiteKey)
        }
        
        if let enteredById = try container.decode(Int?.self, forKey: .entered_by_id) {
            self.enteredBy = AppState.shared.getUserBy(id: enteredById) ?? CBUser()
        }
        
        if let updatedById = try container.decode(Int?.self, forKey: .updated_by_id) {
            self.updatedBy = AppState.shared.getUserBy(id: updatedById) ?? CBUser()
        }

        enteredDate = try container.decode(Date.self, forKey: .entered_date)
        updatedDate = try container.decode(Date.self, forKey: .updated_date)
        
    }

    
    func hasChanges() -> Bool {
        if let deepCopy = deepCopy {
            if self.amount == deepCopy.amount
            && self.amount2 == deepCopy.amount2
            && self.item?.id == deepCopy.item?.id {
                return false
            }
        }
        return true
    }
    
    
    var deepCopy: CBBudgetItem?
    func deepCopy(_ mode: ShadowCopyAction) {
        switch mode {
        case .create:
            let budget = CBBudgetItem(type: self.type)
            budget.id = self.id
            budget.monthId = self.monthId
            budget.amountString = self.amountString
            budget.amountString2 = self.amountString2
            budget.category = self.category
            budget.categoryGroup = self.categoryGroup
            budget.tag = self.tag
            budget.item = self.item
            budget.active = self.active
            budget.appSuiteKey = self.appSuiteKey
            self.deepCopy = budget
            
        case .restore:
            if let deepCopy = self.deepCopy {
                self.id = deepCopy.id
                self.monthId = deepCopy.monthId
                self.amountString = deepCopy.amountString
                self.amountString2 = deepCopy.amountString2
                self.category = deepCopy.category
                self.categoryGroup = deepCopy.categoryGroup
                self.tag = deepCopy.tag
                self.item = deepCopy.item
                self.active = deepCopy.active
                //self.type = deepCopy.type
                self.appSuiteKey = deepCopy.appSuiteKey
            }
        case .clear:
            break
        }
    }
    
    func setFromAnotherInstance(budget: CBBudgetItem) {
        self.monthId = budget.monthId
        self.amountString = budget.amount.currencyWithDecimals()
        self.amountString2 = budget.amount2.currencyWithDecimals()
        self.category = budget.category
        self.categoryGroup = budget.categoryGroup
        self.tag = budget.tag
        self.active = budget.active
        self.appSuiteKey = budget.appSuiteKey
        //self.type = budget.type
        self.item = budget.item
        
        self.enteredBy = budget.enteredBy
        self.updatedBy = budget.updatedBy
        self.enteredDate = budget.enteredDate
        self.updatedDate = budget.updatedDate
        
        //print(category?.title)
        //print(categoryGroup?.title)
        //print(tag?.title)
    }
    
   
    
    static func == (lhs: CBBudgetItem, rhs: CBBudgetItem) -> Bool {
        if lhs.id == rhs.id
        && lhs.monthId == rhs.monthId
        && lhs.amount == rhs.amount
        && lhs.amount2 == rhs.amount2
        && lhs.type == rhs.type
        && lhs.item?.id == rhs.item?.id {
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
//class CBBudgetItemGroup: Codable, Identifiable, Hashable, Equatable {
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
//        try container.encode(Cody.shared.id, forKey: .user_id)
//        try container.encode(Cody.shared.accountID, forKey: .account_id)
//        try container.encode(Cody.shared.deviceUUID, forKey: .device_uuid)
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
//        self.amountString = amount.currencyWithDecimals()
//        
//        /// Amount 2 is only for fetching the analytics in the category sheet.
//        let amount2 = try container.decodeIfPresent(Double.self, forKey: .amount2)
//        self.amountString2 = amount2?.currencyWithDecimals() ?? ""
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
//    static var empty: CBBudgetItemGroup {
//        CBBudgetItemGroup()
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
//    var deepCopy: CBBudgetItemGroup?
//    func deepCopy(_ mode: ShadowCopyAction) {
//        switch mode {
//        case .create:
//            let budget = CBBudgetItemGroup.empty
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
//    func setFromAnotherInstance(budget: CBBudgetItemGroup) {
//        self.month = budget.month
//        self.year = budget.year
//                
//        self.amountString = budget.amount.currencyWithDecimals()
//        self.amountString2 = budget.amount2.currencyWithDecimals()
//        
//        self.group = budget.group
//        self.active = budget.active
//        self.appSuiteKey = budget.appSuiteKey
//        self.type = budget.type
//    }
//    
//   
//    
//    static func == (lhs: CBBudgetItemGroup, rhs: CBBudgetItemGroup) -> Bool {
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
//        self.amountString = amount.currencyWithDecimals()
//    }
//}

