//
//  Enums.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/18/24.
//

import Foundation

enum WhereToLookForTransaction {
    case normalList, tempList, searchResultList
}

enum AppError: Error {
    case serverError(String), connectionError, badtimeOut, taskCancelled, sessionError, incorrectCredentials, failedToGetPhoto, failedToUploadPhoto
}

enum CalendarSearchWhat {
    case titles, tags
}

enum FunkyChatGptDateError: Error {
    case funkyYear, funkyMonth
}

enum TransactionAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add:      return "add_cb_transaction"
        case .edit:     return "edit_cb_transaction"
        case .delete:   return "delete_cb_transaction"
        }
    }
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "add": return .add
        case "edit": return .edit
        case "delete": return .delete
        default: return .add
        }
    }
}

enum RepeatingTransactionAction {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add:      return "add_cb_repeating_transaction"
        case .edit:     return "edit_cb_repeating_transaction"
        case .delete:   return "delete_cb_repeating_transaction"
        }
    }
}


enum PaymentMethodAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add:      return "add_cb_payment_method"
        case .edit:     return "edit_cb_payment_method"
        case .delete:   return "delete_cb_payment_method"
        }
    }
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "add": return .add
        case "edit": return .edit
        case "delete": return .delete
        default: return .add
        }
    }
}

enum StartingAmountAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add:      return "add_cb_starting_amount"
        case .edit:     return "edit_cb_starting_amount"
        case .delete:   return "delete_cb_starting_amount"
        }
    }
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "add": return .add
        case "edit": return .edit
        case "delete": return .delete
        default: return .add
        }
    }
}

enum KeywordAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add:      return "add_cb_keyword"
        case .edit:     return "edit_cb_keyword"
        case .delete:   return "delete_cb_keyword"
        }
    }
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "add": return .add
        case "edit": return .edit
        case "delete": return .delete
        default: return .add
        }
    }
}

enum KeywordTriggerType: String {
    case equals = "equals"
    case contains = "contains"
}


enum TagAction {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add:      return "add_cb_tag"
        case .edit:     return "edit_cb_tag"
        case .delete:   return "delete_cb_tag"
        }
    }
}


enum CategoryAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add:      return "add_cb_category"
        case .edit:     return "edit_cb_category"
        case .delete:   return "delete_cb_category"
        }
    }
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "add": return .add
        case "edit": return .edit
        case "delete": return .delete
        default: return .add
        }
    }
}

enum BudgetAction {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add:      return "add_cb_budget"
        case .edit:     return "edit_cb_budget"
        case .delete:   return "delete_cb_budget"
        }
    }
}


enum WhenType: String {
    case weekday = "weekday"
    case month = "month"
    case dayOfMonth = "dayOfMonth"
    case specificDate = "specificDate"
}

enum ShadowCopyAction {
    case create, restore
}


enum TextFieldInputType {
    case text, double, currency
}

enum KeyboardLocation {
    case toolbar, app
}

enum AccountType: String {
    case checking = "checking"
    case credit = "credit"
    case savings = "savings"
    case investment = "investment"
    case k401 = "k401"
    case cash = "cash"
    case unifiedChecking = "unified checking"
    case unifiedCredit = "unified credit"
    
}

enum LineItemIndicator: String {
    case dot, emoji, paymentMethod
}

//enum MacCategoryDisplayMode: String {
//    case dot, emoji
//}

enum CategorySortMode: String {
    case title, listOrder
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "title": return .title
        case "listOrder": return .listOrder
        default: return .title
        }
    }
}

enum TransactionSortMode: String {
    case title, category, enteredDate
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "title": return .title
        case "category": return .category
        case "enteredDate": return .enteredDate
        default: return .title
        }
    }
}

enum PhoneLineItemDisplayItem: String {
    case title, total, both, category
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "title": return .title
        case "total": return .total
        case "both": return .both
        case "category": return .category
        default: return .title
        }
    }
}

enum PhoneLineItemTotalPosition: String {
    case inline, below
}

enum LineItemInteractionMode: String {
    case open, preview
}

enum UpdatedByOtherUserDisplayMode: String {
    case concise, full
}

enum SearchScope: String, CaseIterable {
    case category, title
}

enum ImageState {
    case empty, loading(Progress), failure(AppError)
}

enum TransferError: Error {
    case importFailed
}

enum FocusedField {
    case title, dueDate, amount, notes, emoji, search, startingAmount, none, trackingNumber, orderNumber, url
}

enum CalendarViewMode: String {
    case bottomPanel, details, budget, split, scrollable
}

enum CalendarChartModel: String {
    case verticalBar, horizontalBar, pie, donut, line
}


enum RefreshTechnique: String {
    case viaInitial, viaButton, viaSceneChange, viaLongPoll, viaTempListButton, viaTempListSceneChange
}







//MARK: Core Data Stuff

enum IdType {
    case int(Int)
    case string(String)
}

enum Predicate {
    case single(NSPredicate)
    case compound(NSCompoundPredicate)
    case byId(IdType)
}

enum CoreDataError: Error {
    case reason(String)
}
