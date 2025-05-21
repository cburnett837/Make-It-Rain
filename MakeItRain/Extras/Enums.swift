//
//  Enums.swift
//  MakeItRain
//
//  Created by Cody Burnett on 9/18/24.
//

import Foundation

enum InAppAlertPreference {
    case alert, toast
}

enum WhereToLookForTransaction {
    case normalList, tempList, searchResultList, /*eventList,*/ smartList
}

enum TransactionSaveActionToProcess {
    case normal, fromTransfer, fromEvent
}

enum AppError: Error {
    case serverError(String), connectionError, badtimeOut, taskCancelled, sessionError, incorrectCredentials, failedToGetPhoto, failedToUploadPhoto, accessRevoked
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

enum EventAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add:      return "add_cb_event"
        case .edit:     return "edit_cb_event"
        case .delete:   return "delete_cb_event"
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


enum EventParticipantAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add:      return "add_cb_event_participant"
        case .edit:     return "edit_cb_event_participant"
        case .delete:   return "delete_cb_event_participant"
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


enum EventItemAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add:      return "add_cb_event_item"
        case .edit:     return "edit_cb_event_item"
        case .delete:   return "delete_cb_event_item"
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

enum EventTransactionOptionAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add:      return "add_cb_event_transaction_option"
        case .edit:     return "edit_cb_event_transaction_option"
        case .delete:   return "delete_cb_event_transaction_option"
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


enum EventCategoryAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add:      return "add_cb_event_category"
        case .edit:     return "edit_cb_event_category"
        case .delete:   return "delete_cb_event_category"
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



enum EventTransactionAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add:      return "add_cb_event_transaction"
        case .edit:     return "edit_cb_event_transaction"
        case .delete:   return "delete_cb_event_transaction"
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


enum CategoryGroupAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add:      return "add_cb_category_group"
        case .edit:     return "edit_cb_category_group"
        case .delete:   return "delete_cb_category_group"
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


enum LocationAction: String {
    case add, edit, delete
    
    var serverKey: String {
        switch self {
        case .add:      return "add_cb_location"
        case .edit:     return "edit_cb_location"
        case .delete:   return "delete_cb_location"
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
    case create, restore, clear
}


enum TextFieldInputType {
    case text, double, currency
}

enum KeyboardLocation {
    case toolbar, app
}

enum AccountType: Int {
    case checking = 32
    case credit = 33
    case savings = 35
    case investment = 37
    case k401 = 36
    case cash = 34
    case unifiedChecking = 30
    case unifiedCredit = 31
    case loan = 38
    
}

enum LineItemIndicator: String, CaseIterable {
    case dot, emoji, paymentMethod
    
    var prettyValue: String {
        switch self {
        case .dot: return "Category Dot"
        case .emoji: return "Category Symbol"
        case .paymentMethod: return "Account"
        }
    }
}

//enum MacCategoryDisplayMode: String {
//    case dot, emoji
//}

enum CategorySortMode: String, CaseIterable {
    case title, listOrder
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "title": return .title
        case "listOrder": return .listOrder
        default: return .title
        }
    }
    
    var prettyValue: String {
        switch self {
        case .title:
            "Title"
        case .listOrder:
            "Custom Order"
        }
    }
}

enum TransactionSortMode: String, CaseIterable {
    case title, category, enteredDate
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "title": return .title
        case "category": return .category
        case "enteredDate": return .enteredDate
        default: return .title
        }
    }
    
    var prettyValue: String {
        switch self {
        case .title:
            "Title"
        case .category:
            "Category"
        case .enteredDate:
            "Entered Date"
        }
    }
}

enum PhoneLineItemDisplayItem: String, CaseIterable {
    case title, total, category, both
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "title": return .title
        case "total": return .total
        case "category": return .category
        case "both": return .both
        default: return .title
        }
    }
    
    var prettyValue: String {
        switch self {
        case .title:
            "Title"
        case .total:
            "Total"
        case .category:
            "Category"
        case .both:
            "Category, Title, & Total"
        }
    }
}

enum CreditEodView: String, CaseIterable {
    case availableCredit, remainingBalance
    
    static func fromString(_ theString: String) -> Self {
        switch theString {
        case "availableCredit": return .availableCredit
        case "remainingBalance": return .remainingBalance
        default: return .remainingBalance
        }
    }
    
    var prettyValue: String {
        switch self {
        case .availableCredit:
            "Available Credit"
        case .remainingBalance:
            "Remaining Balance"
        }
    }
}

enum PhoneLineItemTotalPosition: String, CaseIterable {
    case inline, below
    
    var prettyValue: String {
        switch self {
        case .inline:
            "Next to title"
        case .below:
            "Below title"
        }
    }
}

enum LineItemInteractionMode: String {
    case open, preview
}

enum UpdatedByOtherUserDisplayMode: String, CaseIterable {
    case concise, full
    
    var prettyValue: String {
        switch self {
        case .concise:
            "Bold & italic title"
        case .full:
            "Their Name"
        }
    }
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


enum UserPreferedColorScheme: String {
    case userLight, userDark, userSystem
}

enum ListOrderUpdateType: String {
    case categories = "categories"
    case eventCategories = "event_categories"
    case eventItems = "event_items"
}


enum OpenOrClosed: String {
    case open, closed
}

enum OpenRecordViewType: String {
    case event, transaction, eventTransactionOption
}



enum PhotoUploadProgress {
    case performCleanup
    case readyForPlaceholder(String?, String)
    case uploaded(String?, String)
    case displayCompleteAlert(String?, String)
    case readyForDownload(String?, String)
    case failedToUpload(String?, String)
    case done(String?, String)
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
